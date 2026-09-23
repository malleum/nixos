// jay-status: the status bar feed for jay, in the i3bar JSON protocol.
//
// Compiled by _status.nix after modules/scripts/_daytime.rs (for the date and
// the duod clock) and the generated colour constants (C_*) and PACTL path.
//
// Shape:
//   * jay spawns this and reads stdout. It is not a systemd unit, and jay
//     respawns it on config reload, so older instances are killed at start
//     and a write to a closed stdout exits.
//   * Audio must feel instant: a thread reads `pactl subscribe` and wakes the
//     main loop the moment a sink or source changes. Only the audio blocks
//     are re-read then.
//   * Everything else refreshes on a fixed 2s tick, so it never gates audio.

use std::io::{BufRead, BufReader, Write};
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};
use std::sync::mpsc::{self, RecvTimeoutError};
use std::thread;
use std::time::{Duration, Instant};

const TICK: Duration = Duration::from_secs(2);

extern "C" {
    fn kill(pid: i32, sig: i32) -> i32;
    fn prctl(option: i32, ...) -> i32;
    fn statvfs(path: *const i8, buf: *mut u64) -> i32;
}
const SIGTERM: i32 = 15;
const SIGKILL: i32 = 9;
const PR_SET_PDEATHSIG: i32 = 1;

/// One rounded pill: accent glyph plus value on a C_PILL fill.
///
/// jay's i3bar reader (jay-config/src/status.rs) turns a block's `color` /
/// `background` into a pango span around the *whole* block, and a pango
/// bgcolor is a hard rectangle. So the fill is done in markup instead, capped
/// by the Nerd Font powerline half-circles U+E0B6 / U+E0B4 drawn in the fill
/// colour: cap, filled body, cap. Needs JetBrainsMono Nerd Font
/// (theme.bar-font in _config.nix); a plain font renders tofu.
///
/// Two spacing details, both load-bearing and tuned with pango-view:
///   * The spaces after the icon sit INSIDE the icon's span. Nerd Font glyphs
///     draw wider than their advance, and pango paints each run's background
///     just before that run's glyphs, so a space in the value's run painted
///     over the icon's overhang and sheared its right edge off.
///   * Two spaces after the icon, one before the closing cap: the icon's
///     overhang visually swallows the first.
fn pill(name: &str, color: &str, icon: char, value: &str) -> String {
    format!(
        concat!(
            r#"{{"name":"{name}","markup":"pango","full_text":""#,
            "<span foreground='{pill}'>\u{E0B6}</span>",
            "<span bgcolor='{pill}'><span foreground='{color}'>{icon}  </span>{value} </span>",
            "<span foreground='{pill}'>\u{E0B4}</span>",
            r#""}}"#,
        ),
        name = name,
        pill = C_PILL,
        color = color,
        icon = icon,
        value = value,
    )
}

/// Gap before the tray. jay sizes the status by ink rect, which drops
/// trailing spaces but not glyph ink, so an invisible glyph reserves width.
/// It hides via pango `alpha` rather than painting itself the bar colour,
/// because the bar is translucent.
fn spacer() -> String {
    format!(
        concat!(
            r#"{{"name":"spacer","markup":"pango","full_text":""#,
            "<span foreground='{}' alpha='1%'>\u{2588}</span>",
            r#""}}"#,
        ),
        C_BG,
    )
}

fn pactl(args: &[&str]) -> String {
    Command::new(PACTL)
        .args(args)
        .stderr(Stdio::null())
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

/// Output device: is the default sink the Bluetooth headset?
fn bt_block() -> String {
    if pactl(&["get-default-sink"]).starts_with("bluez_output.") {
        pill("btaudio", C_BT, '\u{F02CB}', "bt")
    } else {
        pill("btaudio", C_DIM, '\u{F04C3}', "spk")
    }
}

fn audio_block() -> String {
    if pactl(&["get-sink-mute", "@DEFAULT_SINK@"]) == "Mute: yes" {
        return pill("pulseaudio", C_DIM, '\u{F075F}', "muted");
    }
    // "Volume: front-left: 65536 / 100% / 0.00 dB, ..." -- first percentage.
    let vol: Option<u32> = pactl(&["get-sink-volume", "@DEFAULT_SINK@"])
        .split_whitespace()
        .find_map(|w| w.strip_suffix('%')?.parse().ok());
    let icon = match vol.unwrap_or(0) {
        0..=33 => '\u{F057F}',
        34..=66 => '\u{F0580}',
        _ => '\u{F057E}',
    };
    let text = vol.map_or("?%".to_string(), |v| format!("{v}%"));
    pill("pulseaudio", C_AUDIO, icon, &text)
}

/// Busy and total jiffies from the aggregate line of /proc/stat.
fn cpu_jiffies() -> (u64, u64) {
    let stat = std::fs::read_to_string("/proc/stat").unwrap_or_default();
    let f: Vec<u64> = stat
        .lines()
        .next()
        .unwrap_or("")
        .split_whitespace()
        .skip(1)
        .take(4)
        .filter_map(|x| x.parse().ok())
        .collect();
    match f[..] {
        [user, nice, system, idle] => (user + nice + system, user + nice + system + idle),
        _ => (0, 0),
    }
}

fn memory_block() -> String {
    let info = std::fs::read_to_string("/proc/meminfo").unwrap_or_default();
    let field = |key: &str| -> Option<u64> {
        let line = info.lines().find(|l| l.starts_with(key))?;
        line.split_whitespace().nth(1)?.parse().ok()
    };
    let text = match (field("MemTotal:"), field("MemAvailable:")) {
        (Some(total), Some(avail)) => {
            let used_mb = total.saturating_sub(avail) / 1024;
            format!("{}.{}G", used_mb / 1024, used_mb % 1024 * 10 / 1024)
        }
        _ => "?G".to_string(),
    };
    pill("memory", C_MEM, '\u{F0F85}', &text)
}

/// Root filesystem use, rounded up like df's Use% column.
fn disk_block() -> String {
    // struct statvfs is 112 bytes of unsigned longs and ints on 64-bit glibc;
    // 16 u64s over-allocate it. Fields 2..=4 are f_blocks, f_bfree, f_bavail.
    let mut buf = [0u64; 16];
    let ok = unsafe { statvfs(b"/\0".as_ptr() as *const i8, buf.as_mut_ptr()) } == 0;
    let pct = match (ok, buf[2], buf[3], buf[4]) {
        (true, blocks, bfree, bavail) if blocks > 0 => {
            let used = blocks - bfree;
            let (num, den) = (used * 100, used + bavail);
            num / den + u64::from(num % den != 0)
        }
        _ => 0,
    };
    pill("disk", C_DISK, '\u{F02CA}', &format!("{pct:02}%"))
}

fn battery_block() -> Option<String> {
    let dir = std::path::Path::new("/sys/class/power_supply/BAT0");
    if !dir.is_dir() {
        return None;
    }
    let read = |f: &str| std::fs::read_to_string(dir.join(f)).unwrap_or_default().trim().to_string();
    let capacity = read("capacity");
    let status = read("status");
    let (icon, color) = if status == "Charging" || status == "Full" {
        ('\u{F0084}', C_BAT)
    } else if capacity.parse::<u32>().is_ok_and(|c| c <= 15) {
        ('\u{F0079}', C_BAT_LOW)
    } else {
        ('\u{F0079}', C_BAT)
    };
    let text = if capacity.is_empty() { "?" } else { &capacity };
    Some(pill("battery", color, icon, &format!("{text}%")))
}

/// Kill any jay-status the same jay started before this one: a leftover from
/// before a config reload. Matching the parent keeps a copy run by hand in a
/// terminal from killing the real bar.
fn kill_older_instances() {
    // Fields after the parenthesised comm (which may contain spaces): the
    // parent pid is stat field 4 and the start time field 22.
    let stat = |pid: &str| -> Option<(String, u64)> {
        let stat = std::fs::read_to_string(format!("/proc/{pid}/stat")).ok()?;
        let fields: Vec<&str> = stat.rsplit_once(')')?.1.split_whitespace().collect();
        Some((fields.get(1)?.to_string(), fields.get(19)?.parse().ok()?))
    };
    let me = std::process::id().to_string();
    let Some((my_parent, my_start)) = stat(&me) else { return };
    let Ok(procs) = std::fs::read_dir("/proc") else { return };
    for entry in procs.flatten() {
        let pid = entry.file_name().to_string_lossy().into_owned();
        if pid == me || !pid.bytes().all(|b| b.is_ascii_digit()) {
            continue;
        }
        let comm = std::fs::read_to_string(format!("/proc/{pid}/comm")).unwrap_or_default();
        if comm.trim_end() != "jay-status" {
            continue;
        }
        if stat(&pid).is_some_and(|(parent, start)| parent == my_parent && start < my_start) {
            unsafe { kill(pid.parse().unwrap(), SIGKILL) };
        }
    }
}

/// Send a message on `tx` for every sink or source event, forever. pactl is
/// restarted if it exits (e.g. PipeWire restarting) and dies with us.
fn watch_audio(tx: mpsc::Sender<()>) {
    loop {
        let child = unsafe {
            Command::new(PACTL)
                .arg("subscribe")
                .stdout(Stdio::piped())
                .stderr(Stdio::null())
                .pre_exec(|| {
                    prctl(PR_SET_PDEATHSIG, SIGTERM);
                    Ok(())
                })
                .spawn()
        };
        if let Ok(mut child) = child {
            let lines = BufReader::new(child.stdout.take().unwrap()).lines();
            for line in lines.map_while(Result::ok) {
                if (line.contains(" sink ") || line.contains(" source ")) && tx.send(()).is_err() {
                    return;
                }
            }
            let _ = child.wait();
            // A server change can move the default sink; re-read once.
            let _ = tx.send(());
        }
        thread::sleep(Duration::from_secs(1));
    }
}

fn main() {
    kill_older_instances();

    let (tx, rx) = mpsc::channel();
    thread::spawn(move || watch_audio(tx));

    let mut out = std::io::stdout().lock();
    let mut emit = |line: &str| {
        // jay closed the pipe (reload or exit): nothing left to do.
        if writeln!(out, "{line}").and_then(|_| out.flush()).is_err() {
            std::process::exit(0);
        }
    };
    emit(r#"{"version":1}"#);
    emit("[");
    emit("[]");

    // CPU is diffed against the previous tick, averaging over the whole 2s.
    // Primed here so the first tick reports recent load, not the boot average.
    let mut prev_cpu = cpu_jiffies();
    let mut slow = Vec::new();
    let mut next_tick = Instant::now();

    loop {
        if Instant::now() >= next_tick {
            let cpu = cpu_jiffies();
            let (busy, total) = (cpu.0 - prev_cpu.0, cpu.1 - prev_cpu.1);
            prev_cpu = cpu;
            let cpu_pct = if total > 0 { busy * 100 / total } else { 0 };

            let now = local_now();
            // Four duod places: the fifth changes ~3x a second.
            let duod: String = format_duod(now.ms_of_day).chars().take(4).collect();

            slow.clear();
            slow.push(pill("cpu", C_CPU, '\u{F035B}', &format!("{cpu_pct:02}%")));
            slow.push(memory_block());
            slow.push(disk_block());
            slow.extend(battery_block());
            slow.push(pill("clock", C_DATE, '\u{F0E17}', &format!("{:02}-{:02}", now.month, now.day)));
            slow.push(pill("duod", C_DUOD, '\u{F051B}', &duod));
            slow.push(spacer());

            next_tick += TICK;
            if next_tick < Instant::now() {
                next_tick = Instant::now() + TICK; // suspended; don't catch up
            }
        }

        let mut blocks = vec![bt_block(), audio_block()];
        blocks.extend(slow.iter().cloned());
        emit(&format!(",[{}]", blocks.join(",")));

        match rx.recv_timeout(next_tick.saturating_duration_since(Instant::now())) {
            // Volume keys fire bursts of events; settle, then render once.
            Ok(()) => {
                thread::sleep(Duration::from_millis(10));
                while rx.try_recv().is_ok() {}
            }
            Err(RecvTimeoutError::Timeout) => {}
            // The watcher only returns if we are shutting down.
            Err(RecvTimeoutError::Disconnected) => thread::sleep(next_tick.saturating_duration_since(Instant::now())),
        }
    }
}
