#!/bin/bash

# memory-monitor.sh - Monitors and kills processes using more than 20GB of memory
# 
# Usage: ./memory-monitor.sh [--dry-run] [--interval=SECONDS] [--threshold=GB]
#   --dry-run      Don't actually kill processes, just log what would be killed
#   --interval     How often to check memory usage (default: 60 seconds)
#   --threshold    Memory threshold in GB (default: 20)

DRY_RUN=false
CHECK_INTERVAL=60
THRESHOLD_GB=20
LOG_FILE="/var/log/memory-monitor.log"

# Process command line arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --interval=*)
      CHECK_INTERVAL="${arg#*=}"
      shift
      ;;
    --threshold=*)
      THRESHOLD_GB="${arg#*=}"
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Make sure we can write to the log file
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/memory-monitor.log"
echo "$(date): Memory monitor started. Threshold: ${THRESHOLD_GB}GB, Interval: ${CHECK_INTERVAL}s, Dry run: ${DRY_RUN}" >> "$LOG_FILE"

# Convert threshold to KB for comparison with ps output
THRESHOLD_KB=$((THRESHOLD_GB * 1024 * 1024))

# Main monitoring loop
while true; do
  # Get list of processes with memory usage in KB (RSS)
  # Format: PID USERNAME RSS COMMAND
  PROCESSES=$(ps -eo pid,user,rss,comm --no-headers)
  
  # Check each process
  echo "$PROCESSES" | while read -r PID USER RSS COMMAND; do
    # Skip processes with no RSS value or non-numeric values
    [[ "$RSS" =~ ^[0-9]+$ ]] || continue
    
    # Convert RSS to GB for logging
    RSS_GB=$(echo "scale=2; $RSS / 1024 / 1024" | bc)
    
    # Check if memory usage exceeds threshold
    if [ "$RSS" -gt "$THRESHOLD_KB" ]; then
      # Log the detection
      echo "$(date): Process $PID ($COMMAND) owned by $USER is using ${RSS_GB}GB of memory, exceeding threshold of ${THRESHOLD_GB}GB" >> "$LOG_FILE"
      
      # Kill the process if not in dry run mode
      if [ "$DRY_RUN" = false ]; then
        # Send SIGTERM first for clean shutdown
        kill -15 "$PID" 2>/dev/null
        echo "$(date): Sent SIGTERM to process $PID ($COMMAND)" >> "$LOG_FILE"
        
        # Wait 5 seconds then check if it's still running
        sleep 5
        if ps -p "$PID" > /dev/null; then
          # Process still running, force kill with SIGKILL
          kill -9 "$PID" 2>/dev/null
          echo "$(date): Process $PID didn't terminate gracefully, sent SIGKILL" >> "$LOG_FILE"
        fi
      else
        echo "$(date): Would kill process $PID ($COMMAND) [DRY RUN]" >> "$LOG_FILE"
      fi
    fi
  done
  
  # Wait for next check interval
  sleep "$CHECK_INTERVAL"
done
