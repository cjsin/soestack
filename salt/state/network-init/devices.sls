#!stateconf yaml . jinja 

{%- set sysconfig_devices = [] %}
{%- set wpa_configs       = [] %}
{%- set wpa_devices       = [] %}

{%- for devname, configuration in pillar.network.devices.iteritems() %}
{%-     set ifcfg_file='/etc/sysconfig/network-scripts/ifcfg-' ~ devname %}

{%-     if 'delete' in configuration and configuration.delete %}

.sysconfig-{{devname}}-deleted:
    file.absent:
        - name: {{ifcfg_file}}

{%-     else %}
{%-         if 'wpa' in configuration %}
{%-             do wpa_configs.append(configuration.wpa) %}
{%-             do wpa_devices.append(devname) %}

{%-         endif %} 
{%-         if 'sysconfig' in configuration %}
{%-             set sysconfig = configuration.sysconfig %}
{%-             do sysconfig_devices.append(devname) %}

.sysconfig-{{devname}}:
    file.managed:
        - name: {{ifcfg_file}}
        - user:     root
        - group:    root
        - mode:     '0600'
        - contents: |
            NAME={{devname}}
            DEVICE={{devname}}
            {{sysconfig|indent(12)}}
        - template: jinja

{%-         endif %} 
{%-    endif %} 
{%- endfor %}

{%- if wpa_configs %}

.wpa-config:
    file.managed:
        - name:     /etc/wpa_supplicant/wpa_supplicant.conf
        - user:     root
        - group:    root
        - mode:     '0600'
        - contents: |
            ctrl_interface=/var/run/wpa_supplicant
            ctrl_interface_group=wheel
            {% for section in wpa_configs %}
            {{section|indent(12)}}
            {% endfor %}

.wpa-interfaces:
    file.replace:
        - name:    /etc/sysconfig/wpa_supplicant
        - pattern: '^INTERFACES="'
        - repl:    'INTERFACES="{% for i in wpa_devices %}-i{{i}} {%endfor%}"'

.wpa-installed:
    pkg.installed:
        - pkgs:
            - wpa_supplicant
            - wpa_supplicant-gui

.wpa-service:
    service.running:
        - name:   wpa_supplicant
        - enable: True
        - onchanges:
            - file: {{sls}}::wpa-config
            - pkg:  {{sls}}::wpa-installed
            - file: {{sls}}::wpa-interfaces

{%- endif %}

{%- if sysconfig_devices %}

.net-restart:
    service.running:
        - name:   network
        - enable: True
        - onchanges:
            {%- for devname in sysconfig_devices %}
            - file: network-init.devices::sysconfig-{{devname}}
            {%- endfor %}

{%- endif %}
