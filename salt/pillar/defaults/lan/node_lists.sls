{{ salt.loadtracker.load_pillar(sls) }}

# Node lists are by default empty

node_lists:

    # Example of setting some freeform node lists which assist in 
    #     various other states and templates
    #
    # prometheus:
    #    primary:
    #        - infra1
    #        - infra2
    #
    #    secondary:
    #        - management-server-1
    #        - management-server-2
    #        - storage-server-1
    #
    #    workstations:
    #        - workstation1
    #        - workstation2
    #        - workstation3
    #
    #
    # How these are used would depend on the state so you could
    # use patterns if your state supports that, for example:
    #
    # ups-shutdown-sequence:
    #     - workstation.*
    #     - infra1
    #     - infra2
    #     - managment-server-1

    #
    #  This is freeform lookup table, so if you have multiple sites 
    #  you could add node lists per-site, for example:
    #
    #  site1:
    #       prometheus:
    #           (as in above example)
    #  site2:
    #       prometheus:
    #           (some other nodes)
