{{ salt.loadtracker.load_pillar(sls) }}

nugget_data:

    package-sets:

        pgp-keyserver:
            centos,rhel,fedora:
                - sks
                - nginx

nuggets:

    pgp-keyserver:
        description: |
            provides a PGP keyserver

        install:
            installed:
                package-sets:
                    - pgp-keyserver
        
        # NOTE that we do not enable services because the service needs to be configured first
        
        filesystem:
            defaults:
                user:  sks
                group: sks
                dir_mode: '0755'
                file_mode: '0644'
            dirs:

                /srv:

                /etc/systemd/system-preset:
                    user: root
                    group: root

                /srv/sks:
                    mode:  '0755'
                    makedirs: True

                /srv/sks/web:

                /srv/sks/nginx:
                    user:  nginx
                    group: nginx
                    mode:  '0755'
                    makedirs: True

                /srv/sks/nginx/html:
                    user:  nginx
                    group: nginx
                    mode:  '0755'
                    makedirs: True

                /etc/systemd/system/sks-db.service.d:
                    user: root
                    group: root

            symlinks:
                /srv/sks/web/index.html:
                    target: /usr/share/doc/sks-1.1.6/sampleWeb/HTML5/index.html
                /srv/sks/nginx/html/index.html:
                    user:  nginx
                    group: nginx
                    mode:  '0755'
                    target: /usr/share/doc/sks-1.1.6/sampleWeb/HTML5/index.html

            templates: 
                {% raw %}
                sks_conf: |
                    debuglevel:                     {{config.debuglevel}}
                    hostname:                       {{config.hostname}}
                    hkp_address:                    127.0.0.1
                    hkp_port:                       11371
                    recon_port:                     11370
                    server_contact:                 {{config.contact}}
                    initial_stat:
                    disable_mailsync:
                    membership_reload_interval:     1
                    stat_hour:                      12
                    max_matches:                    500

                sks_nginx_conf: |
                    user nginx;
                    worker_processes 4;
                    pid /run/sks-web.pid;

                    events {
                        worker_connections 768;
                    }

                    http {
                        sendfile    on;
                        tcp_nopush  on;
                        tcp_nodelay on;
                        client_max_body_size 8m;

                        access_log  /srv/sks/nginx/access.log;
                        error_log   /srv/sks/nginx/error.log;
                        rewrite_log on;

                        include /etc/nginx/mime.types;

                        #----------------------------------------------------------------------
                        # OpenPGP Public SKS Key Server
                        #----------------------------------------------------------------------

                        server {
                            listen {{config.nginx.bind_ip}}:11371 default_server;

                            server_name *.sks-keyservers.net;
                            server_name *.pool.sks-keyservers.net;
                            server_name pgp.mit.edu;
                            server_name keys.gnupg.net;
                            server_name {{config.hostname}};
                            server_name {{config.nginx.bind_ip}};

                            root /srv/sks/nginx/html;

                            rewrite ^/stats /pks/lookup?op=stats;
                            rewrite ^/s/(.*) /pks/lookup?search=$1;
                            rewrite ^/search/(.*) /pks/lookup?search=$1;
                            rewrite ^/g/(.*) /pks/lookup?op=get&search=$1;
                            rewrite ^/get/(.*) /pks/lookup?op=get&search=$1;
                            rewrite ^/d/(.*) /pks/lookup?op=get&options=mr&search=$1;
                            rewrite ^/download/(.*) /pks/lookup?op=get&options=mr&search=$1;

                            location /pks {
                                proxy_pass         http://127.0.0.1:11371;
                                proxy_pass_header  Server;
                                add_header         Via "1.1 {{config.hostname}}:11371 (nginx)";
                                proxy_ignore_client_abort on;
                                client_max_body_size 8m;
                            }
                        }
                    }
                {% endraw %}

            files:

                # This is en example, but this file should be added in 
                # a deployment with access to a config_pillar with the correct values
                #/srv/sks/sksconf:
                #    user: sks
                #    group: sks
                #    mode: '0644'
                #    template: sks_conf
                #    config_pillar:   :config
                #/srv/sks/nginx.conf:
                #    user: sks
                #    group: sks
                #    mode: '0644'
                #    template: sks_nginx_conf
                #    config_pillar:   :config

                /srv/sks/DB_CONFIG:
                    user: sks
                    group: sks
                    contents: |
                        set_mp_mmapsize         268435456
                        set_cachesize    0      134217728 1
                        set_flags               DB_LOG_AUTOREMOVE
                        set_lg_regionmax        1048576
                        set_lg_max              104857600
                        set_lg_bsize            2097152
                        set_lk_detect           DB_LOCK_DEFAULT
                        set_tmp_dir             /tmp
                        set_lock_timeout        1000
                        set_txn_timeout         1000
                        mutex_set_max           65536

                /etc/systemd/system/sks-web.service:
                    user: root
                    group: root
                    contents: |
                        [Unit]
                        Description=Nginx frontend for SKS keyserver
                        After=network.target remote-fs.target nss-lookup.target

                        [Service]
                        Type=forking
                        PIDFile=/run/sks-web.pid
                        WorkingDirectory=/srv/sks
                        # Nginx will fail to start if /run/nginx.pid already exists but has the wrong
                        # SELinux context. This might happen when running `nginx -t` from the cmdline.
                        # https://bugzilla.redhat.com/show_bug.cgi?id=1268621
                        ExecStartPre=/usr/bin/rm -f /run/sks-web.pid
                        ExecStartPre=/usr/sbin/nginx -t -c /srv/sks/nginx.conf
                        ExecStart=/usr/sbin/nginx -c /srv/sks/nginx.conf
                        ExecReload=/bin/kill -s HUP $MAINPID
                        KillSignal=SIGQUIT
                        TimeoutStopSec=5
                        KillMode=process
                        PrivateTmp=true

                        [Install]
                        WantedBy=sks-db.service

                /etc/systemd/system/sks-db.service.d/preconfigure.conf:
                    user: root
                    group: root
                    contents: |
                        [Service]
                        ExecStartPre=/usr/local/bin/preconfigure-sks

                /usr/local/bin/preconfigure-sks:
                    user: root
                    group: root
                    mode: '0755'
                    contents: |
                        #!/bin/bash
                        [[ -d /srv/sks/KDB ]] && exit 0
                        [[ -d /srv ]] || mkdir -p /srv 
                        [[ -d /srv/sks ]] || mkdir -p /srv/sks
                        chown sks.sks /srv/sks
                        cd /srv/sks
                        sks build
                        ln -s ../DB_CONFIG KDB/DB_CONFIG
                        ss_key=/etc/salt/gpgkeys/soestack-pub.gpg
                        master_key=/etc/salt/gpgkeys/pubring.gpg
                        sks merge ${ss_key}
                        sks merge ${master_key}

                /etc/systemd/system-preset/99-sks-start-disabled.preset:
                    user: root
                    group: root
                    contents: |
                        disable sks-db.service
                        disable sks-recon.service

