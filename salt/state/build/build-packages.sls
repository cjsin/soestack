{%- if 'build' in pillar and 'rpm' in pillar.build and pillar.build.rpm %}
{%-     for name in pillar.build.rpm.keys() %}
{%-         if name != 'defaults' %}
{%              set args = { 'pkgname': name } %}
{%              include('templates/build/build_package.sls') with context %}
{%-         endif %}
{%-     endfor %}
{%- endif %}
