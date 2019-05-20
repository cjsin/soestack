#!stateconf yaml . jinja

.prepare:
    file.directory:
        - name: /var/log/provision
        - user: root
        - group: root
        - mode: '0755'
