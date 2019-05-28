#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function configure_salt_api()
{
    ensure_installed pyOpenSSL

    salt-call --local tls.create_self_signed_cert

    cat > /etc/salt/master.d/salt_api.conf <<-EOF
		rest_cherrypy:
		    port:     9009
		    ssl_crt:  /etc/pki/tls/certs/localhost.crt
		    ssl_key:  /etc/pki/tls/certs/localhost.key
		    # start with auth disabled during dev, get salt e-auth working later
		    webhook_disable_auth : True
		
		external_auth:
		    pam:
		        salt-enrol:
		            - '@wheel'
	EOF

    if ! grep -q salt-enrol: /etc/passwd 
    then 
        useradd -s /sbin/nologin -r salt-enrol -d /var/lib/salt-enrol 
        passwd --stdin salt-enrol <<< "d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a"
    fi

    ensure_installed openssh
    mkdir -p /var/lib/salt-enrol/.ssh
    create_ssh_key_file /var/lib/salt-enrol/.ssh/id_rsa
    chown -R salt-enrol.salt-enrol /var/lib/salt-enrol/
    chmod 700 /var/lib/salt-enrol/.ssh 
}

function salt_master_enrol_self()
{
    local h="$(hostname -s)"

    if [[ ! -f "/etc/salt/pki/master/minions/${h}" ]]
    then
        while [[ ! -f "/etc/salt/pki/master/minions_pre/${h}" ]]
        do 
            # Wait a little for the minion to request enrolment
            sleep 1
            msg "Waiting for minion pre-enrolment"
        done

        msg "Enroling salt minion '${h}'"
        
        salt-key -y -a "${h}"

        sleep 2

    fi
     
    while ! salt_test_ping "${h}"
    do
        msg "Waiting longer for minion to start responding to pings."
        sleep 5
    done 
}
