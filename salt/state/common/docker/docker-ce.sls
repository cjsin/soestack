#!stateconf yaml . jinja

#include:
#    - repos.dockerce

.remove-old:
    pkg.removed:
        - pkgs: 
            - docker-common
            - docker-client
            - docker
            - docker-forward-journald
            - docker-rhel-push-plugin
            - docker-v1.10-migrator
            - fedora-dockerfiles
            - docker-latest
            - docker-current
            - docker-client-latest
            - docker-client-current

.requirements:
    pkg.installed:
        - pkgs:
            - container-selinux
            - libtool-ltdl

.installed:
    pkg.installed:
        - fromrepo: dockerce
        - pkgs:
            - docker-ce

.sysctls:
    file.managed:
        - name: /etc/sysctl.d/99-docker.conf
        - contents: |
            net.bridge.bridge-nf-call-iptables = 1
            net.bridge.bridge-nf-call-ip6tables = 1

.config-dir:
    file.directory:
        - name: /etc/docker
        - user: root
        - group: root
        - mode: '0750'

.config:
    file.managed:
        - name: /etc/docker/daemon.json
        - contents: |
            {{pillar.docker.config.daemon|json()|indent(12)}}
        - user: root
        - mode: '0644'
        - group: root

.service:
    service.running:
        - name: docker
        - enable: True
        #- watch:
        #    - pkg:  common.docker.docker-ce::installed
        #    - file: common.docker.docker-ce::sysctls
        #    - file: common.docker.docker-ce::config
