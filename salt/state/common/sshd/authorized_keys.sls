#!stateconf yaml . jinja

{#- The sshd config file is only updated if the data is not empty #}
{%- if 'ssh' in pillar and pillar.ssh and 'authorized_keys' in pillar.ssh %}
{%-     set authorized_keys = pillar.ssh.authorized_keys %}
{%-     if authorized_keys and 'root' in authorized_keys %}
{%-         if authorized_keys.root is mapping %}
.root-ssh-dir:
    file.directory:
        - name:  /root/.ssh
        - user:  root
        - group: root
        - mode:  '0700'

{%-         set text = [] %}
{%-         for keyname, keyval in authorized_keys.root.iteritems() %}
{%-             if keyval in ['','unset'] %}
.key-unset-{{keyname}}:
    noop.warning:
        - text: The ssh authorized key '{{keyname}}' is unset. This should be populated with a key after installation of the infra server.
{%-             else %}
{%-                 do text.append(keyval ~ ' ' ~ keyname) %}
{%-             endif %}
{%-         endfor %}

.root-authorized-keys:
    file.managed:
        - name:   /root/.ssh/authorized_keys
        - user:   root
        - group:  root
        - mode:   '0600'
        - contents: |
            {%- for item in text %}
            {{item}}
            {%- endfor %}

{%-         else %}
.unexpected-data:
    noop.error:
        - text: pillar value ssh:authorized_keys:root is expected to be a mapping
{%-         endif %}
{%-     else %}
.no-data:
    noop.notice:
        - text: pillar value ssh:authorized_keys:root is missing or empty
{%-     endif %}
{%- else %}
.no-data:
    noop.notice:
        - text: pillar value ssh:authorized_keys is missing
{%- endif %}
