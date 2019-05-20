roles:

    basic-node:
        purpose: |
            a node type intended as a basis for other custom node type.
            it should not have much installed other than basic system tools

    minimal-node: 
        purpose: |
            a minimal node has preinstalled little other than what is required by a
            base installation of the soe (salt minion) and tools which 
            may be required by salt or by an administrator only. intended as a base
            for other node types

    primary-server-node:
        purpose: |
            primary server role type is one which provides critical services
            such as IPA, DNS, DHCP, PXE booting
            
    kubernetes-node:
        purpose: |
            a node which acts as a kubernetes node, and which generally
            wouldn't usually be used for any other workloads. 

    docker-node:
        purpose: |
            any node which runs docker

    email-server-node:
        purpose: |
            a server which provides email services. may be extra locked
            down to comply with security requirements

    homedir-server-node:
        purpose: |
            a server which provides home directories, which may have
            additional tools such as quota management or autofs support

    jumpserver-node:
        purpose: |
            a jump server is a node which allows an administrative user to
            log in prior to a subsequent access of a server where logins 
            are generally not allowed or where privileged logins are  not
            directly allowed

    management-node:
        purpose: |
            a management node is a node which may run some services on the
            network for management purposes or to provide an administrator
            a place to work without disrupting users

    service-node:
        purpose: |
            a service node is a node which runs some services that are
            required on the network

    processor-node:
        purpose: |
            A processor node is a workhorse node which may or may not allow logins. 
            It generally won't run critical system services but may run services
            for accepting workloads.

    login-node:
        purpose: |
            a node which allows logins

    workstation-node:
        purpose: |
            a workstation (has a GUI login)

    sofware-development-node:
        purpose: |
            a node used for software development. whether or not it is logged into
            directly by developers, it needs compilers, toolchains, headers, libraries
