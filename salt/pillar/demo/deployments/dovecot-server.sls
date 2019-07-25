{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    dovecot:
        deploy_type: dovecot_server
        roles:
            - email-server-node
        activated: False
        activated_where: {{sls}}
        activate:
            service:
                enabled:
                    - dovecot
            firewall:
                basic:
                    dovecot-pop3:
                        ip:  '!!demo.ips.infra'
                        accept:
                            tcp:
                                pop3: 110
                    dovecot-imap:
                        ip:  '!!demo.ips.infra'
                        accept:
                            tcp:
                                imap: 143
                    dovecot-imaps:
                        ip:  '!!demo.ips.infra'
                        accept:
                            tcp:
                                imaps: 993
                    dovecot-pop3s:
                        ip:  '!!demo.ips.infra'
                        accept:
                            tcp:
                                pop3s: 995

        config:
            mail_location: 'maildir:~/Maildir'
