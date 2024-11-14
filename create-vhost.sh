#!/bin/env bash

# Default values
USE_IPV6=false
SERVER_ALIAS=""
ERROR_LOG=""
ACCESS_LOG=""
SSL_KEY_DIR="$HOME/.local/certs/"

# Check if WSL2 environment
is_wsl2() {
    grep -qEi "(Microsoft|WSL2)" /proc/version &> /dev/null
    return $? # 0 if WSL2, 1 if not
    # systemd-detect-virt -q -v &> /dev/null
    # return $? # 0 if WSL2, 1 if not
}

# Edit /etc/hosts or Windows hosts file based on environment
edit_hosts() {
    WSL2=$(systemd-detect-virt)
    if [[ -z $WSL2 ]]; then
        # Use PowerShell command to edit Windows hosts file if in WSL2
        if powershell.exe -Command "Get-Content C:\Windows\System32\drivers\etc\hosts" | grep -q "$DOMAIN_NAME"; then
            echo "$DOMAIN_NAME already exists in Windows hosts file."
        else
            powershell.exe -Command "Add-Content C:\Windows\System32\drivers\etc\hosts '127.0.0.1 $DOMAIN_NAME'"
            echo "Added $DOMAIN_NAME to Windows hosts file."
        fi
    elif [[ "$DISTRO" == "gentoo" ]]; then
        if grep -q "$DOMAIN_NAME" /etc/hosts; then
            echo "$DOMAIN_NAME already exists in /etc/hosts."
        else
            echo "127.0.0.1 $DOMAIN_NAME" | sudo tee -a /etc/hosts > /dev/null
            echo "Added $DOMAIN_NAME to /etc/hosts."
        fi
    fi
}


# Edit /etc/hosts according to Distribution and system  (linux or windows)
edit_hosts() {
    if [[ "$DISTRO" == "ubuntu" ]]; then
        if grep -q "$DOMAIN_NAME" /etc/hosts; then
            echo "$DOMAIN_NAME already exists in /etc/hosts."
        # else
        fi
    else #gentoo
        # Add entry to /etc/hosts for local development
        if grep -q "$DOMAIN_NAME" /etc/hosts; then
            echo "$DOMAIN_NAME already exists in /etc/hosts."
        else
            echo "127.0.0.1 $DOMAIN_NAME" | sudo tee -a /etc/hosts > /dev/null
            echo "Added $DOMAIN_NAME to /etc/hosts."
        fi
    fi
}


# Detect Distribution if not specified
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=${DISTRO:-$ID}
else
    echo "Warning: Distribution not supported by this script."
    #exit 1
fi

# Function to display help
function usage() {
    echo "Usage: sudo $0 -t <document_root> -n <domain_name> -k <ssl_key> -c <ssl_cert> [-d <ubuntu|gentoo>] [-a <server_alias>] [-6]"
    echo "  -t  Root document directory (required)"
    echo "  -n  Domain name (required)"
    echo "  -k  SSL directory (optional, default is already defined) where key and crt are   locateed"
    echo "  -d  Distribution (ubuntu or gentoo) (optional, auto-detects if omitted)"
    echo "  -a  Server alias (optional, e.g., www.example.com)"
    echo "  -6  Enable IPv6 (optional)"
    exit 1
}

# Parse arguments
while getopts "t:n:k:c:d:a:6" opt; do
    case "$opt" in
        t) DOC_ROOT=$OPTARG ;;
        n) DOMAIN_NAME=$OPTARG ;;
        k) SSL_KEY_DIR=$OPTARG ;;
        d) DISTRO=$OPTARG ;;
        a) SERVER_ALIAS=$OPTARG ;;
        6) USE_IPV6=true ;;
        *) usage ;;
    esac
done

# Ensure required parameters are provided
if [[ -z "$DOC_ROOT" || -z "$DOMAIN_NAME"   ]]; then
    usage
fi

if [[ -d "$SSL_KEY_DIR$DOMAIN_NAME" ]]; then
    files=($SSL_KEY_DIR$DOMAIN_NAME/*)
    for file in "${files[@]}"; do
        if [[ "$file" == *".key" ]]; then
            SSL_KEY=$file
        elif [[ "$file" == *".crt" ]]; then
            SSL_CERT=$file
        fi
    done
    echo "SSL files found in $SSL_KEY_DIR$DOMAIN_NAME"
    echo "SSL key: $SSL_KEY"
    echo "SSL cert: $SSL_CERT"
fi

# Check if SSL files were found
if [[ -z "$SSL_CERT" || -z "$SSL_KEY" ]]; then
    echo "Error: SSL certificate or key file not found in the specified directory."
    echo "Expected file names include '${DOMAIN_NAME}.crt' and '${DOMAIN_NAME}.key'."
    exit 1
fi



# Validate or default the distribution
#if [[ -z "$DISTRO" ]]; then
    #DISTRO=$ID
#elif [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "gentoo" ]]; then
    #echo "Error: Invalid distribution. Please choose 'ubuntu' or 'gentoo'."
    #usage
#fi


# Set virtual host configuration file path based on the distro
if [[ "$DISTRO" == "ubuntu" ]]; then
    VHOST_CONF="/etc/apache2/sites-available/${DOMAIN_NAME}.conf"
else
    VHOST_CONF="/etc/apache2/vhosts.d/${DOMAIN_NAME}.conf"
fi

# Define log file paths
ERROR_LOG="/var/log/apache2/${DOMAIN_NAME}_error.log"
ACCESS_LOG="/var/log/apache2/${DOMAIN_NAME}_access.log"

# Create the main virtual host configuration
sudo tee "$VHOST_CONF" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
EOF

if [[ ! -z "$SERVER_ALIAS" ]]; then
    sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
    ServerAlias $SERVER_ALIAS
EOF
fi

sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
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

if [[ ! -z "$SERVER_ALIAS" ]]; then
    sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
    ServerAlias $SERVER_ALIAS
EOF
fi

sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
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
    sudo tee -a "$VHOST_CONF" > /dev/null <<EOF

<VirtualHost [::]:80>
    ServerName $DOMAIN_NAME
EOF

    if [[ ! -z "$SERVER_ALIAS" ]]; then
        sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
    ServerAlias $SERVER_ALIAS
EOF
    fi

    sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
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
        sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
    ServerAlias $SERVER_ALIAS
EOF
    fi

    sudo tee -a "$VHOST_CONF" > /dev/null <<EOF
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

# Add entry to /etc/hosts for local development
edit_hosts

# Enable site and restart Apache depending on the distribution
if [[ "$DISTRO" == "ubuntu" ]]; then
    sudo a2ensite ${DOMAIN_NAME}.conf
    sudo systemctl restart apache2
else
    sudo /etc/init.d/apache2 restart
fi

echo "Virtual host configuration created and Apache restarted for $DISTRO."
