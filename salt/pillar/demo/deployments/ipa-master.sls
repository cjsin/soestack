deployments:
    ipa_master:
        testenv-master:
            host:   infra
            activated: True
            install:
                nuggets-required:
                    - ipa-server

            config:
                domain: demo
                realm:  DEMO
                fqdn:   infra.demo
                reverse_zone: 121.168.192.in-addr.arpa.
                site:   demo
                install:
                    dns:
                        enabled: True
                        forwarders:
                            - 192.168.188.1 # modem / wifi
                            # - 192.168.121.1 # wired-gateway
                bind_ips:
                    httpd: 192.168.121.101
                    named: 192.168.121.101

                initial-setup:

                    global-config:
                        maxusernamelength:   32
                        homesrootdir:        /home
                        defaultloginshell:   /bin/bash
                        defaultprimarygroup: ipausers
                        defaultemaildomain:  localhost.localdomain
                        usersearchfields:    uid,givenname,sn,telephonenumber,ou,title
                        migrationenabled:    FALSE
                        pwdexpadvnotify:     4

                    automount:
                        locations:
                            - demo
                            - qemu
                            - default

                        maps:
                            auto.master:
                                '/home':  auto.home
                                '/-':     auto.direct

                            auto.direct:
                                '/e':     '-fstype=nfs4,ro  infra.demo:/e'

                            auto.home:
                                '*':      '-fstype=nfs4,rw  infra.demo:/e/home/&'

                    pwpolicy:
                        minlength:  1
                        minclasses: 1
                        history:    0

                    accounts:
                        groups: 
                            admins:
                            bind-users:
                            grafana-admins:
                            grafana-editors:
                            dev-users:

                        users:
                            admin:
                                groups:
                                    - grafana-admins
                            devuser:
                                first-name: Dev
                                surname:    User
                                groups: 
                                    - dev-users
                                    - grafana-editors
                            adminuser:
                                first-name: Admin
                                surname:    User
                                groups:
                                    - admins
                                    - grafana-admins
                                    
                            bind-user:
                                first-name: Bind
                                surname:    User
                                groups:
                                    - bind-users
                            salt-pillar:
                                first-name: Salt
                                surname:    Pillar
                                groups:
                                    - bind-users
                            salt-enrol:
                                first-name: Salt
                                surname:    Enrol
                                groups:
                                    - bind-users
