#!/bin/bash

[[ -n "${SS_LOADED_COMMON_LIB}" ]] || . /soestack/provision/common/lib/lib.sh

function install_development_tools()
{
    echo_start 
    if is_development
    then
        ensure_installed \
            net-tools iproute nano vim-enhanced  \
            htop diffutils gpm psmisc bind-utils \
            iputils iproute diffutils procps-ng psmisc nmap-ncat \
            jq rpm-build jnettop axel perl-autodie alpine mutt git \
            nfs-utils pciutils mlocate rsync xclock xterm telnet \
            nmap socat msr-tools qemu-guest-agent 
    fi

    ensure_installed gpm
    systemctl enable gpm
    systemctl start gpm 
    echo_done
}

function ssh_alternate_port()
{
    local port="${1:-22}"

    if [[ "${port}" != "22" ]]
    then
        for p in policycoreutils-python policycoreutils-python-utils 
        do 
            if yum search "${p}" 2> /dev/null | egrep "${p}([[:space:]]|$)"
            then 
                ensure_installed "${p}"
            fi
        done
        sed -i \
            -e "/Port 22/ s/.*/Port ${port}/" \
            /etc/ssh/sshd_config
        if ! semanage port -l | egrep "ssh_port_t.*${port}:" 
        then 
            semanage port -a -t ssh_port_t -p tcp "${port}"
            iptables -I INPUT 1 -p tcp -m state --state NEW -m tcp --dport "${port}" -j ACCEPT
        fi
    fi
}

# Enable ssh on a nonstandard port during dev
function enable_ssh_during_development()
{
    if is_development
    then
        sed -i \
            -e '/ListenAddress/ s/.*/ListenAddress 0.0.0.0/' \
            /etc/ssh/sshd_config
        # ssh_alternate_port 9999
        systemctl restart sshd
        iptables -I INPUT 1 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
    fi
}

function successful_provision()
{
    systemctl disable soestack-provision
}

function failed_provision()
{
    systemctl disable soestack-provision
    err "system service soestack-provision has run but failed."
    err "To retry, manually run /soestack/provision/common/provision.sh"
}

function provision_client()
{
    add_hosts
    add_nameserver
    bootstrap_repos
}

function provision_common_early()
{
    configure_timezone
    
    setup_root_ssh
    
    configure_yum
}

function provision_common_middle()
{
    install_utils
    fix_bootflags

    msg "Starting soestack provision at date $(date)"
    install_development_tools 2>&1 | indent

    replace_firewall

    yum makecache
}

function soestack_provision()
{
    provision_common_early

    if [[ -n "${STANDALONE}" ]] && (( STANDALONE ))
    then
        provision_standalone
    else
        provision_client
    fi 

    provision_common_middle

    . /soestack/provision/common/lib/lib-salt.sh

    local salt_failed
    provision_salt
    salt_failed=$?

    local nexus_failed=0
    if [[ -n "${STANDALONE}" ]] && (( STANDALONE ))
    then
        switchover_to_nexus
        nexus_failed=$?
    fi 

    if (( nexus_failed))
    then
        err "Skipping further provisioning since nexus setup failed."
        err "Done."
        failed_provision
    elif (( salt_failed ))
    then 
        err "Skipping salt state provision since salt setup failed."
        err "Done."
        failed_provision
    else
        run_salt_state_provision "${ROLES}"
        msg "Done."
        successful_provision
    fi 

}

function replace_firewall()
{
    msg "Replacing firewall"
    {
        ensure_installed iptables-services
        systemctl disable firewalld
        systemctl enable iptables
        iptables -F
        systemctl start iptables   
        msg "Firewall:"
        iptables -nvL
        enable_ssh_during_development
    } 2>&1 | indent
}

function fix_bootflags()
{
    #sed -i -r 's/(rhgb|quiet//g' /etc/default/grub
    #sed -i -r 's/(quiet)//g' /etc/default/grub
    #sed -i -r 's/(rhgb)//g' /etc/default/grub

    local additions="rd.shell rd.shell=1 net.ifnames=0 biosdevname=0"
    if ! grep -q "${additions}" /etc/default/grub 
    then 
        sed -i -r 's/=en_US/=en_AU/g' /etc/default/grub
        sed -i -r 's/ quiet/ /g' /etc/default/grub

        sed -i -r "/GRUB_CMDLINE_LINUX/ s/[\"]/ ${additions}\"/" /boot/grub2/grub.cfg

        grub2-mkconfig -o /boot/grub2/grub.cfg
        
        if command -v plymouth-set-default-theme 2> /dev/null
        then
            msg "Rebuilding plymouth initrd"
            plymouth-set-default-theme details --rebuild-initrd 2>&1 | indent
        fi
    fi 
}

function disable_repos()
{
    local prefix
    for prefix in "${@}"
    do
        msg "Disable '${prefix}' repos"
        mkdir -p /etc/yum.repos.d/disable
        if ( cd /etc/yum.repos.d/ && ls | egrep -q "^${prefix}.*[.]repo")
        then
            mv -f "/etc/yum.repos.d/${prefix}"*.repo /etc/yum.repos.d/disable/
        fi
    done
    msg "done"
}

function import_gpgkeys()
{
    msg "Importing GPG keys"
    local f
    for f in /soestack/provision/common/inc/gpgkeys/* 
    do
        msg "Import ${f}"
        rpm --import "${f}"
        msg "  ... done."
    done
    msg "Done."
}

function bootstrap_repos()
{
    msg "Bootstrap repos."

    import_gpgkeys

    if [[ -n "${BOOTSTRAP_REPOS}" ]]
    then
        disable_repos ""
        local f
        for f in ${BOOTSTRAP_REPOS//,/ }
        do
            try="/soestack/provision/common/inc/${f}"
            if [[ -f "${try}" ]]
            then
                /bin/cp -f "${try}" /etc/yum.repos.d/
            fi 
        done
        yum makecache
    else
        msg "No BOOTSTRAP_REPOS defined. Preconfigured OS repos will be used."
    fi
}

function configure_soestack_provision()
{
    msg "Configure soestack postinstall provisioning"
    /bin/cp -f /soestack/provision/common/inc/soestack-provision.service /etc/systemd/system/
    chmod a-x  /etc/systemd/system/soestack-provision.service
    chmod a+rx /soestack/provision/*/*.sh
    chmod a+rx /soestack/provision/*/lib/*.sh
    systemctl enable soestack-provision
    msg "Done."
}

function yum_setting()
{
    local varname="${1}"
    local varval="${2}"
    local regex="^${varname}="
    local line="${varname}=${varval}"
    local f=/etc/yum.conf
    if ! ( egrep "${regex}" "${f}" | grep -qF "${line}" )
    then
        msg "Delete yum setting '${varname}' : " "$(egrep "${regex}" "${f}" | tr '\n' ' ')"
        sed -i "/${regex}/ d" "${f}"
        msg "Add yum setting ${line}"
        msg "${line}" >> "${f}"
    fi
}


# Determine a new value for the yum $releasevar variable.
# This is used so that we access RPM packages in a repo by (for example)
# the 7.6 directory instead of just 7
# (or in the case of centos, 7.6.1810 instead of just 7).
function modify_specific_yum_releasever()
{
    local pkg=$(egrep -i distroverpkg /etc/yum.conf | cut -d= -f2)
    local ver=$(rpm -q --queryformat='%{version}' "${pkg}")
    local release=$(rpm -q --queryformat='%{release}' "${pkg}")
    local -a v=( ${ver//./ } ${release//./ })
    
    local releasever="${ver}"
    local releaseshort="${ver}"
    local releaselong="${ver}"

    case "${OS_NAME}" in
        centos)
            releaselong="${v[0]}.${v[1]}.${v[2]}"
            ;;
        redhat)
            releaselong="${v[0]}.${v[1]}"
            ;;
    esac

    echo_data "${releaselong}" > /etc/yum/vars/releaselong
    echo_data "${releaseshort}" > /etc/yum/vars/releaseshort

}

function configure_yum_bundled_var()
{
    local var_file="/etc/yum/vars/bundled"

    if [[ ! -f "${var_file}" ]]
    then
        local bundled_url=""

        case "${BUNDLED_SRC}" in
            http:*)
                bundled_url="${BUNDLED_SRC}"
                ;;
            /*)
                bundled_url="file://${BUNDLED_SRC}"
                ;;
            "")
                bundled_url="file:///e/bundled"
                ;;
            *)
                err "Unrecognised or unsupported BUNDLED_SRC value."
                return 1
                ;;
        esac

        echo_data "${bundled_url}" > "${var_file}"
    fi
}

function configure_yum()
{
    yum_setting minrate 1
    yum_setting timeout $((60*100))
    yum_setting keepcache 1
    yum_setting fastestmirror 0
    yum_setting ip_resolve 4
    yum_setting deltarpm 0
    
    configure_yum_bundled_var
    modify_specific_yum_releasever

    sed -i '/enabled=/ s/=1/=0/' /etc/yum/pluginconf.d/fastestmirror.conf
}

function setup_root_ssh()
{
    # Set up ssh for root
    [[ -f /root/.ssh/id_rsa ]] || ssh-keygen -t rsa -q -N "" -f /root/.ssh/id_rsa 

    # Allow root login via ssh
    if ! grep '^PermitRootLogin yes/' /etc/ssh/sshd_config 
    then
        sed -i '/#PermitRootLogin/ s/.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        systemctl reload sshd
    fi
}

function configure_timezone()
{
    local tz="${TIMEZONE:-UTC}"

    ln -sf "/usr/share/zoneinfo/${tz}" /etc/localtime
    echo_data "TZ=${tz}" > /etc/profile.d/timezone.sh
    . /etc/profile.d/timezone.sh
}

function preconfigure_pip()
{
    {
        echo_data "[global]"
        echo_data "index http://nexus:7081/repository/pypi/pypi"
        echo_data "index-url http://nexus:7081/repository/pypi/simple"
        echo_data "trusted-host = nexus"
    } >> /etc/pip.conf 
}

function with_low_tcp_time_wait()
{
    echo_data "1" > /proc/sys/net/ipv4/tcp_fin_timeout
    "${@}"
    sleep 1
    echo_data "60" > /proc/sys/net/ipv4/tcp_fin_timeout
}

function provision_standalone()
{
    . /soestack/provision/common/lib/lib-standalone.sh

    add_hosts
    add_nameserver # nameserver needs to be configured before docker is installed and started
    
    if [[ "${BUNDLED_SRC}" ]]
    then
        disable_repos CentOS
    else 
        # regardless, disable Source, Debuginfo , Vault repos
        disable_repos 'CentOS-Sources' 'CentOS-Vault' 'CentOS-fasttrack' 'CentOS-Debuginfo' 'CentOS-CR'
        disable_repos 'CentOS-Media'
    fi

    configure_standalone_server
}
