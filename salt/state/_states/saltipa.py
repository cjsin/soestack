from __future__ import absolute_import

import logging
import salt.exceptions

LOG = logging.getLogger(__name__)

toplevel_objects=[
    'certmapconfig',
    'config',
    'dnsconfig',
    'krbtpolicy',
    'otpconfig',
    'pwpolicy',
    'realmdomains',
    'trustconfig',
    'vaultconfig',
]

def __init__(arg):
    _factory_init()

def __virtual__():
    '''
    Only make these states available if a the execution module is working
    '''

    if 'saltipa.check_ticket' not in __salt__:
        LOG.error("IPA execution module failed loading")

    return 'saltipa.check_ticket' in __salt__


def dnsrecord(name,zone,record_type, value, update_existing=True):
    '''
    Add or update a DNS record. 
    DNS zones can have multiple similar records.
    If update_existing is true, then other records will be deleted
    and a new record added. If it is false, then just a new record is added.
    '''
    testing = __opts__['test']

    loggedin, loggedin_msg = __salt__['saltipa.check_ticket']()
    changes = {}

    if not loggedin:
        return {
            'name':     name,
            'result':   False,
            'comment':  loggedin_msg,
            'changes':  changes,
            }

    adding = [ 'dnsrecord', zone, name, record_type, value ]
    prefix = '-'.join(adding)

    success, changed, mods = __salt__['saltipa.dnsrecord'](name=name, zone=zone, record_type=record_type, value=value, update_existing=update_existing, testing=testing)

    if changed:
        changes.update({ prefix : { 'old': '', 'new': mods }})
    
    changekey = 'pchanges' if testing else 'changes'

    result =  {
            'name':     '-'.join(adding),
            'result':   success,
            }

    comment_suffix = ' - {}'.format(' '.join(mods if changed else adding))

    if testing:
        result['pchanges'] = changes 
        result['changes'] = {}
        if success:
            comment = 'Test mode - ' + ('Would add record' if changes else 'Record exists')
        else:
            comment = 'Test mode - Record addition would fail'
    else:
        result['changes'] = changes
        if success:
            comment = 'Record added' if changed else 'Record exists'
        else:
            comment = 'Failed adding record'

    result.update({ 'comment': comment + comment_suffix })

    return result 



def cnames(name, aliases, zone=None, fqdn=None):
    '''
    Add cname records.
    '''
    testing = __opts__['test']

    loggedin, loggedin_msg = __salt__['saltipa.check_ticket']()

    changes = {}

    if not loggedin:
        return {
            'name':     name,
            'result':   False,
            'comment':  loggedin_msg,
            'changes':  changes,
            }

    success, changed, mods = __salt__['saltipa.cnames'](name=name, zone=zone, fqdn=fqdn, aliases=aliases, testing=testing)

    if changed:
        changes.update({ 'cnames' : { 'old': '', 'new': mods }})
    
    changekey = 'pchanges' if testing else 'changes'

    result =  {
            'name':     name,
            'result':   success,
            changekey : changes
            }

    comment_suffix = ' - {}'.format(' '.join(mods if changed else ''))

    if testing:
        result['changes'] = {}
        if success:
            comment = 'Test mode - ' + ('Would add record' if changes else 'Record exists')
        else:
            comment = 'Test mode - Record addition would fail'
    else:
        if success:
            comment = 'Record added' if changed else 'Record exists'
        else:
            comment = 'Failed adding record'

    result.update({ 'comment': comment + comment_suffix })

    return result 


def arecord(name, ip, zone=None, fqdn=None, update_existing=True, add_reverse=False):
    '''
    Update an A record for a name (and optionally add a reverse PTR rec).
    '''

    testing = __opts__['test']

    loggedin, loggedin_msg = __salt__['saltipa.check_ticket']()

    if not loggedin:
        return {
            'name':     name,
            'result':   False,
            'comment':  loggedin_msg,
            'changes':  {},
            }

    if fqdn is None and '.' in name and not zone:
        fqdn = name

    if fqdn is not None:
        if zone and fqdn.endswith('.'+zone):
            trunc = len(zone)+1
            name = fqdn[0:-trunc]
        elif zone:
            return {
                'name':     name,
                'result':   False,
                'comment':  "Cannot update fqdn '{}' in different zone '{}'".format(fqdn,zone),
                'changes':  {},
                }
        elif '.' in fqdn:
            name, dot, zone = fqdn.partition('.')
        else:
            return {
                'name':     name,
                'result':   False,
                'comment':  "FQDN must have at least one dot",
                'changes':  {},
                }

    record_type = 'arecord'
    adding = [ 'dnsrecord', zone, name, record_type, ip ]
    prefix = '-'.join(adding)
    changes = {}

    success, changed, mods = __salt__['saltipa.arecord'](name, zone, ip, add_reverse=add_reverse, update_existing=True, testing=testing)

    if changed:
        changes.update({ prefix : { 'old': '', 'new': mods }})
    
    changekey = 'pchanges' if testing else 'changes'

    result =  {
            'name':     name,
            'result':   success,
            }

    comment_suffix = ' - {}'.format(' '.join(mods if changed else adding))

    if testing:
        result['pchanges'] =  changes
        result['changes'] = {}
        if success:
            comment = 'Test mode - ' + ('Would add record' if changes else 'Record exists')
        else:
            comment = 'Test mode - Record addition would fail'
    else:
        result['changes'] = changes
        if success:
            comment = 'Record added' if changed else 'Record exists'
        else:
            comment = 'Failed adding record'

    result.update({ 'comment': comment + comment_suffix })

    return result 


def _config(name, objtype, **kwargs):
    '''
    Update an IPA toplevel config object such as 'config', 'otpconfig','pwpolicy'
    '''

    testing = __opts__['test']

    loggedin, loggedin_msg = __salt__['saltipa.check_ticket']()

    if not loggedin:
        return {
            'name':     name,
            'result':   False,
            'comment':  loggedin_msg,
            'changes':  {},
            }

    record_type = 'config'
    changes = {}


    if objtype not in toplevel_objects:
        return {
            'name':  name,
            'result': False,
            'comment': "Invalid object type for toplevel configuration",
            'changes': {}
        }

    success, changed, mods, old = __salt__['saltipa.modify_object'](objtype, [], testing=testing,**kwargs)

    if changed:
        changes.update({ record_type : { 'old': old, 'new': mods }})
    
    changekey = 'pchanges' if testing else 'changes'

    result =  {
            'name':     name,
            'result':   success,
            changekey : changes
            }

    comment_suffix = ' - {}'.format(' '.join(mods if changed else []))

    if testing:
        result['changes'] = {}
        if success:
            comment = 'Test mode - ' + ('Would update' if changes else 'No changes')
        else:
            comment = 'Test mode - Updates would fail'
    else:
        if success:
            comment = 'Records updated' if changed else 'No changes'
        else:
            comment = 'Failed updating records'

    result.update({ 'comment': comment + comment_suffix })

    return result 


def _factory_set_toplevel(objtype):
    """ Create a state function for the specified object type """
    import sys
    current_module = sys.modules[__name__]
    setattr(current_module, objtype, lambda name, **kwargs : _config(name, objtype, **kwargs))

def _factory_init():
    """ Create state functions for all the toplevel config objects """
    for objtype in toplevel_objects:
        _factory_set_toplevel(objtype)

