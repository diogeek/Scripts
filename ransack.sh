#!/usr/bin/env sh

printf "\n"

# echoes and crashes on error
set -e

# help / usage printing function
usage() {
    printf "Usage: %s [-dfglsv] [-e extension] [filename] <directory>\n\n -d        Debug mode : enables 'set -x'.\n -v        Verbose mode : outputs more info on each ransacked directory (& clears screen).\n -s        Step mode : Only available in verbose mode (-v). Waits for input inbetween every verbose output.\n -l        File list : Only available in verbose mode (-v). Displays a file list for each ransacked directory. WARNING : may crash %s.\n -g      Globbing mode : enables globbing. %s will also output files containing target filename, not only those that match the exact search term. In globbing mode, %s does not look for a specific extension by default. See -f.\n -f        Only available while NOT in globbing mode (-g). Opposite of -e. Look for any extension while not in globbing mode. Using -f, <target> will be considered extension-less and any matching filename (minus the extensions) will be output. \n -e        Extension : Only available in globbing mode (-g). Opposite of -f. %s will only look for filenames matching this extension, while still matching any filename containing <target>." "${0}" "${0}" "${0}" "${0}" >&2
    exit 1
}

# filename = target
# directory = start

# verbose print function
vprint () {
    if [[ $_V -eq 1 ]]; then
        printf "%s" "${@}"
    fi
}

# options list
while getopts "de:fglsv" opt; do
    case $opt in
        d)
            # Debug mode
            set -x
            ;;
        v)
            # Verbose mode
            _V=1
            ;;
        s)
            # Only usable if in verbose mode : Step mode
            [[ _V -eq 1 ]] && _S=1 || printf " [-s] : Step mode is only available in verbose mode (-v).\n" && exit 1
            ;;
        l)
            # File list mode
            [[ _V -eq 1 ]] && _L=1 || printf " [-l] : File lists are only available in verbose mode (-v).\n" >%2 && exit 1
            ;;
        g)
            # Globbing mode : does not look for the exact name but rather for any name containing the target filename.
            _G=1
            ;;
        e)
            # Only usable if globbing mode is active. Looks for files with this exact extension, which is not the default behavior of globbing mode.
            [[ _G -eq 1 ]] && extension="${OPTARG}" >&2 || printf " [-e] : Exact extension mode is on by default when not in globbing mode (-g). Enabling it without globbing mode being active has no effect.\n" >%2 && exit 1
            ;;
        f)
            # Looks for files regardless of their extension, which is not the default behavior with globbing mode disabled. On by default if globbing mode is active.
            [[ _G -eq 1 ]] && printf " [-f] : Any extension mode is on by default in globbing mode (-g). Enabling it has no effect.\n" >%2 || _F=1
            _F=1
            ;;
        *)
            # Help / Usage
            usage
            ;;
    esac
done

# shift past all passed options, thus setting $1 and $2 to be our passed parameters
shift $((OPTIND-1))

# check if we're using a posix-compliant shell
[[ $_S -eq 1 ]] && vprint "$(set -o | grep posix)" && read -r

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
    
    vprint '\033cRecursivity Depth : %s\033[0K\nCurrent Working Directory : %s\033[0K' "${recurlevel}" "${1}"
    [[ $_L -eq 1 ]] && vprint '\nFile list : %s\033[0K' "${filelist}"
    [[ $_S -eq 1 ]] && read -r

    # quickly check for our target in the current working directory
    # instead of iterating through its directories right away
    [[ $_G -ne 1 ]] && {
        # check for the exact name (exact mode, on by default)
        for file in $(echo "${filelist}"); do
            if [ "${file%/"${target}"}" != "${file}" ]; then
                printf "\n%s\n" "${file}"
            fi
        done
    } || {
        # check for a filename containing the target (globbing mode)
        for file in $(echo "${filelist}"); do
            if [ "${file#*/"${target}"}" != "${file}" ]; then
                printf "\n%s\n" "${file}"
            fi
        done
    }

    # if target not found, start iterating through directories and repeating the loop
    for file in $(echo "${filelist}"); do
        if [ -d "${file}" ]; then
            ransack "${file}/" $(($recurlevel + 1))
        fi
    done
)}

ransack "${start}" 0

# check for exact file name but without knowing the extension (coder le -f et le -e)
# améliorer l'Usage
