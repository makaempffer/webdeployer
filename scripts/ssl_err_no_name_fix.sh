#!/bin/bash

# Ensure the script is run with two arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <domain> <email>"
    exit 1
fi

# Assign arguments to variables
DOMAIN=$1
EMAIL=$2

# Check if domain and email are provided
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Both domain and email must be provided."
    exit 1
fi

# Obtain SSL certificate
echo "Obtaining SSL certificate for $DOMAIN with email $EMAIL..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

# Check if certbot command was successful
if [ $? -eq 0 ]; then
    echo "SSL certificate successfully obtained for $DOMAIN."
else
    echo "Error: Failed to obtain SSL certificate for $DOMAIN."
    exit 1
fi
