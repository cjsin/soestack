#!stateconf yaml . jinja
{% import 'lib/noop.sls' as noop %}

{%- if 'runlevel' in pillar and pillar.runlevel %}
{%-    set runlevel = pillar.runlevel %}

{%-    if runlevel in [ 'multi-user', 'graphical' ] %}

.set-default:
    cmd.run:
        - name:   systemctl set-default '{{runlevel}}'            
        - unless: systemctl get-default | grep '{{runlevel}}'

.isolate:
    cmd.run:
        - name:   systemctl isolate '{{runlevel}}'
        - unless: systemctl list-units --type target | egrep '^{{runlevel}}(|[.]target)[[:space:]].*loaded.active'
        
{%-     else %}

{{ noop.notice('Unrecognised runlevel '+runlevel) }}

{%-     endif %}

{%- else %}

{{ noop.notice('No system runlevel specified - runlevel will remain at system default') }}

{%- endif %}
