#!/bin/env bash

#!/bin/env bash

# Default values
CERT_NAME=$(date +%s | sha256sum | base64 | head -c 8)
KEY_SIZE=409 6
DAYS_VALID=365
BASE_DIR="$HOME/.local/certs/"
DIRNAME=""

# Function to generate a random name
# generate_random_name() {
#     echo "$(date +%s | sha256sum | base64 | head -c 8)"
# }

# Function to display help
function usage() {
    echo "Usage: sudo $0 -d <domain_name> [-k <key_size>] [-v <days_valid>] [-o <output_dir>] [-n <name>] []"
    echo "Options:"
    echo "  -c  Certificate name (optional, default is a random name)"
    echo "  -d  Domain name (required, e.g., example.com)"
    echo "  -k  Key size (optional, default is 2048)"
    echo "  -v  Validity in days (optional, default is 365)"
    echo "  -o  Output directory (optional, default is ~/local/certs/)"
    echo "  -n  Custom directory name for the key and cert (optional)"
    exit 1
}

# Parse arguments
while getopts "c:d:k:v:o:n::" opt; do
    case "$opt" in
        c) CERT_NAME=$OPTARG ;;
        d) DOMAIN_NAME=$OPTARG ;;
        k) KEY_SIZE=$OPTARG ;;
        v) DAYS_VALID=$OPTARG ;;
        o) DIRNAME=$OPTARG ;;
        n)
            if [[ -z $OPTARG ]]; then
                read -p "Enter a name for the output files: " DIRNAME
            else
                DIRNAME=$OPTARG
            fi
            ;;
        *) usage ;;
    esac
done

# Ensure domain name is provided
if [[ -z "$DOMAIN_NAME" ]]; then
    usage
fi

# Generate a random name if DIRNAME is not set
if [[ -z "$DIRNAME" ]]; then
    # DIRNAME=$(generate_random_name)
    DIRNAME=$$


    
fi

# Set file paths
KEY_FILE="$BASE_DIR/$DIRNAME/$CERT_NAME.key"
CERT_FILE="$BASE_DIR/$DIRNAME/$CERT_NAME.crt"

# Create output directory if it doesn't exist
mkdir -p "$BASE_DIR/$DIRNAME"

# Generate private key
echo "Generating a private key..."
sudo openssl genpkey -algorithm RSA -out "$KEY_FILE" -pkeyopt rsa_keygen_bits:$KEY_SIZE

# Generate certificate signing request (CSR)
echo "Generating a certificate signing request (CSR)..."
sudo openssl req -new -key "$KEY_FILE" -out "$BASE_DIR/$DIRNAME/$CERT_NAME.csr" -subj "/CN=$DOMAIN_NAME"

# Generate self-signed certificate
echo "Generating a self-signed certificate..."
sudo openssl x509 -req -days "$DAYS_VALID" -in "$BASE_DIR/$DIRNAME/$CERT_NAME.csr" -signkey "$KEY_FILE" -out "$CERT_FILE"

# Cleanup CSR file (optional)
sudo rm "$BASE_DIR/$DIRNAME/$CERT_NAME.csr"

echo "SSL certificate and key generated:"
echo "  Key:  $KEY_FILE"
echo "  Cert: $CERT_FILE"
