{{ salt.loadtracker.load_pillar(sls) }}

build:
    rpm:
        defaults:
            tmp_builddir:      /var/lib/soestack/builds/
            save_folder:       /d/local/rpm-build
            build_user:       build-user
            build_steps: |
                # run_configure
                # run_make
                run_make_install
                fpm_package

            configure_flags:   --prefix=/usr/local
            make_flags:        -j8 DESTDIR=${DESTDIR}
            install_flags:     install DESTDIR=${DESTDIR}
            required_packages: []
            rpm_version:       1
            rpm_vendor:        soestack
            rpm_vendorsuffix:  .el7.soestack
            rpm_distribution:  soestack
            rpm_summary:       
            package_license:   unknown
            package_version:   
            package_url:       
            version:           
