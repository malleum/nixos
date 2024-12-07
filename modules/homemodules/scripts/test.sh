#!/usr/bin/env bash


s=""
if [ $# -eq 0 ]; then
s="$(date '+%H:%M:%S:%1N')"
else
s="$1"
fi


IFS=":" read -ra parts <<< "$s"

hour=${parts[0]#0}
mins=${parts[1]#0}
seconds=${parts[2]#0}
ms=${parts[3]#0}

day=$(echo "($hour + (($mins + (($seconds + ($ms / 1000)) / 60)) / 60)) / 24" | bc -l)
first=$(echo "($day * 20)/1" | bc)
second=$(echo "(($day * 20 - $first) * 20)/1" | bc)
third=$(echo "(((($day * 20 - $first) * 20) - $second) * 20)/1" | bc)
forth=$(echo "(((((($day * 20 - $first) * 20) - $second) * 20) - $third) * 20)/1" | bc)
echo "$first $second $third $forth"
