#!stateconf yaml . jinja

{%- if 'secrets' in pillar and 'distribute' in pillar.secrets %}
{%-     set distribute = pillar.secrets.distribute %}
{%-     set matched = [] %}
{%-     for secret_name, distribution in pillar.secrets.distribute.iteritems() %}
{%-         if grains.id in distribution %}
{%-             do matched.append(secret_name) %}

.receive-secret-{{secret_name}}:
    secrets.receive:
        - name: {{secret_name}}

{#-        - data: |
      {{salt['secrets.encrypt_secret_for'](secret_name, grains.id, use_base64=True)}}
            {{pillar.secrets[secret_name][grains.id]|indent(12)}}
#}

{%-         endif %}
{%-     endfor %}

{%-     if not matched %}

.no-secrets-configured-for-minion-{{grains.id}}:
    noop.notice

{%-     endif %}

{%- else %}

.no-secrets-data-in-pillar:
    noop.notice

{%- endif %}
