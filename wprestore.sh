#!/bin/env bash

old="http://"  #url to be searched
new="http://"  #url to be inserted
DB=( "DB_NAME" "DB_USER" "DB_PASSWORD" "DB_HOST" )
idDB=( "dbname" "web" "1234" "localhost" )
wpcli=1         #when falsee, use mysql to search and replace
verbose=0       #show files
file="*.sql"
bdiir="backups/" #where the BACKUPS IS
dir="./"        #where am i
wp="wp"         #where is wp-cli 
while [ $# -gt 0 ];do
    case $1 in
        -s)
            shift
            old=$1
            ;;
        -r)
            shift
            new=$1
            ;;
        -n)
            shift
            idDB[0]=$1
            ;;
        -u)
            shift
            idDB[1]=$1
            ;;
        -p)
            shift
            idDB[2]=$1
            ;;
        --host | -l)
            shift
            idDB[3]=$1
            ;;
        -v)
            verbose=1
            ;;
        -b)
            shift
            bdir=$1
            ;;
        -c)
            wpcli=0
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wprestore.sh [-s SSTRING][-r RSTRING][-b BackupDir][-u DBUSER[-p DBPW][--host | -l DBHOST][-n
            DBNAME][-d targetDIR][-w path/to/wp][-c][-v][-h]"
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
################################################
# Preparatins                                  #
################################################

function extract() { #dir where the backup is, trget
    extractioned=0  #is it done?
    for tar in $(ls $1/*.tar.gz); do
       echo "Found $tar"
        echo "Should it be processed? [y/n] "
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            tar xvzf $tar
            extractioned=1
            continue
        fi

    done
     if [ -z $extractioned ]; then
         echo "Nothing extracted"
    fi
}
# import db.sql
function sql() {
    
    for sql in $(ls *.sql); do
        echo "Found $sql"
        echo "Should it be processed? [y/n] "
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            #first delete <cre>ate and use db
            sed -i '/CREATE\ DATABASE/d' "$sql"
            sed -i '/USE/d' "$sql"
            #create db
            mysql -u ${idDB[1]} -p${idDB[2]} -h ${idDB[3]} -e "CREATE DATABASE IF NOT EXISTS ${idDB[0]}; USE ${idDB[0]};"
            if [ -z "$wpcli" ]; then
                mysql -u ${idDB[1]} -p${idDB[2]} -h ${idDB[3]} ${idDB[0]} < "$sql"
            else
                $wp db import "$sql"
            fi
            continue
        fi
    done
    }

#replacements for using db
function config () {
    # replace all DB (array) with  dbname, user, pw, host  in wp_config
    for i in ${!DB[@]}; do
        echo ${DB[$i]}
        # regex explanation: all characters  * between ' til ^''
        sed -i "s/'${DB[$i]}',\ '[^']*'/'${DB[$i]}',\ '${idDB[$i]}'/g" wp-config.php
    done
}

#search and replace in db
function sar () {
    wp search-replace --network --url=${old} ${old} ${new} --precise --dry-run
}
##################
# main           #
##################
cd $dir
sleep 1
echo "-----------------"
echo "extracting..."
extract  $bdir
echo "-----------------"
sleep 1
echo "modifying wp-config..."
config
sleep 1  
echo "-----------------"
echo "db import..."
sql
sleep 1
echo "-----------------"
echo "search and replace..."
sar
cd -

