{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-pgp:
        deploy_type:     pgp_keyserver
        host:            infra
        activated:       True
        activated_where: {{sls}}

        activate:
            firewall:
                basic:
                    sks-pgp-keyserver:
                        ip: '!!demo.ips.infra' 
                        accept:
                            tcp:
                                sks: 11371

        config:
            debuglevel: 3
            hostname: '!!demo.vars.infra'
            contact:  {{salt['cmd.shell']("gpg /etc/salt/gpgkeys/soestack-pub.gpg |grep ^pub|head -n1|tr -s  / ' ' |cut -d' ' -f3") }}
            nginx:
                bind_ip: '!!demo.ips.infra'

        filesystem:
            files:
                /d/local/data/sks/sksconf:
                    user: sks
                    group: sks
                    mode: '0644'
                    template: sks_conf
                    config_pillar:   :config

                /d/local/data/sks/nginx.conf:
                    user: sks
                    group: sks
                    mode: '0644'
                    template: sks_nginx_conf
                    config_pillar:   :config
                
                # The service file included in this package has 
                # syntax errors; Also we change the data directory here.
                /usr/lib/systemd/system/sks-recon.service:
                    user: root
                    group: root
                    mode: '0644'
                    contents: |
                        [Unit]
                        Description=SKS reconciliation service
                        BindsTo=sks-db.service
                        After=sks-db.service

                        [Service]
                        Type=simple
                        WorkingDirectory=/d/local/data/sks
                        ExecStart=/usr/bin/sks recon
                        User=sks
                        
                        [Install]
                        WantedBy=multi-user.target
                /usr/lib/systemd/system/sks-db.service:
                    user: root
                    group: root
                    mode: '0644'
                    contents: |
                        [Unit]
                        Description=SKS database service

                        [Service]
                        Type=simple
                        WorkingDirectory=/d/local/data/sks
                        ExecStart=/usr/bin/sks db
                        User=sks
                        
                        [Install]
                        WantedBy=multi-user.target
