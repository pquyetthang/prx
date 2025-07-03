#!/bin/bash
max=8
# Tạo startup script inline
STARTUP_SCRIPT='#!/bin/bash
USERNAME="user_$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)"
PORT=$((RANDOM % 20000 + 20000))
apt update -y && apt install -y dante-server curl || {
    echo "❌ Không cài được dante-server. Hãy chạy script bằng quyền sudo/root."
    exit 1
}
useradd -M $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
IFACE=$(ip route | grep default | awk '\''{print $5}'\'')
IP=$(curl -s ifconfig.me)
cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log
internal: 0.0.0.0 port = $PORT
external: $IFACE
method: username none
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect
}
pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: connect disconnect
}
EOF
touch /var/log/danted.log
chown nobody:nogroup /var/log/danted.log
systemctl restart danted
systemctl enable danted
PROXY="socks5://$USERNAME:$PASSWORD@$IP:$PORT"
echo "$PROXY" | tee /root/proxy.txt'

# Danh sách zones Brazil
zones=("southamerica-east1-a" "southamerica-east1-b" "southamerica-east1-c")

for ((i=1; i<=max; i++)); do
  # Rotate qua các zones Brazil
  zone_index=$(( (i-1) % 3 ))
  zone="${zones[$zone_index]}"
  
  echo "Creating proxy-vm-$i in $zone (São Paulo, Brazil)"
  gcloud compute instances create proxy-vm-$i \
    --zone="$zone" \
    --machine-type=e2-micro \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --tags=http-server,https-server,socks5-proxy \
    --can-ip-forward \
    --no-restart-on-failure \
    --metadata startup-script="$STARTUP_SCRIPT" \
    --quiet
done

echo "✅ Đã tạo $max VPS tại Brazil (São Paulo)"
echo "Chờ 2-3 phút để các VPS khởi động và cài đặt proxy..."
echo "Để lấy thông tin proxy, chạy lệnh:"
echo "gcloud compute ssh proxy-vm-1 --zone=southamerica-east1-a --command='cat /root/proxy.txt'"