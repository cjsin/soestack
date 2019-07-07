"""
:maintainer:    example
:maturity:      new
:depends:       nothing
:platform:      all
"""

from __future__ import absolute_import
import uuid
from salt.utils.decorators.jinja import jinja_filter, JinjaFilter

import logging

__virtualname__ = 'uuid'

__outputter__ = {
    'run': 'txt'
}

log = logging.getLogger(__name__)


def __init__(opts):
    pass

def __virtual__():
    return __virtualname__

def short():
    return str(uuid.uuid4())[:8]

def ids(args=None):
    if not args:
        args = {} 

    prefix = (args['prefix']) if 'prefix' in args and args['prefix'] else ''
    suffix = (args['suffix']) if 'suffix' in args and args['suffix'] else ''

    if not prefix and not suffix:
        suffix = '.' + short()

    if suffix and suffix[0] != '.':
        suffix = '.' + suffix 

    if prefix and prefix[-1] != '.':
        prefix = prefix +'.' 
        
    return prefix, suffix 

#@jinja_filter('blah')
#def blah(args=None):
#    return "blah fo' real"
