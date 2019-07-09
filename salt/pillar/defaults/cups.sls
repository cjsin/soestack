{{ salt.loadtracker.load_pillar(sls) }}

cups:
    # Override with 0.0.0.0:631 to provide printing services to your network 
    listen_address: 127.0.0.1:631

    # Example of specifying your lan
    # local_subnet: 192.168.121.*
    local_subnet: 127.0.0.1

    management_hosts:
        - localhost.localdomain
        # Example of adding your lan
        # - 192.168.121.*

    printer_default:   ''

    printers:
    
    #    Printer:
    #        uuid:      b11e07ba-8101-4d3d-835e-0d36891faddd
    #        info:      Printer name or description
    #        makemodel: Printer driver name
    #        ip:        192.168.121.215

