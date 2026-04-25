#!/bin/bash
path="/etc/bwlimit"
case "$1" in
    show)
        totalRx=0
        totalTx=0
        for file in "$path/stat"/*; do
            . "$file"
            if echo "$file" | grep -q "\.tmp$"; then
                echo "*TEMPFILE"
            fi
            echo "From `date -d @$lstart --rfc-3339="second"`"
            echo "Rx $Rx"
            echo "Tx $Tx"
            echo ""
            totalRx=$((totalRx + Rx))
            totalTx=$((totalTx + Tx))
        done
        echo "Total Rx $totalRx"
        echo "Total Tx $totalTx"
        ;;
    daemon)
        lstart=`date -d "$(ps -p 1 -o lstart=)" +%s`
        totalRx=0
        totalTx=0
        for file in "$path/stat"/*; do
            [[ $file == "$path/stat/$lstart" ]] && continue
            [[ $file == "$path/stat/$lstart.tmp" ]] && continue
            . "$file"
            totalRx=$((totalRx + Rx))
            totalTx=$((totalTx + Tx))
        done
        while true; do
            current=`grep "INTERFACE:" /proc/net/dev`
            Rx="$(echo $current | awk '{print $2}')"
            Tx="$(echo $current | awk '{print $10}')"

            cat > "$path/stat/$lstart.tmp" <<EOF
lstart="$lstart"
Rx="$Rx"
Tx="$Tx"
EOF

            mv "$path/stat/$lstart.tmp" "$path/stat/$lstart"
            echo "Total Rx $((totalRx + Rx))"
            echo "Total Tx $((totalTx + Tx))"
            if (( METHOD >= LIMIT )); then
                /opt/bwlimit_exceed.sh
                systemctl disable bwlimit
                systemctl stop bwlimit
            fi
            sleep 10
        done
        ;;
esac
