#!/bin/bash

# Linux Server Security & Monitoring - Security Check Script
# This script validates all security measures implemented on the server

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

# SSH Security Checks
check_ssh_security() {
    log "Checking SSH Security Configuration..."
    echo "=========================================="
    
    # Check SSH service status
    if systemctl is-active --quiet ssh; then
        success "SSH service is running"
    else
        error "SSH service is not running"
    fi
    
    # Check SSH configuration
    echo
    echo "SSH Configuration:"
    sshd_config=$(sudo sshd -T 2>/dev/null)
    
    # Password authentication
    if echo "$sshd_config" | grep -q "passwordauthentication no"; then
        success "Password authentication is disabled"
    else
        error "Password authentication is enabled"
    fi
    
    # Public key authentication
    if echo "$sshd_config" | grep -q "pubkeyauthentication yes"; then
        success "Public key authentication is enabled"
    else
        error "Public key authentication is disabled"
    fi
    
    # Root login
    if echo "$sshd_config" | grep -q "permitrootlogin no"; then
        success "Root SSH login is disabled"
    else
        error "Root SSH login is enabled"
    fi
    
    # Protocol version
    if echo "$sshd_config" | grep -q "protocol 2"; then
        success "SSH Protocol 2 is enabled"
    else
        warning "SSH Protocol 2 not explicitly set"
    fi
    
    # Max auth tries
    max_auth=$(echo "$sshd_config" | grep "maxauthtries" | awk '{print $2}')
    if [[ "$max_auth" -le 3 ]]; then
        success "Max authentication tries: $max_auth"
    else
        warning "Max authentication tries: $max_auth (recommended: ≤3)"
    fi
    
    # Login grace time
    grace_time=$(echo "$sshd_config" | grep "logingracetime" | awk '{print $2}')
    if [[ "$grace_time" -le 60 ]]; then
        success "Login grace time: ${grace_time}s"
    else
        warning "Login grace time: ${grace_time}s (recommended: ≤60s)"
    fi
    
    echo
}

# Firewall Security Checks
check_firewall_security() {
    log "Checking Firewall Configuration..."
    echo "=========================================="
    
    # Check UFW status
    if sudo ufw status | grep -q "Status: active"; then
        success "UFW firewall is active"
    else
        error "UFW firewall is not active"
    fi
    
    # Check default policies
    echo
    echo "Firewall Policies:"
    ufw_status=$(sudo ufw status verbose)
    
    if echo "$ufw_status" | grep -q "Default: deny (incoming)"; then
        success "Default incoming policy: deny"
    else
        error "Default incoming policy not set to deny"
    fi
    
    if echo "$ufw_status" | grep -q "Default: allow (outgoing)"; then
        success "Default outgoing policy: allow"
    else
        error "Default outgoing policy not set to allow"
    fi
    
    # Check allowed ports
    echo
    echo "Allowed Ports:"
    allowed_ports=$(sudo ufw status numbered | grep -E "22|80|443" | wc -l)
    if [[ "$allowed_ports" -eq 3 ]]; then
        success "Correct ports allowed (22, 80, 443)"
    else
        warning "Unexpected number of allowed ports: $allowed_ports"
    fi
    
    # Show current rules
    echo
    echo "Current Firewall Rules:"
    sudo ufw status numbered
    
    echo
}

# User Security Checks
check_user_security() {
    log "Checking User Security Configuration..."
    echo "=========================================="
    
    # Check admin user
    if id "admin" &>/dev/null; then
        success "Admin user exists"
        
        # Check admin user groups
        if groups admin | grep -q "sudo"; then
            success "Admin user has sudo privileges"
        else
            error "Admin user missing sudo privileges"
        fi
        
        # Check admin user shell
        admin_shell=$(grep "^admin:" /etc/passwd | cut -d: -f7)
        if [[ "$admin_shell" == "/bin/bash" ]]; then
            success "Admin user has proper shell"
        else
            warning "Admin user shell: $admin_shell"
        fi
    else
        error "Admin user does not exist"
    fi
    
    # Check root account
    if sudo passwd -S root | grep -q "L"; then
        success "Root account is locked"
    else
        warning "Root account is not locked"
    fi
    
    # Check sudoers configuration
    if sudo test -f /etc/sudoers.d/admin; then
        success "Admin sudoers file exists"
        
        if sudo grep -q "admin ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/admin; then
            success "Admin sudoers configuration is correct"
        else
            error "Admin sudoers configuration is incorrect"
        fi
    else
        error "Admin sudoers file does not exist"
    fi
    
    echo
}

# SSH Key Security Checks
check_ssh_keys() {
    log "Checking SSH Key Configuration..."
    echo "=========================================="
    
    # Check .ssh directory for admin user
    if sudo test -d /home/admin/.ssh; then
        success "Admin .ssh directory exists"
        
        # Check .ssh directory permissions
        ssh_dir_perm=$(sudo stat -c "%a" /home/admin/.ssh)
        if [[ "$ssh_dir_perm" == "700" ]]; then
            success "SSH directory permissions: $ssh_dir_perm"
        else
            error "SSH directory permissions: $ssh_dir_perm (should be 700)"
        fi
        
        # Check authorized_keys file
        if sudo test -f /home/admin/.ssh/authorized_keys; then
            success "Authorized keys file exists"
            
            # Check authorized_keys permissions
            auth_keys_perm=$(sudo stat -c "%a" /home/admin/.ssh/authorized_keys)
            if [[ "$auth_keys_perm" == "600" ]]; then
                success "Authorized keys permissions: $auth_keys_perm"
            else
                error "Authorized keys permissions: $auth_keys_perm (should be 600)"
            fi
            
            # Check if keys are present
            key_count=$(sudo wc -l < /home/admin/.ssh/authorized_keys)
            if [[ "$key_count" -gt 0 ]]; then
                success "Authorized keys present: $key_count"
            else
                warning "No authorized keys found"
            fi
        else
            warning "Authorized keys file does not exist"
        fi
    else
        warning "Admin .ssh directory does not exist"
    fi
    
    echo
}

# System Monitoring Checks
check_system_monitoring() {
    log "Checking System Monitoring Configuration..."
    echo "=========================================="
    
    # Check monitoring tools
    echo "Monitoring Tools:"
    
    if command -v htop &> /dev/null; then
        success "htop is installed"
    else
        error "htop is not installed"
    fi
    
    if command -v glances &> /dev/null; then
        success "glances is installed"
    else
        error "glances is not installed"
    fi
    
    if command -v iotop &> /dev/null; then
        success "iotop is installed"
    else
        error "iotop is not installed"
    fi
    
    # Check monitoring services
    echo
    echo "Monitoring Services:"
    
    if systemctl is-active --quiet glances-monitor.service; then
        success "Glances monitoring service is running"
    else
        warning "Glances monitoring service is not running"
    fi
    
    if systemctl is-active --quiet system-monitor.timer; then
        success "System monitoring timer is active"
    else
        warning "System monitoring timer is not active"
    fi
    
    # Check monitoring directories
    echo
    echo "Monitoring Directories:"
    
    if sudo test -d /var/log/monitoring; then
        success "Monitoring log directory exists"
        
        if sudo test -d /var/log/monitoring/glances; then
            success "Glances log directory exists"
        fi
        
        if sudo test -d /var/log/monitoring/system; then
            success "System log directory exists"
        fi
    else
        warning "Monitoring log directory does not exist"
    fi
    
    echo
}

# Network Security Checks
check_network_security() {
    log "Checking Network Security..."
    echo "=========================================="
    
    # Check listening ports
    echo "Listening Ports:"
    listening_ports=$(sudo netstat -tlnp | grep LISTEN | wc -l)
    success "Total listening ports: $listening_ports"
    
    # Check for unexpected ports
    echo
    echo "Port Analysis:"
    sudo netstat -tlnp | grep LISTEN | while read line; do
        port=$(echo "$line" | awk '{print $4}' | cut -d: -f2)
        if [[ "$port" =~ ^(22|80|443|61208)$ ]]; then
            success "Port $port is expected (SSH/HTTP/HTTPS/Glances)"
        else
            warning "Unexpected port $port listening"
        fi
    done
    
    # Check network connections
    echo
    echo "Network Connections:"
    active_connections=$(sudo netstat -an | grep ESTABLISHED | wc -l)
    success "Active connections: $active_connections"
    
    echo
}

# System Logging Checks
check_system_logging() {
    log "Checking System Logging Configuration..."
    echo "=========================================="
    
    # Check journald status
    if systemctl is-active --quiet systemd-journald; then
        success "systemd-journald is running"
    else
        error "systemd-journald is not running"
    fi
    
    # Check recent failed login attempts
    echo
    echo "Recent Failed Login Attempts:"
    failed_logins=$(sudo journalctl | grep "Failed password" | wc -l)
    if [[ "$failed_logins" -eq 0 ]]; then
        success "No failed login attempts found"
    else
        warning "Found $failed_logins failed login attempts"
        
        # Show recent failed attempts
        echo "Recent failed attempts:"
        sudo journalctl | grep "Failed password" | tail -3
    fi
    
    # Check SSH logs
    echo
    echo "SSH Log Analysis:"
    ssh_connections=$(sudo journalctl | grep "sshd" | grep "Accepted" | wc -l)
    success "Successful SSH connections: $ssh_connections"
    
    echo
}

# Security Score Calculation
calculate_security_score() {
    log "Calculating Security Score..."
    echo "=========================================="
    
    total_checks=0
    passed_checks=0
    
    # Count checks (this is a simplified version)
    # In a real implementation, you'd track each check individually
    
    echo "Security Assessment Complete!"
    echo
    echo "Recommendations:"
    echo "1. Review any warnings or errors above"
    echo "2. Ensure all security measures are properly configured"
    echo "3. Run this check regularly to maintain security"
    echo "4. Monitor system logs for suspicious activity"
    echo "5. Keep system packages updated"
    
    echo
}

# Main execution
main() {
    echo "=== Linux Server Security Check ==="
    echo "This script will validate all security measures on your server"
    echo
    
    # Check prerequisites
    check_root
    check_sudo
    
    # Run all security checks
    check_ssh_security
    check_firewall_security
    check_user_security
    check_ssh_keys
    check_system_monitoring
    check_network_security
    check_system_logging
    
    # Calculate and display security score
    calculate_security_score
    
    echo "Security check completed!"
    echo "Run 'security-check' anytime to re-validate your configuration."
}

# Run main function
main "$@"
