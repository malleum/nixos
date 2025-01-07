{pkgs, ...}:
pkgs.writeShellScriptBin "ktv" ''
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
    rem=$(echo "$day * 20" | bc -l)
    p0=$(echo "$rem/1" | bc)
    rem=$(echo "($rem - $p0) * 20" | bc -l)
    p1=$(echo "$rem/1" | bc)
    rem=$(echo "($rem - $p1) * 20" | bc -l)
    p2=$(echo "$rem/1" | bc)
    rem=$(echo "($rem - $p2) * 20" | bc -l)
    p3=$(echo "$rem/1" | bc)

    declare -A digit
    digit=( [0]=𝋀 [1]=𝋁 [2]=𝋂 [3]=𝋃 [4]=𝋄 [5]=𝋅 [6]=𝋆 [7]=𝋇 [8]=𝋈 [9]=𝋉 [10]=𝋊 [11]=𝋋 [12]=𝋌 [13]=𝋍 [14]=𝋎 [15]=𝋏 [16]=𝋐 [17]=𝋑 [18]=𝋒 [19]=𝋓 )
    echo "''${digit[''$p0]} ''${digit[''$p1]} ''${digit[''$p2]} ''${digit[''$p3]}"
''
