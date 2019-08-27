#!/bin/env python3
# read a bundle-dev file and setup and copy files into a usb image

import shlex
import sys
import glob
import os
import subprocess
import argparse
import re
from pprint import pprint, pformat
from attrdict import AttrDict, AttrMap
import itertools
from collections import Iterable
#from collections.iterable import Iterable

bullshit_message="DeprecationWarning: Using or importing the ABCs from 'collections' instead of from 'collections.abc' is deprecated, and in 3.8 it will stop working"

print("Python developers are _______. Seriously", file=sys.stderr)
print("Why:? Because they dump the message {}".format(bullshit_message), file=sys.stderr)
print("And yet, none of the following work. import collections.iterable, nor from collections.iterable import whatever", file=sys.stderr)
print("So what do they expect? We just have to put up with their rubbish, unclear, warnings (threats).", file=sys.stderr)


thismodule = sys.modules[__name__]

help_regex='^(-h|-help|--help.*|help.*)$'
bundled_regex='(^|.*/)bundled.*[.]properties$'
bundler_regex='(^|.*/)bundler.*[.]properties$'
relative_or_absolute_regex='^(|[.]{1,2})/'

from attrdict import AttrDict 

from enum import Enum

# Python enum's are pretty much usesless for any sane purpose
# (ie where you would want them to reduce code complexity, not increase it)
# So this is an Attrdict object instead 

#> adict = AttrDict(default_factory=lambda value: value.upper(), pass_key=True)

Directives = AttrDict(dict(
    ACTION='ACTION',
    APPEND='APPEND',
    BOOT='BOOT',
    BUILD='BUILD',
    BUILDER='BUILDER',
    COPY='COPY',
    DEBUG='DEBUG',
    DEFAULT='DEFAULT',
    DESCR='DESCR',
    DRY_RUN='DRY_RUN',
    EDIT='EDIT',
    EXCLUDES='EXCLUDES',
    FLAGS='FLAGS',
    HELPTEXT='HELPTEXT',
    IMAGE='IMAGE',
    ISO='ISO',
    LABEL='LABEL',
    MODES='MODES',
    ONLY='ONLY',
    SKIPTEXT='SKIPTEXT',
    TAR='TAR',
    TOPDIR='TOPDIR',
    VAR='VAR',
    VERBTEXT='VERBTEXT',
    VERSION='VERSION',
    VERBOSE='VERBOSE',
    CHECK_DEVICE='CHECK_DEVICE',
    LOAD='LOAD',
    STRICT='STRICT',
    FORMAT='FORMAT',
    ))

VALID_DIRECTIVES = [
   x  for x in Directives.keys()
]

class C(AttrDict):
    HEADER = 'soestack bundler properties file'
    AUTO = 'auto'
    INTO = 'into'
    HELP = 'HELP'
    ENTIRE = 'ENTIRE'
    CONTENTS = 'CONTENTS'
    LATEST = 'LATEST'
    SINGLE = 'SINGLE'
    INTO = 'INTO'
    IGNORING='IGNORING'
    AS = 'AS'
    FILE = 'FILE'
    DIR = 'DIR'
    COPY = 'COPY'
    TAR = 'TAR'
    DEFAULT = 'DEFAULT'

G = AttrMap({
        'APPEND': [],
        'ACTIONS': [],
        'BUILD': [],
        'BUILDER': [ "./build-boot-image.py" ],
        'BUNDLE_FILE': '',
        'BUNDLED': 'bundled',
        'DEBUG': 0,
        'DEFAULT': 'default',
        'DRY_RUN': 0,
        'EDIT': '',
        'BOOT': False,
        'EXCLUDES': [],
        'FLAGS': [],
        'IMAGE': 'boot-image.raw',
        'ISO': 'centos.iso',
        'LABEL': '',
        'MODE': '',
        'MODES': ['default'],
        'ONLY': [],
        'SUPPORTED_VERSION': '1',
        'TOPDIR': 'bundled',
        'TAR_CLEANUP': [], 
        'VARS': [],
        'VERBOSE': 0,
        'STRICT': 1,
        'FORMAT': '',
        },sequence_type=list)#,recursive=False)

def msg(*s):
    print(" ".join(s))

def verbmsg(*s):
    if G.VERBOSE and G.VERBOSE != '0':
        msg(*s)

def errmsg(*s):
    msg("ERROR",*s)

def dbgmsg(*s):
    if G.DEBUG:
        msg(*s)

def usage():
    argv0=sys.argv[0]
    msg(f"Usage: {argv0} bundler.properties")
    msg("")
    msg("   The file must start with 'bundler' and end with '.properties'")
    msg("")
    msg("      - this is to avoid confusion with the bundled.properties file")

def die(*s):
    msg("Fatal: "+" ".join(s))
    sys.exit(1)

def flatten_lists(l):
    for x in l:
        if isinstance(x,str):
            yield x
        elif isinstance(x, Iterable):
            for y in flatten_lists(x):
                yield y
        else:
            yield x

def do_copy(src,dst):

    if not re.match(relative_or_absolute_regex,src):
        verbmsg(f"** Converting relative path '{src}' to './{src}'.")
        src=f"./{src}"
    
    dst_parent=os.path.dirname(dst)
    dst_basename=os.path.basename(dst)

    copies=[]

    if os.path.isdir(src):
        copies.extend(["--copydir",src])
    else:
        copies.extend(["--copy",src])

    if dst_parent:
        copies.extend(["--dstdir",  dst_parent])

    if dst_basename:
        copies.extend(["--dstname", dst_basename])

    G.ACTIONS = G.ACTIONS + [copies]
    return True

def read_lines(file):
    with open(file,'r') as f:
        return [x.strip() for x in f.read().splitlines()]
    
    return None

def read_file(bundle_file,ignoring=[]):
    if not os.path.exists(bundle_file):
        msg(f"Bundle file not found: {bundle_file}")
        return False, []

    lines = read_lines(bundle_file)
    lines = [ x for x in lines if x ]  # make a copy, discarding empties

    if not lines:
        msg(f"Could not read file {bundle_file}, or the file is empty")
        return False, []

    accept = []
    num=0
    for l in lines:
        num += 1
        lex=shlex.split(l)
        if lex:
            if lex[0].startswith('#'):
                continue
            tok = lex[0]
            tok = tok.upper()
            tok = tok.replace('-','_')
            
            if tok in VALID_DIRECTIVES:
                if tok in ignoring:
                    msg(f"Ignoring {tok} directive while processing {bundle_file} as instructed")
                else:
                    line = [tok]+lex[1:] 
                    result = preprocess_line(line)
                    accept.extend(result)
            else:
                msg(f"Invalid directive:{tok}")
                msg(f"Valid directives are:{VALID_DIRECTIVES}")

    lines = accept

    if not lines:
        msg(f"No valid directives seen in {bundle_file}, or the file is empty.")
        return False, []

    if G.MODE != C.HELP:
        dv = Directives.VERSION
        if lines[0][0] != Directives.VERSION:
            msg(f'ERROR: No version header: Expected {dv.name}, saw {lines[0][0]}')
            return False, []
        elif len(lines[0]) < 2 or lines[0][1] != str(G.SUPPORTED_VERSION):
            msg(f"ERROR: Unsupported bundle file version {lines[0][1]} != {G.SUPPORTED_VERSION}")
            return False, []
        default_found=None
        def_lines = [x for x in lines if x[0] == Directives.DEFAULT and len(x) > 1]
        if def_lines:
            default_found=def_lines[0][1]
            msg(f"!!Default mode found - {default_found}")
        else:
            msg(f"!!No default mode found in the file - will use 'default'")

        mode_lines = [x for x in lines if x[0] == Directives.MODES and len(x) > 1]
        if mode_lines:
            G.MODES = list(itertools.chain.from_iterable([x.split(',') for x in mode_lines[0][1:]]))
            G.MODES = [ x.upper() for x in G.MODES ]

        if default_found:
            G.DEFAULT=default_found.upper()

        if not G.MODE:
            msg(f"!!Defaulting to mode {G.DEFAULT}")
            G.MODE=G.DEFAULT

        G.MODE = G.MODE.upper() 

        if G.MODE in G.MODES:
            msg(f"!!Mode {G.MODE} accepted")
        elif not G.MODES:
            G.MODES=[G.DEFAULT]
            msg(f"ERROR: Only '{G.DEFAULT}' mode supported with this file")
            return False, []
        elif G.MODE == C.DEFAULT:
            msg(f"!!Applying default mode {G.DEFAULT}")
            G.MODE=G.DEFAULT
        else:
            die(f"ERROR: Invalid mode '{G.MODE}' for this file: try one of {G.MODES}")

    return True,lines

def process_bundle(bundle_file):
    expected_successful = 0
    successful = 0
    skipped = 0
    
    success, lines = read_file(bundle_file,ignoring=[])
    if not success:
        msg(f"Failed reading file {bundle_file}")
        return False
    num_lines = len(lines)
    msg(f"!!Processing {num_lines} accepted lines")

    for l in lines:
        line = [ x for x in l]
 
        if line[0] in [Directives.DEFAULT, Directives.VERSION, Directives.MODES]:
            skipped += 1
            continue 
        expected_successful += 1
        if process_line(line):
            successful += 1
        else:
            msg(f"Problem on line :{l}")
            if G.STRICT:
                die(f"Strict mode - fatal error")

    if G.MODE != C.HELP:
        msg(f"{successful} actions of {expected_successful}")

        if successful != expected_successful:
            return False
        else:
            return True
    else:
        return True
    

def cleanup():
    if G.MODE != C.HELP:
        msg("Cleaning up")
        for tarf in G.TAR_CLEANUP:
            os.unlink(os.path.join(G.BUNDLED,tarf))

def replace_vars(items):
    if not G.VARS:
        return items
    ret=[]
    for x in items:
        for v in G.VARS:
            var_name = v[0]
            repl = ' '.join(v[1:])
            regex = '%'+var_name+'%'
            changed = re.sub(regex,repl, x)
            if changed != x:
                x = changed 
        ret.append(x)
    return ret 

def check_device(devname,model):
    modelpath=f'/sys/block/{devname}/device/model'
    if not os.path.exists(modelpath):
        errmsg(f"File does not exist: {modelpath}") 
        return False
    with open(modelpath,'r') as f:
        data = f.read().strip()
        if data != model:
            errmsg(f"Device {devname} did not have the expected model")
            errmsg(f"Expected {model} but found {data}")
            return False
        else:
            msg(f"Device {devname} has the expected model: '{model}'")
            return True

def preprocess_line(line):
    origline = line
    line = [ x for x in origline ]
    action = line[0]
    remainder = line[1:]
    if action == Directives.LOAD:
        msg(f"Preprocess {action}: {remainder}")
        if len(remainder) < 1:
            die("load directive requires a filename argument")
        filename = remainder.pop(0)
        if not os.path.exists(filename):
            die(f"File specified for loading did not exist: {filename}")
        ignoring = []
        if remainder:
            if remainder[0].upper() == C.IGNORING:
                remainder.pop(0)
                ignoring = [ x.upper() for x in remainder ]
            else:
                die(f"Extra tokens seen with load directive - This is a fatal error - just to be safe.")
        success, new_lines = read_file(filename, ignoring)
        if success:
            return new_lines
        else:
            die(f"Failed including file {filename}")
    else:
        return [line]

def process_line(line):
    action = line[0]
    remainder = line[1:]

    if action == Directives.HELPTEXT:
        if G.MODE == C.HELP:
            msg("## {}".format(" ".join(remainder)))
        else:
            verbmsg("@@ "+" ".join(remainder))
        return True

    if G.MODE == C.HELP:
        return True

    if action in [ G.DEFAULT, G.MODES ]:
        return True

    if action == Directives.ONLY:
        G.ONLY = list(itertools.chain.from_iterable([x.split(',') for x in remainder]))
        G.ONLY = [ x.upper() for x in G.ONLY ]
        return True

    if G.ONLY:
        if G.MODE not in G.ONLY:
            if action == Directives.SKIPTEXT:
                msg(f"-- {remainder}")
                return True
            else:
                dbgmsg(f"*** only in mode {G.ONLY} - [{line}]")
                return True
        else:
            # the line is accepted
            pass
    else:
        # the line is accepted by default since it is not limited by ONLY
        pass

    if action == Directives.VERBTEXT:
        verbmsg("@==============================================")
        verbmsg("@ "+ " ".join(remainder))
        verbmsg("@==============================================")
        return True

    if action == Directives.DESCR:
        msg("#==============================================")
        msg("# "+ " ".join(remainder))
        msg("#==============================================")
        return True

    msg(f"* {action} "+" ".join(remainder))

    if action not in [Directives.BOOT]:
        if len(remainder) < 1:
            msg("Not enough arguments for {action} - ignoring {line}")
            return False

    if action == [Directives.BOOT]:
        G.BOOT = True 
        return True
    elif action == G.MODES:
        G.MODES = remainder
        return True
    elif action == Directives.EXCLUDES:
        if remainder[0] == '--clear':
            G.EXCLUDES = remainder[1:]
        else:
            G.EXCLUDES.append(remainder)

        G.ACTIONS = G.ACTIONS+[ ["--copydef","--exclude"] + G.EXCLUDES ]
        return True
    elif action == Directives.BUILDER:
        G.BUILDER = remainder
        return True
    elif action == Directives.APPEND:
        var_name = remainder.pop(0)
        # This AttrMap object seems pretty crappy in that the objects
        # extracted from it do not modify the objects inside.
        # They have to be reassigned after modification
        current_vars = G.VARS
        for v in current_vars:
            if v[0] == var_name:
                v.extend(remainder)
                G.VARS = current_vars
                return True
        msg(f"No var {var_name} has been declared - ignoring {line}")
        return False
    elif action == Directives.CHECK_DEVICE:
        if len(remainder) < 2:
            die("check-device directive requires 2 arguments - a device and a model")

        devname = remainder.pop(0)
        model = remainder.pop(0)
        if not check_device(devname,model):
            die(f"Bailing - device check failed - expected device {devname} to have model={model}")
        else:
            verbmsg("Device check passed - safe to proceed")
            return True
    elif action == Directives.FLAGS:
        G.FLAGS = G.FLAGS + remainder
        return True
    elif action == Directives.EDIT:
        G.ACTIONS = G.ACTIONS + [["--editdef"] + remainder]
        return True
    elif action == Directives.VAR:
        var_name = remainder.pop(0)
        # We have to store this as a list (because of attrmap sequence_type), which makes it a bit awkward
        current_vars = G['VARS']
        for v in current_vars:
            if v[0] == var_name:
                del v[1:]
                v.append(remainder)
                return True
        current_vars.append([var_name]+remainder)
        G.VARS=current_vars
        return True
    elif action == Directives.ACTION:
        G.ACTIONS = G.ACTIONS + [remainder]
        return True
    elif action == Directives.BUILD:
        G.BUILD = G.BUILD + remainder
        return True
    elif action == Directives.TOPDIR:
        if len(remainder) > 1:
            msg(f"Ignoring line {line} - extra unrecognised tokens at end of line")
            return False
        G.TOPDIR=remainder[0]
        G.ACTIONS = G.ACTIONS + [["--copydef","--dstdir", G.TOPDIR]]
        return True
    elif action == Directives.EDIT:
        if len(remainder) > 1:
            msg(f"Ignoring line {line} - extra unrecognised tokens at end of line")
            return False
        G.EDIT = remainder[0]
        G.ACTIONS = G.ACTIONS + [["--editdef", G.EDIT]]
        return True
    elif action in [ Directives.IMAGE, Directives.ISO, Directives.DRY_RUN, Directives.VERBOSE, Directives.DEBUG, Directives.STRICT, Directives.FORMAT ]:
        if len(remainder) > 1:
            msg(f"Ignoring line {line} - extra unrecognised tokens at end of line")
            return False
        G[action]=remainder[0]
        return True
    elif action == Directives.LABEL:
        if len(remainder) > 1:
            msg(f"Ignoring line {line} - extra unrecognised tokens at end of line")
            return False
        G.LABEL = remainder[0] if remainder else C.AUTO
        return True
    elif action in [ Directives.COPY, Directives.TAR ]:
        return process_copy_action(line)
    elif action == G.MODES:
        # MODES is already handled while initially opening the file
        return True
    else:
        msg(f"*** WTF : {line}")
        return False

def process_copy_action(line):
    if len(line) < 4:
        msg(f"Missing items in copy line: {line}")
        return False

    action = line.pop(0).upper()
    style = line.pop(0).upper()
    kind = line.pop(0).upper()
    src = line.pop(0)

    if len(line) > 2:
        msg(f"Ignoring line {line} - extra unrecognised tokens at end of line")
        return False

    if len(line) == 1:
        msg(f"Ignoring line {line} - missing token at end of line")
        return False

    how = line.pop(0).upper() if line else C.INTO
    where = line.pop(0) if line else ''

    if action not in [ C.COPY, C.TAR ]:
        msg(f"Invalid action {action} - expected {C.COPY} or {C.TAR} [{line}]")
        return False
    
    if style not in [ C.ENTIRE, C.CONTENTS, C.LATEST, C.SINGLE ]:
        msg(f"Invalid style {style} - expected one of {C.ENTIRE}, {C.LATEST}, {C.SINGLE} or {C.CONTENTS} (with tar mode) [{line}]")
        return False

    if kind not in [ C.FILE, C.DIR ]:
        msg(f"Invalid kind {kind} - expected '{C.DIR}' or '{C.FILE}' [{line}]")
        return False 

    if how not in [ C.INTO, C.AS ]:
        msg(f"Invalid 'how' {how} - expected '{C.INTO}' or '{C.AS}' [{line}]")

    #if how and not where:
    #    msg(f"You didn't specify the destination after '{how}' - ignoring line '{line}'")
    #    return False

    if style == C.CONTENTS and action != C.TAR:
        msg(f"Style '{C.CONTENTS}' is only supported with action '{C.TAR}' - ignoring '{line}'")
        return False

    if style == C.SINGLE and kind != C.FILE:
        msg(f"Style '{C.SINGLE}' is only supported for '{C.FILE}' actions - ignoring '{line}'")
        return False
    
    if style == C.LATEST:
        files = glob.glob(src)
        latest = max(files, key=os.path.getmtime())
        if latest:
            src = latest
        else:
            msg(f"No result found for '{src}' - ignoring '{line}'")
            return False

    if not os.path.exists(src):
        msg(f"Source '{src}' not found - ignoring '{line}'")
        return False

    if kind == C.FILE and os.path.isdir(src):
        msg(f"Source '{src}' is a directory (expected a file) - ignoring '{line}'")
        return False

    if kind == C.DIR and not os.path.isdir(src):
        msg(f"Source '{src}' is not a directory - ignoring '{line}'")
        return False

    if action == C.TAR:
        # Determine the tar file name
        tar_path = G.BUNDLED
        tar_name = ""
        if how == C.INTO:
            # keep the same name as the src
            tar_name = os.path.basename(src)+'.tar'
        else:
            if not where.endswith('.tar'):
                tar_name = os.path.basename(where)+'.tar'
            else:
                tar_name = os.path.basename(where)

        if not os.path.isdir(G.BUNDLED) and ( os.path.exists(G.BUNDLED) or not os.makedirs(G.BUNDLED)):
            msg(f"Could not create {G.BUNDLED} dir - ignoring '{line}'")
            return False

        tar_file = os.path.join(G.BUNDLED,tar_name)
        G.TAR_CLEANUP.append(tar_name)

        src_canonical = os.path.normpath(src)
        src_parent = os.path.dirname(src_canonical)

        tar_dir = src_parent
        tar_spec = os.path.basename(src)
        tar_file_canonical = os.path.normpath(tar_file)
        tar_flags = [
            "cf",
            tar_file_canonical,
            '--checkpoint=10000'
        ]

        if style == C.CONTENTS:
            tar_dir = src
            tar_spec = "."
        
        tar_flags.extend(["-C", tar_dir])

        # Add the excludes
        for exc in G.EXCLUDES:
            if exc in [ ':vcs-ignores', ':vcs', ':caches-all', ':caches-under', ':caches', ':backups' ]:
                tar_flags.append('--exclude-' + exc[1:])
            else:
                m = re.match(r'^(:tag-under|:tag-all|:tag|:ignore-recursive|:ignore)=.*', exc)
                if m:
                    tar_flags.append('--exclude='+exc[1:])
                else:
                    tar_flags.append('--exclude='+exc)

        # The actual dir being tarred
        tar_flags.append(tar_spec)

        verbmsg(f"** Tar Command = tar "+ " ".join(tar_flags))
        proc = subprocess.run(["tar"] + tar_flags)

        if proc.returncode != 0:
            msg(f"Tar creation failed for line 'f{line}' - skipping")
            return False

        src = tar_file

    dstpath = ""
    if how == C.INTO:
        src_basename = os.path.basename(src)
        dstpath = os.path.join(where, src_basename)
    else:
        dstpath = where

    if do_copy(src, where):
        return True
    else:
        return False

def process_args(args):
    parser= argparse.ArgumentParser()
    parser.add_argument('file',      type=str)
    parser.add_argument('--mode',    '-m', type=str, nargs='?', default='default')
    parser.add_argument('--dry-run', '-d', dest='dry', action='store_true', default=False)
    parser.add_argument('--verbose', '-v', dest='verbose', action='count', default=0)
    parser.add_argument('--debug',   '-g', dest='debug', action='count', default=0)
    args = parser.parse_args(args)
    return args, parser

def display_cmd(cmd):
    indent=""
    indent1="      "
    indent2="            "
    indent3="                "
    indent4="                    "
    indent5="                        "
    newline_regex='^(modify|inspect|--create|--centos7|--minimal|--copy-isolinux-as-syslinux|--syslinux|--clear|--img|--iso|--label|--verbose|--debug|--minimal|--centos7|--copydir|--copy$|--copytar|--copydef|--edit|--append|--prepend|--delete.*|--insert.*|--replace)'
    indent1_regex='^(--img|--iso|inspect|modify|--debug|--verbose)$'
    indent1or2_regex='^(--debug|--verbose)$'
    indent2_regex='^(--label|--create|--ls|--cat|--editdef|--syslinux|--copydef|--minimal|--clear|--centos7|--copy-isolinux-as-syslinux|--verbose|--debug)$'
    indent3_regex='^(--copy.*|--edit$|--insert.*|--append.*|--delete.*|--replace)'

    cmd = [ x for x in cmd ]
    main_prog = cmd.pop(0)

    print(f"{main_prog} ",end="")

    while cmd:
        token = cmd.pop(0)
        if re.match(indent1_regex, token): 
            if re.match(indent1or2_regex,token) and indent == indent2:
                pass
            else:
                indent=indent1
        elif re.match(indent2_regex,token):
            indent=indent2
        elif re.match(indent3_regex,token):
            indent=indent3
            
        if re.match(newline_regex,token):
            print("")
            print(indent,end="")

        print(token+" ",end="")

    print("") 

def perform():
    
    cmd = []

    cmd.extend(G.BUILDER)
    cmd.extend(G.FLAGS) 

    if G.ISO:
        cmd.extend(["--iso", G.ISO])

    if G.IMAGE:
        cmd.extend(["--img", G.IMAGE])
       
    if G.FORMAT:
        cmd.extend(['--imgformat', G.FORMAT])

    cmd.extend(G.BUILD)

    if G.LABEL:
        cmd.extend(['--label', G.LABEL])

    cmd.extend(G.ACTIONS)

    #flatten = list(itertools.chain.from_iterable(cmd))
    flatten = list(flatten_lists(cmd))

    expanded = replace_vars(flatten)

    display_cmd(expanded)

    if G.DRY_RUN:
        print("(skip work - dry run mode)",file=sys.stderr)
        return True
    else:
        retcode = subprocess.call(expanded)
        return retcode == 0

def main(argv):
    args, parser = process_args(argv)
    
    G.BUNDLE_FILE = args.file
    G.MODE = args.mode.upper()
    G.DRY_RUN = args.dry
    G.VERBOSE = args.verbose
    G.DEBUG = args.debug

    cmdline_dry_run=G.DRY_RUN

    if re.match(bundled_regex, G.BUNDLE_FILE):
        msg("Got a bundled file but expected a bundler file")
        parser.print_help()
        sys.exit(1)
    elif not re.match(bundler_regex, G.BUNDLE_FILE):
        msg(f"Expected a file 'bundler.properties' or 'bundler-<something>.properties'")
        parser.print_help()
        sys.exit(1)
    else:
        verbmsg(f"Input filename seems ok: {G.BUNDLE_FILE}")

    if process_bundle(G.BUNDLE_FILE):
        bundle_dry_run = G.DRY_RUN and not str(G.DRY_RUN).lower() in ["0", "false","off"]
        G.DRY_RUN = cmdline_dry_run or bundle_dry_run
        if G.MODE != C.HELP:
            if perform():
                print("Done.")
            else:
                print("At least some errors occurred.")
    else:
        msg(f"Please fix any issues and retry")

if __name__ == "__main__":
    main(sys.argv[1:])
