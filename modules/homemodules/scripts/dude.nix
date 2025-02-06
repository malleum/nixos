{pkgs, ...}:
pkgs.writeShellScriptBin "dude" ''
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
    digit=( [0]=𝋀 [1]=𝋁 [2]=𝋂 [3]=𝋃 [4]=\( [5]=\(𝋁 [6]=\(𝋂 [7]=\(𝋃 [8]=\(\) [9]=\(𝋁\) [10]=\(𝋂\) [11]=\(𝋃\) )
    echo "''${digit[''$p0]} ''${digit[''$p1]} ''${digit[''$p2]} ''${digit[''$p3]} ''${digit[''$p4]}"
''
