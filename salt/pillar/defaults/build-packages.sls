{{ salt.loadtracker.load_pillar(sls) }}

build:
    rpm: {} # Note the empty dict is required here, or else salt will delete pre-existing data
        # Example package build data
        # python37:
        #     package_url:       https://www.python.org
        #     subdir:            Python-VERSION
        #     configure_flags:   --enable-optimizations --with-ensurepip=upgrade CFLAGS=-Wno-error=coverage-mismatch
        #     install_flags:     altinstall DESTDIR=${DESTDIR}
        #     source_url:        http://nexus:7081/repository/interwebs/www.python.org/ftp/python/VERSION/Python-VERSION.tar.xz
        #
        #     rpm_version:       1
        #     required_pkgs:
        #         - openssl-devel
        #         - valgrind-devel 
        #         - ncurses-devel
        #         - gdbm-devel 
        #         - lzma-devel
        #         - sqlite-devel
        #         - readline-devel
        #         - xz-devel
