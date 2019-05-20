
# Working config:
# rest_cherrypy:
#     port:     9009
#     ssl_crt:  /etc/pki/tls/certs/localhost.crt
#     ssl_key:  /etc/pki/tls/certs/localhost.key
#     # start with auth disabled during dev, get salt e-auth working later
#     webhook_disable_auth : True

# external_auth:
#     pam:
#         salt-enrol:
#             - '@wheel'

function configure_salt_api()
{
    ensure_installed pyOpenSSL

    salt-call --local tls.create_self_signed_cert

    {
        echo "rest_cherrypy:"
        echo "    port:     9009"
        echo "    ssl_crt:  /etc/pki/tls/certs/localhost.crt"
        echo "    ssl_key:  /etc/pki/tls/certs/localhost.key"
        echo "    # start with auth disabled during dev, get salt e-auth working later"
        echo "    webhook_disable_auth : True"
        echo ""
        echo "external_auth:"
        echo "    pam:"
        echo "        salt-enrol:"
        echo "            - '@wheel'"
    } > /etc/salt/master.d/salt_api.conf

    if ! grep -q salt-enrol: /etc/passwd 
    then 
        useradd -s /sbin/nologin -r salt-enrol -d /var/lib/salt-enrol 
        passwd --stdin salt-enrol <<< "d62da93aecc94bd6363d0c7d5fbea7248e8e0c9e15dfca0fb92c1e665760de9a"
    fi


    mkdir -p /var/lib/salt-enrol/.ssh
    
    local keyfile=/var/lib/salt-enrol/.ssh/id_rsa

    if [[ ! -f "${keyfile}" ]]
    then
        ssh-keygen -t rsa -N '' -q -f "${keyfile}"
    fi 

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
            echo "Waiting for minion pre-enrolment" 1>&2
        done
        msg "Enroling salt minion '${h}'"
        
        salt-key -y -a "${h}"

        sleep 2

    fi
     
    while ! salt_test_ping "${h}"
    do
        echo "Waiting longer for minion to start responding to pings."
        sleep 5
    done 
}
