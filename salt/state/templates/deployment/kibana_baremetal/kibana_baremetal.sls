
{%- if 'versions' in pillar and 'cots' in pillar.versions and 'kibana' in pillar.versions.cots %}
{%-     set version = pillar.versions.cots.kibana.version %}

{{sls}}.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

{{sls}}.kibana-direct-download:
    pkg.installed:
        - sources: 
            - kibana: {{pillar.nexus.urls.elasticsearch}}/downloads/kibana/kibana-{{version}}-x86_64.rpm
        - hash:   {{pillar.versions.cots.kibana.hash}}

{%- endif %}
