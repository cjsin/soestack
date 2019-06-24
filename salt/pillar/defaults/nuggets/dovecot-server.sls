nugget_data:

    package-sets:

        dovecot:
            centos,rhel,fedora:
                - dovecot    

nuggets:

    dovecot-server:
        description: |
            Supports deploying dovecot

        install:
            installed:
                package-sets:
                    - dovecot

        activate:
            service-sets:
                enabled:
                    - dovecot

        config:
            mail_location: 'maildir:~/Maildir'

        filesystem:
            defaults:
                user:       root
                group:      root
                dir_mode:  '0755'
                file_mode: '0644'

            templates:
                {%- raw %}
                dovecot-mail-conf: |
                    mail_location = {{config.mail_location}}
                {%- endraw %}

            dirs:
                /etc/skel/Maildir:
                /etc/skel/Maildir/new:
                /etc/skel/Maildir/cur:
                /etc/skel/Maildir/tmp:

            files:

                /etc/dovecot/conf.d/99-soestack.conf:
                    config_pillar:   :config
                    template:        dovecot-mail-conf

