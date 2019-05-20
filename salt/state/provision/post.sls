#!stateconf yaml . jinja

.record:
    cmd.run:
        - name: |
            mkdir -p /var/log/provision
            date > /var/log/provision/provisioned.log
            
