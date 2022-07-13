#!/bin/bash
#make functions available to be used
#in other scripts for maintaning more
#than one wordpress's sies in a web
#serv er or locally
#+----------------------------------+
#|      Functions                   |
#+----------------------------------+
#| colors()                         |
#+----------------------------------+
#| process_dirs()                   |
#| split $argument in sites names   |
#+----------------------------------+
#| searchwp()                       |
#| search for wp sites in $dir      |
#+----------------------------------+
#| list_wp_plugins()                |
#+----------------------------------+
#| print_sites()                    |
#+----------------------------------+
#| process_sites()                  |
#| add or not a wpsite to an array  |
#+----------------------------------+
#| os_detection()                   |
#| arg: 1 -> print OS
#+----------------------------------+
#| out () < text, typ of line       |
#| print text with line "-" or "="  |
#+----------------------------------+
#| copy_plugins()< from             |
#| cp from/plug/in to array wp-sites|
#+----------------------------------+
#| wp_new_user()< Uname, pw, email  |
#+----------------------------------+
colors(){
    # Reset
    Color_Off="\e[0m"       # Text Reset

    # Regular Colors
    Black="\e[30m"        # Black
    Red="\e[31m"          # Red
    Green="\e[32m"        # Green
    Yellow="\e[33m"       # Yellow
    Blue="\e[34m"         # Blue
    Purple="\e[35m"       # Purple
    Cyan="\e[36m"         # Cyan
    White="\e[37m"        # White

}
searchwp() {
    local site #only valid within this function
    for site in $(ls -d "$dir"*/); do
        if [ -d "$site/wp-content/" ]; then
            site=${site##"$dir"}
            [ "$verbose" = "1" ] && sleep 1 && echo "Found $site"
            sites+=("$site"); (( anzahl++ ))
        fi
    done

}
# https://tldp.org/LDP/abs/html/string-manipulation.html
# # , ## -> remove shortest (longest) FRONT -> ${abc#a} = bc
# % , %% -> remove shortest (longest) BACK -> ${abc%a} = NULL
process_dirs(){ #split directories -> a,b,c sites[0]=a, sites[1]=b, sites[2]=c
    local dirs="$1"
    local site #only valid within this function
    local site
    if [ ! -z "$dirs" ]; then #if something did go wrong
        while [ "$dirs" != "$site" ]; do
            site=${dirs%%,*} #first element -> dirs=a,b,c site=a  
            dirs=${dirs#"$site",} #new string w/o first element -> b,c
            while [ ! -d "$dir$site" ]; do #it has to be a correct name
                echo "$dir$site not found! Tipe in [n]ew name or [c]ontinue..."
                read a
                if [ "$a" = "n" ]; then
                    echo "----------------"
                    echo "enter new name: "
                    read site
                    echo "----------------"
                elif [ "$a" = "c" ]; then
                    site="" #first element is empty
                    break #stop loop
                else
                    continue #startover
                    #break
                fi
            done
            [ ! -z "$site" ] && sites+=("$site") #copy into array
            

        done
    fi
}
list_wp_plugins(){
    local i
    local a

    for i in "${sites[@]}"; do
        echo -e "${Green}----------------"
        cd "$dir$i"  &>/dev/null #change to root wp of site
        echo -e $i
        echo -e "----------------${Color_Off}"
        $wp plugin list --color
        echo -e "${Yellow} $($wp plugin list --format=count) Plugins"
        echo -e "${Purple}To continue press any key and enter...${Color_Off}"
        read a
        cd -  &>/dev/null #change back to orignal dir 
    done
}
print_sites(){
    local i
    echo -e "${Yellow}----------------"
    sleep 1
    echo -e "${#sites[@]} selected websites" 
    echo "----------------"
    for i in "${sites[@]}"; do
        echo -e ${Cyan}$i
    done
    echo -e "${Yellow}----------------"
}
# w/o arguments
[ "$print" = "1" ] && print_sites

# -t -> how many found 
[ "$total" = "1" ] && echo -e "\n=======\nTotal $anzahl WP-Sites"

process_sites(){ #optional: dir
    local dir #avoid misstakes
    [ -z "$1" ] && dir="./" || dir="$1" 
    local site #only valid within this function
    if [ -z "$sites" ]; then #if no folders aka Websites were pass as argument
        for site in $(ls -d $dir*/); do
            if [ -d "$site/wp-content/" ]; then
                seite=${site##"$dir"}
                echo "Found $seite"
                echo "Should it be processed? [y] "
                read answer
                echo -e "\n--------------"
                if [ "$answer" = "y" ]; then
                    #only names
                    site=${site#"$dir"}
                    site=${site%%/}
                    sites+=("$site")
                fi
            fi
        done
    fi
}
os_detection(){
    local OS
    local UNAME
    UNAME="$(uname -a)"
    #linux or wsl , gitbash empty
    #OS="$(cat /etc/os-release | grep '^'NAME'' | cut -d '=' -f2)"

case $( echo "${UNAME}" | tr '[:upper:]' '[:lower:]') in
  linux)
      cOS="$(cat /etc/os-release | grep '_NAME' | cut -d '=' -f2)"
      ;;
  *wsl*|*buntu*)
      cOS="$(cat /etc/os-release | sed -n '1p' | cut -d '"' -f2)"
      #cOS="WSL"
#      hostname="127.0.0.1"
    ;;
  msys*|cygwin*|mingw*)
    # or possible 'bash on windows'
    cOS="Git_Bash"
    ;;
  *)
    ;;
esac
    #kernel version
    UNAME="$(uname -r)"

    [[ "$1" -eq 1 ]] && out "$cOS" 1
}
out () { #what? - or #
    local line #avoid extra lines between calls
    local i #avoid stupid errors
    for ((i=0; i<30; i++)); do
        if [[ "$2" -eq 1 ]]; then
            line+='#'
        else
            line+='-'
        fi

    done
    name="##        ${1}        "
    length=${#name}
    #echo $length
    if [[ "$2" -eq 1 ]]; then
        line="${Yellow}${line}"
    elif [[ "$2" -eq 3 ]]; then
        line="${Red}${line}"
   else
        line="${Cyan}${line}"
   fi
    #echo -e "$name${line:$length}" 
    #echo -e ${line}\n${1}\n$line${Color_Off}
echo -e "${line}"
echo -e "${1}"
echo -e "${line}${Color_Off}"

}
assign_env(){
    declare -n var="$1" #string $1 will be the name of var
    value=$2
    #echo ${!var} #print the name of var
    out $var 1
    out "${!var}" 2 #print the name of var
    var="$value"
    out $var 1
}
copy_plugins(){ #from
    local target
    local plugin_name
    local i #avoid stupid errors
    from="$1" #full path w/o / at the end !!!
    #plugin_name="${from%%/*}"
    plugin_name=$(basename "$from")


    for i in "${sites[@]}"; do
        out "${i}" 1
        target="${i}/wp-content/plugins/"
        if [ -d "${target}${plugin_name}" ]; then
            out "${plugin_name} already exists" 3
        else
            out "copying ${plugin_name}from ${from}" 2
            cp "$from" "$target" -r
            sleep 1
            echo "Done"
            out "Activating $plugin_name" 2
            cd "${dir}${i}"
            $wp plugin activate $plugin_name
            cd -  &>/dev/null #change back to orignal dir 
        fi
    done
}
remove_plugins() {
    local plugin_name
    local i

    plugin_name="$1"
    for i in "${sites[@]}"; do
        out "$i" 1
        cd ${i}/wp-content/plugins
        if [ -d "$plugin_name" ]; then
            out "Removing $plugin_name" 2
             "$wp" plugin delete "$plugin_name"
            sleep 1
            echo "Done"
#            "$wp" plugin list
        fi
        if [ "$2" -eq 1 ]; then #pause, when 2 args
            echo -e "${Purple}To continue press any key and enter...${Color_Off}"
            read a
        fi
        cd -  &>/dev/null #change back to orignal dir 
    done
}
wp_new_user(){ #user,passw,email
    out "creating user ${1}"
    sleep 1
    for i in "${sites[@]}"; do
        out "$i" 1
        cd "$i"
        "$wp" user create "$1" "$3" --user_pass="$2" --role=administrator
        cd -  &>/dev/null #change back to orignal dir 
    done
}

wp_update() { #what full path e/o closing /
    plugin=$(basename "$1")
    path="${1}"
    for i in "${sites[@]}"; do
        out "$i" 1
        out "check $plugin if there is one, update it"
            cd $i #for wpcli -> into site
        installed=$(wp plugin is-installed $plugin)
        if [ -z "$installed" ]; then
            out "no $plugin found" 3
            out "installing $path" 2
            cp $path . -rv
            $wp plugin activate $plugin
        else
            out "found $plugin! Updating..." 2
            $wp plugin update $plugin
        fi
            cd -  &>/dev/null #change back to orignal dir 
    done
}
wp_key_migrate(){
    for i in "${sites[@]}"; do
        out "$i" 1
        out "activating wp-migrate-db-pro" 2
        sleep 1
        echo "define( 'WPMDB_LICENCE', 'a8ff1ac2-3291-4591-b774-9d506de828fd');" >> "$i"/wp-config.php
    done
    
}
