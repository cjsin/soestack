check:
    build: build-config

definitions:
    build-config:
        properties:
            rpm: $ref:package-build-configs

    package-build-configs:
        propertyNames: $ref:rpm-name-prefix
        properties:
            package_url: $ref:url
            subdir: $ref:path-string
            configure_flags: $string
            install_flags: $string
            source_url: $ref:url
            rpm_version: $integer
            required_packages: $array:$string
