"""
:maintainer:    cjsin
:maturity:      new
:depends:       nothing
:platform:      all
"""

from __future__ import absolute_import
import uuid
import os
from os.path import exists, isdir, isfile, isabs
import logging
from salt.utils.decorators.jinja import jinja_filter, JinjaFilter
import time

__VIRTUALNAME__ = 'roots'
__virtualname__ = __VIRTUALNAME__

__outputter__ = {
    'run': 'txt'
}

log = logging.getLogger(__name__)

def __init__(opts):
    pass

def __virtual__():
    return __virtualname__

def exists(name, where='filesystem', env=''):
    failure = False, []
    usage = "Incorrect usage of module {}.exists".format(__VIRTUALNAME__)
    if where not in ['filesystem','pillar','state']:
        log.error("{} - {}".format(usage,"the where parameter must be one of pillar, state, filesystem"))
        return failure
    if not name:
        log.error("{} - {}".format(usage,"the name parameter must be non-empty"))
        return failure

    orig_name = name
    if name.lower().endswith('.sls'):
        name = name[:-4]
    
    name = name.replace(os.path.sep, '.')
    prefix = name.replace('.', os.path.sep)

    sls_file = prefix + '.sls'
    sls_dir = os.path.join(prefix,'init.sls')

    if where == 'filesystem':
        if os.path.isabs(prefix):
            return isfile(sls_file) or isfile(sls_dir)
        else:
            log.error("{} - {}".format(usage,"to check for filesystem paths you must use an absolute path"))
            return failure
    elif where in ['pillar','state']:
        roots_key = ('pillar' if where == 'pillar' else 'file') + '_roots'
        roots = __salt__['config.get'](roots_key)
        if not roots or not isinstance(roots, dict):
            log.error("Module {}.exists only works with pillar_roots and file_roots - virtual pillars / file roots are not supported.".format(__VIRTUALNAME__))
            return failure

        found = []
        for env_name, env_roots in roots.iteritems():
            if env and env != env_name:
                continue
            for path in env_roots:
                f = os.path.join(path,sls_file)
                if isfile(f):
                    log.debug("{}.exists checked for {} and found {} {}".format(__VIRTUALNAME__, orig_name, f, 'slsfile'))
                    found.append( {'env': env_name, 'file': f, 'type': 'slsfile' })
                else:
                    log.debug("{}.exists checked for {} at {} and did not find it".format(__VIRTUALNAME__, orig_name, f))
                f = os.path.join(path, sls_dir)
                if isfile(f):
                    log.debug("{}.exists checked for {} and found {} {}".format(__VIRTUALNAME__, orig_name, f, 'slsdir'))
                    found.append( {'env': env_name, 'file': f, 'type': 'slsdir' })
                else:
                    log.debug("{}.exists checked for {} at {} and did not find it".format(__VIRTUALNAME__, orig_name, f))
        if found:
            return True, found
        else:
            log.debug("{}.exists checked for {} at and found no matches".format(__VIRTUALNAME__, orig_name))
            return failure
    else:
        return failure
