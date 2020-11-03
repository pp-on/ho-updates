#!/bin/env bash

verbose=0       #show files
user="web"      #db user
pw="1234"       #db pw
lh="localhost"  #db ho+st
file="*.sql"
dir="./"        #where am i
wp="wp"         #where is wp-cli 
while [ $# -gt 0 ];do
    case $1 in
        -u)
            shift
            user=$1
            ;;
        -p)
            shift
            pw=$1
            ;;
        --host | -l)
            shift
            lh=$1
            ;;
        -v)
            verbose=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wprestore.sh [-u DBUSER[-p DBPW][--host | -l DBHOST][-n DBNAME][-d targetDIR][-w path/to/wp]"
            exit
            ;;
        -w)
            shift
            wp=$1
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
# import db.sql
for sql in $(ls *.sql); do
    echo "Found $sql"
    echo "Should it be processed? [y/n] "
    read answer
    echo -e "\n--------------"
    if [ "$answer" = "y" ]; then
        file=$sql
        continue
    fi
done
#wp-configm update

#only WP-Sites are to be processed
#for site in $(ls -d $dir*/); do
#    if [ -d "$site/wp-content/" ]; then
#        seite=${site##"$dir"}
#        echo "Found $seite"
#        echo "Should it be processed? [y/n] "
#    cd $site  &>/dev/null
#        read answer
#        echo -e "\n--------------"
#        if [ "$answer" = "y" ]; then
#            echo "if name $site is wrong type in a new one"
#            read name
#            # when the name is corrected, put it inarray
#            # if not, put the original one with path in the same array
#            if [ ! -z "$name" ]; then
#                names+=("$name")
#            else
#                name=${site##"$dir"}
#                name=${name%/}
#                names+=("$name")
#            fi
#            sites+=("$site") #this array must contain the path for every site 
#                             # -> "cd $site"
#        fi
#    fi
#done
#
