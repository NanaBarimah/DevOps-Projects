#!/bin/bash
# server-stats.sh - A script to collect server performance statistics
cpu_usage() {
    if command -v mpstat > /dev/null 2>&1; then
        # mpstat: Report CPU usage - subtract idle percentage from 100
        mpstat 1 1 | awk '/Average/ { idle=$NF; printf("%.2f%%", 100 - idle) }'
    else
        # top: parse idle value
        top -bn1 | awk '/Cpu\(s\)/ { idle=$8; printf("%.2f%%", 100 - idle) }'
    fi
}

# Get total memory usage
memory_usage() {
    free -m | awk 'NR==2 { used=$3; total=$2; free=$4; printf("Used: %dMB (%.2f%%), Free: %dMB (%.2f%%)", used, used*100/total, free, free*100/total) }'
}

# Get total disk usage for root (/)
disk_usage() {
    df -h / | awk 'NR==2 { fs=$1; used=$3; total=$2; pct=$5; printf("%s - Used: %s/%s (%s)", fs, used, total, pct) }'
}

# Print header
echo "=== Server Performance Statistics ==="

echo -n "CPU Usage: "; cpu_usage

echo -n " Memory Usage: "; memory_usage

echo -n " Disk Usage: "; disk_usage

# Top processes by CPU
echo -e "\nTop 5 processes by CPU usage:"
ps -eo pid,comm,pcpu --sort=-pcpu | head -n 6

# Top processes by memory
echo -e "\nTop 5 processes by memory usage:"
ps -eo pid,comm,pmem --sort=-pmem | head -n 6

#OS version
if [ -f /etc/os-release ]; then
    os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    echo -e "\nOS Version: $os"
fi

# Uptime and load average
echo -e "Uptime & Load Average: $(uptime --pretty) Load: $(uptime | awk -F 'load average:' '{ print $2 }')"

# Logged in users
echo -e "\nLogged in users:"; who

# Failed login attempts (requires auth log access)
if [ -r /var/log/auth.log ]; then
    fails=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null)
    echo -e "\nFailed login attempts: $fails"
fi