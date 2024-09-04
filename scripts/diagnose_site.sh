#!/bin/bash

# Ensure the script is run with two arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <domain> <ip-address>"
    exit 1
fi

# Assign arguments to variables
DOMAIN=$1
IP=$2

# Helper functions
print_separator() {
    echo "==============================================="
}

# Check DNS resolution
check_dns() {
    print_separator
    echo "Checking DNS resolution for $DOMAIN..."
    dig +short $DOMAIN
    if [ $? -ne 0 ]; then
        echo "DNS resolution failed."
    else
        echo "DNS resolution successful."
    fi
}

# Check if the domain resolves to the correct IP
check_domain_ip() {
    print_separator
    echo "Checking if $DOMAIN resolves to $IP..."
    DNS_IP=$(dig +short $DOMAIN)
    if [ "$DNS_IP" == "$IP" ]; then
        echo "$DOMAIN resolves to the correct IP: $IP"
    else
        echo "$DOMAIN resolves to $DNS_IP instead of $IP"
    fi
}

# Check web server status
check_web_server() {
    print_separator
    echo "Checking web server status on port 80 and 443..."
    curl -Is http://$DOMAIN | head -n 10
    curl -Is https://$DOMAIN | head -n 10
}

# Check if Nginx is running
check_nginx() {
    print_separator
    echo "Checking Nginx status..."
    systemctl status nginx
}

# Check firewall rules
check_firewall() {
    print_separator
    echo "Checking firewall rules..."
    sudo ufw status verbose
}

# Check local DNS cache
check_local_dns_cache() {
    print_separator
    echo "Checking local DNS cache..."
    if command -v ipconfig > /dev/null; then
        echo "Clearing Windows DNS cache..."
        ipconfig /flushdns
    elif command -v systemd-resolve > /dev/null; then
        echo "Clearing Linux DNS cache..."
        sudo systemd-resolve --flush-caches
    elif command -v dscacheutil > /dev/null; then
        echo "Clearing macOS DNS cache..."
        sudo killall -HUP mDNSResponder
    else
        echo "DNS cache clear command not found for this OS."
    fi
}

# Check for ERR_NAME_NOT_RESOLVED error
check_err_name_not_resolved() {
    print_separator
    echo "Checking for ERR_NAME_NOT_RESOLVED error..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
    if [ "$HTTP_STATUS" -eq 000 ]; then
        echo "Error: ERR_NAME_NOT_RESOLVED detected for $DOMAIN."
    else
        echo "No ERR_NAME_NOT_RESOLVED error detected."
    fi
}

# Run diagnostic functions
check_dns
check_domain_ip
check_web_server
check_firewall
check_local_dns_cache
check_err_name_not_resolved
check_nginx

print_separator
echo "Diagnostic script completed."
