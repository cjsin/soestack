{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa_master:
        demo-ipa-master:
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
                hosts:  managed-hosts:demo-ipa-master
                install:
                    dns:
                        enabled: True
                        forwarders: []
                passwords:
                    master: salt-secret:pw-ipa-master
                    admin:  salt-secret:pw-ipa-admin
                    ds:     salt-secret:pw-ipa-ds
                bind_ips:
                    httpd: '!!demo.ips.infra'
                    named: '!!demo.ips.infra'

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
