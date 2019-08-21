{{ salt.loadtracker.load_pillar(sls) }}

# NOTE: this configuration is incomplete
deployments:
    ss-nginx-reverse-proxy:
        deploy_type: nginx_container
        roles:
            - nginx-frontend-node
        activated: False
        activated_where: {{sls}}
        activate:
            firewall:
                basic:
                    ss-nginx-reverse-proxy:
                        ip: '!!demo.ips.nginx'
                        accept:
                            tcp:
                                http: 80
                                https: 443
            services:
                enabled:
                    - ss-nginx-reverse-proxy
        container:
            description: Nginx reverse proxy
            volumes: 
                - -v /etc/nginx/ss-nginx-reverse-proxy.conf:/etc/nginx/nginx.conf 
            ports:   
                -p 192.168.121.103:80 
                -p 192.168.121.103:443
            image:   library/nginx:1.15.3
            options: 
            mounts:
                /etc/nginx/ss-nginx-reverse-proxy.conf: file
            storage: []
