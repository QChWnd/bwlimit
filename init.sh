#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 interface rx|tx|both limit(Byte)"
    exit 1
fi
mkdir -p /etc/bwlimit/stat
curl -fL -o /usr/bin/bwlimit "https://raw.githubusercontent.com/QChWnd/bwlimit/master/bwlimit.sh"
sed -i "s/INTERFACE/$1/g" /usr/bin/bwlimit
case "$2" in
    rx)
        sed -i "s/METHOD/totalRx + Rx/g" /usr/bin/bwlimit
        ;;
    tx)
        sed -i "s/METHOD/totalTx + Tx/g" /usr/bin/bwlimit
        ;;
    both)
        sed -i "s/METHOD/totalRx + Rx + totalTx + Tx/g" /usr/bin/bwlimit
        ;;
esac
sed -i "s/LIMIT/$3/g" /usr/bin/bwlimit
chmod +x /usr/bin/bwlimit
cat > /etc/systemd/system/bwlimit.service << EOF
[Unit]
Description=bwlimit
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
Type=simple
User=root
Restart=always
RestartSec=5
ExecStart=/usr/bin/bwlimit daemon
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable bwlimit
systemctl start bwlimit
