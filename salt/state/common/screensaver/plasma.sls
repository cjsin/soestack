#!stateconf yaml . jinja

{%- if 'screensaver' in pillar and pillar.screensaver is mapping and 'x11' in pillar.screensaver and pillar.xscreensaver.x11 is mapping %}
{%-     set empties = ['', 'unset'] %}
{%-     set cfg = pillar.screensaver.x11 %}
{%-     set lock_enabled = cfg['lock-enabled'] and lock_enabled not in empties %}
{%-     set idle_enabled = cfg['idle-enabled'] and idle_enabled not in empties %}
{%-     set idle_timeout = cfg['idle-timeout'] if 'idle-timeout' in cfg else 'unset' %}
{%-     set lock_timeout = cfg['lock-timeout'] if 'lock-timeout' in cfg else 'unset' %}
{%-     set idle_set     = idle_timeout not in empties %}
{%-     set lock_set     = lock_timeout not in empties %}
{%-     set timeout = lock_timeout if not idle_set else idle_timeout if not lock_set else lock_timeout if lock_timeout <= idle_timeout else idle_timeout %}

.kdeglobals:
    file.managed:
        - name:     /etc/xdg/kdeglobals
        - makedirs: True
        - user:     root
        - group:    root
        - mode:     '0644'
        {#- see https://userbase.kde.org/KDE_System_Administration/Kiosk/Keys#Screensavers #}
        - contents: |
            [KDE Resource Restrictions][$i]

            [KDE Action Restrictions][$i]
            gnhs=false
            opengl_screensavers=false
            manipulatescreen_screensavers=false
            lineedit_reveal_password=false
            #action/switch_user=true
            #action/start_new_session=true
            #shell_access=true
            #run_desktop_files=true
            #run_command=true
            #movable_toolbars=true
            logout=true
            lineedit_text_completion=true
            editable_desktop_icons=true
            screenlocker.desktop=false
            {%- if lock_set %}
            action/lock_screen=true
            {%- endif %}

            # prevent overriding locked-down config files. Important for enforcing screensaver settings.
            custom_config=false

            [ScreenSaver][$i]
            AutoLogout=true
            AutoLogoutTimeout=600
            
            {%- if lock_set %}
            Lock={{'false' if not lock_enabled else 'true'}}
            {%- endif %}
            {%- if lock_set or idle_set %}
            Enabled={{'false' if not lock_enabled and not idle_enabled else 'true'}}
            Timeout={{timeout}}
            {%- endif %}

.plasma-widgets:
    file.managed:
        - name:  /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc
        - user:  root
        - group: root
        - mode:  '0644'
        - makedirs: True
        - contents: |


{%- endif %}
