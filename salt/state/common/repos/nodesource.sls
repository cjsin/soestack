#!stateconf yaml . jinja 

.repo:
    file.managed:
        - name:     /etc/yum.repos.d/nodesource.repo
        - user:     root
        - group:    root
        - mode:     '0644'
        - template: jinja
        - contents: |
            [nodesource]
            name=Node.js Packages for Fedora Linux $releasever - $basearch
            baseurl={{pillar.nexus.repos.nodesource}}/pub_10.x/fc/$releasever/$basearch
            baseurl=https://rpm.nodesource.com/pub_10.x/fc/$releasever/$basearch
            failovermethod=priority
            enabled=1
            gpgcheck=1
            gpgkey=file:///etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL
