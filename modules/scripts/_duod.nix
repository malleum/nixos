{pkgs, ...}:
pkgs.writers.writeRustBin "duod" {}
/*
rust
*/
''
  use std::env;
  use std::process;
  use std::time::{SystemTime, UNIX_EPOCH};

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

  const DIGIT_MAP: [&str; 12] = [
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "χ", "ε",
  ];

  fn calculate_duod(hour: u32, minute: u32, second: u32, millisecond: u32) {
      let total_ms =
          (hour as u64 * 3600 + minute as u64 * 60 + second as u64) * 1000
          + millisecond as u64;
      let day_ms: u64 = 86_400_000;

      let mut buf = String::with_capacity(10);
      let mut numerator = total_ms * 12;

      for _ in 0..5 {
          let digit = (numerator / day_ms) as usize;
          buf.push_str(DIGIT_MAP[digit]);
          numerator = (numerator % day_ms) * 12;
      }

      println!("{}", buf);
  }

  fn local_from_unix(secs: i64) -> (u32, u32, u32) {
      unsafe {
          let mut tm = std::mem::zeroed::<Tm>();
          localtime_r(&secs, &mut tm);
          (tm.tm_hour as u32, tm.tm_min as u32, tm.tm_sec as u32)
      }
  }

  fn parse_or_exit(s: &str) -> u32 {
      match s.parse() {
          Ok(v) => v,
          Err(e) => {
              eprintln!("Error parsing time string: {}", e);
              process::exit(1);
          }
      }
  }

  fn main() {
      let args: Vec<String> = env::args().collect();

      if args.len() >= 3 && (args[1] == "-u" || args[1] == "--unix-ms") {
          let unix_ms: i64 = match args[2].parse() {
              Ok(v) => v,
              Err(e) => {
                  eprintln!("Error parsing unix-ms: {}", e);
                  process::exit(1);
              }
          };
          let secs = unix_ms.div_euclid(1000);
          let ms = unix_ms.rem_euclid(1000) as u32;
          let (h, m, s) = local_from_unix(secs);
          calculate_duod(h, m, s, ms);
      } else if args.len() >= 2 && !args[1].starts_with('-') {
          let parts: Vec<&str> = args[1].split(':').collect();
          if parts.len() != 4 {
              eprintln!(
                  "Error parsing time string: Invalid time string format. \
                   Expected HH:MM:SS:NS."
              );
              process::exit(1);
          }
          let hour = parse_or_exit(parts[0]);
          let minute = parse_or_exit(parts[1]);
          let second = parse_or_exit(parts[2]);
          let nanosecond = parse_or_exit(parts[3]);
          let millisecond = (nanosecond / 1000) / 1000;
          calculate_duod(hour, minute, second, millisecond);
      } else if args.len() == 1 {
          let duration = SystemTime::now()
              .duration_since(UNIX_EPOCH)
              .expect("system clock before unix epoch");
          let secs = duration.as_secs() as i64;
          let ms = duration.subsec_millis();
          let (h, m, s) = local_from_unix(secs);
          calculate_duod(h, m, s, ms);
      } else {
          eprintln!(
              "usage: duod [-u UNIX_MS] [HH:MM:SS:NS]\n\n\
               Calculate 'duod' time. 'Duod' time is a base-12 \
               representation of the fraction of a day."
          );
          process::exit(1);
      }
  }
''
