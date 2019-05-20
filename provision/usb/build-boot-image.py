#!/usr/bin/python3

# Git repo for this project:
#
#  https://github.com/cjsin/guestfs-iso-to-image
#
# Please see there for example usage.
#

# Original inspiration:
#
# This script was developed using the following one as a great example to get started:
#    https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/10/html/director_installation_and_usage/appe-whole_disk_images


import guestfs
import os
import sys
import re
import argparse
import traceback
import subprocess
import tempfile
import itertools
from collections import OrderedDict
from attrdict import AttrDict
from pprint import pprint 

import sys
import argparse
import pprint
import shlex
import traceback

class Defaults:
    IMAGE_SIZE = 12*1024
    IMAGE_FORMAT = 'qcow2'
    LABEL = ''
    FSTYPE = 'vfat'
    SYSLINUX_PATH = '/usr/share/syslinux'
    SYSLINUX_MENU_FILES = 'vesamenu.c32,libcom32.c32,libutil.c32,menu.c32' 
    SYSLINUX_MBR_FILE = 'mbr.bin'
    SUPPORTED_IMAGE_FORMATS = ["qcow2","raw"]

INSPECT_OPERATIONS = [ 
    '--ls', 
    '--cat' 
    ]

SMART_OPERATIONS = [ 
    '--create', 
    '--patch-syslinux',
    '--label',    
    '--syslinux' 
    ]

MAJOR_MODES = [ 
    'modify',
    'inspect'
    ]

COPY_OPERATIONS = [
    '--copydef',
    '--copydir',
    '--copytar',
    '--copy',
    '--copy-iso-files', 
    '--copy-isolinux-as-syslinux',
    ]

EDIT_OPERATIONS = [
    '--append',
    '--delete-line',
    '--delete-near',
    '--editdef',
    '--edit',
    '--insert-start',
    '--insert-end',
    '--insert-line',
    '--insert-near',
    '--prepend',
    '--replace',
    ]

MODIFY_OPERATIONS = SMART_OPERATIONS + COPY_OPERATIONS + EDIT_OPERATIONS


class ArgParsingMetaData:
    MODES = {
        'modify':  MODIFY_OPERATIONS  + INSPECT_OPERATIONS ,
        'inspect': INSPECT_OPERATIONS ,
        'global' : MAJOR_MODES
    }

    # parent mode -> minor mode lookup:
    # There doesn't seem to be any reasonable way in python to split this over multiple lines
    OPERATIONS = [ 'global' ] + INSPECT_OPERATIONS + COPY_OPERATIONS + SMART_OPERATIONS + EDIT_OPERATIONS    

    LIFT_UP = {
        'global': MAJOR_MODES,
        'modify': [ '--create' ],
    }

    FLOW_DOWN = {
        'global': [ 'debug', 'quiet', 'verbose', 'isofile', 'imgfile', 'imgformat' ],
        'modify': [ ] 
    }
    
    FLOW_DOWN_APPEND = {
        # The need for this has largely been replaced by the --editdef container sibling
        'modify': [ 'exclude' ]
    }

def munge_name(name):
    """ 
    Turn an argparse argument ('--cat') into a string that can be
    used as a python token, for use in a method name.
    For example --cat becomes simply cat. --abc-def becomes abc_def.
    """
    munged_name = name.replace('-','_')
    if munged_name.startswith('__'):
        munged_name=munged_name[2:]
    return munged_name

    
class ArgList:
    """ 
    Storage for the args prior to passing them to argparse..
    This class is what allows us to have multiple edit operations
    with the same flags, which argparse doesn't allow.
    For example this allows us to do:
       $0 inspect --cat /abc.txt --cat /def.txt 
    
    The ArgParsingBase helper class below uses this class as temporary
    storage for options from the commandline prior to passing broken-up chunks
    of them to argparse.
    """
    def __init__(self,name,pseudo=False,parent=None,arglist=None,children=None):
        if arglist is None:
            argslist = []
        if children is None:
            children = []
        self.name = name
        self.parent = parent
        self.arglist = arglist 
        self.children = []
        self.args = None
        self.pseudo = pseudo

    def add_child(self,child):
        self.children.append(child)
        child.parent = self

    def add_children(self,items):
        for c in items:
            self.add_child(c)

    def parse(self,lookup):
        if self.name not in lookup or not lookup[self.name]:
            print("No parser for {} in {}".format(self.name,lookup))
            return argparse.Namespace()
        parser = lookup[self.name]
        prefix = [] # if self.pseudo else [self.name]
        parent_args = parser.parse_args(prefix+self.arglist)
        child_parsed = []
        lift_up = ArgParsingMetaData.LIFT_UP[self.name] if self.name in ArgParsingMetaData.LIFT_UP else []
        for child in self.children:
            #child_parsed.append(parser.parse_args([ self.name , child.name]+ child.arglist))) 
            #child_parsed.append(lookup[child.name].parse_args(prefix + [ child.name]+ child.arglist)) 
            parsed = child.parse(lookup)
            child_parsed.append(parsed)
            if child.name in lift_up:
                vars(parent_args)[munge_name(child.name)]=parsed
            else:
                pass

        if self.name in ArgParsingMetaData.FLOW_DOWN:
            md = ArgParsingMetaData.FLOW_DOWN[self.name]
            for name in md:
                if name in parent_args:
                    for child in child_parsed:
                        if name not in child and name in parent_args:
                            mine = vars(parent_args)[name] or None
                            if mine:
                                if not name in vars(child):
                                    vars(child)[name]=mine

        if self.name in ArgParsingMetaData.FLOW_DOWN:
            md = ArgParsingMetaData.FLOW_DOWN[self.name]
            for name in md:
                if name in parent_args:
                    for child in child_parsed:
                        if name not in child and name in parent_args:
                            mine = vars(parent_args)[name] or None
                            if mine:
                                vars(child)[name]=vars(parent_args)[name]

        if self.name in ArgParsingMetaData.FLOW_DOWN_APPEND:
            md = ArgParsingMetaData.FLOW_DOWN_APPEND[self.name]
            for name in md:
                if name in parent_args:
                    for child in child_parsed:
                        if name not in child:
                            vars(child)[name]=vars(parent_args)[name]
                        else:
                            mine = vars(parent_args)[name] or []
                            childs = vars(child)[name] or []
                            vars(child)[name]=mine+ childs

        vars(parent_args)['children']=child_parsed
        return parent_args

class ArgParsingBase:
    """ 
    Break up an argv array into small chunks which can then be
    passed to the argparse routines without bailing from 'duplicate' flags.
    """
    def __init__(self, metadata, defaultmode,mode_names):
        self.lookup = {} 
        self.metadata = metadata 
        self.defaultmode = defaultmode 
        self.mode_names = mode_names

    def parse_argv(self, argv):
        accumulate_args=[]
        accumulate_children=[]
        accumulate_mains=[]
        while argv:
            arg = argv.pop()
            if arg in ArgParsingMetaData.MODES:
                parent = ArgList(name=arg,arglist=accumulate_args,children=accumulate_children)
                accumulate_mains.append(parent)
                parent.add_children(accumulate_children)
                accumulate_children=[]
                accumulate_args=[]
            elif arg in ArgParsingMetaData.OPERATIONS:
                item = ArgList(name=arg,arglist=accumulate_args,children=None)
                accumulate_children.insert(0,item)
                accumulate_args=[]
            else:
                accumulate_args.insert(0,arg) 
        
        global_flags = accumulate_args
        root=ArgList('global', arglist=global_flags,pseudo=True)
        root.add_children(accumulate_mains)
        if accumulate_children:
            print("Warning: args got lost:{}".format(accumulate_children))
        return root.parse(self.lookup)


    def empty_parser(self,name):
        p = argparse.ArgumentParser()
        p.set_defaults(func=name)
        return p

    def store_sub_add(self, subs, name):
        sub = subs.add_parser(name)
        sub.set_defaults(func=name)
        return self.store_parser(name,sub)

    def find_setup_args_routine(self,name):
        method = getattr(self, 'setup_' + munge_name(name))
        return method

    def find_setup_subs_routine(self,name):
        method = getattr(self, 'setup_' + munge_name(name) + '_subs')
        return method

    def store_parser(self, name, parser=None):
        if parser is None:
            parser = argparse.ArgumentParser()
        self.lookup[name] = parser
        assert(self.lookup[name])
        assert parser
        return parser 

    def register_modes(self, parser, names=None,default_mode=None):
        if names is None:
            names=[]
        if default_mode:
            parser.set_defaults(cmd=default_mode)
        subs = parser.add_subparsers()
        ret = {}
        for name in names:
            result = self.store_parser(name, subs.add_parser(name))
            result.set_defaults(cmd=name)
            ret[name] = result 
        return (parser,subs,ret)

    def complete_setup(self, name,parser):
        if parser is None:
            parser = self.lookup[name]
        method = self.find_setup_args_routine(name)
        if method:
            method(parser)
        return parser

    def sub_helper(self, name, sub):
        self.complete_setup(name, self.store_sub_add(sub, name))

    def mode_helper(self, a,names):
        subs = a.add_subparsers()
        for name in names:
            self.sub_helper(name, subs)
        return (a,subs)

    def combined_parser(self, modes=None, default_mode=None, which=None):
        if modes is None:
            modes=[]

        parser = self.setup_global(self.store_parser('global'))

        _,_,modes =  self.register_modes(parser, names=modes, default_mode=default_mode)

        if which:
            selected = modes[which]
            routine = self.find_setup_args_routine(which)
            if routine:
                routine(selected)
            routine = self.find_setup_subs_routine(which)
            if routine:
                routine(selected)
    
        return parser

    def parse_args(self, argv):
        
        parser = None

        self.lookup = {} 

        which = None
        main_modes_specified=list(argv & self.metadata.MODES.keys())

        if not main_modes_specified:
            # The user didn't specify a main mode so generate 
            # a parser without any of the main modes populated
            parser = self.generate_combined_parser()
        elif len(main_modes_specified) > 1:
            # The user specified two main modes but should have
            # specified just one. Return a simple parser which will
            # be enough to inform them of the mistake.
            parser = self.generate_combined_parser()
        else:
            which = main_modes_specified[0]
            parser = self.generate_combined_parser(which)

        hierarchy = self.parse_argv(argv)
        return (hierarchy, which, parser)

    def generate_combined_parser(self, which=None):
        return self.combined_parser(modes=self.mode_names,default_mode=self.defaultmode, which=which)

class ArgParsing(ArgParsingBase):
    def __init__(self):
        super().__init__(ArgParsingMetaData,'modify',['modify','inspect'])

    def setup_global(self,a):
        a.add_argument('--img', '-o',
                       dest='imgfile', type=str, default='', 
                       help='image file (or possibly device?)')
        a.add_argument('--iso', '-i',
                       dest='isofile', type=str, default='',
                       help='ISO input file')
        a.add_argument('--debug',
                       dest='debug', action='store_true',
                       help='Enable debugging messages')
        a.add_argument('--quiet',
                       dest='quiet', action='store_true',
                       help='Silence some messages')
        a.add_argument('--verbose', '-v',
                       dest='verbose', action='count', default=0,
                       help='Print more information while doing the work')
        a.add_argument('--imgformat',
                       dest='imgformat', type=str, default='auto',
                       help='Specify image file format')
        a.add_argument('--qcow2',
                       dest='imgformat', const='qcow2',action='store_const',
                       help='Specify qcow2 image file format. Shortcut for --imgformat qcow2.')
        a.add_argument('--raw',
                       dest='imgformat', const='raw',action='store_const',
                       help='Specify raw image file format. Shortcut for --imgformat raw.')
        return a

    def setup_modify_subs(self, a):
        return self.mode_helper(a, MODIFY_OPERATIONS+INSPECT_OPERATIONS)

    def setup_inspect(self, a):
        return a

    def setup_inspect_subs(self, a):
        return self.mode_helper(a, INSPECT_OPERATIONS)

    def setup_copy_iso_files(self,a):
        return a

    def setup_copy_isolinux_as_syslinux(self,a):
        return a

    def setup_patch_syslinux(self,a):
        return a

    def setup_syslinux(self,a):
        a.add_argument('src',   type=str, nargs='?', help="Path to syslinux files")
        a.add_argument('--mbr', type=str, nargs='?', help='Name of a syslinux mbr file')
        a.add_argument('--menu-files', dest='menufiles', type=str, nargs='*', help='One or more syslinux menu or c32 files to copy')
        a.add_argument('--overwrite',  dest='overwrite', action='store_true', default=False, help='Seems like you need to overwrite the existing vesamenu.c32')
        return a
    
    def setup_copydir(self,a):
        return self.setup_copy_with_excludes(a)

    def setup_copytar(self,a):
        return self.setup_copy_with_excludes(a)
        
    def setup_copy_with_excludes(self,a):
        self.setup_copy(a)
        self.setup_exclude_option(a)
        return a

    def setup_exclude_option(self,a):
        a.add_argument('--exclude',   
                        dest='exclude', type=str,nargs='*', action='append', # This is required so that later specified args don't replace earlier ones
                        help='Exclude items when copying in dirs (--copy-dir mode). Use :<tar-exclude-option> for tar-specific options. See the tar man page. For example -   --exclude :vcs-ignores to ignore files specified in your .gitignore ')

    def setup_copy_common(self,a):
        a.add_argument('--overwrite', 
                       dest='overwrite', action='store_true', default=None, 
                       help='Overwrite files when copying data into the image')
        a.add_argument('--quick',
                       dest='overwrite', action='store_false', default=None,
                       help='Skip files/dirs that exist when copying data into the image')
        a.add_argument('--dstdir',
                       dest='dstdir', type=str, default=None,
                       help='Specify a destination folder for a copy operation')

    def setup_editdef(self,a):
        """ Edit defaults """
        return self.setup_edit_func(a,'path','match','search','text','location')

    def setup_copydef(self,a):
        """ Copy defaults """
        self.setup_copy_common(a)
        self.setup_exclude_option(a)
        return a
    
    def setup_copy(self,a):
        a.add_argument('src',
                       type=str, nargs='+', 
                       help='The source path to copy')
        self.setup_copy_common(a)
        a.add_argument('--dstname',
                       dest='dstname', type=str,  
                       help='Specify a destination filename for a copy operation')
        return a

    def setup_create(self,a):
        a.add_argument('--size',
                        dest='size', type=int, default=10000, 
                        help='Image size (in MB)')
        a.add_argument('--force',
                        action='store_true', default=None,
                        help='Allow create mode with an existing image (delete it)')
        return a

    def setup_label(self,a):
        a.add_argument('label',
                       nargs='?', type=str, default='auto',
                       help='Set a disk label, (or auto).') 
        a.add_argument('--patch', 
                       action='store_true', default=None,
                       help='Update the syslinux.cfg file also')
        return a

    def setup_edit(self,a):
        return self.setup_edit_func(a,'path?','action','match','search','text','location')

    def setup_replace(self,a):
        return self.setup_edit_func(a,'path?','match','search','text','location')

    def setup_append(self,a):
        return self.setup_edit_func(a,'path?','match','text')

    def setup_prepend(self,a):
        return self.setup_edit_func(a,'path?','match','text')

    def setup_insert_start(self,a):
        return self.setup_edit_func(a,'path?','text')

    def setup_insert_end(self,a):
        return self.setup_edit_func(a,'path?','text')

    def setup_insert_line(self,a):
        return self.setup_edit_func(a,'path?','text','location')

    def setup_insert_near(self,a):
        return self.setup_edit_func(a,'path?','match','text','location')

    def setup_delete_line(self,a):
        return self.setup_edit_func(a,'path?','location')

    def setup_delete_near(self,a):
        return self.setup_edit_func(a,'path?','match','location')

    def setup_edit_func(self,a, *items):
        for x in items:
            if x == 'path':
                a.add_argument('path',     default=None, help='The file to edit')
            if x == 'path?':
                a.add_argument('path',     nargs='?', default=None, help='The file to edit')
            if x == 'path*':
                a.add_argument('path',     nargs='*', default=None, help='The file to edit')
            if x == 'action':
                a.add_argument('action',   type=str, choices=['delete-line','insert-line','search-replace'])
            if x == 'match':
                a.add_argument('--match',  dest='match',  type=str, help='A regular expression to match only lines which you want to edit')
            if x == 'search':
                a.add_argument('--search', dest='search',  type=str, help='The text which will be replaced (within a line), use ~ prefix for a regex')
            if x == 'text':
                a.add_argument('--text', dest='text',     type=str, help='The new line or replacement text. ignored for insert-line,delete-line')
            if x == 'location':
                a.add_argument('--line', dest='location', type=int, default=0, help='A line offset (delete or insert in a different position)')
        return a 

    def setup_ls(self,a):
        a.add_argument('path',    help='The path to inspect')
        return a

    def setup_cat(self,a):
        a.add_argument('path',    help='The path to cat')
        return a

    def setup_modify(self,a):
        a.add_argument('--debug',          
                       dest='debug',   action='store_true', 
                       help='Enable debugging messages')
        a.add_argument('--clear',          
                       dest='clear',   action='store_true', 
                       help='Clear any automated actions and only perform those specified on the commandline')
        a.add_argument('--centos7',        
                       dest='canned',  const='centos7',action='store_const', 
                       help='Select auto setup for a centos7 ISO')
        a.add_argument('--defaults',       
                       dest='canned',  const='defaults',action='store_const', 
                       help='Select auto setup')
        a.add_argument('--minimal',        
                       dest='canned',  const='minimal',action='store_const', 
                       help='Select image creation without any other auto setup (file copying, label updating, syslinux operations).')
        a.add_argument('--fstype',  '-f',  
                       dest='fstype',  type=str, default=Defaults.FSTYPE, 
                       help='Specify filesystem type')
        a.add_argument('--vfat',           
                       dest='fstype',  const='vfat',action='store_const', 
                       help='Specify vfat filesystem format. Shortcut for --fstype vfat.')
        a.add_argument('--ext4',           
                       dest='fstype',  const='ext4',action='store_const', 
                       help='Specify ext4 filesystem format. Shortcut for --fstype ext4.')
        a.add_argument('--ext2',           
                       dest='fstype',  const='ext2',action='store_const', 
                       help='Specify ext4 filesystem format. Shortcut for --fstype ext2.')
        a.add_argument('--patch', '-p', 
                       dest='patch',   action='store_true', 
                       help='Allow patching boot entries in the syslinux file to match the volume label')
        self.setup_copy_common(a)
        self.setup_exclude_option(a)
        return a

def path_join(src,*items):
    """ Python is so stupid sometimes. 
        The os.path.xjoin implementation deliberately does not join multiple paths 
        starting with the separator - instead if it sees another path with a separator,
        it throws away everything preceeding it. 
        So, os.path.xjoin('/usb','/syslinux') returns '/syslinux', it does not JOIN them at all.
        It should be called 'os.path.xjoin_or_not_join_just_when_youre_least_expecting_it()'
        Thus, in order to allow the user to specify a virtual path with a slash at
        the front, we have to strip it away here.
        """

    if not items:
        return src

    # First make sure there's at most one separator to take off.
    # We can't use os.path.normpath either because that takes off
    # the separator from the end, which we don't want to do.
    sep = os.path.sep 
    out = src + sep
    last_item = src
    for x in items:
        out += sep
        out += x 
        last_item = x
    out = os.path.normpath(out)
    # Make sure the output path ends with a separator if one was specified
    if x and x.endswith(sep):
        out += sep 

    return out


class Edit:
    """
    basic file editor for editing contents of files inside the image
    """
    def __init__(self,
                 line_match='.*',
                 action=None,
                 search='~.*',
                 text=None,
                 location=0):

        if text is None and action not in ['delete-line']:
            raise ValueError("No edit text specified for action {}".format(action))

        if action in ['delete-line','insert-line']:
            if (line_match is None or line_match == '' ) and location is None:
                raise ValueError("No line number or pattern specified for {}".format(action))

        if action == 'search-replace' and search is None:
            raise ValueError("No search specified for search-replace")

        if not line_match and location is None:
            raise ValueError("No line matcher or line numbering specified for {}".format(action))

        self.line_match = line_match
        self.action = action
        self.search = search
        self.text = text
        self.location = location

    def __str__(self):
        out=[]
        out.append(self.action)
        if self.search:
            out.append("find lines with {}".format(self.line_match))
        if self.action == 'search-replace':
            out.append("replace '{}' with '{}'".format(self.search,self.text))
        elif not self.action.startswith('delete'):
            if self.text is not None:
                out.append("'{}'".format(self.text))
        if self.location is not None:
            out.append("using line number or line offset {}".format(self.location))
        return " ".join(out)

    def edit(self,lines):
        line_match=self.line_match 
        text = self.text
        search = self.search
        action = self.action 
        location = self.location 

        changes = 0
        insertions = 0
        deletions = 0
        matched = 0

        # an array of line numbers
        lines_matched=[]

        line_count=len(lines)

        if line_match is None:
            # convert just a location(line number) into
            # line offset from start or end.
            if location < 0:
                line_match='$$'
            else:
                line_match='^^'
        if line_match == '^^':
            lines_matched.append(0)
            matched += 1
        elif line_match == '$$':
            lines_matched.append(line_count-1)
            matched += 1
        elif line_match[0] == '~':
            for idx,line in enumerate(lines):
                m = re.search(line_match[1:],line)
                if m:
                    lines_matched.append(idx)
                    matched += 1
        else:
            for idx,line in enumerate(lines):
                if line_match in line:
                    lines_matched.append(idx)
                    matched += 1

        if not matched:
            print("No lines matched "+line_match)
            return 0,0, lines, []
        
        # new data for the file. a list of items for each line.
        # deletions will be performed by setting an empty array
        # insertions will be performed by addign an item for a row
        new_data=[ 
                    [
                        [],  #insertions before the line
                        [x], # original line
                        [],  # edits (new text, or None for a deletion)
                        []   # insertions after
                    ] for x in lines]

        while lines_matched:
            # process matched lines from the end
            # so that insertions/deletions do not
            # affect line numbers that haven't been procesed yet.
            line_number = lines_matched.pop()
            if location is not None:
                line_number = line_number + location 

            if action == 'delete-line':
                if line_number >= 0 and line_number < line_count:
                    new_data[line_number][2]=[None]
                    deletions += 1
            elif action == 'insert-line':
                if line_number == -1:
                    new_data[0][0].insert(0,text)
                    insertions += 1
                elif line_number == line_count:
                    new_data[line_count-1][0].append(text)
                    insertions += 1
                elif line_number < line_count:
                    new_data[line_number][0].insert(0,text)
                    insertions += 1
                else:
                    msg("Line number {} out of range ({})".format(line_count,line_number))
            elif action == 'search-replace':
                if line_number >= 0 and line_number < line_count:
                    oldline = lines[line_number]
                    changed = oldline
                    if search[0] == '~':
                        changed = re.sub(search[1:],text,oldline)
                    else:
                        changed = oldline.replace(search,text)
 
                    if changed != oldline:
                        changes += 1
                        new_data[line_number][2]=[changed]
                else:
                    msg("Line number {} out of range for this file ({} lines total)".format(location,line_count))

        if not changes and not insertions and not deletions:
            msg("The lines were not found (no insertions,deletions, or replacements made).")
            return matched,0, lines, []

        out = []
        diff = []
        for item in new_data:
            before = item[0]
            orig = item[1]
            edits = item[2]
            after = item[3]
            for b in before:
                diff.append("+"+b)
                out.append(b)
            if not edits:
                diff.append(" "+orig[0])
                out.append(orig[0])
            else:
                if edits[0] is None:
                    # line deleted
                    diff.append("-"+orig[0])
                else:
                    diff.append(":"+edits[0])
                    out.append(edits[0])
            for a in after:
                diff.append("+"+a)
                out.append(a)

        return matched, (changes+deletions+insertions), out, diff


builder = None 

def die(msg):
    global builder
    print(msg, file=sys.stderr)
    if builder:
        builder.cleanup()
    sys.exit(1)

def msg(strmsg):
    print(strmsg,file=sys.stderr)

class Syslinux:

    def __init__(self,rootpath=Defaults.SYSLINUX_PATH,menufiles=Defaults.SYSLINUX_MENU_FILES,mbrfile=Defaults.SYSLINUX_MBR_FILE):
        self.rootpath = rootpath
        self.menufiles = menufiles.split(',') if menufiles and isinstance(menufiles,str) else menufiles if menufiles else []
        self.mbrfile = mbrfile 

    def file_path(self,name):
        path = path_join(self.rootpath,name)
        if os.path.exists(path):
            return path
        else:
            print("Warning: File "+path+" was not found!")
            return None

    def mbr_file(self):
        return self.file_path(self.mbrfile)

    def file_paths(self,names=None):
        if names is None:
            names=self.menufiles
        
        ret=[]
        
        for name in names:
            path = self.file_path(name)
            if path:
                ret.append(path)
        
        return ret


class Action:
    def run(self,builder):
        return False

class EditFileAction(Action):
    def __init__(self, path=None, action=None, line_match=None, text=None, search=None, location=None):
        self.path       = path
        # pattern for finding a line (specify this or else location)
        # the pattern '^' will match the start of a file instead of matching every line
        # the pattern '$' will match the end of a file instead of matching every line
        self.line_match = line_match 
        self.action     = action      # search-replace,'delete-line','insert-line','insert-before','insert-after'
        self.search     = search     # ~regex, or plain text
        self.text       = text       # plain text replacement
        self.location   = location    # a line number 
        self.edit = Edit(line_match=self.line_match,
                         action=self.action,
                         search=self.search,
                         text=self.text,
                         location=self.location)

    def GenericEdit(path, line_match, search, text,location):
        return EditFileAction(path, action='search-replace', line_match=line_match, search=search, text=text, location=location)

    def Sed(path, line_match, search, text,location):
        return EditFileAction(path, action='search-replace', line_match=line_match, search=search, text=text, location=location)

    def Replace(path, line_match, search, text,location):
        return EditFileAction(path, action='search-replace', line_match=line_match, search=search, text=text, location=location)

    def Append(path, line_match, text):
        return EditFileAction(path, action='search-replace', line_match=line_match, search='~$', text=text)

    def Prepend(path,line_match, text):
        return EditFileAction(path, action='search-replace', line_match=line_match, search='~^', text=text)

    def InsertAtStart(path,text):
        """ Insert a line somewhere from the start of the file """
        return EditFileAction(path, action='insert-line', line_match='^^', text=text, location=0)

    def InsertAtEnd(path,text):
        """ Insert a line somewhere from the end of the file """
        return EditFileAction(path, action='insert-line', line_match='$$', text=text, location=-1)

    def InsertAtLine(path,text,location):
        return EditFileAction(path, action='insert-line', line_match='', search='', text=text, location=location)

    def InsertNear(path,line_match,text,location):
        return EditFileAction(path, action='insert-line', line_match=line_match, text=text, location=location)

    def DeleteLine(path, location):
        return EditFileAction(path, action='delete-line', line_match='', location=location)

    def DeleteNear(path, line_match, location):
        return EditFileAction(path, action='delete-line', line_match=line_match, location=location)


    def run(self,builder):
        builder.edit_path(self.path,self.edit);
        return True

    def __str__(self):
        return "Patch file {} with edit {}".format(self.path,self.edit)

class BaseCopyAction(Action):
    FALLBACK = AttrDict({'src':[], 'dstdir': '', 'dstname': '', 'exclude': [], 'overwrite': False})
    
    def __init__(self,*src,args=None,defaults=None, dstname="",dstdir="",overwrite=False, exclude=None):
        """ 
        if args is specified it will be used instead of all other parameters, and should
        be a dict or an argparse Namespace, but the parameter will be used as a 
        default where the value in the argpars args is not present 
        """
        
        if not args:
            args= BaseCopyAction.FALLBACK
        if not defaults:
            defaults= BaseCopyAction.FALLBACK

        self.items=args.src or src or defaults.src
        self.dstdir=args.dstdir or dstdir or defaults.dstdir
        self.dstname=args.dstname or dstname # No dstname from defaults - this is an individual parameter
        self.overwrite=args.overwrite or overwrite or defaults.overwrite
        self.exclude=list(itertools.chain.from_iterable(args.exclude or exclude or defaults.exclude))


    def _dst_str(self):
        to = "{}{}{}".format(self.dstdir,"/" if self.dstdir else "", self.dstname)
        return " to {}{}".format(to if to else 'the image',' (with overwriting)' if self.overwrite else '')

    def __str__(self):
        return "Copy {}{}.".format(",".join(self.items or []), self._dst_str())

class CopyAction(BaseCopyAction):
    def run(self,builder):
        builder.copy_files_generic(self.items,dstdir=self.dstdir,dstpath=self.dstname,overwrite=self.overwrite)
        return True

class CopyTarAction(BaseCopyAction):
    def run(self,builder):
        if self.dstname:
            msg("Warning: destination naming does not work for copy tar action!")
        builder.copy_tar_in(self.item[0],dstdir=self.dstdir,overwrite=self.overwrite)
        return True
    def __str__(self):
        return "Copy tar {} in{}.".format(self.items[0],self._dst_str())

class CopyDirAction(BaseCopyAction):
    def run(self,builder):
        builder.copy_dir_in(self.items[0],dstdir=self.dstdir,dstpath=self.dstname,overwrite=self.overwrite,exclude=self.exclude)
        return True
    def __str__(self):
        return "Copy dir {} in{}.".format(self.items[0],self._dst_str())

class CopyGlobAction(BaseCopyAction):
    def __init__(self,glob,**kwargs):
        super().__init__(**kwargs)
        self.glob=glob 
    def run(self,builder):
        builder.copy_files_generic(self.glob,dstdir=self.dstdir,dstpath=self.dstname,overwrite=self.overwrite)
        return True
    def __str__(self):
        return "Copy paths matching {} {}.".format(self.glob,self._dst_str())

class CopyAllIsoFilesAction(BaseCopyAction):
    def run(self,builder):
        if self.dstname:
            msg("Warning - dstname {} is ignored while copying iso files - use dstdir instead".format(self.dstname))
        builder.copy_all_from_iso_to_dir(dstdir=self.dstdir,ignore_isolinux=True,overwrite=self.overwrite)
        return True
    def __str__(self):
        return "Copy all files from within the primary ISO (excepts isolinux dir) to the image"

class CopyIsoFileAction(BaseCopyAction):
    def run(self,builder):
        builder.copy_iso_file(dstdir=self.dstdir,dstname=self.dstname,overwrite=self.overwrite)
        return True
    def __str__(self):
        return "Copy ISO File"

class CopyIsolinuxAsSyslinuxAction(BaseCopyAction):
    def __init__(self,args=None,overwrite=False):
        if args:
            args['src']='/iso'
        super().__init__('/iso',args=args,overwrite=overwrite)
    def run(self,builder):
        builder.copy_isolinux_as_syslinux(overwrite=self.overwrite)
        return True
    def __str__(self):
        return "Copy isolinux dir as syslinux"
        
class SyslinuxAction(Action):
    def __init__(self,src=None,mbr=None,menufiles=None,overwrite=False):
        self.src=src or Defaults.SYSLINUX_PATH
        self.mbr=mbr or Defaults.SYSLINUX_MBR_FILE
        self.menufiles=menufiles or Defaults.SYSLINUX_MENU_FILES
        self.overwrite=overwrite
    def run(self,builder):
        builder.install_syslinux(self.src,self.mbr,self.menufiles,overwrite=self.overwrite)
        return True
    def __str__(self):
        return "Install syslinux files"

class UpdateLabelAction(Action):
    """ Update the image label, and update the boot file (optional) """
    def __init__(self,label,patch_sysconfig_labels):
        self.label=label
        self.patch_sysconfig_labels=patch_sysconfig_labels
    def run(self,builder):
        builder.update_label(oldlabel='auto',newlabel=self.label,patch_sysconfig_labels= self.patch_sysconfig_labels)
        return True
    def __str__(self):
        return "Update volume label ({}){}".format(self.label, ' (updating sysconfig boot lines too)' if self.patch_sysconfig_labels else '')

class AutoLabelAction(Action):
    """ Automatically try to make sure the boot label and image label match """
    def __init__(self):
        pass
    def run(self,builder):
        builder.auto_label()
        return True
    def __str__(self):
        return "Update boot label to match volume label if possible"

class AutoSyslinuxPatchAction(Action):
    """ Automatically try to update the labels in the syslinux.cfg to  make sure the boot label and image label match """
    def __init__(self):
        pass
    def run(self,builder):
        builder.update_label(oldlabel=None,newlabel=None,patch_sysconfig_labels=True)
        return True
    def __str__(self):
        return "Update configured boot label to match volume label if possible"

class InspectAction(Action):
    def __init__(self,*paths,display_contents=False):
        self.paths=paths
        self.display_contents=display_contents
    def run(self,builder):
        builder.inspect_paths(self.paths,display_contents=self.display_contents)
        return True
    def __str__(self):
        return "Inspect paths {}".format(self.paths)

class CreateImageAction(Action):
    def __init__(self,size,force):
        self.size=size
        self.force=force
    def run(self,builder):
        builder.prepare_for_build(self.size,self.force)
        return True
    def __str__(self):
        return "Create image file (size {} MB)".format(self.size)

class BeginUpdateAction(Action):
    def run(self,builder):
        builder.prepare_for_update()
        return True
    def __str__(self):
        return "Update existing image file"

class VerboseBase:
    """ Base class to assist in seeing what's going on """
    def __init__(self,
                 verbose=0,
                 quiet=False,
                 indent_base="    "
                 ):
        self.verbose=verbose
        self.quiet=quiet
        self.indent=""
        self.indent_base=indent_base

    def msg(self,message):
        print(self.indent+message,file=sys.stderr)

    def begin(self,msg):
        if self.verbose:
            print(self.indent + msg, file=sys.stderr)
            self.indent += self.indent_base

    def end(self,ok=True):
        if self.verbose:
            unindent = len(self.indent_base)
            self.indent = self.indent[:-unindent]
            if ok:
                self.msg("OK")
            else:
                self.msg("Failed")
                raise ValueError("Something failed")

class ImageAccess(VerboseBase):
    """ Automate creation or access of image file and ISO to
    prepare for further operations """

    def __init__(self,
                 isofile=None,
                 usbfile=None,
                 fstype=None,
                 imgformat=None,
                 force=False,
                 verbose=0,
                 quiet=False,
                 indent_base="    "
                 ):
        super().__init__(verbose=verbose,quiet=quiet,indent_base=indent_base)

        self.isofile=isofile
        self.usbfile=usbfile
        self.imgformat=imgformat or 'auto'
        self.fstype=fstype or 'vfat'
        self.force=force

        self.iso_index=None
        self.usb_index=None
        self.usbpart=None
        self.g=None
        self.usb=None
        self.iso=None
        self.mounts={}

    def startup(self):
        self.begin("Startup guestfs")
        self.g = guestfs.GuestFS(python_return_dict=True)
        self.g.launch()
        self.end()
        
    def cleanup(self):
        self.begin("Cleanup")
        if self.g:
            self.umount()
            self.g.shutdown()
            self.g.close() 
            self.g = None
        self.end()

    def scan_partitioning(self):
        self.begin("Determine partitioning")

        if self.usb is None:
            self.msg("No usb/disk image device available for partitioning")
        elif self.usbpart is None:
            partitions = self.g.list_partitions()

            for part in partitions:
                if part.startswith(self.usb):
                    if self.verbose:
                        self.msg("Found USB/image partition "+part)
                    self.usbpart = part

        self.end()

    def define_images(self,create=False,size=None,imgformat=None,iso_mandatory=False,usb_mandatory=False):
        g = self.g

        self.begin("Access images")

        if imgformat is None:
            imgformat = self.imgformat

        if imgformat is None:
            imgformat = 'auto'

        if size is None or not size:
            size = Defaults.IMAGE_SIZE

        if self.usb or self.iso:
            self.msg("Already defined.")
        else:
            filename_format='unknown'
            fname_ext=''
            extension=''
            self.msg(f"Checking image file {self.usbfile} against imgformat {imgformat}")
            if self.usbfile.startswith("/dev"):
                filename_format = 'device'
                if imgformat == 'auto' or imgformat == '':
                    imgformat = 'raw'
                elif imgformat != 'raw':
                    die("Only raw imgformat supported for real devices")
                if not os.access(self.usbfile,os.W_OK):
                    self.msg("You do not have write access to device {self.usbfile}")
                    self.msg("You need to either run as root, or get access to this device.")
                    self.msg("Example commands:")
                    self.msg("   (as root): ")
                    self.msg(f"       chgrp adm {self.usbfile}")
                    self.msg(f"       usermod -a -G adm yourusername")
                    self.msg(f"  (then as your user, before retrying): ")
                    self.msg(f"       newgrp adm")
                    die("Cannot continue.")
                with open('/proc/mounts','r') as procmounts:
                    mountlines = procmounts.read().splitlines()
                    for mountline in mountlines:
                        if mountline.startswith(self.usbfile):
                            self.msg(f"Device {self.usbfile} appears to be mounted.")
                            die("Refusing to continue.")
            else:
                fname_main,fname_ext=os.path.splitext(self.usbfile)
                if fname_ext:
                    if fname_ext[0] == '.':
                        fname_ext=fname_ext[1:]
                    extension = fname_ext.lower()
                    if extension in Defaults.SUPPORTED_IMAGE_FORMATS:
                        filename_format=extension

            if imgformat == 'auto' or imgformat== '':
                if filename_format == 'unknown':
                    if create:
                        self.msg("I didn't know what filesystem format to use - defaulting to qcow2")
                        imgformat=Defaults.IMAGE_FORMAT
                    else:
                        raise ValueError("Please name the file with a recognised extension or specify the image format on the commandline")
                else:
                    imgformat=filename_format
            elif filename_format != 'device' and imgformat.lower() != extension.lower():
                self.msg("Warning: image filename seems to have different extension '{}' than the image format '{}'".format(extension,imgformat))
                self.msg("Specify the image format on the commandline correctly or use the default 'auto' when using existing images")
                self.msg("or rename the file.")
                self.msg("I will attempt to use the file with the format you specified: '{}'".format(imgformat))

            device_index=0

            # import old and new images
            if create:
                self.begin("Creating new repartitioned image with size {} MB".format(size))
                g.disk_create(self.usbfile, imgformat, size * 1024 * 1024) 
                self.end()

            if os.path.exists(self.usbfile):
                self.usb_index=device_index

                g.add_drive_opts(self.usbfile, format=imgformat, readonly=0, label="usb")
                device_index+=1
                devices = g.list_devices()
                assert(len(devices) == device_index)
                self.usb = devices[self.usb_index]
            else:
                if usb_mandatory:
                    self.msg("No USB image available")

            if os.path.exists(self.isofile):
                self.iso_index=device_index
                g.add_drive_opts(self.isofile, format="raw", readonly=1,label="iso")
                device_index+=1
                devices = g.list_devices()
                assert(len(devices) == device_index)
                self.iso = devices[self.iso_index]
            else:
                if iso_mandatory:
                    self.msg( "No ISO file available")

        self.end()
        return (self.usb,self.iso)

    def create_partitioning(self):
        self.begin("Partitioning")

        usb = self.usb
        g = self.g

        # create the partitions for new image
        self.begin("Create partitions on " + usb)
        g.part_init(usb, "mbr")
        g.part_add(usb, "primary", 2048, -1)

        partitions = g.list_partitions()
        if self.verbose:
            self.msg("Partitions are "+" ".join(partitions))
        self.end()
        
        usbpart = partitions[0]

        self.begin("Make " + self.fstype+" filesystem on " + usbpart)
        g.mkfs(self.fstype, usbpart)
        self.end()
        
        self.begin("Mark "+usbpart+" bootable")
        g.part_set_bootable(usb, 1, True)
        self.end()

        self.usbpart = usbpart 

        self.end()

    def mount(self,iso_mandatory=False,usb_mandatory=False):
        self.begin("Mount")
        self.mount_usb(mandatory=usb_mandatory)
        self.mount_iso(mandatory=iso_mandatory)
        self.end()

    def mount_iso(self,mandatory=True):
        self.mount_dev(self.iso,'iso',mandatory=mandatory)

    def mount_usb(self,mandatory=True):
        self.mount_dev(self.usbpart,'usb',mandatory=mandatory)

    def mount_dev(self,dev,name,mandatory=True):
        if not self.g:
            return False
        if not dev:
            if mandatory:
                self.msg("No device for {}".format(name))
                return False
            else:
                return True

        path='/'+name
        if name not in self.mounts:
            self.begin("Create mountpoint "+path)
            self.g.mkmountpoint(path)
            self.end()
            self.mounts[name]=None

        if not self.mounts[name]:
            self.begin("Mount "+path)
            self.g.mount(dev,path)
            self.end()
            self.mounts[name]=path
        
        return True

    def umount_dev(self,name):
        if not self.g:
            return
        path='/'+name
        if name in self.mounts and self.mounts[name]:
            self.begin("Umount "+path)
            self.g.umount(path)
            self.mounts[name]=None
            self.end()

    def umount_iso(self):
        self.umount_dev('iso')

    def umount_usb(self):
        self.umount_dev('usb')
    
    def umount(self):
        for name in self.mounts:
            self.umount_dev(name)

    def device_available(self,name):
        return name in self.mounts

    def require(self,*what):
        if not self.g:
            raise ValueError("Not ready for update")
        for item in what:
            if item == 'usb' and not self.usb:
                raise ValueError("No image destination available")
            elif item == 'iso' and not self.iso:
                raise ValueError("No iso file source available")
            elif item.startswith('/iso'):
                if not self.device_available('iso'):
                    raise ValueError("No iso available")
                elif not self.mounts['iso']:
                    if self.iso:
                        self.mount_iso()
                    else:
                        raise ValueError("No iso available")
            elif item.startswith('/usb'):
                if not self.device_available('usb'):
                    raise ValueError("No image available")
                if not self.mounts['usb']:
                    if self.usb:
                        self.mount_usb()
                    else:
                        raise ValueError("No usb/ image available")

    def display_lines(self, lines):
        for x in lines:
            print(self.indent + x)

    def ls(self,path,display=False):
        self.require(path)
        results = self.g.ls(path)
        if display:
            self.begin("Listing of "+path+":")
            self.display_lines(results)
            self.end()
        return results   

    def read_file(self,path):
        self.require(path)
        if self.g.exists(path):
            return self.g.cat(path)
        else:
            return None

    def display_path(self,path,display_contents=False):
        self.require(path)
        if not self.g.exists(path):
            self.msg("Path "+path+" does not exist")
        else:
            if self.g.is_dir(path):
                self.ls(path,display=display_contents)
            elif self.g.is_file(path):
                if display_contents:
                    content=self.g.cat(path)
                    self.begin("Contents of "+path+":")
                    lines=content.split('\n')
                    self.display_lines(lines)
                    self.end()
                else:
                    self.msg("File "+path+" exists")
                    parent,base = os.path.split(path)

    def delete_old_image(self):

        self.umount_usb()

        try:
            os.unlink(self.usbfile)
        except:
            pass



class ImageBuilderBase(ImageAccess):
    """ Provide some higher level operations """

    def __init__(self,label=None,syslinux=None,
                 **kwargs):

        super().__init__(**kwargs)

        self.label=label
        if syslinux is None:
            syslinux=Syslinux()
        self.syslinux=syslinux

    def read_syslinux_cfg(self):
        return self.read_file('/usb/syslinux/syslinux.cfg')

    def read_isolinux_cfg(self):
        return self.read_file('/usb/isolinux/isolinux.cfg')

    def read_xxxlinux_cfg(self):
        return self.read_syslinux_cfg() or self.read_isolinux_cfg()
        
    def determine_boot_label(self):
        cfgfile=self.read_xxxlinux_cfg()
        if not cfgfile:
            print("No syslinux config file - cannot search for labels")
            return

        lines=cfgfile.splitlines()
        labels=[]

        for line in lines: 
            if not line:
                continue
            parts = line.replace(':',' ').split(' ')
            for p in parts:
                if 'LABEL=' in p:
                    (start,end)=p.split('LABEL=')
                    end = end.replace('\\x20',' ')
                    if end and end not in labels:
                        labels.append(end)
        if len(labels) > 1:
            self.msg("Autolabel - Multiple potential labels found - please try specifying one of these manually")
            self.display_lines(labels)
            return None
        elif not labels:
            self.msg("Autolabel - No labels were found in the syslinux conf")
            return None
        else:
            self.msg("Autolabel - found label " + labels[0])
            return labels[0]


    def patch_file(self,path,
                    *edits,
                    dstdir="",
                    dry_run=False,
                    terse=True,
                    line_ending="\n"):

        self.require(path)
        
        if not dstdir:
            dstdir="/usb"
        
        path = path_join(dstdir,path)

        if not self.g.exists(path):
            self.msg("File not found")
            return False


        cfgdata = self.read_file(path)
        lines = cfgdata.splitlines()

        new_lines = lines 
        total_changes = 0
        total_matched = 0
        for edit in edits:
            matched, changed, new_lines, diff = edit.edit(new_lines)
            total_changes += changed
            total_matched += matched
            if dry_run or self.verbose:
                if changed:
                    self.msg("Changes:")
                    for line in diff:
                        if terse and line[0] == ' ':
                            continue
                        self.msg("|"+line) 
                    self.msg("OK")

        if not total_changes:
            if not total_matched:
                self.msg("No lines matched (no editing performed)")
                return True
            else:
                self.msg("No changes were made")
                return True
        new_content = line_ending.join(new_lines) + line_ending 

        if not dry_run:
            self.g.write(path,new_content)
            self.msg("Updated file {} successfully".format(path))

        return True

    def determine_usbfs_label(self):
        self.require('usb')
        return self.g.vfs_label(self.usbpart)

    def patch_boot_label(self,oldlabel,newlabel):
        self.require('/usb')
        self.begin("Patch boot menu label ({} -> {})".format(oldlabel,newlabel))
        syslinux_cfg='/syslinux/syslinux.cfg'
        searchtext = oldlabel.replace(' ','\\x20')
        newtext = newlabel.replace(' ','\\x20')
        self.patch_file(syslinux_cfg,Edit(action='search-replace',line_match='LABEL=',search='LABEL='+searchtext,text='LABEL='+newtext))

    def truncate_label_if_necessary(self,label):
        fslabel=label
        if self.fstype == 'vfat' and len(label) > 11:
            print("Warning - filesystem label is being truncated to 11 characters for vfat")
            fslabel=fslabel[0:11]
        return fslabel

    def set_label(self,label):
        self.begin("Update image filesystem label")
        self.require('usb') # require the device but not necessarily the filesystem mount
        if (not label and not self.label) or label == 'auto':
            label = self.determine_boot_label()
            if not label:
                msg("Could not determine a label to use")
        else:
            label = label if label else self.label

        if label:
            fslabel = self.truncate_label_if_necessary(label)
            self.g.set_label(self.usbpart, fslabel)
            self.label = fslabel

        self.end()
        return label

    def auto_label(self):
        self.begin("Auto Label")
        oldlabel = self.determine_boot_label()
        newlabel = self.determine_usbfs_label()
        if newlabel and oldlabel:
            # Update the boot menu file to match the device
            self.update_label(oldlabel,newlabel,patch_sysconfig_labels=True)
        else:
            msg("Could not determine a single correct label to use")

    def update_label(self,oldlabel=None,newlabel=None,patch_sysconfig_labels=False):
        self.begin("Update label")
        self.require('usb') # require the device but not necessarily the filesystem mount
        if newlabel:
            newlabel = self.set_label(newlabel)
        else:
            newlabel = self.determine_usbfs_label()

        if patch_sysconfig_labels:
            if not oldlabel or oldlabel == 'auto':
                oldlabel = self.determine_boot_label()
            if oldlabel:
                self.patch_boot_label(oldlabel,newlabel)

        self.end()

    def copy_isolinux_as_syslinux(self,overwrite=False):
        self.begin("Copy ISO boot contents")
        self.require('/iso','/usb')
        g = self.g
        if 'isolinux' in self.ls('/iso/'):
            self.begin("Copy isolinux as syslinux")
            if g.exists('/usb/syslinux'):
                if overwrite:
                    g.rm_rf('/usb/syslinux')
            if not g.exists('/usb/syslinux'):
                g.cp_a('/iso/isolinux','/usb/syslinux')
            self.end()
    
        self.begin("setup syslinux.cfg")
    
        if (not g.exists('/usb/syslinux.cfg')) or overwrite:
            g.cp_a('/usb/syslinux/isolinux.cfg','/usb/syslinux/syslinux.cfg')
    
        self.end()

    def copy_iso_file(self,dstdir="",dstname=None,overwrite=False):
        self.begin("Copy ISO")
        self.upload_file(self.isofile,dstdir=dstdir,dstname=dstname,overwrite=overwrite)
        self.end()

    def upload_file(self,src,dstdir="",dstpath="",overwrite=False):
        """ 
        Upload a file to a folder (within the image) and with a particular name 
            - the folder defaults to empty (the toplevel)
            - the name defaults to the base name of the original
        All destinations will have /usb prepended 
        """
        if not dstpath:
            dstpath=os.path.basename(src)
        if not dstdir:
            dstdir=""
        
        dstdir=path_join("/usb",dstdir)
        dstpath=path_join(dstdir,dstpath)
        self.begin("Upload "+src+" to "+dstpath)
        self.require(dstpath)

        exists = self.g.exists(dstpath) 
        if exists and not overwrite:
            self.msg("File {} already exists - skipping".format(dstpath))
        else:
            if exists:
                self.msg("Overwriting {}".format(dstpath))
            self.mkdirs(dstpath)
            self.g.upload(src, dstpath)

        self.end()

    def mkdirs(self,dstpath, full_path=False):
        if full_path:
            if not self.g.exists(dstpath):
                self.g.mkdir_p(dstpath)
        else:
            (parent,child)=os.path.split(dstpath)
            if not self.g.exists(parent):
                self.g.mkdir_p(parent)

    def install_syslinux(self,syslinux_path=None, mbr_file=None, menufiles=None,overwrite=False):
        if not self.usb:
            raise ValueError("No image available")

        if not self.g.feature_available(['syslinux']):
            die("no syslinux support")

        if not mbr_file and not menufiles:
            self.msg("Warning - No mbr file or syslinux files were specified for installation")

        if not syslinux_path:
            syslinux_path = self.syslinux.rootpath

        if mbr_file:
            self.begin("Load MBR")
            mbr_data=None
            if not os.path.exists(mbr_file) and mbr_file[0] != '/':
                mbr_file=self.syslinux.file_path(mbr_file)
            with open(mbr_file,"rb") as f:
                mbr_data = f.read()
            self.end()

            self.begin("Write MBR")
            self.g.pwrite_device(self.usb, mbr_data, 0)
            self.end()

        if menufiles:
            self.begin("Upload syslinux menu files.")
            self.require('/usb')
            for fpath in self.syslinux.file_paths():
                self.upload_file(fpath,'syslinux',overwrite=overwrite)
            self.end()

        if self.fstype.startswith('ext'):
            self.mount_usb()
            self.begin("Run extlinux")
            self.g.extlinux('/usb/syslinux')
            self.end()
        else:
            # syslinux mode is meant to run with the volume unmounted.
            self.umount_usb()
            self.begin("Run syslinux")
            self.g.syslinux(self.usbpart,'/syslinux')

            # Re-mount the USB
            self.mount_usb()
            self.end()

    def copy_path_from_iso(self,item,destfolder="",destpath=""):
        self.copy_path_from_iso_to_path(item,item,destfolder=destfolder,dstpath=dstpath)

    def path_glob(self,path,pattern):
        prefix=path+"/"
        self.require(prefix+pattern)
        glob_result= self.g.glob_expand_opts(prefix+pattern,directoryslash=True)
        ret=[]
        for item in glob_result:
            if item.startswith(prefix):
                ret.append(item[len(prefix):])
            else:
                msg("Weird result from glob is ignored:{}".format(item))
        return ret

    def copy_all_from_iso_to_dir(self,dstdir="",overwrite=False,ignore_isolinux=False):
        self.copy_glob_from_iso_to_dir('*',dstdir=dstdir,overwrite=overwrite,ignore_isolinux=ignore_isolinux)

    def copy_glob_from_iso_to_dir(self,glob,dstdir="",overwrite=False,ignore_isolinux=False):
        """ No support for dstpath in this one because it doesn't make sense when copying multiple sources - use dstdir instead """
        if not dstdir:
            dstdir=""
 
        dstdir = path_join("/usb",dstdir)
 
        self.begin("Copy "+glob+" to " + dstdir+" (added /usb)")
 
        self.require('/iso',dstdir)

        names=self.path_glob("/iso",glob)

        for item in names:
            if ignore_isolinux and item == 'isolinux':
                msg("Subdirectory isolinux is handled specially and ignored when copying '{}' files".format(glob))
            else:
                dstpath=path_join(dstdir,os.path.basename(item))
                self.mkdirs(dstpath)
                self.g.cp_a('/iso/'+item,dstpath)

        self.end()

    def copy_path_from_path_to_path(self,item,srcdir="",dstdir="",dstpath="",overwrite=False):
        self.msg("srcdir={}".format(srcdir))
        if not dstdir:
            dstdir=""
        dstdir=path_join("/usb",dstdir)

        if not srcdir:
            srcdir="/iso"

        self.begin("Copy "+srcdir+"/"+item+" to " + dstpath)
        self.require(srcdir,dstdir)

        dir_component,filename_component=os.path.split(item)
        parent = path_join(srcdir,dir_component)
        if filename_component in self.g.ls(parent):
            if not dstpath:
                dstpath=item
            dstpath=path_join(dstdir,dstpath)
            if self.g.exists(dstpath) and overwrite:
                self.g.rm_rf(dstpath)
            self.mkdirs(dstpath)
            if not self.g.exists(dstpath):
                self.g.cp_a(path_join(parent,filename_component), dstpath)
        else:
            self.msg("Not found on {} - {}".format(parent,filename_component))

        self.end()


    def copy_path_from_iso_to_path(self,item,dstdir="",dstpath="",overwrite=False):
        self.copy_path_from_path_to_path(item,srcdir="/iso",dstdir=dstdir,dstpath=dstpath,overwrite=overwrite)

    def copy_path_from_img_to_path(self,item,dstdir="",dstpath="",overwrite=False):
        self.copy_path_from_path_to_path(item,srcdir="/usb",dstdir=dstdir,dstpath=dstpath,overwrite=overwrite)
        
    def prepare_for_inspection(self):
        """ 
        Inspection allows for not having the USB image or ISO available.
        Additionally, inspection mode can be re-entered after update or create mode 
        """
        self.begin("Prepare for inspection")

        if not self.g:
            self.startup()
        
        if not self.define_images(create=False,iso_mandatory=False,usb_mandatory=False):
            return False

        self.scan_partitioning()
        self.mount(False,False)

        self.end()

    def prepare_for_update(self, require_iso=False):
        """ Update mode requires at least a USB file available """
        self.begin("Prepare for Update")
        if not os.path.exists(self.usbfile):
            raise ValueError("Output file does not yet exist!")

        if require_iso and not os.path.exists(self.isofile):
            raise ValueError("Iso file does not exist!")

        self.startup()
        if not self.define_images(create=False,iso_mandatory=False,usb_mandatory=True):
            return False
        self.scan_partitioning()
        self.mount(iso_mandatory=False,usb_mandatory=True)

        self.end()

    def prepare_for_build(self,size=None,force=False, iso_mandatory=False):
        self.begin("Prepare build")

        if iso_mandatory:
            if not ( self.isofile and os.path.exists(self.isofile)):
                raise ValueError("Iso file does not exist!")

        if self.usbfile and os.path.exists(self.usbfile):
            if force:
                self.delete_old_image()
            else:
                raise ValueError("Output file exists - set force flag to overwrite")
        
        self.startup()
        if not self.define_images(create=True,size=size,iso_mandatory=iso_mandatory,usb_mandatory=True):
            return False
        self.create_partitioning()
        self.mount(iso_mandatory=False,usb_mandatory=True)

        self.end()

    def copy_tar_in(self,tarfile,dstdir="",checkfolders=None,overwrite=False):
        """ 
        Extract a tar into the filesystem. 
        Cannot check for overwriting unless you specify a folder to check within the dstdir
        If you specify checkfolders, and overwrite=True,
        then the folders specified will be deleted first (so that you can do a 'clean')
        """

        if checkfolders is None:
            checkfolders=[]

        if not dstdir:
            dstdir=""

        dstdir=path_join("/usb",dstdir)
        self.require(dstdir)

        self.begin("Copy tar {} in to dstdir {}".format(tarfile,dstdir))

        any_existing = self._check_folders(dstdir=dstdir,checkfolders=checkfolders,overwrite=overwrite)

        # TODO: some code might have been deleted by stupid vscode shortcuts here
        if any_existing and not overwrite:
            msg("Not unpacking {} in {} because some content already existed".format(tarfile,dstdir))
        else:
            self.g.tar_in(tarfile, dstdir)

        self.end()

    def _check_folders(self,dstdir="",checkfolders=None,overwrite=False):
        if checkfolders is None:
            checkfolders=[]
        any_existing=False
        if checkfolders:
            for name in checkfolders:
                checkfolder=path_join(dstdir,checkfolder)
                if self.g.exists(checkfolder):
                    if self.overwrite:
                        self.g.rm_rf(checkfolder)
                    any_existing=True

    def copy_dir_in(self,extdir,dstdir="",dstpath="",checkfolders=None, overwrite=False,exclude=None):
        """ 
        Extract an external (host) dir into the filesystem
        """

        if not dstdir:
               dstdir=""
        
        dstdir=path_join("/usb",dstdir)
        # TODO: vscode has deleted code here

        if not dstpath:
            dstpath=os.path.basename(extdir)

        dstpath=path_join(dstdir,dstpath)

        if exclude is None:
            exclude=[]

        self.require(dstpath)

        any_existing = self._check_folders(dstdir=dstpath,checkfolders=checkfolders,overwrite=overwrite)

        if extdir.endswith("/..") or extdir.endswith("/../"):
            self.msg("Warning: -it is better to use a path with a directory at the end if you want to be sure of the name")
            self.msg("Converting {} to {}".format(extdir,os.path.realpath(extdir)))
            real_extdir=os.path.realpath(extdir)
            if not real_extdir or not os.path.exists(real_extdir):
                raise ValueError("Failed determining parent and subdirectory name from {}.".format(extdir))
            extdir=real_extdir
        
        (parent,name)=os.path.split(extdir)
        exclude_flags=[]
        for item in exclude:
            if item[0] == ':':
                if item[1:] in ['vcs-ignores','vcs','caches-all','caches-under','caches','backups']:
                    exclude_flags.append('--exclude-'+item[1:])
                elif item[1:].split('=')[0] in ['tag-under','tag-all','tag','ignore-recursive','ignore']:
                    exclude_flags.append('--exclude-'+item[1:])
                else:
                    msg("ERROR: Unsupported exclude tag {} will be ignored".format(item))
            else:
                exclude_flags.append('--exclude='+item)

        command=[ 'tar', 'cf', '-', '--checkpoint=1000', '-C', extdir ] + exclude_flags + [ '.' ]

        if self.verbose:
            self.msg("Spawning tar : {}".format(command))

        p = subprocess.Popen(command,stdout=subprocess.PIPE,close_fds=True)
        fileno = p.stdout.fileno()
        procfile = "/proc/"+str(os.getpid())+"/fd/"+str(fileno)
        
        self.mkdirs(dstpath,full_path=True)
        self.g.tar_in(procfile,dstpath)
        
        self.begin("Waiting for tar process to finish")
        retcode = p.wait()
        self.end()
        return retcode == 0

    def copy_files_generic(self,items, dstdir="",dstpath="",overwrite=False):
        """ 
        Generic copy which can source files from the iso or the host filesystem 
        a few extra special source items are recognised:
            :isolinux-as-syslinux
            :isofile
        If the source starts with / or ./ or '../' then it is assumed to be a path on the host filesystem,
        not in the image.
        If the source is relative (doesn't start with / or ./ or ../) then it is assumed to be 
        from the ISO.
        If you want to copy a file from the USB then, use the :usb: prefix.
        You can also be explicit about the ISO files by using the :iso: prefix,
        or the host by usign the :host: prefix
        """

        self.begin("Copying files from iso to {} - {}".format(dstpath,items))

        for item in items:
            if not item:
                continue 

            origin = ''
            if item[0] == ':':
                for x in ['host','usb','iso']:
                    if item.startswith(':'+x+':'):
                        origin=x
                        item=item[len(x)+2:]
                        self.msg("Origin of {} is {}".format(item,origin))
                        break
        
                if item == ":isolinux-as-syslinux":
                    self.copy_isolinux_as_syslinux(overwrite=overwrite)
                elif item == ":isofile":
                    self.copy_iso_file(dstdir=dstdir,dstpath=dstpath,overwrite=overwrite)
            
            if not origin:
                if item.startswith('/') or item.startswith('./') or item.startswith('../'):
                    origin = 'host'
                else:
                    # assume it is contents on the ISO
                    origin = 'iso'
            
            if origin == 'host':
                self.upload_file(item,dstdir=dstdir,dstpath=dstpath,overwrite=overwrite)
            elif origin == 'usb':
                self.copy_path_from_img_to_path(item,dstdir=dstdir,dstpath=dstpath,overwrite=overwrite)
            elif origin == 'iso':
                self.copy_path_from_iso_to_path(item,dstdir=dstdir,dstpath=dstpath,overwrite=overwrite)
    
        self.end()

    def inspect_paths(self,paths,display_contents=True):
        self.begin("Inspect paths "+" ".join(paths))
        for path in paths:
            self.display_path(path,display_contents=display_contents)
        self.end()

class ImageBuilder(ImageBuilderBase):
    
    def __init__(self,actions=None, **kwargs):

        if actions is None:
            actions=[]

        super().__init__(**kwargs)
        
        self.actions=actions 

    def clear_actions(self):
        self.actions=[]

    def add_action(self, action):
        self.actions.append(action)
    
    def edit_path(self, path,
                       *edits):
        self.begin("Edit path {}".format(path))
        if not path:
            raise ValueError("No path specified for edit")
        self.patch_file(path,*edits)
        self.end()

    def perform_actions(self,actions):
        for action in actions:
            if action:
                if not self.verbose and not self.quiet:
                    print(str(action))
                if not action.run(self):
                    return False
        return True 

    def perform_updates(self,actions):
        """ 
        Perform preconfigured actions in update or build mode, if actions is None or unspecified.
        If actions is passed and is not None, those actions will be performed instead.
        To perform no actions at all, pass an empty array.
         """
        self.mount()

        if actions is None:
            actions = self.actions

        result = self.perform_actions(actions)

        return result

    def inspect_mode(self):
        """ Inspect mode will prepare for inspection or update but will not perform any preconfigured updates """
        self.begin("INSPECT")
        self.prepare_for_inspection()
        self.end()
        return True

    def update_mode(self,actions=None):
        """ Update mode will prepare for update and then perform preconfigured updates """
        self.begin("UPDATE")

        self.prepare_for_update()

        result=self.perform_updates(actions)

        self.end(result)

        return result


    def build_mode(self,size=None,actions=None,force=False):
        self.begin("BUILD")

        self.prepare_for_build(size=size,force=force)

        result=self.perform_updates(actions)

        self.end(result)

        return result

class DoNothingImageBuilder(ImageBuilder):
    def __init__(self, **kwargs):
        super().__init__([],**kwargs)

class IsoBasedImageBuilder(ImageBuilder):
    """ 
    Some distros apparently build with the iso in the root of the stick, and the images and syslinux and that's it.
    I haven't seen that working, it would likely need customisation of the boot parameters in the syslinux file.
    Nevertheless, here is a basis for that mode.
    """
    def __init__(self, **kwargs):
        actions=[
            CopyIsolinuxAsSyslinuxAction(),
            CopyAction('images'),
            SyslinuxAction( 
                src=Defaults.SYSLINUX_PATH,
                mbr=Defaults.SYSLINUX_MBR_FILE, 
                menufiles=Defaults.SYSLINUX_MENU_FILES
            ),
            # In this mode it is assumed that the boot config
            # will somehow find the ISO with the volume label from the ISO
            # So, the disk image is NOT updated
            CopyIsoFileAction()
        ]
        super().__init__(actions,**kwargs)

class CopyFilesImageBuilder(ImageBuilder):
    """
    The only method I have seen working yet, is to copy the iso files (works with centos 7-1804).
    There is a Centos7 builder below, however this is a more generic one that
    performs a similar action - using a glob instead to copy all the files,
    whereas the centos builder is copying explicitly files known to be on the centos 7 minimal ISO.
    """
    def __init__(self,**kwargs):
        actions=[
            CopyIsolinuxAsSyslinuxAction(),
            SyslinuxAction( 
                src="/usr/share/syslinux",
                mbr='mbr.bin',
                menufiles='vesamenu.c32,libcom32.c32,libutil.c32,menu.c32'
            ),
            AutoLabelAction(),
            CopyAllIsoFilesAction()
        ]
        super().__init__(actions,**kwargs)

class Centos7ImageBuilder(ImageBuilder):
    def __init__(self,**kwargs):
        actions=[
            CopyIsolinuxAsSyslinuxAction(),
            CopyAction('images'),
            SyslinuxAction( 
                src='/usr/share/syslinux',
                mbr='mbr.bin',
                menufiles='vesamenu.c32,libcom32.c32,libutil.c32,menu.c32',
                overwrite=True  # vesamenu.c32 exists in the isolinux dir but does not work
            ),
            UpdateLabelAction('BOOT',True),
            CopyAction(
                'images',
                'repodata',
                'Packages',
                '.discinfo',
                '.treeinfo',
                'LiveOS',
                'CentOS_BuildTag',
                'RPM-GPG-KEY-CentOS-7',
                'RPM-GPG-KEY-CentOS-Testing-7'
            )
        ]
        super().__init__(actions,**kwargs)

def run(args):

    global builder

    is_modify = 'modify' in args and args.modify
    is_inspect = 'inspect' in args and args.inspect

    if not is_modify and not is_inspect:
        raise ValueError("Either modify or inspect mode must be specified")
    
    mode = args.modify if is_modify else args.inspect if is_inspect else {}

    try:
        params=dict(OrderedDict(
                force=mode.force if 'force' in mode else False,
                label=mode.label if 'label' in mode else '',
                isofile=args.isofile,
                usbfile=args.imgfile,
                imgformat=args.imgformat,
                verbose=args.verbose,
                fstype=mode.fstype if 'fstype' in mode else '',
                quiet=args.quiet,
                indent_base=("    " if args.verbose else "")
        ))

        if is_modify and args.modify.canned:
            if mode.canned == 'centos7':
                builder = Centos7ImageBuilder(**params)
            elif mode.canned == 'minimal':
                builder = DoNothingImageBuilder(**params)
            elif mode.canned == 'defaults':
                builder = CopyFilesImageBuilder(**params)
            elif mode.canned == 'iso-based':
                builder = IsoBasedImageBuilder(**params)
        else:
            builder = ImageBuilder(**params)

        if is_modify and mode.clear:
            builder.clear_actions()

        factory = ArgToActionFactory(args)

        print("Creating {} extra actions.".format(len(mode.children)))
        extra_actions = factory.generate_actions(args,mode.children)
    
        main_result=None

        if is_modify:
            if 'create' in mode:
                main_result = builder.build_mode(size=mode.create.size,force=mode.create.force)
            else:
                main_result = builder.update_mode()
        else:
            main_result = builder.inspect_mode()

        if main_result:
            if extra_actions:
                print("Running {} extra actions:".format(len(extra_actions)))
                for name in [x.__class__.__name__ for x in extra_actions]:
                    print(f"  - {name}")
                print(".")
                extra_result = builder.perform_actions(extra_actions)
                main_result = main_result and extra_result
            else:
                print("No extra actions to perform.")
        else:
            print("Main result was Fail - not continuing with extra actions specified.")

        if not main_result:
            print("Failed",file=sys.stderr)

        return main_result

    except ValueError as ve:
        print(ve)
        if args.debug:
            traceback.print_exc()
        return False
    finally:
        if builder:
            builder.cleanup()


class ArgToActionFactory:
    def __init__(self,args):
        self.args=args

    def generate_actions(self,args,items):

        # In modify mode, there will be two levels
        # of fallback values for these properties.
        # The first comes from values set on the 'modify' object
        # (early in the commandline).
        # The second comes from the most recent *preceding* '--copydef' or '--editdef'
        # sibling of the action being processed.

        moddef = AttrDict({
            'dstdir':  args.modify.dstdir ,
            'exclude': args.modify.exclude or [],
            'overwrite': args.modify.overwrite,
        }) if 'modify' in args else {}

        copydef = AttrDict({
            'dstdir':  args.modify.dstdir,
            'exclude': args.modify.exclude or [],
            'overwrite': args.modify.overwrite,
        }) if 'modify' in args else {}
        
        editdef = AttrDict({
            'path': None #/syslinux/syslinux.cfg'
        })

        ret = []
        for item in items:
            x = self.generate_action(item, moddef, editdef, copydef)
            if not x:
                if item.func not in [ '--copydef', '--editdef', '--create' ]:
                    msg("No action generated for {}".format(item))
            else:
                ret.append(x)
        return ret

    def generate_action(self, item, moddef, editdef, copydef):
            
        if 'modify' in self.args:
            if item.func == '--copydef':
                if item.dstdir:
                    copydef.dstdir=item.dstdir
                if item.exclude:
                    oldexclude=copydef.exclude
                    copydef.exclude=list(moddef.exclude) + list(item.exclude)
                if item.overwrite is not None:
                    copydef.overwrite=item.overwrite
            elif item.func == '--editdef':
                if item.path:
                    editdef.path=item.path
            elif item.func == '--copy':
                return CopyAction(args=item,dstdir=copydef.dstdir,overwrite=copydef.overwrite,defaults=copydef)
            elif item.func == '--copydir':
                return CopyDirAction(args=item,dstdir=copydef.dstdir,overwrite=copydef.overwrite,defaults=copydef)
            elif item.func == '--copytar':
                return CopyTarAction(args=item,dstdir=copydef.dstdir,overwrite=copydef.overwrite,defaults=copydef)
            # Note, the create action is not processed separately but done by the image builder
            # so there is no item for it here.
            elif item.func == '--label':
                return UpdateLabelAction(item.label,item.patch)
            elif item.func == '--copy-syslinux':
                return CopyIsolinuxAsSyslinuxAction()
            elif item.func == '--syslinux':
                return SyslinuxAction(item.src,item.mbr,item.menufiles,item.overwrite)
            elif item.func == '--copy-iso-file':
                return CopyIsoFileAction()
            elif item.func == '--copy-iso-files':
                return CopyAllIsoFilesAction()
            elif item.func == '--copy-isolinux-as-syslinux':
                return CopyIsolinuxAsSyslinuxAction()
            elif item.func == '--patch-syslinux':
                return AutoSyslinuxPatchAction()
            elif item.func == '--edit':
                return EditFileAction.GenericEdit(path=item.path or editdef.path, action=item.action, line_match=item.match, search=item.search, text=item.text, location=item.location)
            elif item.func == '--sed':
                return EditFileAction.Sed(path=item.path or editdef.path, line_match=item.match, search=item.search, text=item.text, location=item.location)
            elif item.func == '--replace':
                return EditFileAction.Replace(path=item.path or editdef.path, line_match=item.match, search=item.search, text=item.text, location=item.location)
            elif item.func == '--append':
                return EditFileAction.Append(path=item.path or editdef.path, line_match=item.match,  text=item.text)
            elif item.func == '--prepend':
                return EditFileAction.Prepend(path=item.path or editdef.path, line_match=item.match, text=item.text)
            elif item.func == '--insert-start':
                return EditFileAction.InsertAtStart(path=item.path or editdef.path, text=item.text)
            elif item.func == '--insert-end':
                return EditFileAction.InsertAtEnd(path=item.path or editdef.path, text=item.text)
            elif item.func == '--insert-line':
                return EditFileAction.InsertLine(path=item.path or editdef.path, text=item.text, location=item.location)
            elif item.func == '--insert-near':
                return EditFileAction.InsertNear(path=item.path or editdef.path, line_match=item.match, text=item.text, location=item.location)
            elif item.func == '--delete-line':
                return EditFileAction.DeleteLine(path=item.path or editdef.path, location=item.location)
            elif item.func == '--delete-near':
                return EditFileAction.DeleteNear(path=item.path or editdef.path, line_match=item.match, location=item.location)
        else:
            # At the moment there are no actions that are only for inspect mode
            pass

        # The following actions are valid for both modes
        if item.func == '--ls':
            return InspectAction(item.path)
        elif item.func == '--cat':
            return InspectAction(item.path,display_contents=True)


def main(argv):
    args,mode,parser = ArgParsing().parse_args(sys.argv[1:])

    if not args.imgfile and not args.isofile:
        parser.print_help()
        print("ERROR: Neither an iso file nor an image file were specified.", file=sys.stderr)
        sys.exit(1)

    run(args)

if __name__ == "__main__":
    main(sys.argv[1:])
