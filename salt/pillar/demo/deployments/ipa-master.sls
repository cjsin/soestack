_loaded:
    {{sls}}:

deployments:
    ipa_master:
        testenv-master:
            host:      infra
            activated: True
            activated_where: {{sls}}
            install:
                nuggets-required:
                    - ipa-server

            config:
                domain: default
                realm:  DEFAULT
                fqdn:   infra.default
                reverse_zone: 121.168.192.in-addr.arpa.
                site:   default
                install:
                    dns:
                        enabled: True
                        forwarders: []
                passwords:
                    master: random
                    admin:  random
                    ds:     random
                bind_ips:
                    httpd: 192.168.121.101
                    named: 192.168.121.101

                initial-setup:

                    global-config:
                        maxusernamelength:   32
                        homesrootdir:        /home
                        defaultloginshell:   /bin/bash
                        defaultprimarygroup: ipausers
                        defaultemaildomain:  demo.com
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
                                '/e':        '-fstype=nfs4,ro  infra:/'

                            auto.home:
                                '*':      '-fstype=nfs4,rw  infra:/home/&'

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

                        send-email: True
                        default-groups:
                            - dev-users
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
