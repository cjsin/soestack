{%- if 'svd' in pillar and 'cots' in pillar.svd and 'mattermost' in pillar.svd.cots %}
{%-     set version = pillar.svd.cots.mattermost.version %}
{%-     set hash    = pillar.svd.cots.mattermost.hash %}

.install:
    archive.extracted:
        - name:             /opt
        - source:           {{pillar.nexus.urls.interwebs}}/releases.mattermost.com/desktop/{{version}}/mattermost-desktop-{{version}}-linux-x64.tar.gz
        - if_missing:       /opt/mattermost-desktop-{{version}}
        - user:             root
        - group:            root
        - trim_output:      10
        - enforce_toplevel: True
        {%- if hash %}
        - source_hash:      {{hash}}
        {%- else %}
        - skip_verify:      True
        {%- endif %}

.symlink-dir:
    file.symlink:
        - name:     /opt/mattermost-desktop
        - target:   /opt/mattermost-desktop-{{version}}

.symlink-executable:
    file.symlink:
        - name:     /usr/local/bin/mattermost
        - target:   /opt/mattermost-desktop/mattermost-desktop

{%-     endif %}
