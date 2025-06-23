#!/bin/bash

# WordPress Installation Functions - Optimized Version
# Requires: wphelpfunctions.sh to be sourced first

# Default WordPress admin credentials (can be overridden)
readonly DEFAULT_WP_USER="test"
readonly DEFAULT_WP_PASS="secret"
readonly DEFAULT_WP_EMAIL="oswaldo.nickel@pfennigparade.de"

# Function to check if database exists and handle accordingly
check_database() {
    log "INFO" "Checking if database '${CONFIG[DB_NAME]}' exists..."
    
    local db_exists
    db_exists=$(mysql -h "${CONFIG[DB_HOST]}" -u web -p1234 -e "SHOW DATABASES LIKE '${CONFIG[DB_NAME]}';" 2>/dev/null | grep -c "${CONFIG[DB_NAME]}" || true)
    
    if [[ "$db_exists" -gt 0 ]]; then
        log "WARN" "Database '${CONFIG[DB_NAME]}' already exists"
        echo -n "All data will be erased. Continue? [y/N]: "
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] || error_exit "Installation aborted by user"
    fi
    
    create_database
}

# Create or recreate database
create_database() {
    log "INFO" "Creating database '${CONFIG[DB_NAME]}'..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would create database: ${CONFIG[DB_NAME]}"
        return 0
    fi
    
    mysql -u "${CONFIG[DB_USER]}" -p"${CONFIG[DB_PASS]}" -h "${CONFIG[DB_HOST]}" << EOF || error_exit "Failed to create database"
DROP DATABASE IF EXISTS \`${CONFIG[DB_NAME]}\`;
CREATE DATABASE \`${CONFIG[DB_NAME]}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF
    
    log "INFO" "Database '${CONFIG[DB_NAME]}' created successfully"
}

# Download WordPress core
wp_download() {
    log "INFO" "Downloading WordPress core..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would download WordPress core (German locale)"
        return 0
    fi
    
    "$WP_CLI_PATH" core download --locale=de_DE || error_exit "Failed to download WordPress core"
    log "INFO" "WordPress core downloaded successfully"
}

# Create WordPress configuration
wp_config() {
    log "INFO" "Creating WordPress configuration..."
    log "DEBUG" "Using database host: ${CONFIG[DB_HOST]}"
    
    # Remove existing config if present
    [[ -f "wp-config.php" ]] && rm -f wp-config.php
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would create wp-config.php with database: ${CONFIG[DB_NAME]}"
        return 0
    fi
    
    "$WP_CLI_PATH" config create \
        --dbname="${CONFIG[DB_NAME]}" \
        --dbuser="${CONFIG[DB_USER]}" \
        --dbpass="${CONFIG[DB_PASS]}" \
        --dbhost="${CONFIG[DB_HOST]}" \
        --extra-php << 'EOF' || error_exit "Failed to create WordPress configuration"
// Custom WordPress configuration
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);
define('WP_CACHE', false);
define('CONCATENATE_SCRIPTS', false);

// Security improvements
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', false);
define('FORCE_SSL_ADMIN', false);

// Performance improvements
define('WP_POST_REVISIONS', 5);
define('AUTOSAVE_INTERVAL', 300);
define('WP_CRON_LOCK_TIMEOUT', 60);
EOF
    
    log "INFO" "WordPress configuration created successfully"
}

# Handle database operations using WP-CLI
wp_database() {
    log "INFO" "Setting up WordPress database..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would reset and setup database"
        return 0
    fi
    
    # Reset database (this will recreate tables)
    "$WP_CLI_PATH" db reset --yes || error_exit "Failed to reset database"
    log "INFO" "Database setup completed"
}

# Install WordPress
wp_install() {
    # local wp_user="${CONFIG[WP_USER]:-$DEFAULT_WP_USER}"
    # local wp_pass="${CONFIG[WP_PASS]:-$DEFAULT_WP_PASS}"
    # local wp_email="${CONFIG[WP_EMAIL]:-$DEFAULT_WP_EMAIL}"
    
    log "INFO" "Installing WordPress with title: ${CONFIG[WP_TITLE]}"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install WordPress with URL: ${CONFIG[WP_URL]}"
        return 0
    fi
    
    "$WP_CLI_PATH" core install \
        --url="${CONFIG[WP_URL]}" \
        --title="${CONFIG[WP_TITLE]}" \
        --admin_user="${CONFIG[WP_USER]}" \
        --admin_password="${CONFIG[WP_PASS]}" \
        --admin_email="${CONFIG[WP_EMAIL]}" \
        --skip-email || error_exit "Failed to install WordPress"
    
    log "INFO" "WordPress installed successfully"
    log "INFO" "Admin credentials - User: $wp_user, Password: $wp_pass"
}

# Clone Git repository to wp-content
wp_clone_repository() {
    local repo="${CONFIG[GIT_REPO]}"
    
    if [[ -z "$repo" ]]; then
        log "WARN" "No repository specified, skipping git clone"
        return 0
    fi
    
    log "INFO" "Cloning repository: $repo"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would clone $repo to wp-content/"
        return 0
    fi
    
    # Backup existing wp-content if it contains custom files
    if [[ -d "./wp-content" ]] && [[ -n "$(find ./wp-content -name '*.php' -not -path '*/plugins/hello.php' -not -path '*/plugins/akismet/*' 2>/dev/null)" ]]; then
        log "INFO" "Backing up existing wp-content..."
        mv ./wp-content "./wp-content.backup.$(date +%Y%m%d_%H%M%S)"
    else
        rm -rf ./wp-content
    fi
    
    # Clone repository
    if ! git clone "$repo" wp-content; then
        error_exit "Failed to clone repository: $repo"
    fi
    
    log "INFO" "Repository cloned successfully"
}

# Activate all plugins
wp_activate_plugins() {
    log "INFO" "Activating all plugins..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would activate all plugins"
        return 0
    fi
    
    # Check if there are any plugins to activate
    local plugin_count
    plugin_count=$("$WP_CLI_PATH" plugin list --status=inactive --format=count 2>/dev/null || echo "0")
    
    if [[ "$plugin_count" -gt 0 ]]; then
        "$WP_CLI_PATH" plugin activate --all || log "WARN" "Some plugins failed to activate"
        log "INFO" "Plugins activated: $plugin_count"
    else
        log "INFO" "No plugins found to activate"
    fi
}

# Configure .htaccess for pretty permalinks
wp_configure_htaccess() {
    log "INFO" "Configuring .htaccess for SEO-friendly URLs..."
    
    local base_path
    base_path="$(get_relative_path)"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would create .htaccess with base path: $base_path"
        return 0
    fi
    
    cat > .htaccess << EOF || log "WARN" "Failed to create .htaccess"
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On

# Force HTTPS (uncomment if needed)
# RewriteCond %{HTTPS} !=on
# RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# WordPress rewrite rules
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase $base_path
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . ${base_path}index.php [L]
</IfModule>

# Security headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</IfModule>

# Disable directory browsing
Options -Indexes

# Protect wp-config.php
<Files wp-config.php>
    order allow,deny
    deny from all
</Files>
# END WordPress
EOF
    
    chmod 644 .htaccess 2>/dev/null || log "WARN" "Could not set .htaccess permissions"
    log "INFO" ".htaccess configured successfully"
}

# Block search engines for development
wp_block_search_engines() {
    log "INFO" "Disabling search engine indexing for development..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would disable search engine indexing"
        return 0
    fi
    
    "$WP_CLI_PATH" option update blog_public 0 || log "WARN" "Failed to disable search engine indexing"
    log "INFO" "Search engine indexing disabled"
}

# Set up proper file permissions
wp_set_permissions() {
    log "INFO" "Setting up file permissions..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would set file permissions"
        return 0
    fi
    
    # Create uploads directory if it doesn't exist
    mkdir -p wp-content/uploads
    
    # Set permissions for WordPress
    find . -type d -exec chmod 755 {} \; 2>/dev/null || log "WARN" "Could not set directory permissions"
    find . -type f -exec chmod 644 {} \; 2>/dev/null || log "WARN" "Could not set file permissions"
    
    # Make wp-config.php more secure
    chmod 600 wp-config.php 2>/dev/null || log "WARN" "Could not secure wp-config.php permissions"
    
    # Ensure uploads directory is writable
    chmod 755 wp-content/uploads 2>/dev/null || log "WARN" "Could not set uploads directory permissions"
    
    log "INFO" "File permissions configured"
}

# License plugin activation (ACF Pro, WP Migrate DB Pro)
wp_license_plugins() {
    local plugin="$1"
    local license_code=""
    
    case "$plugin" in
        "ACF_PRO")
            license_code='b3JkZXJfaWQ9NzQ3MzF8dHlwZT1kZXZlbG9wZXJ8ZGF0ZT0yMDE2LTAyLTEwIDE1OjE1OjI4'
            ;;
        "WPMDB")
            license_code='a8ff1ac2-3291-4591-b774-9d506de828fd'
            ;;
        *)
            log "WARN" "Unknown plugin license: $plugin"
            return 1
            ;;
    esac
    
    log "INFO" "Activating license for $plugin..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would activate license for $plugin"
        return 0
    fi
    
    # Check if license is already defined
    if grep -q "${plugin}_LICENSE" wp-config.php 2>/dev/null; then
        log "INFO" "${plugin} license already configured"
        return 0
    fi
    
    # Add license to wp-config.php
    local define_line
    if [[ "$plugin" == "ACF_PRO" ]]; then
        define_line="define('ACF_PRO_LICENSE', '$license_code');"
    else
        define_line="define('WPMDB_LICENCE', '$license_code');"
    fi
    
    # Insert before the "/* That's all" comment in wp-config.php
    sed -i "/That's all, stop editing/i $define_line" wp-config.php || log "WARN" "Could not add license to wp-config.php"
    
    log "INFO" "$plugin license activated"
}

# Enable WordPress debug mode
wp_enable_debug() {
    log "INFO" "Enabling WordPress debug mode..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would enable debug mode"
        return 0
    fi
    
    "$WP_CLI_PATH" config set WP_DEBUG true --raw || log "WARN" "Could not set WP_DEBUG"
    "$WP_CLI_PATH" config set WP_DEBUG_LOG true --raw || log "WARN" "Could not set WP_DEBUG_LOG"
    "$WP_CLI_PATH" config set WP_DEBUG_DISPLAY false --raw || log "WARN" "Could not set WP_DEBUG_DISPLAY"
    "$WP_CLI_PATH" config set SCRIPT_DEBUG true --raw || log "WARN" "Could not set SCRIPT_DEBUG"
    
    log "INFO" "Debug mode enabled"
}

# Disable WordPress debug mode
wp_disable_debug() {
    log "INFO" "Disabling WordPress debug mode..."
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log "INFO" "[DRY RUN] Would disable debug mode"
        return 0
    fi
    
    "$WP_CLI_PATH" config set WP_DEBUG false --raw || log "WARN" "Could not set WP_DEBUG"
    "$WP_CLI_PATH" config set WP_DEBUG_LOG false --raw || log "WARN" "Could not set WP_DEBUG_LOG"
    "$WP_CLI_PATH" config set WP_DEBUG_DISPLAY false --raw || log "WARN" "Could not set WP_DEBUG_DISPLAY"
    "$WP_CLI_PATH" config set SCRIPT_DEBUG false --raw || log "WARN" "Could not set SCRIPT_DEBUG"
    
    log "INFO" "Debug mode disabled"
}

# Helper function to get relative path for .htaccess
get_relative_path() {
    local current_path="$PWD"
    local web_root="/var/www/html"  # Adjust this to your web root
    
    # Try to determine web root from common patterns
    if [[ "$current_path" =~ /htdocs/ ]]; then
        web_root="$(echo "$current_path" | sed 's|/htdocs/.*|/htdocs|')"
    elif [[ "$current_path" =~ /public_html/ ]]; then
        web_root="$(echo "$current_path" | sed 's|/public_html/.*|/public_html|')"
    elif [[ "$current_path" =~ /www/ ]]; then
        web_root="$(echo "$current_path" | sed 's|/www/.*|/www|')"
    fi
    
    # Calculate relative path
    local relative_path="${current_path#$web_root}"
    [[ "$relative_path" != "/" ]] && echo "$relative_path/" || echo "/"
}

# Comprehensive WordPress installation for standard mode
install_complete_wordpress() {

    wp_config 
    check_database
    wp_database
    wp_install
    wp_configure_htaccess
    wp_block_search_engines
    wp_clone_repository
    wp_activate_plugins
    wp_license_plugins "ACF_PRO"
    wp_license_plugins "WPMDB"
    wp_set_permissions
}

# Minimal WordPress installation for new mode
install_minimal_wordpress() {
    wp_download
    wp_config
    check_database
    wp_database
    wp_install
    wp_configure_htaccess
    wp_set_permissions
}

# WordPress  Installation for ddev
install_ddev_wordpress{

}
