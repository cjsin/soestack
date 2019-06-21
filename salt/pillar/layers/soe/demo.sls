# Overrides for the demo test soe

_loaded:
    {{sls}}:

soe:
    name:         soestack-demo
    description:  Example soe implementation using vagrant

# The remaining items are in alphabetical order

build:

    rpm:

        python37:
            package_url:       https://www.python.org
            subdir:            Python-VERSION
            configure_flags:   --enable-optimizations --with-ensurepip=upgrade CFLAGS=-Wno-error=coverage-mismatch
            install_flags:     altinstall DESTDIR=${DESTDIR}
            source_url:        http://nexus:7081/repository/interwebs/www.python.org/ftp/python/VERSION/Python-VERSION.tar.xz

            rpm_version:       1

            required_packages:
                - openssl-devel
                - valgrind-devel 
                - ncurses-devel
                - gdbm-devel 
                - sqlite-devel
                - readline-devel
                - xz-devel
                - zlib-devel 
                # need libuuid-devel and must not have uuid-devel installed (they both provide conflicting headers)
                - libuuid-devel
                - libffi-devel
                - bzip2-devel
                - tcl-devel
                - tk-devel

email:
    aliases:
        root: devuser

filesystem:
    dirs:
        common:
            /d:
                description:     Data storage area

            /d/local:
                description:     Data storage area for local data

            /var/log/everything: 
                mode:            '0750'
                description:     Logs split by day

        # TODO - move this instead into a role layer
        by-role:
            primary-server-node:
                /e:
                    description: Top directory for nfs exports
                    export:
                        0-toplevel:
                            # The insecure option allows ports over 1024.
                            # This is required when developing with virtual machines because
                            # the virtual network performs NAT and low port numbers are 
                            # shifted up above 1024. This results in the NFS server denying
                            # access, unless this opt is added. This won't be needed when
                            # deployed on real hardware.
                            '*':              ro,async,root_squash,insecure,fsid=0
                            '192.168.121.*':  rw,async,insecure,fsid=0
                            '10.0.2.*':       rw,async,insecure,fsid=0

                /e/home:
                    user: root
                    group: root
                    mode: '0755'
                    mkdirs: True
                    description: Export home directories for clients
                    export:
                        1-home:
                            - '*':       rw,async,root_squash,insecure
                    bind:
                        dev:       /home
                        readwrite: True

                /e/pxe:
                    user: root
                    group: root
                    mode: '0755'
                    mkdirs: True
                    description: Exports for pxe booting
                    export:
                        1-pxe:
                            - '*':       ro,async,insecure,root_squash,nohide,no_subtree_check


                /e/pxe/os/dvd:
                    user:  root
                    group: root
                    mode: '0775'
                    mkdirs: True
                    description: Exports for installing pxe clients from dvd image
                    export:
                        1-pxe-dvd:
                            - '*':       ro,async,insecure,root_squash,nohide,no_subtree_check

                /e/pxe/os/minimal:
                    user:  root
                    group: root
                    mode: '0775'
                    mkdirs: True
                    description: Exports for installing pxe clients from minimal image
                    export:
                        1-pxe-minimal:
                            - '*':       ro,async,insecure,root_squash,nohide,no_subtree_check

                /home:
                    description: Home directories

                /var/log/clients: 
                    mode:        '0750'
                    description: Client logs split by day

installed_scripts:
    local-bin:
        from:  salt://scripts
        to:    /usr/local/bin
        mode:  '0755'
        common:
            - uuid4
            - yum-refresh

# This data is not used yet but I am just recording the
# configuration which is performed, so it can be automated
# later.
ipa-configuration:
    automounts:
        maps:
            auto.home: 
                type: direct
                keys:
                    '*': '-fstype=nfs4 infra:/home/&'

issue: |
    Welcome to the SoeStack example soe

motd: |
    Welcome to the SoeStack example soe

network:
    # demo virtual network
    subnet:  192.168.121/24
    netmask: 255.255.255.0
    prefix:  24

    hostfile-additions: {}
    
    devices: {}

    classes:
        defaults:
            sysconfig:
                # Note the values 'yes', 'no' and 'none' need to be quoted when using yaml
                PEERDNS: 'no'
                BOOTPROTO: 'none'
                PEERROUTES: 'no'
                DEFROUTE: 'no'
                PROXY_METHOD: 'none'
                BROWSER_ONLY: 'no'
                IPV4_FAILURE_FATAL: 'no'
                IPV6INIT: 'no'
                IPV6_AUTOCONF: 'no'
                IPV6_DEFROUTE: 'no'
                IPV6_FAILURE_FATAL: 'no'
                IPV6_ADDR_GEN_MODE: 'stable-privacy'
                NM_CONTROLLED: 'no'

        peerdns:
            sysconfig:
                # Note the values 'yes', 'no' and 'none' need to be quoted when using yaml
                PEERDNS: 'yes'
                PEERROUTES: 'yes'

        no-peerdns:
            sysconfig:
                # Note the values 'yes', 'no' and 'none' need to be quoted when using yaml
                PEERDNS: 'no'
                PEERROUTES: 'no'

        no-ipv6:
            sysconfig:
                IPV6INIT: 'no'
                IPV6_AUTOCONF: 'no'
                IPV6_DEFROUTE: 'no'
                IPV6_FAILURE_FATAL: 'no'
                IPV6_ADDR_GEN_MODE: 'stable-privacy'
        
        nm-controlled:
            sysconfig:
                NM_CONTROLLED: 'yes'

        no-nm-controlled:
            sysconfig:
                NM_CONTROLLED: 'no'

        ignored:
            ignored: True

        delete:
            delete: True

        ethernet:
            sysconfig:
                TYPE: Ethernet

        enabled:
            sysconfig:
                ONBOOT: 'yes'

        disabled:
            sysconfig:
                ONBOOT: 'no'

        defroute:
            sysconfig:
                DEFROUTE: 'yes'

        no-defroute:
            sysconfig:
                DEFROUTE: 'no'

        dhcp:
            sysconfig:
                BOOTPROTO: 'dhcp'
                PERSISTENT_DHCLIENT: 'yes'

        no-dhcp:
            sysconfig:
                BOOTPROTO: 'none'

        # Zeroconf routing is responsible for the 169.254.0.0 route that gets added
        zeroconf:
            sysconfig:
                NOZEROCONF: 'no'

        no-zeroconf:
            sysconfig:
                NOZEROCONF: 'yes'

        wireless:
            sysconfig:
                TYPE:     'Wireless'
                WPA:      'yes'
                KEY_MGMT: 'WPA-PSK'
                MODE:     'Managed'
            wpaconfig: {}

# NOTE - while this key houses nexus configuration,
# the separate key nexus-repos (above) selects which 
# repositories are selected for particular hosts.
nexus:

    http_address:   nexus:7081
    docker_address: nexus:7082

    urls:
        centos:          http://nexus:7081/repository/centos
        docker:          nexus:7082
        dockerce:        http://nexus:7081/repository/dockerce
        epel:            http://nexus:7081/repository/epel
        fedora:          http://nexus:7081/repository/dl-fedora
        github:          http://nexus:7081/repository/github
        gitlab:          http://nexus:7081/repository/gitlab
        grafana:         http://nexus:7081/repository/grafana
        ius:             http://nexus:7081/repository/ius
        nodesource:      http://nexus:7081/repository/nodesource
        npmjs:           http://nexus:7081/repository/npmjs
        pypi:            http://nexus:7081/repository/pypi
        rpmfusion:       http://nexus:7081/repository/rpmfusion
        saltstack:       http://nexus:7081/repository/saltstack
        kubernetes:      http://nexus:7081/repository/kubernetes 
        vscode:          http://nexus:7081/repository/vscode
        elasticsearch:   http://nexus:7081/repository/elasticsearch
        elastic-docker:  http://nexus:7081/repository/elastic-docker
        #elastic-docker: nexus:7082
        rubygems:        http://nexus:7081/repository/rubygems
        interwebs:       http://nexus:7081/repository/interwebs
        built-rpms:      http://nexus:7081/repository/built-rpms
        google-storage:  http://nexus:7081/repository/google-storage

    blobstores:
        dockerhub:
        dockerce:
        fedora-dl:
        nodesource:
        npmjs:
        pypi:
        rpmfusion:
        microsoft:
        elasticsearch:
        elastic-docker:
        rubygems:
        interwebs:
        built-rpms:

    repos:

        built-rpms:
            type:           hosted
            format:         yum
            blobstore:      built-rpms
            repodata_depth: 2
            deploy_policy:  Permissive
            yum:
                centos:
                    enabled: 1
                    repos:
                        built-rpms:
                            description: Packages built for this SOE
                            path:        soestack/demo/

        centos:
            type:           proxy
            format:         yum
            blobstore:      centos
            remote_url:     http://mirror.centos.org/
            yum:
                centos:
                    gpgkey_url:  http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-$releasever
                    enabled:     1
                    gpgcheck:    1
                    gpgkey:      RPM-GPG-KEY-CentOS-7
                    repos:
                        os:
                            description: Centos $releaselong - $basearch
                            path:        centos/$releaselong/os/$basearch

                        updates:
                            description: Centos $releaselong - $basearch - Updates
                            path:        centos/$releaselong/updates/$basearch
                        
                        # extras repo is needed for container-selinux
                        centos-extras:
                            description: Centos $releaselong - $basearch - Extras
                            path:        centos/$releaselong/extras/$basearch

                        centos-plus:
                            description: Centos $releaselong - $basearch - Plus
                            path:        centos/$releaselong/centosplus/$basearch
                            enabled:     0

        dockerhub:
            type:           proxy
            format:         docker
            blobstore:      dockerhub
            remote_url:     https://registry-1.docker.io/
            docker:
                # Note this port is 8082 within the container, 7082 on the host
                http_connector: 8082
                docker_index:   'Use Docker Hub'
                enable_v1_api:  True
                force_basic_authentication: 'unchecked'

        dockerce:
            type:           proxy
            format:         yum
            blobstore:      dockerce
            remote_url:     https://download.docker.com/
            yum:
                fedora:
                    gpgkey_url:  https://download.docker.com/linux/fedora/gpg
                    enabled:     1
                    gpgcheck:    1
                    gpgkey:      RPM-GPG-KEY-DOCKERCE-fedora
                    repos:
                        dockerce:
                            description: Docker CE Stable - $basearch
                            path:        linux/fedora/$releasever/$basearch/stable

                        dockerce-edge:
                            description: Docker CE Edge - $basearch
                            path:        linux/fedora/$releasever/$basearch/edge
                            enabled:     0

                centos:
                    gpgkey_url:  https://download.docker.com/linux/centos/gpg
                    enabled:     1
                    gpgcheck:    1
                    gpgkey:      RPM-GPG-KEY-DOCKERCE-centos
                    repos:
                        dockerce:
                            description: Docker CE Stable - $basearch
                            path:        linux/centos/$releasever/$basearch/stable

                        dockerce-edge:
                            description: Docker CE Edge - $basearch
                            path:        linux/centos/$releasever/$basearch/edge
                            enabled:     0

        fedora:
            type:           proxy
            format:         yum
            blobstore:      fedora-dl
            remote_url:     https://dl.fedoraproject.org/
            yum:
                fedora:
                    gpgkey_url: https://getfedora.org/static/9DB62FB1.txt
                    gpgkey:     RPM-GPG-KEY-fedora-28-x86_64
                    enabled:    1
                    gpgcheck:   1
                    repos:
                        os:
                            description: Fedora $releasever - $basearch
                            path:        pub/fedora/linux/releases/$releasever/Everything/$basearch/os

                        updates:
                            description: Fedora $releasever - $basearch - Updates
                            path:        pub/fedora/linux/updates/$releasever/Everything/$basearch

        elastic-docker:
            type:           proxy
            format:         docker
            blobstore:      elastic-docker
            remote_url:     https://docker.elastic.co/
            docker:
                # Note this port is 8082 within the container, 7082 on the host
                http_connector: 8083
                docker_index:   'Use proxy registry' #'Use Docker Hub'
                enable_v1_api:  True
                force_basic_authentication: 'unchecked'

        elasticsearch:
            type:           proxy
            format:         raw
            blobstore:      elasticsearch
            remote_url:     https://artifacts.elastic.co/
                            #downloads/elasticsearch/elasticsearch-6.4.0.rpm


        # The online EPEL repos switched to using 'zchunk' metadata, and nexus
        # currently does not support that, so nexus is incapable of proxying for EPEL now.
        # see Sonatype issue tracker bug url: https://issues.sonatype.org/browse/NEXUS-20078
        #
        #epel:
        #    type:           proxy
        #    format:         yum
        #    blobstore:      epel
        #    remote_url:     https://dl.fedoraproject.org/
        #    yum:
        #        centos:
        #            enabled:     1
        #            gpgcheck:    1
        #            gpgkey_url:  https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-$releasever
        #            gpgkey:      RPM-GPG-KEY-EPEL-7
        #            repos:
        #                epel:
        #                    description: EPEL for Centos $releasever
        #                    path:        pub/epel/$releasever/$basearch

        github:
            type:                proxy
            format:              raw
            blobstore:           raw
            remote_url:          http://github.com/

        google-storage:
            type:                proxy
            format:              raw
            blobstore:           raw
            remote_url:          https://storage.googleapis.com/

        gitlab:
            type:                proxy
            format:              yum
            blobstore:           gitlab
            remote_url:          https://packages.gitlab.com/
            yum:
                gpgkey_url:      https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
                gpgkey:          gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
                enabled:         1
                gpgcheck:        1
                centos:
                    repos:
                        gitlab-ce:
                            description: "Gitlab Community Edition"
                            path:        gitlab/gitlab-ce/el/$releasever/$basearch
                        gitlab-runner:
                            description: "Gitlab Community Edition - runner"
                            path:        runner/gitlab-runner/el/$releasever/$basearch
                # fedora:
                #     repos:
                #         gitlab-ce:
                #             description: "Gitlab Community Edition"
                #             path:        gitlab/gitlab-ce/fedora/$releasever/$basearch
                #         gitlab-runner:
                #             description: "Gitlab Community Edition - runner"
                #             path:        runner/gitlab-runner/fedora/$releasever/$basearch
        
        grafana:
            type:                proxy
            format:              raw
            blobstore:           raw
            remote_url:          https://s3-us-west-2.amazonaws.com/

        # The "Inline with Upstream Stable" repos
        ius:
            type:           proxy
            format:         yum
            blobstore:      ius
            remote_url:     https://dl.iuscommunity.org/
            yum:
                centos:
                    # IUS repo is explicitly disabled because its packages
                    # have upgrades that cause issues with the IPA server installation.
                    # However we will enable it later for git package installation.
                    enabled:     0
                    gpgcheck:    1
                    gpgkey:      IUS-COMMUNITY-GPG-KEY
                    gpgkey_url:  https://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY
                    repos:
                        ius:
                            description: IUS for Centos $releasever
                            path:        pub/ius/stable/CentOS/$releasever/$basearch

        kubernetes:
            type:           proxy
            format:         yum
            remote_url:     https://packages.cloud.google.com/
            blobstore:      google
            yum:
                enabled:    1
                gpgcheck:   1
                # gpgkey_url:  https://packages.cloud.google.com/yum/doc/yum-key.gpg 
                gpgkey_url:  https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
                gpgkey:     RPM-GPG-KEY-GOOGLE-CLOUD-PACKAGES
                centos,fedora,rhel:
                    repos:
                        kubernetes:
                            description: Kubernetes packages for RedHat family of operating systems
                            path:        yum/repos/kubernetes-el$releasever-$basearch

        nodesource:
            type:           proxy
            format:         yum
            remote_url:     https://rpm.nodesource.com/
            blobstore:      nodesource
            yum:
                enabled:     1
                gpgcheck:    1
                gpgkey_url:  https://rpm.nodesource.com/pub/el/NODESOURCE-GPG-SIGNING-KEY-EL
                gpgkey:      NODESOURCE-GPG-SIGNING-KEY-EL
                centos:
                    repos:
                        nodesource:
                            description: Node.js Packages for Centos $releasever - $basearch
                            path:        pub_10.x/el/$releasever/$basearch
                fedora:
                    repos:
                        nodesource:
                            description: Node.js Packages for Fedora $releasever - $basearch
                            path:        pub_10.x/fc/$releasever/$basearch

        npmjs:
            type:           proxy
            format:         npm
            remote_url:     https://registry.npmjs.org/
            blobstore:      npmjs

        prometheus:
            type:           proxy
            format:         yum
            remote_url:     
            blobstore:      prometheus

        pypi:
            type:           proxy
            format:         pypi
            remote_url:     https://pypi.org/
            blobstore:      pypi

        rpmfusion:
            type:           proxy
            format:         yum
            blobstore:      rpmfusion
            remote_url:     http://download1.rpmfusion.org/
            
            yum:
                enabled:     1
                gpgcheck:    1
                fedora:
                    repos:
                        rpmfusion-free:
                            description: RPM Fusion for Fedora $releasever - Free
                            path:        free/fedora/releases/$releasever/Everything/$basearch/os
                            gpgkey:      RPM-GPG-KEY-rpmfusion-free-fedora-28
                            gpgkey_url:  https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-fedora-$releasever
                        rpmfusion-free-updates:
                            description: RPM Fusion for Fedora $releasever - Free - Updates
                            path:        free/fedora/updates/$releasever/$basearch
                            gpgkey:      RPM-GPG-KEY-rpmfusion-free-fedora-28
                            gpgkey_url:  https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-fedora-$releasever
                        rpmfusion-nonfree:
                            description: RPM Fusion for Fedora $releasever - Nonfree
                            path:        nonfree/fedora/releases/$releasever/Everything/$basearch
                            gpgkey:      RPM-GPG-KEY-rpmfusion-nonfree-fedora-28
                            gpgkey_url:  https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever
                        rpmfusion-nonfree-updates:
                            description: RPM Fusion for Fedora $releasever - Nonfree - Updates
                            path:        nonfree/fedora/updates/$releasever/$basearch
                            gpgkey:      RPM-GPG-KEY-rpmfusion-nonfree-fedora-28
                            gpgkey_url:  https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever
                centos:
                    repos:
                        # NOTE: The base (non-updates) repo does not seem to exist for EL?
                        rpmfusion-free-updates:
                            description: RPM Fusion for EL $releasever - Free - Updates
                            path:        free/el/updates/$releasever/$basearch
                            gpgkey:      RPM-GPG-KEY-rpmfusion-free-el-7
                            gpgkey_url:  https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-$releasever
                        rpmfusion-nonfree-updates:
                            description: RPM Fusion for EL $releasever - Nonfree - Updates
                            path:        nonfree/el/updates/$releasever/$basearch
                            gpgkey:      RPM-GPG-KEY-rpmfusion-nonfree-el-7
                            gpgkey_url:  https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-nonfree-el-$releasever


        rubygems:
            type:           proxy
            format:         rubygems
            blobstore:      rubygems
            remote_url:     https://rubygems.org


        saltstack:
            type:           proxy
            format:         yum
            blobstore:      saltstack
            remote_url:     https://repo.saltstack.com/
            
            yum:
                enabled:     1
                gpgcheck:    1
                gpgkey:      saltstack-signing-key

                # Note, saltstack is already included in Fedora repos, so is not included here.

                centos,redhat:
                    repos:
                        saltstack:
                            description: Saltstack for EL$releasever
                            path:        yum/redhat/$releasever/$basearch/latest

        vscode:
            type:           proxy
            format:         yum
            blobstore:      microsoft
            remote_url:     https://packages.microsoft.com/
            
            yum:
                enabled:     1
                gpgcheck:    1
                gpgkey_url:  https://packages.microsoft.com/keys/microsoft.asc
                gpgkey:      microsoft.asc

                # Note, saltstack is already included in Fedora repos, so is not included here.

                centos,fedora,redhat:
                    repos:
                        vscode:
                            description: Visual Studio Code 
                            path:        yumrepos/vscode/

nexus-repos:
    defaults:
        kubernetes: True 
        built-rpms: True
        dockerce:   True
        # gitlab:   True # add only on the infra server
        nodesource: True
        #prometheus: 
        saltstack: True
        vscode: True
    # Redhat and centos are both so crappy and ancient
    # that they both need these three
    redhat,centos:
        rpmfusion:
            # This is really for fedora, but still useful here. 
            # can cause some conflicts though so it's disabled unless
            # explicitly enabled
            enabled: 0 
        epel:       True
        ius:        True
    centos:
        centos:     True
    fedora:
        fedora:     True
        rpmfusion:  True

#node_exporter:
#    port:     9100
#    storage:  /d/local/node_exporter
#
#    options:
#        - --collector.textfile.directory /d/local/node_exporter/textfile_collector
#        - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*)
#        - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$

node_lists:
    prometheus:
        primary:
            - infra
        #secondary:
        #    #- pxe-client1
        #    #- pxe-client2
        workstations: []

npm:
    host_config:
        send-metrics:     false
        metrics-registry: 
        registry:         http://nexus:7081/repository/npmjs/

pip:
    host_config: |
        [global]
        index        = http://nexus:7081/repository/pypi/pypi
        index-url    = http://nexus:7081/repository/pypi/simple
        no-cache-dir = false
        trusted-host = nexus
        disable-pip-version-check = True

        [list]
        format = columns


rsyslog:
    enabled: True
    client:
        ## Send endpoints will be added in the lan layer
        ##send: {}
        send:
            192.168.121.101:
                port:     2514
                protocol: relp
        enabled: True

    # The server will be enabled in a host or role override
    server:
        enabled: False

rubygems:
    mirror: http://nexus:7081/repository/rubygems/

service-status:

    service-sets: {} 
        # Example of enabling a service
        # Note, these are expected to be the name of a service set
        # not the service itself (though that may be the same depending on the OS)

        # enabled:
        #    - dhcp-server-dnsmasq
        # disabled:
        #    - dhcp-server-dhcpd
        
        # Or, an example of enabling/disabling different implementations:
        # enabled:
        #     - dhcp-server-dhcpd
        #     - tftp-server-xinetd
        # disabled:
        #     - pxeboot-server-dnsmasq

    services:
        disabled:
            # polkit is left enabled simply for convenience because in the test environment we are using a single all-in-one node ie including workstation functionality
            # - polkit
            # Can't disable NetworkManager in my test env as I need the wifi!
            # - NetworkManager
            - libvirtd
            - virtlockd
            - virtlogd
            - avahi-daemon
            - xinetd
            - abrt-ccpp
            - abrt-oops
            - abrt-xorg
            - abrtd
            - pulseaudio
            - tuned
            - lsmd
            - kdump

service-reg:
    nexus_http:       nexus:7081
    nexus_docker:     nexus:7082
    default_registry: nexus:7082
    gitlab_http:      gitlab
    gitlab_docker:    gitlab-registry:5005
    prometheus:       prometheus:9090
    grafana:          grafana:7070
    ipa_https:        infra:443
    nginx_http:       192.168.121.102:80
    nginx_https:      192.168.121.102:443

ssh:
    sshd:
        sshd_config: |
            Port 22
            ListenAddress 0.0.0.0
            HostKey /etc/ssh/ssh_host_rsa_key
            HostKey /etc/ssh/ssh_host_ecdsa_key
            HostKey /etc/ssh/ssh_host_ed25519_key
            SyslogFacility AUTHPRIV
            PermitRootLogin yes
            AuthorizedKeysFile	.ssh/authorized_keys
            PasswordAuthentication yes
            ChallengeResponseAuthentication no
            GSSAPIAuthentication yes
            GSSAPICleanupCredentials no
            UsePAM yes
            X11Forwarding yes
            PrintMotd no
            AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
            AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
            AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
            AcceptEnv XMODIFIERS
            Subsystem	sftp	/usr/libexec/openssh/sftp-server

sudoers:
    files:

        # In vagrant dev environment, allow sudo without password
        vagrant: |
            %vagrant ALL=(root) NOPASSWD: ALL

        wheel: |
            ## Allows people in group wheel to run all commands
            %wheel    ALL=(ALL)       ALL
            
        net-restart: |
            Cmnd_Alias NETWORK_RESTART = /usr/bin/systemctl restart network
            Cmnd_Alias NETWORK_STOP    = /usr/bin/systemctl stop network
            Cmnd_Alias NETWORK_START    = /usr/bin/systemctl stop network
            ALL ALL=(root) NOPASSWD: NETWORK_RESTART, NETWORK_STOP, NETWORK_START

timezone: UTC

firefox:
    defaults: |
        // Disable updater
        pref("app.update.enabled", false);
        // make absolutely sure it is really off
        pref("app.update.auto", false);
        pref("app.update.mode", 0);
        pref("app.update.service.enabled", false);

        // Disable Add-ons compatibility checking
        pref("extensions.lastAppVersion",""); 

        // Don't show 'know your rights' on first run
        pref("browser.rights.3.shown", true);

        // Don't show WhatsNew on first run after every update
        pref("browser.startup.homepage_override.mstone","ignore");

        // Set default homepage - users can change
        // Requires a complex preference
        pref("browser.startup.homepage","data:text/plain,browser.startup.homepage=http://docs/");
        pref("startup.homepage_override_url",       "http://docs/");
        pref("startup.homepage_welcome_url",        "http://docs/");

        // Disable the internal PDF viewer
        pref("pdfjs.disabled", true);

        // Disable the flash to javascript converter
        pref("shumway.disabled", true);

        // Don't ask to install the Flash plugin
        pref("plugins.notifyMissingFlash", false);

        //Disable plugin checking
        pref("plugins.hide_infobar_for_outdated_plugin", true);
        pref("plugins.update.url","");

        // Disable health reporter
        pref("datareporting.healthreport.service.enabled", false);

        // Disable all data upload (Telemetry and FHR)
        pref("datareporting.policy.dataSubmissionEnabled", false);

        // Disable crash reporter
        pref("toolkit.crashreporter.enabled", false);
        //Components.classes["@mozilla.org/toolkit/crash-reporter;1"].getService(Components.interfaces.nsICrashReporter).submitReports = false; 
