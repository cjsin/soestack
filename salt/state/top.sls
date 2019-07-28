base:
    '*':
        - secrets
        - yum
        - common
        - activated
        - deployments
        - util

    'roles:primary-server-node':
        - match: grain
        - server.primary

    'roles:secondary-server-node':
        - match: grain
        - server.secondary

    'roles:workstation-node':
        - match: grain
        - workstation
   
    #'E@.*':
    #    - classes
    #    - objects
