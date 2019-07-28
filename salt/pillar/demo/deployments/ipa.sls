{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ipa:
        deploy_type: ipa
        hosts: []
        activated:   True
        activated_where: {{sls}}
        config:
            type:    server
            realm:   '!!ipa.realm'
            domain:  '!!ipa.domain'
            reverse_zone: 121.168.192.in-addr.arpa.
            server: unset
            site:   default
            ldap:    {}
            hosts:  managed-hosts:ipa-hosts

            install:
                dns:
                    enabled: True
                    forwarders: []
            bind_ips:
                httpd: '!!demo.ips.replica1'
                named: '!!demo.ips.replica1'

            passwords:
                master: salt-secret:pw-ipa-master
                admin:  salt-secret:pw-ipa-admin
                ds:     salt-secret:pw-ipa-ds

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
                    locations: {}

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
                        gitlab-admins:
                        gitlab-users:

                    send-email: True

                    default-groups:
                        - dev-users
                        - gitlab-users

                    users:
                        admin:
                            groups:
                                - grafana-admins
                                - gitlab-admins
                        devuser:
                            first-name: Dev2
                            surname:    User
                            groups: 
                                - dev-users
                                - grafana-editors
                                - gitlab-users

                        devuser2:
                            first-name: Dev2
                            surname:    User
                            groups: 
                                - dev-users
                                - gitlab-users

                        adminuser:
                            first-name: Admin
                            surname:    User
                            groups:
                                - admins
                                - grafana-admins
                                - gitlab-admins
                                - gitlab-users
                                
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

