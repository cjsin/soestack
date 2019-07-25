{#- save the deployment args for reuse when including ipa_common #}
{%- set deployment_name = args.deployment_name %}
{%- set deployment      = args.deployment %}

{%- if 'activated' in deployment and deployment.activated not in ['', 'unset', 'false', 'no'] %}

{#-     # IPA is a bit different from other services in that it uses ipactl to start/stop #}
{#-     # and in addition here, if we modified the files above, we want to do a full restart #}
{%-     set running = salt['cmd.run'](['bash','-c','ipactl status 2> /dev/null | cut -d: -f2- | sort | uniq']).splitlines() %}

{{sls}}.{{deployment_name}}.running-status:
    noop.notice:
        - text: |
            {{running|json}}

{%-     set is_running     = 'RUNNING' in running %}
{%-     set is_stopped     = 'STOPPED' in running %}
{%-     set is_partially_running = is_stopped and is_running %}

{%-     if is_partially_running or is_stopped %}

{#- Perform an unconditional restart because some part of the service was not running #}
{{sls}}.{{deployment_name}}.reactivate-unconditional:
    cmd.run:
        - name:     ipactl restart

{%-     endif %}

{%- else %}

{{sls}}.{{deployment_name}}.deactivate:
    cmd.run:
        - name:     ipactl stop
        - onlyif:   ipactl status | grep RUNNING

{%- endif %}
