{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    pgp_keyserver:
        ss-pgp:
            host:      infra
            activated: True
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
                    /srv/sks/sksconf:
                        user: sks
                        group: sks
                        mode: '0644'
                        template: sks_conf
                        config_pillar:   :config
                    /srv/sks/nginx.conf:
                        user: sks
                        group: sks
                        mode: '0644'
                        template: sks_nginx_conf
                        config_pillar:   :config
