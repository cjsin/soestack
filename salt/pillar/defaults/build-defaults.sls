{{ salt.loadtracker.load_pillar(sls) }}

build:
    upload: 
        url: 'http://nexus:7081/repository/built-rpms/soestack/demo'
