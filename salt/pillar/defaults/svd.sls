
svd:

    cots:

        drawio:
            version: 8.8.0
            url:     github.com/jgraph/drawio-desktop/releases/download/

        edraw:
            version: 9-64
            url:     www.edrawsoft.com/archives/

        elasticsearch:
            version: 6.4.0
            hash:    sha256=
        
        gitlab:
            version: 11.11.3-ce.0.el7

        gitlab-runner:
            version: 11.11.2-1

        grafana:
            # Grafana dashboard provisioning is USELESS since v 5.1 due to a senseless change
            # that makes all provisioned dashboards readonly - so you cannot edit them
            # So we need to hold the version back to 5.0.4
            version: 5.2.2-1
            #version: 5.0.4
        
        helm:
            version: 2.14.0
            url:     https://github.com/helm/helm/releases

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

        pencil:
            version: 3.0.4-49
            url:     pencil.evolus.vn
        
        prometheus:
            version: 2.3.2
   
        python37:
            version: 3.7.0
            hash:    md5=eb8c2a6b1447d50813c02714af4681f3

        staruml:
            version: 3.0.2
            url:     s3.amazonaws.com/staruml-bucket/releases/
