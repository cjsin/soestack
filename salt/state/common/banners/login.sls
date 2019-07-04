#!stateconf yaml . jinja

{%- if 'legal' in pillar and pillar.legal is mapping %}
{%-     if 'banners' in pillar.legal and pillar.legal.banners is mapping %}
{%-         if 'login' in pillar.legal.banners %}

.:
    file.managed:
        - name: /etc/banner
        - contents: |
            {{pillar.legal.banners.etc|indent(12)}}
        - template: jinja
        - user:     root
        - group:    root
        - mode:     '0644'

{%-         endif %}
{%-     endif %}
{%- endif %}
