{#- in real life, the objects wouldn't be processed in order #}
{#- this is just done here to test and get a working implementation #}
{%- if 'objects' in pillar %}
{%-   for this in pillar.objects %}
{%        include('object.sls') with context %}
{%-   endfor %}
{%- endif %}
