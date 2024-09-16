#!/bin/env bash

# Festlegung der Variablen
DOMAIN="arbeit.local"
DOMAIN_ROOT="/mnt/arbeit"
APACHE_CONF="/etc/apache2/vhosts.d/${DOMAIN}-ssl.conf"
CERT_DIR="/etc/ssl/localcerts"
KEY_FILE="${CERT_DIR}/${DOMAIN}.key"
CERT_FILE="${CERT_DIR}/${DOMAIN}.crt"
DAYS_VALID=365

######################################################
# function
# ####################################################

# Erstelle eine Apache VirtualHost-Konfiguration
function vhost() {
    local conf
    conf="
    <VirtualHost *:443>
        ServerAdmin webmaster@$DOMAIN
        ServerName $DOMAIN

        DocumentRoot $DOMAIN_ROOT

        SSLEngine on
        SSLCertificateFile /etc/ssl/localcerts/$DOMAIN.crt
        SSLCertificateKeyFile /etc/ssl/localcerts/$DOMAIN.key

        <Directory $DOMAIN_ROOT>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog /var/log/apache2/$DOMAIN-ssl-error.log
        CustomLog /var/log/apache2/$DOMAIN-ssl-access.log combined
    </VirtualHost>

    "

    echo "copying $conf to $APACHE_CONF"
    sudo echo $conf > $APACHE_CONF
}

######################################################
# argument parsing
######################################################

while [ $# -gt 0 ];do
    case $1 in
        -d)
            shift
            DOMAIN="$1"
            ;;
        -r|--document-root)
            shift
            DOMAIN_ROOT="$1"
            ;;
        -a|--apache-conf)
            shift
            $APACHE_CONF="$1"
            ;;
        --ssl)
            sleep 2
            vhost
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done

######################################################
# main
######################################################

# Prüfe, ob ein Domainname übergeben wurde
if [ -z "$DOMAIN" ]; then
    echo "Bitte eine Domain angeben, z.B. ./create_ssl_cert.sh example.local"
    exit 1
fi

# Erstelle das Verzeichnis für die Zertifikate, falls es noch nicht existiert
if [ ! -d "$CERT_DIR" ]; then
    sudo mkdir -p "$CERT_DIR"
fi

# Generiere den privaten Schlüssel und das selbstsignierte Zertifikat
echo "Erstelle den privaten Schlüssel und das selbstsignierte Zertifikat für $DOMAIN ..."

sudo openssl req -x509 -nodes -days $DAYS_VALID -newkey rsa:2048 \
    -keyout "$KEY_FILE" -out "$CERT_FILE" \
    -subj "/C=DE/ST=YourState/L=YourCity/O=YourOrg/OU=YourUnit/CN=$DOMAIN"

# Berechtigungen setzen
sudo chmod 600 "$KEY_FILE" "$CERT_FILE"

# Ausgabe der Dateipfade
echo "Zertifikat und Schlüssel erstellt:"
echo "Privater Schlüssel: $KEY_FILE"
echo "Zertifikat: $CERT_FILE"


echo -e "\nZertifikat für $DOMAIN erfolgreich erstellt und gespeichert unter $CERT_DIR"

