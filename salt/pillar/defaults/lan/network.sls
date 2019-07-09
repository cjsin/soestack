{{ salt.loadtracker.load_pillar(sls) }}

network:

    # Set some reasonable defaults for people first using this soe
    netmask: 255.255.255.0
    prefix:  24

    # The following is example data, but you need to set your subnet and gateway
    # to a real value in one of the other layers
    # subnet:  192.168.121/24
    # gateway: 192.168.121.1

    hostfile-additions: {}
        # Example data
        # 127.0.0.1:       localhost.localdomain localhost localhost4.localdomain localhost4
        # '::1':           localhost6.localdomain localhost6
        # x.x.x.x:         hostx.exampledomain hostx
        # y.y.y.y:         hosty.exampledomain hosty

