#!stateconf yaml . jinja

{%- set selected = { } %}
{%- if 'yum' in pillar and pillar.yum is mapping and 'repos' in pillar.yum and pillar.yum.repos is mapping %}
{%-     set repos = pillar.yum.repos %}
{%-     set toplevel_defaults = repos.defaults if 'defaults' in repos else {} %}
{%-     for subkey, data in repos.iteritems() %}
{%-         if subkey != 'defaults' %}
{%-             if grains.os.lower() in subkey.lower().split(',') and data is mapping %}
{%-                 set os_defaults = data.defaults if 'defaults' in data else {} %}
{%-                 for reponame, repodata in data.iteritems() %}
{%-                     if reponame != 'defaults' and repodata is mapping %}
{%-                         set spec = {} %}
{%-                         do spec.update(toplevel_defaults) %}
{%-                         do spec.update(os_defaults) %}
{%-                         do spec.update(repodata) %}
{%-                         do selected.update({reponame: repodata})%}
{%-                     endif %}
{%-                 endfor %}
{%-             endif %}
{%-         endif %}
{%-     endfor %}
{%- endif %}

{%- for reponame, repodata in selected.iteritems() %}
{%-     set yum_repo_file = '/etc/yum.repos.d/' ~ reponame ~ '.repo' %}
{%-     set gpgkey = repodata.gpgkey if 'gpgkey' in repodata else '' %}
{%-     set gpgkey_url = 'file:///etc/pki/rpm-gpg/'~gpgkey if gpgkey and '/' not in gpgkey else gpgkey %}

.{{reponame}}:
    file.managed:
        - name:     '{{yum_repo_file}}'
        - user:     root
        - group:    root
        - mode:     '0644'
        - contents: |
            [{{reponame}}]
            name={{reponame}}
            description={{repodata.description}}
            baseurl={{repodata.baseurl}}
            enabled={{'1' if repodata.enabled else '0'}}
            gpgcheck={{'1' if repodata.gpgcheck else '0'}}
            {{'' if gpgkey_url else '#'}}gpgkey={{gpgkey_url}}

{%- endfor %}

