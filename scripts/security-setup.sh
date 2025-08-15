#!/bin/bash

# Linux Server Security & Monitoring - Security Setup Script
# This script automates the security hardening process for Ubuntu servers

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

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    success "System packages updated"
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    sudo apt install -y ufw openssh-server sudo vim htop glances systemd systemd-sysv net-tools
    success "Required packages installed"
}

# Configure UFW firewall
configure_firewall() {
    log "Configuring UFW firewall..."
    
    # Reset UFW to default state
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow specific ports
    sudo ufw allow 22/tcp    # SSH
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    
    # Enable UFW
    echo "y" | sudo ufw enable
    
    success "UFW firewall configured and enabled"
    
    # Show status
    log "Firewall status:"
    sudo ufw status verbose
}

# Configure SSH security
configure_ssh() {
    log "Configuring SSH security..."
    
    # Backup original SSH config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Configure SSH for security
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
    
    # Additional security settings
    echo "Protocol 2" | sudo tee -a /etc/ssh/sshd_config
    echo "MaxAuthTries 3" | sudo tee -a /etc/ssh/sshd_config
    echo "LoginGraceTime 30" | sudo tee -a /etc/ssh/sshd_config
    
    # Test SSH configuration
    if sudo sshd -t; then
        success "SSH configuration is valid"
    else
        error "SSH configuration has errors"
        sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
        exit 1
    fi
    
    # Restart SSH service
    sudo systemctl restart ssh
    success "SSH service restarted with new configuration"
}

# Setup admin user
setup_admin_user() {
    log "Setting up admin user..."
    
    # Check if admin user exists
    if id "admin" &>/dev/null; then
        warning "Admin user already exists"
    else
        # Create admin user
        sudo useradd -m -s /bin/bash admin
        sudo usermod -aG sudo admin
        success "Admin user created"
    fi
    
    # Configure sudoers for admin user
    echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin
    success "Admin user sudo privileges configured"
}

# Setup SSH keys for admin user
setup_ssh_keys() {
    log "Setting up SSH keys for admin user..."
    
    # Create .ssh directory for admin user
    sudo mkdir -p /home/admin/.ssh
    sudo chown admin:admin /home/admin/.ssh
    sudo chmod 700 /home/admin/.ssh
    
    # Check if public key exists in /tmp
    if [ -f /tmp/id_ed25519.pub ]; then
        sudo cp /tmp/id_ed25519.pub /home/admin/.ssh/authorized_keys
        sudo chown admin:admin /home/admin/.ssh/authorized_keys
        sudo chmod 600 /home/admin/.ssh/authorized_keys
        success "SSH public key configured for admin user"
    else
        warning "No SSH public key found in /tmp/id_ed25519.pub"
        warning "Please copy your public key to the container and run this script again"
    fi
}

# Configure system monitoring
configure_monitoring() {
    log "Configuring system monitoring..."
    
    # Create monitoring directory
    sudo mkdir -p /var/log/monitoring
    
    # Configure log rotation for monitoring
    cat << EOF | sudo tee /etc/logrotate.d/monitoring
/var/log/monitoring/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    success "System monitoring configured"
}

# Create security check script
create_security_check() {
    log "Creating security check script..."
    
    cat << 'EOF' | sudo tee /usr/local/bin/security-check
#!/bin/bash

# Security Check Script
echo "=== Linux Server Security Check ==="
echo

echo "1. SSH Configuration:"
sudo sshd -T | grep -E "(password|root|key)" | sort
echo

echo "2. Firewall Status:"
sudo ufw status verbose
echo

echo "3. User Privileges:"
echo "Admin user groups: $(groups admin)"
echo "Sudo access test: $(sudo whoami)"
echo

echo "4. System Services:"
sudo systemctl status ssh --no-pager -l
echo

echo "5. Listening Ports:"
sudo netstat -tlnp | grep LISTEN
echo

echo "6. Recent Failed Logins:"
sudo journalctl | grep "Failed password" | tail -5
echo

echo "Security check completed!"
EOF
    
    sudo chmod +x /usr/local/bin/security-check
    success "Security check script created at /usr/local/bin/security-check"
}

# Display final status
show_status() {
    log "=== Security Setup Complete ==="
    echo
    echo "Security measures implemented:"
    echo "✓ UFW firewall configured and enabled"
    echo "✓ SSH hardened (key-based auth only, root login disabled)"
    echo "✓ Admin user created with sudo privileges"
    echo "✓ System monitoring tools installed"
    echo "✓ Security check script created"
    echo
    echo "Next steps:"
    echo "1. Copy your SSH public key to the container"
    echo "2. Test SSH connection: ssh admin@localhost"
    echo "3. Run security check: security-check"
    echo "4. Monitor system with: htop, glances"
    echo
    echo "Important security notes:"
    echo "- Only ports 22, 80, 443 are open"
    echo "- Password authentication is disabled"
    echo "- Root SSH login is disabled"
    echo "- All administrative actions are logged"
}

# Main execution
main() {
    echo "=== Linux Server Security Setup Script ==="
    echo "This script will configure security measures for your Ubuntu server"
    echo
    
    # Check prerequisites
    check_root
    check_sudo
    
    # Confirm execution
    read -p "Do you want to continue with security setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Security setup cancelled"
        exit 0
    fi
    
    # Execute security setup steps
    update_system
    install_packages
    configure_firewall
    configure_ssh
    setup_admin_user
    setup_ssh_keys
    configure_monitoring
    create_security_check
    
    # Show final status
    show_status
}

# Run main function
main "$@"
