
test-uuid-once:
    cmd.run:
        - name: echo {{ 'random' | uuid }}

test-uuid-again:
    cmd.run:
        - name: echo {{ 'random' | uuid }}

test-rand-hash-uuid:
    cmd.run:
        - name: echo {{ (99999 | random_hash | uuid)[0:8] }}

test-rand-hash-uuid-again:
    cmd.run:
        - name: echo {{ (99999 | random_hash | uuid)[0:8] }}

test-execution-module-uuid-short:
    cmd.run:
        - name: echo {{ salt.uuids.short() }}

test-execution-module-uuid-short-again:
    cmd.run:
        - name: echo {{ salt.uuids.short() }}

{%- set prefix, suffix = salt.uuids.ids({'suffix': '', 'prefix': '' }) %}

{{prefix}}test-execution-module-uuid-short-again{{suffix}}:
    cmd.run:
        - name: echo {{ ','.join(salt.uuids.ids({})) }}

{%- set prefix, suffix = salt.uuids.ids({'suffix': '', 'prefix': 'abc' }) %}

{{prefix}}test-execution-module-uuid-short-again{{suffix}}:
    cmd.run:
        - name: echo {{ ','.join(salt.uuids.ids({})) }}

{%- set prefix, suffix = salt.uuids.ids({'suffix': 'xyz', 'prefix': '' }) %}

{{prefix}}test-execution-module-uuid-short-again{{suffix}}:
    cmd.run:
        - name: echo {{ ','.join(salt.uuids.ids({})) }}

{%- set prefix, suffix = salt.uuids.ids({'suffix': 'xyz', 'prefix': 'abc' }) %}

{{prefix}}test-execution-module-uuid-short-again{{suffix}}:
    cmd.run:
        - name: echo {{ ','.join(salt.uuids.ids({})) }}
