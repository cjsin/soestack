#!/bin/bash

echo "Primary provisioning - Docker-specific" 1>&2

. "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/docker/lib/lib.sh

docker_provision "${@}"

for f in /etc/ss/*sh
do 
   echo_return "${f}"
   cat "${f}" | indent
done
