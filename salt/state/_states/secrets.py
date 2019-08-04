from __future__ import absolute_import

import logging
import salt.exceptions
from pprint import pformat
import salt.utils.json 
import yaml

LOG = logging.getLogger(__name__)

def receive(name):
    """ Get a secret value which was passed from the master in the pillar key 'secrets' and store it """
    secret_name = name

    comment = 'Nothing to do'
    changes = { 
            name : { 'old': {}, 'new': {} }
        }

    minion_id = __grains__['id'] if 'id' in __grains__ else None

    data = None
    if 'secrets' in __pillar__ and 'data' in __pillar__['secrets'] and name in __pillar__['secrets']['data']:
        secret = __pillar__['secrets']['data'][name]
        if minion_id is not None and minion_id in secret:
            data = secret[minion_id]
            comment = 'Attempted'

    result = False

    if data:

        success, data = __salt__['secrets.minion_receive_from_master'](secret_name, data, True)
        if success is None:
            changes = {}
            comment = 'Up-to-date'
            result = True
        elif success:
            changes = { 
                    name : { 'old': { secret_name: '' }, 'new': { secret_name: 'updated' } }
                }
            comment = 'Stored'
            result = True
        else:
            comment = 'Receive from master failed for secret {} on minion {}'.format(secret_name, minion_id)
            result = False

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
        ret= {
            'name':     name,
            'result':   result,
            'comment':  comment,
            'changes':  changes,
            }

    LOG.info("secrets.ret = {}".format(pformat(ret)))
    return ret
