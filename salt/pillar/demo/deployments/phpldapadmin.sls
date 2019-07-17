{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    phpldapadmin_baremetal:
        phpldapadmin:
            host:      infra
            activated: False
            activated_where: {{sls}}
            activate:
                firewall:
                    basic:
                        phpldapadmin-frontend:
                            ip: '!!demo.ips.infra' 
                            accept:
                                tcp:
                                    http: 80
                                    https: 443
            config:
                allow:
                    - local
                    - ip 192.168.121.0/24
                servers:
                    IPA Server:
                        server:
                            host: 127.0.0.1
                            port: 389
                            tls: false
                        appearance:
                            password_hash: ''
                        login:
                            attr: uid
                            base: 
                                - cn=users
                                - cn=accounts
                                - dc=demo
                                - dc=com
                            auth_type: session 
                            # bind_id: ''
                            # bind_id: 'uid=admin,cn=users,cn=accounts,dc=demo,dc=com'
                            # bind_pass: ''
                            # bind_pass: 'secret'
            filesystem:
                templates:
                    phpldapadmin-httpd-conf:   salt://templates/deployment/phpldapadmin_baremetal/phpldapadmin-httpd.conf.jinja
                    phpldapadmin-php-conf:     salt://templates/deployment/phpldapadmin_baremetal/phpldapadmin-php.conf.jinja

                dirs:
                    /etc/phpldapadmin:
                        user:            root
                        group:           apache
                        mode:            '0750'
                    /etc/httpd/conf.d/:
                        user:            root
                        group:           root
                        mode:            '0755'
                files:
                    /etc/httpd/conf.d/phpldapadmin.conf:
                        config_pillar:   :config
                        template:        phpldapadmin-httpd-conf
                        user:            root
                        group:           root
                        mode:            '0644'
                    /etc/phpldapadmin/config.php:
                        config_pillar:   :config
                        template:        phpldapadmin-php-conf
                        user:            root
                        group:           apache
                        mode:            '0640'
