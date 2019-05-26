_loaded:
    {{sls}}:

deployments:

    kube_master:
        kube-dev:
            host: infra 
            activated: False
            activated_where: {{sls}}
            activate:
                services:
                    enabled:
                        - kubelet

            config:
                single_node:           True
                version:               v1.11.3
                master_name:           infra
                pod_network_cidr:      172.27.0.0/16
                api_advertise_address: 192.168.121.110

                cni:
                    config:            http://nexus:7081/repository/interwebs/raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml

                dashboard:
                    enabled:           True
                    config:            http://nexus:7081/repository/interwebs/raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

                helm:
                    enabled:           True 
                    charts:            http://nexus:7081/repository/kube-charts
                    registry:          nexus:7085/repository/gcrio
                    version:           v2.11.0

                metallb:
                    enabled:           True
                    config:
                        controller:
                            image:
                                repository: nexus:7082/metallb/controller
                        speaker:
                            image:
                                repository: nexus:7082/metallb/speaker
                        # Note, this 'config' is text
                        config: |
                            controller:
                                image:
                                    repository: nexus:7082/metallb/controller
                            speaker:
                                image:
                                    repository: nexus:7082/metallb/speaker
                            address-pools:
                                - name:     my-ip-space
                                  protocol: layer2
                                  addresses:
                                      - 192.168.121.10-192.168.121.30

                images:
                    docker.io:
                        pull_from:     nexus:7082/library
                        tag_into:      ''
                        images: 
                            busybox:   1.29.2-glibc
                            #busybox:   1.30.1-glibc

                    #cloudnativelabs:
                    #    images:
                    #        kube-router: latest

                    gcr.io:
                        pull_from: nexus:7085
                        tag_into:  'gcr.io/'
                        images:
                            kubernetes-helm/tiller:    v2.14.0
                    
                    k8s.gcr.io:
                        pull_from: nexus:7084
                        tag_into:  k8s.gcr.io/
                        images:
                            coredns:    1.1.3
                            pause:      3.1
                            etcd-amd64: 3.2.18
                            kube-proxy-amd64:       v1.11.3
                            kube-scheduler-amd64:   v1.11.3
                            kube-apiserver-amd64:   v1.11.3
                            kube-controller-manager-amd64:   v1.11.3
                            #kubernetes-dashboard-amd64:      v1.10.0
                            kubernetes-dashboard-amd64:      v1.5.0

                            # docker pull gcr.io/google_containers/kube-apiserver-amd64:v1.5.0
                            # docker pull gcr.io/google_containers/kube-controller-manager-amd64:v1.5.0
                            # docker pull gcr.io/google_containers/kube-proxy-amd64:v1.5.0
                            # docker pull gcr.io/google_containers/kube-scheduler-amd64:v1.5.0
                            # docker pull weaveworks/weave-npc:1.8.2
                            # docker pull weaveworks/weave-kube:1.8.2
                            # docker pull gcr.io/google_containers/kubernetes-dashboard-amd64:v1.5.0
                            # docker pull gcr.io/google-containers/kube-addon-manager:v6.1
                            # docker pull gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm
                            # docker pull gcr.io/google_containers/kubedns-amd64:1.9
                            # docker pull gcr.io/google_containers/dnsmasq-metrics-amd64:1.0
                            # docker pull gcr.io/google_containers/kubedns-amd64:1.8
                            # docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.4
                            # docker pull gcr.io/google_containers/kube-discovery-amd64:1.0
                            # docker pull quay.io/coreos/flannel-git:v0.6.1-28-g5dde68d-amd64
                            # docker pull gcr.io/google_containers/exechealthz-amd64:1.2
                            # docker pull gcr.io/google_containers/pause-amd64:3.0

