##!/bin/bash

# WordPress Local Installation Script - Optimized Version
# Author: Improved from original scripts
# Description: Automated WordPress installation with GitHub repository integration

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper functions
source "${SCRIPT_DIR}/wphelpfunctions.sh" 
source "${SCRIPT_DIR}/wpfunctionsinstall.sh"

# Default configuration - moved to top for better overview
readonly DEFAULT_CONFIG=(
    [DB_USER]="wordpress"
    [DB_PASS]="AM1uY+4C9l4#,1;V=xDAd."
    [DB_HOST]="localhost"
    [WP_EMAIL]="oswaldo.nickel@pfennigparade.de"
    [WP_USER]="test"
    [WP_PASS]="secret"
    [GIT_USER]="pfennigparade"
    [GIT_PROTOCOL]="https"
)

# Global variables
declare -A CONFIG
declare -g CURRENT_DIR INSTALL_MODE TARGET_DIR WP_CLI_PATH

# Initialize configuration with defaults
init_config() {
    for key in "${!DEFAULT_CONFIG[@]}"; do
        CONFIG["$key"]="${DEFAULT_CONFIG[$key]}"
    done
    
    CURRENT_DIR=$(basename "$PWD")
    CONFIG[DB_NAME]="${CURRENT_DIR//[^a-zA-Z0-9]/_}"
    CONFIG[WP_TITLE]="test${CURRENT_DIR^^}"
    CONFIG[WP_URL]="arbeit.local/repos/$CURRENT_DIR"
    CONFIG[GIT_REPO]="https://github.com/${CONFIG[GIT_USER]}/$CURRENT_DIR.git"
    
    INSTALL_MODE="standard"
    TARGET_DIR="."
    WP_CLI_PATH="wp"
}

# Improved logging with timestamps
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${Green}[${timestamp}] INFO: ${message}${Color_Off}" ;;
        "WARN")  echo -e "${Yellow}[${timestamp}] WARN: ${message}${Color_Off}" ;;
        "ERROR") echo -e "${Red}[${timestamp}] ERROR: ${message}${Color_Off}" ;;
        "DEBUG") echo -e "${Cyan}[${timestamp}] DEBUG: ${message}${Color_Off}" ;;
    esac
}

# Improved error handling
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Validation functions
validate_requirements() {
    log "INFO" "Validating requirements..."
    
    # Check if wp-cli is available
    if ! command -v "$WP_CLI_PATH" &> /dev/null; then
        error_exit "WP-CLI not found. Please install wp-cli first."
    fi
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        error_exit "Git not found. Please install git first."
    fi
    
    # Check if mysql is available
    if ! command -v mysql &> /dev/null; then
        error_exit "MySQL client not found. Please install mysql client first."
    fi
    
    log "INFO" "All requirements satisfied"
}

# Improved argument parsing with validation
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --new)
                INSTALL_MODE="new"
                CONFIG[WP_URL]="arbeit.local/wp/$CURRENT_DIR"
                shift
                ;;
            -n|--db-name)
                [[ -z "$2" ]] && error_exit "Database name cannot be empty"
                CONFIG[DB_NAME]="$2"
                shift 2
                ;;
            -u|--db-user)
                [[ -z "$2" ]] && error_exit "Database user cannot be empty"
                CONFIG[DB_USER]="$2"
                shift 2
                ;;
            -p|--db-pass)
                [[ -z "$2" ]] && error_exit "Database password cannot be empty"
                CONFIG[DB_PASS]="$2"
                shift 2
                ;;
            -h|--db-host)
                [[ -z "$2" ]] && error_exit "Database host cannot be empty"
                CONFIG[DB_HOST]="$2"
                shift 2
                ;;
            -t|--title)
                [[ -z "$2" ]] && error_exit "WordPress title cannot be empty"
                CONFIG[WP_TITLE]="$2"
                shift 2
                ;;
            --url)
                [[ -z "$2" ]] && error_exit "WordPress URL cannot be empty"
                CONFIG[WP_URL]="$2"
                shift 2
                ;;
            --wp-user)
                [[ -z "$2" ]] && error_exit "WordPress user cannot be empty"
                CONFIG[WP_USER]="$2"
                shift 2
                ;;
            --wp-pass)
                [[ -z "$2" ]] && error_exit "WordPress password cannot be empty"
                CONFIG[WP_PASS]="$2"
                shift 2
                ;;
            --wp-email)
                [[ -z "$2" ]] && error_exit "WordPress email cannot be empty"
                # Basic email validation
                [[ "$2" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] || error_exit "Invalid email format"
                CONFIG[WP_EMAIL]="$2"
                shift 2
                ;;
            -d|--directory)
                [[ -z "$2" ]] && error_exit "Target directory cannot be empty"
                TARGET_DIR="$2"
                shift 2
                ;;
            -w|--wp-cli-path)
                [[ -z "$2" ]] && error_exit "WP-CLI path cannot be empty"
                WP_CLI_PATH="$2"
                shift 2
                ;;
            -g|--git-repo)
                [[ -z "$2" ]] && error_exit "Git repository cannot be empty"
                CONFIG[GIT_REPO]="$2"
                shift 2
                ;;
            --git-user)
                [[ -z "$2" ]] && error_exit "Git user cannot be empty"
                CONFIG[GIT_USER]="$2"
                # Update repo URL with new user
                CONFIG[GIT_REPO]="https://github.com/${CONFIG[GIT_USER]}/$CURRENT_DIR.git"
                shift 2
                ;;
            --ssh)
                CONFIG[GIT_PROTOCOL]="ssh"
                CONFIG[GIT_REPO]="git@github.com:${CONFIG[GIT_USER]}/$CURRENT_DIR.git"
                shift
                ;;
            -x|--ddev)
                INSTALL_MODE="ddev"
                setup_ddev
                shift
                ;;
            --debug)
                set -x  # Enable debug mode
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

# Improved help function
show_help() {
    cat << EOF
WordPress Local Installation Script - Optimized Version

USAGE: $0 [OPTIONS]

DESCRIPTION:
    Automatically installs WordPress with GitHub repository integration.
    Downloads WordPress, creates database, configures installation, and 
    clones specified GitHub repository into wp-content directory.

OPTIONS:
    --new                   Install in new WordPress subdirectory structure
    -n, --db-name NAME      Database name (default: sanitized current directory)
    -u, --db-user USER      Database user (default: wordpress)
    -p, --db-pass PASS      Database password
    -h, --db-host HOST      Database host (default: localhost)
    -t, --title TITLE       WordPress site title (default: test + DIRNAME)
    --url URL               WordPress site URL
    --wp-user USER          WordPress admin username (default: test)
    --wp-pass PASS          WordPress admin password (default: secret)
    --wp-email EMAIL        WordPress admin email
    -d, --directory DIR     Installation target directory (default: current)
    -w, --wp-cli-path PATH  Path to wp-cli binary (default: wp)
    -g, --git-repo URL      Git repository URL
    --git-user USER         GitHub username (default: pfennigparade)
    --ssh                   Use SSH instead of HTTPS for git clone
    -x, --ddev              Use DDEV for local development
    --debug                 Enable debug output
    --dry-run               Show what would be done without executing
    --help                  Show this help message

EXAMPLES:
    # Basic installation with current directory as project name
    $0 -t "My WordPress Site"
    
    # Install with custom database settings
    $0 -t "My Site" -n mysite_db -u dbuser -p dbpass
    
    # Install with DDEV support
    $0 -t "My Site" --ddev
    
    # Install with SSH git clone
    $0 -t "My Site" --ssh --git-user myusername

REQUIREMENTS:
    - WP-CLI installed and accessible
    - MySQL/MariaDB server running
    - Git installed
    - Web server (Apache/Nginx) or DDEV

EOF
}

# DDEV setup function
setup_ddev() {
    log "INFO" "Setting up DDEV configuration..."
    CONFIG[DB_USER]="db"
    CONFIG[DB_PASS]="db" 
    CONFIG[DB_HOST]="db"
    CONFIG[WP_URL]="${CURRENT_DIR}.ddev.site"
    WP_CLI_PATH="ddev wp"
}

# Configuration display
show_configuration() {
    log "INFO" "Installation Configuration:"
    echo "  Mode: $INSTALL_MODE"
    echo "  Directory: $TARGET_DIR"
    echo "  Database: ${CONFIG[DB_NAME]} on ${CONFIG[DB_HOST]}"
    echo "  WordPress URL: ${CONFIG[WP_URL]}"
    echo "  WordPress Title: ${CONFIG[WP_TITLE]}"
    echo "  Git Repository: ${CONFIG[GIT_REPO]}"
    echo "  WP-CLI Path: $WP_CLI_PATH"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "DRY RUN MODE - No actual changes will be made"
        return 0
    fi
    
    echo -n "Proceed with installation? [y/N]: "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] || exit 0
}

# Main installation orchestrator
main() {
    init_config
    colors  # Initialize colors from helper functions
    
    log "INFO" "Starting WordPress installation process..."
    
    parse_arguments "$@"
    validate_requirements
    os_detection 0
    os_process
    
    show_configuration
    
    case "$INSTALL_MODE" in
        "new")
            install_new_wordpress
            ;;
        "ddev")
            install_with_ddev
            ;;
        "standard")
            install_standard_wordpress
            ;;
        *)
            error_exit "Unknown installation mode: $INSTALL_MODE"
            ;;
    esac
    
    log "INFO" "WordPress installation completed successfully!"
    log "INFO" "Site URL: ${CONFIG[WP_URL]}"
    log "INFO" "Admin User: ${CONFIG[WP_USER]}"
    log "INFO" "Admin Pass: ${CONFIG[WP_PASS]}"
}

# Installation modes
install_standard_wordpress() {
    log "INFO" "Installing standard WordPress..."
    
    cd "$TARGET_DIR" || error_exit "Cannot access target directory: $TARGET_DIR"
    
    wp_download
    wp_config 
    wp_database
    wp_install
    wp_configure_htaccess
    wp_block_search_engines
    wp_clone_repository
    wp_activate_plugins
    wp_set_permissions
    
    log "INFO" "Standard WordPress installation complete"
}

install_new_wordpress() {
    log "INFO" "Installing new WordPress (minimal)..."
    
    cd "$TARGET_DIR" || error_exit "Cannot access target directory: $TARGET_DIR"
    
    wp_download
    wp_config
    wp_database
    wp_install
    wp_configure_htaccess
    
    log "INFO" "New WordPress installation complete"
}

install_with_ddev() {
    log "INFO" "Installing WordPress with DDEV..."
    
    # Initialize DDEV config
    ddev config --project-type=wordpress --docroot=. --create-docroot=false --project-name="${CURRENT_DIR}"
    ddev start
    
    install_standard_wordpress
    
    log "INFO" "DDEV WordPress installation complete"
    log "INFO" "Access your site at: https://${CONFIG[WP_URL]}"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
