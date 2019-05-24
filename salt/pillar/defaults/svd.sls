
svd:

    cots:

        elasticsearch:
            version: 6.4.0
            hash:    sha256=
        
        gitlab:
            version: 11.2.3

        grafana:
            # Grafana dashboard provisioning is USELESS since v 5.1 due to a senseless change
            # that makes all provisioned dashboards readonly - so you cannot edit them
            # So we need to hold the version back to 5.0.4
            version: 5.2.2-1
            #version: 5.0.4

        kibana:
            version: 6.4.0
            hash:    sha256=

        kubernetes:
            version: 1.11.2
        
        kubernetes-cni:
            version: v0.6.0
        
        kubernetes-crictl:
            version: v1.11.1

        logstash:
            version: 6.4.0
            hash:    sha256=

        mattermost:
            version: 4.1.2
            hash:    

        nginx:
            version: 1.15.3

        node_exporter:
            version: 0.16.0
            hash:    sha256=e92a601a5ef4f77cce967266b488a978711dabc527a720bea26505cba426c029

        prometheus:
            version: 2.3.2
   
        python37:
            version: 3.7.0
            hash:    md5=eb8c2a6b1447d50813c02714af4681f3
            