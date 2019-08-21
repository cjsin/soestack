#!stateconf yaml . jinja 

# See:
# https://www.chromium.org/administrators/policy-list-3

{%- if 'chromium' in pillar and pillar.chromium is mapping and 'autoconfig' in pillar.chromium and pillar.chromium.autoconfig is mapping %}
{%-     set autoconfig = pillar.chromium.autoconfig %}
{%-     set dirs = [
            '/etc/chromium/policies',
            '/etc/chromium/policies/managed/',
            '/etc/chromium/policies/recommended/' ]%}

{%-     for d in dirs %}
.{{sls}}.{{d}}:
    file.directory:
        - name:     '{{d}}'
        - user:     root
        - group:    root
        - mode:     '0755'
        - makedirs: True 
{%-     endfor %}

{%-     for category in [ 'recommended', 'managed' ] %}
{%-         set cat_config = autoconfig[category] if (category in autoconfig and autoconfig[category]) else {} %}

.{{sls}}.policies.{{category}}:
    file.managed:
        - name:     '/etc/chromium/policies/{{category}}/soestack.json'
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            {{cat_config|tojson(True)|indent(12)}}

{%-     endfor %}

{%- set default_master = {
  "homepage": "http://docs.demo.com",
  "homepage_is_newtabpage": False,
  "distribution": {
     "alternate_shortcut_text": false,
     "oem_bubble": true,
     "chrome_shortcut_icon_index": 0,
     "create_all_shortcuts": true,
     "show_welcome_page": true,
     "system_level": false,
     "verbose_logging": false
  },
  "first_run_tabs": [
     "http://docs.demo.com",
  ]
} %}

{%-     set master_config = autoconfig['master'] if 'master' in autoconfig else default_master %}

.{{sls}}.preferences.master:
    file.managed:
        - name:     /etc/chromium/master_preferences
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            {{master_config|tojson(True)|indent(12)}}

{%- endif %}
