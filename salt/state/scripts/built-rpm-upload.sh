#!/bin/bash

rpmfile="${1}"

if ! [[ "${rpmfile}" =~ [.]rpm ]]
then
    echo "ERROR: an rpm file must be specified" 1>&2
    exit 1
fi

name=$(basename "${rpmfile}")

url="http://nexus:7081/repository/built-rpms/soestack/demo/${name}"

echo "File ${name} will be uploaded as ${url}"

#this will prompt for the password
curl -v --user "admin" --upload-file "${rpmfile}" "${url}" 
