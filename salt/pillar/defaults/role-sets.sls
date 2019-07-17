{{ salt.loadtracker.load_pillar(sls) }}

# Sets of roles which are used to initialise a server's roles list
# Once applied, most states would use the individual roles only

role-sets:

    # NOTE that the order of the roles within a role-set 
    # CAN affect the resulting merged data in a counter-intuitive way.
    # In short, more important roles should appear later, so that their data
    # can override that specified for less important roles
    
    all-in-one-sde-server-node:
        purpose: |
            all-in-one-sde server role type is one which provides all the basic functions 
            of a software development environment in one node
        combine:
            - kubernetes-node
            - workstation-node
            - software-development-node
            - docker-node
            - login-processor-node
            - login-node
            - processor-node
            - jumpserver-node
            ## - elasticsearch-node
            - email-server-node
            - service-node
            - nexus-node
            - homedir-server-node
            - primary-server-node
            - infra-node

    usb-infra-server-node:
        purpose: |
            slightly cut-back usb infrastructure server node for
            quicker USB install testing
        combine:
            - docker-node
            - processor-node
            - jumpserver-node
            - email-server-node
            - service-node
            - nexus-node
            - homedir-server-node
            - primary-server-node
            - infra-node

    secondary-server-node:
        purpose: |
            similar to an infra node but intended as a secondary or failover. NOTE only ripa services are currently implemented for the secondary
        combine:
            - docker-node
            - jumpserver-node
            - email-server-node
            - service-node
            - homedir-server-node
            - primary-server-node

    quickstart-infra-server-node:
        purpose: |
            an infrastructure server with a connection to the internet - uses regular repos
            instead of a configuring a nexus server
        combine:
            - docker-node
            - workstation-node
            - software-development-node
            - kubernetes-node
            - login-processor-node
            - login-node
            - processor-node
            - jumpserver-node
            - email-server-node
            - service-node
            - homedir-server-node
            - primary-server-node
            - infra-node

    login-processor-node:
        purpose: |
            a login processor node is a workhorse node which also allows logins
        combine:
            - processor-node
            - login-node

    developer-workstation-node:
        purpose: |
            developer-workstation role type is one which supports regular
            workstation functions as well as having software development tools
        combine:
            - software-development-node
            - workstation-node

