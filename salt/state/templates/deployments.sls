{#
#
# This template will search the 'deployments' pillar key for any 
# deployments of the specified type, and generate states to implement
# each one, if the host matches
#

# This template expects the following context vars:
#  args:   a dict with the following keys
#   - deployment_type   - the name of the deployment type, or 'all'
#   - actions - a list containing one or more of 'install', or 'activate'

# Supports deploying something, with some standard behaviour:
# as defined by the following structure:

# deployments:
#     <deployment-type>:
#         <deployment-name>:
#             host: <hostname or regex>
#             hosts:
#                 - <hostname or regex>
#                 - <hostname or regex>
# 
#             <other deployment data> (see deployment.sls)
#
#}

{%  import 'lib/noop.sls' as noop %}
{%- set deployment_type = args.deployment_type if 'deployment_type' in args and args.deployment_type else 'all' %}
{%- set actions = args.actions if 'actions' in args else [ 'auto' ] %}
{%- set diagnostics = False %}
{%- set verbose = False %}

{%- if 'deployments' in pillar %}
{#-     # build a list of deployment objects - the actions will then be processed #}
{#-     # in order - so for example all install actions can be performed before all activate actions, if desired #}
{%-     set work = [] %}

{%-     for deploy_type, deployments in pillar.deployments.iteritems() %}

{%- if diagnostics %}
{{sls}}.deployments.{{deployment_type}}.processing.{{deploy_type}}:
    noop.notice
{%- endif %}

{%-         if deployment_type == 'all' or deploy_type == deployment_type %}

{%- if diagnostics %}
{{sls}}.deployments.{{deployment_type}}.correct-type.{{deploy_type}}:
    noop.notice:
        - text: {{deployments.keys()|json}}
{%- endif %}

{%-             for deployment_name, deployment in deployments.iteritems() %}

{%- if False %}
{{sls}}.deployments.{{deployment_type}}.found.{{deployment_name}}.processing:
    noop.pprint:
        - text: {{deployment_name}}
        - data: {{deployment|json}}

{%- endif %}

{%-                 set pillar_location = ':'.join(['deployments',deploy_type,deployment_name]) %}
{%-                 set hosts = deployment.hosts if 'hosts' in deployment else None %}
{%-                 set host = deployment.host if 'host' in deployment else None %}
{%-                 set matchers = [] %}
{%-                 do matchers.extend([host] if host else []) %}
{%-                 do matchers.extend(hosts if hosts else []) %}
{%-                 set matched = [] %}

{%-                 if not matchers %}
{{sls}}.deployments.{{deployment_type}}.{{deploy_type}}.{{deployment_name}}.has-no-matchers:
    noop.notice
{%-                 endif %}

{%-                 for item in matchers %}

{%- if diagnostics %}
{{sls}}.deployments.{{grains.host}}.attempted-match.{{item}}:
    noop.notice
{%- endif %}

{%-                     if grains.host == item or grains.host|regex_match('('~item~')') %}

{%- if diagnostics %}
{{sls}}.deployments.{{grains.host}}.successful-match.{{item}}:
    noop.notice
{%- endif %}

{%-                          do matched.append(item) %}
{%-                     else %}
{%- if diagnostics %}
{{sls}}.deployments.{{grains.host}}.did-not-match.{{item}}:
    noop.notice
{%- endif %}
{%-                     endif %}
{%-                 endfor %}
{%-                 if matched %}
{%-                     do work.append({
                            'deployment_type': deploy_type,
                            'deployment_name': deployment_name, 
                            'deployment': deployment,
                            'pillar_location': pillar_location,
                            }) %}
{%-                 endif %}
{%-             endfor %}
{%-         endif %}
{%-     endfor %}

{%-     for action in actions %}
{%-         if action in [ 'install', 'configure', 'activate', 'auto' ] %}
{%-             for item in work %}
{%-                 set deploy_args = {} %}
{%-                 do deploy_args.update(item) %}
{%-                 do deploy_args.update({'action': action}) %}
{%-                 with args = deploy_args %}
{%                      include('templates/deployment.sls') with context %}
{%-                 endwith %}
{%-             endfor %}
{%-        endif %}
{%-    endfor %}

{%- else %}

{{sls}}.deployments.no-deployments-in-pillar:
    noop.notice

{%- endif %}
