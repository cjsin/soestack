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
{%- set work = [] %}


{%- if 'deployments' in pillar %}
{#-     # build a list of deployment objects - the actions will then be processed #}
{#-     # in order - so for example all install actions can be performed before all activate actions, if desired #}

{%-     set correct_type = [] %}
{%-     for deployment_name, deployment in pillar.deployments.iteritems() %}
{%-         set deploy_type = deployment.deploy_type if 'deploy_type' in deployment else 'basic' %}

{%-         if deployment_type == 'all' or deploy_type == deployment_type %}
{%-             do correct_type.append(deployment_name) %}

{%-             if diagnostics %}
{{sls}}.deployments.{{deployment_type}}.processing.{{deploy_type}}.{{deployment_name}}:
    noop.notice
{%-             endif %}

{%-             set pillar_location = ':'.join(['deployments',deployment_name]) %}

{%-             set matchers = {} %}
{%-             for style in ['host', 'role'] %}
{%-                 set a = deployment[style~'s'] if (style~'s') in deployment else [] %}
{%-                 set b = deployment[style].split(',') if style in deployment else [] %}
{%-                 if a or b %}
{%-                     do matchers.update({style: a+b}) %}
{%-                 endif %}
{%-             endfor %}

{%-             set matched = [] %}

{%-             for style, what in matchers.iteritems() %}
{%-                     for w in what %}
{%-                         if style == 'host' %}
{%-                             if grains.host == w or grains.host|regex_match('('~w~')') %}
{%-                                  do matched.append(w) %}
{%-                             endif %}
{%-                         elif style == 'role' %}
{%-                             if ('role' in grains and w == grains.role) or ('roles' in grains and w in grains.roles) %} 
{%-                                  do matched.append(w) %}
{%-                             endif %}
{%-                         endif %}
{%-                     endfor %}
{%-             endfor %}

{%-             if (not matchers) or matched %}
{%-                 do work.append({
                        'deployment_type': deploy_type,
                        'deployment_name': deployment_name, 
                        'deployment': deployment,
                        'pillar_location': pillar_location,
                        }) %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}
{%- endif %}


{%- if work %}
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
{%- elif correct_type %}

{{sls}}.deployments.no-deployments-in-pillar-matched-this-node--of-{{correct_type|length}}:
    noop.notice

{%- elif deployment_type == 'all' %}

{{sls}}.deployments.no-deployments-in-pillar-at-all:
    noop.notice

{%- else %}

{{sls}}.deployments.no-{{deployment_type}}-deployments-in-pillar:
    noop.notice

{%- endif %}
