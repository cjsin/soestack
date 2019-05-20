#!/bin/bash

# Make sure that any errors cause a failure not an install
# because if a problem happens then it may have happened
# before the user confirmation has occurred.

. /soestack/provision/kickstart/lib/lib-bootstrap.sh

function completed_bootstrap()
{
    echo "Completed bootstrap: $(date)"
}

# This is done before calculating the kickstart vars, which
# will hopefully be able to use the DHCP hostname
# Therefore we cannot use 'is_standalone'
if ! grep -q ss.STANDALONE=1 /proc/cmdline
then
    dhcp_hostname_fix
fi

load_kickstart_vars

if [[ -n "${TIMEZONE}" && -f "/usr/share/zoneinfo/${TIMEZONE}" ]]
then 
    echo "Configuring timezone in install environment"
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
fi

date

setup_symlinks

switch_to_console

date

display_build_configuration

# echo running from ${PWD} Install path will be ${ANA_INSTALL_PATH}

set -e
user_rebuild_confirmation
set +e

step add_hosts

step generate_repositories
step generate_timezone
step generate_selinux

step select_partitioning
step update_bootloader_password
step update_root_password
step update_ssh_password

step completed_bootstrap

if ! is_interactive
then 
    switch_to_logfile
fi

