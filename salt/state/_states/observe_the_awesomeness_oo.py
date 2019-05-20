# -*- coding: utf-8 -*-
'''
My awesome execution module
---------------------------
'''

import oofoo

def observe_the_awesomeness_oo():
    '''
    Prints information from my utility module

    CLI Example:

    .. code-block:: bash

        salt '*' oofoo.observe_the_awesomeness_oo
    '''
    foo = oofoo.Foo()
    return foo.bar()
