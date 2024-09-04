#!/bin/bash

DOMAIN=$1
WWW_DIR="/var/www/$DOMAIN"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
BUILD_DIR="/home/ubuntu/website-deploy/website_builds"  # Directory containing the build files

# Check if domain argument is provided
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 domain"
    exit 1
fi

# Check if domain already exists
if [ -f "$NGINX_CONF_DIR/$DOMAIN" ]; then
    echo "Error: A site with the domain $DOMAIN already exists."
    exit 1
fi

# Create the website directory
mkdir -p $WWW_DIR

# Deploy the build files
if [ -d "$BUILD_DIR/$DOMAIN" ]; then
    cp -r $BUILD_DIR/$DOMAIN/* $WWW_DIR/
    echo "Build files have been copied to $WWW_DIR."
else
    echo "Error: Build directory $BUILD_DIR/$DOMAIN does not exist."
    exit 1
fi

# Copy and modify the Nginx configuration for SSL
CONF_FILE="$NGINX_CONF_DIR/$DOMAIN"
cp /home/ubuntu/website-deploy/scripts/site_template.conf $CONF_FILE

sed -i "s/yourdomain.com/$DOMAIN/g" $CONF_FILE

# Enable the site
ln -s $CONF_FILE $NGINX_ENABLED_DIR/$DOMAIN
echo "Symlink for $DOMAIN created."

# Reload Nginx
systemctl reload nginx
echo "Nginx reloaded with new configuration."

# Obtain SSL certificate using Certbot
echo "Requesting SSL certificate for $DOMAIN and www.$DOMAIN..."
if certbot certonly --webroot -w $WWW_DIR -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email mathias.devops@gmail.com; then
    echo "SSL certificate obtained for $DOMAIN and www.$DOMAIN."

    # Reload Nginx to apply the HTTPS configuration
    systemctl reload nginx
    echo "Nginx reloaded with HTTPS configuration."
else
    echo "Error: Failed to obtain SSL certificate."
    exit 1
fi
