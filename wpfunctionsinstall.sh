#! /bin/bash

wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"
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
    out "activating plugins" 2
    $wp plugin activate --all
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
            
    out "$1" 1
    sleep 1
    out "PHP: $php wp: $wp" 2
    sleep 1
    out "DB: $dbname" 2
    sleep 1
    out "WP_user:  $wpuser" 2
    out "WP_pass: $wppw" 2
    out "WP_email: $wpemail" 2
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
