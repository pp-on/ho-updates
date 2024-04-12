#!/bin/bash
######################################################
# globa vars
######################################################
# today
dt=$(date +'%Y%m%d')
# local
loc_d="/home/www/sicherungen"
#remote use@server
rem_h=""
# backup
rem_bu=""
##remote dir
rem_d=""
#where?
server=""
#what?
# wp_site=""
# if connection can be done throughssh -> 0 no, 1 yes
server_ssh=0

######################################################
# function
# ####################################################
#remove files older than given. only local!
 rmf(){ 
     # only -r
     [[ "$#" -eq 0 ]] && days=10 || days="$1"
     echo "removing files older than $days days in $local_d"
     find "$local_d" -type f -mtime "+${days}" 
     # find "$loc_d" -type f -mtime "+${1}" -delete
 }
#configurations for a remote server
function r_server(){
    case $server in
        pp)
            # must explict -> for cronjopbs
            wp='/home/www/.script/wp-cli.phar'
            ;;
        netcup)
            #connection through ssh keys
            server_ssh=1
            # using host in .ssh/config
            rem_h="nc"
            # must explict -> for cronjopbs
            wp='~/git/wp-cli.phar'
            #where is the root dir
            ser_d="/httpdocs"
            ;;
        he)
            #connection through ssh keys
            server_ssh=1
            # must explict -> for cronjopbs
            wp="~/www/.bin/wp"
            # using host in .ssh/config
            rem_h="bbsb"
            #where is the root dir
             ser_d="/is/htdocs/wp1065095_P40ZWGUICY/www"
            ;;
        mkq)
            #connection through ssh keys
            server_ssh=1
            # using host in .ssh/config
            rem_h="mkq"
            #where is the root dir
            ser_d="/mnt/web511/c0/05/53594905/htdocs"
            ;;
    esac
 }
function r_client(){
    #local acording to wp_site
    #:? if not set, exit
    local_d="${loc_d}/${wp_site:?}"
    case "$wp_site" in
        bbsb)
            rem_d="${ser_d}/bbsb_wp"
            ;;
        beans-books)
            rem_d="${ser_d}/beansandbooks"
            ;;
        bsst)
            rem_d="${ser_d}/blinden-und-sehbehindertenstiftung-bayern.org"
            ;;
        bzt)
            #akeeba
            profile=" --profile=2"
            #bu server
            local_d="${loc_d}/bit-zentrum"
            #only copy tday's date
            rem_d="${ser_d}/bit-zentrum"
          # rm_a="rm ${rem_d}/*"
                ;;
            bzm)
                # rm_a="rm ${rem_d}/*.j*"
                rem_d="${ser_d}/bit-zentrum/wp-content/plugins/akeebabackupwp/app/backups"
                ;;
            bbsb)
                rem_d="${ser_d}/bbsb_wp"
                ;;
            emw)
                rem_d="${ser_d}/elternmitwirkung"
                ;;
            neuronetz)
                rem_d="${ser_d}/neuronetz"
                ;;
            mkq-t)
                #bu server
                local_d="${loc_d}/mkq"
                rem_d="${ser_d}/wordpress/wp-content/backups/daily*.j*"
                ;;
            mkq-m)
                #bu server
                local_d="${loc_d}/mkq"
                rm_a="rm ${rem_d}/monat*.j*"
                ;;
    esac
 }
 bup_ssh(){
     echo "taking backup of $wp_site with wp_cli in server $server"
    ssh  "${rem_h}" "cd $rem_d && $wp akeeba backup take $profile"

 }
 function bup(){

            echo "taking backup $wp_site with curl"
            
            case $wp_site in
                sbz)
                     curl -L --max-redirs 1000 -v "https://www.sbz.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=py1zI0b6FhAmwOASA86I-dEWW-CnWwFf" 1>/dev/null 2>/dev/null
                     ;;
                # eca)
                #     curl -L --max-redirs 1000 -v "https://european-conductive-association.org/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=oRxLxnVNtiUkBqKmLTMkOkAeCocRSGKZ" 1>/dev/null 2>/dev/null
                #     ;;
                # beans-books)
                    # ssh  "${rem_h}" "cd $rem_d && $wp akeeba backup take $profile"
                    # ;;
                aura-hotel)
                     curl -L --max-redirs 1000 -v "https://aura-hotel.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=TUD_8NwKMrzH07X28ugp0s_xy77TIl12" > /dev/null 2>&1
                     ;;
                # bzt)
                #     ssh  "${rem_h}" "cd $rem_d && $wp akeeba backup take $profile"
                #     ;;
                # bzm)
                #     ssh bbsb "cd www/bit-zentrum && $wp akeeba backup take"
                #     ;;
                lag)
                    curl -L --max-redirs 1000 -v "https://www.wfbm-bayern.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=_jCA1rel_H-kifC4oDVVNTIt48ihqH" 1>/dev/null 2>/dev/null
                    ;;
                agsv)
                    curl -L --max-redirs 1000 -v "https://www.agsv.bayern.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=%06%DDg%09vg%D9%DFp%90%85%8BL%09dD%E5%8E%962%F6%A6%D1x%05kR%E8%B5%B9%E2%A5%FF%13%C3i%A8%FF%9F%05%C8%7C%82%05%AAyy%BB" 1>/dev/null 2>/dev/null
                    ;;
                sbs)
                    curl -L --max-redirs 1000 -v "https://www.sbsfahrdienst.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=al_b6PBNKUL55WhVhu86a_nspLLARU-0" 1>/dev/null 2>/dev/null
                    ;;
                # mkq-m)
                #     ssh mkq "cd wordpress && wp akeeba backup take"
                #      # curl -L --max-redirs 1000 -v "https://munichkyivqueer.org/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=L1df_JFMlSQ50OxUgXr2hY0tMHfYXJBn" 1>/dev/null
                #      # curl -L --max-redirs 1000 -v "https://munichkyivqueer.org/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=%BD%1D%ED%C9%E8i%C9%8F%F89%88vq%C6%23%FA%89%E8%9B%C2K%BD%FF%40%2B%B8TU%A3%1B%2A%93T%FB%D4q%DF%23%A9%8B%D4C%C6%F3%9FG%CE3" 1>/dev/null 2>/dev/null
                #      ;;
                # mkq-t)
                #     ssh mkq "cd wordpress && wp akeeba backup take --profile=2"
                #     ;;
                pp-fenster)
                    curl -L --max-redirs 1000 -v "https://fenster.pfennigparade.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=JcsYNuJJbhRNqpBFcetLdWGfyngIMT" 1>/dev/null 2>/dev/null
                    # cd /home/www/wp_pfennigfenster && $wp akeeba backup take
                    ;;
                pp-news)
                    # täglich
                    curl -L --max-redirs 1000 -v "https://pfennignews.pfennigparade.de/wp-admin/admin-ajax.php?action=akeebabackup_legacy&key=DDUUzo5xkLm9tJRR7UtD93aYJOoDdw1H&profile=2" 1>/dev/null 2>/dev/null
                    ;;
            esac

            # "$rem_bu"
 }
 function usage(){
     echo "./remote-ak-b.sh [-s SERVER][-w website][-b][-c][-r][-d][-h]"
     echo "-: server -> he"
     echo "w: website -> bzt (bit-zentrum taeglich)"
     echo "b: take backup. -s and -w has to be set"
     echo "c: scp from remote. -s and -w has to be set"
     echo "r: remove according to website 10 (default) or given number of days. locally. -w has to be set"
     echo "d: remove remotely. -s and -w has to be set"
     echo "m: mv all .j* to date (dwfault today)"
     echo "h: print this message"
 }
sort_date(){
    anzahl_dates=0
    dir_dates=()
    for filename in *.j* ; do
        # date YYYYMMDD
        # tdate="${f:0:8}"
        # Extracting the date part (YYYYMMDD)
        date=$(echo "$filename" | grep -oP '\d{8}')
		# Check if the variable is already in the array
        if [[ ! " ${dir_dates[@]} " =~ " $date" ]]; then
            # Add the variable to the array
            dir_dates+=("$date")
            (( anzahl_dates++ ))
        fi

        #-p makes sure the dir is created or not w/o an error
        # mkdir -p "$tdate"

    done
    echo "found $anzahl_dates dates"

    for d in "${dir_dates[@]}"; do
        move_today $d
    done
}
 move_today() {
    if [[ "$#" -eq 1 ]]; then
    	# Argument provided, use it as the target date
        echo "Using the provided date: $1"
        dt="$1"
    else 
         # No argument provided, use today's date as the default
        echo "No date argument provided, using today's date."
    fi
    
    #use remote or local?
    [ -z "$rem_d" ] && cdir="$rem_d" || cdir="$loc_d"

    echo "creating directory of date $dt in current directory $cdir"
    cd "$cdir"
     mkdir -p "$dt"
     echo "moving all j* to directory $dt"
    # count 
    total=$(ls *"$dt"*.j* | wc -l)
    current_file=0

    for file in *"$dt"*.j*; do
        if [ -e "$file" ]; then
            sleep 1
            ((current_file++))
            echo -ne "\r$current_file/$total"
            mv "$file" "$dt/" > /dev/null 2>&1 #print nothing
        fi
    done

    echo "Files *.j* with $dt in the filename moved to '$dt/' directory."
    cd -
 }

######################################################
# argument parsing
######################################################
#main() {
# for arg in "$@"; do
# while [[ $# -gt 0 ]]; do
while getopts ":s:w:abcdhmlr" o; do
    case "${o}" in
        a)
            sort_date
            ;;
        l)
            echo -e "he"
            ;;
       m)
    		# Check next positional parameter
    		eval nextopt=\${$OPTIND}
    		# existing or starting with dash?
    		if [[ -n $nextopt && $nextopt != -* ]] ; then
      			OPTIND=$((OPTIND + 1))
      			move_today "$nextopt"
    		else
      			move_today
    		fi
    		;;
        s)
            # shift
            # server=$1
            server=${OPTARG}
            r_server "$[OPTARG]"
            ;;
        w)
            wp_site=${OPTARG}
            r_client "${OPTARG}"
            ;;
        r)
    		# Check next positional parameter
    		eval nextopt=\${$OPTIND}
    		# existing or starting with dash?
    		if [[ -n $nextopt && $nextopt != -* ]] ; then
      			OPTIND=$((OPTIND + 1))
      			rmf "$nextopt"
    		else
      			rmf
    		fi
            
            # rmf "${OPTARG}"
            ;;
        b)
            #if ssh connectionto server, go ahead else curl
            [ "$server_ssh" -eq 1 ] && bup_ssh || bup
            #backup and scp
            # bup
            ;;
        c)
            # copy (ssh)
            echo "copy to $local_d..."
            # ssh "${rem_h}" "find $rem_d -type f -name '*.j*' -newermt $dt
            # -exec cp {} $local_d/ \;"
            # scp "${rem_h}":"${re m_d}/*$dt*"  "$local_d"
            # scp "${rem_h}":"${rem_d}/*.j*"  "$local_d"
            rsync -avP --remove-source-files "$rem_h":"$rem_d" "$local_d"
            ;;
        d)
            #delete remote backup
            if [[  -n "$rm_a" ]]; then
                echo "rm remote"
                ssh "${rem_h}" "${rm_a}"
                echo "Files removed from the remote server."
            fi
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;

    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    # shift
done
shift $((OPTIND-1))
#}
 #echo "s:$server w:$wp_site arg:$#"

#main "$@"
