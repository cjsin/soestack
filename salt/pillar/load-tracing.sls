_loads:
    {%- for l in salt.loadtracker.loaded_pillars() %}
    - {{l|join(' ')}}
    {%- endfor %}
