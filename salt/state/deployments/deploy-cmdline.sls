{%- import 'lib/noop.sls' as noop %}
{%- set sls_parts = sls.split('.') %}
{%- set last_sls_part = sls_parts[-1] %}
{%- set cmdline_parameter = last_sls_part %}

{%- if 'cmdline-args' in pillar and pillar['cmdline-args'] and cmdline_parameter in pillar['cmdline-args']  %}
{%-     set cmdline_args = pillar['cmdline-args'][cmdline_parameter] %}
{%-     if 'deployments' in pillar %}

{%-         if 'deployment_name' in cmdline_args %}
{%-             set deployment_name = cmdline_args.deployment_name %}
{%-             if deployment_name in pillar.deployments %}
{%-                 set deployment = pillar.deployments[deployment_name] %}
{%-                 if 'deploy_type' in deployment %}
{%-                     set deployment_type = deployment.deploy_type %}
{%-                     set actions = cmdline_args.actions.split(',') if 'actions' in cmdline_args else ['auto'] %}
{%-                     with args = { 'deployment_type': deployment_type, 'deployment': deployment, 'deployment_name': deployment_name, 'pillar_location': 'deployments:'~deployment_name, 'actions': actions } %}
{%                          include('templates/deployment.sls') with context %}
{%-                     endwith %}
{%-                 else %}
{{noop.notice('The deployment '~deployment_name~' did not specify a value for deploy_type')}}
{%-                 endif %}
{%-            else %}
{{noop.notice('The deployment '~deployment_name~' was not found within pillar.deployments')}}
{%-            endif %}
{%-         elif 'deployment_type' in cmdline_args %}
{%-             set deployment_type = cmdline_args.deployment_type %}
{%-             with args = { 'deployment_type': deployment_type } %}
{%                  include('templates/deployments.sls') with context %}
{%-             endwith %}
{%-         else %}
{{noop.notice('No deployment_name or deployment_type was specified within cmdline-args')}}
{%-         endif %}
{%-     else %}
{{noop.notice('No deployment definitions were found within the pillar')}}
{%-     endif %}
{%- else %}
{{noop.notice('No commandline args were specified')}}
{%- endif %}
