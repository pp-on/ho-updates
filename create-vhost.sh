#!/bin/env bash

# Default values
USE_IPV6=false
DISTRO=""
SERVER_ALIAS=""
ERROR_LOG=""
ACCESS_LOG=""

# Function to display help
function usage() {
    echo "Usage: sudo $0 -t <document_root> -n <domain_name> -k <ssl_key> -c <ssl_cert> -d <ubuntu|gentoo> [-a <server_alias>] [-6]"
    echo "  -t  Root document directory (required)"
    echo "  -n  Domain name (required)"
    echo "  -k  SSL key file fullpath (required for port 443)"
    echo "  -c  SSL certificate file fullpath (required for port 443)"
    echo "  -d  Distribution (ubuntu or gentoo) (required)"
    echo "  -a  Server alias (optional, e.g., www.example.com)"
    echo "  -6  Enable IPv6 (optional)"
    exit 1
}

# Parse arguments
while getopts "t:n:k:c:d:a:6" opt; do
    case "$opt" in
        t) DOC_ROOT=$OPTARG ;;
        n) DOMAIN_NAME=$OPTARG ;;
        k) SSL_KEY=$OPTARG ;;
        c) SSL_CERT=$OPTARG ;;
        d) DISTRO=$OPTARG ;;
        a) SERVER_ALIAS=$OPTARG ;;
        6) USE_IPV6=true ;;
        *) usage ;;
    esac
done

# Ensure required parameters are provided
if [[ -z "$DOC_ROOT" || -z "$DOMAIN_NAME" || -z "$SSL_KEY" || -z "$SSL_CERT" || -z "$DISTRO" ]]; then
    usage
fi

# Validate distribution choice
if [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "gentoo" ]]; then
    echo "Error: Invalid distribution. Please choose 'ubuntu' or 'gentoo'."
    usage
fi

# Set virtual host configuration file path based on the distro
if [[ "$DISTRO" == "ubuntu" ]]; then
    VHOST_CONF="/etc/apache2/sites-available/${DOMAIN_NAME}.conf"
else
    VHOST_CONF="/etc/apache2/vhosts.d/${DOMAIN_NAME}.conf"
fi

# Define log file paths
ERROR_LOG="/var/log/apache2/${DOMAIN_NAME}_error.log"
ACCESS_LOG="/var/log/apache2/${DOMAIN_NAME}_access.log"

# Create the virtual host configuration file
sudo cat <<EOF > $VHOST_CONF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
EOF

# If a ServerAlias is provided, include it
if [[ ! -z "$SERVER_ALIAS" ]]; then
    sudo cat <<EOF >> $VHOST_CONF
    ServerAlias $SERVER_ALIAS
EOF
fi

sudo cat <<EOF >> $VHOST_CONF
    ServerAdmin webmaster@$DOMAIN_NAME
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $ERROR_LOG
    CustomLog $ACCESS_LOG combined
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN_NAME
EOF

# If a ServerAlias is provided, include it for HTTPS as well
if [[ ! -z "$SERVER_ALIAS" ]]; then
    sudo cat <<EOF >> $VHOST_CONF
    ServerAlias $SERVER_ALIAS
EOF
fi

sudo cat <<EOF >> $VHOST_CONF
    ServerAdmin webmaster@$DOMAIN_NAME
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile $SSL_CERT
    SSLCertificateKeyFile $SSL_KEY

    ErrorLog $ERROR_LOG
    CustomLog $ACCESS_LOG combined
</VirtualHost>
EOF

# Add IPv6 configuration if enabled
if [ "$USE_IPV6" = true ]; then
    sudo cat <<EOF >> $VHOST_CONF

<VirtualHost [::]:80>
    ServerName $DOMAIN_NAME
EOF

    if [[ ! -z "$SERVER_ALIAS" ]]; then
        sudo cat <<EOF >> $VHOST_CONF
    ServerAlias $SERVER_ALIAS
EOF
    fi

    sudo cat <<EOF >> $VHOST_CONF
    ServerAdmin webmaster@$DOMAIN_NAME
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $ERROR_LOG
    CustomLog $ACCESS_LOG combined
</VirtualHost>

<VirtualHost [::]:443>
    ServerName $DOMAIN_NAME
EOF

    if [[ ! -z "$SERVER_ALIAS" ]]; then
        sudo cat <<EOF >> $VHOST_CONF
    ServerAlias $SERVER_ALIAS
EOF
    fi

    sudo cat <<EOF >> $VHOST_CONF
    ServerAdmin webmaster@$DOMAIN_NAME
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile $SSL_CERT
    SSLCertificateKeyFile $SSL_KEY

    ErrorLog $ERROR_LOG
    CustomLog $ACCESS_LOG combined
</VirtualHost>
EOF
fi

# Enable site and restart Apache depending on the distribution
if [[ "$DISTRO" == "ubuntu" ]]; then
    # Ubuntu: Enable site and restart Apache
    sudo a2ensite ${DOMAIN_NAME}.conf
    sudo systemctl restart apache2
else
    # Gentoo: Just restart Apache
    sudo /etc/init.d/apache2 restart
fi

echo "Virtual host configuration created and Apache restarted for $DISTRO."
