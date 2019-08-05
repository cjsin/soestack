{{ salt.loadtracker.load_pillar(sls) }}

package-sets:

    alternative-desktop:
        purpose: |
            provide other desktop
        centos,redhat,fedora:
            - '@MATE Desktop'
            #- '@Cinnamon Desktop'
            #- '@General Purpose Desktop'
            - openbox
            - fluxbox

    basic-tools:
        purpose: |
            tools desired on all boxes
        centos,redhat,fedora:
            - rsync 

    alternative-toolchains:
        purpose: | 
            provide some other common development toolchains
        centos,redhat,fedora:
            - cmake
            # python2-scons and extra-cmake-modules are broken/unailable due to broken epel zchunk issue
            # - extra-cmake-modules
            #- python2-scons

    chromium-browser:
        purpose: |
            provide the chromium web browser
        centos,redhat,fedora:
            updates:
                - chromium
                - chromium-headless
                - chromium-libs
                - chromium-libs-media
            #rpmfusion-free-updates:
            #    - chromium-libs-media-freeworld

    clamav-antivirus:
        purpose: |
            provide antivirus support for scanning files obtained from untrusted sources
        centos,redhat-fedora:
            order: os,epel
            os:
                - pcre2
                - libtool-ltdl
            epel:
                - clamav
                - clamav-data
                #- clamav-milter
                - clamav-scanner-systemd
                - clamav-unofficial-sigs

    clamav-antivirus-server:
        purpose: |
            provide antivirus support for scanning files obtained from untrusted sources - the server component
        centos,redhat-fedora:
            epel:
                - clamav-server-systemd

    console-tools:
        purpose: |
            provide tools that improve console usage
        centos,redhat,fedora:
            - gpm
            # htop is broken/unailable due to broken epel zchunk issue
            - htop

    development-base:
        purpose: |
            provide the centos/redhat development group
        centos,redhat,fedora:
            - '@Development and Creative Workstation'


    development-minimal:
        purpose: |
            smaller set of packages for development, to serve
            as an example but without taking ages to install
            while testing
        centos,redhat,fedora:
            - gcc
            - make
            - libtool

    dhcp-server:
        purpose: |
            provide standardised well known DHCP server implementation
        centos,redhat,fedora:
            - dhcp

    diff-tools-console:
        purpose: |
            provide differencing tools for general purposes
        centos,redhat,fedora:
            - diffutils

    diff-tools-gui:
        purpose: |
            provide differencing tools for developers
        centos,redhat,fedora:
            - meld
            - kdiff3
            # - kdesdk-kompare

    dnsmasq:
        purpose: |
            provide simple easy to configure DHCP, TFTP, or DNS functions
        centos,redhat,fedora:
            - dnsmasq

    docker:
        purpose: |
            provide support for running docker containers
        centos,redhat:
            dockerce:
                - docker-ce
        fedora:
            - docker

    firefox-browser:
        purpose: |
            provide the chromium web browser
        centos,redhat,fedora:
            any:
                - firefox

    gcc:
        purpose: |
            provide the GCC compiler
        centos,redhat,fedora:
            - cpp
            - gcc
            - gcc-c++
            - gcc-go
            - libmpc
            - mpfr
            - glibc-devel
            - glibc-headers
            - kernel-headers

    git-standard-uninstall:
        purpose: |
            uninstall standard version of git included with the OS
        action: absent
        centos,redhat:
            - git
            - perl-git

    git-newer:
        purpose: |
            provide a newer version of git
        centos,redhat:
            # Install the OS repo dependencies before the ius packages
            order: os,ius
            os:
                - perl-Error
                - perl-TermReadKey
                - libsecret
            ius:
                - git2u
        fedora:
            - git

    gnome-desktop:
        purpose: |
            provide the gnome desktop
        centos,redhat,fedora:
            - '@GNOME Desktop'
            #- '@General Purpose Desktop'

    gnu-autotools-toolchain:
        purpose: |
            provide standard GNU development toolchain
        centos,redhat,fedora:
            - autoconf
            - automake
            - libtool
            - libtool-ltdl
            - m4
            - make
            - pkgconfig

    iptables-firewall:
        purpose: |
            provide an iptables firewall implementation that works
            better with docker, kubernetes, saltstack etc than firewalld does currently
        centos,redhat,fedora:
            - iptables-services

    ipa-client:
        purpose: |
            IPA client and autofs homedir support
        centos,redhat,fedora:
            - ipa-client
            - autofs

    ipa-server:
        purpose: |
            IPA master server or replica
        centos,redhat,fedora:
            - ipa-server
            - ipa-server-dns

    kde-desktop:
        purpose: |
            provide the kde desktop
        centos,redhat,fedora:
            - '@KDE Plasma Workspaces'
            # - '@KDE Desktop'
            #- '@General Purpose Desktop'
            # - openbox-kde

    kubernetes:
        purpose: |
            provide kubernetes cluster support
        centos,redhat,fedora:
            any:
                - socat
                - conntrack-tools
            kubernetes:
                - kubelet
                - kubeadm
                - kubectl
                - cri-tools
                - kubernetes-cni

    minimal-desktop:
        purpose: |
            provide minimal desktop install to keep install time down during testing
        centos,redhat,fedora:
            - openbox
            #- fluxbox
            #- terminator
            - lightdm
            - xorg-x11-server-Xorg
            - xorg-x11-utils
            - xorg-x11-xinit
            - xorg-x11-xkb-extras
            - xorg-x11-xkb-utils
            - xorg-x11-util-macros
            - xorg-x11-server-utils
            - xorg-x11-fonts-100dpi
            - xorg-x11-apps
            - xorg-x11-docs
            - xorg-x11-drivers
            - xorg-x11-drv-evdev
            - xorg-x11-drv-keyboard
            - xorg-x11-drv-intel
            - xorg-x11-drv-fbdev
            - xorg-x11-drv-ati
            - xorg-x11-drv-libinput
            - xorg-x11-drv-mouse
            - xorg-x11-drv-nouveau
            - xorg-x11-drv-qxl
            - xorg-x11-drv-synaptics
            - xorg-x11-drv-vesa
            - xorg-x11-drv-vmmouse
            - xorg-x11-font-utils
            - xorg-x11-xauth
            - xorg-x11-xbitmaps
            - xorg-x11-xkb-extras
            - xorg-x11-xkb-utils
            - xorg-x11-fonts-ISO8859-1-100dpi
            - xorg-x11-xinit-session
            - xfce4-session
            - xfce4-panel
            - xfce4-settings
            - xfce4-terminal
            - xfdesktop
            - xfwm4
            - xfconf

    net-tools:
        purpose: |
            provide basic network tools (for example 'route', 'ip')
        centos,redhat,fedora:
            # provides 'route', 'ifconfig'
            - net-tools
            # provides 'ip'
            - iproute
            - wget
            - curl

    nfs-server:
        purpose: |
            provide nfs exports or access nfs exports
        centos,redhat,fedora:
            - nfs-utils

    node-exporter-custom-build:
        purpose: |
            provide node metrics for prometheus + grafana dashboard
        centos,redhat,fedora:
            built-rpms:
                - node_exporter

    nodejs-development:
        purpose: |
            provide nodejs tools
        centos,redhat,fedora:
            nodesource:
                - nodejs
                - npm

    oldschool-editors-console:
        purpose: |
            provide oldschool editors that support editing in a console (no gui)
        centos,redhat,fedora:
            - nano
            - vim-enhanced

    oldschool-editors-gui:
        purpose: |
            provide gui support in oldschool editors
        centos,redhat,fedora:
            - vim-X11
            # xemacs isn't available because epel is broken by zchunk metadata changes
            #- xemacs

    process-tools:
        purpose: |
            provide tools for management of processes
        centos,redhat,fedora:
            # htop is broken/unailable due to broken epel zchunk issue
            - htop
            # provides pstree
            - psmisc

    python-development:
        purpose: |
            provide tools for python development
        centos,redhat,fedora:
            - python
            # Unfortunately python2 pip is only available for RedHat/CentOS through the EPEL repos, which are currently broken due to them changing to use zchunk metadata which is not supported through nexus
            # - python2-pip
            - python37

    selinux-tools:
        purpose: |
            provide tools for configuring selinux ports, booleans, etc.
        centos,redhat:
            - policycoreutils-python
        fedora:
            - policycoreutils-python-utils

    terminator:
        purpose: |
            provide a better terminal than crappy gnome terminal
        centos,redhat,fedora:
            order: os,epel
            os:
                - gnome-python2-gconf
                - gnome-python2-bonobo
            epel:
                - terminator
                #- vte
                - terminus-fonts
                - terminus-fonts-console
                - python-keybinder

    tftp-server-dnsmasq:
        purpose: |
            provide tftp support for pxe booting via dnsmasq
        centos,redhat,fedora:
            - dnsmasq
            - syslinux 
            - syslinux-tftpboot

    tftp-server-xinetd:
        purpose: |
            provide tftp support for pxe booting via xinetd
        centos,redhat,fedora:
            - tftp-server
            - syslinux 
            - syslinux-tftpboot
            - xinetd

    vscode-editor:
        purpose: |
            provide the VSCode editor / IDE
        centos,redhat,fedora:
            vscode:
                - code

    virt-fs-tools:
        purpose: |
            provide virtual filesystem tools. These are used for building a
            bootable USB stick image for booting a server, among other things.
        fedora:
            - libguestfs
            - libguestfs-forensics
            - libguestfs-gfs2
            - libguestfs-man-pages
            - libguestfs-nbdkit # create image over network, for automated pxeboot
            - libguestfs-nilfs 
            - libguestfs-rsync
            - libguestfs-rescue 
            - libguestfs-tools
            - guestfs-browser
            - perl-Sys-Guestfs
            - nbdkit-plugin-guestfs 
            - python2-libguestfs
            - python3-libguestfs


        centos,redhat:

    xfce-desktop:
        purpose: |
            provide the XFCE desktop 
        # Xfce and General Purpose Desktop groups no longer seem to be provided
        # (Xfce is in broken epel repo, General Purpos Desktop seems just gone.)
        centos,redhat,fedora: []
        #    - '@Xfce'
        #    - '@General Purpose Desktop'

