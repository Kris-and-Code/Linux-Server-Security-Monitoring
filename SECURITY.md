# Linux Server Security & Monitoring - Security Documentation

## 🔒 Security Overview

This document provides comprehensive documentation of all security measures implemented in this Linux server demonstration project. Each section includes the commands used, why the measure improves security, and how to verify the configuration.

## 🚪 SSH Security Hardening

### 1. Key-Based Authentication Only

**Commands Used:**
```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Set the following parameters:
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Restart SSH service
sudo systemctl restart ssh
```

**Security Benefit:**
- Eliminates password brute-force attacks
- Provides cryptographic strength authentication
- Enables audit trail for authentication attempts
- Reduces risk of credential theft

**Verification:**
```bash
# Check SSH configuration
sudo sshd -T | grep -E "(password|pubkey)"

# Expected output:
# passwordauthentication no
# pubkeyauthentication yes
```

### 2. Disable Root SSH Login

**Commands Used:**
```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Set parameter:
PermitRootLogin no

# Restart SSH service
sudo systemctl restart ssh
```

**Security Benefit:**
- Prevents direct root account compromise
- Forces attackers to compromise a regular user first
- Reduces attack surface
- Improves audit trail

**Verification:**
```bash
# Check root login setting
sudo sshd -T | grep permitrootlogin

# Expected output:
# permitrootlogin no
```

### 3. SSH Key Management

**Commands Used:**
```bash
# Generate SSH key pair (on client)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Create .ssh directory on server
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add public key to authorized_keys
cat /tmp/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Remove temporary file
rm /tmp/id_ed25519.pub
```

**Security Benefit:**
- Uses strong cryptographic algorithms (Ed25519)
- Proper file permissions prevent unauthorized access
- Enables secure remote access without passwords

**Verification:**
```bash
# Check SSH directory permissions
ls -la ~/.ssh/

# Expected output:
# drwx------ 2 admin admin 4096 ... .ssh
# -rw------- 1 admin admin   xxx ... authorized_keys
```

## 🛡️ Firewall Configuration (UFW)

### 1. Basic UFW Setup

**Commands Used:**
```bash
# Install UFW if not present
sudo apt update && sudo apt install -y ufw

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow specific ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Enable UFW
sudo ufw enable
```

**Security Benefit:**
- Blocks all incoming connections by default
- Only allows necessary services
- Prevents unauthorized access to unused ports
- Provides clear network access control

**Verification:**
```bash
# Check UFW status
sudo ufw status verbose

# Check UFW rules
sudo ufw status numbered

# Expected output shows only ports 22, 80, 443 allowed
```

### 2. UFW Rule Management

**Commands Used:**
```bash
# List all rules
sudo ufw status numbered

# Delete specific rule (if needed)
sudo ufw delete [rule_number]

# Reload UFW
sudo ufw reload
```

**Security Benefit:**
- Easy rule management and modification
- Quick response to security incidents
- Clear audit trail of firewall rules

## 👤 User Management & Privileges

### 1. Create Non-Root Admin User

**Commands Used:**
```bash
# Create admin user
sudo useradd -m -s /bin/bash admin

# Add to sudo group
sudo usermod -aG sudo admin

# Set password (if needed for sudo)
sudo passwd admin

# Configure sudoers (optional - for passwordless sudo)
echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin
```

**Security Benefit:**
- Implements principle of least privilege
- Prevents direct root access
- Enables audit trail for administrative actions
- Reduces impact of user compromise

**Verification:**
```bash
# Check user groups
groups admin

# Test sudo access
sudo whoami

# Expected output: root
```

### 2. Sudo Configuration

**Commands Used:**
```bash
# Edit sudoers file safely
sudo visudo

# Or create specific sudoers file
echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin
```

**Security Benefit:**
- Controlled administrative access
- Audit trail for all sudo commands
- Prevents privilege escalation attacks

## 📊 System Monitoring Tools

### 1. htop Installation & Configuration

**Commands Used:**
```bash
# Install htop
sudo apt update && sudo apt install -y htop

# Run htop
htop
```

**Security Benefit:**
- Real-time system resource monitoring
- Identifies resource exhaustion attacks
- Monitors process behavior
- Helps detect unusual system activity

**Usage:**
```bash
# Start htop
htop

# Key bindings:
# F1: Help
# F2: Setup
# F3: Search
# F4: Filter
# F5: Tree view
# F6: Sort by
# F9: Kill process
# F10: Quit
```

### 2. glances Installation & Configuration

**Commands Used:**
```bash
# Install glances
sudo apt update && sudo apt install -y glances

# Run glances
glances

# Run in web server mode
glances -w
```

**Security Benefit:**
- Advanced system monitoring
- Web interface for remote monitoring
- Historical data tracking
- Alert system for resource thresholds

**Usage:**
```bash
# Start glances
glances

# Start web server mode (accessible on port 61208)
glances -w

# Access web interface: http://server-ip:61208
```

### 3. System Logging with journald

**Commands Used:**
```bash
# Check systemd journal status
sudo systemctl status systemd-journald

# View system logs
sudo journalctl -f

# View specific service logs
sudo journalctl -u ssh -f

# View logs since boot
sudo journalctl -b
```

**Security Benefit:**
- Centralized logging system
- Tamper-resistant logs
- Easy log analysis and searching
- Audit trail for security events

**Log Analysis Commands:**
```bash
# View failed login attempts
sudo journalctl | grep "Failed password"

# View SSH connections
sudo journalctl | grep "sshd"

# View system errors
sudo journalctl -p err

# View logs for specific time period
sudo journalctl --since "2024-01-01" --until "2024-01-02"
```

## 🔍 Security Validation & Testing

### 1. SSH Security Check

**Commands Used:**
```bash
# Test SSH configuration
sudo sshd -T | grep -E "(password|root|key|protocol)"

# Check SSH service status
sudo systemctl status ssh

# Test SSH connection (from another machine)
ssh -i ~/.ssh/id_ed25519 admin@server-ip
```

**Expected Results:**
- `passwordauthentication no`
- `permitrootlogin no`
- `pubkeyauthentication yes`
- SSH service active and running

### 2. Firewall Validation

**Commands Used:**
```bash
# Check UFW status
sudo ufw status verbose

# Test port accessibility
sudo netstat -tlnp

# Check listening ports
sudo ss -tlnp
```

**Expected Results:**
- UFW active
- Only ports 22, 80, 443 listening
- Default deny incoming policy

### 3. User Privilege Check

**Commands Used:**
```bash
# Check user groups
groups admin

# Test sudo access
sudo whoami

# Check sudoers configuration
sudo cat /etc/sudoers.d/admin
```

**Expected Results:**
- admin user in sudo group
- sudo access working
- Proper sudoers configuration

## 🚨 Security Monitoring & Alerts

### 1. Failed Login Monitoring

**Commands Used:**
```bash
# Monitor failed SSH attempts
sudo journalctl -f | grep "Failed password"

# Count failed attempts
sudo journalctl | grep "Failed password" | wc -l

# Check for brute force attempts
sudo journalctl | grep "Failed password" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}"
```

**Security Benefit:**
- Early detection of brute force attacks
- IP address tracking
- Incident response preparation

### 2. System Resource Monitoring

**Commands Used:**
```bash
# Monitor CPU usage
htop

# Monitor disk usage
df -h

# Monitor memory usage
free -h

# Monitor network connections
sudo netstat -tuln
```

**Security Benefit:**
- Detect resource exhaustion attacks
- Identify unusual system behavior
- Prevent denial of service

### 3. Process Monitoring

**Commands Used:**
```bash
# List running processes
ps aux

# Monitor process tree
pstree

# Check for suspicious processes
ps aux | grep -E "(python|perl|bash)" | grep -v grep
```

**Security Benefit:**
- Detect unauthorized processes
- Identify malware or backdoors
- Monitor system integrity

## 📋 Security Checklist

### Pre-Deployment
- [ ] SSH key pairs generated
- [ ] UFW firewall configured
- [ ] Non-root user created
- [ ] SSH configuration hardened
- [ ] Monitoring tools installed

### Post-Deployment
- [ ] SSH key-based auth working
- [ ] Root login disabled
- [ ] Firewall rules active
- [ ] Monitoring tools functional
- [ ] Logs being generated

### Ongoing Monitoring
- [ ] Failed login attempts reviewed
- [ ] System resources monitored
- [ ] Process list reviewed
- [ ] Logs analyzed regularly
- [ ] Security updates applied

## 🔧 Troubleshooting Common Issues

### SSH Connection Issues
```bash
# Check SSH service status
sudo systemctl status ssh

# Check SSH configuration syntax
sudo sshd -t

# View SSH logs
sudo journalctl -u ssh -f
```

### Firewall Issues
```bash
# Check UFW status
sudo ufw status

# Reset UFW if needed
sudo ufw reset

# Check iptables rules
sudo iptables -L
```

### Permission Issues
```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Check user groups
groups admin
```

## 📚 Additional Security Resources

- [Ubuntu Security Documentation](https://ubuntu.com/security)
- [SSH Security Best Practices](https://www.ssh.com/ssh/)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [systemd Journal Documentation](https://systemd.io/JOURNAL_NATIVE_PROTOCOL/)

## ⚠️ Security Warnings

1. **This is a demonstration project** - Do not use in production without proper security review
2. **Regular security updates** - Always keep your system updated
3. **Monitor logs regularly** - Security is an ongoing process
4. **Backup configurations** - Keep copies of security configurations
5. **Test in isolation** - Never test security measures on production systems

---

**Last Updated**: January 2024  
**Security Level**: Demonstration/Educational  
**Recommended Use**: Learning, Testing, Development Environments
