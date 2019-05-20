#!stateconf yaml . jinja

/etc/Muttrc.local:
    file.managed:
        - user: root
        - group: root
        - mode: '0644'
        - contents: |
            # Local configuration for Mutt.
            #set folder="~/Maildir"
            #set mbox=+inbox
            #set spoolfile=+inbox
            #set mbox_type=Maildir
            #set move=no
            #set mbox_type=Maildir
            #Next configure the locations of the common folders:

            set folder="~/Maildir"
            set mask="!^\\.[^.]"
            set mbox="~/Maildir"
            set record="+.Sent"
            set postponed="+.Drafts"
            set spoolfile="~/Maildir"
            mailboxes `echo -n "+ "; find ~/Maildir -maxdepth 1 -type d -name ".*" -printf "+'%f' "`
            macro index c "<change-folder>?<toggle-mailboxes>" "open a different folder"
            macro pager c "<change-folder>?<toggle-mailboxes>" "open a different folder"
            macro index C "<copy-message>?<toggle-mailboxes>" "copy a message to a mailbox"
            macro index M "<save-message>?<toggle-mailboxes>" "move a message to a mailbox"

            macro compose A "<attach-message>?<toggle-mailboxes>" "attach message(s) to this message"
