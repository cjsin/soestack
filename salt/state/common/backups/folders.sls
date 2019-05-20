#!stateconf yaml . jinja

{%- if 'backups' in pillar %}

{%-     for pathname in ['jobs_bin', 'storage_dir'] %}
{%-         if pathname in pillar.backups %}

.{{pathname}}:
    file.directory:
        - name:        {{pillar.backups[pathname]}}
        - makedirs:    True
        - user:        root
        - group:       root
        - mode:        '0755'

{%-         endif %}
{%-     endfor %}
{%- endif %}

