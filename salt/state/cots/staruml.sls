#!stateconf yaml . jinja

.:
    file.managed:
        - name:     /opt/bin/StarUML
        - makedirs: True
        - source: staruml: http://nexus:7081/repository/interwebs/s3.amazonaws.com/staruml-bucket/releases/StarUML-3.0.2-x86_64.AppImage
        - user: root
        - group: root
        - mode: 755
