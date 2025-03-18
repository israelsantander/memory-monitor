# Memory Monitor Daemon

A simple and lightweight daemon for Ubuntu systems that monitors memory usage of running processes and automatically terminates any process consuming more than a configurable threshold (default: 20GB).

## Features

- Continuously monitors all system processes for memory consumption
- Configurable memory threshold (default: 20GB)
- Configurable check interval (default: 60 seconds)
- Graceful termination with SIGTERM before using SIGKILL
- Comprehensive logging of all actions
- Dry-run mode for testing without killing processes
- Runs as a systemd service for automatic startup and recovery

## Installation

### Automatic Installation

1. Clone this repository or download the files:
   ```bash
   git clone https://github.com/yourusername/memory-monitor.git
   cd memory-monitor
   ```

2. Run the installation script:
   ```bash
   sudo ./install.sh
   ```

### Manual Installation

1. Copy the script to the system:
   ```bash
   sudo cp memory-monitor.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/memory-monitor.sh
   ```

2. Install the systemd service:
   ```bash
   sudo cp memory-monitor.service /etc/systemd/system/
   ```

3. Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable memory-monitor.service
   sudo systemctl start memory-monitor.service
   ```

## Usage

### Basic Usage

Once installed and started, the daemon runs automatically in the background with default settings:
- Memory threshold: 20GB
- Check interval: 60 seconds

### Configuration

There are several ways to modify the configuration:

#### Method 1: Edit the systemd service override

```bash
sudo systemctl edit memory-monitor.service
```

Add these lines to change parameters:

```ini
[Service]
ExecStart=
ExecStart=/usr/local/bin/memory-monitor.sh --threshold=25 --interval=120
```

Then restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart memory-monitor.service
```

#### Method 2: Edit the script directly

You can edit the default values at the top of the script:

```bash
sudo nano /usr/local/bin/memory-monitor.sh
```

Find and modify these lines:

```bash
CHECK_INTERVAL=60
THRESHOLD_GB=20
```

Save and restart the service:

```bash
sudo systemctl restart memory-monitor.service
```

### Command Line Options

If running the script manually, you can use these command line options:

- `--dry-run`: Log what would be killed without actually terminating processes
- `--interval=SECONDS`: How often to check memory usage (default: 60 seconds)
- `--threshold=GB`: Memory threshold in GB (default: 20)

Example:
```bash
./memory-monitor.sh --dry-run --threshold=15 --interval=30
```

### Monitoring and Logs

Check service status:
```bash
sudo systemctl status memory-monitor.service
```

View logs:
```bash
sudo tail -f /var/log/memory-monitor.log
```

## How It Works

The daemon works by:

1. Periodically running `ps` commands to get memory usage (RSS) for all processes
2. Comparing each process's memory usage against the configured threshold
3. For processes exceeding the threshold:
   - First sending SIGTERM for graceful termination
   - Waiting 5 seconds
   - If the process is still running, sending SIGKILL to force termination
4. Logging all actions to `/var/log/memory-monitor.log`

## Security Considerations

The daemon is configured with systemd security hardening options:
- `ProtectSystem=full`: Mounts /usr and /boot as read-only
- `ProtectHome=true`: Makes /home, /root, and /run/user inaccessible
- `PrivateTmp=true`: Provides private /tmp directory
- `NoNewPrivileges=true`: Prevents privilege escalation

## Limitations

- The memory monitoring is based on RSS (Resident Set Size) which may not always accurately represent the total memory footprint of a process
- The daemon does not distinguish between critical system processes and user processes
- There is no whitelist functionality to protect specific processes

## Troubleshooting

### The daemon is not starting

Check the systemd journal for error messages:
```bash
sudo journalctl -u memory-monitor.service
```

### The daemon is not killing processes

1. Verify the threshold is set correctly
2. Check the log file for errors
3. Try running in dry-run mode to see if processes are being detected correctly

## License

This project is licensed under the MIT License - see the LICENSE file for details.
