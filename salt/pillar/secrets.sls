secrets:
    data:
        a-globally-accessible-secret: this secret is available to all in pillar but is not stored encrypted unless it is generated or distributed below
    generate:
        # Generate random tokens automatically for these secrets.
        # They will be used for initial configuration of the IPA server and for
        # client enrolment.
        # The tokens are stored in encrypted storage, only available on the
        # master unless distributed via the secrets:distribute key below
        ipa_client_enrol: token
        replica_enrol:    token
        pw-ipa-ds:        token
        pw-ipa-master:    token
        # A random token could be generated but this serves as 
        # an example of setting a fixed value and makes it easier to work with IPA during development.
        # You should set it to 'token' to set a random value if utilising in 
        # a real situation
        pw-ipa-admin:     str:admin123

    distribute:
        pw-ipa-ds:
            replica1:
        pw-ipa-master:
            replica1:
        pw-ipa-admin:
            replica1:
        ipa_client_enrol: 
            # Send to every minion
            {{grains.id}}:
        
        replica_enrol:
            # replica testing is for replica1
            replica1:

        # Distribute the runner registration token to all nodes
        gitlab-runner-registration-token:
            {{grains.id}}:
