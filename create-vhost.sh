#!/bin/env bash

# Default values
USE_IPV6=false
DISTRO=""

# Function to display help
function usage() {
    echo "Usage: sudo $0 -t <document_root> -k <ssl_key> -c <ssl_cert> -d <ubuntu|gentoo> [-6]"
    echo "  -t  Root document directory (required)"
    echo "  -k  SSL key file path (required for port 443)"
    echo "  -c  SSL certificate file path (required for port 443)"
    echo "  -d  Distribution (ubuntu or gentoo) (required)"
    echo "  -6  Enable IPv6 (optional)"
    exit 1
}

# Parse arguments
while getopts "t:k:c:d:6" opt; do
    case "$opt" in
        t) DOC_ROOT=$OPTARG ;;
        k) SSL_KEY=$OPTARG ;;
        c) SSL_CERT=$OPTARG ;;
        d) DISTRO=$OPTARG ;;
        6) USE_IPV6=true ;;
        *) usage ;;
    esac
done

# Ensure required parameters are provided
if [[ -z "$DOC_ROOT" || -z "$SSL_KEY" || -z "$SSL_CERT" || -z "$DISTRO" ]]; then
    usage
fi

# Validate distribution choice
if [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "gentoo" ]]; then
    echo "Error: Invalid distribution. Please choose 'ubuntu' or 'gentoo'."
    usage
fi

# Set virtual host configuration file path based on the distro
if [[ "$DISTRO" == "ubuntu" ]]; then
    VHOST_CONF="/etc/apache2/sites-available/$(basename $DOC_ROOT).conf"
else
    VHOST_CONF="/etc/apache2/vhosts.d/$(basename $DOC_ROOT).conf"
fi

# Create the virtual host configuration file
sudo cat <<EOF > $VHOST_CONF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile $SSL_CERT
    SSLCertificateKeyFile $SSL_KEY

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Add IPv6 configuration if enabled
if [ "$USE_IPV6" = true ]; then
    sudo cat <<EOF >> $VHOST_CONF

<VirtualHost [::]:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<VirtualHost [::]:443>
    ServerAdmin webmaster@localhost
    DocumentRoot $DOC_ROOT

    <Directory $DOC_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile $SSL_CERT
    SSLCertificateKeyFile $SSL_KEY

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
fi

# Enable site and restart Apache depending on the distribution
if [[ "$DISTRO" == "ubuntu" ]]; then
    # Ubuntu: Enable site and restart Apache
    sudo a2ensite $(basename $DOC_ROOT).conf
    sudo systemctl restart apache2
else
    # Gentoo: Just restart Apache
    sudo /etc/init.d/apache2 restart
fi

echo "Virtual host configuration created and Apache restarted for $DISTRO."

