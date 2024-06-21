# ho-updates

bash scripts for doing fasster updates and kkeping track wp sites
- wpsearchdir.sh
    search in a given directory for wp sites
- wpupdate.sh
    automatis does an update (core and plugins) for every wp-site in a given directory 
- wpfunctionsinstall.sh
    functions for installing wrdpress.

# <u>Documentation</u>

## wpfunctionsinstall.sh

### Variables

- **wpuser**: `"test"`
  - WordPress admin username.
- **wppw**: `"secret"`
  - WordPress admin password.
- **wpemail**: `"xxx.xxx@pfennigparade.de"`
  - WordPress admin email.

### Functions

#### 1. check_db
Checks if a database with a specified name exists. If not, it calls `create_db` to create the database. If the database exists, it prompts the user to confirm whether to proceed and recreate the database.

#### 2. create_db
Drops the existing database (if it exists) and creates a new database with the specified name.

#### 3. wp_dw
Downloads the WordPress core files with a specified locale.

#### 4. wp_config
Creates the WordPress configuration file (`wp-config.php`). If the file already exists, it is removed before creating a new one.

#### 5. wp_db
Drops the existing WordPress database using WP-CLI and creates a new one.

#### 6. wp_install
Installs WordPress using the WP-CLI with specified parameters like URL, title, admin username, admin password, and admin email.

#### 7. wp_git
Clones a specified repository into the WordPress content directory (`wp-content`) and activates all plugins using WP-CLI.

#### 8. ssh_repo
Constructs a repository URL based on the provided SSH mode. The resulting URL is used to set the `repo` variable.

#### 9. out_msg
Outputs various configuration details to the terminal, including PHP version, WP-CLI version, database name, WordPress admin credentials, hostname, local URL, and repository URL.

#### 10. os_process
Determines the operating system's kernel version and sets up SSH repository details. It also calls `out_msg` to display configuration details.

#### 11. main
The main function that orchestrates the script execution by calling other functions in the following order: `wp_dw`, `wp_config`, `wp_db`, `wp_install`, `htaccess`, `wp_git`, and `wp_license_plugins`.




