#!stateconf yaml . jinja 
{%- set network = pillar.network if 'network' in pillar else {} %}
{%- set classes = network.classes if 'classes' in network else {} %}
{%- set devices = network.devices if 'devices' in network else {} %}

# Build a set of configuration data for each network device,
# utilising any inherited classes. 
# A full set of 'sysconfig' and 'wpaconfig' data is built for each device,
# and then afterwards, the ifcfg files are updated.
# Each network device may specify a list of 'classes' to inherit, in order.'
# The data from those inherited classes is merged prior to the configuration
# data for this device itself
{%- set processed_devices = {} %}
{%- for devname, cfg in devices.iteritems() %}
{%-     set defaults = { 'ignore': False, 'delete': False, 'sysconfig': {}, 'wpaconfig': {} } %}
{%-     set merged = {} %}
{%-     do  merged.update(defaults) %}
{%-     set inherit = cfg.inherit if 'inherit' in cfg else [] %}
{%-     set all_items = inherit + ['self'] %}
{%-     for classname in all_items %}
{%-         set netclass = cfg if classname == 'self' else (classes[classname] if classname else {}) %}
{%-         for netclass_key, netclass_data in netclass.iteritems() %}
{%-             if netclass_key in ['ignore', 'delete'] %}
{%-                 do merged.update({netclass_key: netclass[netclass_key]}) %}
{%-             elif netclass_key in ['sysconfig', 'wpaconfig'] %}
{%-                 do merged[netclass_key].update(netclass_data) %}
{%-             endif %}
{%-         endfor %}
{%-     endfor %}
{%-     do processed_devices.update({devname: merged}) %}
{%- endfor %}

{%- set sysconfig_devices = [] %}
{%- set wpa_configs       = [] %}
{%- set wpa_devices       = [] %}

{%- for devname, configuration in processed_devices.iteritems() %}
{%-     set ignore = 'ignore' in configuration and configuration.ignore %}
{%-     set delete = 'delete' in configuration and configuration.delete %}
{%-     set ifcfg_file='/etc/sysconfig/network-scripts/ifcfg-' ~ devname %}

{%-     if delete %}

.sysconfig-{{devname}}-deleted:
    file.absent:
        - name: {{ifcfg_file}}

{%-     elif not ignore %}

{%-         if 'wpa' in configuration %}
{%-             do wpa_configs.extend(configuration.wpa.values()) %}
{%-             do wpa_devices.append(devname) %}
{%-         endif %} 

{%-         if 'sysconfig' in configuration %}
{%-             set sysconfig = configuration.sysconfig %}
{%-             do sysconfig_devices.append(devname) %}
{%-             set keys = [] %}
{%-             for k,v in sysconfig.iteritems() %}
{%-                 do keys.append(k) %}
{%-             endfor %}

.sysconfig-{{devname}}:
    file.managed:
        - name:     '{{ifcfg_file}}'
        - user:     root
        - group:    root
        - mode:     '0600'
        - source:   salt://network-init/ifcfg-file.jinja
        - template: jinja
        - context:
            devname:   '{{devname}}'
            keys:      {{keys|sort|json}}
            sysconfig: {{sysconfig|json}}

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
        - watch:
            - file: {{sls}}::wpa-config
            - pkg:  {{sls}}::wpa-installed
            - file: {{sls}}::wpa-interfaces

{%- endif %}

{%- if sysconfig_devices %}

.net-restart:
    service.running:
        - name:   network
        - enable: True
        - watch:
            {%- for devname in sysconfig_devices %}
            - file: network-init.devices::sysconfig-{{devname}}
            {%- endfor %}

{%- endif %}
