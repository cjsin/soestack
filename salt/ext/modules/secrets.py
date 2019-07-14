# This module may be found using the extension_modules setting
# (it will look in a pillar dir under there)
# NOTE this module is the same as state/_modules/secrets.py, where it is
# provided for the minions
# If you make changes, please keep both in sync

"""
:maintainer:    example
:maturity:      new
:depends:       nothing
:platform:      all
"""

from __future__ import absolute_import
import uuid
from salt.utils.decorators.jinja import jinja_filter, JinjaFilter
from os.path import sep, pathsep
import traceback
import subprocess
import logging
import os
import base64
import random
from pprint import pprint, pformat

__virtualname__ = 'secrets'

__outputter__ = {
    'run': 'txt'
}

SALT_PKI='/etc/salt/pki'
STORAGE=os.path.sep.join(['/etc','salt','secrets'])
MINION_STORAGE=os.path.sep.join([STORAGE,'minion'])
MASTER_STORAGE=os.path.sep.join([STORAGE,'master'])

log = logging.getLogger(__name__)

def __init__(opts):
    init_storage()

def init_storage():
    try:
        os.makedirs(STORAGE ) #, mode=0o777, exist_ok=True)
    except:
        pass
    try:
        os.makedirs(MINION_STORAGE ) #, mode=0o777, exist_ok=True)
    except:
        pass
    try:
        os.makedirs(MASTER_STORAGE) #, mode=0o777, exist_ok=True)
    except:
        pass
    pass

def __virtual__():
    return __virtualname__

def master_keypair():
    """ Return the master keypair, only on the master """
    return os.path.sep.join([SALT_PKI,'master','master.pem'])

def master_pub():
    """ Return the master public key """
    return os.path.sep.join([SALT_PKI,'master','master.pub'])

def minion_pub(minion_id=None):
    if minion_id is None or minion_id == '__self__':
        return os.path.sep.join([SALT_PKI,'minion','minion.pub'])
    else:
        return os.path.sep.join([SALT_PKI,'master', 'minions', minion_id ] )

def minion_keypair(minion_id=None):
    if minion_id is None or minion_id == '__self__':
        return os.path.sep.join([SALT_PKI,'minion','minion.pem'])
    else:
        print("Minion keypair not available for specific minions yet")
        #return '/etc/salt/pki/minion/minion.pem'
        return None

def readfile(path):
    if path is None:
        return False, None
    try:
        with open(path, 'r') as f:
            encoded = f.read()
            return True, encoded
    except:
        traceback.print_exc()
        return False, None

def writefile(path,data):
    print("write {}".format(path))
    print("writing {} bytes of data".format(len(data)))
    if path is None:
        print("writefile path is none")
        return False
    if data is None:
        print("writefile data is none")
        return False
    try:
        print("B64 of data is :")
        print(base64.b64encode(data))
        with open(path, 'w') as f:
            f.write(data)
            print("writefile success")
            return True
    except:
        traceback.print_exc()
        print("Writefile exception")
        return False

def decrypt_secret_with(secret_name, keypath):
    return _decrypt(keypath, storage)

def encrypt_secret_for(secret_name, minion_id,use_base64=False):
    """ Requires to run on the master """
    data = get_master_secret(secret_name)
    success, data = _encrypt(minion_pub(minion_id), data, use_base64=use_base64)
    if success:
        return data
    else:
        return None

def minion_storage(secret_name):
    if sep in secret_name:
        print("Illegal secret name")
        return None
    return sep.join([MINION_STORAGE,secret_name])

def master_storage(secret_name):
    if sep in secret_name:
        print("Illegal secret name")
        return None
    return sep.join([MASTER_STORAGE,secret_name])

def receive_from_master(secret_name, secret_data, base64_encoded=False):
    """ Receive some secret data (encrypted) and save it. No need to decode it. (other than base64) """
    if base64_encoded:
        secret_data=base64.b64decode(secret_data)
    return writefile(minion_storage(secret_name), secret_data)

def _encrypt(pubfile,data, use_base64=False):
    if data is None:
        print("Data to encrypt is None")
        return False, None
    if pubfile is None:
        print("Pubfile for encryption is None")
        return False, None
    if not os.path.exists(pubfile):
        print("Pubfile does not exist")
        return False, None

    print("data to encode is:")
    pprint(data)
    try:
        command = ['openssl','rsautl','-encrypt','-inkey',pubfile,'-pubin']
        print("command is "+" ".join(command))
        encps = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        output, errs = encps.communicate(input=data)
        print("result len is {}".format(len(output)))
        print("result (base64 encoded) is " + base64.b64encode(output))
        if use_base64:
            output = base64.b64encode(output)

        return True, output
    except:
        traceback.print_exc()
        print("Encryption failed!")
        return False, None

def _decrypt(keyfile,infile):
    if keyfile is None:
        print("No keyfile")
        return False, None
    if infile is None:
        print("No infile")
        return False, None
    if not os.path.exists(keyfile):
        print("keyfile {} does not exist".format(keyfile))
        return False, None
    if not os.path.exists(infile):
        print("Infile {} does not exist".format(infile))
        return False, None

    command = ['openssl','rsautl','-decrypt','-inkey',keyfile,'-in',infile]
    print("command is "+" ".join(command))

    try:
        output = subprocess.check_output(command)
        #print("Decoded data is :{}".format(output))
        return True, output 
    except subprocess.CalledProcessError as ex:
        print("Decoding secret failed!")
        print("This can happen if the secret is too long (greater than the key length - 11 bits)")
        return False, None

def get_secret(secret_name,minion_id=None):
    success, result = _decrypt(minion_keypair(minion_id), minion_storage(secret_name))
    if not success:
        print("Decrypt failure")
        return None
    if not len(result):
        print("Empty result")
        return None
    return result

def get_master_secret(secret_name):
    """ For the master only """
    success, result = _decrypt(master_keypair(), master_storage(secret_name))
    if not success:
        print("Decrypt failure")
        return None
    if not len(result):
        print("Empty result")
        return None
    return result

def save_secret(secret_name, data):
    """ On master """
    path = master_storage(secret_name)
    success, encrypted = _encrypt(master_pub(), data, use_base64=False)
    if success:
        return writefile(path, encrypted)
    else:
        print("encryption failed, not writing")
        return False

def generatePassphrase(size=13,letters=None):
    if letters is None:
        import string
        valid = set(list(string.printable))
        invalid = set(list(string.whitespace+ "'\"$1l0O/(){}[]`\\"))
        letters = ''.join(valid - invalid)
    return ''.join([ random.choice(letters) for x in range(size)])

def generateToken(size=16):
    #a3random.ran
    u = str(uuid.uuid4())[0:size/2]
    p = generatePassphrase(size=size-size/2)
    return u+p

def check_or_generate(secret_name):
    """ generate a new secret on the master """
    if not os.path.exists(master_storage(secret_name)):
        newtoken = generateToken()
        save_secret(secret_name, newtoken)

def check_or_set(secret_name, newvalue):
    """ generate a new secret on the master """
    if not os.path.exists(master_storage(secret_name)):
        save_secret(secret_name, newvalue)

def test_master_storage(secret_name, data):
    save_secret(secret_name, data)
    result = get_master_secret(secret_name)
    assert data == result

def test_minion_storage(secret_name):
    success, result = encrypt_secret_for(secret_name,"__self__", use_base64=False)
    assert success
    print("Success encrypting for own minion")
    print("len of result = {}".format(len(result)))
    print("")
    receive_from_master(secret_name, result)
    print("Returning result")
    return result

def run_tests():
    secret_name='test1'
    secret_data=generateToken(16)
    print("Starting secret:")
    print(secret_data)
    minion_id='pxe-client1'
    test_master_storage(secret_name, secret_data)
    minion_stored = test_minion_storage(secret_name)
    assert len(minion_stored)
    minion_retrieved = get_secret(secret_name)
    print("minion retrieved:")
    pprint(minion_retrieved)
    print("secret data was:")
    pprint(secret_data)
    assert minion_retrieved == secret_data


if __name__ == "__main__":
    init_storage()
    run_tests()
