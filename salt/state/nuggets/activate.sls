{%- if 'nuggets' in pillar and pillar.nuggets and 'nuggets-activated' in pillar and pillar['nuggets-activated'] %}
{%-     for name in pillar['nuggets-activated'] %}
{%-         with args = { 'nugget_name': name } %}
{%              include('templates/nugget/activate.sls') with context %}
{%-         endwith %}
{%-     endfor %}
{%- endif %}
