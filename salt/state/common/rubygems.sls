#!stateconf yaml . jinja

.requirements:
    pkg.installed:
        - pkgs:
            - rubygems

{%- if 'rubygems' in pillar and pillar.rubygems and 'mirror' in pillar.rubygems and pillar.rubygems.mirror %}

{%-     set mirror = pillar.rubygems.mirror %}

.user-gems-setup:
    file.managed:
        - name:     /usr/local/bin/gems-user-setup
        - user:     root
        - group:    root
        - mode:     '0755'
        - contents: |
            #!/bin/bash

            {%- if mirror %}
            gem sources | grep -s "{{mirror}}" || gem sources --add "{{mirror}}"
            gem sources | grep -s rubygems.org && gem sources --remove https://rubygems.org/
            {%- endif %}

            # Bundler released version 2.0 and decided to break compatibility entirely
            gem list | egrep -s '^bundler[[:space:]]' || gem install -v bundle "< 2.0"

            {%- if mirror %}
            if ! bundle config | grep "{{mirror}}"
            then
                bundle config mirror.http://rubygems.org "{{mirror}}"
                bundle config
            else
                exit 0
            fi
            {%- endif %}


.run-for-root:
    cmd.run:
        - name:   /usr/local/bin/gems-user-setup
        - onlyif: test -f /usr/local/bin/gems-user-setup
        - unless: gem sources | grep "{{mirror}}" && bundle config | grep "{{mirror}}"

{%- endif %}
