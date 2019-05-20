#!stateconf yaml . jinja

.requirements:
    pkg.installed:
        - pkgs:
            - rubygems

{%- if 'rubygems' in pillar and pillar.rubygems and 'mirror' in pillar.rubygems and pillar.rubygems.mirror %}

{%-     set mirror = pillar.rubygems.mirror %}

.user-gems-setup:
    file.managed:
        - name: /usr/local/bin/gems-user-setup
        - user: root
        - group: root
        - mode:  '0755'
        - contents: |
            {%- if mirror %}
            gem sources | grep "{{mirror}}" || gem sources --add "{{mirror}}"
            gem sources | grep rubygems.org && gem sources --remove https://rubygems.org/
            {%- endif %}

            gem list | grep -s bundle || gem install bundle

            {%- if mirror %}
            if ! bundle config | grep "{{mirror}}"
            then
                bundle config mirror.http://rubygems.org "{{mirror}}"
                bundle config
            fi
            {%- endif %}


.run-for-root:
    cmd.run:
        - name: /usr/local/bin/gems-user-setup
        - onlyif: test -f /usr/local/bin/gems-user-setup
        - unless: gem sources | grep "{{mirror}}" && bundle config | grep "{{mirror}}"

{%- endif %}
