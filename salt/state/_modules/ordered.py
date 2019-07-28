"""
:maintainer:    cjsin
:maturity:      new
:depends:       nothing
:platform:      all

Provides an ordered dict
"""

from __future__ import absolute_import
from collections import OrderedDict
import logging

__VIRTUALNAME__ = 'ordered'
__virtualname__ = __VIRTUALNAME__

__outputter__ = {
    'run': 'txt'
}

log = logging.getLogger(__name__)

def __init__(opts):
    pass

def __virtual__():
    return __virtualname__

def odict(*args,**kwargs):
    return OrderedDict(*args,**kwargs)
