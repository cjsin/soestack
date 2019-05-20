# Sets of roles which are used to initialise a server's roles list
# Once applied, most states would use the individual roles only

role-sets:

    all-in-one-sde-server-node:
        purpose: |
            all-in-one-sde server role type is one which provides all the basic functions 
            of a software development environment in one node
        combine:
            - primary-server-node
            - kubernetes-node
            - docker-node
            - email-server-node
            - homedir-server-node
            - processor-node
            - software-development-node
            - login-node
            - jumpserver-node
            - service-node
            - login-processor-node
            - workstation-node

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
            - workstation-node
            - software-development-node
