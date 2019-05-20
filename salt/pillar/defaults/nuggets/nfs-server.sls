
nugget_data:

    package-sets:

        nfs-server:
            centos,rhel,fedora:
                - nfs-utils
    
    firewall-rule-sets:
        nfs-server:
            basic:
                standard-port:
                    accept:
                        tcp/udp:
                            nfs4: 2049


nuggets:

    nfs-server:
        description: |
            provides support for an NFS server

        install:
            installed:
                package-sets:
                    - nfs-server
            
            service-sets:
                enabled:
                    - nfs-server

        activate:
            firewall:
                firewall-rule-sets:
                    - nfs-server 
