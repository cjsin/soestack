# This module may be found using the extension_modules setting
# (it will look in a pillar dir under there)

import logging

log = logging.getLogger(__name__)

# Specify defaults
__opts__ = { 'pillarexample.someconfig': 137 }

# This external pillar will be known as `something_else`
__virtualname__ = 'pillarexample'

def __init__( __opts__ ):
    log.debug("pillarexample init was called.")
    # Do init work here
    pass

def __virtual__():
    log.debug("pillarexample virtual was called.")
    return __virtualname__

def get_pillarexample_dictionary():
    return {'examplevalue': 12345 }


# ext_pillar( id, pillar, 'some argument' )                   # example_a
# ext_pillar( id, pillar, 'argumentA', 'argumentB' )          # example_b
# ext_pillar( id, pillar, keyA='valueA', keyB='valueB' } )    # example_c

def ext_pillar( minion_id, pillar, *args, **kwargs ):
    log.debug("pillarexample ext_pillar was called.")
    my_pillar = {'pillarexample': {}}

    my_pillar['pillarexample'] = get_pillarexample_dictionary()

    return my_pillar

#REMINDER
#Just as with traditional pillars, external pillars must be refreshed in order for minions to see any fresh data:
#
#salt '*' saltutil.refresh_pillar

#You can call pillar with the dictionary's top name to retrieve its data. From above example, 'external_pillar' is the top dictionary name. Therefore:
#Therefore:
#
#salt-call '*' pillar.get external_pillar

