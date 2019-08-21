#!stateconf yaml . jinja

{%- for expect in [ ['minrate','0'] , ['timeout','600'], ['ip_resolve','4'], ['fastestmirror','0'] ] %}
{%-     set expect_text= expect[0] ~ '='~ expect[1] %}

.fix-yum-for-mirror-use-{{expect[0]}}:
    cmd.run:
        - name:   sed -i -e '/{{expect[0]}}/ d' -e '$ p; n; a {{expect_text}}' /etc/yum.conf
        - unless: grep -q '{{expect_text}}' /etc/yum.conf

{%- endfor %}
