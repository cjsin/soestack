#!stateconf yaml . jinja
{% import 'lib/noop.sls' as noop %}

{%- if 'runlevel' in pillar and pillar.runlevel %}
{%-    set runlevel = pillar.runlevel %}
{%-    if runlevel in [ 'multi-user', 'graphical' ] %}

{#-        # This is disabled for multi-user runlevel at least until systemd bug is fixed, where it hangs in 'systemctl isolate multi-user' #}
{%-        if runlevel not in ['multi-user'] %}

.set-default:
    cmd.run:
        - name:   systemctl set-default '{{runlevel}}'            
        - unless: systemctl get-default | grep '{{runlevel}}'

.isolate:
    cmd.run:
        - name:   systemctl isolate '{{runlevel}}'
        - unless: systemctl list-units --type target | egrep '^{{runlevel}}(|[.]target)[[:space:]].*loaded.active'

{%-         else %}
{{ noop.notice('Switching to multi-user runlevel disabled due to systemd bug/hang.') }}
{%-         endif %}
{%-     else %}
{{ noop.notice('Unrecognised runlevel '+runlevel) }}
{%-     endif %}
{%- else %}
{{ noop.notice('No system runlevel specified - runlevel will remain at system default') }}
{%- endif %}
