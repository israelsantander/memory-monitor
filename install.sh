#!/bin/bash
#
# Installation script for memory-monitor daemon
# This script installs the memory monitor daemon and enables it as a systemd service
# Usage: sudo ./install.sh [--threshold=GB] [--interval=SECONDS]
#

# ANSI color codes for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
THRESHOLD=""
INTERVAL=""

# Process command line arguments
for arg in "$@"; do
  case $arg in
    --threshold=*)
      THRESHOLD="${arg#*=}"
      shift
      ;;
    --interval=*)
      INTERVAL="${arg#*=}"
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Make sure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error:${NC} This script must be run as root"
  echo "Please run: sudo $0"
  exit 1
fi

echo -e "${BLUE}Memory Monitor Daemon Installation${NC}"
echo "====================================="
echo

# Check for required files
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SCRIPT_FILE="${SCRIPT_DIR}/memory-monitor.sh"
SERVICE_FILE="${SCRIPT_DIR}/memory-monitor.service"

if [ ! -f "$SCRIPT_FILE" ]; then
  echo -e "${RED}Error:${NC} Cannot find memory-monitor.sh in the current directory"
  exit 1
fi

if [ ! -f "$SERVICE_FILE" ]; then
  echo -e "${RED}Error:${NC} Cannot find memory-monitor.service in the current directory"
  exit 1
fi

# Function to handle errors
handle_error() {
  echo -e "${RED}Error:${NC} $1"
  echo "Installation failed"
  exit 1
}

# Step 1: Copy the script to system directory
echo -e "${YELLOW}Step 1:${NC} Installing memory-monitor script..."
cp "$SCRIPT_FILE" /usr/local/bin/ || handle_error "Failed to copy memory-monitor.sh to /usr/local/bin/"
chmod +x /usr/local/bin/memory-monitor.sh || handle_error "Failed to set executable permissions"
echo -e "${GREEN}Success:${NC} Installed script to /usr/local/bin/memory-monitor.sh"

# Step 2: Copy the systemd service file
echo -e "${YELLOW}Step 2:${NC} Installing systemd service..."
cp "$SERVICE_FILE" /etc/systemd/system/ || handle_error "Failed to copy service file to /etc/systemd/system/"
echo -e "${GREEN}Success:${NC} Installed service file to /etc/systemd/system/memory-monitor.service"

# Step 3: Reload systemd to recognize the new service
echo -e "${YELLOW}Step 3:${NC} Reloading systemd daemon..."
systemctl daemon-reload || handle_error "Failed to reload systemd daemon"
echo -e "${GREEN}Success:${NC} Systemd daemon reloaded"

# Step 4: Enable the service to start on boot
echo -e "${YELLOW}Step 4:${NC} Enabling service to start on boot..."
systemctl enable memory-monitor.service || handle_error "Failed to enable service"
echo -e "${GREEN}Success:${NC} Service enabled to start on boot"

# Step 5: Configure the service if parameters were specified
if [ -n "$THRESHOLD" ] || [ -n "$INTERVAL" ]; then
  echo -e "${YELLOW}Step 5:${NC} Configuring service with custom parameters..."
  
  # Create directory if it doesn't exist
  mkdir -p /etc/systemd/system/memory-monitor.service.d/
  
  # Create or overwrite the override.conf file
  OVERRIDE_FILE="/etc/systemd/system/memory-monitor.service.d/override.conf"
  echo "[Service]" > "$OVERRIDE_FILE"
  echo "ExecStart=" >> "$OVERRIDE_FILE"
  
  # Build the ExecStart command with provided parameters
  EXEC_CMD="/usr/local/bin/memory-monitor.sh"
  [ -n "$THRESHOLD" ] && EXEC_CMD="$EXEC_CMD --threshold=$THRESHOLD"
  [ -n "$INTERVAL" ] && EXEC_CMD="$EXEC_CMD --interval=$INTERVAL"
  
  echo "ExecStart=$EXEC_CMD" >> "$OVERRIDE_FILE"
  
  # Reload daemon to apply changes
  systemctl daemon-reload
  
  echo -e "${GREEN}Success:${NC} Service configured with custom parameters"
  [ -n "$THRESHOLD" ] && echo "          - Memory threshold: ${THRESHOLD}GB"
  [ -n "$INTERVAL" ] && echo "          - Check interval: ${INTERVAL} seconds"
fi

# Step 6: Start the service
echo -e "${YELLOW}Step 6:${NC} Starting memory-monitor service..."
systemctl start memory-monitor.service
if [ $? -ne 0 ]; then
  echo -e "${RED}Warning:${NC} Failed to start service. Check status with: sudo systemctl status memory-monitor.service"
else
  echo -e "${GREEN}Success:${NC} Service started successfully"
fi

# Step 7: Create or check log file
LOG_FILE="/var/log/memory-monitor.log"
touch "$LOG_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
  echo -e "${YELLOW}Notice:${NC} Could not create log file at $LOG_FILE"
  echo "          The service will use /tmp/memory-monitor.log instead"
else
  echo -e "${GREEN}Success:${NC} Log file created at $LOG_FILE"
fi

# Display status and next steps
echo
echo -e "${BLUE}Installation Complete!${NC}"
echo "====================================="
echo
echo "The memory-monitor daemon has been installed and started."
echo "By default, it will monitor for processes using more than 20GB of memory."
echo
echo -e "You can check the service status with: ${YELLOW}sudo systemctl status memory-monitor.service${NC}"
echo -e "View logs with: ${YELLOW}sudo tail -f $LOG_FILE${NC}"
echo
echo "To customize settings, you can either:"
echo "1. Edit the script directly: sudo nano /usr/local/bin/memory-monitor.sh"
echo "2. Override service options: sudo systemctl edit memory-monitor.service"
echo
echo "Thank you for installing the Memory Monitor Daemon!"
exit 0
