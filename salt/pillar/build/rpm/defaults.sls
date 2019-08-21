{{ salt.loadtracker.load_pillar(sls) }}
defaults:
    tmp_builddir:      /home/build-user/builds
    save_folder:       /d/local/rpm-build
    build_user:        build-user
    logdir:            "${distdir}/var/log/build"
    logprefix:         "${logdir}/${package_name}-${version}-${rpm_version}"
    configure_flags:   --prefix=/usr/local
    make_flags:        -j8 DESTDIR=${DESTDIR}
    install_flags:     install DESTDIR=${DESTDIR}
    required_packages: []
    rpm_version:       1
    rpm_vendor:        soestack
    rpm_vendorsuffix:  .el7.soestack
    rpm_distribution:  soestack
    rpm_summary:       'unset'
    package_license:   unknown
    package_version:   'unset'
    package_url:       'unset'
    version:           'unset'
    build_steps:       configure,make,make-install,fpm-package

    steps:
        configure: |
            ./configure "${configure_flags[@]}"
        make: |
            make "${make_flags[@]}"
        make-install: |
            make install DESTDIR="${DESTDIR}"
        #copy-logs: |
        #    mkdir -p "${DESTDIR}/${logprefix}/"
        #    rsync -av "${logprefix}/" "${DESTDIR}${logdir}/${logprefix}/"
        fpm-package: |
            local -a fpm_args=(
                -t rpm 
                --force 
                --rpm-os linux 
                --rpm-auto-add-directories  
                --rpm-dist     "${rpm_distribution}" 
                --rpm-summary  "${rpm_summary}"
                --url          "${package_url}"
                --description  "${rpm_description}"
                -S             "${rpm_vendorsuffix}"  
                -a             "native" 
                --vendor       "${vendor}"
                --version      "${version}" 
                --iteration    "${rpm_version}"
                --license      "${package_license}" 
                -n             "${package_name}"
                -C             "${distdir}" 
                -p             "${outfile}" 
                -s dir "."
            )
            
            chmod -R ug-st "${distdir}"
            echo fpm "${fpm_args[@]}"
            fpm "${fpm_args[@]}"
        opt-rsync: |
            echo "DESTDIR is ${DESTDIR}"
            mkdir -p "${DESTDIR}/opt"
            echo running from $(pwd)
            echo rsync -av ./ "${DESTDIR}/opt/${subdir}/"
            rsync -av ./ "${DESTDIR}/opt/${subdir}/"
        symlink-opt-dir: |
            cd "${DESTDIR}/opt" && test -d "${subdir}" && ln -sf "${subdir}" "${package_name}"

