#!/bin/bash
# EC2 Automation: Monitoring, Docker Setup, GitHub Push
# Author: Your Name

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR="$HOME/linux-bash-scripts/logs"
mkdir -p "$LOG_DIR"

echo "=== Starting EC2 Automation ==="

# -----------------------------
# 1. Update & Install Docker
# -----------------------------
echo "Updating system and installing Docker..."
sudo yum update -y
sudo yum install -y docker git
sudo systemctl enable docker
sudo systemctl start docker

# Pull a sample app (Nginx container)
echo "Pulling Nginx Docker image..."
sudo docker pull nginx:latest
sudo docker run -d -p 80:80 --name nginx_demo nginx:latest

# -----------------------------
# 2. Collect Metrics
# -----------------------------
echo "Collecting system metrics..."
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
MEM=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
DISK=$(df -h | awk '$NF=="/"{printf "%s", $5}')

METRICS_FILE="$LOG_DIR/metrics_$TIMESTAMP.log"
echo "CPU Usage: $CPU" > $METRICS_FILE
echo "Memory Usage: $MEM" >> $METRICS_FILE
echo "Disk Usage: $DISK" >> $METRICS_FILE
echo "Metrics saved to $METRICS_FILE"

# -----------------------------
# 3. GitHub Commit & Push
# -----------------------------
cd $HOME/linux-bash-scripts
git add logs/metrics_$TIMESTAMP.log
git commit -m "Auto backup: $TIMESTAMP"
git push origin main

echo "Automation complete! Metrics logged, Docker running, and pushed to GitHub."
