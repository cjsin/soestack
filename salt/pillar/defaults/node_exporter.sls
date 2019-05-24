deployments:
    node_exporter_baremetal:
        node_exporter:

            activated: True
            activated_where: {{sls}}

            activate:
                firewall:
                    basic:
                        metrics:
                            accept:
                                tcp:
                                    http: 9100

            filesystem:
                defaults:
                    user:     node_exporter
                    group:    node_exporter
                    mode:     '0755'
                    makedirs: True

                dirs:
                    /d/local/node_exporter:
                    /d/local/node_exporter/text-collector:

                files:
                    /etc/sysconfig/node_exporter:
                        template:        node-exporter-sysconfig
                        config_pillar:   :config
                    /etc/systemd/system/node_exporter.service:
                        template:        node-exporter-service
                        config_pillar:   :config
                templates:
                    node-exporter-sysconfig: salt://templates/deployment/node_exporter_baremetal/sysconfig.jinja
                    node-exporter-service:   salt://templates/deployment/node_exporter_baremetal/service.jinja

            config:
                port:    9100
                storage: /d/local/node_exporter

                options:
                    # Example node exporter options:
                    # - --collector.textfile.directory /d/local/node_exporter/textfile_collector
                    # - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*)
                    # - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$

                    - --collector.textfile.directory /d/local/node_exporter/textfile_collector 
                    - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*) 
                    - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$ 

                    # Other node exporter options from its help text
                    #      --collector.diskstats.ignored-devices="^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"  
                    #                                Regexp of devices to ignore for diskstats.
                    #      --collector.filesystem.ignored-mount-points="^/(sys|proc|dev)($|/)"  
                    #                                Regexp of mount points to ignore for filesystem
                    #                                collector.
                    #      --collector.filesystem.ignored-fs-types="^(sys|proc|auto)fs$"  
                    #                                Regexp of filesystem types to ignore for
                    #                                filesystem collector.
                    #      --collector.megacli.command="megacli"  
                    #                                Command to run megacli.
                    #      --collector.netdev.ignored-devices="^$"  
                    #                                Regexp of net devices to ignore for netdev
                    #                                collector.
                    #      --collector.ntp.server="127.0.0.1"  
                    #                                NTP server to use for ntp collector
                    #      --collector.ntp.protocol-version=4  
                    #                                NTP protocol version
                    #      --collector.ntp.server-is-local  
                    #                                Certify that collector.ntp.server address is the
                    #                                same local host as this collector.
                    #      --collector.ntp.ip-ttl=1  IP TTL to use while sending NTP query
                    #      --collector.ntp.max-distance=3.46608s  
                    #                                Max accumulated distance to the root
                    #      --collector.ntp.local-offset-tolerance=1ms  
                    #                                Offset between local clock and local ntpd time
                    #                                to tolerate
                    #      --path.procfs="/proc"     procfs mountpoint.
                    #      --path.sysfs="/sys"       sysfs mountpoint.
                    #      --collector.qdisc.fixtures=""  
                    #                                test fixtures to use for qdisc collector
                    #                                end-to-end testing
                    #      --collector.runit.servicedir="/etc/service"  
                    #                                Path to runit service directory.
                    #      --collector.supervisord.url="http://localhost:9001/RPC2"  
                    #                                XML RPC endpoint.
                    #      --collector.systemd.unit-whitelist=".+"  
                    #                                Regexp of systemd units to whitelist. Units must
                    #                                both match whitelist and not match blacklist to
                    #                                be included.
                    #      --collector.systemd.unit-blacklist=".+\\.scope"  
                    #                                Regexp of systemd units to blacklist. Units must
                    #                                both match whitelist and not match blacklist to
                    #                                be included.
                    #      --collector.systemd.private  
                    #                                Establish a private, direct connection to
                    #                                systemd without dbus.
                    #      --collector.textfile.directory=""  
                    #                                Directory to read text files with metrics from.
                    #      --collector.wifi.fixtures=""  
                    #                                test fixtures to use for wifi collector metrics
                    #      --collector.arp           Enable the arp collector (default: enabled).
                    #      --collector.bcache        Enable the bcache collector (default: enabled).
                    #      --collector.bonding       Enable the bonding collector (default:
                    #                                disabled).
                    #      --collector.buddyinfo     Enable the buddyinfo collector (default:
                    #                                disabled).
                    #      --collector.conntrack     Enable the conntrack collector (default:
                    #                                enabled).
                    #      --collector.cpu           Enable the cpu collector (default: enabled).
                    #      --collector.diskstats     Enable the diskstats collector (default:
                    #                                enabled).
                    #      --collector.drbd          Enable the drbd collector (default: disabled).
                    #      --collector.edac          Enable the edac collector (default: enabled).
                    #      --collector.entropy       Enable the entropy collector (default: enabled).
                    #      --collector.filefd        Enable the filefd collector (default: enabled).
                    #      --collector.filesystem    Enable the filesystem collector (default:
                    #                                enabled).
                    #      --collector.gmond         Enable the gmond collector (default: disabled).
                    #      --collector.hwmon         Enable the hwmon collector (default: enabled).
                    #      --collector.infiniband    Enable the infiniband collector (default:
                    #                                enabled).
                    #      --collector.interrupts    Enable the interrupts collector (default:
                    #                                disabled).
                    #      --collector.ipvs          Enable the ipvs collector (default: enabled).
                    #      --collector.ksmd          Enable the ksmd collector (default: disabled).
                    #      --collector.loadavg       Enable the loadavg collector (default: enabled).
                    #      --collector.logind        Enable the logind collector (default: disabled).
                    #      --collector.mdadm         Enable the mdadm collector (default: enabled).
                    #      --collector.megacli       Enable the megacli collector (default:
                    #                                disabled).
                    #      --collector.meminfo       Enable the meminfo collector (default: enabled).
                    #      --collector.meminfo_numa  Enable the meminfo_numa collector (default:
                    #                                disabled).
                    #      --collector.mountstats    Enable the mountstats collector (default:
                    #                                disabled).
                    #      --collector.netdev        Enable the netdev collector (default: enabled).
                    #      --collector.netstat       Enable the netstat collector (default: enabled).
                    #      --collector.nfs           Enable the nfs collector (default: disabled).
                    #      --collector.ntp           Enable the ntp collector (default: disabled).
                    #      --collector.qdisc         Enable the qdisc collector (default: disabled).
                    #      --collector.runit         Enable the runit collector (default: disabled).
                    #      --collector.sockstat      Enable the sockstat collector (default:
                    #                                enabled).
                    #      --collector.stat          Enable the stat collector (default: enabled).
                    #      --collector.supervisord   Enable the supervisord collector (default:
                    #                                disabled).
                    #      --collector.systemd       Enable the systemd collector (default:
                    #                                disabled).
                    #      --collector.tcpstat       Enable the tcpstat collector (default:
                    #                                disabled).
                    #      --collector.textfile      Enable the textfile collector (default:
                    #                                enabled).
                    #      --collector.time          Enable the time collector (default: enabled).
                    #      --collector.uname         Enable the uname collector (default: enabled).
                    #      --collector.vmstat        Enable the vmstat collector (default: enabled).
                    #      --collector.wifi          Enable the wifi collector (default: enabled).
                    #      --collector.xfs           Enable the xfs collector (default: enabled).
                    #      --collector.zfs           Enable the zfs collector (default: enabled).
                    #      --collector.timex         Enable the timex collector (default: enabled).
                    #      --web.listen-address=":9100"  
                    #                                Address on which to expose metrics and web
                    #                                interface.
                    #      --web.telemetry-path="/metrics"  
                    #                                Path under which to expose metrics.
                    #      --log.level="info"        Only log messages with the given severity or
                    #                                above. Valid levels: [debug, info, warn, error,
                    #                                fatal]
                    #      --log.format="logger:stderr"  
                    #                                Set the log target and format. Example:
                    #                                "logger:syslog?appname=bob&local=7" or
                    #                                "logger:stdout?json=true"
