#!/bin/env python

def run(*kwarg,**kwargs):
    contents_pillar = context.get('contents_pillar', None)
    if contents_pillar is None:
        return None

    encoded = __salt__['pillar.get'](contents_pillar, None)
    if encoded is None:
        return None

    try:
        import base64
        return base64.b64decode(encoded)
    except:
        return None
