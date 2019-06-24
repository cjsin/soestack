#!stateconf yaml . jinja

# Can't use this because the rubbish clients in centos don't even
# support maildir format 

#postconf:
#    cmd.run:
#        - name:   postconf -e "home_mailbox = Maildir/"
#        - unless: grep "home_mailbox = Maildir/" /etc/postfix/main.cf

{%- if 'postfix' in pillar and pillar.postfix is mapping and 'config' in pillar.postfix %}
{%-     set postfix  = pillar.postfix %}
{%-     set configs  = postfix.config %}
{%-     set mode     = postfix.mode if 'mode' in postfix else 'client' %}
{%-     set defaults = configs.defaults if 'defaults' in configs else {'enabled': True } %}
{%-     set selected = configs[mode] if mode in configs else {} %}

{%-     set config     = {} %}
{%-     do config.update(defaults) %}
{%-     do config.update(selected) %}
{%-     set enabled = config['enabled'] %}

.postconf:
    file.managed: 
        - name: /etc/postfix/main.cf
        - user: root
        - group: root
        - mode: '0644'
        - template: jinja
        - source: salt://{{slspath}}/postfix-main.cf.jinja
        - context:
            config: {{config|json}}

# May need to uninstall esmtp or ssmtp

.service:
    service.{{'running' if enabled else 'dead'}}:
        - name:   postfix
        - enable: {{enabled}}
        - watch:
            - file: {{sls}}::postconf

{%- endif %}
