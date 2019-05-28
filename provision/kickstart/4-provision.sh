#!/bin/bash
# Load kickstart-related vars and routines

[[ -n "${SS_LOADED_KS_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/kickstart/lib/lib.sh

echo_start "${0##*/} Start"

# This script will run inside the chroot after package installation
# but before the reboot

# Load common provisioning routines
. "${SS_DIR}"/provision/common/lib/lib-provision.sh

load_kickstart_vars

configure_soestack_provision

# This is done prior to the main provisioning because it saves a reboot
fix_bootflags

# save a copy of this script
cp /tmp/ks-script* /var/log/provision/

notice "Reached end of pre-reboot provisioning."

if is_inspect
then
    notice "Inspection mode enabled - dropping into shell"
    bash -i
fi

if is_wait
then
    msg "Big sleep for (${WAIT} minutes)"

    for n in $(seq ${WAIT} -1 0)
    do
        msg "finishing in $n minutes"
        msg "Create the file /tmp/end-WAIT to abort the wait."
        sleep 60
        [[ -f /tmp/end-WAIT ]] && break
    done
fi > /dev/tty1 2>&1


echo_done "${0##*/}"
