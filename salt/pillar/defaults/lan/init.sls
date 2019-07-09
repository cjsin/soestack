{{ salt.loadtracker.load_pillar(sls) }}

# While your site could possibly be defined in a single file 'layers/lan/<your-lan-name>.sls'
# these you could also split up your overrides/additons into several files
# as shown here, by adding:
#    - a directory:   layers/lan/<your-lan-name>/
#    - an init file:  layers/lan/<your-lan-name>/init.sls
# and then explicitly including the files in the directory as shown below.
# 

include:
    - defaults.lan.network
    - defaults.lan.nodes
    - defaults.lan.node_lists
