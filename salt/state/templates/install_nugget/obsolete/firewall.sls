# This state is obsolete, replaced by support/firewall

{%- if 'firewall' in nugget and nugget.firewall %}
{%-     set firewall = nugget.firewall %}
{%-     if 'firewall-rule-sets' in firewall and 'nugget_data' in pillar and 'firewall-rule-sets' in pillar.nugget_data %}
{%-         set fwrs = pillar.nugget_data['firewall-rule-sets'] %}
{%-         for fw_ruleset_name in firewall['firewall-rule-sets'] %}
{%-             if fw_ruleset_name in fwrs %}
{%-                 with args = { 'firewall': fwrs[fw_ruleset_name] } %}
{%                      include('templates/support/firewall.sls') with context %}
{%-                 endwith %}
{%-             endif %}
{%-         endfor %}
{%-     endif %}
{%-     if 'firewall' in deployment and deployment.firewall %}
{%-         with args = { 'prefix': deployment_type ~ '-' ~ deployment_name, 'firewall': deployment.firewall, 'pillar_location': pillar_location } %}
{%              include('templates/support/firewall.sls') with context %}
{%-         endwith %}
{%-     endif %}
{%- endif %}
