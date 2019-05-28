#!/bin/bash

[[ -n "${SS_LOADED_KS_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/kickstart/lib/lib.sh

echo_start "${0##*/}"

load_dyn_vars

add_hosts

echo_done "${0##*/}"
