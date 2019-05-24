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
 
    # NOTE these still use /e/bundled, for accessing the bundled repo files and soe copy.
    # However BUNDLED_SRC should be set to specify the downloading large bundled files,
    # and can also be set to /e/bundled if all the files were included.
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

function select_iso()
{
    local src="${1}"
    local -a preferred_sequence=( DVD Everything Minimal )
    local available=()

    if [[ "${src}" =~ ^http:// ]]
    then
        local listing=$(curl -s "${BUNDLED_SRC}/iso/" | sed -r -n -e '/href=.*[.]iso"/ { s/.*href="(.*[.]iso)".*/\1/; p}')
        mapfile -t available <<< "${listing}"
    elif [[ "${src}" =~ ^/ ]]
    then
        listing=$(cd "${src}" && ls | egrep '[.]iso$')
        mapfile -t available <<< "${listing}"
    fi

    if ! (( ${#available[@]} ))
    then
        echo "WARNING: No isos found within ${src}"
        return 1
    fi

    local selected_iso=""
    local iso_file=""
    local name=""
    local copy_all=0

    for name in "${preferred_sequence[@]}"
    do
        for iso_file in "${available[@]}"
        do
            [[ "${iso_file}" =~ -${name}- ]] && selected_iso="${iso_file}"
        done
        [[ -n "${selected_iso}" ]] && break 
    done
    if [[ -n "${selected_iso}" ]]
    then
        echo "${src}/${selected_iso}"
    else
        echo "WARNING: No recognised iso filename was found in ${src}" 1>&2
    fi
}

function obtain_isos()
(
    local dst_dir="/e/iso"

    mkdir -p "${dst_dir}"

    if ! cd "${dst_dir}" 
    then
        echo "Could not enter ${dst_dir}." 1>&2
        return 1
    fi

    local selected=""

    if ls | egrep "[.]iso\$"
    then
        local selected=$(select_iso "${dst_dir}")
        if [[ -n "${selected}" ]]
        then 
            echo "Iso ${selected} is suitable." 1>&2
            return 0
        fi
    fi

    selected=$(select_iso "${BUNDLED_SRC}/iso")

    if [[ -n "${selected}" ]]
    then
        local filename="${selected##*/}"
        local extension="${filename##*.}"
        if [[ "${extension,,}" == "iso" ]]
        then
            if [[ "${selected}" =~ ^http:// ]]
            then 
                echo "Downloading ${selected}" 1>&2
                if curl -o "./${filename}" "${selected}" 
                then
                    echo "Successfully downloaded ${selected}" 1>&2
                else
                    echo "Failed downloading ${selected}" 1>&2
                    rm -f "./${filename}"
                fi
            elif [[ "${selected:0:1}" == "/" ]]
            then
                ln -s "${selected}"
            else
                echo "I do not know how to obtain iso '${selected}'" 1>&2
            fi
        else 
            echo "Iso filename '${selected}' extension '${extension}' did not end in 'iso' as expected." 1>&2
        fi
    else
        echo "No source isos available at ${BUNDLED_SRC}" 1>&2
    fi
)

function unpack_tar()
{
    local src="${1}"
    local path="${2}"
    local dst="${3}"
    mkdir -p "${dst}"
    if [[ "${src}" =~ ^http ]]
    then
        curl "${src}${path}" | tar x -C "${dst}" -
    elif [[ -f "${src}" ]]
    then
        tar x -C "${dst}" -f "${src}${path}"
    else
        echo "No tar archive available for ${src}${path}" 1>&2
    fi
}

function restore_nexus_data()
{
    local datadir=/d/local/data/nexus/
    local db_dest="${datadir}/restore-from-backup"
    local problems=0

    echo "Restoring nexus data from bundled source" 1>&2

    if [[ ! -d "${db_dest}" ]]
    then 
        mkdir -p "${db_dest}"
    else
        echo "Nexus DB backup files appear to have been unpacked already. Will overwrite anyway."
        rm -f "${db_dest}"/*bak
    fi

    unpack_tar "${BUNDLED_SRC}" "/nexus/db-backup.tar" "${datadir}/restore-from-backup"
    ((problems+=$?))

    if [[ ! -d "${datadir}/blobs" ]]
    then
        echo "Install Nexus Blobs backup. This may take a while."
        unpack_tar "${BUNDLED_SRC}" "/nexus/blobs.tar" "${datadir}"
        ((problems+=$?))
    else
        echo "Nexus Blobs appear to have been unpacked already"
    fi

    if (( problems ))
    then 
        echo "No Nexus backup database is available. Nexus will probably be configured as a new instance."
    else
        echo "Nexus backup data copied"
    fi

    echo "Fix nexus file contexts"
    chcon -R -t container_file_t "${datadir}"

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

function load_container_file()
{
    echo "Checking docker status"
    if ! systemctl status docker
    then 
        echo "Docker failed to start"
        return 1
    fi

    local image_file="${BUNDLED_SRC}/docker/${name}"
    echo "Load nexus container ${image_file}" 1>&2
    docker load -i "${image_file}"
}

function load_nexus_container()
{
    sonatype_version="3.13.0"
    load_container_file "sonatype_nexus3__${sonatype_version}.tar"
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
