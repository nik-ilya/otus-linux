#!/bin/bash


CLK_TCK=$(getconf CLK_TCK) 

(
echo "PID|TTY|STAT|TIME|COMMAND";


for pid in `ls /proc | grep -E "^[0-9]*$"`; do
    if [ -d /proc/$pid ]; then
        stat=$(< /proc/$pid/stat)
        tty=$(echo "$stat" | awk '{print $7}')
        state=$(echo "$stat" | awk '{print $3}')
        comm=$(echo "$stat" | awk  '{print $2}')
        utime=$(echo "$stat" | awk  '{print $14}')
        stime=$(echo "$stat" | awk  '{print $15}')
       
        total_time=$((utime + stime))
        time=$((total_time / CLK_TCK))
            mtime=$(($time/60))
	    stime=$(($time - $mtime*60))

        echo "${pid}|${tty}|${state}|${mtime}:${stime}|${comm}"
    fi
done
)  | sort -n | column -t -s "|"

