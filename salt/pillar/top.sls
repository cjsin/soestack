{{ salt.loadtracker.clear_pillar() }}

base:
    '*':
        # Load soestack defaults
        - diagnostics
        - defaults
        - layers
        - secrets
        - deployment-sequence
        # Testing schema validation
        #- test-schema
        #- test-schema-testdata

        # Testing salt pillar merge hierarchy - found bug 53516
        #- layers-test
        #- saltstack-bug-53516-test

        # Override with mid level security just during early development
        # - defaults.security.low
        - ignore_missing: True

    'roles:primary-server':
        - match: grain
        - defaults.security.mid
        - ignore_missing: True

    'E@.*':

        # Experimentation with object-oriented method of declaring deployments that can generate their own states
        #- classes
        #- object-data

        # Post processing data for postproc pillar extension module (Creates re-usable '!!' refs)
        #- postproc-test-data

        # Perform schema validation after the postprocessing
        - schema

        # Dump a list of all tracked layer files that were loaded, with sequence numbers and timing
        - load-tracing
        - ignore_missing: True
