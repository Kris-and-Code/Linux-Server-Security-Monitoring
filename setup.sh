#!/bin/bash

# Linux Server Security & Monitoring - Quick Setup Script
# This script helps you get started with the project

set -e

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

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    success "All prerequisites are met"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    mkdir -p data logs
    success "Directories created: data/, logs/"
}

# Generate SSH keys if they don't exist
generate_ssh_keys() {
    log "Checking SSH keys..."
    
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        warning "SSH key not found. Generating new key pair..."
        ssh-keygen -t ed25519 -C "linux-security-monitoring@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
        success "SSH key pair generated"
    else
        success "SSH key already exists"
    fi
    
    # Copy public key to data directory for container access
    cp ~/.ssh/id_ed25519.pub data/
    success "Public key copied to data/ directory"
}

# Build and start the container
build_and_start() {
    log "Building and starting the Linux security monitoring container..."
    
    # Build the image
    docker-compose build
    
    # Start the container
    docker-compose up -d
    
    success "Container built and started successfully"
}

# Wait for container to be ready
wait_for_container() {
    log "Waiting for container to be ready..."
    
    # Wait for container to start
    sleep 10
    
    # Check container status
    if docker-compose ps | grep -q "Up"; then
        success "Container is running"
    else
        error "Container failed to start"
        docker-compose logs
        exit 1
    fi
}

# Display connection information
show_connection_info() {
    log "=== Connection Information ==="
    echo
    echo "Container Status:"
    docker-compose ps
    echo
    echo "Access Information:"
    echo "SSH: ssh admin@localhost -p 2222"
    echo "Web Monitor: http://localhost:61208"
    echo "HTTP: http://localhost:8080"
    echo "HTTPS: https://localhost:8443"
    echo
    echo "Container Logs:"
    echo "docker-compose logs -f"
    echo
    echo "Access Container:"
    echo "docker exec -it linux-security-monitoring bash"
    echo
    echo "Stop Container:"
    echo "docker-compose down"
    echo
    echo "Security Check:"
    echo "docker exec -it linux-security-monitoring security-check"
    echo
    echo "Monitoring Dashboard:"
    echo "docker exec -it linux-security-monitoring monitor-dashboard"
}

# Main execution
main() {
    echo "=== Linux Server Security & Monitoring - Quick Setup ==="
    echo "This script will set up the complete environment for you"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Create directories
    create_directories
    
    # Generate SSH keys
    generate_ssh_keys
    
    # Build and start container
    build_and_start
    
    # Wait for container
    wait_for_container
    
    # Show connection information
    show_connection_info
    
    echo
    success "Setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. SSH into the container: ssh admin@localhost -p 2222"
    echo "2. Run security check: docker exec -it linux-security-monitoring security-check"
    echo "3. Access web monitoring: http://localhost:61208"
    echo "4. Explore the monitoring tools: htop, glances, etc."
    echo
    echo "For more information, see README.md and SECURITY.md"
}

# Run main function
main "$@"
