#!stateconf yaml . jinja

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
            cups:   {{pillar.cups|json()}}

.printers-file-template:
    file.managed:
        - name:     /etc/cups/printers.conf.ss
        - user:     root
        - group:    lp
        - mode:     '0600'
        - template: jinja
        - source:   salt://{{slspath}}/cupsd-printers.conf.jinja
        - context:
            cups:   {{pillar.cups|json()}}

.printers-file:
    cmd.run:
        - name: |
            stopstart=0
            systemctl is-active cups && stopstart=1
            (( stopstart )) && (systemctl stop cups; sleep 1) 
            cp -a /etc/cups/printers.conf.ss /etc/cups/printers.conf
            (( stopstart )) && systemctl start cups 
        - unless: cd /etc/cups && test -f printers.conf && diff printers.conf.ss printers.conf | egrep -v '^---|+++' | egrep '^[-+]' | egrep -v '^.(Type|ConfigTime|State|StateMessage|[#]|UUID) ' | egrep .

.service:
    service.running:
        - name:     cups
        - enable:   True
