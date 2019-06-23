nuggets:
    test-nugget:

        install:
            nuggets-required:
                - dhcp-server-dnsmasq

            packages:
                - Pencil: http://nexus:7081/repository/interwebs/pencil.evolus.vn/dl/V3.0.4/Pencil-3.0.4-49.x86_64.rpm

        activate:
            firewall:
                firewall-rule-sets:
                    - dhcp-server
                basic:
                    accept:
                        test-nugget:
                            tcp:
                                testport: 9999 
            service-sets:
                enabled:
                    - dnsmasq

        config:
            test_data: test1


        filesystem:
            defaults:
                user: nobody
                group: nobody
                dir_mode: '0700'
                file_mode: '0600'

            templates:
                {%- raw %}
                test-nugget-template1: |
                    this is a test, the value is {{config.test_data}}
                test-nugget-template2: |
                    this is a test, the value is {{config.test_data}}
                {%- endraw %}

            dirs:
                /tmp/test:

            files:
                /tmp/test/test-1.conf:
                    config_pillar:   :config
                    template:        test-nugget-template1

                /tmp/test/test-2.conf:
                    config:
                        test_data: test2
                        b: 2
                    template:        test-nugget-template2
