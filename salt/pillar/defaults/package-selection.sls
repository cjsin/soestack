{{ salt.loadtracker.load_pillar(sls) }}

# Individual hosts or layers can install package sets in 4 ways:
#   1. Select them globally here
#   2. Add to the package-selection in another pillar file in another layer (included based on host or some other grain)
#   3. Pull them in using the package/set or package/group templates
#   4. Create a package group or set definition with a name that matches a 'role' that
#      is set within a host's 'roles' grain (a list of roles)

package-selection:
    package-groups: []
    package-sets:   []

    # Example data:
    # package-sets:
    #     - package-set-a
    #     - package-set-b
    #
    # package-groups:
    #     - package-group-a
    #     - package-group-b
