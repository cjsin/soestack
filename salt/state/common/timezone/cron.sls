#!stateconf yaml . jinja 
{%- if 'timezone' in pillar %}

.:
    cmd.run:
        - name:  sed -i -e 's/^TZ=.*//' -e '1 iTZ={{pillar.timezone}}\n' /etc/crontab
        - unless: grep -sxF 'TZ={{pillar.timezone}}' /etc/crontab

{%- endif %}
