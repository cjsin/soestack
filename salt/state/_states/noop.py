from __future__ import absolute_import

import logging
import salt.exceptions
from pprint import pformat
import salt.utils.json 

LOG = logging.getLogger(__name__)

def _noop(name,prefix=None,changed=False,result=None,text=None,changes=None,comment=None):
    
    if changes is None:
        changes = {}

    if text is not None:
        name = text

    if prefix is not None:
        name = prefix.upper() + '-'+ name

    if comment is None:
        if text is not None:
            comment = text
        else:
            comment = name

    if changed:
        # to simulate changes, we have to update the changes dict
        # otherwise salt doesn't know the difference between success with no change
        # and success with changes.
        key = prefix or 'notice'
        if not changes:
            changes.update({ prefix : { 'old': '', 'new': name }})

    ret={}

    if __opts__['test']:
        # if result is False, we leave it, so it is still shown as an error
        # if result is True, we change it to None for test mode
        if result is True:
            result = None
        ret= {
            'name':     name,
            'result':   result,
            'comment':  'test mode - notice would be ' + comment,
            'pchanges': changes,
            'changes': { }
            }
    else:
        #if result is None:
        #    result = True
        #if not changes:
        #    LOG.info("fix for saltstack shitty API change")
        #    changes['fuckoff'] = { 'old': 'fuckoff', 'new': 'getfucked'}
        ret= {
            'name':     name,
            'result':   result,
            'comment':  comment,
            'changes':  changes,
            }
    LOG.info("noop.ret = {}".format(pformat(ret)))
    return ret

def notice(name,text=None):
    '''
    Print a notice without reporting any changes.

    name
        The thing to do something to
    '''
    return _noop(name,prefix='notice',text=text,changed=False,result=True)

def log(name,text=None):
    '''
    Log a message but do not report a change
    '''

    LOG.info(name)
    return _noop(name,prefix='log',text=text,changed=False,result=True)

def warning(name,text=None):
    '''
    Create a warning - a message which reports as a Change
    '''

    LOG.info(name)
    return _noop(name,prefix='warning',text=text,changed=True,result=None)

def error(name,text=None):
    '''
    Create an error - a message which reports as a failure
    '''

    LOG.info(name)
    return _noop(name,prefix='error',text=text,changed=True,result=False)

def pprint(name,data,text=None):
    '''
    Pprint an object to the log but do not report a change
    '''
    pf = salt.utils.json.dumps(data) 
    # pf = pformat(data,width=-1)
    pretty = "{} data {}".format(name, pf)
    LOG.info(pretty)

    changes = { 
            name : { 'old': {}, 'new': data }
            }
    return _noop(name, prefix='pprint', text=text, changed=False, changes=changes, result=True, comment=pretty)

