#!stateconf yaml . jinja

{%- if 'rsyslog' in pillar and pillar.rsyslog.enabled %}
{%-     set rsyslog = pillar.rsyslog %}

.installed:
    pkg.latest:
        - pkgs:
            - rsyslog
            - rsyslog-relp

.config-main:
    file.managed:
        - name:     /etc/rsyslog.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - source:   salt://{{slspath}}/rsyslog.conf.jinja
        - context:
            rsyslog: {{rsyslog|json()}}

.config-local:
    file.managed:
        - name:     /etc/rsyslog.d/00-local.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - source:   salt://{{slspath}}/rsyslog-local.conf.jinja
        - context:
            rsyslog: {{rsyslog|json()}}

{%-     if 'server' in rsyslog and rsyslog.server.enabled %}

.server-config:
    file.managed:
        - name:     /etc/rsyslog.d/25-server.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - source:   salt://{{slspath}}/rsyslog-server.conf.jinja
        - context:
            rsyslog: {{rsyslog|json()}}

.selinux:
    cmd.run:
        - name: semanage port -a -t syslogd_port_t -p tcp 2514
        - unless: semanage port -l | grep 2514

{%-     endif %}

{%-     if 'client' in rsyslog and rsyslog.client.enabled %}

.client-config:
    file.managed:
        - name:     /etc/rsyslog.d/75-client.conf
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - source:   salt://{{slspath}}/rsyslog-client.conf.jinja
        - context:
            rsyslog: {{rsyslog|json()}}

{%-     endif %}

.service:
    service.running:
        - name:     rsyslog
        - enable:   True

{%-     endif %}
