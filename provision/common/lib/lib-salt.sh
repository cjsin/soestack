#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function provision::salt::fixes::regressions()
{
    functrace
    ensure_installed patch
    local patcher="/usr/local/bin/patch-saltstack.sh"
    create_script "${patcher}" <<-EOF
		# bug 53516
		badfile_1='/usr/lib/python2.7/site-packages/salt/pillar/__init__.py'
		replacement_1='s/sub_sls in set.matched_pstates.:/sub_sls in matched_pstates:/'
		sed -i.bak -r -e "\${replacement_1}" "\${badfile_1}"
		# bug 51932
		cd /usr/lib/python2.7/site-packages/salt/output
		patch -p0 --backup --forward < "${SS_DIR}/provision/common/patches/salt-bug-51932.patch"
		exit 0
	EOF

    install_systemd_service_patcher salt-master "${patcher}"
    install_systemd_service_patcher salt-minion "${patcher}"

    # Run it once. It is run by the service unit also to re-patch after reinstallation or upgrade.
    /usr/local/bin/patch-saltstack.sh

    systemctl daemon-reload
}

function provision::salt::fixes()
{
    functrace
    # This is really not important - it just reduces some 
    # salt log file error messages
    ensure_installed python2-pip # gpgme-devel
    preconfigure_pip
    pip_install --upgrade pip
    pip_ensure_installed boto boto3 attrdict six
    provision::salt::fixes::regressions
}

function provision::salt::minion::install()
{
    functrace
    ensure_installed salt-minion
    if ! is_installed salt-minion
    then 
        err "Salt minion installation failed. Will not continue"
        return 1
    fi
}

function provision::salt::master::install()
{
    functrace
    ensure_installed salt-master salt-minion salt salt-api salt-ssh
    if ! is_installed salt-master 
    then 
        err "Salt master installation failed. Will not continue"
        return 1
    fi 
}

function provision::salt::master::restart-services()
{
    functrace
    systemctl stop salt-minion
    netstat | grep 4505
    systemctl stop salt-master
    netstat | grep 4505
    #systemctl restart salt-api 
    systemctl start salt-master
    systemctl start salt-minion 
}

function provision::salt::minion::restart-services()
{
    functrace
    systemctl stop salt-minion
    netstat | grep 4505
    systemctl start salt-minion 
}

function provision::salt::test-ping()
{
    functrace
    local h="${1}"
    msg "Test ping minion '${h}'"
    salt "${h}" test.ping 2>&1 | indent
}

function provision::salt::grains::roles::generate()
{
    echo_data "roles:"
    local r
    for r in ${ROLES//,/ }
    do
        echo_data "    - ${r}"
    done
}

function provision::salt::grains::roles::write()
{
    functrace
    [[ -f /etc/salt/grains ]] || touch /etc/salt/grains

    if ! grep -q "^roles:" /etc/salt/grains 
    then 
       if [[ -n "${ROLES}" ]]
       then
            provision::salt::grains::roles::generate >> /etc/salt/grains
        else
            echo_data "roles: []" >> /etc/salt/grains
        fi
    fi
}

function provision::salt::grains::layers::generate()
{
    local DEFAULT_LAYERS=(
        soe:demo
        site:demo
        lan:demo
    )
    local DEFAULT_SEQUENCE=(
        'soe=soe/G@layers:soe'
        'role=role/G@roles'
        'site=site/G@layers:site'
        'lan=lan/G@layers:lan'
        'host=host/G@host'
        'lan-host=lan/G@layers:lan/host/G@host'
        'private=private/G@layers:private'
    )
    local layers_sequence=()
    if [[ -n "${LAYERS_SEQ}" && "${LAYERS_SEQ}" != "default" ]]
    then 
        layers_sequence=( ${LAYERS_SEQ//,/ } )
    else
        layers_sequence=( "${DEFAULT_SEQUENCE[@]}" )
    fi

    local layers=()
    if [[ -n "${LAYERS}" && "${LAYERS}" != "default" ]]
    then 
        layers=( ${LAYERS//,/ } )
    else
        layers=( ${DEFAULT_LAYERS[@]} )
    fi 

    local layer_vals=()
    local item=""
    for item in "${layers[@]}"
    do
        local layer_name="${item%%:*}"
        local layer_val="${item#*:}"
        layer_vals+=("${layer_name}: '${layer_val}'")
    done 

    {
        echo_data "layers:"
        for item in "${layer_vals[@]}"
        do 
            echo_data "    ${item}"
        done 
        echo_data "layers-sequence:"
        for item in "${layers_sequence[@]}"
        do 
            echo_data "    - '${item}'"
        done 
    }
}

function provision::salt::grains::layers::write()
{
    functrace
    [[ -f /etc/salt/grains ]] || touch /etc/salt/grains
    
    if ! grep -q "^layers:" /etc/salt/grains 
    then 
        if [[ -n "${LAYERS}" ]]
        then
            provision::salt::grains::layers::generate >> /etc/salt/grains
        else
            echo_data "layers: []" >> /etc/salt/grains
        fi
    fi
}


# NOTE this function uses a subshell () not a block {} so that
# the working directory is not changed in the calling routine.
# And also so that the 'set -e' can be used to bail out on any
# error.
function provision::salt::prepare-gpg-keys()
(
    functrace
    if [[ -z "${ADMIN_EMAIL}" ]]
    then
        err "Cannot generate GPG keys for saltstack private pillar data"
        err "without an ADMIN_EMAIL specified!"
        # This is not treated as an error
        return 0
    fi

    ensure_installed gnupg2 rng-tools
    mkdir -p "/var/log/build/salt-gpgkeys"
    prepare_gpg_keystore "salt" "/etc/salt/gpgkeys" "${ADMIN_EMAIL}" "/etc/salt/gpgkeys" "/var/log/build/salt-gpgkeys" "/usr/local/sbin"
)

function provision::salt::master::configure-etc()
{
    functrace
    mkdir -p /etc/salt/master.d
    
    # Copy some static configuration
    cp "${SS_INC}"/master.d/* /etc/salt/master.d/

    provision::salt::configure-for-development
    provision::salt::prepare-gpg-keys
    # Override the SALT_MASTER variable for this node
    # since we are a master ourselves
    export SALT_MASTER="$(best_hostname)"
    provision::salt::minion::configure-etc
}

function provision::salt::minion::configure-etc()
{
    functrace
    mkdir -p /etc/salt/minion.d

    # Copy some static configuration
    cp "${SS_INC}"/minion.d/* /etc/salt/minion.d/

    notice "Minion ID being used for salt registration is $(hostname -s)"
    echo_data "id: $(hostname -s)" > /etc/salt/minion.d/id.conf

    provision::salt::configure-ipa-integration
    
    echo_data "master: ${SALT_MASTER:-salt}" > /etc/salt/minion.d/master.conf

    #provision::salt::grains::roles::write # this will be done instead with grains.set in salt_state_provision
    provision::salt::grains::layers::write
}

function provision::salt::configure-ipa-integration()
{
    functrace
    cat > /etc/salt/minion.d/saltipa.conf <<-EOF
		saltipa:
		    ticket_file:  '/var/cache/salt/master/salt.krb'
		    check_server: 'infra.${DOMAIN}'
	EOF
}

function provision::salt::minion::start()
{
    functrace
    systemctl enable salt-minion
    systemctl start salt-minion
}

function provision::salt::master::start()
{
    functrace
    systemctl enable salt-master salt-api
    systemctl restart salt-master
}

function provision::salt::minion::wait-for-enrolment()
{
    functrace
    while ! salt-call test.ping
    do 
        date
        msg "Waiting for enrolment"
        msg "Will try again in 30"
        sleep 30
        date
    done
}

function provision::salt::step()
{
    functrace
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

function provision::salt::states()
{
    functrace
    local preconfigured_roles="${1}"
    local fail_fast="${2:-0}"

    # Sync custom modules to the minion ('uuid','noop', and 'saltipa')
    provision::salt::step saltutil.sync_all

    # Setting host grain to match short hostname
    # The 'host' grain is otherwise dynamically calculated and is affected by the installed hosts file,
    # especially when there are multiple interfaces on the machine, it can get the name from
    # the IP associated from the wrong network interface
    provision::salt::step grains.set host "$(hostname -s)"

    if [[ "${PROVISION_TYPE}" == "vagrant" ]]
    then 
        provision::salt::step grains.set vagrant True
    fi

    # NOTE the roles grains must be configured prior to running the 
    # full state apply, because the roles grains are utilised in selecting
    # which states are applied. 
    if [[ "${preconfigured_roles}" == "auto" ]]
    then 
        provision::salt::step state.sls common.role-sets.auto
    elif [[ "${preconfigured_roles}" =~ ^role-set: ]]
    then 
        provision::salt::step grains.set role-set "${preconfigured_roles#role-set:}" force=True
        provision::salt::step state.sls common.role-sets.apply
    else
        # This works to set multiple roles with a simple string 'a,b,c'
        provision::salt::step grains.set roles "[${preconfigured_roles}]" force=True
    fi

    local steps=(
        # Receive secrets which may be used by various states
        "state.sls secrets"
        # Set up yum for package installation as soon as possible
        "state.sls yum"
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
        provision::salt::step ${step}
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
    functrace
    echo_start "Starting salt state provisioning."
    local logfile=/var/log/provision/salt-state-provision.log
    msg "Log file is ${logfile}"
    provision::salt::states "${*}" >> "${logfile}" 2>&1
    echo_done "Completed salt state provisioning."
}

function provision::salt::minion::client()
{
    functrace
    if ! provision::salt::minion::auto-enrol
    then 
        err "Automatic enrolment failed!"
        err "It will need to be enroled manually on the master."
        err "Will retry."
        # Continue below, it will wait in a loop
    fi

    #with_low_tcp_time_wait provision::salt::master::restart-services

    provision::salt::minion::start

    provision::salt::minion::wait-for-enrolment 2>&1 | indent
}

function provision::salt::minion::master()
{
    functrace
    #with_low_tcp_time_wait provision::salt::minion::restart-services

    provision::salt::minion::start

    provision::salt::master::enrol-self

    provision::salt::minion::wait-for-enrolment
}

function provision::salt::minion()
{
    functrace
    . "${SS_DIR}"/provision/common/lib/lib-client.sh

    msg "Installing salt minion"
    if ! provision::salt::minion::install
    then
        return 1
    fi

    provision::salt::fixes
    provision::salt::minion::configure-etc
    provision::salt::minion::client
}

function provision::salt::master()
{
    . "${SS_DIR}"/provision/common/lib/lib-master.sh

    # The master uses the master and client 
    msg "Installing salt master"
    if ! provision::salt::master::install
    then
        return 1
    fi

    msg "Installing salt minion"
    if ! provision::salt::minion::install
    then
        return 1
    fi

    provision::salt::fixes
    provision::salt::minion::configure-etc
    provision::salt::master::configure-etc
    provision::salt::configure-salt-api

    msg "Starting salt master"
    if ! provision::salt::master::start
    then 
        err "Salt master failed to start. Will not continue for now."
        return 1
    fi 

    msg "Continuing to salt client config"
    provision::salt::minion::master

    msg "Done $(date)"
}

function provision::salt()
{
    functrace
    if [[ -z "${SALT_TYPE}" ]]
    then
        if is_standalone 
        then 
            export SALT_TYPE="master"
        else 
            err "No SoeStack node type configured and not a standalone install."
        fi
    fi

    cfg_routine="provision::salt::${SALT_TYPE,,}"
    if ! declare -f "${cfg_routine}" > /dev/null
    then
        err "Configure method for soestack type '${SALT_TYPE}' was not found." 
        return 1
    fi

    if ! ${cfg_routine}
    then
        err "Configuration of salt '${SALT_TYPE}' failed. Will not continue."
        return 1
    fi 

}
