#!stateconf yaml . jinja 

.repo:
    file.managed:
        - name: /etc/yum.repos.d/docker-ce.repo
        - user: root
        - group: root
        - mode:  '0644'
        - template: jinja
        - contents: |
            [docker-ce-stable]
            name=Docker CE Stable - $basearch
            baseurl={{pillar.nexus.repos.docker}}/linux/fedora/$releasever/$basearch/stable
            enabled=1
            gpgcheck=1
            gpgkey=file:///etc/pki/rpm-gpg/DOCKER-CE-GPG-SIGNING-KEY-fedora
            
            [docker-ce-edge]
            name=Docker CE Edge - $basearch
            baseurl={{pillar.nexus.repos.docker}}/linux/fedora/$releasever/$basearch/edge
            enabled=0
            gpgcheck=1
            gpgkey=file:///etc/pki/rpm-gpg/DOCKER-CE-GPG-SIGNING-KEY-fedora

