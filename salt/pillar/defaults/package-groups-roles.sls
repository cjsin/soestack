# Package groups which represent roles (share a name with a role)

package-groups:

    #all-in-one-sde-server-node:
    #    package-groups:
    #        - software-development-node
    #        - kubernetes-node
    #        - homedir-server-node

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

    software-development-node:
        package-groups:
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

    homedir-server-node:
        package-sets:
            - nfs-server
            - disk-quotas

    email-server-node:
        package-sets:
            - email-server
            - email-clients

    primary-server-node:
        package-sets:
            - ipa-server
            - tftp-server-dnsmasq

    workstation-node:
        package-sets:
            - gnome-desktop
            - kde-desktop
            - alternative-desktop
            - xfce-desktop

    developer-workstation-node:
        package-groups:
            - workstation-node
        package-sets:
            - browsers-group
            - development-tools-group
            - development-editors-group
            - development-base
            
