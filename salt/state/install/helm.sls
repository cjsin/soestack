#!stateconf yaml . jinja 

{%- if 'svd' in pillar and 'cots' in pillar.svd and 'helm' in pillar.svd.cots %}

{%-     set svd = pillar.svd.cots.helm %}
{%-     set version = svd.version %}
{%-     set hash    = svd.hash if 'hash' in svd and svd.hash else '' %}

{%-     if 'google-storage' in pillar.nexus.urls %}
{%-         set baseurl = pillar.nexus.urls['google-storage'] %}

.helm-direct-download:
    archive.extracted:
        - name:             /opt/helm-{{version}}
        - source:           '{{baseurl}}/kubernetes-helm/helm-v{{version}}-linux-amd64.tar.gz'
        {%- if hash %}
        - source_hash:      '{{hash}}'
        {%- else %}
        - skip_verify:      True
        {%- endif %}
        - if_missing:       /opt/helm-{{version}}/helm
        - user:             root
        - group:            root
        - trim_output:      10
        - enforce_toplevel: False
        - options: '-v --strip-components=1'

.helm-version-symlink:
    file.symlink:
        - target: /opt/helm-{{version}}
        - name:   /opt/helm
        - onlyif: test -d /opt/helm-{{version}}

.helm-system-symlinks:
    file.symlink:
        - target: /opt/helm/helm
        - name:   /usr/local/bin/helm

.tiller-system-symlinks:
    file.symlink:
        - target: /opt/helm/tiller
        - name:   /usr/local/bin/tiller

{%-     else %}

.no-repository-configured:
    noop.notice:
        - text: There is no nexus repository configured for helm release downloads

{%-     endif %}

{%- else %}

.no-svd-configured:
    noop.notice:
        - text: Helm is not present with the svd version configuration area

{%- endif %}

