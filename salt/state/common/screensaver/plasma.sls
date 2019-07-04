#!stateconf yaml . jinja

{%- if 'screensaver' in pillar and pillar.screensaver is mapping and 'x11' in pillar.screensaver and pillar.xscreensaver.x11 is mapping %}
{%-     set config = pillar.screensaver.x11 %}

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
            action/switch_user=true
            action/start_new_session=true
            shell_access=true
            run_desktop_files=true
            run_command=true
            movable_toolbars=true
            logout=true
            action/lock_screen=true
            lineedit_text_completion=true
            editable_desktop_icons=true
            screenlocker.desktop=false

            # prevent overriding locked-down config files. Important for enforcing screensaver settings.
            custom_config=false

            [ScreenSaver][$i]
            AutoLogout=true
            AutoLogoutTImeout=600
            Lock=true
            Enabled=true
            Timeout=60

.plasma-widgets:
    file.managed:
        - name:  /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc
        - user:  root
        - group: root
        - mode:  '0644'
        - makedirs: True
        - contents: |


{%- endif %}
