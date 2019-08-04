{{ salt.loadtracker.load_pillar(sls) }}

deployments:
    ss-runners:
        deploy_type:     gitlab_runner_baremetal
        activated:       False
        activated_where: {{sls}}
        activate:
            service:
                enabled:
                    - gitlab-runner
        filesystem:
            defaults:
                user: gitlab-runner
                group: gitlab-runner
            dirs:
                /d/local/data/gitlab-runners:
                /d/local/data/gitlab-runners/docker:
                /d/local/data/gitlab-runners/dind:
                /d/local/data/gitlab-runners/k8s:
                /d/local/data/gitlab-runners/shell:

        config:
            run_as: gitlab-runner
            # Replace this with the correct token after gitlab installation
            registration_token: salt-secret:gitlab-runner-registration-token
            working_directory:  /d/local/data/gitlab-runners
            gitlab_host:        gitlab
            registration_flags: 
                - --env TEST_ENV=test                                      # Custom environment variables injected to build environment [$RUNNER_ENV]
                - --env REGISTER_LOCKED=false 
                # Register to run untagged builds; defaults to 'true' when 'tag-list' is empty [$REGISTER_RUN_UNTAGGED]
                #- --run-untagged
                - --locked=false                                          # Lock Runner for current project, defaults to 'true' [$REGISTER_LOCKED]
            executors:
                dind:
                    type: docker
                    registration_flags:
                        - --docker-image nexus:7082/library/docker:18.06.3-git
                        # - --docker-host gitlab
                        - --docker-dns 192.168.121.101
                        # Note that for docker-dind mode, you can't bind the docker.sock
                        # Also --docker-privileged is required for docker-in-docker
                        - --docker-privileged
                        - --docker-volumes /etc/docker/daemon.json:/etc/docker/daemon.json
                        - --docker-volumes "/cache"
                        - --docker-volumes "/etc/docker/certs.d:/etc/docker/certs.d"
                        #- --docker-extra-hosts ''
                        - --cache-dir /cache
                        - --tag-list dind
                        - --docker-pull-policy if-not-present 
                        - --docker-volume-driver overlay2
                        - --env "DOCKER_DRIVER=overlay2"
                        - --builds-dir /d/local/data/gitlab-runners/dind
                docker:
                    type: docker
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
                        - --env "DOCKER_DRIVER=overlay2"
                        - --builds-dir /d/local/data/gitlab-runners/docker

                shell:
                    type: shell
                    registration_flags:
                        - --tag-list shell
                        - --builds-dir /d/local/data/gitlab-runners/shell
                kubernetes:
                    type: kubernetes
                    registration_flags:
                        - --tag-list k8s
                        - --kubernetes-host infra
                        - --builds-dir /d/local/data/gitlab-runners/k8s
