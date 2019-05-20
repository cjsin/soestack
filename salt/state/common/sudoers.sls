#!stateconf yaml . jinja 

{%- if 'sudoers' in pillar and 'files' in pillar.sudoers %}
{%-     for filename, contents in pillar.sudoers.files.iteritems() %}

.sudoers-{{filename}}:
    file.managed:
        - name:  /etc/sudoers.d/{{filename}}
        - user:  root
        - group: root
        - mode:  '0440'
        - template: jinja
        - contents: |
            {{contents|indent(12)}}

{%-     endfor %}
{%- endif %}
