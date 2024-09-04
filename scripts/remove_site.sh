#!/bin/bash

DOMAIN=$1
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
WWW_DIR="/var/www/$DOMAIN"

# Check if domain argument is provided
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 domain"
    exit 1
fi

# Step 1: Remove the symbolic link from sites-enabled (Disable the site)
LINK_FILE="$NGINX_ENABLED_DIR/$DOMAIN"
if [ -L "$LINK_FILE" ]; then
    rm $LINK_FILE
    echo "Removed symbolic link $LINK_FILE."
else
    echo "Symbolic link $LINK_FILE does not exist."
fi

# Step 2: Test Nginx configuration and reload if valid (Apply the changes)
if nginx -t; then
    systemctl reload nginx
    echo "Nginx configuration reloaded."
else
    echo "Error: Nginx configuration test failed. Please check the configuration."
    exit 1
fi

# Step 3: Remove the site’s Nginx configuration file
CONF_FILE="$NGINX_CONF_DIR/$DOMAIN"
if [ -f "$CONF_FILE" ]; then
    rm $CONF_FILE
    echo "Removed Nginx configuration file $CONF_FILE."
else
    echo "Nginx configuration file $CONF_FILE does not exist."
fi

# Step 4: Delete the site’s directory from /var/www
if [ -d "$WWW_DIR" ]; then
    rm -rf $WWW_DIR
    echo "Removed website directory $WWW_DIR."
else
    echo "Website directory $WWW_DIR does not exist."
fi

# Step 5: Delete the SSL certificate (if applicable)
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
if [ -d "$CERT_DIR" ]; then
    certbot delete --cert-name $DOMAIN --non-interactive --agree-tos
    echo "Removed SSL certificate for $DOMAIN."
else
    echo "SSL certificate for $DOMAIN does not exist."
fi

# Optionally remove SSL certificate for www subdomain
WWW_CERT_DIR="/etc/letsencrypt/live/www.$DOMAIN"
if [ -d "$WWW_CERT_DIR" ]; then
    certbot delete --cert-name www.$DOMAIN --non-interactive --agree-tos
    echo "Removed SSL certificate for www.$DOMAIN."
else
    echo "SSL certificate for www.$DOMAIN does not exist."
fi

echo "Site $DOMAIN has been removed."
