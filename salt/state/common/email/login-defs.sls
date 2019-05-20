#!stateconf yaml . jinja

#/etc/login.defs: 
#    cmd.run:
#        - name:   sed -i -e '/MAIL_DIR/ s/.*/MAIL_DIR Maildir/' /etc/login.defs
#        - unless: egrep '^MAIL_DIR Maildir/' /etc/login.defs

