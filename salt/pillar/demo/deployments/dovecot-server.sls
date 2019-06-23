_loaded:
    {{sls}}:

deployments:
    dovecot_server:
        dovecot:
            host:      infra
            activated: False
            activated_where: {{sls}}
            activate:
                service:
                    enabled:
                        - dovecot
                firewall:
                    basic:
                        dovecot-pop3:
                            ip:  192.168.121.101
                            accept:
                                tcp:
                                    pop3: 110
                        dovecot-imap:
                            ip:  192.168.121.101
                            accept:
                                tcp:
                                    imap: 143
                        dovecot-imaps:
                            ip:  192.168.121.101
                            accept:
                                tcp:
                                    imaps: 993
                        dovecot-pop3s:
                            ip:  192.168.121.101
                            accept:
                                tcp:
                                    pop3s: 995

            config:
                mail_location: 'maildir:~/Maildir'
