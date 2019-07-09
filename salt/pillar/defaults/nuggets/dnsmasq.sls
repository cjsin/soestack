{{ salt.loadtracker.load_pillar(sls) }}

nugget_data:

    package-sets:

        dnsmasq:
            centos,rhel,fedora:
                - dnsmasq    

nuggets:

    dnsmasq:
        description: |
            Supports deploying dnsmasq

        install:
            installed:
                package-sets:
                    - dnsmasq

        activate:
            service-sets:
                enabled:
                    - dnsmasq
