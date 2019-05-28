#!/bin/bash

# routines for bootstrapping an initial standalone server
# so that it can proceed to provision itself like any other node.

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . "${SS_DIR:=${BASH_SOURCE[0]%/provision/*}}"/provision/common/lib/lib.sh

function import_gpgkeys()
{
    msg "Import GPG keys"
    if [[ -d "${SS_DIR}/provision/common/inc/gpgkeys" ]]
    then 
        if rpm --import "${SS_DIR}"/provision/common/inc/gpgkeys/*
        then
            msg "OK".
        fi
    else 
        err "GPG keys were not found for import"
    fi
}

function create_installmedia_repo()
{
    local pkg_dst="/e/yum-repos/installmedia"
    local repos_dir="${ANA_INSTALL_PATH}/etc/yum.repos.d"
    {
        echo_data "[installmedia]"
        echo_data "name=installmedia"
        echo_data "baseurl=file://${pkg_dst}"
        echo_data "enabled=1"
        echo_data "gpgcheck=1"
    } > "${repos_dir}/installmedia.repo"

    yum --disablerepo='*' --enablerepo=installmedia makecache
}

function configure_standalone_network()
{
    echo_stage 3 "Configure network for standalone server"

    local IP_INFO="${IPADDR}${IPADDRS}"
    if [[ -n "${NETDEV}" && -n "${IP_INFO}" && -n "${IPPREFIX}" ]]
    then 
        local netcfgfile=/etc/sysconfig/network-scripts/ifcfg-"${NETDEV}"
        local netcfgtemplate="${SS_DIR}"/provision/common/inc/ifcfg-template

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

        msg "Network configuration file is ${netcfgfile}"
        if [[ -f "${netcfgfile}" ]] && grep -qi soestack "${netcfgfile}"
        then 
            msg "Network device appears to have already been installed"
        else
            msg "Configuring network device from template"
            /bin/cp -f "${netcfgtemplate}" "${netcfgfile}"
            sed -i -r "${ip_edits[@]}" "${netcfgfile}"
        fi 

        sed -i "${devname_edits[@]}" "${netcfgfile}"
 
        systemctl restart network
    else 
        notice "Network device was not autodetected or IP address and PREFIX not configured"
        notice " - skipping network configuration"
    fi
}

function copy_bundled_files()
{
    msg "Copy bootstrap packages"
 
    # NOTE these still use /e/bundled, for accessing the bundled repo files and soe copy.
    # However BUNDLED_SRC should be set to specify the downloading large bundled files,
    # and can also be set to /e/bundled if all the files were included.
    if [[ -d "/e/bundled/bootstrap-pkgs" ]]
    then
        /bin/cp -f /e/bundled/bootstrap-pkgs/*repo /etc/yum.repos.d/
        yum makecache
    else
        notice "No bootstrap repos for bundled rpms found."
    fi 

    ensure_installed rsync

    if [[ ! -d "${SS_DIR}/salt" ]]
    then 
        if [[ -d /e/bundled/soe ]]
        then 
            nsg "Copy bundled SOE to /e/soestack"
            rsync -av /e/bundled/soe/salt/ "${SS_DIR}/salt/"
        else 
            notice "No SOE copy is availble for pre-configuration"
        fi
    fi

    local pkg_dir="/e/yum-repos/installmedia"
    local result selected_iso
    selected_iso=$(obtain_isos)
    result=$?
    if [[ -n "${selected_iso}" ]]
    then
        local fstab_line="${selected_iso} ${pkg_dir} auto defaults,ro,loop,auto,nofail 0 0 "
        if ! grep -F -q "${fstab_line}" /etc/fstab 
        then
            echo_data "${fstab_line}" >> "/etc/fstab"
        fi
        mkdir -p "${pkg_dir}"
        if ! grep -q "${pkg_dir}" /proc/mounts 
        then
            mount "${pkg_dir}"
            create_installmedia_repo
        fi
    else
        notice "Could not mount ${pkg_dir} (no iso available)"
        return 1
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
        warn "No isos found within ${src}"
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
        echo_return "${src}/${selected_iso}"
    else
        warn "No recognised iso filename was found in ${src}"
    fi
}

function obtain_isos()
(
    local dst_dir="/e/iso"

    mkdir -p "${dst_dir}"

    if ! cd "${dst_dir}" 
    then
        err "Could not enter ${dst_dir}."
        return 1
    fi

    local selected=""

    if ls | egrep -q "[.]iso\$"
    then
        local selected=$(select_iso "${dst_dir}")
        if [[ -n "${selected}" ]]
        then 
            msg "Iso ${selected} is suitable."
            echo_return "${selected}"
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
                msg "Downloading ${selected}"
                if curl -o "./${filename}" "${selected}" 
                then
                    nsg "Successfully downloaded ${selected}"
                    echo_return "${dst_dir}/${filename}"
                else
                    err "Failed downloading ${selected}"
                    rm -f "./${filename}"
                fi
            elif [[ "${selected:0:1}" == "/" ]]
            then
                ln -s "${selected}"
                echo_return "${selected}"
            else
                err "I do not know how to obtain iso '${selected}'"
            fi
        else 
            err "Iso filename '${selected}' extension '${extension}' did not end in 'iso' as expected."
        fi
    else
        err "No source isos available at ${BUNDLED_SRC}/"
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
        curl "${src}${path}" | tar x -C "${dst}"
    elif [[ -f "${src}" ]]
    then
        tar x -C "${dst}" -f "${src}${path}"
    else
        err "No tar archive available for ${src}${path}"
    fi
}

function restore_nexus_data()
{
    local datadir=/d/local/data/nexus/
    local db_dest="${datadir}/restore-from-backup"
    local problems=0

    echo_stage 3 "Restoring nexus data from bundled source"

    if [[ ! -d "${db_dest}" ]]
    then 
        mkdir -p "${db_dest}"
    else
        notice "Nexus DB backup files appear to have been unpacked already. Will overwrite anyway."
        rm -f "${db_dest}"/*bak
    fi

    unpack_tar "${BUNDLED_SRC}" "/nexus/db-backup.tar" "${datadir}/restore-from-backup"
    ((problems+=$?))

    if [[ ! -d "${datadir}/blobs" ]]
    then
        notice "Install Nexus Blobs backup. This may take a while."
        unpack_tar "${BUNDLED_SRC}" "/nexus/blobs.tar" "${datadir}"
        ((problems+=$?))
    else
        notice "Nexus Blobs appear to have been unpacked already"
    fi

    if (( problems ))
    then 
        notice "No Nexus backup database is available. Nexus will probably be configured as a new instance."
    else
        msg "Nexus backup data copied"
    fi

    msg "Fix nexus file contexts"
    chcon -R -t container_file_t "${datadir}"

    return 0
}

function start_docker()
{
    echo_stage 3 "Enable and start docker"
    yum -y install git

    systemctl enable docker
    # Docker is restarted not just started, because
    # if the network has been reconfigured it will need 
    # to reinstall firewall rules
    systemctl restart docker

    msg "Pause for docker startup"
    sleep 10
    
}

function obtain_bundled_file()
{
    local path="${1}"
    local dst_dir="${2:-/e/bundled}"
    local src="${BUNDLED_SRC}/${path}"
    local dst="${dst_dir}/${path}"
    mkdir -p "${dst_dir}"

    if [[ -z "${dst}" || "${dst}" == "/" || ! "${dst}" =~ .... ]]
    then
        warn "Refusing to download to '${dst}' - sanity check failed."
        warn "A required variable may be empty"
        return 1
    fi

    if [[ -f "${dst}" ]]
    then
        notice "${dst} was already obtained"
        echo_return "${dst}"
    elif [[ "${src}" =~ ^http:// ]]
    then
        
        msg "Downloading ${src} to ${dst}"
        if curl -o "${dst}" "${src}" 
        then
            #local sz=$(stat -c %s "${dst}")
            #if [[ ${sz} -lt ]]
            local file_type=$(file "${dst}")
            if [[ "${file_type}" =~ HTML.document ]]
            then
                if head -n 100 "${dst}" | egrep -i 'error.*404|http.*not.*found' 
                then 
                    err " The file appears to have been missing"
                    head -n100 "${dst}" 1>&2 | sed 's/^/    /'
                    rm -f "${dst}"
                    return 1
                else
                    warn "The file downloaded was HTML - could be a file-not-found error"
                    echo_return "${dst}"
                    return 0
                fi
            else
                msg "Successfully downloaded ${src}"
                echo_return "${dst}"
            fi
        else
            err "Failed downloading ${src}"
            rm -f "${dst}"
        fi
    elif [[ "${src:0:1}" == "/" && "${src}" != "${dst}" ]]
    then
        ln -s "${selected}" "${dst}"
        echo_return "${dst}"
    else
        err "I do not know how to obtain '${src}'"
    fi
}

function require_docker()
{
    if ! command_is_available docker
    then
        err "Docker is not available - perhaps it is not installed"
        return 1
    fi
}

function load_container_file()
{
    local name="${1}"

    require_docker || return 1

    msg "Checking docker status"
    if ! systemctl status docker
    then 
        err "Docker failed to start"
        return 1
    fi

    local image_file=$(obtain_bundled_file "docker/${name}" "/e/bundled")
    if [[ -z "${image_file}" ]]
    then 
        return 1
    fi
    msg "Load nexus container ${image_file}"
    docker load -i "${image_file}"
}

function load_nexus_container()
{
    sonatype_version="3.13.0"
    if [[ -n "${BUNDLED_SRC}" ]]
    then 
        load_container_file "sonatype_nexus3__${sonatype_version}.tar"
    else
        docker pull "sonatype/nexus3:${sonatype_version}"
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
    if is_docker
    then
        msg "No sysctl setup for docker build"
    else
        sysctl --system
    fi
}

function prepare_nexus_service()
{
    echo_stage 3 "Preparing nexus user and service"
    cp "${SS_DIR}"/provision/common/inc/nexus-mirror.service /etc/systemd/system/
    groupadd -g 200 nexus
    useradd -r -d /d/local/data/nexus -u 200 -g 200 nexus
    chown -R nexus.nexus /d/local/data/nexus/
    systemctl enable nexus-mirror.service
    # NOTE the service is not started yet
}

function patch_hostfile_for_nexus()
{
    echo_stage 4 "Patch hostfile for nexus in standalone instance."
    sed -i -r -e 's/[[:space:]]nexus($|[[:space:]]|[.][^[:space:]]+)/ /g' /etc/hosts
    msg "Result:"
    cat /etc/hosts 1>&2
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
    msg "Result:"
    cat /etc/hosts 1>&2
}

function start_nexus()
{
    if docker ps | egrep nexus-mirror && docker logs nexus-mirror | egrep -i 'Started Sonatype Nexus' 
    then
        notice "Nexus appears to already be running"
        return 0
    fi

    msg "Starting nexus service"
    if systemctl start nexus-mirror.service
    then
        msg "Wait for nexus mirror startup"
        sleep 30 
        if docker ps | egrep nexus-mirror
        then 
            max_wait=600
            while ! docker logs --since=10s nexus-mirror | egrep -i 'Started Sonatype Nexus' 
            do
                msg "Still waiting for Nexus to recreate its database and finish starting up."
                sleep 5
                ((max_wait-=5))
                if [[ "${max_wait}" -le 0 ]]
                then
                    warn "Timed out - Nexus took too long to start. Something probably went wrong." 
                    return 1
                fi
                notice "Waiting a max of ${max_wait} seconds longer"
            done
            msg "Nexus appears to have completed startup"
        else 
            err "Nexus appears to have failed to start"
            return 1
        fi
    else 
        err "Starting nexus failed"
        return 1
    fi 
}

function prepare_docker_for_nexus()
{
    local infra_ip=$(egrep "[[:space:]]infra.${DOMAIN}" /etc/hosts | head -n1 | awk '{print $1}')
    local substitute_localhost="s/^127.0.0.1\$/${infra_ip}/"
    local nameservers=( $(grep nameserver /etc/resolv.conf | awk '{print $2}' | sed -r -e "${substitute_localhost}") )
    local searchdomains=( $(grep search /etc/resolv.conf | cut -d' ' -f2-) ) 
    # TODO - get this from boot config
    local x
    local build
    local registries=( ${DOCKER_REGISTRIES//,/ } )
    mkdir -p /etc/docker
    pairs_to_json \
        "dns" "$(array_to_json "${nameservers[@]}")" \
        "dns-search" "$(array_to_json "${searchdomains[@]}")" \
        "insecure-registries" "$(array_to_json "${registries[@]}")" \
        > /etc/docker/daemon.json
}

function configure_standalone_server()
{
    import_gpgkeys 

    if [[ -n "${BUNDLED_SRC}" ]]
    then
        copy_bundled_files
    fi

    echo_stage 5 "Docker"
    {
        prepare_network_for_docker
        prepare_docker_for_nexus
    } | indent 

    # We prefer to use docker community edition, although unfortunately it 
    # does not support the ability to block the default registry, for operation in a standalone network
    if ls /etc/yum.repos.d | egrep -q 'docker.*ce' 
    then 
        rpm -qa | grep docker-ce || yum -y --enablerepo='*' install docker-ce
    else
        ensure_installed docker
    fi

    is_docker || replace_firewall

    if [[ -n "${BUNDLED_SRC}" ]]
    then
        restore_nexus_data
    fi

    is_docker || configure_standalone_network 

    if [[ -n "${BUNDLED_SRC}" ]]
    then
        # patch_hostfile_for_nexus

        if ! require_docker
        then
            warn "Nexus cannot be provisioned without docker - skipping"
            return 1
        fi

        if ! docker ps | grep -q nexus-mirror 
        then 
            if start_docker
            then
                load_nexus_container
            else
                err "Docker seems to have failed to start"
                return 1
            fi

            prepare_nexus_service

        fi
    fi
}

function switchover_to_nexus()
{
    if start_nexus 
    then 
        msg "Disabling old yum repos and switching over to nexus bootstrap repos"
        mv -f /etc/yum.repos.d/*repo /etc/yum.repos.d/disable/
        /bin/cp -f "${SS_DIR}"/provision/common/inc/bootstrap-centos.repo /etc/yum.repos.d/
        yum makecache
    else 
        notice "Skipping yum repo switchover because nexus is not available"
    fi
}
