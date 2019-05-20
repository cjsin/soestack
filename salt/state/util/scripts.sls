#!stateconf yaml . jinja 

.salt-render:
    file.managed:
        - name: /usr/local/sbin/salt-render
        - user: root
        - group: root
        - mode: '0755'
        - contents: |
            #!/bin/bash
                salt-call slsutil.renderer /soestack/salt/state/${1//./\/}.sls jinja

