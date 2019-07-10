#!stateconf yaml . jinja


.setup-selinux:
    cmd.run: 
        # TODO: convert to selinux.boolean state
        - name:     setsebool -P antivirus_can_scan_system 1

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
            ## Adjust this line...
            MAILTO=root

            # NOTE that the timing here is also affected by
            # the /etc/sysconfig/freshclam file
            ## It is ok to execute it as root; freshclam drops privileges and becomes
            ## user 'clamupdate' as soon as possible
            0  */3 * * * root /usr/share/clamav/freshclam-sleep

.freshclam-run-once:
    cmd.run:
        - name: freshclam
        - unless: test -f /var/log/freshclam-run-once

.clamd-service-enabled:
    service.running:
        - name: clamd@scan
        - enable: True

.scan-scripts:
    file.managed:
        - name: /usr/local/sbin/clam-scan-home
        - user: root
        - group: root
        - mode: '0755'
        - contents: |
            #!/bin/bash
            clamscan --infected --remove --recursive /home

#Apache is already configured with a listener on port 443:
