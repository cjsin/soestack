base:
    '*':
        - secrets
        - yum
        - common
        - activated
        - deployments
        - util

    'roles:primary-server':
        - match: grain
        - server.primary

    'roles:secondary-server':
        - match: grain
        - server.secondary

    'roles:workstation':
        - match: grain
        - workstation
   
    #'E@.*':
    #    - classes
    #    - objects
