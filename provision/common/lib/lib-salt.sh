#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function install_patcher()
{
    local service_name="${1}"
    local patcher="${2}"
    local dropins="/etc/systemd/system/${service_name}.d"
    mkdir -p "${dropins}"

    cat > "${dropins}/patches.conf" <<-EOF
		[Service]
		ExecStartPre=${patcher}
	EOF

}

function fix_saltstack_pillar_regression_53516()
{
    local patcher="/usr/local/sbin/patch-saltstack.sh"
    cat > "${patcher}" <<-'EOF'
		#!/bin/bash
		badfile_1='/usr/lib/python2.7/site-packages/salt/pillar/__init__.py'
		replacement_1='s/sub_sls in set.matched_pstates.:/sub_sls in matched_pstates:/'
		sed -i.bak -r -e "${replacement_1}" "${badfile_1}"
	EOF

    chmod +x "${patcher}"

    install_patcher salt-master "${patcher}"
    install_patcher salt-minion "${patcher}"
}

function saltstack_fixes()
{
    # This is really not important - it just reduces some 
    # salt log file error messages
    ensure_installed python-pip 
    preconfigure_pip
    pip list | egrep boto || pip install boto boto3
    fix_saltstack_pillar_regression_53516
}

function install_salt_minion()
{
    ensure_installed salt-minion
}

function install_salt_master()
{
    ensure_installed salt-master salt-minion salt salt-api salt-ssh
}

function restart_salt_services()
{
    systemctl stop salt-minion
    netstat | grep 4505
    systemctl stop salt-master
    netstat | grep 4505
    #systemctl restart salt-api 
    systemctl start salt-master
    systemctl start salt-minion 
}

function salt_test_ping()
{
    local h="${1}"
    msg "Test ping minion '${h}'"
    salt "${h}" test.ping 2>&1 | indent
}

function write_role_grains()
{
    [[ -f /etc/salt/grains ]] || touch /etc/salt/grains

    if ! grep -q "^roles:" /etc/salt/grains 
    then 
       if [[ -n "${ROLES}" ]]
       then
            {
                echo_data "roles:"
                local r
                for r in ${ROLES//,/ }
                do
                    echo_data "    - ${r}"
                done
            } >> /etc/salt/grains
        else
            echo_data "roles: []" >> /etc/salt/grains
        fi
    fi
}

function write_layer_grains()
{
    [[ -f /etc/salt/grains ]] || touch /etc/salt/grains
    
    if ! grep -q "^layers:" /etc/salt/grains 
    then 
        if [[ -n "${LAYERS}" ]]
        then
            {
                local item
                echo_data "layers:"
                if [[ "${LAYERS}" =~ : ]]
                then
                    for item in ${LAYERS//,/ }
                    do
                        echo_data "    ${item//:/: }"
                    done
                elif [[ "${LAYERS}" =~ , ]]
                then
                    for item in ${LAYERS//,/ }
                    do
                        echo_data "    - ${item}"
                    done
                else
                    echo_data "    - ${LAYERS}"
                fi
            } >> /etc/salt/grains
        else
            echo_data "layers: []" >> /etc/salt/grains
        fi
    fi
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

# NOTE this function uses a subshell () not a block {} so that
# the working directory is not changed in the calling routine.
# And also so that the 'set -e' can be used to bail out on any
# error.
function prepare_salt_gpg_keys()
(
    ensure_installed gnupg2 rng-tools
    msg "Initialising random seed data"

    # NOTE this is the default location that salt expects
    local keystore="/etc/salt/gpgkeys"
    local savedir="/var/log/build/salt-gpgkeys"
    local -a opts=( --homedir "${keystore}" )
    local keyconfig_file="${keystore}/keyconfig"
    local savefile="${savedir}/soestack.key"
    local pubkey="${keystore}/soestack.gpg"

    if [[ -d "${keystore}" ]]
    then
        err "Salt GPG keys appear to have already been generated - refusing to overwrite them"
        return
    fi

    mkdir -p "${keystore}" "${savedir}"
    chmod 0700 "${keystore}" "${savedir}"

    if [[ -z "${ADMIN_EMAIL}" ]]
    then
        err "Cannot generate GPG keys for saltstack private pillar data"
        err "without an ADMIN_EMAIL specified!"
        return
    fi

    if ! cd "${keystore}"
    then 
        err "Could not enter/create '${keystore}'"
        return
    fi

    set -e
    msg "Generating gpg keys for salt"
    set -vx
    cat <<-EOF > "${keyconfig_file}"
		%echo Generating a basic OpenPGP key
		Key-Type: default
		#Key-Length: default
		Subkey-Type: default
		#Subkey-Length: 2048
		Name-Real: SoeStack
		Name-Comment: SoeStack GPG key for Salt
		Name-Email: ${ADMIN_EMAIL}
		Expire-Date: 0
		# NOTE this option will stop working for gnupg 2.1 and later
		%no-ask-passphrase
		%no-protection
		#%pubring pubring.kbx
		#%secring trustdb.gpg
		%commit
		%echo done
	EOF

    gpg2 --verbose "${opts[@]}" --batch  --gen-key "${keyconfig_file}" < /dev/null
    gpg2 --verbose "${opts[@]}" --list-secret-keys

    gpg2 "${opts[@]}" --armor --output "${savefile}" --export-secret-keys 
    chmod 700 "${savefile}"

    gpg2 "${opts[@]}" --armor --output "${pubkey}" --export # "${ADMIN_EMAIL}"

    # Import the key for the root user configs, so that
    # the root user can encrypt data with these keys
    gpg2 --import "${pubkey}"

    local encrypt_script="/usr/local/sbin/salt-gpg-encrypt-stdin"
    cat <<-EOF > 
		#!/bin/bash 
		gpg --armor --batch --trust-model always --encrypt -r "${ADMIN_EMAIL}"
	EOF
    chmod u+rx "${encrypt_script}"


)

function configure_etc_salt()
{
    local minion_type="${1}" # client or master
    
    mkdir -p /etc/salt/minion.d
    mkdir -p /etc/salt/master.d

    # Copy some static configuration
    cp "${SS_INC}"/minion.d/* /etc/salt/minion.d/

    notice "Minion ID being used for salt registration is $(hostname -s)"
    echo_data "id: $(hostname -s)" > /etc/salt/minion.d/id.conf

    configure_ipa_integration
    
    if [[ "${minion_type}" == "master" ]]
    then
        export SALT_MASTER="$(best_hostname)"
        # Copy some static configuration
        cp "${SS_INC}"/master.d/* /etc/salt/master.d/

        salt_configure_for_development
    fi
    
    echo_data "master: ${SALT_MASTER:-salt}" > /etc/salt/minion.d/master.conf

    #write_role_grains # this will be done instead with grains.set in salt_state_provision
    write_layer_grains
}

function configure_ipa_integration()
{
    cat > /etc/salt/minion.d/saltipa.conf <<-EOF
		saltipa:
		    ticket_file:  '/var/cache/salt/master/salt.krb'
		    check_server: 'infra.${DOMAIN}'
	EOF
}

function start_salt_minion()
{
    systemctl enable salt-minion
    systemctl start salt-minion
}

function start_salt_master()
{
    systemctl enable salt-master salt-api
    systemctl restart salt-master
}

function wait_for_enrolment()
{
    while ! salt-call test.ping
    do 
        date
        msg "Waiting for enrolment"
        msg "Will try again in 30"
        sleep 30
        date
    done
}

function salt-step()
{
    local what="${1}"
    shift
    local -a args=("${@}")
    local name="misc"
    case "${what}" in
        grains.set) name="grains-${args[0]}";;
        state.sls)  name="state-${args[0]}";;
        state.apply) name="apply";;
        *) name="${what}-${args[0]}"; name="${name//./-}";;
    esac
    local logdir="/var/log/provision/salt"
    mkdir -p "${logdir}"
    local logfile="${logdir}/${name}.log"
    msg "Salt step ${what} ${args[*]} [log file ${logfile}]"
    local result=0
    salt-call "${what}" "${args[@]}" 2>&1 | tee -a "${logfile}"
    result=$?
    if (( ${result} ))
    then 
        err "FAILED: Salt step ${what} ${args[*]} [log file ${logfile}]"
    else
        msg "OK: Salt step ${what} ${args[*]} [log file ${logfile}]"
    fi
    return ${result}
}

function salt_state_provision()
{
    local preconfigured_roles="${1}"
    local fail_fast="${2:-0}"

    # Sync custom modules to the minion ('uuid','noop', and 'saltipa')
    salt-step saltutil.sync_all

    # Setting host grain to match short hostname
    # The 'host' grain is otherwise dynamically calculated and is affected by the installed hosts file,
    # especially when there are multiple interfaces on the machine, it can get the name from
    # the IP associated from the wrong network interface
    salt-step grains.set host "$(hostname -s)"

    if [[ "${PROVISION_TYPE}" == "vagrant" ]]
    then 
        salt-step grains.set vagrant True
    fi

    # NOTE the roles grains must be configured prior to running the 
    # full state apply, because the roles grains are utilised in selecting
    # which states are applied. 
    if [[ "${preconfigured_roles}" == "auto" ]]
    then 
        salt-step state.sls common.role-sets.auto
    elif [[ "${preconfigured_roles}" =~ ^role-set: ]]
    then 
        salt-step grains.set role-set "${preconfigured_roles#role-set:}" force=True
        salt-step state.sls common.role-sets.apply
    else
        # This works to set multiple roles with a simple string 'a,b,c'
        salt-step grains.set roles "[${preconfigured_roles}]" force=True
    fi

    local steps=(
        "state.sls provision.pre"
        "state.sls provision.main"
        "state.apply"
        "state.sls provision.post"
    )

    local step
    local problems=0
    for step in "${steps[@]}"
    do
        local result
        # The step variable is deliberately not quoted in the following line
        salt-step ${step}
        result=$?
        if (( result ))
        then
            ((problems++))
            err "Salt step ${step} failed"
            if (( fail_fast ))
            then
                err "Fail-fast mode enabled - aborting salt provisioning immediately."
                break
            fi
        fi
    done
    if (( problems ))
    then 
        err "Salt provisioning done - ${problems} problems occurred."
    else
        msg "Salt provisioning done - No problems occurred."
    fi
    return ${problems}
} 

function run_salt_state_provision()
{
    echo_start "Starting salt state provisioning."
    local logfile=/var/log/provision/salt-state-provision.log
    msg "Log file is ${logfile}"
    salt_state_provision "${*}" >> "${logfile}" 2>&1
    echo_done "Completed salt state provisioning."
}

function provision_minion_client()
{
    if ! salt_minion_autoenrol
    then 
        err "Automatic enrolment failed!"
        err "It will need to be enroled manually on the master."
        # Continue below, it will wait in a loop
    fi

    #with_low_tcp_time_wait restart_salt_services

    start_salt_minion

    wait_for_enrolment 2>&1 | indent
}

function provision_minion_master()
{
    #with_low_tcp_time_wait restart_salt_services

    start_salt_minion

    salt_master_enrol_self

    wait_for_enrolment
}

function provision_salt_minion()
{
    . "${SS_DIR}"/provision/common/lib/lib-client.sh

    echo "Installing salt minion"
    install_salt_minion

    if ! is_installed salt-minion
    then 
        echo "Salt minion installation failed. Will not continue"
        return 1
    fi

    configure_etc_salt client

    provision_minion_client
}

function provision_salt_master()
{
    . "${SS_DIR}"/provision/common/lib/lib-master.sh

    # The master uses the master and client 
    echo "Installing salt master"
    install_salt_master

    echo "Installing salt minion"
    install_salt_minion

    if ! is_installed salt-master 
    then 
        echo "Salt master installation failed. Will not continue"
        return 1
    fi 

    configure_etc_salt master
    configure_salt_api

    echo "Starting salt master"
    if ! start_salt_master
    then 
        echo "Salt master failed to start. Will not continue for now."
        return 1
    fi 

    echo "Continuing to salt client config"
    provision_minion_master

    echo "Done $(date)"
}

function provision_salt()
{
    if [[ -z "${SALT_TYPE}" ]]
    then
        if is_standalone 
        then 
            export SALT_TYPE="master"
        else 
            echo "No SoeStack node type configured and not a standalone install."
        fi
    fi

    cfg_routine="provision_salt_${SALT_TYPE,,}"
    if ! declare -f "${cfg_routine}" > /dev/null
    then
        echo "Configure method for soestack type ${SALT_TYPE} was not found." 
        return 1
    fi

    if ! ${cfg_routine}
    then
        echo "Configuration of salt ${SALT_TYPE} failed. Will not continue."
        return 1
    fi 

}
