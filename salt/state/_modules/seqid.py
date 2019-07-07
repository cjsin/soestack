"""
:maintainer:    example
:maturity:      new
:depends:       nothing
:platform:      all
"""

from __future__ import absolute_import
import uuid
from salt.utils.decorators.jinja import jinja_filter, JinjaFilter
import time

import logging

__VIRTUALNAME__ = 'seqid'
__virtualname__ = __VIRTUALNAME__

__outputter__ = {
    'run': 'txt'
}

log = logging.getLogger(__name__)

def __init__(opts):
    pass

def __virtual__():
    return __virtualname__

_id = 0
def next():
    global _id
    x = _id
    _id += 1
    return x
