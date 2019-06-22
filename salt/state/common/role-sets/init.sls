include:
    {%- if 'roles' in grains and grains.roles == 'auto' %}
    - .auto
    {%- else %}
    - .apply
    {%- endif %}
