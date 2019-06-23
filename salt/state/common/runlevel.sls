#!stateconf yaml . jinja
{% import 'lib/noop.sls' as noop %}

{%- if 'runlevel' in pillar and pillar.runlevel %}
{%-    set runlevel = pillar.runlevel %}
{%-    if runlevel in [ 'multi-user', 'graphical' ] %}

.set-default:
    cmd.run:
        - name:   systemctl set-default '{{runlevel}}'            
        - unless: systemctl get-default | grep '{{runlevel}}'

{%-         if runlevel in [ 'graphical' ] %}
{#-             # if trying to switch to graphical runlevel, systemd needs to be #}
{#-             # forced to reload multi-user target first #}
{#-             # otherwise, it fails to start various services needed for desktop login #}
.force-multi-user-first:
    cmd.run:
        - name:   systemd-bugfix-change-runlevel --force 3
        - unless: systemctl list-units --type target | egrep '^{{runlevel}}(|[.]target)[[:space:]].*loaded.active[[:space:]]+active'
{%-         endif %}

.isolate:
    cmd.run:
        - name:   systemd-bugfix-change-runlevel --force '{{runlevel}}'
        - unless: systemctl list-units --type target | egrep '^{{runlevel}}(|[.]target)[[:space:]].*loaded.active[[:space:]]+active'

{%-     else %}
{{ noop.notice('Unrecognised runlevel '+runlevel) }}
{%-     endif %}
{%- else %}
{{ noop.notice('No system runlevel specified - runlevel will remain at system default') }}
{%- endif %}
