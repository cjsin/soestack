#!/bin/bash
script="${BASH_SOURCE[0]}"
script=$(readlink -f "${script}")
dir="${script%/*}"

dirs=( "${dir}"/*/repodata )

for d in "${dirs[@]}"
do
    top="${d%/*}"
    echo "Updating ${top}" 1>&2
    ( cd "${top}" && createrepo --update . )
done
