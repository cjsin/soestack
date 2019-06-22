#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

export KS_DIR="${PROVISION_DIR:=${SS_DIR}/provision}/kickstart"
export KS_LIB="${KS_DIR}/lib"
export KS_INC="${KS_DIR}/inc"
export KS_CFG="${KS_DIR}/cfg"
export KS_GEN="${SS_GEN}" # Note, generating into the toplevel soestack cfg gen folder
export KS_VARS="${KS_GEN}/2-ks-dynamic-vars.sh"
export PW_VARS="${KS_GEN}/3-ks-passwords.sh"
export SS_LOADED_KS_LIB=1

early_boot_logfile="/tmp/provision-1-bootstrap.log"
current_output_destination="${current_output_destination:-logfile}"

# NOTE: This is overriding a routine provided in provision/common/lib.sh
function bmsg()
{
    echo_return "${*}"
    if [[ "${current_output_destination}" == "console" ]]
    then
        echo_data "${*}" >> "${early_boot_logfile}"
    fi
}

function switch_to_console()
{
    if [[ "${current_output_destination}" != "console" ]]
    then 
        bmsg "Switching to console 5"
        exec < /dev/tty5 > /dev/tty5 2> /dev/tty5
        chvt 5
    fi 
    current_output_destination="console"
}

function switch_to_logfile()
{
    bmsg "Switching to log file only"
    exec >> "${early_boot_logfile}" 2>&1
    current_output_destination="logfile"
}

# function determine_timezone()
# {
# 
# }

function check_ipa_host()
{
    local host="$(hostname -f)"
    local search=""

    if ! [[ "${host}" =~ [.] ]]
    then
        if [[ -n "${DOMAIN}" ]]
        then
            host="${host}.${DOMAIN}"
        else
            search="+search"
        fi
    fi

    if command -v dig > /dev/null 2>/dev/null
    then
        local arecord=$(dig ${search} A "${host}" | grep -A1 ANSWER.SECTION:)
        local sshfp_record=$(dig ${search} SSHFP "${host}" | grep -A1 ANSWER.SECTION:)

        if [[ -n "${arecord}" ]]
        then
            if [[ -n "${sshfp_record}" ]]
            then
                spam notice "The host was already enrolled and needs to be re-enrolled prior to rebuilding!"
                spam notice "Please use host-rm/host-add to re-enrol it."
                return 1
            else
                spam notice "The host appears to be enrolled ready to (re)build."
                return 0
            fi
        else
            spam notice "The host does not seem to be recognised!"
            return 1
        fi
    else
        spam notice "The required tools are not available for checking host enrolment."
        return 0
    fi
}

function check_host_recognised()
{
    local host=$(hostname -s)
    
    if [[ "${host}" == "localhost" ]]
    then
        spam notice "Hostname detected as 'localhost'."
        spam notice "Please check:"
        spam notice "  - is the host mac address defined correctly in the SOE configuration"
        spam notice "  - is the host booting from the correct DHCP server"
        exit 1
    fi

    if ! is_standalone
    then
        while ! check_ipa_host
        do
            spam notice "Either the host is not registered in IPA, needs to be re-enrolled, "
            spam notice "or you booted off the wrong DHCP server."
            spam notice "You may enrol the host now using the host-add command."
            spam notice "Checking again in a minute."
            sleep 60
        done
    fi
}

function dhcp_hostname_fix()
{
    if ! grep -q ss.STANDALONE=1 /proc/cmdline
    then
        if [[ "$(hostname -s)" =~ localhost ]] && ps -wef | egrep -q dhclient
        then 
            msg "Applying DHCP hostname fix"
            # Release IP address so that hostname will be processed.
            # This is because NetworkManager tries to do everything but fails
            # at the basics, as always.
            dhclient -r eth0 
            dhclient 4 -x &
            sleep 5
            dhclient eth0 &
            sleep 3
        fi
    fi
}

function determine_kickstart_type()
{
    local nfs_server="${1}"
    local usb_installsrc="${2}"
    local vagrant_src="${3}"

    local count=0 is_nfs=0 is_usb=0 is_vagrant=0

    [[ -n "${nfs_server}" ]] && ((is_nfs++))
    [[ -n "${usb_installsrc}" ]] && ((is_usb++))
    [[ -n "${vagrant_src}" ]] && ((is_vagrant++))

    count=$((is_nfs + is_usb))

    if [[ "${count}" -gt 1 ]]
    then
        bmsg "ERROR: Could not determine if installation is from the network or from USB" 1>&2
        bmsg "       (it appears to be both)" 1>&2
        bmsg "Bailing - to avoid overwriting a USB by accident" 1>&2
        exit 1
    elif (( is_usb ))
    then
        echo_return "usb"
    elif (( is_nfs ))
    then
        echo_return "pxe"
    elif (( is_vagrant ))
    then
        echo_return "vagrant"
    elif is_docker
    then
        echo_return "docker"
    else
        bmsg "ERROR: Could not determine if installation is from the network or from USB" 1>&2
        bmsg "       or a vagrant image (it appears to be none of the above)" 1>&2
        bmsg "Bailing - this affects the partitioning and I wouldn't want to partition the wrong drive." 1>&2
        exit 1
    fi
}

function generate_kickstart_vars()
{
    echo_return "set -e"

    # Produce auto-calculated vars first
    echo_return "######"
    echo_return "# Calculated vars"
    echo_return "######"

    echo_return "# OS release vars"
    if [[ -n "${relname}" ]]
    then
        if [[ -f "${KS_LIB}/${relname}.sh" ]]
        then
            . "${KS_LIB}/${relname}.sh"
        fi
    fi

    echo_return "# Installation vars"
    export NFS_SERVER=$( grep /run/install/repo /proc/mounts | head -n1 | awk '{print $1}' | grep : | cut -d: -f1 )
    echo_return "NFS_SERVER=${NFS_SERVER}"

    export USB_SRC=$( grep /run/install/repo /proc/mounts | head -n1 | awk '{print $1}' | grep ^/dev | sed 's%^/dev/%%' )
    echo_return "USB_SRC=${USB_SRC}"

    export VAGRANT_SRC=$([[ -d "/vagrant" ]] && echo_return "/vagrant")

    export KICKSTART_TYPE=$(determine_kickstart_type "${NFS_SERVER}" "${USB_SRC}" "${VAGRANT_SRC}")
    echo_return "KICKSTART_TYPE=${KICKSTART_TYPE}"

    echo_return "TIMEZONE=${TIMEZONE:-UTC}"

    echo_return "# Static vars for ${KICKSTART_TYPE}"
    local static_vars="${KS_CFG}/static-vars-${KICKSTART_TYPE}.sh"
    if [[ -f "${static_vars}" ]]
    then
        cp -f "${static_vars}" "${KS_GEN}/1-ks-${KICKSTART_TYPE}-default-vars.sh"
        . "${static_vars}"
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
    elif [[ -z "${IPPREFIX}" ]]
    then
        notice "Defaulting to IPPREFIX=24"
        export IPPREFIX="24"
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

    if [[ -z "${NETDEV}" ]]
    then
        notice "# NETDEV was not set - determining it from current configuration"
        current_NETDEV=$(determine_network_device)
        if [[ -n "${current_NETDEV}" && "${current_NETDEV}" != "${SKIP_NETDEV}" ]]
        then
            export NETDEV="${current_NETDEV}"
        fi
    fi

    echo_return "# Network vars"
    [[ -n "${GATEWAY}" ]] && echo_return "GATEWAY=${GATEWAY}"
    [[ -n "${IPADDR}" ]] && echo_return "IPADDR=${IPADDR}"
    [[ -n "${IPPREFIX}" ]] && echo_return "IPPREFIX=${IPPREFIX}"

    echo_return "NETDEV=${NETDEV}"

    echo_return "# Passwords etc"    
    # Load distributed provisioning passwords, prior to the pxe commandline
    if [[ -f "${SS_INC}/password-fallbacks.sh" ]]
    then 
        . "${SS_INC}/password-fallbacks.sh"
    fi

    # Load distributed provisioning passwords, prior to the pxe commandline
    if [[ -f "${SS_INC}/provisioning-passwords.sh" ]]
    then 
        . "${SS_INC}/provisioning-passwords.sh"
    fi

    echo_return "######"
    echo_return "# Boot commandline vars"
    echo_return "######"
    if [[ -d /vagrant ]]
    then 
        echo_return "# Kernel commandline var processing skipped for vagrant install."
    else
        process_commandline_vars kernel
    fi

    # Check if passwords were set via pxe
    # These will be generated one time
    if [[ ! -f "${PW_VARS}" ]]
    then 
        {

            if [[ -z "${ROOT_PW}" ]]
            then 
                ROOT_PW="${FALLBACK_ROOT_PW}"
            fi
            echo_return "ROOT_PW='${ROOT_PW}'"
            export ROOT_PW

            if [[ -z "${GRUB_PW}" ]]
            then 
                GRUB_PW="${FALLBACK_GRUB_PW}"
            fi
            echo_return "GRUB_PW='${GRUB_PW}'"
            export GRUB_PW

            if [[ -z "${SSH_PW}" ]]
            then 
                SSH_PW="${FALLBACK_SSH_PW}"
            fi
            echo_return "SSH_PW='${SSH_PW}'"
            export SSH_PW

        } > "${PW_VARS}"
    fi 

    # These are then loaded but not echoed
    . "${PW_VARS}"

    echo_return "######"
    echo_return "set +e" 
}

function load_kickstart_vars()
{
    load_bootstrap_vars

    if ! [[ -f "${KS_VARS}" ]]
    then 
        generate_kickstart_vars > "${KS_VARS}"
    fi 

    . "${KS_VARS}"
    . "${PW_VARS}"
    
    
    # The network device is recalculated each time,
    # because ideally we are reconfiguring it to use ethX style during the
    # install, whereas during early install it may be eno1 or enp0s25 style.
    export NETDEV=$(determine_network_device)
    
    #if ! grep -q "NETDEV=${NETDEV}" "${KS_VARS}"
    #then 
    #    sed -i "/NETDEV/ s/.*/NETDEV=${NETDEV}/" "${KS_VARS}"
    #fi
}
