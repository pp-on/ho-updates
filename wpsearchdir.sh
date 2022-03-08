#!/bin/bash

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

verbose=0
total=0
dir=./
anzahl=0
print=0

while [ $# -gt 0 ];do
    case $1 in
        -p)
            print=1
            ;;
        -s)
            searchwp
            ;;
        -v)
            verbose=1
            ;;
        -t)
            total=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpsearchdir.sh [-s][-p][-v][-t][-d TARGET DIR]"
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
#for dirs
#dirs=($(ls -lh -d */ | awk '{print $9}' | sed 's/\///g'))
dirs=$(find "$dir"*/ -maxdepth 1 -mindepth 1 -type d)
#check for wpsites and add them to array
#for site in "${dirs[@]}"; do
searchwp() {
    for site in $(ls -d "$dir"*/); do
        if [ -d "$site/wp-content/" ]; then
            site=${site##"$dir"}
            [ "$verbose" = "1" ] && sleep 1 && echo "Found $site"
            sites+=("$site"); (( anzahl++ ))
        fi
    done

}
process_dirs(){ #split directories -> a,b,c sites[0]=a, sites[1]=b, sites[2]=c
    local dirs="$1"
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
print_sites(){
        echo -e "${Yellow}----------------"
        sleep 1
        echo -e "${#sites[@]} selected websites" 
                    echo "----------------"
        for i in ${sites[@]}; do
            echo -e ${Cyan}$i
        done
        echo -e "${Yellow}----------------"
}
# w/o arguments
[ "$print" = "1" ] && print_sites

# -t -> how many found 
[ "$total" = "1" ] && echo -e "\n=======\nTotal $anzahl WP-Sites"

process_sites(){
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
