#!stateconf yaml . jinja

{%- for parent in [ 'root', 'skel' ] %}

{{sls}}.maildir-setup-{{parent}}-Maildir:
    file.directory:
        - name: '{{'/root' if parent == 'root' else '/etc/skel'}}/Maildir/'
        - user: root
        - group: root
        - mode: '0750'

{%-     for subdir in [ 'new', 'cur', 'tmp' ] %}

{{sls}}.maildir-setup-{{parent}}-Maildir-{{subdir}}:
    file.directory:
        - name: '{{'/root' if parent == 'root' else '/etc/skel'}}/Maildir/{{subdir}}'
        - user: root
        - group: root
        - mode: '0750'

{%-    endfor %}
{%- endfor %}
