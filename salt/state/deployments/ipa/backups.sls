#!stateconf yaml . jinja

{%- if salt.file.file_exists('/var/log/ipaserver-install.log') %}

include:
    - common.backups

.script:
    file.managed:
        - name: /usr/local/sbin/backups/jobs/ipa
        - user: root
        - group: root
        - mode: '0755'
        - contents: |
            #!/bin/bash
            ipa-backup -q --data --online

{%- endif %}
