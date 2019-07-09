{{ salt.loadtracker.load_pillar(sls) }}

nugget_data:

    package-sets:
        firewalld-firewall:
            centos,rhel,fedora:
                - firewalld

        iptables-firewall:
            centos,rhel,fedora:
                - iptables-services
    
    service-sets:

        firewalld-firewall:
            centos,rhel,fedora:
                - firewalld

        iptables-firewall:
            centos,rhel,fedora:
                - iptables-services
    
nuggets:
    firewall-implementations:
        description: |
            provides a firewall. A specific implementation needs to be selected.
            
