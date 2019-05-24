_loaded:
    {{sls}}:

deployments:
    gitlab_baremetal:
        gitlab:
            host: infra
            activated: False
            activated_where: {{sls}}
            activate:
                service:
                    enabled:
                        - gitlab-runsvdir
                firewall:
                    basic:
                        gitlab-frontend:
                            ip: 192.168.121.104
                            accept:
                                tcp:
                                    http: 80
                        pages-frontend:
                            ip: 192.168.121.106
                            accept:
                                tcp:
                                    http: 80
                        registry-frontend:
                            ip: 192.168.121.107
                            accept:
                                tcp:
                                    http: 5000
                        mattermost:
                            ip: 192.168.121.105
                            accept:
                                tcp:
                                    http: 80

            config:
                ports:
                    #gitlab_rails_registry_port: 5005
                    #registry_nginx_listen_port: 5005
                    #node_exporter_listen_port:  9101

                registry_nginx:
                    port:         5005

                gitlab:
                    hostname:     gitlab
                    port:         80
                    bind_ip:      192.168.121.104

                pages:
                    enabled:      True
                    hostname:     pages
                    port:         80
                    bind_ip:      192.168.121.106

                registry:
                    enabled:      True
                    hostname:     gitlab-registry
                    port:         5000
                    bind_ip:      192.168.121.107

                mattermost:
                    enabled:      True
                    hostname:     mattermost
                    port:         80
                    bind_ip:      192.168.121.105
                    token:        a29362af4cf0ad81466ead3ae8d82d78b295563b826f77496336c43ac5c3b2cb
                    app_id:       ecdd5b5f4d9967e6bf342e8d34519f51f88ceed91634963cfb1591f6b2f8b4f6

                prometheus:
                    enabled:  False

                node_exporter:
                    enabled:  False

                unicorn:
                    port:     18080

                storage:  
                    path:     /d/local/gitlab/git-data
                    
                backups:  
                    path:     /d/local/gitlab-backups

  
