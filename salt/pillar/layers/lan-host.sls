{%- if 'lan' in grains.layers %}
_loaded_layers:
    {{sls}}: {{[grains.layers.lan, grains.host]|json}}
{%- else %}
    {{sls}}: {{['no lan layer set', grains.host]|json}}
{%- endif %}

{% include('layers/lan/' ~ grains.layers.lan ~ '/host/' ~ grains.host ~ '.sls') ignore missing %}
