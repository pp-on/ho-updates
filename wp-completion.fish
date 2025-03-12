function __fish_wp_complete
    set -l cur (commandline -ct)
    set -l opts (wp cli completions --line=(commandline -cp) --point=(string length -- (commandline -cp)))

    if string match -q "*<file>*" -- $opts
        # File completion
        printf "%s\n" (commandline -ct | string match -e '*')
    else if test -z "$opts"
        # Fallback to file completion
        printf "%s\n" (commandline -ct | string match -e '*')
    else
        # Normal command completion
        printf "%s\n" $opts
    end
end

complete -c wp -f -a "(__fish_wp_complete)"

