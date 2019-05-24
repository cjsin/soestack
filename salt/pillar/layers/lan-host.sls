_loaded_layers:
    {{sls}}: {{[grains.layers.lan, grains.host]|json}}

{% include('layers/lan/' ~ grains.layers.lan ~ '/host/' ~ grains.host ~ '.sls') ignore missing %}
