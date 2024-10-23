#!/bin/env bash

# Default values
KEY_SIZE=2048
DAYS_VALID=365
OUTPUT_DIR="./"

# Function to display help
function usage() {
    echo "Usage: sudo $0 -d <domain_name> [-k <key_size>] [-v <days_valid>] [-o <output_dir>]"
    echo "  -d  Domain name (required, e.g., example.com)"
    echo "  -k  Key size (optional, default is 2048)"
    echo "  -v  Validity in days (optional, default is 365)"
    echo "  -o  Output directory (optional, default is current directory)"
    exit 1
}

# Parse arguments
while getopts "d:k:v:o:" opt; do
    case "$opt" in
        d) DOMAIN_NAME=$OPTARG ;;
        k) KEY_SIZE=$OPTARG ;;
        v) DAYS_VALID=$OPTARG ;;
        o) OUTPUT_DIR=$OPTARG ;;
        *) usage ;;
    esac
done

# Ensure domain name is provided
if [[ -z "$DOMAIN_NAME" ]]; then
    usage
fi

# Set file paths
KEY_FILE="$OUTPUT_DIR/$DOMAIN_NAME.key"
CERT_FILE="$OUTPUT_DIR/$DOMAIN_NAME.crt"

# Create output directory if it doesn't exist (with sudo)
sudo mkdir -p $OUTPUT_DIR

# Generate private key
echo "Generating a private key..."
sudo openssl genpkey -algorithm RSA -out $KEY_FILE -pkeyopt rsa_keygen_bits:$KEY_SIZE

# Generate certificate signing request (CSR)
echo "Generating a certificate signing request (CSR)..."
sudo openssl req -new -key $KEY_FILE -out $OUTPUT_DIR/$DOMAIN_NAME.csr -subj "/CN=$DOMAIN_NAME"

# Generate self-signed certificate
echo "Generating a self-signed certificate..."
sudo openssl x509 -req -days $DAYS_VALID -in $OUTPUT_DIR/$DOMAIN_NAME.csr -signkey $KEY_FILE -out $CERT_FILE

# Cleanup CSR file (optional)
sudo rm $OUTPUT_DIR/$DOMAIN_NAME.csr

echo "SSL certificate and key generated:"
echo "  Key:  $KEY_FILE"
echo "  Cert: $CERT_FILE"
