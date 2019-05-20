#!/bin/bash
# This file runs in the install environment with the destination system
# mounted at /mnt/sysimage

. /soestack/provision/kickstart/lib/lib.sh

function copy_files()
{
    local dst_dir="${ANA_INSTALL_PATH}/${2}"
    echo "Copy install system ${1} to ${dst_dir}/"
    mkdir -p "${dst_dir}"
    cp -a ${1} "${dst_dir}/"
}

function copy_logs()
{
    echo "Copy logs"
    copy_files "/tmp/*" "/var/log/provision/tmpdir/"
    echo "Done copying logs"

    echo "Copying provisioning ss dir for troubleshooting"
    copy_files "/etc/ss/*" "/var/log/provision/etc-ss"
    echo "Done copying provisioning ss dir"
}

function copy_ss_provisioning()
{
    echo "Copy ss kickstarts to installed system"
    copy_files "/soestack/provision" "/soestack"
    copy_files "${SS_GEN}/*" "${SS_GEN}"
    ls -lR "${ANA_INSTALL_PATH}/soestack/provision"
    echo "Completed copying ss kickstarts and ss config."
}

function determine_ip()
{
    ip a | grep 'inet '| grep -v 127.0.0 | sed 's/^[ ]*//' | tr  '/ ' ':' | cut -d: -f2
}

function configure_hostname()
{
    echo "Configuring hostname from dhcp and predfined vars."
    local host=""
    local domain=""
    
    if [[ -n "${DOMAIN}" ]]
    then
        domain="${DOMAIN}"
    fi

    if [[ -n "${HOSTNAME}" ]]
    then
        host="${HOSTNAME}"
    fi

    if [[ -z "${host}${domain}" ]]
    then
        domain="soestack"
        host="unset.${domain}"
    elif [[ -z "${host}" ]]
    then
        host="unset.${domain}"
    elif [[ -z "${domain}" ]]
    then
        if [[ "${host}" =~ [.] ]]
        then
            domain="${host#*.}"
        else
            domain="soestack"
            host="${host}.${domain}"
        fi
    else
        if [[ "${host}" =~ [.]${domain} ]]
        then
            echo "Hostname is already configured appropriately"
        else
            host="${host}.${domain}"
        fi
    fi
   
    echo "${host}" > "${ANA_INSTALL_PATH}/etc/hostname"

    hostname "${host}"

    local ip=$(determine_ip)
    if [[ -n "${ip}" ]]
    then
        grep "${host}" /etc/hosts || echo "${ip} ${host}" >> "${ANA_INSTALL_PATH}/etc/hosts"
    fi

    echo "Hostname configured as ${host}"
}

#
# Copy files from the USB image to the installed system.
#  Place the files in a 'bundled' subdirectory
#  Place a bundled.properties file with instructions on
#   the dir to copy and the destionation.

#  Example file placement and 
#  on the usb stick (/run/install/repo)
#      files:
#      /run/install/repo/bundled/soe/...
#      /run/install/repo/bundled/nexus/db-backup/...
#      /run/install/repo/bundled/nexus/blobs/...
#      /run/install/repo/bundled/git-repos/
#      /run/install/repo/bundled.properties
#  Example bundled.properties syntax
#    version 1
#    copy soe as /srv/soestack/soe
#    copy ipa-backup.tar into /d/local/data/ipa/
#    copy nexus-data/db-backup as /d/local/data/nexus/restore-from-backup
#    copy nexus-data/blobs as /d/local/data/nexus/blobs
#    copy gitlab/repos as /d/local/data/gitlab/git-data
#    copy gitlab/backup as /d/local/data/gitlab/backups
#    copy grafana/backup as /d/local/data/grafana/backups


function create_installmedia_repo()
{
    local pkg_dst="/e/yum-repos/installmedia"
    local pkg_dir="${ANA_INSTALL_PATH}${pkg_dst}"
    local iso_dir="${ANA_INSTALL_PATH}${iso_dst}"
    local repos_dir="${ANA_INSTALL_PATH}/etc/yum.repos.d"
    local disable_dir="${repos_dir}/disable"
    local bootstrap_repo="${repos_dir}/bootstrap-centos.repo"

    {
        echo "[installmedia]"
        echo "name=installmedia"
        echo "baseurl=file://${pkg_dst}"
        echo "enabled=1"
        echo "gpgcheck=1"
    } > "${repos_dir}/installmedia.repo"

    mkdir -p "${disable_dir}"
    [[ -f "${bootstrap_repo}" ]] && mv -f "${bootstrap_repo}" "${disable_dir}/"

    if [[ -z "${ANA_INSTALL_PATH}" ]]
    then
        yum makecache
    fi
}

function copy_isopackages()
{
    # This is used on an initial server USB build
    local pkg_dst="${ANA_INSTALL_PATH}/e/yum-repos/installmedia"
    mkdir -p "${pkg_dst}"

    (
        cd /run/install/repo
        # TODO - update for RHEL8 which has Base and AppStream subdirs with a repodata in each
        [[ -d "Packages" && -d "repodata" ]] && cp -a {Packages,repodata} "${pkg_dst}/"
    ) 

}

function copy_isos()
{
    local iso_dir="/e/isos"
    local pkg_dir="/e/yum-repos/installmedia"
    local iso_src="/run/install/repo/isos"
    local pkg_dst="${ANA_INSTALL_PATH}${pkg_dir}"
    local iso_dst="${ANA_INSTALL_PATH}${iso_dir}"

    mkdir -p "${iso_dst}"
    if [[ ! -d "${iso_src}" ]]
    then
        echo "WARNING: No isos dir at ${iso_src}!"
        return 1
    fi
    local -a iso_files=( "${iso_src}"/*.iso )
    local -a preferred_sequence=( Everything DVD Minimal )

    if ! (( ${#iso_files[@]} ))
    then
        echo "WARNING: No isos found within ${iso_src}"
        ls -l "${iso_src}"
        return 1
    fi

    local selected_iso=""
    local iso_file=""
    local name=""
    local copy_all=0

    for name in "${preferred_sequence[@]}"
    do
        for iso_file in "${iso_files[@]}"
        do
            [[ "${iso_file}" =~ -${name}- ]] && selected_iso="${iso_file}"
        done
        [[ -n "${selected_iso}" ]] && break 
    done

    for iso_file in "${iso_files[@]}"
    do
        if (( copy_all )) || [[ "${iso_file}" == "${selected_iso}" ]]
        then
            echo "Copy ${iso_file} to ${iso_dst}"
            cp "${iso_file}" "${iso_dst}/"
        fi 
    done

    if [[ -n "${selected_iso}" ]]
    then
        echo "Found ${selected_iso} - configuring mount."
        echo "${iso_dir}/${selected_iso##*/} ${pkg_dir} auto defaults,ro,loop,auto,nofail 0 0 " >> "${ANA_INSTALL_PATH}/etc/fstab"
    else
        echo "WARNING: Could not find a recognised iso file. Packages will need to be copied instead."
    fi
}

function copy_bundled_data()
{
    echo "Copying bundled data.."
    #cp /lib/anaconda-lib.sh /mnt/sysimage/

    # TODO - use /run/install/repo path from anaconda lib, not hard coded.
    local bundled_src="/run/install/repo/bundled"
    local bundled_dir="/e/bundled"
    local bundled_dst="${ANA_INSTALL_PATH}${bundled_dir}"
    
    # NOTE this is copying the entire bundled dir
    if [[ -d "${bundled_src}" ]]
    then
        cp -a "${bundled_src}" "${bundled_dst}"
        echo "Done copying bundled data from '${bundled_src}' to '${bundled_dst}'"
    else
        echo "No bundled data dir was found."
        echo "Looked for it at ${bundled_src}:"
        ls -al "${bundled_src}"
    fi
}
