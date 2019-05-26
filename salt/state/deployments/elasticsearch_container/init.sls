{%- with args = { 'deployment_type': 'elasticsearch_container', 'actions': [ 'auto' ] } %}
{%      include('templates/deployments.sls') with context %}
{%- endwith %}
{# 
# elasticsearch config files are as follows:
# /usr/share/elasticsearch/config/
# /usr/share/elasticsearch/config/elasticsearch.yml
# /usr/share/elasticsearch/config/ingest-geoip
# /usr/share/elasticsearch/config/ingest-geoip/GeoLite2-ASN.mmdb
# /usr/share/elasticsearch/config/ingest-geoip/GeoLite2-City.mmdb
# /usr/share/elasticsearch/config/ingest-geoip/GeoLite2-Country.mmdb
# /usr/share/elasticsearch/config/jvm.options
# /usr/share/elasticsearch/config/log4j2.properties
# /usr/share/elasticsearch/config/role_mapping.yml
# /usr/share/elasticsearch/config/roles.yml
# /usr/share/elasticsearch/config/users
# /usr/share/elasticsearch/config/users_roles
# /usr/share/elasticsearch/config/elasticsearch.keystore
#}
