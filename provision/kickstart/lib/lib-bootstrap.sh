#!/bin/bash

[[ -n "${SS_LOADED_KS_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/kickstart/lib/lib.sh

# Patch device names of the style %USB%, or %HD0%, %HD1%,
# to match the found device names.
# This is done for two reasons -
#   - the primary reason is to protect the USB from being overwritten 
#     by the partitioning when the BIOS disk discovery order has changed
#   - the secondary reason is to automatically support virtual machines
#     ( so the partitioning can use %HD0% which will match vda in a VM and sda on a baremetal device)

function scan_devices()
{
    declare -a hds=()
    local usbdev=""
    local -a devs=( $( lsblk -d -p --noheadings -e 11 -e 7 | egrep '[[:space:]]disk' | egrep -v zram | cut -d ' ' -f1 | cut -d/ -f3-) )
    local d
    for d in "${devs[@]}"
    do
        msg "Checking device ${d}"
        if [[ "${USB_SRC#${d}}" != "${USB_SRC}" ]]
        then
            usbdev="${d}"
        else
            hds+=("${d}")
        fi
    done 
    echo_return "USB=${usbdev}" "${hds[@]}"
}

function patch_partitioning_for_usb()
{
    local devices=( $(scan_devices) )
    local partfile="${KS_GEN}/partitioning.cfg" 
    local usbdev=""
    local -a hds=()
    local dev
    for dev in "${devices[@]}"
    do
        case "${dev}" in
            USB=*) usbdev="${dev#USB=}";;
            *)     hds+=("${dev}");;
        esac
    done

    [[ -f "${partfile}.base" ]] ||  cp "${partfile}" "${partfile}.base"
    
    cp "${partfile}.base" "${partfile}.new"
    
    if [[ -n "${usbdev}" ]]
    then
        notice "USB device is ${usbdev}"
        # This device is the install source - protect it.
        sed -i "s,%USB%,${usbdev}," "${partfile}.new"
    fi

    local i=0
    for d in "${hds[@]}"
    do
        notice "hd[$i] is $d"
        sed -i "s,%HD${i}%,${d}," "${partfile}.new"
        ((i++))
    done
    cp "${partfile}.new" "${partfile}"
}

function update_bootloader_password()
{
    local partfile="${KS_GEN}/partitioning.cfg"
    local directives=""

    if [[ -n "${GRUB_PW}" ]]
    then 
        directives="--iscrypted --password=${GRUB_PW}"
    fi
    sed -i "s,%GRUB_PW%,${directives}," "${partfile}"
}

function update_root_password()
{
    local directives=""

    if [[ -n "${ROOT_PW}" ]]
    then 
        directives="rootpw --iscrypted ${ROOT_PW}"
    else
        directives="rootpw --plaintext password"
    fi

    sed "s,%ROOT_PW%,${directives}," < "${KS_INC}/rootpw.cfg" > "${SS_GEN}/rootpw.cfg"

    notice "Root password config is:"
    cat "${SS_GEN}/rootpw.cfg" 1>&2
    notice ""
}

function update_ssh_password()
{
    local directives=""

    if [[ -n "${SSH_PW}" ]]
    then 
        directives="${SSH_PW} --iscrypted"
    fi

    sed "s,%SSH_PW%,${directives}," < "${KS_INC}/ssh.cfg" > "${SS_GEN}/ssh.cfg"
}

function calculate_netmask()
{
    local prefix="${1:-24}"
    local netmask=""
    local bytes=$((prefix / 8))
    case "${bytes}" in
        2) netmask="255.255.X.0";;
        1) netmask="255.X.0.0";;
        0) netmask="X.0.0.0";;
        *) netmask="255.255.255.X";;
    esac 
    local nibbles=$(( prefix - ( 8*bytes) ))
    local nibble="0"
    case "${nibbles}" in
        0) nibble=0;;
        1) nibble=128;;
        2) nibble=192;;
        3) nibble=224;;
        4) nibble=240;;
        5) nibble=248;;
        6) nibble=252;;
        7) nibble=254;;
    esac
    netmask="${netmask//X/${nibble}}"
    echo "${netmask}"
}

function generate_kickstart_networkconfig()
{
    local -a options=(
        --onboot yes
        --device "${NETDEV:-eth0}" 
        --mtu=1500 
        --noipv6 
    )

    if [[ -n "${NAMESERVER}" ]]
    then
        local item
        for item in ${NAMESERVER//,/ }
        do
            options+=("--nameserver=${item}")
        done
    fi

    if [[ -z "${DOMAIN}" ]]
    then
        if [[ "${HOSTNAME}" =~ [.] ]]
        then
            DOMAIN="${HOSTNAME#*.}"
        elif [[ "$(hostname -f)" =~ [.] ]]
        then
            local hostname_f=$(hostname -f)
            DOMAIN="${hostname_f#*.}"
        fi
    fi

    if [[ -z "${HOSTNAME}" ]] && ! [[ "$(hostname)" =~ localhost ]]
    then
        hostname "${hostname}"
    fi

    if [[ -n "${HOSTNAME}" ]]
    then
        if [[ "${HOSTNAME}" =~ [.] ]]
        then 
            options+=("--hostname=${HOSTNAME}")
        elif [[ -n "${DOMAIN}" ]]
        then 
            options+=("--hostname=${HOSTNAME}.${DOMAIN}")
        else
            options+=("--hostname=${HOSTNAME}")
        fi
    fi

    if [[ -z "${IPADDRS}" && -n "${IPADDR}" ]]
    then
        IPADDRS="${IPADDR}/${IPPREFIX}"
    fi 

    if [[ -n "${IPADDRS}" && "${IPADDRS}" != "dhcp" ]]
    then
        local item
        for item in ${IPADDRS//,/ }
        do
            local ip="${item//\/*}"
            local prefix="24"
            [[ "${ip}" =~ / ]] && prefix="${ip##*/}"

            local netmask=$(calculate_netmask "${prefix}")
            # I think anaconda kickstart supports only one IP address...
            # so, break out after the first one
            options+=("--ip=${ip}" "--netmask=${netmask}")
            use_dhcp=0
            break
        done
    fi

    if (( use_dhcp )) && ! is_standalone
    then 
        options+=("--bootproto" "dhcp")
    fi

    echo network "${options[@]}" > "${SS_GEN}/network.cfg"
}

# EXAMPLE of using a hostname scheme to determine 
# the node role (and falling back to 'auto' which
# will look up the role out of pillar data).
# To use this, call this somewhere early in the bootstrap.
#
# function determine_role_from_hostname()
# {
#     local specifier="${HOSTNAME:6:1}"
#     local role="auto"
#     case "${specifier}" in 
#         w) role="role-set:developer-workstation-node"
#            ;;
#         p) role="role-set:login-processor-node"
#            ;;
#         *) echo "Unknown node role!" 1>&2      
#            ;;
#     esac 
#     export ROLES="${role}"
# }

function generate_partitioning()
{
    local installation_src="${1}"
    shift

    if [[ -z "${installation_src}" ]]
    then
        bmsg "ERROR: Installation source is mandatory for determining partitioning!" 1>&2
        bmsg "Bailing!" 1>&2
        return 1
    fi

    # lowercase it
    installation_src="${installation_src,,}"

    case "${installation_src}" in
        usb|pxe)
            bmsg "Installation source ${installation_src} is acceptable for partitioning" 1>&2
            ;;
        *)
            bmsg "Installation source type ${installation_src} is not a supported type - this could be a bug - bailing" 1>&2
            return 1
            ;;
    esac


    # for now, the install type isn't used but later it can be used
    # to select a different partitioning, eg for workstations versus servers
    # Example values - infrastructure,server,workstation

    # If more are specified, it allows even finer grained selection
    # Example values - singlevolume,datavolume

    local extra_tags="${*}"
    extra_tags="${extra_tags// /,}"
    tags="${installation_src}${extra_tags:+-}${extra_tags}" 

    local partitioning_selected="partitioning-${tags}.cfg"
    local preconfigured="${KS_DIR}/inc/${partitioning_selected}"

    if [[ -f "${preconfigured}" ]]
    then
        bmsg "Valid partitioning configuration - selected ${partitioning_selected}" 
        cat "${preconfigured}" > "${KS_GEN}/partitioning.cfg"
        patch_partitioning_for_usb
        update_bootloader_password
    else
        bmsg "Preconfigured partitioning for ${tags} was not found!" 1>&2
        return 1
    fi

}

function select_partitioning()
{
    # PARTITIONING can be set via ss.PARTITIONING on the boot commandline
    local extra_partitioning=( ${PARTITIONING} )
    generate_partitioning "${KICKSTART_TYPE}" "${HARDWARE}" "${extra_partitioning[@]}"
}

function generate_repositories()
{ 
    # The extra repos are for the pxe/nfs install only
    if [[ "${KICKSTART_TYPE}" == "pxe" ]]
    then
        local repo_lines=()
        local line

        for line in "${repos[@]}"
        do
            read name baseurl <<< "${line}"
            repo_lines+=("repo --name=${name} --baseurl=${baseurl}")
        done 

        append_lines "${KS_GEN}/repositories.cfg" create "${repo_lines[@]}"
    else 
        touch "${KS_GEN}/repositories.cfg"
    fi 
}

function generate_timezone()
{
    local tzconfig=""

    if [[ -n "${TIMEZONE}" ]]
    then
        if [[ -f "/usr/share/zoneinfo/${TIMEZONE}" ]]
        then 
            utc="--utc"

            case "${HWCLOCK^^}" in
                LOCAL) 
                    utc=""
                    ;;
                *)
                    ;;
            esac 
        
            tzconfig="timezone ${utc} ${TIMEZONE}"
        fi
    fi 

    echo_data "${tzconfig}" > $KS_GEN/timezone.cfg
}

function generate_selinux()
{
    local selinuxconf=""

    if [[ -n "${SELINUX}" ]]
    then
        case "${SELINUX}" in
            0|disabled) 
                selinuxconf=""
                ;;
            1|enabled|enforcing)
                selinuxconf="selinux --enforcing"
                ;;
            permissive)
                selinuxconf="selinux --permissive"
                ;;
            *) 
                selinuxconf=""
                ;;
        esac 
    fi

    echo_data "${selinuxconf}" > "${KS_GEN}/selinux.cfg"
}

function user_rebuild_confirmation()
{
    # First things first, don't just blow away a server without
    # an admin confirmation.

    if is_skip_confirmation
    then
        bmsg "Skipping rebuild confirmation (SKIP_CONFIRMATION=1 was present on the commandline) !"
        return 0
    else

        confirmation=""

        bmsg "Prompting for manual confirmation to continue on vt5" >> "${early_boot_logfile}"
        while [[ "${confirmation}" != "CONTINUE" ]]
        do
            bmsg "                                --NOTICE--"
            bmsg "$(display_bar)"
            bmsg "                This machine is about to be (re)installed."
            bmsg "$(display_bar)"
            bmsg ""
            bmsg "                     Manual confirmation is required."
            bmsg ""
            bmsg "            Please type CONTINUE to continue with the rebuild:"
            read confirmation
            bmsg "$(date)" >> "${early_boot_logfile}"
            bmsg "User response: ${confirmation}" >> "${early_boot_logfile}"
        done 

        if [[ "${confirmation}" != "CONTINUE" ]]
        then
            bmsg "Installation aborted!"
            exit 1
        fi

        bmsg "OK, continuing... Log file is ${early_boot_logfile}"

        bmsg "Build output will continue on console 1 (Alt+Ctrl+F1)."
        sleep 5

        if ! is_interactive
        then
            switch_to_logfile
        fi

        bmsg "Installation was manually approved to continue at $(date)" 
        return 0
    fi
}

# This is crucial for the kickstart because
# the files will be copied to /soestack, but the
# kickstart includes are relative to /root 
function setup_symlinks()
{
    cd /root
    ln -s /soestack soestack
    ln -s soestack/provision/kickstart
    ln -s kickstart/inc
    ln -s kickstart/lib
    ln -s "${KS_GEN}" gen
}
