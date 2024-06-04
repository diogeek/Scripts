#! /usr/bin/env sh

usage() { echo "Usage: $0 [-d] [-s] [-p password]" >&2; exit 1;}

while getopts "dsp:" opt; do
    case $opt in
        d)
            set -x
            ;;
        s)
            printf "Password:"
            read -r password
            ;;
        p)
            password="${OPTARG}" >&2
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

password=$1

if [ -z "${password}" ]; then
    printf "Password:"
    trap "stty echo" INT EXIT
    stty -echo
    read -r password
    stty echo
    printf "\n"
fi

range=0

[ "$(echo "${password}" | sed 's/[^ -\/:-@[-\`{-~$]//g')" ] && range=$((range+33))
[ "${password}" != "$(echo "${password}" | tr "[:lower:]" "[:upper:]")" ] && range=$((range+26))
[ "${password}" != "$(echo "${password}" | tr "[:upper:]" "[:lower:]")" ] && range=$((range+26))
[ "$(echo "${password}" | sed 's/[^0-9$]//g')" ] && range=$((range+10))

echo "${#password}*l(${range})/l(2)" | bc -l
