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
import traceback

import logging

__VIRTUALNAME__ = 'trace'
__virtualname__ = __VIRTUALNAME__

__outputter__ = {
    'run': 'txt'
}

log = logging.getLogger(__name__)

def __init__(opts):
    pass

def __virtual__():
    return __virtualname__

def stack():
    exc = traceback.format_stack()
    exc.pop()
    return exc[-8:]
