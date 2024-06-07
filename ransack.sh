#!/usr/bin/env sh

set -e

usage() { echo "Usage: $0 [-defglsv] [filename] <directory>" >&2; exit 1;}

# filename = target
# directory = start

# verbose print
vprint () {
    if [[ $_V -eq 1 ]]; then
        printf "$@"
    fi
}

while getopts "dvslgfe" opt; do
    case $opt in
        d)
            # debug mode
            set -x
            ;;
        v)
            # verbose mode
            _V=1
            ;;
        s)
            # step mode
            _S=1
            ;;
        l)
            # file list mode
            _L=1
            ;;
        g)
            # 'globbing' mode : does not look for the exact name
            _G=1
            ;;
        f)
            # looks for files regardless of their extension. on by default if globbing mode is active
            _F=1
            ;;
        e)
            # only usable if globbing mode is active. looks for files with this exact extension.
            extension="${OPTARG}" >&2
            ;;
        *)
            # help
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# check if we're using a posix-compliant shell
[[ $_S -eq 1 ]] && vprint "$(set -o | grep posix)" && read -r ""

# set our target and our starting directory for clarity
target="${1}"
start="${2}"

# check if the last character is a slash, if it's not, add one
if [ "${start#"${start%?}"}" != "/" ]; then
    start="${start}/"
fi

# loop function, ransacks a directory
ransack() {(
    # set our local variable preventing overwriting due to recursivity
    filelist="$(echo "${1}"*)"
    recurlevel="${2}"
    
    vprint '\033cNiveau de récursivité : %s\033[0K\nDossier Courant : %s\033[0K' "${recurlevel}" "${1}"
    [[ $_L -eq 1 ]] && vprint '\nliste des fichiers : %s\033[0K' "${filelist}"
    [[ $_S -eq 1 ]] && read -r

    # quickly check for our target in the current working directory
    # instead of iterating through its files right away
    [[ $_G -ne 1 ]] && {
        # check for the exact name (exact mode, on by default)
        for file in $(echo "${filelist}"); do
            if [ "${file%/"${target}"}" != "${file}" ]; then
                printf "\n%s\n" "${file}"
                read -r
            fi
        done
        #if [ "${1%/"${target}"}" != "${1}" ]; then printf "\n%s%s\n" "${1}" "${target}" ; fi
        # case "$(echo "${1}"*)" in
        #     *"/${target}"* )
        #         printf "\n%s%s\n" "${1}" "${target}"
        #         ;;
        # esac
    } || {
        for file in $(echo "${filelist}"); do
            if [ "${file#*/"${target}"}" != "${file}" ]; then
                printf "\n%s\n" "${file}"
                read -r
            fi
        done
        # # check for a filename containing the target (globbing mode)
        # if [ "${1#*/"${target}"}" != "${1}" ]; then
        #     printf "\n%s%s\n" "${1}" "${target}"
        # fi
    }

    #posix compliant
    #if [ "${vartest#*"${target}"}" != "${vartest}" ]; then echo vartest .... V target ; else echo vartest .... X target ; fi
    #if [ "${vartest%"${target}"}" != "${vartest}" ]; then echo vartest .... V target à la fin ; else echo vartest .... X target à la fin; fi

    # if target not found, start iterating and repeating the loop
    for file in $(echo "${filelist}"); do
        if [ -d "${file}" ]; then
            ransack "${file}/" $(($recurlevel + 1))
        fi
    done
)}

ransack "${start}" 0

# check for exact file name but without knowing the extension (coder le -f et le -e)
# améliorer l'Usage
