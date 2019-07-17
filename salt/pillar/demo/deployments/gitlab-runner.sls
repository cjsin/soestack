{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    gitlab_runner_baremetal:
        gitlab-runner:
            activated: False
            activated_where: {{sls}}
            activate:
                service:
                    enabled:
                        - gitlab-runner
            filesystem:
                dirs:
                    /d/local/data/gitlab-runners:
                        user: root
                        group: root
                    /d/local/data/gitlab-runners/docker:
                        user: root
                        group: root
                    /d/local/data/gitlab-runners/kubernetes:
                        user: root
                        group: root
                    /d/local/data/gitlab-runners/shell:
                        user: gitlab-runner
                        group: gitlab-runner

            config:
                # Replace this with the correct token after gitlab installation
                registration_token: salt-secret:fuckgitlab-runner-registration-tokenbla

                gitlab_host:        gitlab
                registration_flags: 
                    - --env TEST_ENV=test                                      # Custom environment variables injected to build environment [$RUNNER_ENV]
                    - --env REGISTER_LOCKED=false 
                    - --run-untagged                                          # Register to run untagged builds; defaults to 'true' when 'tag-list' is empty [$REGISTER_RUN_UNTAGGED]
                    - --locked=false                                          # Lock Runner for current project, defaults to 'true' [$REGISTER_LOCKED]
                executors:
                    docker:
                        registration_flags:
                            - --docker-image nexus:7082/library/docker:18.06.3-git
                            # - --docker-host gitlab
                            - --docker-dns 192.168.121.101
                            - --docker-volumes /var/run/docker.sock:/var/run/docker.sock
                            - --docker-volumes /etc/docker/daemon.json:/etc/docker/daemon.json
                            #- --docker-extra-hosts ''
                            - --cache-dir /cache
                            - --tag-list docker
                            - --docker-pull-policy if-not-present 
                            - --docker-volume-driver overlay2
                            - --builds-dir /d/local/data/gitlab-runners/docker

                    shell:
                        registration_flags:
                            - --tag-list shell
                            - --builds-dir /d/local/data/gitlab-runners/shell
                    kubernetes:
                        registration_flags:
                            - --tag-list k8s
                            - --kubernetes-host infra
                            - --builds-dir /d/local/data/gitlab-runners/kubernetes
