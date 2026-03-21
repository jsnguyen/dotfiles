#!/bin/bash

# CPU usage
cpu=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s}')

# RAM
ram=$(vm_stat | awk '
  /Pages active/ {a=$3}
  /Pages wired/ {w=$4}
  /Pages free/ {f=$3}
  END {total=a+w+f; printf "%.0f", (a+w)/total*100}')

# Disk
disk=$(df -h / | awk 'NR==2 {print $5}')

# Battery
batt=$(pmset -g batt | grep -o '[0-9]*%' | head -1)

echo "CPU:${cpu}% | RAM:${ram}% | Disk:${disk} | Batt:${batt}"
