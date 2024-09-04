#!/bin/bash

# Define directories
NGINX_CONF_DIR="/etc/nginx/sites-available"
CERT_DIR="/etc/letsencrypt/live"

# Helper function to print a separator
print_separator() {
    echo "==============================================="
}

# Function to check if a certificate file exists
check_certificate_file() {
    local cert_file="$1"
    if [ -f "$cert_file" ]; then
        echo "Certificate file found: $cert_file"
    else
        echo "Certificate file missing: $cert_file"
    fi
}

# Function to check certificates in Nginx configuration files
check_nginx_certificates() {
    print_separator
    echo "Checking certificates in Nginx configuration files..."

    # Find all certificate paths in Nginx configuration files
    grep -r -E 'ssl_certificate|ssl_certificate_key' $NGINX_CONF_DIR | while read -r line; do
        cert_path=$(echo $line | grep -oP '(?<=ssl_certificate\s)[^\s]*')
        key_path=$(echo $line | grep -oP '(?<=ssl_certificate_key\s)[^\s]*')

        # Check if the certificate and key files exist
        if [ ! -z "$cert_path" ]; then
            check_certificate_file "$cert_path"
        fi

        if [ ! -z "$key_path" ]; then
            check_certificate_file "$key_path"
        fi
    done
}

# Function to check if directories and files for SSL certificates exist
check_certificates() {
    print_separator
    echo "Checking SSL certificates..."

    # Check SSL certificates in the /etc/letsencrypt/live directory
    if [ -d "$CERT_DIR" ]; then
        for domain_dir in $CERT_DIR/*; do
            if [ -d "$domain_dir" ]; then
                domain=$(basename "$domain_dir")
                echo "Checking SSL certificates for domain: $domain"

                # Check certificate files
                check_certificate_file "$domain_dir/fullchain.pem"
                check_certificate_file "$domain_dir/privkey.pem"
            fi
        done
    else
        echo "Certificate directory $CERT_DIR does not exist."
    fi
}

# Run the functions
check_nginx_certificates
check_certificates

print_separator
echo "Certificate check completed."
