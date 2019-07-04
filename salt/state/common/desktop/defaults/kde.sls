#!stateconf yaml . jinja

{%- if 'desktop' in pillar and pillar.desktop is mapping and 'kde' in pillar.screensaver and pillar.xscreensaver.kde is mapping %}
{%-     set config = pillar.screensaver.kde %}

.kdeglobals:
    file.managed:
        - name:     /etc/xdg/system.kdeglobals
        - user:     root
        - group:    root
        - mode:     '0644'
        {#- see https://userbase.kde.org/KDE_System_Administration/Kiosk/Keys#Screensavers #}
        - contents: |
            [General]
            BrowserApplication[$e]=firefox.desktop
            TerminalApplication[$e]=terminator
            ColorScheme=Breeze
            fixed=Monospace,10,-1,5,50,0,0,0,0,0
            font=Sans Serif,10,-1,5,50,0,0,0,0,0
            menuFont=Sans Serif,10,-1,5,50,0,0,0,0,0
            smallestReadableFont=Sans Serif,8,-1,5,50,0,0,0,0,0
            toolBarFont=Sans Serif,9,-1,5,50,0,0,0,0,0
            widgetStyle=breeze
            desktopFont=Sans Serif,10,-1,5,50,0,0,0,0,0
            XftAntialias=true

            [KSpell]
            KSpell_Client=4
            KSpell_Encoding=11

            [K3Spell]
            K3Spell_Client=4
            K3Spell_Encoding=11

            [Icons]
            Theme=breeze

            [KDE]
            ColorScheme=Breeze
            widgetStyle=breeze
            DoubleClickInterval=400
            ShowDeleteCommand=false
            SingleClick=false
            StartDragDist=4
            StartDragTime=500
            WheelScrollLines=3

            [KFileDialog Settings]
            Automatically select filename extension=true
            Breadcrumb Navigation=true
            Decoration position=0
            LocationCombo Completionmode=5
            PathCombo Completionmode=5
            Show Bookmarks=true
            Show Full Path=true
            Show Preview=false
            Show Speedbar=true
            Show hidden files=true
            Sort by=Name
            Sort directories first=true
            Sort reversed=false
            Speedbar Width=132
            View Style=Simple
            listViewIconSize=0

            [KShortcutsDialog Settings]
            Dialog Size=866,480

            [PreviewSettings]
            MaximumRemoteSize=0

            [Translations]
            LANGUAGE=en_GB:en_US

            [Paths]
            Desktop[$e]=$(xdg-user-dir DESKTOP)
            Documents[$e]=$(xdg-user-dir DOCUMENTS)
            #Trash[$e]=$(xdg-user-dir DESKTOP)/Trash/

            [Toolbar style]
            Highlighting=true
            IconText=IconOnly
            TransparentMoving=true

            [WM]
            activeFont=Sans Serif,9,-1,5,50,0,0,0,0,0


{%- endif %}
