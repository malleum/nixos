{pkgs, ...}:
pkgs.writers.writePython3Bin "cin" {} ''
  from datetime import datetime
  end_date = datetime(2025, 10, 14)
  current_time = datetime.now()
  time_difference = (end_date - current_time).total_seconds()
  print(f"{(time_difference / 864):.3f}")
''
