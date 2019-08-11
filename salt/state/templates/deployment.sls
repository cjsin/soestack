{#
# Processes deployments with the following structure
#
#         <deployment-name>:
#             install:
#                 nuggets-required:
#                     - <nugget-which-will-be-installed>
#                     - <another-nugget>
# 
#             activate:
#                 nuggets-required:
#                     - <nugget-which-will-be-activated>
#
#                 firewall: #<basic firewall support, same syntax as nugget firewall-rules>
#                     basic:
#                         <ruleset-name>:
#                             ip: <optional specific-destination-ip>
#                             from: <optional specific-source-ip>
#                             <accept,deny,...>:
#                                 tcp,udp,tcp/udp:
#                                     <port-name>: <port>
#                                     <port-range-name>: <port:port>
# 
#             filesystem: #<basic filesystem support, same syntax as nugget filesystem setup>
#                 # Templates that can be used for the file generation
#                 templates:
#                     example-config-2-yml: salt://path/to/template.jinja
#                     example-config-yml: |
#                         {%- raw %}
#                         http.host: "{{config.listen_address or '0.0.0.0'}}"
#                         xpack.monitoring.elasticsearch.url: {{config.xpack_elasticsearch_url or 'http://elasticsearch:9200'}}
#                         {%- endraw %}
# 
#                 # Default user/group,modes
#                 defaults:
#                     user:            1000
#                     group:           1000
#                     dir_mode:        '0750'
#                     file_mode:       '0644'
# 
#                 # Directory creation
#                 dirs:
#                     /etc/config:
#                         user:            root
#                         group:           root
# 
#                 # File creation, using template files or template text
#                 # defined above
#                 files:
#                     /etc/example/config1.yml:
#                         # This says to use the 'config' from the deployment
#                         config_pillar:   ':config'
#                         template:        example-config-yml
#                     /etc/example/config2.yml:
#                         config:
#                             example_value: foo
#                         template:        example-config-2-yml
# 
#  
#             config: <custom data dependent on the deployment>
#             
#             # custom data dependent on the deployment type
#             # for example with a container based service 
#             # this will be container:
#             <deployment-specific-key>:
#}

{% import 'lib/noop.sls' as noop %}
{%- set diagnostics = 'diagnostics' in pillar and sls in pillar.diagnostics %}
{%- set deployment_type  = args.deployment_type %}
{%- set deployment_name  = args.deployment_name %}
{%- set deployment       = args.deployment %}
{%- set stages           = deployment.stages if 'stages' in deployment else [ 'install', 'configure', 'activate' ] %}
{%- set pillar_location  = args.pillar_location if 'pillar_location' in args else ':'.join(['deployments',deployment_name]) %}
{%- set single_action    = [args.action] if 'action' in args and args.action else [] %}
{%- set multiple_actions = args.actions if 'actions' in args else [] %}
{%- set combined_actions = single_action + multiple_actions %}
{%- set auto_action      = [] if combined_actions else ['auto'] %}
{%- set actions          = [] %}
{%- set activated        = ('activated' not in deployment) or  deployment.activated %}
{%- set auto_mode        = 'auto' if 'auto' in combined_actions else ('' if combined_actions else 'auto') %}

{#- the intent of this section is that if specific actions have been specified, do those, but #}
{#- if an action 'auto' was specified, or no action were specified, then, only perform #}
{#- the activate action if the deployment was 'activated' #}
{%- if combined_actions %}
{%-     for s in stages %}
{%-         if s in combined_actions or auto_mode %}
{%-             if not ( auto_mode and s == 'activate' and not activated ) %}
{%-                 do actions.append(s) %}
{%-             endif %}
{%-        endif %}
{%-     endfor %}
{%- else %}
{#-     # No specific actions were specified, therefore execute all stages #}
{%-     for s in stages %}
{%-         if not (s == 'activate' and not activated ) %}
{%-             do actions.append(s) %}
{%-         endif %}
{%-     endfor %}
{%- endif %}

{%- set required_files  = deployment['require-exists'].file if 'require-exists' in deployment and 'file' in deployment['require-exists'] else {} %}

{%- set required_missing = [] %}

{%- for name,_val in required_files.iteritems() %}
{%-     if not salt['file.file_exists'](name) %}
{%-         do required_missing.append(name) %}
{%-     endif %}
{%- endfor %}

{%- if required_missing %}
{{sls}}.{{deployment_name}}.not-ready:
    noop.notice:
        - text: |
            This deployment cannot be run until after the following files are generated by other states:
            {%- for x in required_missing %}
            {{x}}
            {%- endfor %}
{%- else %}


{%-     if diagnostics %}

{{noop.notice(' '.join(['deployment', deployment_type, deployment_name])) }}

{{noop.pprint('actions-' ~ item.deployment_name, actions) }}

{%-     endif %}

{%-     for action in stages %}
{%-         if action in actions %}

{#-             # Call custom deployment handler #}
{%-             with args = { 
                        'deployment_name': deployment_name, 
                        'deployment_type': deployment_type, 
                        'deployment': deployment, 
                        'pillar_location': pillar_location,
                        'action': action 
                    } %}

{%-                 include 'templates/deploy.sls' with context %}
{%-             endwith %}

{%-         endif %}
{#-     end for each action #}
{%-     endfor %}
{%- endif %}
