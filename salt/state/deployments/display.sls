{#- NOTE that this file will display all deployments found in the pillar for #}
{#-   this node, as long as they were selected by a matcher such as hostname or role #}
{#- To run deployments of only a partiular type, run one of the other states within #}
{#- this directory, which will select only a particular type of deployment #}

{%- set deployments = pillar.deployments if 'deployments' in pillar else {} %}

{#- The deployments are all gathered up by type here, so that they can #}
{#- be executed in a priorit order, if such an order was defined within the 'deployment-sequence' pillar key #}
{%- set by_type = {} %}

{%- for deployment_name, deployment in deployments.iteritems() %}
{%-     set deployment_type = deployment.deploy_type if 'deploy_type' in deployment else 'nugget' %}
{%-     set all_of_those = by_type[deployment_type] if deployment_type in by_type else [] %}
{%-     do all_of_those.append([deployment_name,deployment]) %}
{%-     do by_type.update({deployment_type: all_of_those})%}
{%- endfor %}

{%- set sequence_by_type = pillar['deployment-sequence'] if 'deployment-sequence' in pillar else by_type.keys() %}
{%- set none_found = [] %}

{{sls}}.would-deploy:
    noop.notice:
        - text: |
{%- for deploy_type in sequence_by_type %}
{%-    set deployments_for_type = by_type[deploy_type] if deploy_type in by_type else [] %}
{%-    if not deployments_for_type %}
{%-        do none_found.append(deploy_type) %}
{%-    else %}
            {%- for pair in deployments_for_type %}
            {%-     set deployment_name, deployment = pair %}
            {{deploy_type}} {{deployment_name}}
            {%- endfor %}
{%-    endif %}
{%- endfor %}

{%- if none_found %}
{{sls}}.would-not-deploy:
    noop.notice:
        - text: |
            {%- for x in none_found %}
            {{x}}
            {%- endfor %}
{%- endif %}
