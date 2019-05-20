#!stateconf yaml . jinja

{%- if 'bash' in pillar %}

.bash-custom:
    file.managed:
        - name:     /etc/bashrc-custom
        - mode:     '0644'
        - user:     root
        - group:    root
        - source:   salt://{{slspath}}/files/bashrc-custom.sh.jinja
        - template: jinja
        - context:
            bash: {{pillar.bash|json()}}

.include:
    cmd.run:
        - name: echo ". /etc/bashrc-custom" >> /etc/bashrc
        - unless: grep bashrc-custom /etc/bashrc

{%- endif %}
