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
#    - soestack provisioning copied to ${SS_DIR}/provision

#
# For a network install, this will be after the anaconda install has finished.
# For a vagrant install, this will be after the vagrant image has had minimal setup.
#

# Make sure SS_DIR is set
: ${SS_DIR:-${BASH_SOURCE[0]%/provision/*}} ;
log_dir="/var/log/provision"
log_file="${log_dir}/provision-soestack.log"
record_file="${log_dir}/provision-soestack-record.log"

function provision_routine()
{
    echo_start "${0##*/}"

    load_dyn_vars

    mkdir -p "${log_dir}"

    set -o pipefail
    soestack_provision 2>&1 | tee -a "${log_file}"

    echo_done "${0##*/}"
}

function usage()
{
    echo "Usage: ${0##*/} [-vx|+vx] [console]" 1>&2
}

function common_provision_main()
{
    . "${SS_DIR}/provision/common/lib/lib-provision.sh"

    is_docker && echo "Running within docker. Some functionality will be disabled."

    mkdir -p "${log_dir}"

    local routine="provision_routine"
    local remaining=()
    local use_console=0

    local arg
    while (( $# ))
    do 
        arg="${1}"
        shift
        case "${arg}" in
            -vx)
                set -vx
                ;;
            +vx)
                set +vx
                ;;
            console|-console|--console)
                use_console=1
                ;;
            +console)
                use_console=0
                ;;
            [a-z]*)
                if declare | egrep "^${arg} [(]])]$"
                then
                    provision_routine="${arg}"
                    remaining=( "${@}")
                    while (( $# )) ; do shift ; done
                    break
                else 
                    usage
                    exit 1
                fi
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    done

    if (( use_console ))
    then
        "${routine}" "${remaining[@]}"
    else
        "${routine}"  "${remaining[@]}" > "${logfile}" 2>&1
    fi
}

common_provision_main "${@}"
