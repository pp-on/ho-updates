#! /bin/env bash

# list and copy plugins (xsel || clip.exe)
wplistpl(){
    plugins=$(wp plugin list --update=available --field=name)
    i=1
    for p in $plugins; do
        echo "$i. $p"
        (( i++  ))
    done
    echo "Select"
    read i
    echo "$plugins[$i]" | $copy
    echo "$plugins[$i] copied"

} 
