#!stateconf yaml . jinja

.:
    cmd.run:
        - name: |
            mkdir -p /etc/yum.repos.d/disable/
            if ls /etc/yum.repos.d/bootstrap*repo > /dev/null
            then
                mv -f /etc/yum.repos.d/bootstrap*repo /etc/yum.repos.d/disable/
            fi
