#!stateconf yaml . jinja

{%- if 'screensaver' in pillar and pillar.screensaver is mapping and 'x11' in pillar.screensaver and pillar.xscreensaver.x11 is mapping %}
{%-     set screensaver_config = pillar.screensaver.x11 %}
{%-     set idle_timeout_seconds = screensaver_config['idle-timeout'] %}
{%-     set lock_timeout_seconds = screensaver_config['lock-timeout'] %}
{%-     set lock_enabled = screensaver_config['lock-enabled'] %}

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
            {%- if idle_timeout_seconds != 'unset' %}
            [org/gnome/desktop/session]
            # Set the lock time out to 180 seconds before the session is considered idle.
            idle-delay={{idle_timeout_seconds}}
            {%- endif %}
            [org/gnome/desktop/screensaver]
            # Set this to true to lock the screen when the screensaver activates
            {%- if lock_enabled != 'unset' %}
            lock-enabled={{'false' if not idle_lock else 'true'}}
            {%- endif %}
            {%- if idle_lock_seconds != 'unset' %}
            # Set the lock timeout to 180 seconds after the screensaver has been activated
            lock-delay={{screensaver_config['lock-timeout']}}
            {%- endif %}

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

{%- endif %}
