{#- # wtf, it seems slspath is not set at all while processing pillar data #}
{#- # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%- set slspath = 'layers' %}
{%- set prefix = '/' if slspath else '' %}

# attempted_load:
#     {{slspath ~ '/host/' ~ grains.host ~ '.sls'}}:

{%  include(slspath ~ prefix ~ 'host/' ~ grains.host ~ '.sls') ignore missing %}
