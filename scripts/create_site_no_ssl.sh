#!/bin/bash

# Check if domain argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1
WWW_DIR="/var/www/$DOMAIN"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
BUILD_DIR="/home/ubuntu/website-deploy/website_builds"  # Directory containing the build files

# Check if domain already exists
if [ -f "$NGINX_CONF_DIR/$DOMAIN.conf" ]; then
    echo "Error: A site with the domain $DOMAIN already exists."
    exit 1
fi

# Create the website directory
sudo mkdir -p $WWW_DIR

# Deploy the build files
if [ -d "$BUILD_DIR/$DOMAIN" ]; then
    sudo cp -r $BUILD_DIR/$DOMAIN/* $WWW_DIR/
    echo "Build files have been copied to $WWW_DIR."
else
    echo "Error: Build directory $BUILD_DIR/$DOMAIN does not exist."
    exit 1
fi

# Copy and modify the Nginx configuration
CONF_FILE="$NGINX_CONF_DIR/$DOMAIN.conf"
sudo cp /home/ubuntu/website-deploy/scripts/site_template.conf $CONF_FILE

# Update configuration with domain
sudo sed -i "s/yourdomain.com/$DOMAIN/g" $CONF_FILE

# Enable the site
if [ ! -L "$NGINX_ENABLED_DIR/$DOMAIN.conf" ]; then
    sudo ln -s $CONF_FILE $NGINX_ENABLED_DIR/
    echo "Symlink for $DOMAIN created."
else
    echo "Symlink for $DOMAIN already exists."
fi

# Test the Nginx configuration and reload
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "Nginx configuration is valid and reloaded."
else
    echo "Error: Nginx configuration test failed."
    exit 1
fi

echo "Site setup for $DOMAIN completed successfully."
