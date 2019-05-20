#!stateconf yaml . jinja

.send-test-email:
    cmd.run:
        - name: |
            date | mail -s test root@localhost 
            