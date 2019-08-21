{{ salt.loadtracker.load_pillar(sls) }}
python37:
    package_url:       https://www.python.org
    subdir:            Python-VERSION
    configure_flags:   --enable-optimizations --with-ensurepip=upgrade CFLAGS=-Wno-error=coverage-mismatch
    install_flags:     altinstall DESTDIR=${DESTDIR}
    source_url:        http://nexus:7081/repository/interwebs/www.python.org/ftp/python/VERSION/Python-VERSION.tar.xz

    rpm_version:       1

    required_packages:
        - openssl-devel
        - valgrind-devel 
        - ncurses-devel
        - gdbm-devel 
        - sqlite-devel
        - readline-devel
        - xz-devel
        - zlib-devel 
        # need libuuid-devel and must not have uuid-devel installed (they both provide conflicting headers)
        - libuuid-devel
        - libffi-devel
        - bzip2-devel
        - tcl-devel
        - tk-devel
