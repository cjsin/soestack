{{ salt.loadtracker.load_pillar(sls) }}

nuggets:
    managed-hosts:
        description: |
            provides management of extra entries to /etc/hosts
            and recording of salt pillar data to an extra host file
            where it is available for processing by scripts on the system

        install: {}
        activate: {}
