#!/bin/bash
. /soestack/provision/kickstart/lib/lib.sh

echo_start "${0##*/}"

load_dyn_vars

add_hosts

echo_done "${0##*/}"
