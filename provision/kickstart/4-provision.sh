#!/bin/bash
echo "$(date) ${0##*/} Start."

# This script will run inside the chroot after package installation
# but before the reboot

echo Provision

# Load kickstart-related vars and routines
. /soestack/provision/kickstart/lib/lib.sh 

# Load common provisioning routines
. /soestack/provision/common/lib/lib-provision.sh

load_kickstart_vars

configure_soestack_provision

# This is done prior to the main provisioning because it saves a reboot
fix_bootflags

# save a copy of this script
cp /tmp/ks-script* /var/log/provision/

echo "Reached end of pre-reboot provisioning."

if is_inspect
then
    echo "Inspection mode enabled - dropping into shell"
    msg "Inspection mode enabled - dropping into shell"
    bash -i
fi

if is_wait
then
    echo "Big sleep for (${WAIT} minutes)"

    for n in $(seq ${WAIT} -1 0)
    do
        echo "finishing in $n minutes"
        echo "Create the file /tmp/end-WAIT to abort the wait."
        sleep 60
        [[ -f /tmp/end-WAIT ]] && break
    done
fi > /dev/tty1 2>&1


echo "$(date) ${0##*/} Done."
