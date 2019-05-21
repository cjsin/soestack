# routines for bootstrapping an initial standalone server
# so that it can proceed to provision itself like any other node.

. /soestack/provision/kickstart/lib/lib.sh

function import_gpgkeys()
{
    echo "Import GPG keys"
    if [[ -d "/soestack/provision/common/inc/gpgkeys" ]]
    then 
        if rpm --import /soestack/provision/common/inc/gpgkeys/*
        then
            echo "OK".
        fi
    else 
        echo "GPG keys were not found for import"
    fi
}

function configure_standalone_network()
{
    echo "Configure network for standalone server"

    local IP_INFO="${IPADDR}${IPADDRS}"
    if [[ -n "${NETDEV}" && -n "${IP_INFO}" && -n "${IPPREFIX}" ]]
    then 
        local netcfgfile=/etc/sysconfig/network-scripts/ifcfg-"${NETDEV}"
        local netcfgtemplate=/soestack/provision/common/inc/ifcfg-template

        local -a ip_edits=()

        if [[ -n "${IPADDRS}" ]]
        then
            local extra=""
            local p
            local num=1
            for p in ${IPADDRS//,/ }
            do 
                local left="${p%/*}"
                local right="${p##*/}"
                [[ -n "${left}" ]] && extra+="IPADDR${num}=${left}\\n"
                [[ -n "${right}" ]] && extra+="PREFIX${num}=${right}\\n"
                ((num++))
            done
            ip_edits=(
                -e "/^.*=%IPADDR%/ d" 
                -e "/^.*=%IPPREFIX%/ d" 
                -e "s/^%IPADDRS%/${extra}/"
            )
        else
            ip_edits=(
                -e "s/%IPADDR%/${IPADDR}/" 
                -e "s/%IPPREFIX%/${IPPREFIX}/" 
                -e "/%IPADDRS%/ d"
            )
        fi

        if [[ -n "${GATEWAY}" ]]
        then 
            ip_edits+=( -e "s/%GATEWAY%/${GATEWAY}/" )
        fi 

        #if [[ -n "${NAMESERVER}" ]]
        #then 
            ip_edits+=( -e "s/%NAMESERVER%/${NAMESERVER}/" )
        #fi 

        local devname_edits=(
            -r -e "s/^(NAME|DEVICE)=.*/\1=${NETDEV}/" 
        )

        echo "Network configuration file is ${netcfgfile}"
        if [[ -f "${netcfgfile}" ]] && grep -qi soestack "${netcfgfile}"
        then 
            echo "Network device appears to have already been installed"
        else
            echo "Configuring network device from template"
            /bin/cp -f "${netcfgtemplate}" "${netcfgfile}"
            sed -i -r "${ip_edits[@]}" "${netcfgfile}"
        fi 

        sed -i "${devname_edits[@]}" "${netcfgfile}"
 
        systemctl restart network
    else 
        echo "Network device was not autodetected or IP address and PREFIX not configured"
        echo " - skipping network configuration"
    fi
}

function copy_bundled_files()
{
    echo "Copy bootstrap packages"
 
    if [[ -d "/e/bundled/bootstrap-pkgs" ]]
    then
        /bin/cp -f /e/bundled/bootstrap-pkgs/*repo /etc/yum.repos.d/
        yum makecache
    else
        echo "No bootstrap repos for bundled rpms found."
    fi 

    ensure_installed rsync

    if [[ ! -d /soestack/salt ]]
    then 
        if [[ -d /e/bundled/soe ]]
        then 
            echo "Copy bundled SOE to /e/soestack"
            rsync -av /e/bundled/soe/salt/ /soestack/salt/
        else 
            echo "No SOE copy is availble for pre-configuration"
        fi
    fi
}

function restore_nexus_data()
{
    local datadir=/d/local/data/nexus/

    if [[ ! -d "${datadir}/restore-from-backup" ]]
    then 
        mkdir -p "${datadir}"/restore-from-backup
    else
        echo "Nexus DB backup files appear to have been unpacked already. Will overwrite anyway."
        rm -f "${datadir}/restore-from-backup"/*bak
    fi

    if ! [[ -f /e/bundled/nexus/blobs.tar && -f /e/bundled/nexus/db-backup.tar ]]
    then 
        echo "No Nexus backup database is available. Nexus will be configured as a new instance."
    else
        echo "Install Nexus DB backup"
        tar x -C "${datadir}"/restore-from-backup -f /e/bundled/nexus/db-backup.tar

        if [[ ! -d "${datadir}/blobs" ]]
        then
            echo "Install Nexus Blobs backup. This may take a while."
            tar x -C /d/local/data/nexus --checkpoint=20000 -f /e/bundled/nexus/blobs.tar
        else 
            echo "Nexus Blobs appear to have been unpacked already"
        fi
    fi

    echo "Fix nexus file contexts"
    chcon -R -t container_file_t /d/local/data/nexus

    return 0
}

function start_docker()
{
    echo "Enable docker"
    systemctl enable docker
    # Docker is restarted not just started, because
    # if the network has been reconfigured it will need 
    # to reinstall firewall rules
    systemctl restart docker

    echo "Pause for docker startup"
    sleep 10
}

function load_nexus_container()
{
    echo "Checking docker status"
    if systemctl status docker
    then 
        echo "Load nexus container"
        docker load -i /e/bundled/docker/sonatype*nexus*tar
        return $?
    else 
        echo "Docker failed to start"
        return 1
    fi
}

function prepare_network_for_docker()
{
    cat > /etc/sysctl.d/90-docker-networking.conf <<-EOF
		net.ipv4.ip_forward = 1
		net.ipv4.conf.all.forwarding = 1
		net.bridge.bridge-nf-call-iptables = 1
		net.bridge.bridge-nf-call-ip6tables = 1
	EOF
    sysctl --system
}

function prepare_nexus_service()
{
    echo "Preparing nexus user and service"
    cp /soestack/provision/common/inc/nexus-mirror.service /etc/systemd/system/
    groupadd -g 200 nexus
    useradd -r -d /d/local/data/nexus -u 200 -g 200 nexus
    chown -R nexus.nexus /d/local/data/nexus/
    systemctl enable nexus-mirror.service
    # NOTE the service is not started yet
}

function patch_hostfile_for_nexus()
{
    echo "Patch hostfile for nexus in standalone instance."
    sed -i -r -e 's/[[:space:]]nexus($|[[:space:]]|[.][^[:space:]]+)/ /g' /etc/hosts
    echo "Result:"
    cat /etc/hosts
    # This is a temporary hack because I don't have the disk
    # space to allow copying the nexus blobs inside the VM,
    # so on a VM will change it to use nexus on the host (the gateway)
    if ! grep -q nexus /etc/hosts 
    then 
        if [[ "${HARDWARE}" != "vm" ]]
        then 
            sed -i '/127.0.0.1[[:space:]].*/ s/$/ nexus/' /etc/hosts
        elif [[ -n "${GATEWAY}" ]]
        then 
            sed -i "/^${GATEWAY}[[:space:]]/ s/$/ nexus/" /etc/hosts
        elif grep gateway /etc/hosts
        then 
            sed -i "/gateway/ s/$/ nexus/" /etc/hosts
        fi
    fi
    echo "Result:"
    cat /etc/hosts
}

function start_nexus()
{
    echo "Starting nexus service"
    if systemctl start nexus-mirror.service
    then
        echo "Wait for nexus mirror startup"
        sleep 30 
        if docker ps | egrep nexus-mirror
        then 
            max_wait=600
            while ! docker logs --since=10s nexus-mirror | egrep -i 'Started Sonatype Nexus' 
            do
                echo "Still waiting for Nexus to recreate its database and finish starting up."
                sleep 5
                ((max_wait-=5))
                if [[ "${max_wait}" -le 0 ]]
                then
                    echo "Timed out - Nexus took too long to start. Something probably went wrong." 
                    return 1
                fi
                echo "Waiting a max of ${max_wait} seconds longer"
            done 
        else 
            echo "Nexus appears to have failed to start"
            return 1
        fi
    else 
        echo "Starting nexus failed"
        reutrn 1
    fi 
}

function configure_standalone_server()
{
    import_gpgkeys 

    copy_bundled_files

    prepare_network_for_docker

    rpm -qa | grep docker-ce || yum -y --enablerepo='*' install docker-ce

    replace_firewall 

    restore_nexus_data

    configure_standalone_network 

    # patch_hostfile_for_nexus

    if ! docker ps | grep -q nexus-mirror 
    then 
        if start_docker
        then
            load_nexus_container
        else
            echo "Docker seems to have failed to start"
            return 1
        fi

        prepare_nexus_service

    fi
}

function switchover_to_nexus()
{
    if start_nexus 
    then 
        mv -f /etc/yum.repos.d/*repo /etc/yum.repos.d/disable/
        /bin/cp -f /soestack/provision/common/inc/bootstrap-centos.repo /etc/yum.repos.d/
        yum makecache
    else 
        echo "Skipping yum repo switchover because nexus is not available"
    fi
}
