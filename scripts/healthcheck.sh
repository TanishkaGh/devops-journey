#!/bin/bash

LOG_FILE="/tmp/healthcheck.log"
DATE=$(date)

echo "=== Health Check: $DATE ===" >> $LOG_FILE

check_service() {
    if systemctl is-active --quiet $1; then
        echo "OK: $1 is running" >> $LOG_FILE
    else
        echo "WARNING: $1 is stopped" >> $LOG_FILE
    fi
}

check_disk() {
    USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ $USAGE -gt 80 ]; then
        echo "WARNING: Disk usage is at $USAGE%" >> $LOG_FILE
    else
        echo "OK: Disk usage is at $USAGE%" >> $LOG_FILE
    fi
}

check_service nginx
check_service sshd
check_disk

echo "Health check complete. Results saved to $LOG_FILE"
