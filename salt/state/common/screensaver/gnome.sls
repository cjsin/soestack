#!stateconf yaml . jinja

.user-profile:
    file.managed:
        - name: /etc/dconf/profile/user
        - makedirs: True
        - user: root
        - group: root
        - mode:  '0644'
        - contents:
            user-db:user
            system-db:local

.system-db-local:
    file.managed:
        - name: /etc/dconf/db/local.d/00-screensaver
        - makedirs: True
        - user: root
        - group: root
        - mode:  '0644'
        - contents: |
            [org/gnome/desktop/session]
            # Set the lock time out to 180 seconds before the session is considered idle.
            idle-delay=180
            [org/gnome/desktop/screensaver]
            # Set this to true to lock the screen when the screensaver activates
            lock-enabled=true
            # Set the lock timeout to 180 seconds after the screensaver has been activated
            lock-delay=180

.lockdown:
    file.managed:
        - name: /etc/dconf/db/local.d/locks/screensaver
        - makedirs: True
        - user: root
        - group: root
        - mode:  '0644'
        - contents: |
            # Lock desktop screensaver settings
            /org/gnome/desktop/session/idle-delay
            /org/gnome/desktop/screensaver/lock-enabled
            /org/gnome/desktop/screensaver/lock-delay

.update-dconf:
    cmd.run:
        - name: dconf update
        - onchanges:
            - file: {{sls}}::user-profile
            - file: {{sls}}::system-db-local
            - file: {{sls}}::lockdown

