
tests:
    defaults:
        curl:
            server: {{grains.fqdn_ip4[0]}}
            proto: http
        service:
            status: exists,enabled,running
    ss-pxe:
        curl:
            path: /
            port: 9001
            good: pxelinux.0
            bad:
        service: {}

    ss-bundled:
        curl:
            path: /bootstrap-pkgs/epel/
            port: 9002
            good: repodata/
            bad:
        service: {}

    ss-docs:
        curl:
            server: '!!demo.ips.docs'
            path: /
            port: 80
            good: SoeStack.*documentation
            bad:
        service: {}

    ss-elk:
        service:
            status: exists

    ss-elk-1:
        curl:
            server: '!!demo.ips.elasticsearch'
            path: /
            port: 9200
            good: 
            bad:

    ss-elk-2:
        curl:
            server: '!!demo.ips.elasticsearch'
            path: /
            port: 9300
            good: 
            bad:

    ss-kibana:
        curl:
            server: '!!demo.ips.kibana'
            path: /
            port: 80
            good: 
            bad:
        service:
            status: exists

    ss-grafana:
        curl:
            server: '!!demo.ips.grafana'
            path: /login
            port: 80
            good: grafana-app
            bad:
        service: {}

    cups:
        curl:
            path: /
            port: 631
            good: 
            bad:
        service: {}

    ss-nexus-mirror:
        service: {}

    {%- for port in range(7081,7084) %}
    ss-nexus-mirror-{{loop.index}}:
        curl:
            server: '!!demo.ips.nexus'
            path: /
            port: {{port}}
            good: Nexus.Repository.Manager
            bad:
    {%- endfor %}
    
    ss-node-exporter:
        curl:
            path: /metrics
            port: 9100
            good: ^node_exporter_build_info
            bad:
        service: {}

