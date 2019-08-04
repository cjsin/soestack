# This module may be found using the extension_modules setting
# (it will look in a pillar dir under there)
# NOTE this module is the same as state/_modules/secrets.py, where it is
# provided for the minions
# If you make changes, please keep both in sync

import logging
from salt.ext import six

log = logging.getLogger(__name__)

__virtualname__ = 'secrets'
__VIRTUALNAME__ = __virtualname__

def find_opts():
    opts = {}
    for p in __opts__.get('ext_pillar',[]):
        if __virtualname__ in p:
            specified_options = next(six.itervalues(p))
            opts.update(specified_options)
    return opts

warnings = []
errors   = []
status   = []

def __init__(x):
    opts = find_opts()
    # Nothing to do here yet
    pass

def __virtual__():
    return __virtualname__

def generate_secrets(generate):
    global warnings, errors, status
    secret_names = list(generate.keys())
    for secret_name in secret_names:
        log.info("Processing auto-generation for secret '{}'".format(secret_name))
        how = generate[secret_name]
        if how is None or how == 'token':
            __salt__['secrets.master_check_or_generate'](secret_name)
        elif how.startswith('str:'):
            __salt__['secrets.master_check_or_set'](secret_name, how[4:])
        else:
            log.error("Unrecognised generation mode '{}' for secret '{}'".format(how, secret_name))

def distribute_secrets(secrets, distribute, minion_id):
    global warnings, errors, status
    if 'data' in secrets:
        data = secrets['data']
    else:
        data = {}
        secrets['data'] = data

    secret_names = list(distribute.keys())
    for secret_name in secret_names:
        distribution = distribute[secret_name]
        status.append("Processing secret {}".format(secret_name))
        count = 0
        if distribution and minion_id in distribution:
            retrieve_success, secret_data = __salt__['secrets.master_get_secret'](secret_name)
            if retrieve_success:
                encode_success, encoded_for_minion = __salt__['secrets.master_encrypt_for'](secret_name,minion_id,use_base64=True)
                if secret_name not in data:
                    data[secret_name]={}
                data[secret_name][minion_id] = encoded_for_minion
                status.append("Provided secret {} for minion {}".format(secret_name, minion_id))
                count += 1
            else:
                warnings.append("Secret {} not available on master".format(secret_name))
        else:
            status.append("Secret {} is not marked for distribution to {}".format(secret_name, minion_id))
        #if not count:
        #    status.append("Deleting secret {} not required for minion {}".format(secret_name,minion_id))
        #    del data[secret_name]


def ext_pillar( minion_id, pillar, *args, **kwargs ):
    global warnings, errors, status

    errors = []
    warnings = []
    status = []

    ret = {}

    if 'secrets' in pillar:
        secrets = pillar['secrets']
        generate = secrets['generate'] if 'generate' in secrets else {}
        distribute = secrets['distribute'] if 'distribute' in secrets else {}

        if generate:
            generate_secrets(generate)

        if distribute:
            distribute_secrets(secrets, distribute, minion_id)
    else:
        status.append("No secrets distribution list in pillar")

    ret.update({ 
        '_secrets': {
            'errors': errors,
            'warnings': warnings,
            'status': status
        }
    })
    return ret
