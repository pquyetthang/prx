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

for ((i=1; i<=max; i++)); do
  if (( i % 2 == 1 )); then
    zone="asia-northeast2-a"  # Osaka
  else
    zone="asia-northeast1-a"  # Tokyo
  fi

  echo "Creating proxy-vm-$i in $zone"
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
