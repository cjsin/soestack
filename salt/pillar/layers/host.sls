{{ salt.loadtracker.load_pillar(sls) }}

_loaded_layers:
    {{sls}}: {{grains.host}}

{#- # wtf, it seems slspath is not set at all while processing pillar data #}
{#- # so it is hard coded here for now, but should raise a bug or feature request with saltstack #}
{%- set slspath = 'layers' %}
{%- set prefix = '/' if slspath else '' %}

{%  include(slspath ~ prefix ~ 'host/' ~ grains.host ~ '.sls') ignore missing %}
