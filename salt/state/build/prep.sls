#!stateconf yaml . jinja
{%- if 'build' in pillar and 'rpm' in pillar.build and 'defaults' in pillar.build.rpm %}

include:
    - common.rubygems
    - accounts.build-user
    
.build-tools:
    pkg.installed:
        - pkgs: 
            # rubygems is required to install fpm
            - rubygems
            - ruby-devel
            - redhat-rpm-config
            - rpm-build
            # compilers - needed to build Fpm anyway
            - gcc
            - gcc-c++  
            - make
            # sha256sum,md5sum utils
            - coreutils
            # for formatting the parameters
            - jq

.install-fpm:
    cmd.run:
        - name: gem install fpm
        - unless: gem list | grep ^fpm

.build-tmpdir:
    file.directory:
        - name:     {{pillar.build.rpm.defaults.tmp_builddir}}
        - makedirs: True
        - user: root
        - group: root
        - mode:  '0755'

.upload-script:
    file.managed:
        - name: /usr/local/sbin/upload-rpm
        - user: root
        - group: root
        - mode: '0755'
        - contents: |
            #!/bin/bash
            n=$(basename "${1}")
            if ! [[ "${n}" =~ [.]rpm$ ]]
            then 
                echo "ERROR: Not an rpm file: '${1}'"
                exit 1
            fi 
            d="soestack/demo"
            repo="built-rpms"
            url="http://nexus:7081/repository/${repo}/${d}/${n}"
            upload_pw=$(salt-secret pw-nexus-admin)
            curl -v --user 'admin' --upload-file  "${n}" "${url}" <<< "${upload_pw}"

{%- endif %}
