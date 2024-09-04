#!/bin/bash

# Define the directories
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
NGINX_CONF_DIR="/etc/nginx/sites-available"

# Check if NGINX_ENABLED_DIR exists
if [ ! -d "$NGINX_ENABLED_DIR" ]; then
    echo "Error: NGINX enabled sites directory not found at $NGINX_ENABLED_DIR."
    exit 1
fi

# Function to check the status of a website
check_status() {
    DOMAIN=$1

    # Check HTTP status
    HTTP_STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" http://$DOMAIN)
    
    if [ "$HTTP_STATUS_CODE" -eq 200 ]; then
        echo "UP (HTTP)"
    elif [ "$HTTP_STATUS_CODE" -eq 301 ]; then
        # If HTTP redirects, check HTTPS
        HTTPS_STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" https://$DOMAIN)
        
        if [ "$HTTPS_STATUS_CODE" -eq 200 ]; then
            echo "UP (HTTPS)"
        else
            echo "DOWN (HTTP 301 -> HTTPS $HTTPS_STATUS_CODE)"
        fi
    elif [ "$HTTP_STATUS_CODE" -eq 000 ]; then
        echo "UNREACHABLE"
    else
        echo "DOWN (HTTP $HTTP_STATUS_CODE)"
    fi
}

# Print table header
printf "%-30s %-30s\n" "Domain" "Status"
printf "%-30s %-30s\n" "------" "------"

# Loop through all enabled sites
for FILE in $NGINX_ENABLED_DIR/*; do
    DOMAIN=$(basename $FILE)
    
    # Check if the config file exists in the sites-available directory
    if [ -f "$NGINX_CONF_DIR/$DOMAIN" ]; then
        STATUS=$(check_status $DOMAIN)
        printf "%-30s %-30s\n" $DOMAIN "$STATUS"
    else
        printf "%-30s %-30s\n" $DOMAIN "Config Missing"
    fi
done
