#!stateconf yaml . jinja

.:
    file.managed: 
        - name:     /etc/mail.rc
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - source:   salt://{{slspath}}/mail.rc.jinja
