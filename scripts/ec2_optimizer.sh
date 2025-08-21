#!/bin/bash
# EC2 Resource Optimization Script
# Author: Your Name
# Description: Monitors EC2 resources, logs metrics, suggests optimizations,
#              pushes logs to GitHub, supports multi-EC2, and sends Slack notifications.

# -----------------------------
# Config
# -----------------------------
LOG_DIR="$HOME/linux-bash-scripts/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/metrics_$TIMESTAMP.log"

# Slack Webhook (optional, replace with your webhook URL)
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# EC2 hosts to monitor
EC2_HOSTS=("localhost")  # Add more SSH shortcuts if needed
# Thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=85

# -----------------------------
# Functions
# -----------------------------

monitor_resources() {
    echo "Collecting system metrics from $1..."
    CPU=$(ssh -o StrictHostKeyChecking=no $host "top -bn1 | grep 'Cpu(s)' | awk '{print \$2+\$4}'")
    MEM=$(ssh -o StrictHostKeyChecking=no $host "free -m | awk 'NR==2{printf \"%.2f%%\", \$3*100/\$2 }'")
    DISK=$(ssh -o StrictHostKeyChecking=no $host "df -h | awk '\$NF==\"/\"{printf \"%s\", \$5}'")
    NET_IN=$(ssh $1 "cat /sys/class/net/\$(ip route show default | awk '/default/ {print \$5}')/statistics/rx_bytes")
    NET_OUT=$(ssh $1 "cat /sys/class/net/\$(ip route show default | awk '/default/ {print \$5}')/statistics/tx_bytes")

    echo "=== Metrics ($TIMESTAMP) for $1 ===" >> $LOG_FILE
    echo "CPU Usage: $CPU%" >> $LOG_FILE
    echo "Memory Usage: $MEM" >> $LOG_FILE
    echo "Disk Usage: $DISK" >> $LOG_FILE
    echo "Network In: $NET_IN bytes" >> $LOG_FILE
    echo "Network Out: $NET_OUT bytes" >> $LOG_FILE
}

optimize_resources() {
    echo "Analyzing resource usage for optimization..."
    OPTIMIZE_LOG="$LOG_DIR/optimization_$TIMESTAMP.log"
    touch $OPTIMIZE_LOG

    for host in "${EC2_HOSTS[@]}"; do
        CPU_VAL=$(echo $CPU | awk '{print int($1)}')
        MEM_VAL=$(echo $MEM | awk '{print int($1)}')
        DISK_VAL=$(echo $DISK | sed 's/%//')

        echo "=== Optimization Suggestions ($TIMESTAMP) for $host ===" >> $OPTIMIZE_LOG

        MESSAGE=""

        if [ "$CPU_VAL" -gt "$CPU_THRESHOLD" ]; then
            echo "High CPU usage detected ($CPU_VAL%) on $host." >> $OPTIMIZE_LOG
            MESSAGE+="High CPU usage ($CPU_VAL%) on $host. "
        else
            echo "CPU usage normal ($CPU_VAL%) on $host." >> $OPTIMIZE_LOG
        fi

        if [ "$MEM_VAL" -gt "$MEM_THRESHOLD" ]; then
            echo "High Memory usage detected ($MEM_VAL%) on $host." >> $OPTIMIZE_LOG
            MESSAGE+="High Memory usage ($MEM_VAL%) on $host. "
        else
            echo "Memory usage normal ($MEM_VAL%) on $host." >> $OPTIMIZE_LOG
        fi

        if [ "$DISK_VAL" -gt "$DISK_THRESHOLD" ]; then
            echo "High Disk usage detected ($DISK_VAL%) on $host." >> $OPTIMIZE_LOG
            MESSAGE+="High Disk usage ($DISK_VAL%) on $host. "
        else
            echo "Disk usage normal ($DISK_VAL%) on $host." >> $OPTIMIZE_LOG
        fi

        # Send Slack notification if any threshold exceeded
        if [ -n "$MESSAGE" ] && [ "$SLACK_WEBHOOK_URL" != "" ]; then
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"Optimization Alert: $MESSAGE\"}" $SLACK_WEBHOOK_URL
        fi
    done
    echo "Optimization suggestions saved to $OPTIMIZE_LOG"
}

push_to_github() {
    REPO_DIR="$HOME/linux-bash-scripts"
    cd $REPO_DIR

    # Auto-clone if repo doesn't exist
    if [ ! -d "$REPO_DIR/.git" ]; then
        git clone https://github.com/DevOpsAvatar/linux-bash-scripts.git $REPO_DIR
    fi

    git add logs/metrics_$TIMESTAMP.log logs/optimization_$TIMESTAMP.log
    git commit -m "EC2 metrics & optimization logs: $TIMESTAMP"
    git push origin main
    echo "Logs pushed to GitHub."
}

# -----------------------------
# CLI Menu
# -----------------------------
case $1 in
    monitor)
        for host in "${EC2_HOSTS[@]}"; do
            monitor_resources $host
        done
        ;;
    optimize)
        for host in "${EC2_HOSTS[@]}"; do
            monitor_resources $host
        done
        optimize_resources
        ;;
    report)
        for host in "${EC2_HOSTS[@]}"; do
            monitor_resources $host
        done
        optimize_resources
        push_to_github
        ;;
    *)
        echo "Usage: $0 {monitor|optimize|report}"
        echo "  monitor  -> Collect EC2 metrics for all hosts"
        echo "  optimize -> Analyze and suggest optimizations"
        echo "  report   -> Collect metrics, optimize, and push logs to GitHub"
        ;;
esac
