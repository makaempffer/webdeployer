#!/bin/bash

DOMAIN=$1
USE_SSL=$2  # Pass "ssl" as the second argument to enable SSL
WWW_DIR="/var/www/$DOMAIN"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
BUILD_DIR="/home/ubuntu/website-deploy/website_builds"  # Directory containing the build files

# Check if domain argument is provided
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 domain [ssl]"
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

# Copy and modify the Nginx configuration
CONF_FILE="$NGINX_CONF_DIR/$DOMAIN"
if [ "$USE_SSL" == "ssl" ]; then
    cp /home/ubuntu/website-deploy/scripts/site_template.conf $CONF_FILE
else
    cp /home/ubuntu/website-deploy/scripts/non_ssl_site_template.conf $CONF_FILE
fi

sed -i "s/yourdomain.com/$DOMAIN/g" $CONF_FILE

# Enable the site
ln -s $CONF_FILE $NGINX_ENABLED_DIR/$DOMAIN
echo "Symlink for $DOMAIN created."

# Reload Nginx
systemctl reload nginx
echo "Nginx reloaded with new configuration."

if [ "$USE_SSL" == "ssl" ]; then
    # Obtain SSL certificate for both main domain and www subdomain
    echo "Requesting SSL certificate for $DOMAIN and www.$DOMAIN..."
    if certbot certonly -v --dry-run --webroot -w $WWW_DIR -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email mathias.devops@gmail.com --debug-challenges; then
        echo "SSL certificate obtained for $DOMAIN and www.$DOMAIN."

        # Wait for certificate files to be created
        while [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; do
            echo "Waiting for certificates to be created..."
            sleep 5
        done

        # Set permissions for SSL certificates
        chown -R root:root /etc/letsencrypt
        chmod -R 755 /etc/letsencrypt
        chmod 644 /etc/letsencrypt/live/$DOMAIN/fullchain.pem
        chmod 600 /etc/letsencrypt/live/$DOMAIN/privkey.pem

        # Reload Nginx to apply the HTTPS configuration
        if systemctl reload nginx; then
            echo "Nginx reloaded with HTTPS configuration."
        else
            echo "Error: Failed to reload Nginx after obtaining SSL certificate."
            exit 1
        fi
    else
        echo "Error: Failed to obtain SSL certificate."
        exit 1
    fi
fi
