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

__VIRTUALNAME__ = 'loadtracker'
__virtualname__ = __VIRTUALNAME__

__outputter__ = {
    'run': 'txt'
}

log = logging.getLogger(__name__)

_data=[]
_id = 0

_pillar_loads=[]
_pillar_id=0

_state_id=0
_state_loads=[]

def __init__(opts):
    pass

def __virtual__():
    return __virtualname__

def now():
    return time.time()

def millis():
    return int(round(time.time() * 1000))

def load(*strs):
    global _data, _id
    x = _id
    _data.append([x,now(), ' '.join(strs)])
    _id += 1
    return x

def loaded():
    return _data

def load_pillar(*strs):
    global _pillar_loads, _pillar_id
    x = _pillar_id
    _pillar_loads.append([ x, now(), ' '.join(strs)])
    _pillar_id += 1
    return ''

def load_state(*strs):
    global _state_loads, _state_id
    x = _state_id
    _state_loads.append([ x, now(), ' '.join(strs)])
    _state_id += 1
    return ''

def loaded_pillars():
    global _pillar_loads, _pillar_id
    return _pillar_loads

def loaded_states():
    global _state_loads, _state_id
    return _state_loads

def clear_pillar():
    global _pillar_loads, _pillar_id
    _pillar_loads=[]
    _pillar_id=0
    return ''

def clear_state():
    global _state_loads, _state_id
    _state_loads=[]
    _state_id=0
    return ''
