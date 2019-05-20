{#- # wtf, it seems slspath is not set at all while processing pillar data #}
{#- # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%- set slspath = 'layers' %}
{%- set prefix = '/' if slspath else '' %}

# attempted_load:
#     {{slspath ~ '/host/' ~ grains.host ~ '.sls'}}:

{%- set roles = grains.roles if 'roles' in grains and grains.roles else  ( grains.role if 'role' in grains and grains.role else []) %}
{%- for role in roles %}
{%      include(slspath ~ prefix ~ 'role/' ~ role~ '.sls') ignore missing %}
{%- endfor %}
