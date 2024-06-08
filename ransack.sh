#!/usr/bin/env sh

printf "\n"

# echoes and crashes on error
set -e

programname="${0#"./"}"

# help / usage printing function
usage() {
    printf "Usage: %s [-dEglsvh] [-e extension] [filename] <directory>

 -d ...... Debug mode : enables 'set -x'.

 -v ...... Verbose mode : outputs more info on each ransacked directory
           (also clears screen).

 -s ...... Step mode : Only available in verbose mode (-v).
           Waits for input inbetween every verbose output.

 -l ...... File list : Only available in verbose mode (-v).
           Displays a file list for each ransacked directory.
           WARNING : may crash %s.

 -g ...... Globbing mode : enables globbing. %s will also output files
           containing target filename, not only those that match the exact
           search term. In globbing mode, %s does not look for a specific
           extension by default. See -E.

 -e ...... Extension : Default behavior, therefore only available in globbing
           mode (-g). Opposite of -E. %s will only look for filenames matching
           this extension, while still matching any filename containing
           <target>.

 -E ...... No known Extension : Default behavior in globbing mode (-g),
           therefore only available while NOT in globbing mode. Opposite of -e.
           Look for any extension while not in globbing mode. Using -E, <target>
           will be considered extension-less and any matching filename
           (including the dots, minus the extensions) will be output.
" "${programname}" "${programname}" "${programname}" "${programname}" "${programname}" >&2
    exit 1
}

# verbose print function
vprint () {
    if [ "${_V}" = "1" ]; then
        printf "${@}"
    fi
}

# primary options : debug,  globbing mode, verbose, error catching
while getopts ":dgvlse:E" opt; do
    case $opt in
        d)
            # Debug mode
            set -x
            ;;
        v)
            # Verbose mode
            _V=1
            ;;
        g)
            # Globbing mode : does not look for the exact name but rather for any name containing the target filename.
            _G=1
            ;;
        l)
            ;;
        s)
            ;;
        e)
            ;;
        E)
            ;;
        ?)
            # Help / Usage
            usage
            ;;
        *)
            # Help / Usage
            usage
            ;;
    esac
done

# in order to repeat getopts, reset OPTIND to 1
OPTIND=1

# secondary options : file list, step mode, extension handling
while getopts "lse:Edgv" opt; do
    case $opt in
        l)
            # File list mode
            [ "${_V}" = "1" ] && _L=1 || ( printf " [-l] : File lists are only available in verbose mode (-v).\n" >&2 && exit 1 )
            ;;
        s)
            # Only usable if in verbose mode : Step mode
            [ "${_V}" = "1" ] && _S=1 || ( printf " [-s] : Step mode is only available in verbose mode (-v).\n" >&2 && exit 1 )
            ;;
        e)
            # Only usable if globbing mode is active. Looks for files with this exact extension, which is not the default behavior of globbing mode.
            [ "${_G}" = "1" ] && extension="${OPTARG}" >&2 || ( printf " [-e] : Exact extension mode is on by default when not in globbing mode (-g). Enabling it without globbing mode being active has no effect.\n" >%2 && exit 1 )
            ;;
        E)
            # Looks for files regardless of their extension, which is not the default behavior with globbing mode disabled. On by default if globbing mode is active.
            [ "${_G}" = "1" ] && printf " [-f] : Any extension mode is on by default in globbing mode (-g). Enabling it has no effect.\n" >%2 || _E=1
            ;;
        d)
            ;;
        v)
            ;;
        g)
            ;;
        ?)
            # Help / Usage
            usage
            ;;
        *)
            # Help / Usage
            usage
            ;;
    esac
done

# shift past all passed options, thus setting $1 and $2 to be our passed parameters
shift $((OPTIND-1))

# check if we're using a posix-compliant shell (only useful if currently in verbose and step mode)
[ "${_S}" = "1" ] && vprint "$(set -o | grep posix)" && read -r


# arguments > variables
# filename  |  target
# directory |  start

if [ ! -z "${1}" ]; then
    # set our target and our starting directory for clarity
    target="${1}"
else
    # if no argument is passed, the user clearly doesn't know what they're doing so let's throw a help page just in case
    usage
fi

# "./" is set to be the default value for the facultative <directory> parameter.
if [ -z "${2}" ]; then
    start="./"
else
    # if $2 is not a directory, throw an error
    if [ -d "${2}" ]; then
        # check if the last character is a slash, if it's not, add one
        if [ "${2#"${2%?}"}" != "/" ]; then
            start="${2}/"
        else
            start="${2}"
        fi
    else 
        printf " Error : %s is not a directory\n" "${2}" >%2 && exit 1 
    fi
fi

# loop function, ransacks a directory
ransack() {(
    # set our local variable preventing overwriting due to recursivity
    filelist="$(echo "${1}"*)"
    recurlevel="${2}"
    
    vprint '\033[H\033[JRecursivity Depth : %s\033[0K\nCurrent Working Directory : %s\033[0K' "${recurlevel}" "${1}"
    [ "${_L}" = "1" ] && vprint '\nFile list : %s\033[0K' "${filelist}"
    [ "${_S}" = "1" ] && read -r

    # quickly check for our target in the current working directory
    # instead of iterating through its directories right away
    [ "${_G}" != "1" ] && {
        # check for the exact name (exact mode, on by default)
        for file in $(echo "${filelist}"); do
            if [ "${file%/"${target}"}" != "${file}" ]; then
                printf "%s\n" "${file}"
            fi
        done
    } || {
        # check for a filename containing the target (globbing mode)
        for file in $(echo "${filelist}"); do
            if [ "${file#*/"${target}"}" != "${file}" ]; then
                printf "%s\n" "${file}"
            fi
        done
    }

    # if target not found, start iterating through directories and repeating the loop
    for file in $(echo "${filelist}"); do
        if [ -d "${file}" ]; then
            ransack "${file}/" $(("${recurlevel}" + 1))
        fi
    done
)}

ransack "${start}" 0

# coder -e et -E
# trouver un moyen de faire en sorte que le print que j'utilise pour output les matchs ne soit pas écrasé par les caractères d'échappement du mode verbose : eh oui actuellemnt quand on trouve un résultat qui match on l'output sur le coup, ce qui fait qu'il finit par être supprimé lors du clear que j'effectue au début de chaque itération du printf verbeux
