#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function provision::salt::fixes::regressions()
{
    ensure_installed patch
    local patcher="/usr/local/sbin/patch-saltstack.sh"
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
    systemctl daemon-reload
}

function provision::salt::fixes()
{
    # This is really not important - it just reduces some 
    # salt log file error messages
    ensure_installed python2-pip # gpgme-devel
    preconfigure_pip
    pip list | egrep boto || pip install boto boto3
    pip list | egrep attrdict || pip install attrdict 
    #pip list | egrep gpg || pip install gpg
    if ! pip list | egrep attrdict
    then 
        # Install bootstrap-pkgs pypi copy of attrdict
        local files=( /e/bundled/bootstrap-pkgs/pypi/{attrdict,six}-*)
        pip install "${files[@]}"
    fi
    provision::salt::fixes::regressions
}

function provision::salt::minion::install()
{
    ensure_installed salt-minion
}

function provision::salt::master::install()
{
    ensure_installed salt-master salt-minion salt salt-api salt-ssh
}

function provision::salt::master::restart-services()
{
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
    systemctl stop salt-minion
    netstat | grep 4505
    systemctl start salt-minion 
}

function provision::salt::test-ping()
{
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
    local layers=()
    local item=""
    local layers_sequence=()
    for item in ${LAYERS//,/ }
    do
        local layer_name="${item%%:*}"
        local layer_spec="${item#*:}"
        local spec_parts=( ${layer_spec//+/ } )
        layers_sequence+=("${layer_name}")
        if [[ "${#spec_parts[@]}" == 1 ]]
        then
            layers+=("${layer_name}: ${layer_spec}")
        else
            layers+=("${layer_name}:")
            for sp in "${spec_parts[@]}"
            do
                sp_name="${sp%%:*}"
                sp_value="${sp#*:}"
                layers+=("    ${sp_name}: ${sp_value}")
            done
        fi
    done 
    {
        echo_data "layers:"
        for item in "${layers[@]}"
        do 
            echo_data "    ${item}"
        done 
        echo_data "layers-sequence:"
        for item in "${layers_sequence[@]}"
        do 
            echo_data "    - ${item}"
        done 
        
    }
}

function provision::salt::grains::layers::write()
{
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
    if [[ -z "${ADMIN_EMAIL}" ]]
    then
        err "Cannot generate GPG keys for saltstack private pillar data"
        err "without an ADMIN_EMAIL specified!"
        # This is not treated as an error
        return 0
    fi

    ensure_installed gnupg rngd
    mkdir -p "/var/log/build/salt-gpgkeys"
    prepare_gpg_keystore "salt" "/etc/salt/gpgkeys" "${ADMIN_EMAIL}" "/var/log/build/salt-gpgkeys" "/usr/local/sbin"
)

function provision::salt::master::configure-etc()
{
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
    cat > /etc/salt/minion.d/saltipa.conf <<-EOF
		saltipa:
		    ticket_file:  '/var/cache/salt/master/salt.krb'
		    check_server: 'infra.${DOMAIN}'
	EOF
}

function provision::salt::minion::start()
{
    systemctl enable salt-minion
    systemctl start salt-minion
}

function provision::salt::master::start()
{
    systemctl enable salt-master salt-api
    systemctl restart salt-master
}

function provision::salt::minion::wait-for-enrolment()
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

function provision::salt::step()
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

function provision::salt::states()
{
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

    # Receive secrets which may be used by various states
    provision::salt::step state.sls secrets

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
    echo_start "Starting salt state provisioning."
    local logfile=/var/log/provision/salt-state-provision.log
    msg "Log file is ${logfile}"
    provision::salt::states "${*}" >> "${logfile}" 2>&1
    echo_done "Completed salt state provisioning."
}

function provision::salt::minion::client()
{
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
    #with_low_tcp_time_wait provision::salt::minion::restart-services

    provision::salt::minion::start

    provision::salt::master::enrol-self

    provision::salt::minion::wait-for-enrolment
}

function provision::salt::minion()
{
    . "${SS_DIR}"/provision/common/lib/lib-client.sh

    msg "Installing salt minion"
    provision::salt::minion::install

    if ! is_installed salt-minion
    then 
        err "Salt minion installation failed. Will not continue"
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
    provision::salt::master::install

    msg "Installing salt minion"
    provision::salt::minion::install

    if ! is_installed salt-master 
    then 
        err "Salt master installation failed. Will not continue"
        return 1
    fi 

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
