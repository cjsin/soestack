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

{%- set diagnostics      = False %}
{%- set deployment_type  = args.deployment_type %}
{%- set deployment_name  = args.deployment_name %}
{%- set deployment       = args.deployment %}
{%- set pillar_location  = args.pillar_location if 'pillar_location' in args else ':'.join(['deployments',deploy_type,deployment_name]) %}
{%- set single_action    = [args.action] if 'action' in args and args.action else ['auto'] %}

{%- set multiple_actions = args.actions if 'actions' in args else [] %}
{%- set actions          = [] %}
{%- set activated        = 'activated' in deployment and deployment.activated %}

{%- for act in multiple_actions+single_action %}
{%-     if act == 'auto' %}
{%-         if 'install' not in actions %}
{%-             do actions.append('install') %}
{%-         endif %}
{%-         if 'configure' not in actions %}
{%-             do actions.append('configure') %}
{%-         endif %}
{%-         if activated and 'activate' not in actions %}
{%-             do actions.append('activate') %}
{%-         endif %}
{%-     elif act not in actions %}
{%-         do actions.append(act) %}
{%-     endif %}
{%- endfor %}

{%- if diagnostics %}

{{noop.notice(' '.join(['deployment', deployment_type, deployment_name])) }}

{{noop.pprint('actions-' ~ item.deployment_name, actions) }}

{%- endif %}


{%- for action in [ 'install', 'configure', 'activate' ] %}

{%-     if action in actions %}

{#-         # Install the base nugget class - that has a name matching the deployment type #}
{%-         set base_nugget_type = deployment_type.replace('_','-') %}

{%-         if diagnostics %}
{{sls}}.{{deployment_name}}.{{action}}.base-nugget-type.{{base_nugget_type}}:
    noop.notice
{%-         endif %}

{%-         if 'nuggets' in pillar and pillar.nuggets and base_nugget_type in pillar.nuggets %}

{%-             if diagnostics %}
{{noop.notice(' '.join(['deployment', deployment_type, deployment_name, action, action~'-base-nugget', base_nugget_type])) }}
{%-             endif %}

{%-             with args = { 'nugget_name': base_nugget_type} %}
{%                  include('templates/nugget/'~action~'.sls') with context %}
{%-             endwith %}
{%-         endif %}

{#-         # Install this deployment as a nugget itself #}
{%-         with args = { 'nugget': deployment, 
                          'nugget_name': '-'.join([deployment_type,'deployment',deployment_name]), 
                          'pillar_location': pillar_location, 
                          'action': action 
                        } %}

{%-             if diagnostics %}
{{noop.notice(' '.join(['deployment', deployment_type, deployment_name,action,'install-instance-as-nugget'])) }}
{%-             endif %}

{%              include('templates/nugget/'~action~'.sls') with context %}
{%-         endwith %}

{#-         # Call custom deployment handler #}
{%-         with args = { 'deployment_name': deployment_name, 
                  'deployment_type': deployment_type, 
                  'deployment': deployment, 
                  'pillar_location': pillar_location,
                  'action': action } %}

{%- if diagnostics %}
{{noop.notice(' '.join(['deployment', deployment_type, deployment_name,action,'custom-deployment-handler'])) }}
{%- endif %}

{%              include('templates/deployment/'~deployment_type~'/'~deployment_type~'.sls') with context %}

{%-         endwith %}
{%-     endif %}
{#- end for each action #}
{%- endfor %}

