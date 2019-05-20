{%- if 'nuggets' in pillar and pillar.nuggets and 'nuggets-installed' in pillar and pillar['nuggets-installed'] %}
{%-     for name in pillar['nuggets-installed'] %}
{%-         with args = { 'nugget_name': name } %}
{%              include('templates/nugget/install.sls') with context %}
{%-         endwith %}
{%-     endfor %}
{%- endif %}
