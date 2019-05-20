# -*- coding: utf-8 -*-
'''
My awesome execution module
---------------------------
'''

def observe_the_awesomeness():
    '''
    Prints information from my utility module

    CLI Example:

    .. code-block:: bash

        salt '*' mymodule.observe_the_awesomeness
    '''
    return __utils__['foo.bar']()
