{{ salt.loadtracker.load_pillar(sls) }}
build:
    rpm: {}

include:
    - build.rpm.*:
        key: build:rpm

