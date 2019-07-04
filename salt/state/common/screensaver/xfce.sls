#!stateconf yaml . jinja

{%- if 'screensaver' in pillar and pillar.screensaver is mapping and 'x11' in pillar.screensaver and pillar.xscreensaver.x11 is mapping %}
{%-     set config = pillar.screensaver.x11 %}

.kioskrc:
    file.managed:
        - name:     /etc/xdg/xfce4/kiosk/kioskrc
        - user:     root
        - group:    root
        - mode:     '0644'
        {#- see https://wiki.xfce.org/howto/kiosk_mode #}
        - contents: |
            [xfce4-panel] 
            {#- This allows only users in the group powerusers and the user foo to customize their panels. #}
            # CustomizePanel=%powerusers,foo

            [xfce4-session]
            CustomizeSplash=ALL
            CustomizeChooser=ALL
            CustomizeLogout=ALL
            CustomizeCompatibility=%wheel
            #Shutdown=%wheel
            CustomizeSecurity=NONE

            [xfdesktop]
            #UserMenu=%wheel
            CustomizeBackdrop=ALL
            CustomizeDesktopMenu=%wheel
            CustomizeWindowlist=NONE
            CustomizeDesktopIcons=ALL
{%- endif %}
