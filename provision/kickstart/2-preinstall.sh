#!/bin/bash
echo "$(date) ${0##*/} Start."

. /soestack/provision/kickstart/lib/lib.sh

load_dyn_vars

add_hosts

echo "$(date) ${0##*/} Done."
