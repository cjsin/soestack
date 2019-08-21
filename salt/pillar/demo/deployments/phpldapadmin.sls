{{ salt.loadtracker.load_pillar(sls) }}

include:
    - defaults.nuggets.phpldapadmin

deployments:
    phpldapadmin:
        deploy_type:     phpldapadmin_baremetal
        roles:
            - ipa-server-node
        activated:       False
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
                        host: '!!demo.ips.infra'
                        port: 389
                        tls: false
                        base: 
                            - '!!demo.vars.ipa_base_dn'
                        
                    appearance:
                        password_hash: ''
                    login:
                        attr: uid
                        anon_bind: 1
                        class:
                            - posixAccount
                        base: 
                            - '!!demo.vars.users_base_dn'
                        auth_type: session 

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
