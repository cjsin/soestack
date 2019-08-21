#!stateconf yaml . jinja

.send-test-email:
    cmd.run:
        - name: |
            date | MAILRC=/etc/mail.rc mailx -n -s test root@localhost 
