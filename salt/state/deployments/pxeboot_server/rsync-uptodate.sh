#!/bin/bash 
# Return 0 if the destination does not need to be updated
dry="${1}"
a="${2}"
b="${3}"
c="${4}"

if [[ -z "${c}" ]]
then
    echo "Refusing to operate without sanity check" 1>&2
    exit 0
fi

if ! [[ "${a}" =~ ${c} ]]
then 
    echo "Sanity check - Refusing to operate on '${a}'" 1>&2
    exit 0
fi 

if ! [[ "${b}" =~ ${c} ]]
then 
    echo "Sanity check - Refusing to operate on '${b}'" 1>&2
    exit 0
fi 

cmd=(
    rsync -av  --info=stats0,flist0
)

if [[ "${dry}" != "real" ]]
then
    line_count=$( "${cmd[@]}" --dry-run "${a}/" "${b}/" | wc -l)
    if (( line_count ))
    then 
        echo "Destination needs updating ( ${line_count} lines)"
        exit 1
    else
        echo "Destination does not need updating"
        exit 0
    fi
else
    mkdir -p "${b}"
    echo "Updating:"
    "${cmd[@]}" "${a}/" "${b}/"
    echo "done."
fi