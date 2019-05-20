#!stateconf yaml . jinja

.install-requirements:
    pkg.installed:
        - pkgs:
            - libnotify
            - libappindicator
            - libXScrnSaver 

.install-drawio:
    pkg.installed:
        - sources: 
            - draw.io: http://nexus:7081/repository/github/jgraph/drawio-desktop/releases/download/v8.8.0/draw.io-x86_64-8.8.0.rpm

