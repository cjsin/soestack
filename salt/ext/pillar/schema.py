# This module may be found using the extension_modules setting
# (it will look in a pillar dir under there)

import logging
from pprint import pformat
from uuid import uuid4
import copy
from salt.utils.jinja import tojson

log = logging.getLogger(__name__)

CONFIG = 'pillar-schema'
SCHEMA = CONFIG + ':schema'
CHECK  = CONFIG + ':check'
OUTPUT = '_schema'

# Specify defaults
DEFAULTS        = { 
    # If specified, then 'schema' and 'check' will be obtained from pillar,
    # otherwise the master config values will be used
    'pillar-config': CONFIG, 
    'schema': SCHEMA, 
    'check' : CHECK,
    'output' : OUTPUT
}


__virtualname__ = 'schema'
__VIRTUALNAME__ = __virtualname__

SUPPORTED       = True
NOT_FOUND       = uuid4()
warnings        = []
errors          = []

def __init__( opts ):
    global SUPPORTED, CHECK, SCHEMA, DEFAULTS

    if 'ext_pillar' in opts and __virtualname__ in opts['ext_pillar']:
        opts = opts['ext_pillar'][__virtualname__]

    if opts:

        global SCHEMA, CHECK
        #SCHEMA = opts.get('schema', DEFAULTS['schema'])
        #CHECK = opts.get('check', DEFAULTS['check'])

    try:
        import jsonschema
        SUPPORTED = True
        log.debug("Schema supported - using jsonschema module")
    except:
        SUPPORTED = False
        log.debug("Schema not supported - no jsonschema module!")
    
    pass

def __virtual__():
    global SUPPORTED
    if SUPPORTED:
        return __virtualname__
    else:
        return False

def process_checklist(pillar, check, schema):
    global warnings, errors, NOT_FOUND
    results = []
    if isinstance(check, dict):
        for path, typename in check.iteritems():
            val = pillar.get(path, NOT_FOUND)
            if val == NOT_FOUND:
                warnings.append("Data '{}' ({}) cannot be validated as it does not exist in pillar".format(path, typename))
            else:
                results.append( (path, typename, val, schema) )
    elif isinstance(check, list):
        for item in check:
            results.extend(process_checklist(pillar, item, schema))
    else:
        log.debug("Badly specified checklist data")
    return results

def validate_object(schema, obj):
    from jsonschema import validate
    from jsonschema.exceptions import ValidationError
    try:
        validate(obj, schema)
        log.debug("Validation passed")
        return True, None
    except ValidationError as ve:
        return False, str(ve) 

def ext_pillar( minion_id, pillar, *args, **kwargs ):
    global SUPPORTED, CHECK, SCHEMA, DEFAULTS, warnings, errors

    errors = []
    warnings = []
    count = 0
    passed = []
    failed = []
    ret = {}

    status = 'initializing'

    config = None
    check  = None
    schema = None

    if CONFIG:
        config = pillar.get(CONFIG,None)
    else:
        log.debug("No CONFIG specified")
    
    if config:
        schema = config.get('schema',SCHEMA)
        check  = config.get('check',CHECK)
    else:
        log.debug("No CONFIG found")
        schema = SCHEMA
        check  = check

    if isinstance(check, str):
        check = pillar.get(check, None)
    if isinstance(schema, str):
        schema = pillar.get(schema, None)

    if not schema:
        warnings.append('No schema found or defined in pillar')
        status = 'nothing-to-do'
    elif not check:
        warnings.append('No pillar paths to check were found')
        status = 'nothing-to-do'
    else:
        to_check = process_checklist(pillar, check, schema)

        if not to_check:
            warnings.append('None of the pillar paths specified for checking were found in the pillar')
            status = 'nothing-to-do'
        else:
            status = 'success'
            try:
                for c in to_check:
                    
                    path, typename, val, base_schema = c
                    
                    validator = copy.deepcopy(base_schema)
                    
                    validator.update({"$ref":"#/definitions/"+typename})

                    result, message = validate_object(validator, val)
                    if result:
                        count += 1
                        passed.append("{} ({})".format(path,typename))
                    else:
                        failed.append("{} ({})".format(path,typename))
                        errors.append("While validating {} of type {} - FAILED with message:{}".format(path,typename,message))
                        #errors.append("The object value is {}".format(tojson(val)))
                        status = 'validation-failed'
            except:
                status = 'validation-failed'
                errors.append("Validation failed")
                import traceback
                errors.extend(traceback.format_exc().split('\n'))

    ret.update({
        OUTPUT : {
            'status': status,
            'errors': errors,
            'warnings': warnings,
            'count':    count,
            'passed':   passed,
            'failed':   failed
        }
    })
    return ret
