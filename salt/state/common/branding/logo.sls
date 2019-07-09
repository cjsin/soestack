#!stateconf yaml . jinja 

.logo:
    file.managed:
        - name: /usr/share/icons/soe-logo.png
        - contents_pillar: branding:logo
        - user: root
        - group: root
        - mode:  '644'
