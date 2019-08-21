{{ salt.loadtracker.load_pillar(sls) }}
node_exporter:
    version:           '!!versions.cots.node_exporter.version'
    package_url:       'https://www.github.com/prometheus/node_exporter/'
    subdir:            'node_exporter-VERSION.linux-amd64'
    build_steps:       opt-rsync,symlink-opt-dir,symlink-opt-executable,fpm-package
    source_url:        'http://nexus:7081/repository/github/prometheus/node_exporter/releases/download/vVERSION/node_exporter-VERSION.linux-amd64.tar.gz'
    rpm_version:       1
    steps:
        symlink-opt-executable: |
            mkdir -p "${DESTDIR}/usr/local/bin"
            cd "${DESTDIR}/usr/local/bin" && test -f "/opt/${package_name}/${package_name}" && ln -sf "/opt/${package_name}/${package_name}"
