import logging
from collections import OrderedDict
import uuid
from pprint import pformat
import copy


log = logging.getLogger(__name__)
__virtualname__ = 'postproc'
SEPARATOR1 = '.'
SEPARATOR2 = '%'
#SEPARATOR2 = '^\\v'
SEPARATOR3 = ']##['
#SEPARATOR2 = '\0'
#SEPARATOR2 = '%@%'
#SEPARATOR2 = ']|[
#SEPARATOR2 = '^\\v'

REF_PREFIX = '!!'
REF_PREFIX_LEN = 2
VERBOSE = False
DEBUG = False
SUPPORTED = True

def arrjoin(s,arr):
    return s.join([str(x) for x in arr])

def find_opts():
    opts = {}

    for p in __opts__.get('ext_pillar',[]):
        if __virtualname__ in p:
            specified_options = next(six.itervalues(p))
            opts.update(specified_options)
        
    return opts

def __init__( opts = None):
    global SUPPORTED
    try:
        #check_imports() # Nothing to check, yet
        if SUPPORTED:
            opts = find_opts()
            if 'separator' in opts:
                SEPARATOR1 = opts['separator']
            if 'ref_prefix' in opts:
                REF_PREFIX = opts['ref_prefix']
    except:
        log.debug("Shitty error")
        import traceback
        traceback.print_exc()
    pass

def __virtual__():
    global SUPPORTED
    if SUPPORTED:
        return __virtualname__
    else:
        log.error("Salt extension module {} cannot load due to missing dependencies".format(__virtualname__))
        return False

def _str_number(s):
    try:
        i = int(s)
        return i
    except ValueError:
        return None

def _lookup_key(obj,keyname):
    if isinstance(obj, dict):
        if keyname in obj:
            return obj[keyname], "OK"
    elif isinstance(obj, list):
        i = _str_number(keyname)
        if i is not None:
            return obj[i], "OK"
    return None, "Fail"

def split_ref(r):
    if SEPARATOR3 in r:
        return r.split(SEPARATOR3)
    elif SEPARATOR2 in r:
        return r.split(SEPARATOR2)
    elif SEPARATOR1 in r:
        return r.split(SEPARATOR1)
    else:
        return [r]

def canonicalize_ref(r):
    return canonicalize_path(split_ref(r))

def canonicalize_path(path):
    contains_sep1 = False
    contains_sep2 = False
    contains_sep3 = False
    for p in path:
        ps=str(p)
        if SEPARATOR1 in ps:
            contains_sep1 = True
        if SEPARATOR2 in ps:
            contains_sep2 = True
        if SEPARATOR3 in ps:
            contains_sep3 = True

    if contains_sep1 and contains_sep2 and contains_sep3:
        return None
    elif contains_sep2:
        return arrjoin(SEPARATOR3,path)
    elif contains_sep1:
        return arrjoin(SEPARATOR2,path)
    else:
        return arrjoin(SEPARATOR1,path)

def extract_reference(v):
    if v.startswith(REF_PREFIX) and len(v) > REF_PREFIX_LEN:
        #diag("Found a reference in {}".format(v))
        return canonicalize_ref(v[REF_PREFIX_LEN:])
    else:
        return None

def search_list(obj, path):
    ret = []
    idx=0
    for item in obj:
        found = search_for_refs(item, path+ [idx])
        if found:
            ret.extend(found)
        idx+=1
    return ret

def search_mapping(obj, path):
    ret = []
    for k, v in obj.iteritems():
        newpath = path+[k] 
        
        found = search_for_refs(v, newpath)
        if found:
            ret.extend(found)
    return ret

_diag = []

def search_for_refs(obj, path):
    ret = []
    
    if obj is None:
        return []
    if isinstance(obj, dict):
        found = search_mapping(obj, path)
        if found:
            ret.extend(found)
    elif isinstance(obj, list):
        found = search_list(obj, path)
        if found:
            ret.extend(found)
    elif isinstance(obj, str) or isinstance(obj, unicode):

        ref = extract_reference(obj)
        if ref:
            ret.append([path, ref])

    return ret

def _lookup(obj, prior_path, remaining_path):
    if not remaining_path:
        return obj, "OK"
    elif obj is None:
        return None, "Not found!"
    else:
        key = remaining_path[0]
        next_path = remaining_path[1:]

        found, ok = _lookup_key(obj, key)
        
        if ok != "OK":
            return None, ok
        elif not next_path:
            return found, "OK"
        else:
            return _lookup( found, prior_path + [key], next_path )

def lookup(obj, path):
    return _lookup(obj,[], path)

def update(obj, path, value, traversed=[]):
    if not path:
        pass
    elif len(path) == 1:
        key = path[0]
        if isinstance(obj, list):
            obj[_str_number(key)] = value
        else:
            obj[key] = value
    else:
        key = path[0]
        
        child = None
        if isinstance(obj, list):
            child = obj[_str_number(key)]
        else:
            child = obj[key]
        
        update(child, path[1:], value, traversed+[key])

def ellipsize(s,maxlen=90):
    if len(s) > maxlen:
        return s[0:maxlen-3] + '...'
    else:
        return s

def tostr(i):
    if i is None:
        return "(None)"
    elif isinstance(i, list):
        return ",".join([tostr(x) for x in i])
    elif isinstance(i, dict):
        return pformat(i)
    else:
        return str(i)

def stringify(*items):
    return " ".join( [ ellipsize(tostr(i)) for i in items ])

def diag(*items):
    global _diag
    _diag.insert(0,stringify(*items))

diagdata={}

def getdata(pillar):
    #from attrdict import AttrDict
    c = {}

    updated = {}
    global _diag
    global diagdata 
    diagdata={}
    _diag = []
    count = 0
    refs = {}
    problems = {}
    referenced = {}
    expand = {}
    path_mapping = {}
    referenced = {}
    extract = {}
    status = {}
    overall = 'success'
    stacktraces = []

    try:
        diagdata['refs']=refs 
        diagdata['expand']=expand 
        diagdata['extract']=extract 
        diagdata['referenced']=referenced 
        diagdata['msg']=_diag

        # Create an array of [path, ref], wherever a value is a reference
        refs = search_for_refs(pillar, [])

        if not refs:
            return {'postproc-status': 'success', 'postproc-result': count }

        # Create a dict of { <refpath>: [path, refpath] }

        for r in refs:
            r_path = r[0]
            r_ref  = r[1]
            
            target_ref = canonicalize_path(r_path)
            if target_ref is None:
                msg = stringify("path",path,"cannot be canonicalized! All the separator tokens are used within keys along the path")
                diag(msg)
                problems.append(msg)
                pass
            expand[target_ref] = r
            path_mapping[target_ref] = r_path
            

        #diag("Completed processing refs")
        # Just say we have pillar:
        #   a:
        #      b: !!a.d
        #      c: blah
        #      d: !!a.z
        #      z: !!a.c
        #   m:
        #      n: 1
        #      o: !!m.n
        # Then we will have 'expand':
        #  a.b : [['a','b'],'a.d']
        #  a.d : [['a','d'],'a.z']
        #  a.z : [['a','z'],'a.c']
        #  m.o : [['m','o'],'m.n']
        # and 'path_mapping':
        #  a.b: ['a','b']
        #  a.d: ['a','d']
        #  (and so on)
        #
        # And we want to detect that a.d is already in the list and change it like this:
        #  a.b : [['a','b'],'a.c']
        #  a.d : [['a','d'],'a.c']
        #  a.z : [['a','z'],'a.c']
        #  m.o : [['m','o'],'m.n']

        while True:
            changes = 0
            for target_ref, item in expand.iteritems():
                
                target_path = item[0]
                src_ref = item[1]
                
                if src_ref == target_ref:
                    pass
                if src_ref in expand:
                    # Replace the cyclic reference
                    expand[target_ref] = expand[src_ref]
                    changes += 1
            if not changes:
                break

        # Now generate a map of all paths that have been referenced, 
        # and where they were referenced

        for target_ref, item in expand.iteritems():
            target_path = item[0]
            src_ref = item[1]
            
            if src_ref in referenced:
                referenced[src_ref].append(target_ref)
            else:
                referenced[src_ref]=[target_ref]

        # Now 'referenced will look like:
        #
        # referenced:
        #     a.c : [ 'a.b', 'a.d', 'a.z'] # pillar objects a.b, a.d, and a.z need to be filled in with pillar value a.c
        #     m.n : [ 'm.o' ]              # pillar object m.n needs to be filled in with pillar value m.o
        #     a.d : [ 'a.z' ]
        #     a.z : [ 'a.c' ]

        c = copy.deepcopy(pillar)
        
        for src_ref in referenced.keys():
            src_path = split_ref(src_ref)
            src_value, lookup_status = lookup(c, src_path)
            if lookup_status == "OK":
                extract[src_ref] = src_value
            else:
                #extract[src_ref] = stringify("Error:", lookup_status, "for ref", src_ref)
                problems.append(stringify("Error:", lookup_status, "for ref", src_ref))

        count = 0

        for src_ref, target_refs in referenced.iteritems():
            src_value = extract[src_ref]
            for t in target_refs:
                t_path = split_ref(t) # TODO - maybe look up in path_mapping
                
                update(c, t_path, src_value)
                count += 1
        diag("SUCCESS")
    except:
        import traceback
        for l in traceback.format_exc().split('\n'):
            diag(l)
        diag("FAIL")
        stacktraces.append(traceback.format_exc())
        overall = 'failed'

    if problems:
        status['problems'] = problems 

    if stacktraces:
        status['stack'] = stacktraces

    if VERBOSE:
        status['msg'] = "\n".join(_diag) 

    if DEBUG:
        status['diag'] = diagdata

    if status:
        status['result'] = overall
        status['count'] = count
        c['_postproc'] = status 
        
    return c

def ext_pillar( minion_id, pillar, *args, **kwargs ):
    return getdata(pillar)

if __name__ == "__main__":
    global __opts__
    __opts__={ 'ext_pillar': [] }
    __init__()
    print("__virtual__ returns {}".format(__virtual__()))
