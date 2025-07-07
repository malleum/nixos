{pkgs, ...}:
pkgs.writers.writeFishBin "disfiles" {}
# fish
''
  #!/usr/bin/env fish
  function disfiles
      set output ""
      if set -q argv[1]
          set files (fd --type f --glob $argv[1] | sort)
      else
          set files (fd --type f | sort)
      end
      for file in $files
          set output "$output$file\n\n"
          set output "$output```\n"
          set output "$output"(cat $file)"\n"
          set output "$output```\n\n"
      end

      echo -e $output | wl-copy

  end

  disfiles $argv
''
