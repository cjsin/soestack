#!stateconf yaml . jinja 

{%- if 'npm' in pillar %}
{%-     if 'host_config' in pillar.npm %}

.global-npmrc:
    file.managed:
        - name:     /etc/npmrc
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            {%- for key, value in pillar.npm.host_config.iteritems() %}
            {{key}}={{value}}
            {%- endfor %}

{%-     endif %}
{%- endif %}
