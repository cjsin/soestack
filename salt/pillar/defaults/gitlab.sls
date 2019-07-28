{{ salt.loadtracker.load_pillar(sls) }}

# TODO - rework filewall configuration
firewall:
    ports:
        tcp:
            gitlab-http-frontend:
                8000: ACCEPT
            # gitlab-pages-frontend:
            #     8000: ACCEPT
            gitlab-nginx-status:
                8060: ACCEPT
            gitlab-alertmanager:
                9094: ACCEPT
            gitlab-registry:
                5005: ACCEPT
            
