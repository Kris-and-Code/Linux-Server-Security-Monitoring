# Linux Server Security & Monitoring

A comprehensive demonstration project showcasing Linux server security hardening, monitoring, and system administration skills.

## 🚀 Project Overview

This project demonstrates essential Linux server security practices including:
- **Firewall Configuration** (UFW)
- **SSH Security Hardening**
- **System Monitoring Tools**
- **Log Management & Analysis**
- **Security Best Practices**

## 📁 Project Structure

```
linux-security-monitoring/
├── Dockerfile                 # Ubuntu server container setup
├── docker-compose.yml         # Container orchestration
├── SECURITY.md               # Detailed security documentation
├── scripts/                  # Automation scripts
│   ├── security-setup.sh     # Security hardening script
│   ├── monitoring-setup.sh   # Monitoring tools setup
│   └── security-check.sh     # Security validation script
└── README.md                 # This file
```

## 🛠️ Quick Start

### Prerequisites
- Docker and Docker Compose
- SSH client (for key-based authentication)
- Basic Linux command line knowledge

### 1. Build and Start the Container
```bash
# Build the secure Ubuntu server
docker-compose up -d --build

# Check container status
docker-compose ps
```

### 2. Generate SSH Keys (if you don't have them)
```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key to container
docker cp ~/.ssh/id_ed25519.pub linux-security-monitoring_server_1:/tmp/
```

### 3. Access the Server
```bash
# Connect to the container
docker exec -it linux-security-monitoring_server_1 bash

# Or SSH into the container (after key setup)
ssh admin@localhost -p 2222
```

## 🔒 Security Features Implemented

- **UFW Firewall**: Only ports 22, 80, 443 allowed
- **SSH Hardening**: Key-based auth only, root login disabled
- **User Management**: Non-root admin user with sudo privileges
- **System Monitoring**: htop, glances, journald logging
- **Security Scripts**: Automated setup and validation

## 📊 Monitoring Tools

- **htop**: Real-time system resource monitoring
- **glances**: Advanced system monitoring with web interface
- **journald**: System logging and log analysis
- **UFW**: Firewall status and rule management

## 🔍 Security Validation

Run the security check script to validate your setup:
```bash
# Inside the container
./scripts/security-check.sh

# Check firewall status
sudo ufw status verbose

# Verify SSH configuration
sudo sshd -T | grep -E "(password|root|key)"
```

## 📚 Documentation

- **SECURITY.md**: Comprehensive security documentation
- **Scripts**: Automated setup and validation tools
- **Dockerfile**: Container configuration details

## 🚨 Security Best Practices Demonstrated

1. **Principle of Least Privilege**: Non-root user with sudo access
2. **Network Security**: Firewall rules limiting access
3. **Authentication**: Key-based SSH authentication
4. **Monitoring**: Real-time system resource tracking
5. **Logging**: Comprehensive system log management
6. **Automation**: Scripted security setup and validation

## 🤝 Contributing

This is a demonstration project. Feel free to:
- Add additional security measures
- Enhance monitoring capabilities
- Improve automation scripts
- Document additional best practices

## 📄 License

This project is for educational and demonstration purposes.

---


