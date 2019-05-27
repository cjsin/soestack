
"""
:maintainer:    me
:maturity:      new
:depends:       nothing
:platform:      all
"""

from __future__ import absolute_import

import time
import logging
import os
import urllib2
from pprint import pformat

__virtualname__ = 'saltipa'

__outputter__ = {
    'run': 'txt'
}

KRB5CCNAME = 'KRB5CCNAME'
TICKET_FILE = '/var/cache/salt/master/salt.krb'
salt_ticket = TICKET_FILE
check_server = ''
last_check = 0
last_check_result = [False, "Not checked yet"]
check_period = 30

log = logging.getLogger(__name__)

record_to_cmdline_flags = {
    'arecord': 'a-rec',
    'ptrrecord': 'ptr-hostname',
    'cnamerecord': 'cname-hostname'
}

class HeadRequest(urllib2.Request):
    def get_method(self):
        return "HEAD"

def __virtual__():
    return __virtualname__

def __init__(opts):
    global salt_ticket, check_server

    salt_ticket = None

    if __virtualname__ in opts:
        my_opts = opts[__virtualname__]
        logging.info("SaltIPA integration configuration: \n{}".format(pformat(my_opts)))

        if 'ticket_file' in my_opts:
            salt_ticket = my_opts['ticket_file']

        if not salt_ticket:
            salt_ticket = TICKET_FILE
    
        if 'check_server' in my_opts:
            check_server = my_opts['check_server']

    os.environ[KRB5CCNAME] = salt_ticket 

    check_ticket()

def server_unavailable():
    """ Return True if the server to check is configured, and is not available """
    logging.debug("Check IPA server {}".format(check_server))
    if check_server:
        try:
            response = urllib2.urlopen(HeadRequest('https://'+check_server))
            if response:
                return False, "IPA service is responding"
            else:
                return True, "Problems contacting the IPA service."
        except:
            return True, "Cannot contact IPA service."
    else:
        # Not configured with a check, so assume it's available
        return None, "SaltIPA check_server not configured."

def available():
    """ Return whether the integration seems configured and available """
    if not os.path.exists(salt_ticket) and loggedin():
        return False

def check_ticket():
    global last_check, last_check_result
    if not os.path.exists(salt_ticket):
        message1 = "Salt ticket file does not exist:{}".format(salt_ticket)
        message2 = "Use {}={} kinit admin to initialise it".format(KRB5CCNAME, salt_ticket) 
        log.error(message1)
        log.error(message2)
        return False, message1 + '. ' + message2
    else:
        now = time.time()
        diff = now - last_check
        if diff < check_period:
            return last_check_result

        ok, message = loggedin()
        if not ok:
            last_check_result = [ok, message]
        else:
            unavailable, message = server_unavailable()
            if unavailable is True:
                last_check_result = [False, message ]
            else:
                last_check_result = [True, "Logged in"]

        last_check = now
        return last_check_result

def loggedin():
    os.environ[KRB5CCNAME] = salt_ticket 
    
    cmd = [ 'klist', '-s' ]

    out = __salt__['cmd.run_all'](cmd,
                                  output_loglevel='trace',
                                  ignore_retcode=False,
                                  python_shell=False)
    if out['retcode'] == 0:
        return True, "Logged in"
    else:
        return False, "Not logged in."

def rawparser(lines):
    results = []
    for x in lines:
        if x.startswith("----"):
            continue
        elif x.startswith("Number of entries"):
            continue 

        key, colon, val = x.partition(':')
        if not colon:
            print("unexpected data: {}".format(x))
            continue
        key = key.strip()
        val = val.strip()
        results.append([key, val])
    #print("rawparser returning results {}".format(results))
    return results 

def search_raw_results(pairs, search_type=None, search_value=None):
    results = [] 
    for x in pairs:
        key, val = x
        #print("{} = {}".format(key, val))
        if search_type and key != search_type:
            #print("{} != {}.".format(key, search_type))
            continue
        if search_value and val != search_value:
            #print("{} != {}.".format(val, search_value))
            continue 
        #print("some kind of result:{}={}".format(key, val))
        if search_type and search_value:
            #print("Searching for and found {}={}".format(key, val))
            results.append([ key, val ])
        elif search_type:
            #print("Searching for type {} - returning found value {}".format(search_type, val))
            results.append(val) 
        elif search_value:
            #print("Searching for value {} - returning found type {}".format(search_value, key))
            results.append(key)
        else:
            #print("No search criteria - returning full pair {}={}".format(key, val))
            results.append([ key, val ])
    #print("search_raw_results returning {}".format(results))
    return results 

def object_config(objtype, path, search_type=None, search_value=None):
    cmd = [ 'ipa' ] + [objtype + '-show' ] + [ '--raw' ]

    #print("find cmd={}".format(cmd))

    out = __salt__['cmd.run_all'](cmd,
                                  output_loglevel='trace',
                                  ignore_retcode=True,
                                  python_shell=False)

    #print("stderr:{}".format(out['stderr']))
    raw_results = rawparser(out['stdout'].splitlines())
    return search_raw_results(raw_results, search_type=search_type, search_value=search_value)

def _update_object(objtype, path, **kwargs):
    cmd = [ 'ipa' ] + [ objtype + '-mod' ] 
    log.info("Update object {} [{}] with {}".format(objtype,path,kwargs))

    for key, val in kwargs.iteritems():
        # flag = record_to_cmdline_flags[key] if key in record_to_cmdline_flags else key 
        cmd.append("--setattr={}={}".format(key,val))
    cmd.append('--raw')

    #print("find cmd={}".format(cmd))

    out = __salt__['cmd.run_all'](cmd,
                                  output_loglevel='trace',
                                  ignore_retcode=True,
                                  python_shell=False)
    
    raw_results = rawparser(out['stdout'].splitlines())
    success = out['retcode'] == 0
    log.info("Retcode={}".format(out['retcode']))
    return success, search_raw_results(raw_results)

def modify_object(objtype, path, testing=True, **kwargs):
    current_data = object_config(objtype, path) 
    attrib_map = dict( (x[0],x[1]) for x in current_data) 
    needs_update={}
    old_values={}
    for key, val in kwargs.iteritems():
        if key in attrib_map and attrib_map[key] != str(val):
            log.info("Current value {}={} needs to be updated to {}".format(key,attrib_map[key],val))
            needs_update[key]=str(val)
            old_values[key]=attrib_map[key]

    if not needs_update:
        log.info("No updates required.")
        return True, None, None, None

    if testing:
        return True, True, needs_update, old_values
    else:
        success, data = _update_object(objtype, path, **needs_update)
        return success, True, needs_update, old_values

def global_config(search_key=None, search_value=None):
    """ return the toplevel IPA config values, as per 'ipa config-show' """
    return object_config('config', [], search_type=search_key, search_value=search_value)

def modify_global_config(testing=False, **kwargs):
    return modify_object('config', [], testing=testing, **kwargs)

def find_record(category, path, search_type=None,search_value=None):
    cmd = [ 'ipa', category + '-show' ] + path + [ '--raw' ]

    #print("find_record cmd={}".format(cmd))

    out = __salt__['cmd.run_all'](cmd,
                                  output_loglevel='trace',
                                  ignore_retcode=True,
                                  python_shell=False)

    #print("stderr:{}".format(out['stderr']))
    raw_results = rawparser(out['stdout'].splitlines())
    ok = out['retcode'] == 0
    return ok, search_raw_results(raw_results, search_type=search_type, search_value=search_value)

def add_record(category, path, record_type, value):
    #print("add_record {},{},{},{}".format(category, path, record_type, value))

    if not check_ticket():
        log.error("IPA server does not appear to be available")
        return False,{}

    cmd = [ 'ipa', category + '-add' ] + path

    flag = record_to_cmdline_flags[record_type] if record_type in record_to_cmdline_flags else record_type 
    cmd.append("--{}={}".format(flag, value))

    cmd.append('--raw')

    #print("add cmd={}".format(cmd))

    out = __salt__['cmd.run_all'](cmd,
                                  output_loglevel='trace',
                                  ignore_retcode=True,
                                  python_shell=False)

    #print("stderr:{}".format(out['stderr']))

    raw_results = rawparser(out['stdout'].splitlines())
    ok = out['retcode'] == 0
    return ok, search_raw_results(raw_results, search_type=record_type, search_value=value)

def del_record(category, path, record_type, value):
    #print("del_record {},{},{},{}".format(category, path, record_type, value))
    cmd = [ 'ipa', category + '-del' ] + path

    flag = record_to_cmdline_flags[record_type] if record_type in record_to_cmdline_flags else record_type 
    cmd.append("--{}={}".format(flag, value))

    #print("del cmd={}".format(cmd))

    out = __salt__['cmd.run_all'](cmd,
                                  output_loglevel='trace',
                                  ignore_retcode=True,
                                  python_shell=False)

    #print("stderr:{}".format(out['stderr']))
    #print("stdout:{}".format(out['stdout']))

    ok = out['retcode'] == 0

    return ok, out['stderr']

def generic_update(category, path, record_type, value, update_existing=True, testing=True):
    """ 
    Parameters:
      - category - for example 'dnsrecord'
      - path - the hierarchical parent of the record to be added, eg [ zone_name, host_name ]
      - record_type - the record type being added or modified, eg 'arecord'
      - value - the value for the new record - eg an IP address.
    Return tuple is:
      - Success/Failure(true,false)
      - Changed/Changes required (true/false) 
      - added record or none
      - deleted record or none
    """
    #print("Generic_update {}, {}, rectype={},value={}".format(category, path, record_type, value))
    deletions = [] 
    additions = [ value ]
    if update_existing:
        # Any existing mismatched records will be updated
        find_ok, existing = find_record(category, path, record_type)
        for item in existing:
            if item != value:
                deletions.append(item)
            else:
                additions = []
    else:
        # A record will only be added (if not already existing)
        find_ok, existing = find_record(category, path, record_type, value)
        if existing:
            additions = [] 

    if not (additions or deletions):
        return True, None, None
    else:
        if testing:
            return True, True, additions + deletions
        else:
            changes = []
            add_failures = 0
            del_failures = 0

            for d in deletions:
                del_ok, del_result = del_record(category, path, record_type, d) 
                if not del_ok:
                    del_failures += 1
                    log.info("Delete failed for {}".format(d))
                else:
                    changes.append(' '.join(['del', record_type, d]))

            for a in additions:
                add_ok, add_result = add_record(category, path, record_type, a)
                if not add_ok:
                    add_failures += 1
                    log.info("Add failed for {}".format(a))
                else:
                    changes.append(' '.join(['add', record_type, a]))

            any_failures = bool(add_failures or del_failures)

            return (not any_failures), bool(changes), changes

def dnsrecord(zone, name, record_type, value, add_reverse=False, update_existing=True, testing=True):
    if record_type == 'ptrrecord':
        path=[ zone, '--name=' + name ]
    else:
        path=[ zone, name ]

    return generic_update('dnsrecord', path, record_type, value, update_existing=update_existing, testing=testing)


def cnames(name, zone, aliases, fqdn=None, testing=True):
    if fqdn is None and '.' in name and not zone:
        fqdn = name

    if fqdn is not None:
        if zone and fqdn.endswith('.' + zone):
            trunc = len(zone) + 1
            name = fqdn[0:-trunc]
        elif (not zone) and  ('.' in fqdn):
            name, dot, zone = fqdn.partition('.')

    if not fqdn:
        if '.' in name:
            fqdn = name
        elif zone:
            fqdn = name + '.' + zone
        else:
            log.error("Error - a FQDN or name and zone is required.")
            return False, False, False
 
    success = True
    changed = False
    changes = []

    if not fqdn.endswith('.'):
        fqdn = fqdn + '.'

    for a in aliases.split(' '):
        a = a.strip()
        if not a:
            continue 
        if '.' not in a: 
            a = a + '.' + zone
        if '.' in a:
            alias, dot, aliaszone = a.partition('.')
            path = [aliaszone, alias] 
        if a + '.' == fqdn:
            continue
        
        success2, changed2, changes2 = generic_update('dnsrecord', path, 'cnamerecord', fqdn, update_existing=True, testing=testing)
        success = success and success2
        changed = changed or changed2
        changes.extend(changes2 or [])

    return success, changed, changes 

def arecord(name, zone, ip, add_reverse=False, update_existing=True, testing=True):
    log.info("execution module arecord(name={}, zone={}, ip={}, add_rev={}".format(name, zone, ip, add_reverse))

    octets = ip.split('.')
    if len(octets) < 4:
        log.info("Cannot add IP entry for incomplete IP address.")
        return False, False, None 

    success, changed, changes = generic_update('dnsrecord', [ zone, name ], 'arecord', ip, update_existing=update_existing, testing=testing)

    if not add_reverse:
        log.info("Not required to add reverse - returning results")
        return success, changed, changes 

    log.info("Proceeding to check reverse records")
    reversed_ip = list(reversed(octets))

    fqdn = name + '.' + zone + '.'
    last_octet = reversed_ip.pop(0)
    reverse_zone = '.'.join(reversed_ip) + '.in-addr.arpa'

    log.info("Checking reverse record also for fqdn {} and octet {} in zone {}".format(fqdn, last_octet, reverse_zone))

    success2, changed2, changes2 = generic_update('dnsrecord', [ reverse_zone, str(last_octet) ], 'ptrrecord', fqdn, update_existing=True, testing=testing )
 
    log.info("Results of ptr check = {}, {}, {}".format(success2, changed2, changes2))

    changes = changes or []
    changes2 = changes2 or [] 
    changes = changes + changes2 

    changed = changed or changed2 
    success = success and success2
    changes = changes if changes else None 

    log.info("Overall result = {}, {}, {}".format(success, changed, changes))
    return success, changed, changes
