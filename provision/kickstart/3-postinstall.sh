#!/bin/bash

. "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/kickstart/lib/lib-nochroot.sh

echo_start "${0##*/}"

# This script will run after package installation but from 
# within the install environment, not the chroot environment


load_dyn_vars

# Configure the hostname (in the new system)
step configure_hostname

# Copy the ss provisioning into the new system
step copy_ss_provisioning

if is_standalone
then
    echo_stage 3 "Copying files needed for standalone install"
    step copy_isopackages
    step copy_isos
    step copy_bundled_data
    step create_installmedia_repo
fi

echo_stage 2 "Copying install logs"
step copy_logs

echo_stage 2 "Almost done. Syncing written data."
sync

# Set up a fake wireless prior to reboot, if required
if is_wireless_simulated 
then
    simulate_wireless
fi

echo_done "${0##*/}"
