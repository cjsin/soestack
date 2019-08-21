#!/bin/bash

# NOTE that these vars at the top are set for the provisioning
# scripts, but the rest of the script below that, should be 
# kept in sync with the (almost) identical script within soestack/salt/state/scripts/lib-ss.sh
# Set SS_DIR if not set already, using the path of this script
SS_DIR="${SS_DIR:-${BASH_SOURCE[0]%/provision/*}}"
export PROVISION_DIR="${SS_DIR}/provision"
export SS_INC="${PROVISION_DIR}/common/inc"
export SS_LIB="${PROVISION_DIR}/common/lib"
outline_level=3

# NOTE that these two files should be kept mostly identical below this point
#    provision/common/lib/lib-ss.sh
#    soestack/salt/state/scripts/lib-ss.sh

export SS_GEN="/etc/ss"
export BS_VARS="${SS_GEN}/0-bs-vars.sh"

#BEGIN_COLOR=$'\u001b['
COLOR_BEGIN=$'\e['
COLOR_RED="31m"
COLOR_GREEN="32m"
COLOR_GRAY="30m"
COLOR_BLUE="34m"
COLOR_YELLOW="33m"
COLOR_CYAN="36m"
COLOR_PURPLE="35m"
COLOR_WHITE="37m"
COLOR_ERR="${COLOR_RED}"
COLOR_WARN="${COLOR_YELLOW}"
COLOR_NOTICE="${COLOR_BLUE}"
COLOR_INFO="${COLOR_GRAY}"
#COLOR_RESET=$'\u001b[0m'
COLOR_RESET=$'\e[0m'

function msg()
{
    echo "${@}" 1>&2
}

function logmsg()
{
    echo "${*}" 1>&2
    /usr/bin/logger -p auth.notice "${0##*/}" "[${UID}:$$]" "${*}"
}

function bmsg()
{
    echo "${*}"
}

function interesting_frame()
{
    local frame="${1:-2}"
    local nframes=$(array_length "${FUNCNAME[@]}")
    local funcname=""
    local skip_func='^(|colored|spam|notice|info|err|warn|die|echo_stage|functrace)$'
    local indent=""
    while [[ "${frame}" -lt "${nframes}" ]]
    do
        funcname="${FUNCNAME[${frame}]}"
        ((frame++))
        if [[ ! "${funcname}" =~ ${skip_func} ]]
        then
            echo "${indent}${funcname}"
            return 0
        fi
        indent+="    "
    done
    if [[ -n "${BASH_SOURCE[1]}" ]]
    then 
        echo "${indent}${BASH_SOURCE[1]}"
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

function create_script()
{
    local bash_header='#!'"/bin/bash"
    create_file "${1}" "${2:-0700}" "${3:-${bash_header}}"
}

function create_file()
{
    local file_path="${1}"
    local file_mode="${2:-0600}"
    if [[ "$#" -gt 2 ]]
    then
        local header="${3:-}"
        # Create the file, with the specified header
        echo "${header}" > "${file_path}"
    else
        # Create the file, empty
        touch "${file_path}"
    fi
    # Write stdin to the file
    cat >> "${file_path}"
    chmod "${file_mode}" "${file_path}"
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

function display_build_configuration()
{
    {
        #display_bar "######" 
        #echo "                     Static build configuration:"
        #cat "${STATICVARS}" | egrep '^[a-zA-Z].*=' | egrep -v '=[(]' | sed -r 's/^([^=]*)=/\1 /' | indent_vars
        #display_bar "######" 

        local underscores="_____________________________"
        echo "" #display_bar "      "
        echo " ${underscores}Dynamic build config${underscores}"
        
        #display_bar "######"

        local var_names=( $( egrep --no-filename '^[a-zA-Z].*=($|[^(])' "${SS_GEN}"/*-vars.sh  | cut -d= -f1 | sort | uniq ) )

        local -a vals=()
        local screen_height=25
        local reserve_for_bottom=15
        local rows=$((screen_height-reserve_for_bottom))
        local screen_width=80
        local half_width=$(( (screen_width - 2) / 2 ))

        local n v
        local indent=""
        local min_left="0"
        local min_right=0

        local left=()
        local right=()
        local nitems="${#var_names[@]}"
        local nrows=$(( ( nitems + 1 ) / 2 ))

        local itemnum=0
        for n in "${var_names[@]}"
        do
            if [[ "${itemnum}" -lt ${nrows} ]]
            then 
                left+=("${n}")
                [[ "${#n}" -gt "${min_left}" ]] && min_left="${#n}"
            else 
                right+=("${n}")
                [[ "${#n}" -gt "${min_right}" ]] && min_right="${#n}"
            fi
            ((itemnum++))
        done

        #printf "%.0s1234567890" {1..8}
        #echo 
        #vals+=("left=$((min_left))")
        #vals+=("right=$((min_right))")
        itemnum=0
        indlen="${min_left}"
        [[ "${min_right}" -gt "${indlen}" ]] && indlen="${min_right}"
        ((indlen++))
        for n in "${var_names[@]}"
        do 
            v="${!n}"
            local n_len="${#n}"
            local indent_space=$(printf "%-${indlen}s" " ")
            local indent=$(printf "%-${indlen}s" " ")
            local vstr="${v}"
            [[ -z "${v}" ]] && vstr="(empty)"

            local str=$(printf "%${indlen}s%s" "${n} " "${vstr}")
            if [[ "${#str}" -le "${half_width}" ]]
            then 
                vals+=("${str}")
            else
                # The first line can take the full width 
                # without losing some space to the indent
                local chunklen=$((half_width))
                vals+=("${str:0:chunklen-1}+")
                str="${str:chunklen-1}"
                ((chunklen-=indlen))
                while [[ "${#str}" -gt "${chunklen}" ]]
                do
                    vals+=("${indent}${str:0:chunklen-1}+")
                    str="${str:chunklen-1}"
                done
                vals+=("${indent}${str}")
            fi
            ((itemnum++))
        done 
        columnify " %-39s %-39s\n" "${vals[@]}"

        local var_count=$(array_length "${var_names[@]}")
        if ! (( var_count ))
        then 
            echo "No dynamic vars generated in ${f} - generation may have failed." 1>&2
        fi
    } | while IFS='' read line ; do bmsg "${line}" ; done
}

# The install environment does not have 'column'
# So this simply formats X lines into half that many rows,
# each with two columns formatted by the specified formatter
function columnify()
{
    local formatter="${1:- %-39s %-39s\n}"
    shift
    local ncols=2
    local l r
    local nrows=$(( ( $# + 1 ) / 2 ))
    local left=() right=()
    local bar="${bar}"
    #left+=("123456789012345678901234567890123456789")
    while [[ "${#left[@]}" -lt ${nrows} ]]
    do
        left+=("${1}")
        shift
    done 

    
    #right+=("123456789012345678901234567890123456789")
    right+=("${@}")
    r=0
    set -- "${right[@]}"
    while (( $# )) 
    do
        local right="${1}"
        shift 
        local left="${left[${r}]}"
        printf "${formatter}" "${left}" "${right}"
        ((r++))
    done
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
    local filler="${1:-######}"
    echo_return " $(printf "${filler}%.0s" {1..13})"
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
        len=$(string_length "${line}")
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
    if [[ -d /vagrant ]] && grep -q vagrant /etc/passwd 
    then
        echo_return "vagrant"
    else
        echo_return "kickstart"
    fi
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

function is_skip_confirm()
{
    [[ -n "${SKIP_CONFIRM}" ]] && (( SKIP_CONFIRM ))
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

function dir_exists()
{
    [[ -d "${1}" ]]
}

function file_exists()
{
    [[ -f "${1}" ]]
}

function exists()
{
    [[ -e "${1}" ]]
}

function is_empty()
{
    [[ -e "${1}" && -s "${1}" ]]
}

function is_empty_or_missing()
{
    [[ ! -e "${1}" ]] || [[ -s "${1}" ]]
}

function is_not_empty()
{
    [[ -e "${1}" && ! -s "${1}" ]]
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

function command_is_available()
{
    command -v "${1}" > /dev/null 2> /dev/null
}

function install_systemd_service_patcher()
{
    local service_name="${1}"
    local patcher="${2}"
    local dropins="/etc/systemd/system/${service_name}.service.d"
    mkdir -p "${dropins}"

    create_file "${dropins}/patches.conf" '0644' <<-EOF
		[Service]
		ExecStartPre=${patcher}
	EOF
}

function best_hostname()
{
    local h
    for h in "$(hostname -s)" "$(hostname -f)"
    do 
        if egrep -q "[[:space:]]${h}([[:space:]]|\$)" /etc/hosts
        then 
            echo_return "${h}"
            return 0
        fi
    done
    echo_return "$(hostname -f)"
}

function initialise_rng()
{
    local rngdev="/dev/hwrandom"
    [[ -e "${rngdev}" ]] || rngdev="/dev/urandom"
    rngd -r "${rngdev}"
}

function require_docker()
{
    if ! command_is_available docker
    then
        err "Docker is not available - perhaps it is not installed"
        return 1
    fi
}

function yum_vars()
{
    if command_is_available dnf
    then
        python -c 'import dnf, pprint; db = dnf.dnf.Base(); pprint.pprint(db.conf.substitutions,width=1)'
    else
        python -c 'import yum, pprint; yb = yum.YumBase(); pprint.pprint(yb.conf.yumvar, width=1)'
    fi
}

# NOTE this function uses a subshell () not a block {} so that
# the working directory is not changed in the calling routine.
# And also so that the 'set -e' can be used to bail out on any
# error.
function prepare_gpg_keystore()
(
    #set -vx
    local name="${1}"
    local keystore="${2}"
    local email="${3}"
    local priv_savedir="${4:-$2}"
    local pub_savedir="${5:-$2}"
    local scripts="${6:-$2}"
    echo "name=$name,  keystore=$keystore, email=$email, priv_savedir=$priv_savedir, pub_savedir=$5, scripts=$scripts"
    local keyconfig_file="${keystore}/keyconfig"
    local pubkey="${keystore}/soestack-pub.asc"
    local pub_binfile="${keystore}/soestack-pub.gpg"
    local priv_ascfile="${priv_savedir}/soestack-priv.asc"
    local priv_binfile="${priv_savedir}/soestack-priv.gpg"
    
    ensure_installed gnupg2 rng-tools
    msg "Initialising random seed data"

    initialise_rng

    if [[ -f "${keystore}/secring.gpg" ]]
    then
        err "GPG keys for ${name} appear to have already been generated - refusing to overwrite them"
        return
    fi

    if [[ -z "${email}" ]]
    then
        err "Cannot generate GPG keys for ${name} private data"
        err "without an email specified!"
        return
    fi

    mkdir -p "${keystore}"
    chmod 0700 "${keystore}"

    if ! cd "${keystore}"
    then 
        err "Could not enter/create '${keystore}'"
        return
    fi

    set -e
    msg "Generating gpg keys for ${name}"
    create_file "${keyconfig_file}" '0600' <<-EOF
		%echo Generating a basic OpenPGP key
		Key-Type: default
		#Key-Length: default
		Subkey-Type: default
		#Subkey-Length: 2048
		Name-Real: SoeStack ${name}
		Name-Comment: SoeStack GPG key for ${name}
		Name-Email: ${email}
		Expire-Date: 0
		# NOTE this option will stop working for gnupg 2.1 and later
		%no-ask-passphrase
		%no-protection
		#%pubring pubring.kbx
		#%secring trustdb.gpg
		%commit
		%echo done
	EOF

    if [[ ! -s "${keyconfig_file}" ]]
    then
        err "Generated keyconfig file was empty!"
        rm -f "${keyconfig_file}"
        return 1
    fi

    if ! gpg2 --verbose --homedir "${keystore}" --batch  --gen-key "${keyconfig_file}" < /dev/null
    then
        err "Key generation failed!"
        return 1
    fi
    
    if ! gpg2 --verbose --homedir "${keystore}" --list-secret-keys
    then 
        err "No keys were found!"
        return 1
    fi

    if ! gpg2 --homedir "${keystore}" --armor --output "${pubkey}" --export
    then
        err "No public keys were exported!"
        return 1
    fi

    gpg2 --dearmor < "${pubkey}" > "${pub_binfile}"

    if [[ "${pub_savedir}" != "${keystore}" ]]
    then 
        msg "Copy public key ${pubkey} to ${pub_savedir}"
        mkdir -p "${pub_savedir}"
        chmod 0700 "${pub_savedir}"
        cp "${pubkey}" "${pub_binfile}" "${pub_savedir}"
        chmod go-r "${pub_savedir}/"
    fi

#     # Import the key for the root user configs, so that
#     # the root user can encrypt data with these keys
#     #gpg2 --import "${pubkey}"

    if ! gpg2 --homedir "${keystore}" --armor --output "${priv_ascfile}" --export-secret-keys 
    then
        err "No private keys were exported!"
        return 1
    fi

    chmod 700 "${priv_ascfile}"
    gpg2 --dearmor < "${priv_ascfile}" > "${priv_binfile}"

    if [[ "${priv_savedir}" != "${keystore}" ]]
    then
        mkdir -p "${priv_savedir}"
        chmod 0700 "${priv_savedir}"
        cp "${priv_ascfile}" "${priv_binfile}" "${priv_savedir}/"
    fi

    create_script "${scripts}/${name}-gpg-encrypt-ks" <<-EOF
			#!/bin/bash
			# Encrypt using the key store - allows for verifying signatures from imported trusted keys
			gpg --homedir "${keystore}" --armor --trust-model always --encrypt -r "${email}" "\${@}"
			EOF
    create_script "${scripts}/${name}-gpg-encrypt-bk" <<-EOF
			#!/bin/bash
			# Encrypt using only the key files
            gpg --import "${priv_binfile}" 
			gpg --keyring "${pub_binfile}" --armor --trust-model=always -r "${email}" --encrypt  "\${@}"
			EOF
    create_script "${scripts}/${name}-gpg-decrypt-ks" <<-EOF
			#!/bin/bash 
			# Encrypt using the key store - allows for verifying signatures from imported trusted keys
			gpg --homedir "${keystore}" --decrypt "\${@}"
			EOF
    create_script "${scripts}/${name}-gpg-decrypt-bk" <<-EOF
			#!/bin/bash 
			# Decrypt using only the key files
			#local f=$(mktemp)
			gpg --import "${priv_binfile}" 
			gpg --armor --trust-model=always --decrypt "\${@}"
			EOF
    create_script "${scripts}/${name}-gpg-test" <<-EOF
			#!/bin/bash 
			# Decrypt using the key store - allows for verifying signatures from imported trusted keys
			PATH="${scripts}:\${PATH}"
			echo test 1
			echo "successful gpg test on $(date)" | "${name}-gpg-encrypt-ks" | "${name}-gpg-decrypt-ks" 
			echo test 2
			echo "successful gpg test on $(date)" | "${name}-gpg-encrypt-bk" | "${name}-gpg-decrypt-bk" 
			EOF

    if ! "${scripts}/${name}-gpg-test"
    then
        err "Encrypt/Decrypt tests failed!"
        return 1
    fi
)

# This is intended to be run on the master
# This function creates private gpg keystores for minions.
#   - The keystore is then distributed to the minion.
#   - The public key for the new keystore is extracted so that the master
#     can send encrypted data to the minion.
#   - The keystore private files on the master can then be deleted
function prepare_node_keystore()
(
    local name="${1}"
    local base="/etc/salt/minion-gpg"
    local node_base="${base}/${name}"
    local archive="${node_base}.tgz"
    local base_pub="${node_base}" #/pub
    local base_key="${node_base}/key"
    local base_priv="${node_base}" #/priv
    local base_bin="${node_base}" #/bin
    #local -a tar_contents=( "soestack-priv.gpg" "soestack-priv.asc" "soestack-pub.asc" "soestack-pub.gpg")

    mkdir -p "${base}" "${node_base}" "${base_pub}" "${base_key}" "${base_priv}" "${base_bin}"
    chmod 0700 "${base}" "${node_base}" "${base_pub}" "${base_key}" "${base_priv}" "${base_bin}"

    load_dyn_vars

    node_email="${ADMIN_EMAIL//@/@${name}}"
    if ! prepare_gpg_keystore "${name}" "${base_key}" "${node_email}" "${base_priv}" "${base_pub}" "${base_bin}"
    then 
        echo "Keystore prep failed for ${name}!"
        return 1
    fi

    cp -f /etc/salt/gpgkeys/soestack.gpg "${base}/soestack-master.gpg"
    if ! tar -czf "${archive}" -C "${base}" "${name}/soestack-"* "${name}/${name}"-??crypt* "${base}/soestack-master.gpg"
    then
        err "Tarring sig for ${name} failed!"
        return 1
    fi

    chmod 0700 "${archive}" 
    
    if ! gpg2 --home /etc/salt/gpgkeys --armor --output "${archive}.sig" --sign "${archive}" 
    then
        err "Signing with our salt keys failed!"
        return 1
    fi

    chmod 0700 "${archive}.sig"
    
    cleanup_node_keystore "${name}"

    msg "Bundle for distribution...:"
    cat "${archive}.sig"

    msg "Copy to node"
    if scp "${archive}.sig" "${node}:/etc/salt/"
    then
        scp "/usr/local/bin/lib-ss.sh" "${node}:/usr/local/sbin/"
        msg "Unpack on node"
        ssh "${node}" ". /usr/local/bin/lib-ss.sh && import_signed_keystore"
    fi
)

function import_signed_keystore()
{
    # TODO - get through encrypted gpg pillar
    # TODO - import masters's key through gpg pillar

    set -e
    cd /etc/salt
    local name=$(hostname -s)
    tar xvf "${name}.tgz.sig"
    cd "/etc/salt/minion-gpg"
    gpg2 --home "/etc/salt/minion-gpg/${name}/key" --import "soestack-master.gpg"
    cd "/etc/salt/minion-gpg/${name}"
    gpg2 --home "/etc/salt/minion-gpg/${name}/key" --import soestack-priv.gpg
    gpg2 --home "/etc/salt/minion-gpg/${name}/key" --import soestack-pub.gpg
    set +e
}

function clean_node_keystore()
{
    local name="${1}"
    local base="/etc/salt/minion-gpg"
    local node_base="${base}/${name}"
    local base_pub="${node_base}" #/pub"
    local base_key="${node_base}/key"
    local base_priv="${node_base}" #/priv"
    local base_bin="${node_base}" #/bin"
    if [[ -n "${name}" && "${name}" =~ [0-9A-Za-z] && -d "${base}" && -d "${node_base}" ]]
    then
        if [[ -d "${base_key}" ]]
        then
            rm -f "${base_key}"/*
        fi
        if [[ -d "${base_priv}" ]]
        then
            rm -f "${base_priv}"/soestack-priv*
        fi 
    fi
}

function ask_password_twice()
{
    local name="${1}"
    local min_length="${2:-1}"
    local answer1
    local answer2
    local empty_password=0

    while [ 1 ]
    do 
        if [[ -z "${answer1}" ]] && ! (( empty_password ))
        then
            read -s -p "Enter the password for ${name} :" answer1 1>&2
            msg ""
            local answer_len=$(string_length "${answer1}")
            if [[ -n "${min_length}" && "${answer_len}" -lt "${min_length}" ]]
            then 
                err "Password for ${secret_name} was rejected as too short. Minimum length is ${min_length}."
                answer1=""
            elif [[ -z "${answer1}" && "${min_length}" == 0 ]]
            then
                empty_password=1
            fi
            continue
        fi 

        if [[ -z "${answer2}" ]] 
        then
            read -s -p "Re-enter the password for ${name} :" answer2 1>&2
            msg ""
            if (( empty_password )) && [[ -z "${answer2}" ]]
            then 
                break
            fi
            if [[ -n "${answer2}" ]]
            then
                [[ "${answer1}" == "${answer2}" ]] && break
                msg "Password mismatch. Please try again from the start."
                answer1=""
                answer2=""
                empty_password=0
            fi
        fi
    done 
    msg "Read password for ${name} successfully."
    echo_return "${answer1}"
}

# array_length and string_length are used, to avoid
# problems with jinja comments (in scripts deployed using salt)
# ie so that the raw/endraw jinja tags don't need to be scattered everywhere
function array_length()
{
    echo "${#}"
}

function string_length()
{
    echo "${#1}"
}

export SS_LOADED_SS_LIB=1
