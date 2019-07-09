{{ salt.loadtracker.load_pillar(sls) }}

service-sets:
    dhcp-server:
        centos,rhel,fedora:
            - dhcpd

    dnsmasq:
        centos,rhel,fedora:
            - dnsmasq

    nfs-server:
        centos,rhel,fedora:
            - nfs-server

    tftp-server:
        centos,rhel,fedora:
            - xinetd

    docker:
        centos,fedora:
            - docker
        rhel:
            - docker-latest
