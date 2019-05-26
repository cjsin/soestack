#!/bin/bash
echo "$(date) ${0##*/} Start."

# This script will run after package installation but from 
# within the install environment, not the chroot environment

. /soestack/provision/kickstart/lib/lib-nochroot.sh

load_dyn_vars

# Configure the hostname (in the new system)
step configure_hostname

# Copy the ss provisioning into the new system
step copy_ss_provisioning

if is_standalone
then
    echo "Copying files needed for standalone install"
    step copy_isopackages
    step copy_isos
    step copy_bundled_data
    step create_installmedia_repo
fi

echo "Copying install logs"
step copy_logs

echo "Almost done. Syncing written data."
sync

# Set up a fake wireless prior to reboot, if required
if is_wireless_simulated 
then
    simulate_wireless
fi

echo "$(date) ${0##*/} Done."
