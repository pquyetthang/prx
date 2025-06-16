#!/bin/bash

MAX=8

for i in $(seq 1 $MAX); do
  VM="proxy-vm-$i"

  # Xen kẽ vùng southeast2-b và southeast1-b
  if (( i % 2 == 1 )); then
    ZONE="asia-northeast2-a"
  else
    ZONE="asia-northeast1-a"
  fi

  gcloud compute ssh "$VM" \
    --zone="$ZONE" \
    --command="sudo cat /root/proxy.txt" \
    --ssh-flag="-o StrictHostKeyChecking=no" \
    --ssh-flag="-o UserKnownHostsFile=/dev/null" \
    --quiet
done
