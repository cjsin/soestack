{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    
    ss-gitlab:
        deploy_type:     gitlab_baremetal
        activated:       False
        activated_where: {{sls}}
        roles:
            - gitlab-server-node
        activate:
            service:
                enabled:
                    - gitlab-runsvdir
            firewall:
                basic:
                    gitlab-frontend:
                        ip: '!!demo.ips.gitlab'
                        accept:
                            tcp:
                                http: 80
                    pages-frontend:
                        ip: '!!demo.ips.pages'
                        accept:
                            tcp:
                                http: 80
                    registry-frontend:
                        ip: '!!demo.ips.gitlab-registry'
                        accept:
                            tcp:
                                http: 5000
                    mattermost:
                        ip: '!!demo.ips.mattermost'
                        accept:
                            tcp:
                                http: 80
        config:
            hostname:           gitlab
            # Replace this with the correct token after gitlab installation
            registration_token: salt-secret:gitlab-runner-registration-token
            ports:
                #gitlab_rails_registry_port: 5005
                #registry_nginx_listen_port: 5005
                #node_exporter_listen_port:  9101
                gitlab_rails_registry_port: 5005
                registry_nginx_listen_port: 5005
                node_exporter_listen_port:  9101
                http_frontend_port:         8000
                pages_frontend_port:        8000



            registry_nginx:
                port:         5005

            gitlab:
                hostname:     gitlab
                port:         80
                bind_ip:      '!!demo.ips.gitlab'

            pages:
                enabled:      True
                hostname:     pages
                port:         80
                bind_ip:      '!!demo.ips.pages'

            registry:
                enabled:      True
                hostname:     gitlab-registry
                port:         5000
                bind_ip:      '!!demo.ips.gitlab-registry'

            mattermost:
                enabled:      True
                hostname:     mattermost
                port:         80
                bind_ip:      '!!demo.ips.mattermost'
                token:        unset
                app_id:       unset

            prometheus:
                enabled:  False

            grafana:
                enabled:  False

            node_exporter:
                enabled:  False

            unicorn:
                port:     18080

            storage:  
                path:     /d/local/data/gitlab/git-data
                
            backups:  
                path:     /d/local/data/gitlab-backups


