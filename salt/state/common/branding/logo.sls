#!stateconf yaml . jinja 

.logo:
    file.managed:
        - name: /usr/share/icons/soe-logo.png
        - user: root
        - group: root
        - mode:  '644'
        - template: py
        - source: salt://templates/base64decode.py
        - context: 
            contents_pillar: branding:logo
