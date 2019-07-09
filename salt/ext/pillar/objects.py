import logging
from collections import OrderedDict
import uuid
from attrdict import AttrDict
from pprint import pformat

log = logging.getLogger(__name__)

__opts__ = { 'objects.implementation': 'tmpl', 'objects.object-data': 'object-data', 'objects.objects': 'objects' }

__virtualname__ = 'objects'
__VIRTUALNAME__ = __virtualname__

def __init__( __opts__ ):
    # Do init work here
    pass

def __virtual__():
    return __virtualname__

def generate_name():
    return str(uuid.uuid4())

def process_namekey(k, v):
    name = ''
    types = []
    print(k)
    if ' < ' in k:
        name, types = k.split(' < ', 1)
        name = name.strip()
        types = [ x.strip() for x in types.split(',') ]
    
        if name is '':
            if 'name' in v:
                name = v['name']
            else:
                name = None

        return name, types
    else:
        return k, []

def process_obj(specs, k, v, num):
    name, types = process_namekey(k, v)

    # It is reasonable for a value to be empty if types is not empty
    if v is None:
        if not types:
            return "value is None for k={},name={},{}".format(k,name,pformat(v)), ["fuckoff {}".format(k)]
        else:
            v = AttrDict()
    
    if isinstance(v, list):
        #print("ERROR: item with name {} is list: {}".format(k, pformat(v)))
        #return k+"-list-child-{}".format(k), None
        #return "k={},name={},{}".format(k,name,pformat(v)), process_objects("inside obj {} ".format(k), specs, v)
        return name, process_objects("inside obj {} ".format(k), specs, v)
    
    data_keys = []
    for ksub, vsub in v.iteritems():
        if ksub.startswith(' < '):
            types.append([x.strip() for x in ksub[2:].split(',')])
        else:
            data_keys.append(ksub)

    if len(types) < 1:
        print("ERROR: object {} has no type specifier!".format(k))
        return k + "-notype", None
    
    if len(types) > 1:
        print("ERROR: objects do not support multiple inheritance - you must declare a type spec for that")
        return k +"no-multi", None

    if types[0] not in specs:
        print("ERROR: typespec {} was not found".format(types[0]))
        return k + "-notfound-"+types[0], None

    tval = specs[types[0]]
    hierarchy = [ tval ]
    basic = tval['_basic'] if '_basic' in tval else AttrDict()
    objects = tval['_objects'] if '_objects' in tval else AttrDict()
    namekey = tval['_namekey'] if '_namekey' in tval else '_name'

    postproc = AttrDict()
    postproc['_uuid'] = str(uuid.uuid4())
    postproc['_idx'] = num
    postproc['_name'] = name
    postproc['_types'] = types
    postproc['_hierarchy'] = hierarchy
    postproc['_search'] = hierarchy + tval['_search']
    postproc['_basic'] = basic
    postproc['_objects'] = objects
    postproc['_methods'] = tval['_methods']
    postproc['_namekey'] = namekey

    data = AttrDict()
    path = v['path'] if 'path' in v else '(not set)' 

    data.update(basic)
    data.update(objects)

    errors=AttrDict()

    # Process the name key after inherited data but before explicit data
    if namekey and namekey != '_name':
        data[namekey] = name
        postproc[namekey] = name

    for ksub in data_keys:
        if ksub not in [ '_name', '_types', '_hierarchy', '_search', '_methods', '_basic','_uuid', '_idx', '_objects', '_errors','_namekey' ]:
            kval = v[ksub]
            if ksub in basic:
                data[ksub] = kval
            elif ksub in objects:
                data[ksub] = process_objects("inside obj key " + k, specs, kval)
            else:
                errors[ksub+"-explanation"] = "name {} not in objects: {} or basic {}".format(ksub, pformat(objects.keys()), pformat(basic.keys()))
                errors[ksub] = v[ksub]

    postproc.update(data)
    
    if errors:
        postproc['_errors'] = errors 

    return name, postproc

def process_spec(specs, k, v):
    name, types = process_namekey(k, v)
    v = v or AttrDict()
    namekey = v['namekey'] if 'namekey' in v else '_name'
    objects = v['objects'] if 'objects' in v else AttrDict()
    my_objects = process_objects("inside spec " + k, specs, objects)
    my_basic = v['basic'] if 'basic' in v else AttrDict()
    if not types:
        ret = AttrDict({
            '_name': name, 
            '_hierarchy': [], 
            '_super': [], 
            '_search': [],
            '_basic': my_basic,
            '_objects': my_objects,
            '_namekey': namekey,
            '_methods': AttrDict()
            })
        ret[namekey] = name
        return ret

    else:
        # combine previously processed superclasses
        basic = AttrDict()
        super_basic = AttrDict()
        super_objects = AttrDict()
        search_list = []
        hierarchy = [] # direct parents
        methods = AttrDict()
        objects = AttrDict()
        for t in types:
            if t in specs:
                tval = specs[t]
                hierarchy.append(tval)
                search_list.extend(tval['_search'] or [] )
                super_basic.update(tval['_basic'] or AttrDict())
                super_objects.update(tval['_objects'] or AttrDict())
                methods.update(tval['_methods'])
                if tval['_namekey'] != '_name':
                    namekey = tval['_namekey']

        basic.update(super_basic)
        basic.update(my_basic)
        objects.update(super_objects)
        objects.update(my_objects)
        ret = AttrDict({
            '_name': name, 
            '_hierarchy': hierarchy, 
            '_search': search_list, 
            '_basic': basic,
            '_objects': objects,
            '_namekey': namekey,
            '_methods': methods
            })
        #ret[namekey] = name
        return ret

def process_specs(specs):
    processed = AttrDict({})
    
    for k, v in specs.iteritems():
        result = process_spec(processed, k, v)
        if result:
            name = result['_name']
            processed[name] = result
    return processed

def process_objects(tag, specs, objs):
    log.debug("process_objects")
    idx = 0
    if isinstance(objs, dict):
        ret = {}
        for k, v in objs.iteritems():
            log.debug("process_object {}".format(idx))
            name, result = process_obj(specs, k, v, idx)
            if result is not None:
                ret[name] = result
            else:
                ret[k] = tag +" failure in " + "process_object {}".format(pformat(v))
            idx += 1
        return ret
    elif isinstance(objs, list):
        ret = []
        for item in objs:
            child_keys = item.keys()
            if len(child_keys) == 1:
                for child_name, child_val in item.iteritems():
                    cname, cobj = process_obj(specs, child_name, child_val, idx)
                    if cobj:
                        ret.append(cobj)
                    else:
                        # The data should have been a name: value mapping
                        #ret[errors[ksub] = kval
                        pass
        return ret
    return {}

def ext_pillar( minion_id, pillar, *args, **kwargs ):
    objs = { }
    specs = { }

    if 'object-data' in pillar and 'typespecs' in pillar:
        specs = process_specs(pillar['typespecs']) 
        objs = process_objects("toplevel", specs, pillar['object-data'])

    return { 'objects': objs, 'specs': specs }
