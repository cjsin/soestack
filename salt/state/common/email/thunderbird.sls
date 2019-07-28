#!stateconf yaml . jinja

{%- if 'roles' not in grains or 'desktop-node' in grains.roles %}
.thunderbird:
    pkg.installed:
        - pkgs:
            - thunderbird
            # - thunderbird-enigmail

.autoconfig-dir:
    file.directory:
        - name: /usr/lib64/thunderbird/isp
        - user: root
        - group: root
        - mode: '0755'

{%- if 'thunderbird' in pillar and pillar.thunderbird is mapping and 'autoconfig' in pillar.thunderbird and pillar.thunderbird.autoconfig is mapping %}
{%-     for name, config in pillar.thunderbird.autoconfig.iteritems() %}
{%-         if 'domain' in config and config.domain not in [ '', 'unset' ] %}
{%-         set domain = config.domain %}

# NOTE: for now when thundirbird starts, the user needs to select:
# - enter your name
# - enter your email address username@demo.com
# - enter your password
# - click continue
# - click Manual config
# - click Advanced config
# - click OK
# - click Confirm security exception
# - test it: right click username@demo.com and select 'get messages'
# - test sending: click Write, and compose a message to your own email.

.autoconfig-file-{{name}}:
    file.managed:
        - name:     /usr/lib64/thunderbird/isp/{{domain}}.xml
        - user:     root
        - group:    root
        - mode:     '0644'
        - source:   salt://{{slspath}}/thunderbird-autoconfig.xml.jinja
        - template: jinja
        - context: 
            config: {{config|json}}

{%-         endif %}
{%-     endfor %}
{%- endif %}

{%- endif %}
