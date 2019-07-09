{{ salt.loadtracker.load_pillar(sls) }}

nugget_data:

    package-sets:

        ssh-server:
            centos,rhel,fedora:
                - openssh
    
    firewall-rule-sets:
        ssh-server:
            basic:
                standard-port:
                    accept:
                        tcp/udp:
                            ssh: 22


nuggets:

    ssh-server:
        description: |
            provides support for an SSH server

        install:
            installed:
                package-sets:
                    - ssh-server
            
            service-sets:
                enabled:
                    - ssh-server

        activate:
            firewall:
                firewall-rule-sets:
                    - ssh-server 
