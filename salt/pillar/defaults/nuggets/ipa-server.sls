nugget_data:

    # Firewall rules installation not configured yet
    firewall-rule-sets:
        ipa-server:
            basic: 
                ipa-frontend:
                    accept:
                        tcp:
                            http:        80
                            https:       443
                ipa-backend:
                    accept:
                        tcp/udp:
                            kerberos88:  88
                            kerberos464: 464
                        tcp:
                            ldap:        389
                            ldaps:       636
                auxilliary-services:
                    accept:
                        tcp/udp:
                            dns:         53
                        udp:
                            ntp:         123

nuggets:
    ipa-server:
        description: |
            provides support for rolling out an IPA server (initial server, not a replica)

        install:
            nuggets-required:
                - iptables-firewall
                - nfs-server
                - managed-hosts
                
            installed:
                package-sets:
                    - ipa-server

        activate:
            firewall:
                firewall-rule-sets:
                    - ipa-server
