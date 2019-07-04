
{%- if 'versions' in pillar and 'cots' in pillar.versions and 'elasticsearch' in pillar.versions.cots %}
{%-     set version = pillar.versions.cots.elasticsearch.version %}

{{sls}}.requirements:
    pkg.installed:
        - pkgs:
            - java-1.8.0-openjdk

{{sls}}.elasticsearch-direct-download:
    pkg.installed:
        - sources: 
            - elasticsearch: {{pillar.nexus.urls.elasticsearch}}/downloads/elasticsearch/elasticsearch-{{version}}.rpm
        - hash:   {{pillar.versions.cots.elasticsearch.hash}}

{%- endif %}
