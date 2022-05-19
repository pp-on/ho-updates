#! /bin/bash

create_db (){
    echo ""
    out "Creating Database $dbname" 1
    sleep 1
    mysql -u $dbuser -p$dbpw -h $hostname -e "DROP DATABASE IF EXISTS $dbname;
    CREATE DATABASE $dbname"
}
wp_dw (){
    out "downloading core" 1
    sleep 1
    $wp core download --locale=de_DE
}
wp_config (){ #
    out "creating config" 1
    out "using hostname $hostname" 2
    f="wp-config.php"
    if [ ! -f "$f" ]; then
        echo -e "$Yellow there is no $f $Color_Off"
    else
        rm $f
    fi
    sleep 1
    $wp config create --dbname="$dbname" --dbuser="$dbuser" --dbpass="$dbpw" --dbhost="$hostname" 

#    if [ "$wsl" -eq 1 ]; then
 #       echo "define('WP_USE_EXT_MYSQL', false);" >> wp-config.php
  #  fi

}
#alternative for creating DB with mysql using user and name of wp config
wp_db (){
    out "Creating Database $dbname" 1
    sleep 1
    #if there's  an error, exit -> || means exit status 1
#    if [ $gb -eq 1 ]; then
#        winpty mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS `$dbname`;" || echo -e "$Red Error $Color_Off dropping Database"
#    else
#        mysql -u "$dbuser" -p"$dbpw" -h "$hostname" -e "DROP DATABASE IF EXISTS `$dbname`;" || echo -e "$Red Error $Color_Off dropping Database"
#    fi
    out "Dropping $dbname" 2
    sleep 1
    $wp db drop --yes
    out "Creating new $dbname" 2
    sleep 1
    $wp db create
    
}
wp_install (){
    out "installing wp ${title}" 1
    sleep 1
    $wp core install --url="$url" --title="$title" --admin_user="$wpuser" --admin_password="$wppw" --admin_email="$wpemail"   || echo -e "${Red}Something went wrong${Color_Off}"
}
wp_git (){ 
  
    if [ -z "$repo" ]; then
        echo "No repository specified"
        echo "please enter one"
        read repo
    fi

    out "cloning $repo" 1
    sleep 1
    rm ./wp-content/ -rf
   # if [ $wsl -eq 1 ]; then
    #    gh repo clone $repo wp-content
    #else
    #    git clone $repo wp-content
    #fi
    git clone $repo wp-content
}

wp_ap {
    out "activating plugins" 2
    $wp plugin activate --all
}
wp_key_acf_pro (){
    out "activating acf pro" 2 
    sleep 1
    $wp eval 'acf_pro_update_license("b3JkZXJfaWQ9NzQ3MzF8dHlwZT1kZXZlbG9wZXJ8ZGF0ZT0yMDE2LTAyLTEwIDE1OjE1OjI4");'
    $wp plugin list
}
#activate debug
wp_debug(){
    out "adding WP DEBUG to wp-config" 2
    cat <<EOF >> wp-config.php
    // Enable WP_DEBUG mode
define( 'WP_DEBUG', true );

// Enable Debug logging to the /wp-content/debug.log file
define( 'WP_DEBUG_LOG', true );

// Disable display of errors and warnings
define( 'WP_DEBUG_DISPLAY', false );
@ini_set( 'display_errors', 0 );

// Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
define( 'SCRIPT_DEBUG', true );
EOF

     
}
# basic htaccess for SEO
htaccess() {
    out "creating .htaccess" 2
cat  << EOF > .htaccess
# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF
sleep 1
echo "Done"
}
ssh_repo(){ #ssh
    local ssh
    ssh="$1"
    if [ $ssh -eq 1 ]; then
        git="git@github.com-a:" 
    elif [ $ssh -eq 2 ]; then
        git="git@github.com:" 
    else
        git="https://github.com/"
    fi
    repo=${git}${gituser}/${dir}.git    #default, it can be cchanged with -g
}
out_msg (){ #what?, where? ssh
    url="$2"
            
    out $1 1
    sleep 1
    out "PHP: $php wp: $wp" 2
    sleep 1
    out "DB: $dbname" 2
    sleep 1
    out "hostname: $hostname" 2
    sleep 1
    out "Local: $url" 2
    sleep 1
    out " Repo: $repo" 2
    sleep 2
}


os_process(){ #kernel version
 #   [[ "$cOS" == "WSL" ]]  && url="localhost/repos/${dir}" && hostname="127.0.0.1" 
 #   [[ "$cOS" == "Git_Bash" ]]  && url="localhost/repos/${dir}" &&  hostname="localhost"
    uname="$(uname -r)"
    ssh_repo "$ssh"
    out_msg "${cOS}-${uname}" "${url}" 
}
main(){ 
    wp_dw
    wp_config 
    wp_db
    wp_install
     htaccess
    wp_git 
    wp_key_acf_pro
}
