#!stateconf yaml . jinja

{%- set cups = pillar.cups %}

.cups-installed:
    pkg.latest:
        - pkgs:
            - cups
            - cups-client
            - cups-filesystem
            - cups-filters
            - cups-libs
            - cups-pk-helper
            - gutenprint-cups
            - foomatic
            - foomatic-db
            - foomatic-db-filesystem
            - foomatic-db-ppds

.cups-pdf-installed:
    pkg.latest:
        - fromrepo: epel
        - pkgs:
            - cups-pdf

.tools-installed:
    pkg.latest:
        - pkgs:
            - gutenprint
            # - gutenprint-libs
            # - ghostscript-tools-printing
            - ghostscript-fonts
            # - ghostscript-tools-printing
            # - ghostscript-tools-fonts
            # - ghostscript-core
            # - ghostscript-x11

.config-file:
    file.managed:
        - name:     /etc/cups/cupsd.conf
        - user:     root
        - group:    lp
        - mode:     '0640'
        - template: jinja
        - source:   salt://{{slspath}}/cupsd.conf.jinja
        - context:
            cups:   {{cups|json()}}

.printers-file-template:
    file.managed:
        - name:     /etc/cups/printers.conf.ss
        - user:     root
        - group:    lp
        - mode:     '0600'
        - template: jinja
        - source:   salt://{{slspath}}/cupsd-printers.conf.jinja
        - context:
            cups:   {{cups|json()}}

.printers-file-updater:
    file.managed:
        - name:     /usr/local/bin/cups-update-printer-conf
        - user:     root
        - group:    root
        - mode:     '0755'
        - source:   salt://{{slspath}}/cups-update-printers-conf.sh.jinja
        - template: jinja 

.printers-file-update:
    cmd.run:
        - name:     /usr/local/bin/cups-update-printer-conf update
        - unless:   /usr/local/bin/cups-update-printer-conf check

.service:
    service.running:
        - name:     cups
        - enable:   True
