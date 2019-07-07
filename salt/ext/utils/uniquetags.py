import uuid

from salt.utils.decorators.jinja import jinja_filter

def generate(args):
    prefix = args.prefix + '-' if 'prefix' in args else ''
    suffix = ('-' + uuid.uuid4()[:8]) if not prefix else '' 
    return prefix, suffix 
