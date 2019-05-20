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

{%  import 'lib/noop.sls' as noop %}
{%- set deployment_type = args.deployment_type if 'deployment_type' in args and args.deployment_type else 'all' %}
{%- set actions = args.actions if 'actions' in args else [ 'auto' ] %}

{%- if 'deployments' in pillar %}
{#-     # build a list of deployment objects - the actions will then be processed #}
{#-     # in order - so for example all install actions can be performed before all activate actions, if desired #}
{%-     set work = [] %}

{%-     for deploy_type, deployments in pillar.deployments.iteritems() %}
{%-         if deployment_type == 'all' or deploy_type == deployment_type %}
{%-             for deployment_name, deployment in pillar.deployments[deploy_type].iteritems() %}
{%-                 set pillar_location = ':'.join(['deployments',deploy_type,deployment_name]) %}
{%-                 set hosts = deployment.hosts if 'hosts' in deployment else None %}
{%-                 set host = deployment.host if 'host' in deployment else None %}
{%-                 set matchers = [] %}
{%-                 do matchers.extend([host] if host else []) %}
{%-                 do matchers.extend(hosts if hosts else []) %}
{%-                 set matched = [] %}
{%-                 for item in matchers %}
{%-                     if grains.host == item or grains.host|regex_match('('~item~')') %}
{%-                          do matched.append(item) %}
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

{%- endif %}
