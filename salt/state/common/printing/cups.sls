#!stateconf yaml . jinja

.cups-installed:
    pkg.latest:
        - pkgs:
            - cups
            - cups-client
            - cups-filesystem
            - cups-filters
            - cups-libs
            # - cups-pdf
            - cups-pk-helper
            - gutenprint-cups
            - foomatic
            - foomatic-db
            - foomatic-db-filesystem
            - foomatic-db-ppds

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

.printers-file:
    file.managed:
        - name:     /etc/cups/printers.conf
        - user:     root
        - group:    lp
        - mode:     '0600'
        - template: jinja
        - source:   salt://{{slspath}}/cupsd-printers.conf.jinja
        - context:
            cups:   {{pillar.cups|json()}}

.service:
    service.running:
        - name:     cups
        - enable:   True
