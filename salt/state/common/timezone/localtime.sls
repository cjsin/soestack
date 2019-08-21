#!stateconf yaml . jinja 
{%- if 'timezone' in pillar %}

{%-     set tzfile='/usr/share/zoneinfo/'+pillar.timezone %}
{%-     if not salt['file.file_exists'](tzfile) %}
.problem:
    noop.notice:
        - text: |
            Configured timezone '{{pillar.timezone}}' does not match a timezone within /usr/share/zoneinfo.
{%-     else %}

.:
    file.symlink:
        - name: /etc/localtime
        - target: '{{tzfile}}'

{%-     endif %}
{%- endif %}
