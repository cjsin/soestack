_loaded:
    {{sls}}:

# NOTE: this configuration is incomplete
deployments:
    nginx_container:
        nginx-reverse-proxy:
            host:      infra
            activated: False
            activated_where: {{sls}}
            activate:
                firewall:
                    basic:
                        nexus-mirror-frontend:
                            ip: 192.168.121.103
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
