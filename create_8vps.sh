#!/bin/bash

max=8

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
    --metadata startup-script-url=https://raw.githubusercontent.com/khanhhd1987/ggclsocks5/main/setup.sh \
    --quiet
done