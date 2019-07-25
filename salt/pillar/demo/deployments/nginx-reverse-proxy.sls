{{ salt.loadtracker.load_pillar(sls) }}

# NOTE: this configuration is incomplete
deployments:
    nginx-reverse-proxy:
        deploy_type: nginx_container
        roles:
            - nginx-frontend-node
        activated: False
        activated_where: {{sls}}
        activate:
            firewall:
                basic:
                    nexus-mirror-frontend:
                        ip: '!!demo.ips.nginx'
                        accept:
                            tcp:
                                http: 80
                                https: 443
            services:
                enabled:
                    - nginx-reverse-proxy
        container:
            description: Nginx reverse proxy
            volumes: 
                - -v /etc/nginx/nginx-reverse-proxy.conf:/etc/nginx/nginx.conf 
            ports:   
                -p 192.168.121.103:80 
                -p 192.168.121.103:443
            image:   library/nginx:1.15.3
            options: 
            mounts:
                /etc/nginx/nginx-reverse-proxy.conf: file
            storage: []
