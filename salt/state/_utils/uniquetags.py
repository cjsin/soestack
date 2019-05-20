import uuid
def generate(args):
    prefix = args.prefix + '-' if 'prefix' in args else ''
    suffix = ('-' + uuid.uuid4()[:8]) if not prefix else '' 
    return prefix, suffix 
