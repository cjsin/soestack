#!/bin/bash

# Set SS_DIR if not set already, using the path of this script
SS_DIR="${SS_DIR:-${BASH_SOURCE[0]%/provision/*}}"

export PROVISION_DIR="${SS_DIR}/provision"
export SS_INC="${PROVISION_DIR}/common/inc"
export SS_LIB="${PROVISION_DIR}/common/lib"
export SS_GEN="/etc/ss"
export BS_VARS="${SS_GEN}/0-bs-vars.sh"
outline_level=3

#BEGIN_COLOR=$'\u001b['
COLOR_BEGIN=$'\e['
COLOR_RED=31m
COLOR_GREEN=32m
COLOR_GRAY=30m
COLOR_BLUE=34m
COLOR_YELLOW=33m
COLOR_CYAN=36m
COLOR_PURPLE=35m
COLOR_WHITE=37m
COLOR_ERR=${COLOR_RED}
COLOR_WARN=${COLOR_YELLOW}
COLOR_NOTICE=${COLOR_BLUE}
COLOR_INFO=${COLOR_GRAY}
#COLOR_RESET=$'\u001b[0m'
COLOR_RESET=$'\e[0m'

function msg()
{
    local funcname=$(interesting_frame 2)
    echo "${funcname}:" "${@}" 1>&2
}

function bmsg()
{
    echo "${*}"
}

function interesting_frame()
{
    local frame="${1:-2}"
    local nframes="${#FUNCNAME[@]}"
    local funcname=""
    local skip_func='^(|colored|spam|notice|info|err|warn|die|echo_stage)$'
    while [[ "${frame}" -lt "${nframes}" ]]
    do
        funcname="${FUNCNAME[${frame}]}"
        ((frame++))
        if [[ ! "${funcname}" =~ ${skip_func} ]]
        then
            echo "${funcname}"
            return 0
        fi
    done
    if [[ -n "${BASH_SOURCE[1]}" ]]
    then 
        echo "${BASH_SOURCE[1]}"
    fi
}

function colored()
{
    local color="${1}"
    local text="${2}"
    shift 2
    local funcname=$(interesting_frame 2)
    echo "${COLOR_BEGIN}${color}${funcname}:${text}${COLOR_RESET}" "${@}" 1>&2
}

function err()
{
    colored ${COLOR_RED} ERROR: "${@}"
}

function notice()
{
    colored ${COLOR_NOTICE} NOTICE: "${@}"
}

function warn()
{
    colored ${COLOR_WARN} WARN: "${@}"
}

function info()
{
    colored ${COLOR_INFO} INFO: "${@}"
}

# Spam a message to standard output as well as various TTYs, to
# make sure that it can be seen even when output is redirected to a log file.
# WARNING: This will execute the parameters twice so should be used just
# with functions that produce echoe'd output.
function spam()
{
    "${@}" 
    "${@}" > /dev/tty1 2>&1
    "${@}" > /dev/tty2 2>&1
    "${@}" > /dev/tty3 2>&1
}

function echo_stage()
{
    local level="${1:-0}"
    shift
    local spaces=$(printf " %.0s" {0..${level}})
    if [[ "${level}" -ge "${outline_level}" ]]
    then 
        echo "${spaces}########################################" 1>&2
        echo "${spaces}# ${*}" 1>&2
        echo "${spaces}########################################" 1>&2
    fi
}

# Echo some text as an explicit return value within the calling function
function echo_return()
{
    echo "${@}"
}

# Echo some text, but explicitly with it being as returned data from a function
# or being prodocued / generated into a file or other artifact
function echo_data()
{
    echo "${@}"
}

function echo_progress()
{
    echo "$(date) ${*}" 1>&2
}

auto_level="${auto_level:-1}"
export auto_level

function echo_start()
{
    spam echo_stage "${auto_level}" "$(date) Start ${FUNCNAME[1]} ${*}"
    ((auto_level++))
}

function echo_done()
{
    ((auto_level--))
    spam echo_stage "${auto_level}" "$(date) Done ${FUNCNAME[1]} ${*}"
}

function die()
{
    msg "FATAL:" "${*}"
    exit 1
}

function indent()
{
    sed 's/^/    /'
}

function indented()
{
    local heading="${1}"
    shift
    echo_return "${heading}:"
    "${@}" | indent
}

# Override cp with a function so that functions in this library are called
# from ain interactive shell, it does not use the 'cp -i' alias.
function cp()
{
    /bin/cp "${@}"
}

# Override cp with a function so that functions in this library are called
# from ain interactive shell, it does not use the 'mv -i' alias.
function mv()
{
    /bin/mv "${@}"
}

function yum_install()
{
    yum -y install "${@}"
}

function is_installed()
{
    rpm -q "${1}" > /dev/null 2> /dev/null
}

function is_docker()
{
    # The status of this routine is cached and exported in CONTAINER_DETECTED
    if [[ -z "${CONTAINER_DETECTED}" ]]
    then 
        # This works for docker
        if egrep -q '/docker|/lxc' /proc/1/cgroup
        then 
            msg "Detected running within docker or lxc container"
            export CONTAINER_DETECTED=1
        elif [[ -n "${PROVISION_TYPE}" && "${PROVISION_TYPE}" =~ docker|vagrant ]]
        then
            export CONTAINER_DETECTED=1
        else
            export CONTAINER_DETECTED=0
        fi
    fi
    (( CONTAINER_DETECTED ))
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

function unless_installed()
{
    local what="${1}"
    shift
    is_installed "${what}" || "${@}" 2>&1 | indent
}

function ensure_installed()
{
    msg "${*}"
    local p
    for p in "${@}"
    do
        unless_installed "${p}" yum_install "${p}"
    done 
}

# Append lines to a file
# arg 1: outfile - a filename
# arg 2: mode - 'create' (create or overwrite file) or other (will append)
function append_lines()
{
    local outfile="${1}"
    local mode="${2}"
    shift 2
    if [[ "${mode}" == "create" ]]
    then
        > "${outfile}"
    fi
    local n
    for n in "${@}"
    do
        grep -q "${n}" < "${outfile}" || echo_data "${n}" 
    done >> "${outfile}"
}

# Requires an array variable 'hosts' to be set
function add_hosts()
{
    append_lines /etc/hosts               append "${hosts[@]}"
}

function add_nameserver()
{
    # Delete networkmanager filth from the file first.
    sed -i -e '/NetworkManager/ d' /etc/resolv.conf 
    [[ -n "${NAMESERVER}" ]] &&  append_lines /etc/resolv.conf append "nameserver ${NAMESERVER}"
}

function display_build_configuration()
{
    {
        #display_bar "######" 
        #echo "                     Static build configuration:"
        #cat "${STATICVARS}" | egrep '^[a-zA-Z].*=' | egrep -v '=[(]' | sed -r 's/^([^=]*)=/\1 /' | indent_vars
        #display_bar "######" 

        echo 1>&2
        echo "                       Dynamic build configuration:" 1>&2
        
        display_bar "######"

        local var_names=( $( egrep --no-filename '^[a-zA-Z].*=($|[^(])' "${SS_GEN}"/*-vars.sh  | cut -d= -f1 | sort | uniq ) )

        local n v
        for n in "${var_names[@]}"
        do 
            v="${!n}"
            [[ -n "${v}" ]] && echo "${n} ${v}"
        done | indent_vars

        if ! (( ${#var_names[@]} ))
        then 
            echo "No dynamic vars generated in ${f} - generation may have failed." 1>&2
        fi

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

function dump_array()
{
    local name="${1}"
    local quoted="${2:-}"
    shift 2
    echo_return "${name}=("
    local item
    local qt=""
    case "${quoted}" in
        single|sq|quoted|single-quoted) qt="'";;
        double|dq|double-quoted) qt='"';;
        *) qt="${quoted}";;
    esac 
    for item in "${@}" 
    do
        echo_return "    ${qt}${item}${qt}"
    done
    echo_return ")"
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

function indent_vars()
{
    local line
    local token0 remainder
    #sed -e 's/^/\t/' | tr '=' '\t'
    while read line 
    do 
        read token0 remainder <<< "${line}"
        printf " %-20s  %s\n" "${token0}" "${remainder}" # | tr ' ' '_'
    done
}

function display_bar()
{
    echo_return " $(printf "######%.0s" {1..13})"
}

function display_array()
{
    local col1_width="${1}"
    local col2_width="${2}"
    shift 2
    local line a b x remainder len
    local lines=()
    local longest=0
    for x in "${@}"
    do
        line="${x}"
        read a b remainder <<< "${line}"
        line=$(printf " %-${col1_width}s  %-${col2_width}s %s" "${a}" "${b}" "${remainder}")
        lines+=("${line}")
        len="${#line}"
        [[ "${len}" -gt "${longest}" ]] && longest="${len}"
    done

    local indent_len=$(( (78 - longest) / 2))

    if [[ "${indent_len}" -lt 0 ]]
    then 
        indent_len=0
    fi 

    for line in "${lines[@]}"
    do
        printf "%${indent_len}s%s\n" "" "${line}"
    done
}

function determine_network_devices()
{
    # TODO: update this to cater for vagrant situation in which
    # there are two network devices
    ip a | egrep -A2 ': (eno|enp|eth|wlan|wlo)' | egrep -v link/ether | egrep -B1 inet' ' | egrep '^[0-9]' | tr ':' ' '| awk '{print $2}'
}

function determine_network_device()
{
    local devs=( $(determine_network_devices) )
    local d
    for d in "${devs[@]}"
    do 
        if [[ -n "${SKIP_NETDEV}" && "${d}" == "${SKIP_NETDEV}" ]]
        then
            continue
        fi 
        echo_return "${d}"
        return 0
    done
    # Fall back to eth0
    echo_return "eth0"
    return 1
}

function determine_current_ipaddr_prefix()
{
    # TODO: update this to cater for vagrant situation in which
    # there are two network devices
    local dev="${NETDEV:-eno|enp|eth|wlan|wlo}"
    ip a | egrep -A2 ": (${dev})" | egrep -A1 link/ether|grep inet' '| awk '{print $2}' | head -n1 
}

function determine_vm_or_baremental()
{
    if [[ -e /dev/vda ]]
    then
        echo_return "vm"
    elif [[ -e /dev/sda ]]
    then
        echo_return "baremetal"
    else
        echo_return "unknown"
    fi
}

function determine_vagrant_or_kickstart()
{
    if grep -q vagrant /etc/passwd
    then
        echo_return "vagrant"
    else
        echo_return "kickstart"
    fi
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

function load_bootstrap_vars()
{
    if [[ ! -f "${BS_VARS}" ]]
    then
        mkdir -p "${SS_GEN}"
        generate_bootstrap_vars > "${BS_VARS}"
    fi

    . "${BS_VARS}"
}

function load_dyn_vars()
{
    local f
    set -a
    for f in "${SS_GEN}"/*-vars.sh 
    do 
        . "${f}"
    done
    set +a
}

function is_standalone()
{
    [[ -n "${STANDALONE}" ]] && (( STANDALONE ))
}

function is_verbose()
{
    [[ -n "${VERBOSE}" ]] && (( VERBOSE ))
}

function is_skip_confirmation()
{
    [[ -n "${SKIP_CONFIRMATION}" ]] && (( SKIP_CONFIRMATION ))
}

function is_interactive()
{
    [[ -n "${INTERACTIVE}" ]] && (( INTERACTIVE ))
}

function is_wait()
{
    [[ -n "${WAIT}" ]] && (( WAIT ))
}

function is_inspect()
{
    [[ -n "${INSPECT}" ]] && (( INSPECT ))
}

function is_wireless_simulated()
{
    [[ -n "${WLAN_SIM}" ]] && (( WLAN_SIM ))
}

function is_development()
{
    if [[ -n "${DEVELOPMENT}" ]] && (( DEVELOPMENT ))
    then
        notice "Development mode features being enabled."
        return 0
    else
        return 1
    fi
}


function array_to_json()
{
    local i="" s=""
    for i in "${@}"
    do 
        s+="\"${i}\", "
    done
    echo_return "[ ${s%, } ]" # NOTE the final comma is stripped off
}

function pairs_to_json()
{
    local k="" v="" s=""
    while (( $# ))
    do
        k="${1}"
        v="${2}"
        shift 2
        s+="\"${k}\": ${v}, "
    done
    echo_return "{ ${s%, } }" # NOTE the final comma is stripped off
}

function interactive_prompt()
{
    local prompt="${*}"
    local answer
    
    while [ 1 ] 
    do 
        spam notice "${prompt}" 
        spam notice "Hit enter to continue, skip to skip this step, shell for a shell: "
        read answer
        case "${answer,,}" in 
            skip)
                spam notice "OK - skipping this step"
                return 1
                ;;
            shell)
                spam notice "OK - dropping into a shell. Use 'exit 1' to skip the step, and 'exit 0' to continue."
                spam_notice "Shell will be on TTY1."
                bash -i < /dev/tty1 > /dev/tty1 2> /dev/tty1
                ;;
            "")
                spam notice "OK - continuing with [${prompt}]"
                return 0
                ;;
            *)
                err "Invalid answer."
                ;;
        esac 
    done
}

function step()
{
    if is_interactive
    then
        spam notice "Interactive prompt enabled - enter response on TTY1."
        if ! interactive_prompt "STEP: ${*}"
        then
            # The user chose to skip
            return 0
        fi 
    elif is_verbose
    then
        msg "${*}"
    fi

    "${@}"
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

function command_is_available()
{
    command -v "${1}" > /dev/null 2> /dev/null
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

export SSL_LOADED_COMMON_LIB=1
