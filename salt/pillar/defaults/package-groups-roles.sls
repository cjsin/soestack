# Package groups which represent roles (share a name with a role)

package-groups:

    basic-node:
        package-groups:
            - minimal-node
        package-sets:
            - net-tools

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

    software-development-node:
        package-groups:
            - basic-node
            - browsers-group
            - development-tools-group
            - development-editors-group
        package-sets:
            - diff-tools-console
            #- diff-tools-gui
            - development-base
            - python-development
            - git-standard-uninstall
            - git-newer

    workstation-node:
        package-groups:
            - basic-node
        package-sets:
            - gnome-desktop
            - kde-desktop
            - alternative-desktop
            #- xfce-desktop
            - browsers-group
