#!/bin/bash

# Linux Server Security & Monitoring - Monitoring Setup Script
# This script installs and configures system monitoring tools

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        error "This script requires sudo privileges"
        exit 1
    fi
}

# Install monitoring packages
install_monitoring_packages() {
    log "Installing monitoring packages..."
    
    # Update package list
    sudo apt update
    
    # Install monitoring tools
    sudo apt install -y htop glances iotop nethogs nmon sysstat dstat hdparm smartmontools
    
    success "Monitoring packages installed"
}

# Configure htop
configure_htop() {
    log "Configuring htop..."
    
    # Create htop configuration directory
    mkdir -p ~/.config/htop
    
    # Create basic htop configuration
    cat << 'EOF' > ~/.config/htop/htoprc
# htop configuration file
# See htop(1) for more information

# CPU usage colors
cpu_count_from_one=0
detailed_cpu_time=1
color_scheme=0
delay=15
hide_function_bar=0
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
tree_view=0
header_margin=1
EOF
    
    success "htop configured"
}

# Configure glances
configure_glances() {
    log "Configuring glances..."
    
    # Create glances configuration directory
    sudo mkdir -p /etc/glances
    
    # Create glances configuration file
    cat << 'EOF' | sudo tee /etc/glances/glances.conf
[global]
refresh=2
theme=white
disable_plugin=connections,ports,irq,folders,ip,raid,network,diskio,processes,processlist
enable_plugin=cpu,mem,load,uptime,alert,psutilversion,quicklook,uptime,memswap,fs,percpu,core,thermal,count,now,user,hostname,os,version,linux_distro,ip,hostname,network,diskio,fs,irq,load,mem,memswap,network,now,percpu,processcount,quicklook,sensors,uptime,users,version,volts

[outputs]
stdout_csv_file=/var/log/monitoring/glances.csv
stdout_json_file=/var/log/monitoring/glances.json

[alerts]
cpu_critical=90
cpu_warning=70
mem_critical=90
mem_warning=70
swap_critical=90
swap_warning=70
EOF
    
    success "glances configured"
}

# Configure system monitoring
configure_system_monitoring() {
    log "Configuring system monitoring..."
    
    # Create monitoring directories
    sudo mkdir -p /var/log/monitoring
    sudo mkdir -p /var/log/monitoring/glances
    sudo mkdir -p /var/log/monitoring/htop
    sudo mkdir -p /var/log/monitoring/system
    
    # Set proper permissions
    sudo chown -R root:root /var/log/monitoring
    sudo chmod -R 755 /var/log/monitoring
    
    success "System monitoring directories created"
}

# Configure log rotation for monitoring
configure_log_rotation() {
    log "Configuring log rotation for monitoring..."
    
    # Create logrotate configuration for monitoring
    cat << 'EOF' | sudo tee /etc/logrotate.d/monitoring
/var/log/monitoring/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}

/var/log/monitoring/glances/*.csv {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}

/var/log/monitoring/glances/*.json {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    success "Log rotation configured for monitoring"
}

# Create monitoring service files
create_monitoring_services() {
    log "Creating monitoring service files..."
    
    # Create glances service file
    cat << 'EOF' | sudo tee /etc/systemd/system/glances-monitor.service
[Unit]
Description=Glances Monitoring Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/glances -w --export csv --export json --log-file /var/log/monitoring/glances/glances.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Create system monitoring service
    cat << 'EOF' | sudo tee /etc/systemd/system/system-monitor.service
[Unit]
Description=System Monitoring Service
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/bin/bash -c '
    echo "=== System Status $(date) ===" >> /var/log/monitoring/system/system.log
    uptime >> /var/log/monitoring/system/system.log
    free -h >> /var/log/monitoring/system/system.log
    df -h >> /var/log/monitoring/system/system.log
    ps aux --sort=-%cpu | head -10 >> /var/log/monitoring/system/system.log
    echo "---" >> /var/log/monitoring/system/system.log
'

[Install]
WantedBy=multi-user.target
EOF
    
    # Create system monitoring timer
    cat << 'EOF' | sudo tee /etc/systemd/system/system-monitor.timer
[Unit]
Description=Run System Monitor every 5 minutes
Requires=system-monitor.service

[Timer]
Unit=system-monitor.service
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    success "Monitoring service files created"
}

# Enable and start monitoring services
enable_monitoring_services() {
    log "Enabling and starting monitoring services..."
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable and start glances service
    sudo systemctl enable glances-monitor.service
    sudo systemctl start glances-monitor.service
    
    # Enable and start system monitoring timer
    sudo systemctl enable system-monitor.timer
    sudo systemctl start system-monitor.timer
    
    success "Monitoring services enabled and started"
}

# Create monitoring dashboard script
create_monitoring_dashboard() {
    log "Creating monitoring dashboard script..."
    
    cat << 'EOF' | sudo tee /usr/local/bin/monitor-dashboard
#!/bin/bash

# Monitoring Dashboard Script
echo "=== Linux Server Monitoring Dashboard ==="
echo "Generated: $(date)"
echo

echo "1. System Overview:"
echo "   Uptime: $(uptime -p)"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "   CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo

echo "2. Memory Usage:"
free -h | grep -E "(Mem|Swap)"
echo

echo "3. Disk Usage:"
df -h | grep -E "(Filesystem|/dev/)"
echo

echo "4. Network Connections:"
echo "   Active connections: $(netstat -an | grep ESTABLISHED | wc -l)"
echo "   Listening ports: $(netstat -tlnp | grep LISTEN | wc -l)"
echo

echo "5. Top Processes (by CPU):"
ps aux --sort=-%cpu | head -6
echo

echo "6. Recent System Logs:"
journalctl --since "1 hour ago" | grep -E "(error|warning|critical)" | tail -5
echo

echo "7. Monitoring Services Status:"
systemctl status glances-monitor.service --no-pager -l | grep -E "(Active|Status)"
echo

echo "Dashboard generated successfully!"
EOF
    
    sudo chmod +x /usr/local/bin/monitor-dashboard
    success "Monitoring dashboard script created at /usr/local/bin/monitor-dashboard"
}

# Create quick monitoring commands
create_quick_commands() {
    log "Creating quick monitoring commands..."
    
    # Create aliases for common monitoring tasks
    cat << 'EOF' >> ~/.bashrc

# Monitoring aliases
alias cpu='htop'
alias mem='free -h && echo "---" && vmstat 1 5'
alias disk='df -h && echo "---" && iostat -x 1 3'
alias net='netstat -tuln && echo "---" && ss -tuln'
alias logs='journalctl -f'
alias monitor='monitor-dashboard'
alias glances-web='glances -w'
alias system-status='systemctl status --no-pager -l'
EOF
    
    # Source the updated bashrc
    source ~/.bashrc
    
    success "Quick monitoring commands configured"
}

# Display monitoring status
show_monitoring_status() {
    log "=== Monitoring Setup Complete ==="
    echo
    echo "Monitoring tools installed and configured:"
    echo "✓ htop - Real-time system monitoring"
    echo "✓ glances - Advanced system monitoring with web interface"
    echo "✓ iotop - I/O monitoring"
    echo "✓ nethogs - Network usage monitoring"
    echo "✓ nmon - System performance monitoring"
    echo "✓ sysstat - System statistics"
    echo "✓ dstat - Real-time system statistics"
    echo
    echo "Monitoring services:"
    echo "✓ glances-monitor.service - Continuous monitoring"
    echo "✓ system-monitor.timer - Periodic system status"
    echo
    echo "Available commands:"
    echo "- htop: Interactive system monitor"
    echo "- glances: Advanced monitoring with web interface"
    echo "- monitor-dashboard: Quick system overview"
    echo "- glances-web: Start web interface (port 61208)"
    echo
    echo "Monitoring data location:"
    echo "- /var/log/monitoring/ - All monitoring logs"
    echo "- /var/log/monitoring/glances/ - Glances data"
    echo "- /var/log/monitoring/system/ - System status logs"
    echo
    echo "Web interface: http://server-ip:61208"
}

# Main execution
main() {
    echo "=== Linux Server Monitoring Setup Script ==="
    echo "This script will install and configure system monitoring tools"
    echo
    
    # Check prerequisites
    check_root
    check_sudo
    
    # Confirm execution
    read -p "Do you want to continue with monitoring setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Monitoring setup cancelled"
        exit 0
    fi
    
    # Execute monitoring setup steps
    install_monitoring_packages
    configure_htop
    configure_glances
    configure_system_monitoring
    configure_log_rotation
    create_monitoring_services
    enable_monitoring_services
    create_monitoring_dashboard
    create_quick_commands
    
    # Show final status
    show_monitoring_status
}

# Run main function
main "$@"
