#!/bin/bash

. "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib-provision.sh

VAGRANT_VARS="${SS_GEN}/1-vagrant-vars.sh"

function update_hostfile()
{
    # Update hosts file
    if [ ! -f /etc/hosts.orig ]
    then
        cp -f /etc/hosts /etc/hosts.orig
    fi

    sed -r \
        -e '/::1/ s/localhost localhost.localdomain //' \
        -e '/127.0.0.1/ s/\t/  /' \
        < /etc/hosts.orig \
        > /etc/hosts

    vagrant_ip=$(ip a | egrep 'inet.*eth0' | cut -d/ -f1 | awk '{print $2}')
    local h=$(hostname -s)

    # Delete our hostname from the localhost line also if it is there
    sed -i -r -e "/^127.0.0.1.*${h}/ s/[[:space:]]${h}([.][^[:space:]]+|[[:space:]]|\$)/ /g" \
        /etc/hosts

    # The vagrant node comes up with an extra 127.0.0.1 <hostname> line.
    # If it was present it will now be an empty 127.0.0.1 line.  Delete it!

    sed -i -r -e '/^127.0.0.1[[:space:]]*$/ d' /etc/hosts

    if [[ -n "${IPADDR}" ]]
    then
        line="${IPADDR} $(hostname -f) $(hostname -s)"
        if ! grep -q "${line}" /etc/hosts 
        then
            echo_return "${line}" >> /etc/hosts 
        fi
    fi 

    if [[ -n "${vagrant_ip}" ]]
    then
        line="${vagrant_ip} vagrant-ip.$(hostname -f)"
        if ! grep -q "${line}" /etc/hosts 
        then
            echo_return "${line}" >> /etc/hosts 
        fi
    fi 

    add_hosts

    indented "Hosts" cat /etc/hosts
}

function setup_vagrant_ssh()
{
    if is_development
    then
        # Centos vagrant image comes with PasswordAuthentication disabled. Enable it.
        sed -i '/^PasswordAuthentication no/ s/no/yes/' /etc/ssh/sshd_config
        systemctl restart sshd
    fi    
    [[ -f /root/.ssh/authorized_keys ]] || cp -f /home/vagrant/.ssh/authorized_keys /root/.ssh/
}

function import_gpgkeys()
{
    # Copy GPG keys
    /bin/cp -f "${SS_DIR}"/provision/common/inc/gpgkeys/* /etc/pki/rpm-gpg/
    rpm --import "${SS_DIR}"/provision/common/inc/gpgkeys/*
}

function set_root_password()
{
    if [[ -n "${ROOT_PW}" ]]
    then
        local escaped="${ROOT_PW}"
        escaped="${escaped//\\/\\\\}"
        escaped="${escaped//\$/\\\$}"
        sed -i -r -e "s%^root:([^:]*):%root:${escaped}:%" /etc/shadow 
        pwconv
        msg "Updated root password"
    fi
}

function update_yum_repos()
{
    msg "Disable existing yum repos."

    # Disable bundled repos
    [[ -n "${DISABLE_REPOS}" ]] && disable_repos ${DISABLE_REPOS//,/ }

    # Add our own repos
    msg "Install bootstrap repos."
    #cp -f "${SS_DIR}/provision/common/inc/bootstrap-${OS_NAME}.repo" /etc/yum.repos.d/
    # grep '^\[' /etc/yum.repos.d/bootstrap-*repo
    bootstrap_repos
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

# Often in vagrant images, files have been deleted
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

function generate_vagrant_vars()
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
        # Use the hostname from DHCP
        export HOSTNAME="${h}"
        echo_return "HOSTNAME=${HOSTNAME}"
        if [[ "${h}" =~ [.] ]]
        then
            export DOMAIN="${h#*.}"
            echo_return "DOMAIN=${DOMAIN}"
        fi
    fi

    export HARDWARE="vm"
    echo_return "HARDWARE=vm"

    export PROVISION_TYPE="vagrant"
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

    [[ -n "${GATEWAY}" ]] && echo_return "GATEWAY=${GATEWAY}"
    [[ -n "${IPADDR}" ]] && echo_return "IPADDR=${IPADDR}"
    [[ -n "${IPPREFIX}" ]] && echo_return "IPPREFIX=${IPPREFIX}"

    echo_return "NETDEV=${NETDEV}"

    echo_return "######"
    echo_return "# Boot commandline vars"
    echo_return "######"
    
    process_commandline_vars "${SS_GEN}/vagrant-commandline"
    echo_return "######"
    
    echo_return "set +e" 
}

function vagrant_provision_common()
{
    load_bootstrap_vars

    set_root_password
    setup_root_ssh

    setup_vagrant_ssh

    update_hostfile

    import_gpgkeys

    # Load kickstart-related vars and routines
    . "${SS_DIR}"/provision/kickstart/lib/lib.sh 

    # Load common provisioning routines
    . "${SS_DIR}"/provision/common/lib/lib-provision.sh

    load_kickstart_vars

    # This is done prior to the main provisioning because it saves a reboot
    fix_bootflags
}

function load_vagrant_vars()
{
    if [[ ! -f "${VAGRANT_VARS}" ]]
    then 
        generate_vagrant_vars > "${VAGRANT_VARS}"
    else
        notice "${VAGRANT_VARS} already created"
    fi 

    . "${VAGRANT_VARS}"
}

function vagrant_provision()
{
    local provisioning_commandline=()
    local item 
    local cfg_suffix='[.]cfg$'

    mkdir -p "${SS_GEN}"
    
    for item in "${@}"
    do 
        if [[ "${item}" == "--clean" ]]
        then
            msg "Clean ${SS_GEN} for regeneration"
            rm -f "${SS_GEN}"/*
        fi
    done 

    echo_stage 2 "Create ${SS_GEN}/vagrant-commandline"
    for item in "${@}"
    do 
        if [[ "${item}" == "--clean" ]]
        then
            : ignore - this has already been processed ;
        elif [[ "${item}" =~ ${cfg_suffix} ]]
        then 
            local try_file="${SS_DIR}/provision/vagrant/cfg/${item}"
            if [[ -f "${try_file}" ]]
            then
                echo "Using ${try_file}" 1>&2
                egrep -i '^ss[.]' < "${try_file}" | cut -c4-
            fi
        else
            local l r
            l="${item%%=*}"
            r="${item#*=}"
            echo_data "${l^^}=${r}"
        fi
    done > "${SS_GEN}/vagrant-commandline"

    # This will generate the vars first, which will utilise the vagrant-commandline file 
    # that was just created above
    load_vagrant_vars
    load_dyn_vars

    provisioning_display_build_configuration

    vagrant_provision_common

    #if ! is_standalone
    #then
    #    notice "Non-standalone server - updating yum repos"
    #    update_yum_repos
    #else 
    #    notice "Standalone server - bootstrap packages will be used."
    #    update_yum_repos
    #fi
    update_yum_repos

    configure_soestack_provision

    #echo_stage 5 "Running SS Provisioning"
    #systemctl restart soestack-provision
    #ls -lR "${SS_GEN}"
    # ${SS_DIR}/provision/common/provision.sh
    #systemctl start soestack-provision
    msg "Provisioning may be continued by starting the soestack-provision service"
    msg "Or by running '${SS_DIR}/provision/common/provision.sh console' to view"
    msg "the progress, or rebooting."

    msg ""
    msg "If building a standalone infrastructure server then, at this point"
    msg "you should check the network configuration first, before continuing."
    msg "."
}
