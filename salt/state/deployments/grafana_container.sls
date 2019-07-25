#!stateconf yaml . jinja

{#- Generate a secret password before doing the install #}
{{sls}}.grafana.secret-setup:
    cmd.run:
        - name: salt-secret -list | grep pw-grafana-admin || generate-passwords grafana-admin -length=10 -passphrase

{{sls}}.grafana.secret-notice:
    noop.notice:
        - text: Grafana admin password can be accessed by the root account, using the command salt-secret grafana-admin

{%- with args = { 'deployment_type': 'grafana_container' } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
