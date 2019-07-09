{{ salt.loadtracker.load_pillar(sls) }}

typespecs:
    base:
        basic:
            states: []
    fs-item < base:
        namekey: path 
        basic:
            mode:  '0644'
            path:  ''
            user:  'root'
            group: 'root'
            type:  'unset'
        methods:
            create:
        states:
            - create

    dir < fs-item:
        basic:
            type:  'dir'
            mode:  '0755'
            mkdirs: True

    symlink < fs-item:
        basic:
            type:   'link'
            mode:   '0755'
            target: ''
    file < fs-item:
        basic:
            type:          'file'
            template:      ''
            template-file: ''
            contents:      ''

    array < base:
        basic:
            subtype:  ''
        objects:
            children: []
        methods:
            iterate:
        states:
            - iterate

    fs-items < array:

# classes:
#     base:
#         implementation: salt://impl/
#         packages: {}
#         config: {}
#         states: []
#         methods: {}

#     fs-setup:
#         +base:
#         methods:
#             create:
#         states:
#             - dirs
#             - templates
#             - files
#             - links
#             - exports

#     firewall:
#         +base:
#         methods:
#             deps:
#             configure:
#             apply:
#         data:

#     iptables-firewall:
#         +firewall:
#         methods:
#             deps:
#         data:
#             rules: @iptables-rule

#     deployment:
#         isa:
#             fs-setup:
#         states:
#             - init
#             - install
#             - @fs-setup.states
#             - configure
#             - activate
#         methods:
#             install: 
#             configure:
#             activate:
#         data:
#             activated: False
#             activated_where: ''
#         objects:
#             # Using @ means the object is of the same class as its name
#             fs-setup: '@'
#             firewall: 
#                 isa: 
#                     - basic-firewall
#                 data: {}

#     containerized_service:
#         isa:
#             - deployment


#     node_exporter_baremetal:
#         isa:
#             - containerized_service

# objects:
#     node_exporter:
#         +containerized_service:
#         data:
        
#             activated:       True
#             activated_where: {{sls}}
#             firewall:
#                 data:
#                     metrics:
#                         accept:
#                             tcp:
#                                 http: 9100

#             filesystem:
#                 defaults:
#                     user:     node_exporter
#                     group:    node_exporter
#                     mode:     '0755'
#                     makedirs: True

#                 dirs:
#                     /d/local/node_exporter:
#                     /d/local/node_exporter/text-collector:

#                 files:
#                     /etc/sysconfig/node_exporter:
#                         template:        node-exporter-sysconfig
#                         config_pillar:   :config
#                     /etc/systemd/system/node_exporter.service:
#                         template:        node-exporter-service
#                         config_pillar:   :config
#                 templates:
#                     node-exporter-sysconfig: salt://templates/deployment/node_exporter_baremetal/sysconfig.jinja
#                     node-exporter-service:   salt://templates/deployment/node_exporter_baremetal/service.jinja

#             config:
#                 port:    9100
#                 storage: /d/local/node_exporter
#                 textfile_directory: /d/local/node_exporter/textfile_collector 
#                 options:
#                     - --collector.textfile.directory /d/local/node_exporter/textfile_collector 
#                     - --collector.filesystem.ignored-mount-points=^(/sys$|/proc$|/dev$|/var/lib/docker/.*|/run.*|/sys/fs/.*) 
#                     - --collector.filesystem.ignored-fs-types=^(sysfs|procfs|autofs|overlay|nsfs|securityfs|pstore)$ 
