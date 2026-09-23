// Time-of-day units shared by duod, chron and jay-status.
//
// writers.writeRustBin compiles exactly one file with plain rustc, so there is
// no `mod` here: each consumer's .nix concatenates this file ahead of its own
// source. The tests at the bottom run as the `daytime` flake check
// (modules/packages/scripts.nix).
//
// Units, both fractions of a local day:
//   duod   base-12 digits -- "6" is noon, "60000" the same to five places
//          (the last place is ~0.35s). Digits 10 and 11 print as χ and ε.
//   chron  1/100 of a day (14.4 minutes), printed to five places as
//          "DD.D DD" -- noon is "50.0 00", the last place is 0.864s.
//
// All conversions are integer millisecond arithmetic, so exact values stay
// exact: duod 6 and chron 50 are 12:00:00, not 11:59:59.999.

// Not every consumer uses every function.
#![allow(dead_code)]

use std::process;
use std::time::{SystemTime, UNIX_EPOCH};

const DAY_MS: u64 = 86_400_000;

#[repr(C)]
struct Tm {
    tm_sec: i32,
    tm_min: i32,
    tm_hour: i32,
    tm_mday: i32,
    tm_mon: i32,
    tm_year: i32,
    tm_wday: i32,
    tm_yday: i32,
    tm_isdst: i32,
    tm_gmtoff: i64,
    tm_zone: *const i8,
}

extern "C" {
    fn localtime_r(timep: *const i64, result: *mut Tm) -> *mut Tm;
}

/// A local wall-clock instant: calendar date plus milliseconds since midnight.
struct Local {
    month: u32,
    day: u32,
    ms_of_day: u64,
}

fn local_from_unix_ms(unix_ms: i64) -> Local {
    let secs = unix_ms.div_euclid(1000);
    let ms = unix_ms.rem_euclid(1000) as u64;
    // SAFETY: localtime_r only writes into the Tm we own; an all-zero Tm
    // (null tm_zone) is a valid initial value.
    let tm = unsafe {
        let mut tm = std::mem::zeroed::<Tm>();
        localtime_r(&secs, &mut tm);
        tm
    };
    let secs_of_day = tm.tm_hour as u64 * 3600 + tm.tm_min as u64 * 60 + tm.tm_sec as u64;
    Local {
        month: tm.tm_mon as u32 + 1,
        day: tm.tm_mday as u32,
        // A leap second (tm_sec 60) must not push past the end of the day.
        ms_of_day: (secs_of_day * 1000 + ms).min(DAY_MS - 1),
    }
}

fn local_now() -> Local {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock before unix epoch");
    local_from_unix_ms(now.as_millis() as i64)
}

/// Parse a clock time into milliseconds since midnight.
///
/// Accepts HH:MM, HH:MM:SS and HH:MM:SS.fff. A fourth colon field
/// (HH:MM:SS:X) is each tool's historical input format; `fourth_to_ms`
/// converts it, since duod read it as nanoseconds and chron as tenths.
fn parse_clock(s: &str, fourth_to_ms: fn(u64) -> u64) -> Result<u64, String> {
    let bad = || format!("invalid time {s:?}: expected HH:MM[:SS[.fff]]");
    let num = |p: &str| -> Result<u64, String> {
        if p.is_empty() || !p.bytes().all(|b| b.is_ascii_digit()) || p.len() > 9 {
            return Err(bad());
        }
        Ok(p.parse().unwrap())
    };

    let parts: Vec<&str> = s.trim().split(':').collect();
    if !(2..=4).contains(&parts.len()) {
        return Err(bad());
    }
    let hour = num(parts[0])?;
    let minute = num(parts[1])?;

    let (second, mut ms) = match parts.get(2) {
        None => (0, 0),
        Some(p) => match p.split_once('.') {
            None => (num(p)?, 0),
            Some((sec, frac)) => {
                let frac_ms = if frac.is_empty() {
                    0
                } else {
                    // Keep milliseconds; pad "5" to "500", cut "1234" to "123".
                    let digits: String = format!("{frac:0<3}").chars().take(3).collect();
                    num(frac)?;
                    num(&digits)?
                };
                (num(sec)?, frac_ms)
            }
        },
    };
    if let Some(p) = parts.get(3) {
        if parts[2].contains('.') {
            return Err(bad());
        }
        ms = fourth_to_ms(num(p)?);
    }

    if hour > 23 || minute > 59 || second > 59 || ms > 999 {
        return Err(format!("time {s:?} is out of range"));
    }
    Ok((hour * 3600 + minute * 60 + second) * 1000 + ms)
}

/// Milliseconds since midnight as HH:MM:SS, with .fff only when non-zero.
fn format_clock(ms: u64) -> String {
    let secs = ms / 1000;
    let clock = format!("{:02}:{:02}:{:02}", secs / 3600, secs / 60 % 60, secs % 60);
    match ms % 1000 {
        0 => clock,
        frac => format!("{clock}.{frac:03}"),
    }
}

/// Integer division rounded to nearest, clamped inside the day.
fn round_into_day(numerator: u128, denominator: u128) -> u64 {
    let ms = (numerator * 2 + denominator) / (denominator * 2);
    (ms as u64).min(DAY_MS - 1)
}

const DUOD_DIGITS: [char; 12] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'χ', 'ε'];

/// Five base-12 places of the day fraction, truncated (a clock never rounds up).
fn format_duod(ms_of_day: u64) -> String {
    let mut numerator = ms_of_day * 12;
    (0..5)
        .map(|_| {
            let digit = DUOD_DIGITS[(numerator / DAY_MS) as usize];
            numerator = numerator % DAY_MS * 12;
            digit
        })
        .collect()
}

/// Base-12 day-fraction digits back to milliseconds since midnight.
/// Ten is χ, x, a or ↊; eleven is ε, e, b or ↋. A leading "." is allowed.
fn parse_duod(s: &str) -> Result<u64, String> {
    let digits = s.trim().strip_prefix('.').unwrap_or(s.trim());
    if digits.is_empty() {
        return Err("empty duod value".into());
    }
    let mut value: u128 = 0;
    let mut scale: u128 = 1;
    for (i, c) in digits.chars().enumerate() {
        let d = match c {
            '0'..='9' => c as u128 - '0' as u128,
            'χ' | 'x' | 'X' | 'a' | 'A' | '↊' => 10,
            'ε' | 'e' | 'E' | 'b' | 'B' | '↋' => 11,
            _ => return Err(format!("invalid duod digit {c:?} in {s:?}")),
        };
        // Past 20 places the extra digits are far below a millisecond.
        if i < 20 {
            value = value * 12 + d;
            scale *= 12;
        }
    }
    Ok(round_into_day(value * DAY_MS as u128, scale))
}

/// Five decimal places of the day fraction as "DD.D DD", truncated.
fn format_chron(ms_of_day: u64) -> String {
    let v = ms_of_day / 864; // 1/100000 of a day is 864 ms
    format!("{:02}.{} {:02}", v / 1000, v / 100 % 10, v % 100)
}

/// Chrons (a decimal count of hundredths of a day) back to milliseconds since
/// midnight. Whitespace is ignored, so "50.0 00" as printed reads back in.
fn parse_chron(s: &str) -> Result<u64, String> {
    let compact: String = s.chars().filter(|c| !c.is_whitespace()).collect();
    let (int, frac) = compact.split_once('.').unwrap_or((&compact, ""));
    let digits_ok = |p: &str| p.bytes().all(|b| b.is_ascii_digit());
    if (int.is_empty() && frac.is_empty()) || !digits_ok(int) || !digits_ok(frac) {
        return Err(format!("invalid chron value {s:?}: expected e.g. 50.0 00"));
    }
    let int = int.trim_start_matches('0');
    if int.len() > 2 {
        return Err(format!("chron value {s:?} is a day or more (max 99.999)"));
    }
    // Past 18 places the extra digits are far below a millisecond.
    let frac = &frac[..frac.len().min(18)];
    let value: u128 = format!("{int}{frac}").parse().unwrap_or(0);
    let scale = 10u128.pow(frac.len() as u32);
    Ok(round_into_day(value * 864_000, scale))
}

/// The whole command line of duod and chron, which differ only in their unit.
///
///   TOOL              the unit, now
///   TOOL -u UNIX_MS   the unit at a unix timestamp (iamb's timestamp_command)
///   TOOL HH:MM[:SS]   clock time to the unit
///   TOOL VALUE        the unit back to clock time
fn run_cli(
    name: &str,
    about: &str,
    example: &str,
    format: fn(u64) -> String,
    parse: fn(&str) -> Result<u64, String>,
    fourth_to_ms: fn(u64) -> u64,
) {
    let usage = || {
        format!(
            "usage: {name} [-u UNIX_MS | HH:MM[:SS[.fff]] | VALUE]\n\n{about}\n\n\
             \x20 {name}                print the current time\n\
             \x20 {name} -u UNIX_MS     convert a unix timestamp in milliseconds\n\
             \x20 {name} 12:00          convert a clock time to {name}\n\
             \x20 {name} {example:<14} convert {name} back to a clock time"
        )
    };
    let fail = |msg: String| -> ! {
        eprintln!("{name}: {msg}");
        process::exit(1);
    };

    let args: Vec<String> = std::env::args().skip(1).collect();
    let args: Vec<&str> = args.iter().map(String::as_str).collect();
    let out = match args.as_slice() {
        [] => format(local_now().ms_of_day),
        ["-h" | "--help"] => {
            println!("{}", usage());
            return;
        }
        ["-u" | "--unix-ms", ms] => match ms.parse() {
            Ok(ms) => format(local_from_unix_ms(ms).ms_of_day),
            Err(e) => fail(format!("invalid unix-ms {ms:?}: {e}")),
        },
        [time] if time.contains(':') => match parse_clock(time, fourth_to_ms) {
            Ok(ms) => format(ms),
            Err(e) => fail(e),
        },
        // Chron values are printed with a space, so accept them unquoted too.
        values if !values.is_empty() && !values[0].starts_with('-') => {
            match parse(&values.join(" ")) {
                Ok(ms) => format_clock(ms),
                Err(e) => fail(e),
            }
        }
        _ => fail(usage()),
    };
    println!("{out}");
}

#[cfg(test)]
mod tests {
    use super::*;

    const NOON: u64 = 43_200_000;

    #[test]
    fn duod_both_ways() {
        assert_eq!(format_duod(0), "00000");
        assert_eq!(format_duod(NOON), "60000");
        assert_eq!(format_duod(DAY_MS - 1), "εεεεε");
        assert_eq!(parse_duod("6"), Ok(NOON));
        assert_eq!(parse_duod("60000"), Ok(NOON));
        assert_eq!(parse_duod(".6"), Ok(NOON));
        assert_eq!(parse_duod("χ"), parse_duod("x"));
        assert_eq!(parse_duod("εεεεεεεεεεεεεεεεεεεεεεεε"), Ok(DAY_MS - 1));
        assert!(parse_duod("").is_err());
        assert!(parse_duod("6z").is_err());
        for ms in [0, 1234, NOON, 51_234_567, DAY_MS - 1] {
            let back = parse_duod(&format_duod(ms)).unwrap();
            assert!(back <= ms && ms - back < 348, "{ms} -> {back}");
        }
    }

    #[test]
    fn chron_both_ways() {
        assert_eq!(format_chron(0), "00.0 00");
        assert_eq!(format_chron(NOON), "50.0 00");
        assert_eq!(format_chron(DAY_MS - 1), "99.9 99");
        assert_eq!(parse_chron("50"), Ok(NOON));
        assert_eq!(parse_chron("50.0 00"), Ok(NOON));
        assert_eq!(parse_chron(".5"), Ok(432_000));
        assert_eq!(parse_chron("99.9999999"), Ok(DAY_MS - 1));
        assert!(parse_chron("100").is_err());
        assert!(parse_chron(".").is_err());
        assert!(parse_chron("5o").is_err());
        for ms in [0, 1234, NOON, 51_234_567, DAY_MS - 1] {
            let back = parse_chron(&format_chron(ms)).unwrap();
            assert!(back <= ms && ms - back < 864, "{ms} -> {back}");
        }
    }

    #[test]
    fn clock_parsing() {
        let ns = |x| x / 1_000_000;
        assert_eq!(parse_clock("12:00", ns), Ok(NOON));
        assert_eq!(parse_clock("12:00:00", ns), Ok(NOON));
        assert_eq!(parse_clock("12:00:00.5", ns), Ok(NOON + 500));
        assert_eq!(parse_clock("12:00:00.1239", ns), Ok(NOON + 123));
        assert_eq!(parse_clock("12:00:00:500000000", ns), Ok(NOON + 500));
        assert_eq!(parse_clock("12:00:00:5", |x| x * 100), Ok(NOON + 500));
        assert!(parse_clock("24:00", ns).is_err());
        assert!(parse_clock("12", ns).is_err());
        assert!(parse_clock("12:00:00.5:1", ns).is_err());
        assert!(parse_clock("12:-1", ns).is_err());
    }

    #[test]
    fn clock_formatting() {
        assert_eq!(format_clock(NOON), "12:00:00");
        assert_eq!(format_clock(NOON + 347), "12:00:00.347");
        assert_eq!(format_clock(DAY_MS - 1), "23:59:59.999");
    }
}
