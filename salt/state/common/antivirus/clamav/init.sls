#!stateconf yaml . jinja

.setup-selinux:
    selinux.boolean:
        - name:    antivirus_can_scan_system
        - value:   True
        - persist: True


.install:
    pkg.latest:
        - pkgs:
            - clamav
            - clamd
            - clamav-server-systemd 

.config-file-fix-example:
    file.replace:
        - name: /etc/clamd.d/scan.conf
        - pattern: ^Example.*
        - repl: ''

.config-file-socket:
    file.uncomment:
        - name: /etc/clamd.d/scan.conf
        - regex: ^LocalSocket

.freshclam-conf:
    file.replace:
        - name: /etc/freshclam.conf
        - pattern: ^Example.*
        - repl: ''

.freshclam-cron-job:
    file.managed:
        - name: /etc/cron.d/clamav-update
        - contents: |
            ## TODO - Adjust this line (consider whether to send to admin, or make it configurable).
            MAILTO=admin

            # NOTE that the timing here is also affected by
            # the /etc/sysconfig/freshclam file
            ## It is ok to execute it as root; freshclam drops privileges and becomes
            ## user 'clamupdate' as soon as possible
            0  */3 * * * root /usr/share/clamav/freshclam-sleep

.freshclam-run-once-script:
    file.managed:
        - name: /usr/local/bin/freshclam-run-once
        - user: root
        - group: root
        - mode:  '0755'
        - contents: |
            #!/bin/bash 
            
            record="/var/log/freshclam-run-once"
            [[ -f "${record}" ]] && exit 0

            freshclam && touch "${record}"

.freshclam-run-once:
    cmd.run:
        - name:   /usr/local/bin/freshclam-run-once
        - unless: test -f /var/log/freshclam-run-once

.clamd-service-enabled:
    service.running:
        - name:   clamd@scan
        - enable: True

.scan-scripts:
    file.managed:
        - name: /usr/local/bin/clam-scan-home
        - user: root
        - group: root
        - mode: '0755'
        - contents: |
            #!/bin/bash
            clamscan --infected --remove --recursive /home

#Apache is already configured with a listener on port 443:
