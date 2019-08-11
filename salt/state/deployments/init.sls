{#- NOTE that this file will run all deployments found in the pillar for #}
{#-   this node, as long as they were selected by a matcher such as hostname or role #}
{#- To run deployments of only a partiular type, run one of the other states within #}
{#- this directory, which will select only a particular type of deployment #}
{%- import 'lib/noop.sls' as noop %}

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
{%- set all_types = [] %}
{%- do all_types.extend(sequence_by_type) %}
{%- for x in by_type.keys() %}
{%-     if x not in all_types %}
{%-         do all_types.append(x) %}
{%-     endif %}
{%- endfor %}

{%- for deploy_type in all_types %}
{%-    set deployments_for_type = by_type[deploy_type] if deploy_type in by_type else [] %}

{%-    if not deployments_for_type %}
{{sls}}.no-deployments-for-type.{{deploy_type}}:
    noop.notice:
        - text: |
            No deployments with deploy_type={{deploy_type}} were found in pillar.deployments for this node.
{%-    endif %}

{%-    for pair in deployments_for_type %}
{%-        set deployment_name, deployment = pair %}
{%-        with args = { 'deployment_type': deploy_type, 'deployment': deployment, 'deployment_name': deployment_name, 'pillar_location': 'deployments:'~deployment_name, 'actions': ['auto'] } %}
{{noop.notice('run-deployment.'~deployment_name)}}
{%- if True %}
{%             include('templates/deployment.sls') with context %}
{%- endif %}
{%-        endwith %}
{%-    endfor %}
{%- endfor %}
