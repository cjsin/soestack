base:
    '*':

        # Load soestack defaults
        - defaults

        - layers

        - example_python

        # Override with mid level security just during early development
        # - defaults.security.low

    'roles:primary-server':
        - match: grain
        - defaults.security.mid

