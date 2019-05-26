#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            mkdir -p /etc/yum.repos.d/disable/
            mv -f /etc/yum.repos.d/bootstrap*repo /etc/yum.repos.d/disable/
        - onlyif: ls /etc/yum.repos.d | egrep -i '^bootstrap.*[.]repo$'
