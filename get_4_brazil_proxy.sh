#!/bin/bash
MAX=4
zones=("southamerica-east1-a" "southamerica-east1-b" "southamerica-east1-c")

for i in $(seq 1 $MAX); do
  VM="proxy-vm-$i"
  # Rotate qua các zones Brazil
  zone_index=$(( (i-1) % 3 ))
  ZONE="${zones[$zone_index]}"
  
  gcloud compute ssh "$VM" \
    --zone="$ZONE" \
    --command="sudo cat /root/proxy.txt" \
    --ssh-flag="-o StrictHostKeyChecking=no" \
    --ssh-flag="-o UserKnownHostsFile=/dev/null" \
    --quiet
done
