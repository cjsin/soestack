{{ salt.loadtracker.load_pillar(sls) }}

# Package groups which represent roles (share a name with a role)

package-groups:

    # Define some package groups for different roles.
    # This can be thought of as defining a class hierarchy for the node types
    # with multiple inheritance (at least) with respect to the package sets installed on them.
    #
    #  minimal-node:
    #   \
    #    \+-basic-node
    #       \
    #        |
    #        +-processor-node
    #        |
    #        |     +--workstation-node
    #        |    /                    \
    #        +-desktop-node---------    \
    #        |    \                 \    \  
    #        |     \                 \    \ 
    #        |      |                 \    \
    #        |      +------------------+----+-developer-workstation-node
    #        |      |                   \
    #        |      +-processor-node     \
    #        |     /                      \
    #        |    /                        \
    #        +-software-development-node    \
    #        |                          \    \
    #        +-email-server-node -----   \    \
    #        |                        \   \    \
    #        +-homedir-server-node -   \   \    \
    #        |                      \   \   \    \
    #        +-primary-server-node --+---+--+--+--+--all-in-one-sde-server-node
    #        +-docker-node                    /
    #            \                           /
    #             \-kubernetes-node --------/

    basic-node:
        package-groups:
            - minimal-node
        package-sets:
            - net-tools
            - clamav-antivirus
            - basic-tools

    desktop-node:
        package-groups:
            - basic-node
        package-sets:
            #- gnome-desktop
            #- kde-desktop
            #- alternative-desktop
            #- xfce-desktop
            - minimal-desktop
            - browsers-group
            - development-editors-group
            - terminator

    docker-node:
        package-groups:
            - minimal-node
        package-sets:
            - docker

    email-server-node:
        package-groups:
            - basic-node
        package-sets:
            - email-server
            - email-clients

    homedir-server-node:
        package-groups:
            - basic-node
        package-sets:
            - nfs-server
            - disk-quotas
            - clamav-antivirus-server

    kubernetes-node:
        package-groups:
            - docker-node
        package-sets:
            - kubernetes

    minimal-node: 
        package-sets:
            - console-tools
            - process-tools
            - net-tools
            - oldschool-editors-console
            - diff-tools-console

    primary-server-node:
        package-groups:
            - basic-node
        package-sets:
            - ipa-server
            - tftp-server-dnsmasq

    processor-node:
        package-groups:
            - software-development-node

    login-processor-node:
        package-groups:
            - desktop-node
            - processor-node

    software-development-node:
        package-groups:
            - basic-node
            - development-tools-group
        package-sets:
            - diff-tools-console
            # diff-tools-gui is disabled until EPEL zchunk bug is fixed
            #- diff-tools-gui
            #- development-base
            - development-minimal
            - python-development
            - git-standard-uninstall
            - git-newer

    workstation-node:
        package-groups:
            - desktop-node

    infra-server-node:
        package-sets:
            - admin-minimal-desktop
        package-groups:
            - browsers-group
