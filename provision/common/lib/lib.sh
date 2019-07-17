#!/bin/bash

[[ -n "${SS_LOADED_SS_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib-ss.sh

# NOTE: This script will override some vars and functions which were initialised in the file included above.

# Set SS_DIR if not set already, using the path of this script
SS_DIR="${SS_DIR:-${BASH_SOURCE[0]%/provision/*}}"
export PROVISION_DIR="${SS_DIR}/provision"
export SS_INC="${PROVISION_DIR}/common/inc"
export SS_LIB="${PROVISION_DIR}/common/lib"
export SS_GEN="/etc/ss"
export BS_VARS="${SS_GEN}/0-bs-vars.sh"

outline_level=3

# NOTE this provides a different msg() implementation than lib-ss.sh
function msg()
{
    local funcname=$(interesting_frame 2)
    echo "${funcname}:" "${@}" 1>&2
}

function update_mlocate()
{
    ensure_installed mlocate && command_is_available updatedb && updatedb
}

function install_utils()
{
    # Some stuff to make working in the vm easier
    unless_installed mlocate update_mlocate
    unless_installed bind-utils yum_install bind-utils
}

# Requires an array variable 'hosts' to be set
function add_hosts()
{
    append_lines /etc/hosts append "${hosts[@]}"
}

function add_nameserver()
{
    # Delete networkmanager filth from the file first.
    sed -i -e '/NetworkManager/ d' /etc/resolv.conf 
    [[ -n "${NAMESERVER}" ]] &&  append_lines /etc/resolv.conf append "nameserver ${NAMESERVER}"
}


function display_well_known_hosts()
{
    display_array 15 29 "${hosts[@]}"
}

function display_repos()
{
    local replaced=()
    local r
    for r in "${repos[@]}"
    do 
        r="${r//\$releasever/$releasever}"
        r="${r//\$basearch/$basearch}"
        replaced+=("${r}")
    done 
    display_array 8 60 "${r[@]}"
}

function get_kickstart_commandline_settings()
{
    local pattern="${1:-.}"
    local lines=$(cat /proc/cmdline | tr '\0 ' '\n' | egrep -i '^ss[.]' | cut -c4- | egrep "${pattern}" | sed -r -e "s/^([^=]*)=(.*)\$/\1='\2'/")
    local -a ss_vars
    readarray -t ss_vars <<< "${lines}"
    echo_return "${ss_vars[@]}"
}

function process_commandline_vars()
{
    local item
    local -a vars=()
    local -a hosts=()
    local -a repos=()
    local -a netdevs=()
    local nexus=""
    local -a pairs=()

    if [[ "${1}" == "kernel" ]]
    then
        local lines=$(tr '\0 ' '\n' < /proc/cmdline | egrep -i '^ss[.]' | cut -c4- | egrep .)
        readarray -t pairs <<< "${lines}"
    elif [[ "${1:0:1}" == "/" && -f "${1}" ]]
    then
        readarray -t pairs < "${1}"
        shift
    elif [[ "${1:0:1}" == "/" ]]
    then 
        err "File ${1} was not found!"
    else
        pairs=("${@}")
    fi

    local alphanumeric='^[A-Za-z][A-Za-z0-9]*$'
    for item in "${pairs[@]}"
    do
        case "${item^^}" in
            ADD_HOST=*)
                local host_entry="${item#*=}"
                host_entry="${host_entry//,/ }"
                hosts+=("${host_entry}")
                ;;
            ADD_REPO=*)
                local repo_entry="${item#*=}"
                repo_entry="${repo_entry//,/ }"
                repos+=("${repo_entry}")
                ;;
            ADD_NETDEV=*)
                local spec="${item#*=}"
                netdevs+=("${spec}")
                ;;
            *=*)
                left="${item%%=*}"
                left="${left^^}"  # uppercase it
                right="${item#*=}"
                # Make sure the var is stored with uppercase
                vars+=("${left}='${right}'")
                [[ "${left}" == "NEXUS" ]] && nexus="${right}"
                ;;
            "")
                # This will be the case if no args at all were specified.
                continue
                ;;
            *)
                if [[ "${item}" =~ ${alphanumeric} ]]
                then
                    vars+=("${item^^}=1")
                else
                    notice "Ignore commandline var '${item}'"
                fi
                ;;
        esac
    done

    # Substitute the NEXUS var in any repos
    # NOTE this is no longer done because the yum var NEXUS is set up in /etc/yum/vars
    #local repos_expanded=()
    #for item in "${repos[@]}"
    #do
    #    local nexus_var_regex='^(.*)[$]NEXUS(.*)$'
    #    if [[ "${item}" =~ ${nexus_var_regex} ]]
    #    then 
    #        item="${BASH_REMATCH[1]}${nexus}${BASH_REMATCH[2]}"
    #    fi
    #    repos_expanded+=("${item}")
    #done

    for item in "${vars[@]}"
    do
        echo_return "${item}"
        eval "${item}"
    done

    # Add any hosts we've been informed about
    dump_array "hosts"   "quoted" "${hosts[@]}"
    dump_array "netdevs" "quoted" "${netdevs[@]}"
    dump_array "repos"   "quoted" "${repos_expanded[@]}"

}

function generate_bootstrap_vars()
{
    echo_return "set -e"

    # Load operating system name / information
    if [[ -f /etc/os-release ]]
    then
        . /etc/os-release
        export releasever="${VERSION_ID}"
        echo_return "releasever=${releasever}"

        export basearch=$(uname -i)
        echo_return "basearch=${basearch}"

        export relname="${ID,,}-${VERSION_ID}"
        echo_return "relname=${relname}"

        export OS_NAME="${ID,,}"
        echo_return "OS_NAME=${OS_NAME}"
    else
        export basearch=$(uname -i)
        echo_return "basearch=${basearch}"
    fi

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

    export HARDWARE=$(determine_vm_or_baremental)
    echo_return "HARDWARE=${HARDWARE}"
  
    export PROVISION_TYPE=$(determine_vagrant_or_kickstart)
    echo_return "PROVISION_TYPE=${PROVISION_TYPE}"
  
    if [[ -f "${SS_INC}/fallback-passwords.sh" ]]
    then 
        . "${SS_INC}/fallback-passwords.sh"
        cat "${SS_INC}/fallback-passwords.sh"
    fi

    echo_return "set +e"
}
 
function configure_wireless()
{
    local devname="${1}"
    local devinfo="${2}"
    local part="" pw="" ssid=""

    for part in ${devinfo//,/ }
    do 
        case "${part}" in 
            psk=*)
                psk="${part#psk=}"
                ;;
            pw=*)
                pw="${part#pw=}"
                ;;
            ssid=*)
                ssid="${part#ssid=}"
                ;;
        esac 
    done

    local status=$(nmcli device status | egrep "^${devname}[[:space:]]")
    if ! [[ "${status}" =~ wifi ]]
    then 
        err "Device ${devname} is not a wireless device (or nmcli not available)!"
        return 1
    fi
    if ! nmcli radio | egrep -i 'enabled.*enabled.*enabled.*enabled'
    then
        err "The wireless radio is at least partially disabled!"
        return 1
    fi

    # systemctl | egrep hostapd 
    # This is incomplete because it seems that hostapd cannot configure
    # the emulated device if NetworkManager already is using it.
    # However the whole point of simulating the device was to test that
    # the NetworkManager setup of a wireless device was working, without
    # any real hardware. So that makes it pointless.
    if is_wireless_simulated
    then 
        if ! systemctl | grep hostapd
        then 
            nmcli radio wifi off
            rfkill unblock wlan
            ip link add addr 10.0.0.2/24
            ip link set wlan0 up

            if ! systemctl start hostapd 
            then 
                err "Failed starting hostapd for wireless simulation"
                return 1
            fi
            sleep 5
        fi 
    fi 

    nmcli device wifi rescan
    sleep 5

    nmcli device wifi list
    if [[ -n "${ssid}" && -n "${pw}" ]]
    then
        if ! nmcli device wifi connect "${ssid}" password "${pw}"
        then 
            err "wifi connection Failed"
        fi
    fi
}


function simulate_wireless()
{ 
    local base_dir="${1}"
    echo_data options mac80211_hwsim radios=1 >> "${base_dir}"/etc/modprobe.d/99-wireless-emulation.conf
    echo_data "mac80211_hwsim" > /etc/modules-load.d/99-wireless-emulation.conf
    if [[ -z "${ANA_INSTALL_PATH}" ]]
    then
        yum_install hostapd

        cat > /etc/hostapd/hostapd.conf <<-EOF
			interface=wlan0
			ssid=TEST
			hw_mode=g
			wpa=2
			wpa_passphrase=TESTTEST
			wpa_key_mgmt=WPA-PSK WPA-EAP WPA-PSK-SHA256 WPA-EAP-SHA256
		EOF

        systemctl status hostapd || systemctl restart hostapd
    fi
}

function bootstrap_repos()
{
    msg "Bootstrap repos."

    import_gpgkeys

    [[ -n "${DISABLE_REPOS}" ]] && disable_repos ${DISABLE_REPOS//,/ }

    if [[ -n "${BOOTSTRAP_REPOS}" ]]
    then

        local f
        for f in ${BOOTSTRAP_REPOS//,/ }
        do
            local found=""
            for try in "${SS_DIR}/provision/${PROVISION_TYPE}/cfg/${f}" "${SS_DIR}/provision/common/inc/${f}"
            do
                if [[ -f "${try}" ]]
                then
                    found="${try}"
                    break
                fi
            done
            if [[ -n "${found}" ]]
            then
                msg "Installing ${found} which provides the following repos:"
                egrep '^\[' "${found}" | tr '[]' ':' | cut -d: -f2 | indent
                local name="${found##*/}"
                msg "Substituting '${NEXUS}' for \$NEXUS in ${found}"
                sed -e "s%\$NEXUS%$NEXUS%" < "${found}" > /etc/yum.repos.d/"${name}"
            else 
                err "Bootstrap repos file ${f} was not found!"
            fi 
        done
        msg "Refreshing yum repo cache - this may take a while."
        yum makecache
    else
        msg "No BOOTSTRAP_REPOS defined. Preconfigured OS repos will be used."
    fi
}

function provisioning_display_build_configuration()
{
    display_build_configuration
    {
        display_bar "######"
        echo "                              Repositories:" 1>&2
        display_bar "######"
        display_repos 
        display_bar "######"
        echo "                            Well known hosts:" 1>&2
        display_bar "######"
        display_well_known_hosts
        display_bar "######"
    } | while IFS='' read line ; do bmsg "${line}" ; done
}

function create_ssh_key_file()
{
    local keyfile="${1}"

    if command_is_available ssh-keygen 
    then 
        [[ ! -f "${keyfile}" ]] && ssh-keygen -t rsa -N '' -q -f "${keyfile}"
    else
        msg "No ssh client tools available in this environment (cannot create ${keyfile})"
        : TODO - perhaps install ssh client here ;
    fi 
}

export SS_LOADED_COMMON_LIB=1
