#!/bin/bash

# This is the final stage of provisioning, which runs
# within the system that has already been:
#    - partitioned
#    - a base set of packages installed
#    - rebooted if necessary
#    - configuration vars generated into /etc/ss
#    - gpg keys imported
#    - system timezone configured
#    - important 'well known' hosts added to /etc/hosts
#    - soestack provisioning copied to /soestack/provision

#
# For a network install, this will be after the anaconda install has finished.
# For a vagrant install, this will be after the vagrant image has had minimal setup.
#

function provision_routine()
{
    echo "$(date) ${0##*/} Start."

    . /soestack/provision/common/lib/lib-provision.sh 

    load_dyn_vars

    mkdir -p /var/log/provision 

    soestack_provision 2>&1 | tee -a /var/log/provision/provision-soestack.log

    echo "$(date) ${0##*/} Done."
}

mkdir -p /var/log/provision

if [[ "${1}" == "console" ]]
then
    provision_routine
else
    provision_routine > /var/log/provision/provision-soestack-record.log 2>&1
fi

