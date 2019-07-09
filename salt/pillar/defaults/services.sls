{{ salt.loadtracker.load_pillar(sls) }}

service-status:

    service-sets: {} 
        # Example of enabling a service
        # Note, these are expected to be the name of a service set
        # not the service itself (though that may be the same depending on the OS)

        # enabled:
        #    - dhcp-server-dnsmasq
        # disabled:
        #    - dhcp-server-dhcpd
        
        # Or, an example of enabling/disabling different implementations:
        # enabled:
        #     - dhcp-server-dhcpd
        #     - tftp-server-xinetd
        # disabled:
        #     - pxeboot-server-dnsmasq

    services: {}
        # disabled:
        #     - polkit
