#!/bin/bash

. "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib-provision.sh

DOCKER_VARS="${SS_GEN}/1-docker-vars.sh"

function import_gpgkeys()
{
    # Copy GPG keys
    /bin/cp -f ${SS_DIR}/provision/common/inc/gpgkeys/* /etc/pki/rpm-gpg/
    rpm --import ${SS_DIR}/provision/common/inc/gpgkeys/*
}

function find_bad_packages()
{
    local verbose="${1:-0}"
    local p output
    for p in $(rpm -qa)
    do 
        output=$(rpm -q --verify "$p"  | egrep -i ^missing)
        if [[ -n "${output}" ]]
        then 
            if (( verbose ))
            then
                sed "s/^/${p}:/" <<< "${output}"
            else
                echo_return "${p}"
            fi
        fi
    done
}

# Often in docker images, files have been deleted
# to make the image smaller.
# In the centos image for example, the man-pages package
# is installed but the man pages are not present.
function reinstall_bad_packages()
{
    local -a reinst_packages=(
        man-pages python-urllib3 wpa_supplicant
    )
    yum -y reinstall "${reinst_packages[@]}"
}

function generate_docker_vars()
{
    load_bootstrap_vars

    echo_return "set -e"

    # Produce auto-calculated vars first
    echo_return "######"
    echo_return "# Calculated vars"
    echo_return "######"

    local h=$(hostname -f)
    if ! [[ "${h}" =~ localhost ]]
    then 
        # Use the hostname assigned to the container
        export HOSTNAME="${h}"
        echo_return "HOSTNAME=${HOSTNAME}"
        if [[ "${h}" =~ [.] ]]
        then
            export DOMAIN="${h#*.}"
            echo_return "DOMAIN=${DOMAIN}"
        fi
    fi

    export HARDWARE="docker"
    echo_return "HARDWARE=docker"

    export PROVISION_TYPE="docker"
    echo_return "PROVISION_TYPE=${PROVISION_TYPE}"

    if [[ -z "${NETDEV}" ]]
    then 
        current_NETDEV=$(determine_network_device)
        if [[ -n "${current_NETDEV}" && "${current_NETDEV}" != "${SKIP_NETDEV}" ]]
        then
            export NETDEV="${current_NETDEV}"
        fi
    fi

    if [[ -z "${IPADDR}" ]]
    then 

        local current_IPADDR_PREFIX=$(determine_current_ipaddr_prefix)

        if [[ -n "${current_IPADDR_PREFIX}" ]]
        then
            read current_IPADDR current_PREFIX <<< "${current_IPADDR_PREFIX//\// }"
            if [[ -n "${current_IPADDR}" ]]
            then 
                export IPADDR="${current_IPADDR}"
            fi
            if [[ -n "${current_PREFIX}" ]]
            then
                export IPPREFIX="${current_PREFIX}"
            fi 
        fi
    else
        warn "No IPPREFIX was specified, but IPADDR was - using an IPPREFIX of 24"
        if [[ -z "${IPPREFIX}" ]]
        then
            export PREFIX="24"
        fi
    fi

    if [[ -z "${GATEWAY}" ]]
    then

        local current_GATEWAY=$( ip route | egrep '^default via' | awk '{print $3}' | uniq | head -n1)

        if [[ -z "${current_GATEWAY}" ]]
        then
            if command_is_available route > /dev/null 2> /dev/null
            then
                current_GATEWAY=$( route -n | egrep '^0[.]0[.]0[.]0' | head -n1 | awk '{print $2}' ) 
            fi
        fi

        if [[ -n "${current_GATEWAY}" ]]
        then 
            export GATEWAY="${current_GATEWAY}"
        fi
    fi

    [[ -n "${GATEWAY}"  ]] && echo_return "GATEWAY=${GATEWAY}"
    [[ -n "${IPADDR}"   ]] && echo_return "IPADDR=${IPADDR}"
    [[ -n "${IPPREFIX}" ]] && echo_return "IPPREFIX=${IPPREFIX}"

    echo_return "NETDEV=${NETDEV}"

    echo_return "######"
    echo_return "# Boot commandline vars"
    echo_return "######"
    
    process_commandline_vars "${SS_GEN}/docker-commandline"
    echo_return "######"
    
    echo_return "set +e" 
}

function docker_provision_common()
{
    load_bootstrap_vars

    #update_hostfile

    import_gpgkeys

    # Load kickstart-related vars and routines
    . ${SS_DIR}/provision/kickstart/lib/lib.sh 

    # Load common provisioning routines
    . ${SS_DIR}/provision/common/lib/lib-provision.sh

    load_kickstart_vars

}

function load_docker_vars()
{
    if [[ ! -f "${DOCKER_VARS}" ]]
    then 
        generate_docker_vars > "${DOCKER_VARS}"
    else
        notice "${DOCKER_VARS} already created"
    fi 

    . "${DOCKER_VARS}"
}

function docker_provision()
{
    local provisioning_commandline=()
    local item 
    local cfg_suffix='[.]cfg$'
    
    echo_stage 2 "Create ${SS_GEN}/docker-commandline"
    mkdir -p "${SS_GEN}"
    for item in "${@}"
    do 
        if [[ "${item}" =~ ${cfg_suffix} ]]
        then 
            local try_file="${SS_DIR}/provision/docker/cfg/${item}"
            if [[ -f "${try_file}" ]]
            then
                egrep -i '^ss[.]' < "${try_file}" | cut -c4-
            fi
        else
            local l r
            l="${item%%=*}"
            r="${item#*=}"
            echo_data "${l^^}=${r}"
        fi
    done > "${SS_GEN}/docker-commandline"

    # the basic 'ip' tool is not even included in the 200 MB centos image
    yum -y install iproute

    # This will generate the vars first, which will utilise the docker provisioning commandline file 
    # that was just created above
    load_docker_vars

    provisioning_display_build_configuration

    docker_provision_common

    echo "Now ${SS_DIR}/provision/common/provision.sh may be run"
}
