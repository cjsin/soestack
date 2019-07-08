# This module may be found using the extension_modules setting
# (it will look in a pillar dir under there)

import logging
from pprint import pformat
from uuid import uuid4
import copy
from salt.utils.jinja import tojson
from salt.ext import six

log = logging.getLogger(__name__)

__virtualname__ = 'schema'
__VIRTUALNAME__ = __virtualname__

def find_opts():
    opts = {}

    for p in __opts__.get('ext_pillar',[]):
        if __virtualname__ in p:
            specified_options = next(six.itervalues(p))
            opts.update(specified_options)
        
    return opts

# Configuration property names (dict keys)
_CONFIG      = 'config'
_CHECK       = 'check'
_OUTPUT      = 'output'
_TEMPLATE    = 'template'
_DEFINITIONS = 'definitions'
_EXAMPLE     = 'example-data'
_SIMPLIFIED  = 'simplified'

# Default values
CONFIG       = 'pillar-schema'
DEFINITIONS  = {} # definitions
CHECK        = {} # (key -> type) mapping of pillar items to validate
OUTPUT       = '_schema' # Pillar key where validation results will be stored
EXAMPLE      = {}
SIMPLIFIED   = True
TEMPLATE     = {
                    '$schema': 'http://json-schema.org/draft-07/schema#',
                    _DEFINITIONS: DEFINITIONS,
               }

# Specify defaults
DEFAULTS        = { 
    _CONFIG:      CONFIG, 
    _DEFINITIONS: DEFINITIONS, 
    _CHECK :      CHECK,
    _OUTPUT :     OUTPUT,
    _TEMPLATE:    TEMPLATE,
    _EXAMPLE:     EXAMPLE,
    _SIMPLIFIED:  SIMPLIFIED
}

SUPPORTED       = True
NOT_FOUND       = uuid4()
warnings        = []
errors          = []

class SchemaComplexifier():
    """ 
    Takes a simplified schema format and makes it a valid schema.
    Only the 'definitions' key will be processed.

    Basically it will do the following:
        - take 

          $ref:a-typename  => { '$ref': '#/definitions/a-typename' }
          $boolean         => { type: boolean }
          $string          => { type: string }
          $object          => { type: object }
          $integer         => { type: integer }
          $pattern:p       => { type: string pattern: p }
          $array:xxx       => { type: array, children: xxx } (xxx is also processed)

    If '$@' is used instead of $, then an anyOf will be used to allow a null value

    This processing will be performed for:
        simple <string>:<string> pairs that are within a 'properties' key
    """
    def __init__(self):
        pass
    
    def alter(self, v):
        orig = v
        if not v.startswith('$'):
            return False, orig

        if v == '$null':
            return True, { 'type': 'null' }

        v = v[1:]
        allow_null = False
        if v[0] == '@':
            allow_null = True 
            v=v[1:]

        if v in [ 'boolean', 'string', 'object', 'integer' ]:
            if allow_null:
                return True, { 'anyOf': [ { 'type': v }, {'type': 'null' } ] }
            else:
                return True, { 'type': v }
        
        what, remainder = v.split(':',1)
        if what not in ['ref','pattern','array','enum']:
            return False, orig

        non_null_type = None 

        if what == 'ref':
            non_null_type = { '$ref': '#definitions/' + remainder }
        elif what == 'pattern':
            non_null_type = { 'type': 'string', 'pattern': remainder }
        elif what == 'array':
            changed, newvalue = self.alter(remainder)
            non_null_type = { 'type': 'array', 'items': newvalue }
        elif what == 'enum':
            non_null_type = { 'type': 'string', 'enum': remainder.split(',') }
        
        if allow_null:
            return True, { 'anyOf': [ non_null_type, { 'type': 'null' } ] }
        else:
            return True, non_null_type

    def process_dict(self, obj):
        for k, v in obj.iteritems():
            if not v:
                pass
            elif isinstance(v, str) or isinstance(v, unicode) :
                changed, newvalue = self.alter(v)
                if changed:
                    print("Modify key {} in place with new value {}".format(k, pformat(newvalue)))
                    obj[k] = newvalue
            elif isinstance(v, dict):
                self.process_dict(v)
            elif isinstance(v, list):
                self.process_list(v)
        print("After processing, dict obj is {}".format(pformat(obj)))

    def process_list(self, obj):
        for idx, v in enumerate(obj):
            if not v:
                pass
            elif isinstance(v, str) or isinstance(v, unicode) :
                changed, newvalue = self.alter(v)
                if changed:
                    print("Modify index {} in place with new value {}".format(idx, pformat(newvalue)))
                    obj[idx] = newvalue
            elif isinstance(v, dict):
                self.process_dict(v)
            elif isinstance(v, list):
                self.process_list(v)
        print("After processing, list obj is {}".format(pformat(obj)))

    def complexify(self,schema):
        s = copy.deepcopy(schema)
        
        if 'definitions' not in schema:
            return s

        d = s['definitions']
        if isinstance(d, dict):
            self.process_dict(d)
        else:
            errors.append("Schema definitions was not a mapping!")

        #print("After processing, d obj is {}".format(pformat(d)))
        #print("After processing, s obj is {}".format(pformat(s)))

        #warnings.append("Complexified object:")
        #warnings.append(tojson(s))
        return s

def prepare_validator(template, base_definitions, typename, simplified):
    validator = copy.deepcopy(template)
    validator['definitions'] = copy.deepcopy(base_definitions)
    validator['$ref'] = "#/definitions/"+typename
    if simplified:
        complexifier = SchemaComplexifier()
        validator = complexifier.complexify(validator)
    return validator

def __init__(x):
    global SUPPORTED, CHECK, DEFINITIONS, DEFAULTS, TEMPLATE, EXAMPLE, OUTPUT, SIMPLIFIED

    try:
        import jsonschema
        SUPPORTED = True
        log.debug("Schema supported - using jsonschema module")
    except:
        SUPPORTED = False
        log.debug("Schema not supported - no jsonschema module!")

    if SUPPORTED:
        opts = find_opts() or DEFAULTS

        if opts:
            DEFINITIONS = opts.get(_DEFINITIONS, DEFAULTS[_DEFINITIONS])
            CHECK = opts.get(_CHECK, DEFAULTS[_CHECK])
            EXAMPLE = opts.get(_EXAMPLE, DEFAULTS[_EXAMPLE])
            TEMPLATE = opts.get(_TEMPLATE, DEFAULTS[_TEMPLATE])
            OUTPUT = opts.get(_OUTPUT, DEFAULTS[_OUTPUT])
            SIMPLIFIED = opts.get(_SIMPLIFIED, DEFAULTS[_SIMPLIFIED])
        else:
            log.warning("No ext_pillar.{} config specified - Using defaults!".format(__virtualname__))
    pass

def __virtual__():
    global SUPPORTED
    if SUPPORTED:
        return __virtualname__
    else:
        return False

def process_checklist(pillar, check, definitions):
    global warnings, errors, NOT_FOUND
    results = []
    if isinstance(check, dict):
        for path, typename in check.iteritems():
            val = pillar.get(path, NOT_FOUND)
            if val == NOT_FOUND:
                warnings.append("Data '{}' ({}) cannot be validated as it does not exist in pillar".format(path, typename))
            else:
                results.append( (path, typename, val, definitions) )
    elif isinstance(check, list):
        for item in check:
            results.extend(process_checklist(pillar, item, definitions))
    else:
        log.debug("Badly specified checklist data")
    return results

def validate_object(schema, obj):
    from jsonschema import validate
    from jsonschema.exceptions import ValidationError, SchemaError
    try:
        validate(obj, schema)
        log.debug("Validation passed")
        return True, None
    except ValidationError as ve:
        return False, str(ve) 
    except SchemaError as se: 
        return False, str(se) 

def ext_pillar( minion_id, pillar, *args, **kwargs ):
    global SUPPORTED, CHECK, DEFAULTS, OUTPUT, TEMPLATE, EXAMPLE, warnings, errors, SIMPLIFIED

    errors = []
    warnings = []
    count = 0
    passed = []
    failed = []
    ret = {}

    status = 'initializing'

    config = None
    definitions = DEFINITIONS
    check  = CHECK
    template = TEMPLATE
    example = EXAMPLE
    output = OUTPUT
    simplified = SIMPLIFIED

    if isinstance(CONFIG, str):
        config = pillar.get(CONFIG, None)
    elif CONFIG:
        config = CONFIG
    else:
        log.debug("No CONFIG specified")
        log.debug("Will use defaults to find pillar data")
    
    if config:
        # If a config object was specified, it should contain the
        # actual data
        definitions = config.get(_DEFINITIONS,{})
        check  = config.get(_CHECK,{})
        example = config.get(_EXAMPLE, {})
        # For these two, we have to fall back to a non-empty default
        template = config.get(_TEMPLATE, TEMPLATE)
        output = config.get(_OUTPUT, OUTPUT)
        simplified = config.get(_SIMPLIFIED, SIMPLIFIED)
    else:
        log.debug("No CONFIG found")

    if isinstance(check, str):
        check = pillar.get(check, None)

    if isinstance(definitions, str):
        definitions = pillar.get(definitions, None)

    if isinstance(example, str):
        example = pillar.get(example, None)

    if isinstance(template, str):
        template = pillar.get(template, None)

    if not definitions:
        warnings.append('No schema definitions found or defined in pillar')
        status = 'nothing-to-do'
    elif not check:
        warnings.append('No pillar data paths to check were found')
        status = 'nothing-to-do'
    else:
        to_check = process_checklist(pillar, check, definitions)

        if not to_check:
            warnings.append('None of the pillar paths specified for checking were found in the pillar')
            status = 'nothing-to-do'
        else:
            status = 'success'
            for c in to_check:
                try:
                    path, typename, val, base_definitions = c
                    validator = prepare_validator(template, base_definitions, typename, simplified)
                    
                    result, message = validate_object(validator, val)
                    if result:
                        count += 1
                        passed.append("{} ({})".format(path, typename))
                    else:
                        failed.append("{} ({})".format(path, typename))
                        errors.append("While validating {} of type {} - FAILED with message:{}".format(path, typename, message))
                        #errors.append("The object value is {}".format(tojson(val)))
                        status = 'validation-failed'
                except:
                    errors.append("Validation failed for {}".format(path))
                    import traceback
                    errors.extend(traceback.format_exc().split('\n'))#[-4:-1])
            if failed or errors:
                status = 'validation-failed'
                errors.append("Validation failed")

    ret.update({
        output : {
            'status': status,
            'errors': errors,
            'warnings': warnings,
            'count':    count,
            'passed':   passed,
            'failed':   failed
        }
    })
    return ret


if __name__ == "__main__":
    s = {
        "definitions": {
            "roles-config": {
                "propertyNames": "$ref:role-name", 
                "properties": {
                    "purpose": "$string"
                }
            }, 
            "role-name": "$pattern:^([A-Za-z0-9][-_A-Za-z0-9]*)$"
        }, 
        "$schema": "http://json-schema.org/draft-07/schema#", 
        "$ref": "#/definitions/roles-config"
    }

    sc=SchemaComplexifier()
    
    print(tojson(sc.complexify(s)))

