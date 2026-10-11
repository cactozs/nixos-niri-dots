#!/usr/bin/env bash

# CPU usage
read -r cpu user nice system idle iowait irq softirq steal rest < /proc/stat

total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle1=$((idle + iowait))

sleep 0.1

read -r cpu user nice system idle iowait irq softirq steal rest < /proc/stat

total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle2=$((idle + iowait))

total_diff=$((total2 - total1))
idle_diff=$((idle2 - idle1))

if (( total_diff > 0 )); then
    cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
else
    cpu_usage=0
fi

# Temperature icon by threshold
temp_icon() {
    local t="$1"

    [[ "$t" =~ ^[0-9]+$ ]] || { echo ""; return; }

    if (( t <= 30 )); then
        echo ""
    elif (( t <= 40 )); then
        echo ""
    elif (( t <= 55 )); then
        echo ""
    elif (( t <= 65 )); then
        echo ""
    else
        echo ""
    fi
}

# CPU temperature
cpu_temp="N/A"
cpu_icon=""

for zone in /sys/class/thermal/thermal_zone*/temp; do
    if [[ -r "$zone" ]]; then
        temp=$(cat "$zone")
        if (( temp > 20000 && temp < 110000 )); then
            cpu_temp_c=$((temp / 1000))
            cpu_icon=$(temp_icon "$cpu_temp_c")
            cpu_temp="${cpu_temp_c}󰔄"
            break
        fi
    fi
done

# GPU
gpu_temp="N/A"
gpu_icon=""
gpu_usage="N/A"

if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_data=$(nvidia-smi \
        --query-gpu=temperature.gpu,utilization.gpu \
        --format=csv,noheader,nounits 2>/dev/null)

    if [[ -n "$gpu_data" ]]; then
        gpu_temp_c=$(echo "$gpu_data" | awk -F', ' '{print $1}' | tr -d ' ')
        gpu_icon=$(temp_icon "$gpu_temp_c")
        gpu_temp="${gpu_temp_c}󰔄"
        gpu_usage=$(echo "$gpu_data" | awk -F', ' '{print $2 "%"}')
    fi
fi

# RAM
mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

mem_used=$((mem_total - mem_available))
ram_usage=$((100 * mem_used / mem_total))

ram_used=$(awk "BEGIN {printf \"%.1f GiB\", $mem_used / 1024 / 1024}")
ram_total=$(awk "BEGIN {printf \"%.1f GiB\", $mem_total / 1024 / 1024}")

# Network
rx1=$(awk 'NR>2 {sum += $2} END {print sum+0}' /proc/net/dev)
tx1=$(awk 'NR>2 {sum += $10} END {print sum+0}' /proc/net/dev)

sleep 0.1

rx2=$(awk 'NR>2 {sum += $2} END {print sum+0}' /proc/net/dev)
tx2=$(awk 'NR>2 {sum += $10} END {print sum+0}' /proc/net/dev)

rx_rate=$(( (rx2 - rx1) * 10 ))
tx_rate=$(( (tx2 - tx1) * 10 ))

format_speed() {
    local bytes="$1"

    if (( bytes >= 1048576 )); then
        awk "BEGIN {printf \"%.1f MiB/s\", $bytes / 1048576}"
    elif (( bytes >= 1024 )); then
        awk "BEGIN {printf \"%.1f KiB/s\", $bytes / 1024}"
    else
        echo "${bytes} B/s"
    fi
}

rx_speed=$(format_speed "$rx_rate")
tx_speed=$(format_speed "$tx_rate")

# Waybar output
tooltip="\
CPU
${cpu_icon:+$cpu_icon }Temperature: $cpu_temp
Usage:       $cpu_usage%

GPU
${gpu_icon:+$gpu_icon }Temperature: $gpu_temp
Usage:       $gpu_usage

Memory
Used:        $ram_used / $ram_total
Usage:       $ram_usage%

Network
↓ $rx_speed
↑ $tx_speed"

jq -cn \
    --arg text "" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip}'
