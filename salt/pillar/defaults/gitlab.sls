# TODO - rework filewall configuration
firewall:
    ports:
        tcp:
            gitlab-http-frontend:
                8000: ACCEPT
            # gitlab-pages-frontend:
            #     8000: ACCEPT
            gitlab-nginx-status:
                8060: ACCEPT
            gitlab-alertmanager:
                9094: ACCEPT
            gitlab-registry:
                5005: ACCEPT
            
deployment:
    gitlab_baremetal:
        gitlab:
            config:
                ports:
                    gitlab_rails_registry_port: 5005
                    registry_nginx_listen_port: 5005
                    node_exporter_listen_port:  9101
                    http_frontend_port:         8000
                    pages_frontend_port:        8000

                hostname: gitlab
