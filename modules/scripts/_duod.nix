{pkgs, ...}:
pkgs.writeShellScriptBin "duod" ''
  s=""
  if [ $# -eq 0 ]; then
  s="$(date '+%H:%M:%S:%N')"
  else
  s="$1"
  fi


  IFS=":" read -ra parts <<< "$s"

  hour=''${parts[0]#0}
  hour=''${hour:-0}
  mins=''${parts[1]#0}
  mins=''${mins:-0}
  secs=''${parts[2]#0}
  secs=''${secs:-0}
  ms=''${parts[3]#0}
  ms=''${ms:-0}

  day=$(echo "($hour + (($mins + (($secs + ($ms / 1000000000)) / 60)) / 60)) / 24" | bc -l)
  rem=$(echo "$day * 12" | bc -l)
  p0=$(echo "$rem/1" | bc)
  rem=$(echo "($rem - $p0) * 12" | bc -l)
  p1=$(echo "$rem/1" | bc)
  rem=$(echo "($rem - $p1) * 12" | bc -l)
  p2=$(echo "$rem/1" | bc)
  rem=$(echo "($rem - $p2) * 12" | bc -l)
  p3=$(echo "$rem/1" | bc)
  rem=$(echo "($rem - $p3) * 12" | bc -l)
  p4=$(echo "$rem/1" | bc)

  declare -A digit
  digit=( [0]=0 [1]=1 [2]=2 [3]=3 [4]=4 [5]=5 [6]=6 [7]=7 [8]=8 [9]=9 [10]=χ [11]=ε )
  echo "''${digit[''$p0]}''${digit[''$p1]}''${digit[''$p2]}''${digit[''$p3]}''${digit[''$p4]}"
''
