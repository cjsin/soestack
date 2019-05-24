
function saltstack_fixes()
{
    # This is really not important - it just reduces some 
    # salt log file error messages
    ensure_installed python-pip 
    preconfigure_pip
    pip list | egrep boto || pip install boto boto3
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
    salt "${h}" test.ping
}

function write_role_grains()
{
    if ! grep -s "^roles:" /etc/salt/grains 
    then 
       if [[ -n "${ROLES}" ]]
       then
            {
                echo "roles:"
                local r
                for r in ${ROLES//,/ }
                do
                    echo "    - ${r}"
                done
            } >> /etc/salt/grains
        else
            echo "roles: []" >> /etc/salt/grains
        fi
    fi 
}

function write_layer_grains()
{
    if ! grep -s "^layers:" /etc/salt/grains 
    then 
        if [[ -n "${LAYERS}" ]]
        then
            {
                echo "layers:"
                if [[ "${LAYERS}" =~ : ]]
                then
                    local items=(${LAYERS//,/ })
                    local item
                    for item in "${items[@]}"
                    do
                        echo "    ${item//:/: }"
                    done
                elif [[ "${LAYERS}" =~ , ]]
                then
                    local items=(${LAYERS//,/ })
                    local item
                    for item in "${items[@]}"
                    do
                        echo "    - ${item}"
                    done
                else
                    echo "    - ${LAYERS}"
                fi
            } >> /etc/salt/grains
        else
            echo "layers: []" >> /etc/salt/grains
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
            echo "${h}"
            return 0
        fi
    done
    echo "$(hostname -f)"
}

function configure_etc_salt()
{
    local minion_type="${1}" # client or master
    
    mkdir -p /etc/salt/minion.d
    mkdir -p /etc/salt/master.d

    # Copy some static configuration
    cp "${SS_INC}"/minion.d/* /etc/salt/minion.d/

    echo "id: $(hostname -s)" > /etc/salt/minion.d/id.conf
    
    if [[ "${minion_type}" == "master" ]]
    then
        export SALT_MASTER="$(best_hostname)"
        # Copy some static configuration
        cp "${SS_INC}"/master.d/* /etc/salt/master.d/
    fi
    
    echo "master: ${SALT_MASTER:-salt}" > /etc/salt/minion.d/master.conf

    #write_role_grains # this will be done instead with grains.set in salt_state_provision
    write_layer_grains
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
        echo "Waiting for enrolment"
        echo "Will try again in 30"
        sleep 30
        date
    done
}


function salt_state_provision()
{
    local preconfigured_roles="${1}"

    # Setting host grain to match short hostname
    # The 'host' grain is otherwise dynamically calculated and is affected by the installed hosts file,
    # especially when there are multiple interfaces on the machine, it can get the name from
    # the IP associated from the wrong network interface
    salt-call grains.set host "$(hostname -s)"

    if [[ "${preconfigured_roles}" =~ ^role-set ]]
    then 
        salt-call grains.set role-set "${preconfigured_roles#role-set:}" force=True
        salt-call state.sls common.role-sets.apply
    else
        # This works to set multiple roles with a simple string 'a,b,c'
        salt-call grains.set roles "[${preconfigured_roles}]" force=True
    fi

    if [[ "${PROVISION_TYPE}" == "vagrant" ]]
    then 
        salt-call grains.set vagrant True
    fi

    salt-call state.sls provision.pre
    salt-call state.sls provision.main
    salt-call state.apply
    salt-call state.sls provision.post
} 

function run_salt_state_provision()
{
    local logfile=/var/log/provision/salt-state-provision.log
    echo "Starting salt state provisioning."
    echo "Log file is ${logfile}".
    salt_state_provision "${*}" >> "${logfile}" 2>&1
    echo "Completed salt state provisioning."
}

function provision_minion_client()
{
    if ! salt_minion_autoenrol
    then 
        echo "Automatic enrolment failed!"
        echo "It will need to be enroled manually on the master."
        # Continue below, it will wait in a loop
    fi

    #with_low_tcp_time_wait restart_salt_services

    start_salt_minion

    wait_for_enrolment
}

function provision_minion_master()
{
    #with_low_tcp_time_wait restart_salt_services

    start_salt_minion

    salt_master_enrol_self

    wait_for_enrolment
}

function provision_salt_client()
{
    . /soestack/provision/common/lib/lib-client.sh

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
    . /soestack/provision/common/lib/lib-master.sh

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
