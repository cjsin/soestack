#!stateconf yaml . jinja

# Can't use this because the rubbish clients in centos don't even
# support maildir format 

#postconf:
#    cmd.run:
#        - name:   postconf -e "home_mailbox = Maildir/"
#        - unless: grep "home_mailbox = Maildir/" /etc/postfix/main.cf

{%- if 'postfix' in pillar and pillar.postfix is mapping and 'config' in pillar.postfix %}

.postconf:
    file.managed: 
        - name: /etc/postfix/main.cf
        - user: root
        - group: root
        - mode: '0644'
        - template: jinja
        - source: salt://{{slspath}}/postfix-main.cf.jinja
        - context:
            config: {{pillar.postfix.config|json}}

# May need to uninstall esmtp or ssmtp

.service:
    service.running:
        - name:   postfix
        - enable: True
        - watch:
            - file: {{sls}}::postconf

{%- endif %}
