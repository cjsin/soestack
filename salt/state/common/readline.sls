#!stateconf yaml . jinja 

.bracketed-mode:
    cmd.run:
        - name: echo "set enable-bracketed-paste off" >> /etc/inputrc
        - unless: grep enable-bracketed-paste /etc/inputrc
