# Linux Server Security & Monitoring - Dockerfile
# Ubuntu 22.04 LTS with security hardening and monitoring tools

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update system and install essential packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    # Core system packages
    systemd \
    systemd-sysv \
    sudo \
    vim \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    # Security packages
    ufw \
    fail2ban \
    openssh-server \
    # Monitoring packages
    htop \
    glances \
    iotop \
    nethogs \
    nmon \
    sysstat \
    dstat \
    hdparm \
    smartmontools \
    # Network tools
    net-tools \
    iproute2 \
    iptables \
    # Logging and monitoring
    rsyslog \
    logrotate \
    # Additional utilities
    tree \
    htop \
    unzip \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create admin user
RUN useradd -m -s /bin/bash admin && \
    echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/admin && \
    chmod 0440 /etc/sudoers.d/admin

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup && \
    # Configure SSH for security
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config && \
    # Additional security settings
    echo "Protocol 2" >> /etc/ssh/sshd_config && \
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config && \
    echo "LoginGraceTime 30" >> /etc/ssh/sshd_config && \
    echo "X11Forwarding no" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel no" >> /etc/ssh/sshd_config

# Configure UFW firewall
RUN ufw --force reset && \
    ufw default deny incoming && \
    ufw default allow outgoing && \
    ufw allow 22/tcp && \
    ufw allow 80/tcp && \
    ufw allow 443/tcp && \
    ufw allow 61208/tcp && \
    echo "y" | ufw enable

# Create monitoring directories
RUN mkdir -p /var/log/monitoring/{glances,system,htop} && \
    chown -R root:root /var/log/monitoring && \
    chmod -R 755 /var/log/monitoring

# Configure glances
RUN mkdir -p /etc/glances && \
    echo '[global]' > /etc/glances/glances.conf && \
    echo 'refresh=2' >> /etc/glances/glances.conf && \
    echo 'theme=white' >> /etc/glances/glances.conf && \
    echo 'disable_plugin=connections,ports,irq,folders,ip,raid,network,diskio,processes,processlist' >> /etc/glances/glances.conf && \
    echo 'enable_plugin=cpu,mem,load,uptime,alert,psutilversion,quicklook,uptime,memswap,fs,percpu,core,thermal,count,now,user,hostname,os,version,linux_distro,ip,hostname,network,diskio,fs,irq,load,mem,memswap,network,now,percpu,processcount,quicklook,sensors,uptime,users,version,volts' >> /etc/glances/glances.conf && \
    echo '' >> /etc/glances/glances.conf && \
    echo '[outputs]' >> /etc/glances/glances.conf && \
    echo 'stdout_csv_file=/var/log/monitoring/glances/glances.csv' >> /etc/glances/glances.conf && \
    echo 'stdout_json_file=/var/log/monitoring/glances/glances.json' >> /etc/glances/glances.conf && \
    echo '' >> /etc/glances/glances.conf && \
    echo '[alerts]' >> /etc/glances/glances.conf && \
    echo 'cpu_critical=90' >> /etc/glances/glances.conf && \
    echo 'cpu_warning=70' >> /etc/glances/glances.conf && \
    echo 'mem_critical=90' >> /etc/glances/glances.conf && \
    echo 'mem_warning=70' >> /etc/glances/glances.conf && \
    echo 'swap_critical=90' >> /etc/glances/glances.conf && \
    echo 'swap_warning=70' >> /etc/glances/glances.conf

# Configure log rotation
RUN echo '/var/log/monitoring/*.log {' > /etc/logrotate.d/monitoring && \
    echo '    daily' >> /etc/logrotate.d/monitoring && \
    echo '    missingok' >> /etc/logrotate.d/monitoring && \
    echo '    rotate 7' >> /etc/logrotate.d/monitoring && \
    echo '    compress' >> /etc/logrotate.d/monitoring && \
    echo '    delaycompress' >> /etc/logrotate.d/monitoring && \
    echo '    notifempty' >> /etc/logrotate.d/monitoring && \
    echo '    create 644 root root' >> /etc/logrotate.d/monitoring && \
    echo '}' >> /etc/logrotate.d/monitoring && \
    echo '' >> /etc/logrotate.d/monitoring && \
    echo '/var/log/monitoring/glances/*.csv {' >> /etc/logrotate.d/monitoring && \
    echo '    daily' >> /etc/logrotate.d/monitoring && \
    echo '    missingok' >> /etc/logrotate.d/monitoring && \
    echo '    rotate 30' >> /etc/logrotate.d/monitoring && \
    echo '    compress' >> /etc/logrotate.d/monitoring && \
    echo '    delaycompress' >> /etc/logrotate.d/monitoring && \
    echo '    notifempty' >> /etc/logrotate.d/monitoring && \
    echo '    create 644 root root' >> /etc/logrotate.d/monitoring && \
    echo '}' >> /etc/logrotate.d/monitoring && \
    echo '' >> /etc/logrotate.d/monitoring && \
    echo '/var/log/monitoring/glances/*.json {' >> /etc/logrotate.d/monitoring && \
    echo '    daily' >> /etc/logrotate.d/monitoring && \
    echo '    missingok' >> /etc/logrotate.d/monitoring && \
    echo '    rotate 30' >> /etc/logrotate.d/monitoring && \
    echo '    compress' >> /etc/logrotate.d/monitoring && \
    echo '    delaycompress' >> /etc/logrotate.d/monitoring && \
    echo '    notifempty' >> /etc/logrotate.d/monitoring && \
    echo '    create 644 root root' >> /etc/logrotate.d/monitoring && \
    echo '}' >> /etc/logrotate.d/monitoring

# Create glances monitoring service
RUN echo '[Unit]' > /etc/systemd/system/glances-monitor.service && \
    echo 'Description=Glances Monitoring Service' >> /etc/systemd/system/glances-monitor.service && \
    echo 'After=network.target' >> /etc/systemd/system/glances-monitor.service && \
    echo '' >> /etc/systemd/system/glances-monitor.service && \
    echo '[Service]' >> /etc/systemd/system/glances-monitor.service && \
    echo 'Type=simple' >> /etc/systemd/system/glances-monitor.service && \
    echo 'User=root' >> /etc/systemd/system/glances-monitor.service && \
    echo 'ExecStart=/usr/bin/glances -w --export csv --export json --log-file /var/log/monitoring/glances/glances.log' >> /etc/systemd/system/glances-monitor.service && \
    echo 'Restart=always' >> /etc/systemd/system/glances-monitor.service && \
    echo 'RestartSec=10' >> /etc/systemd/system/glances-monitor.service && \
    echo '' >> /etc/systemd/system/glances-monitor.service && \
    echo '[Install]' >> /etc/systemd/system/glances-monitor.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/glances-monitor.service

# System monitoring service
RUN echo '[Unit]' > /etc/systemd/system/system-monitor.service && \
    echo 'Description=System Monitoring Service' >> /etc/systemd/system/system-monitor.service && \
    echo 'After=network.target' >> /etc/systemd/system/system-monitor.service && \
    echo '' >> /etc/systemd/system/system-monitor.service && \
    echo '[Service]' >> /etc/systemd/system/system-monitor.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/system-monitor.service && \
    echo 'User=root' >> /etc/systemd/system/system-monitor.service && \
    echo 'ExecStart=/usr/bin/bash -c "echo \"=== System Status \$(date) ===\" >> /var/log/monitoring/system/system.log && uptime >> /var/log/monitoring/system/system.log && free -h >> /var/log/monitoring/system/system.log && df -h >> /var/log/monitoring/system/system.log && ps aux --sort=-%cpu | head -10 >> /var/log/monitoring/system/system.log && echo \"---\" >> /var/log/monitoring/system/system.log"' >> /etc/systemd/system/system-monitor.service && \
    echo '' >> /etc/systemd/system/system-monitor.service && \
    echo '[Install]' >> /etc/systemd/system/system-monitor.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/system-monitor.service

# System monitoring timer
RUN echo '[Unit]' > /etc/systemd/system/system-monitor.timer && \
    echo 'Description=Run System Monitor every 5 minutes' >> /etc/systemd/system/system-monitor.timer && \
    echo 'Requires=system-monitor.service' >> /etc/systemd/system/system-monitor.timer && \
    echo '' >> /etc/systemd/system/system-monitor.timer && \
    echo '[Timer]' >> /etc/systemd/system/system-monitor.timer && \
    echo 'Unit=system-monitor.service' >> /etc/systemd/system/system-monitor.timer && \
    echo 'OnCalendar=*:0/5' >> /etc/systemd/system/system-monitor.timer && \
    echo 'Persistent=true' >> /etc/systemd/system/system-monitor.timer && \
    echo '' >> /etc/systemd/system/system-monitor.timer && \
    echo '[Install]' >> /etc/systemd/system/system-monitor.timer && \
    echo 'WantedBy=timers.target' >> /etc/systemd/system/system-monitor.timer

# Copy scripts to container
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh && \
    # Create symlinks for easy access
    ln -sf /opt/scripts/security-setup.sh /usr/local/bin/security-setup && \
    ln -sf /opt/scripts/monitoring-setup.sh /usr/local/bin/monitoring-setup && \
    ln -sf /opt/scripts/security-check.sh /usr/local/bin/security-check

# Create security check script
RUN echo '#!/bin/bash' > /usr/local/bin/security-check && \
    echo '# Quick security check' >> /usr/local/bin/security-check && \
    echo 'echo "=== Quick Security Check ==="' >> /usr/local/bin/security-check && \
    echo 'echo "SSH Config:"' >> /usr/local/bin/security-check && \
    echo 'sshd -T | grep -E "(password|root|key)" | sort' >> /usr/local/bin/security-check && \
    echo 'echo' >> /usr/local/bin/security-check && \
    echo 'echo "Firewall:"' >> /usr/local/bin/security-check && \
    echo 'ufw status verbose' >> /usr/local/bin/security-check && \
    echo 'echo' >> /usr/local/bin/security-check && \
    echo 'echo "User:"' >> /usr/local/bin/security-check && \
    echo 'groups admin' >> /usr/local/bin/security-check && \
    echo 'echo' >> /usr/local/bin/security-check && \
    echo 'echo "Ports:"' >> /usr/local/bin/security-check && \
    echo 'netstat -tlnp | grep LISTEN' >> /usr/local/bin/security-check && \
    chmod +x /usr/local/bin/security-check

# Create monitoring dashboard script
RUN echo '#!/bin/bash' > /usr/local/bin/monitor-dashboard && \
    echo 'echo "=== System Monitoring Dashboard ==="' >> /usr/local/bin/monitor-dashboard && \
    echo 'echo "Uptime: $(uptime -p)"' >> /usr/local/bin/monitor-dashboard && \
    echo 'echo "Load: $(uptime | awk -F\"load average:\" \"{print \$2}\")"' >> /usr/local/bin/monitor-dashboard && \
    echo 'echo "Memory: $(free -h | grep Mem | awk \"{print \$3\"/\"\$2}\")"' >> /usr/local/bin/monitor-dashboard && \
    echo 'echo "Disk: $(df -h / | tail -1 | awk \"{print \$5}\")"' >> /usr/local/bin/monitor-dashboard && \
    echo 'echo "Processes: $(ps aux | wc -l)"' >> /usr/local/bin/monitor-dashboard && \
    echo 'echo "Connections: $(netstat -an | grep ESTABLISHED | wc -l)"' >> /usr/local/bin/monitor-dashboard && \
    chmod +x /usr/local/bin/monitor-dashboard

# Create useful aliases
RUN echo "alias cpu='htop'" >> /home/admin/.bashrc && \
    echo "alias mem='free -h'" >> /home/admin/.bashrc && \
    echo "alias disk='df -h'" >> /home/admin/.bashrc && \
    echo "alias net='netstat -tuln'" >> /home/admin/.bashrc && \
    echo "alias logs='journalctl -f'" >> /home/admin/.bashrc && \
    echo "alias monitor='monitor-dashboard'" >> /home/admin/.bashrc && \
    echo "alias security='security-check'" >> /home/admin/.bashrc && \
    echo "alias glances-web='glances -w'" >> /home/admin/.bashrc

# Set ownership for admin user
RUN chown -R admin:admin /home/admin

# Expose ports
EXPOSE 22 80 443 61208

# Create startup script
RUN echo '#!/bin/bash' > /usr/local/bin/startup.sh && \
    echo '# Start required services' >> /usr/local/bin/startup.sh && \
    echo 'systemctl start ssh' >> /usr/local/bin/startup.sh && \
    echo 'systemctl start glances-monitor.service' >> /usr/local/bin/startup.sh && \
    echo 'systemctl start system-monitor.timer' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Show status' >> /usr/local/bin/startup.sh && \
    echo 'echo "=== Server Status ==="' >> /usr/local/bin/startup.sh && \
    echo 'echo "SSH: $(systemctl is-active ssh)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "Glances: $(systemctl is-active glances-monitor.service)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "System Monitor: $(systemctl is-active system-monitor.timer)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "Firewall: $(ufw status | grep Status)"' >> /usr/local/bin/startup.sh && \
    echo 'echo' >> /usr/local/bin/startup.sh && \
    echo 'echo "=== Quick Commands ==="' >> /usr/local/bin/startup.sh && \
    echo 'echo "security-check  - Run security validation"' >> /usr/local/bin/startup.sh && \
    echo 'echo "monitor-dashboard - Show system overview"' >> /usr/local/bin/startup.sh && \
    echo 'echo "htop           - Interactive system monitor"' >> /usr/local/bin/startup.sh && \
    echo 'echo "glances-web    - Start web monitoring interface"' >> /usr/local/bin/startup.sh && \
    echo 'echo "security-setup - Run security setup script"' >> /usr/local/bin/startup.sh && \
    echo 'echo "monitoring-setup - Run monitoring setup script"' >> /usr/local/bin/startup.sh && \
    echo 'echo' >> /usr/local/bin/startup.sh && \
    echo 'echo "=== Access Information ==="' >> /usr/local/bin/startup.sh && \
    echo 'echo "SSH: ssh admin@localhost -p 22"' >> /usr/local/bin/startup.sh && \
    echo 'echo "Web Monitor: http://localhost:61208"' >> /usr/local/bin/startup.sh && \
    echo 'echo' >> /usr/local/bin/startup.sh && \
    echo 'echo "Server is ready!"' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Set the startup script as the default command
CMD ["/usr/local/bin/startup.sh"]
