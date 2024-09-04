#!/bin/bash

DOMAIN=$1
WWW_DIR="/var/www/$DOMAIN"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
BUILD_DIR="/home/ubuntu/website-deploy/website_builds/$DOMAIN"  # Directory containing the build files

# Step 1: Check if the domain already exists
if [ -f "$NGINX_CONF_DIR/$DOMAIN" ]; then
    echo "Error: A site with the domain $DOMAIN already exists."
    exit 1
fi

# Step 2: Create the website directory
mkdir -p $WWW_DIR

# Step 3: Deploy the build files
if [ -d "$BUILD_DIR" ]; then
    cp -r $BUILD_DIR/* $WWW_DIR/
    echo "Build files have been copied to $WWW_DIR."
else
    echo "Error: Build directory $BUILD_DIR does not exist."
    exit 1
fi

# Step 4: Copy and modify the Nginx configuration
CONF_FILE="$NGINX_CONF_DIR/$DOMAIN"
cp /home/ubuntu/website-deploy/scripts/react_site_template.conf $CONF_FILE

sed -i "s/yourdomain.com/$DOMAIN/g" $CONF_FILE

# Step 5: Enable the site
ln -s $CONF_FILE $NGINX_ENABLED_DIR/$DOMAIN

# Step 6: Test the Nginx configuration and reload
if nginx -t; then
    systemctl reload nginx
    echo "Site $DOMAIN has been set up and is ready to use."
else
    echo "Error: Nginx configuration test failed."
    exit 1
fi

# Step 7: Obtain SSL certificate
if ! certbot certificates | grep -q "$DOMAIN"; then
    echo "Obtaining SSL certificate for $DOMAIN..."
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email your-email@example.com
else
    echo "SSL certificate already exists for $DOMAIN."
fi
