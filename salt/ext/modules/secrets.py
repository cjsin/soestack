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
from __future__ import print_function
from __future__ import division
from __future__ import unicode_literals 
#from builtins import bytes, chr
import uuid

from os.path import sep, pathsep
import traceback
import subprocess
import logging
import os
import base64
import random
#import six
from pprint import pprint, pformat

__virtualname__ = 'secrets'

__outputter__ = {
    'run': 'txt'
}

SALT_PKI = '/etc/salt/pki'
STORAGE  = os.path.sep.join(['/etc','salt','secrets'])
MINION_STORAGE = os.path.sep.join([STORAGE,'minion'])
MASTER_STORAGE = os.path.sep.join([STORAGE,'master'])

log = logging.getLogger(__name__)

# The api will be created during __init__ or __main__
api = None 

def init_storage():
    """ Create the storage directories with appropriate permissions """
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

class Generator:
    def generatePassphrase(self, size=13,letters=None):
        """
        Generate a random token which is mostly suitable for a human to type.
        Note that there are length limits due to the openssl implementation
        """
        if letters is None:
            import string
            valid = set(list(string.printable))
            invalid = set(list(string.whitespace+ "'\"$1l0O/(){}[]`\\"))
            letters = ''.join(valid - invalid)
        return ''.join([ random.choice(letters) for x in range(size)])

    def generateToken(self, size=16):
        """ 
        Generate a random token of the specified length.
        Note that there are length limits due to the openssl implementation.
        """
        u = str(uuid.uuid4())
        halfway = int(size//2)
        u = u[0:halfway]
        p = self.generatePassphrase(size=size-halfway)
        return u+p

def error_tuple(message):
    log.error(message)
    return False, message

def nochange_tuple(message):
    return None, message

def success_tuple(message_or_data):
    return True, message_or_data

def write_file(path, data):
    """ 
    Write some data to a file and return a status tuple
    """
    if path is None:
        return error_tuple("No path specified")
    if data is None:
        return error_tuple("No data to write (nil)")
    try:
        with open(path, 'w') as f:
            f.write(data)
            return success_tuple("Written successfully")
    except:
        traceback.print_exc()
        return error_tuple("salt secrets write_file exception")

def read_file(path):
    """ 
    Read data from a file and return a status tuple 
    """
    if path is None:
        return error_tuple("No path was specified")
    try:
        with open(path, 'r') as f:
            encoded = f.read()
            return success_tuple(encoded)
    except:
        traceback.print_exc()
        return error_tuple("An error occurred while reading the file")

class Crypto:
    def decrypt(self, keyfile, infile):
        """ 
        Decrypt a secret in a file, using a specified keyfile.
        Return a tuple consisting of either True, and the plaintext, or False, and the error message
        """
        if keyfile is None:
            return error_tuple("No keyfile")
        if infile is None:
            return error_tuple("No infile")
        if not os.path.exists(keyfile):
            return error_tuple("Key file '{}' does not exist".format(keyfile))
        if not os.path.exists(infile):
            traceback.print_stack()
            return error_tuple("Input file '{}' does not exist".format(infile))

        command = ['openssl', 'rsautl', '-decrypt', '-inkey', keyfile, '-in', infile]
        log.debug("command is "+" ".join(command))

        try:
            output = subprocess.check_output(command)
            return success_tuple(output)
        except subprocess.CalledProcessError as ex:
            return error_tuple("Decoding secret failed!. This can happen if the secret is too long (greater than the key length - 11 bits)")

    def encrypt(self, pubfile, data, use_base64=False):
        """ 
        encrypt a secret specified by param 'data', using the specified public key file, optionally storing it with base64 encoding 
        Return a tuple consisting of either True, and the encoded data, or False, and the error message
        """
        if data is None:
            return error_tuple("Data to encrypt is None")
        if pubfile is None:
            return error_tuple("Pubfile for encryption is None")
        if not os.path.exists(pubfile):
            return error_tuple("Pubfile '{}' does not exist".format(pubfile))

        try:
            command = ['openssl', 'rsautl', '-encrypt', '-inkey', pubfile, '-pubin']
            log.debug("command is "+" ".join(command))
            encps = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
            output, errs = encps.communicate(input=data)#.encode('latin-1'))
            #output = output.decode('latin-1')
            if use_base64:
                output = base64.b64encode(output)

            return success_tuple(output)
        except:
            traceback.print_exc()
            return error_tuple("Encryption failed!")

class Storage:
    def __init__(self, storage_dir, keydir, recipients = None, privkey=None, pubkey=None, base64_storage=False):
        self.storage_dir = storage_dir
        self.keydir = keydir
        self.recipients = recipients
        self.base64_storage = base64_storage
        keydir_name = os.path.basename(keydir)

        if privkey is None:
            privkey = keydir_name+'.pem'
        if pubkey is None:
            pubkey = keydir_name+'.pub'

        self.privkey = os.path.join(keydir, privkey)
        self.pubkey = os.path.join(keydir, pubkey)
        self.crypto = Crypto()
    
    def recipient_pub(self, minion_id):
        if not self.recipients:
            return None
        f = os.path.join(self.recipients, minion_id)
        if os.path.exists(f):
            return f
        else:
            return None

    def keypair(self):
        """
        Return the private keypair for this storage area (for decrypting)
        """
        return self.privkey

    def pub(self):
        """
        Return the public key for this storage area (for encrypting)
        """
        return self.pubkey

    def _secret_file(self, secret_name):
        """
        Return the path for storage of the specified secret name.
        The secret name must not include the os path separator
        """
        if os.path.sep in secret_name:
            traceback.print_stack()
            log.error("Illegal secret name '{}'".format(secret_name))
            return None
        return os.path.join(self.storage_dir, secret_name)

    def read(self, secret_name):
        """
        Read the data from within the storage file for a specified secret
        """
        success, contents = read_file(self._secret_file(secret_name))
        if self.base64_storage:
            try:
                contents=base64.b64decode(encrypted)
                return success_tuple(contents)
            except:
                return error_tuple("Could not decode the message as base64 for secret '{}".format(secret_name))
        return success_tuple(contents)

    def write(self, secret_name, data):
        """
        Write some data to the storage file for a specified secret
        """
        if self.base64_storage:
            try:
                data=base64.b64encode(data)
            except:
                return error_tuple("Could not encode the message as base64 for secret '{}'".format(secret_name))
        return write_file(self._secret_file(secret_name), data)

    def get_plaintext(self, secret_name):
        """
        Decode the data from the storage file for a specified secret.
        """
        f = self._secret_file(secret_name)
        if os.path.exists(f):
            return self.crypto.decrypt(self.privkey, f)
        else:
            return error_tuple("The secret '{}' does not yet exist.".format(secret_name))
    
    def exists(self, secret_name):
        """ 
        Return the storage path of an existing secret, if it exists, otherwise None 
        """
        f = self._secret_file(secret_name)
        if os.path.exists(f):
            return f
        else:
            return None

    def get_encrypted(self, secret_name):
        """
        Return the still-encypted data from the storage file for a specified secret.
        """
        return self.read(secret_name)

    def receive_plaintext(self, secret_name, plaintext):
        """ 
        A
        Return a tuple containing the status and a message.
        The status will be None if the file was not written due to being up to date.
        Otherwise it will be True/False depending on the success/failure.
        The second component of the tuple will be a message
        """
        success, old_plaintext = self.get_plaintext(secret_name)
        if success and plaintext == old_plaintext:
            return nochange_tuple("The data was up-to-date.")
        else:
            return self.save_plaintext(secret_name, plaintext)

    def save_plaintext(self, secret_name, plaintext):
        success, encrypted_or_error = self.crypto.encrypt(self.pub(), plaintext)
        if success:
            return self.write(secret_name, encrypted_or_error)
        else:
            return error_tuple("encryption failed, not writing secret '{}'. ".format(secret_name)+encrypted_or_error)

    def delete(self, secret_name):
        """
        Delete the storage file for a specified secret, if it exists
        """
        f = self._secret_file(secret_name)
        if os.path.exists(f):
            os.remove(f)

    def check_changed(self, secret_name, encrypted):
        """ 
        Check if a secret file will need to be updated with new data.
        This is a process of decrypting the new data and the old 
        data and comparing whether it has changed.
        """
        existing, old_plaintext = self.get_plaintext(secret_name)
        if not existing:
            return success_tuple("The secret '{}' does not exist yet.".format(secret_name))

        temp_name = secret_name + ".tmp"
        written, status = self.write(temp_name, encrypted)
        if not written:
            self.delete(temp_name)
            return error_tuple(status+"\nPermission or space issue - cannot save file.")

        loaded, checkvalue = self.get_plaintext(temp_name)
        if not loaded:
            self.delete(temp_name)
            return error_tuple("Refusing to save encrypted data that we cannot decode.")
        
        self.delete(temp_name)

        if checkvalue == old_plaintext:
            return nochange_tuple("The data was up-to-date.")
        else:
            return success_tuple("The data needs to be updated")

    def receive_encrypted(self, secret_name, encrypted, base64_encoded=False):
        """ 
        Receive some encrypted data and save it in a specified secret name.
        Return None if the file is already up-to-date, otherwise, return the status of writing the file.
        """
        if base64_encoded:
            try:
                encrypted=base64.b64decode(encrypted)
            except:
                return error_tuple("Could not decode the message as base64 for secret {}".format(secret_name))

        status, message = self.check_changed(secret_name, encrypted)

        if status is None:
            return nochange_tuple(message)
        elif not status:
            return error_tuple(message)
        else:
            return self.write(secret_name, encrypted)

class SaltApi:
    def __init__(self, minion_id):
        self.myself = minion_id
        self.crypto = Crypto()
        self.generator = Generator()
        self.master = Storage(MASTER_STORAGE, os.path.join(SALT_PKI, 'master'), os.path.join(SALT_PKI,'master','minions'))
        self.minion = Storage(MINION_STORAGE, os.path.join(SALT_PKI, 'minion'))

    def master_save_secret(self, secret_name, data):
        return self.master.save_plaintext(secret_name, data)

    def master_encrypt_for(self, secret_name, minion_id, use_base64=False):
        """
        Api for the master to encrypt the data from an existing secret, for a specified recipient that must be known to the sender.
        On the master, return the contents of a secret file re-encrypted with a specified minion's public key. 
        Requires to run on the master (which has the public keys of the minions)
        """

        recipient_pubkey = None

        if minion_id == self.myself or minion_id == "__self__":
            recipient_pubkey = self.minion.pub()
        else:
            recipient_pubkey = self.master.recipient_pub(minion_id)

        if not recipient_pubkey:
            return error_tuple("Cannot encrypt for recipient '{}".format(minion_id))

        success, plaintext = self.master.get_plaintext(secret_name)
        if not success:
            return error_tuple("Could not access secret '{}' in order to send to '{}'".format(secret_name, minion_id))
        
        success, encrypted_or_message = self.crypto.encrypt(recipient_pubkey, plaintext, use_base64=use_base64)
        if not success:
            return error_tuple("Failed encrypting data. Perhaps it is too long. " + encrypted_or_message)
        
        return success_tuple(encrypted_or_message)

    def master_check_or_generate(self, secret_name):
        """ 
        generate a new secret on the master, in master storage
        """
        if not self.master.exists(secret_name):
            newtoken = self.generator.generateToken()
            return self.master.save_plaintext(secret_name, newtoken)
        else:
            return self.master.get_plaintext(secret_name)

    def master_get_secret(self, secret_name):
        """
        Api for the master only, to get the decoded form of an existing secret
        """
        return self.master.get_plaintext(secret_name)

    def minion_receive_from_master(self, secret_name, ciphertext, base64_encoded=False):
        """ 
        Api for minions to receive data sent by the master (possibly in base64) and store it locally.
        Receive some secret data (encrypted) and save it. 
        No need to decode it now (other than base64)  (though could do that to check / display any error)
        """
        # Because this secret is being received from the master, the master
        # will have encrypted it with our minion public key
        return self.minion.receive_encrypted(secret_name, ciphertext, base64_encoded=base64_encoded)

    def minion_get_secret(self, secret_name):
        return self.minion.get_plaintext(secret_name)

    def minion_delete_secret(self, secret_name):
        return self.minion.delete(secret_name)

    def master_delete_secret(self, secret_name):
        return self.master.delete(secret_name)

    def master_check_or_set(self, secret_name, plaintext):
        """ 
        save a new secret on the master, in master storage, if it doesn't exist already with the same value
        """
        return self.master.receive_plaintext(secret_name, plaintext)

def test_master_storage(secret_name, data):
    success, result1 = print_tuple(*api.master_save_secret(secret_name, data))
    assert success
    success, result2 = print_tuple(*api.master_get_secret(secret_name))
    assert success
    assert data == result2
    return result2

def print_tuple(*kwds):
    x,y = kwds
    print("{}, {}".format(*kwds))
    return x,y

def test_minion_storage(secret_name, b64):
    success, result1 = print_tuple(*api.master_encrypt_for(secret_name,"__self__", use_base64=b64))
    assert success
    success, result2 = print_tuple(*api.minion_receive_from_master(secret_name, result1, b64))
    assert success
    return result2


def run_tests():
    gen = Generator()
    secret_name='test1'
    secret_data=gen.generateToken(16)

    print("Starting secret:")
    print(secret_data)

    test_master_storage(secret_name, secret_data)
    minion_stored = test_minion_storage(secret_name,True)
    assert len(minion_stored)

    retrieve_status, minion_retrieved = api.minion_get_secret(secret_name)
    assert retrieve_status

    print("minion retrieved:")
    pprint(minion_retrieved)
    print("secret data was:")
    pprint(secret_data)
    assert minion_retrieved == secret_data
    print("Cleanup secret {}".format(secret_name))
    api.minion_delete_secret(secret_name)
    api.master_delete_secret(secret_name)


####
# Functions for accessing the api. These will be exported by salt
# when it loads the module such that states/pillars may access these routines.
####

def minion_receive_from_master(secret_name, data, base64_encoded=True):
    return api.minion_receive_from_master(secret_name, data, base64_encoded=base64_encoded)

def master_get_secret(secret_name):
    return api.master_get_secret(secret_name)

def master_encrypt_for(secret_name, minion_id, use_base64=True):
    return api.master_encrypt_for(secret_name, minion_id, use_base64=use_base64)

def master_check_or_generate(secret_name):
    return api.master_check_or_generate(secret_name)

def master_check_or_set(secret_name, newvalue):
    return api.master_check_or_set(secret_name, newvalue)
    

####
# Initialise the module (for salt)
####
def __init__(opts):
    global api
    init_storage()
    api = SaltApi('infra') # TODO - get minion ID from salt

####
# Initialise the module (for main / script mode)
####
def main():
    global api
    init_storage()
    logging.basicConfig()
    api = SaltApi('infra')
    run_tests()

####
# For now, just run tests when invoked as a script
####
if __name__ == "__main__":
    main()







#     def get_master_secret(secret_name):
#         """ Decrypt a secret saved in master storage only, for running on the master only"""
#         success, result = _decrypt(master_keypair(), master_storage(secret_name))
#         if not success:
#             return error_tuple("Decrypt failure. "+result)
#         if not len(result):
#             return error_tuple("Empty result")
#         return success_tuple(result)

#     def save_plaintext(secret_name, ):
#         """ On master """
#         path = master_storage(secret_name)
#         success, encrypted = crypto.encrypt(self.pub(), data, use_base64=False)
#         if success:
#             return write_file(path, encrypted)
#         else:
#             return error_tuple("encryption failed, not writing.")

#     def check_or_generate(secret_name):
#         if not os.path.exists(self._secret_file(secret_name))
#             newtoken = self.generator.generateToken()
#             self.save_secret(secret_name, newtoken)

#     def check_or_set(secret_name, newvalue):
#         """ save a new secret on the master, in master storage, if it doesn't exist already with the same value"""
#         if not os.path.exists(master_storage(secret_name)):
#             save_secret(secret_name, newvalue)
#         else:
#             current_contents_plaintext = decrypt_secret_with(secret_name, master_keypair())
#             if current_contents_plaintext != newvalue:
#                 save_secret(secret_name, newvalue)


# def get_secret(secret_name,minion_id=None):
#     """ Decrypt a secret saved in minion storage """
#     success, result = _decrypt(minion_keypair(minion_id), minion_storage(secret_name))
#     if not success:
#         log.error("Decrypt failure")
#         return None
#     if not len(result):
#         log.warning("Empty result")
#         return None
#     return result

# def get_master_secret(secret_name):
#     """ Decrypt a secret saved in master storage only, for running on the master only"""
#     success, result = _decrypt(master_keypair(), master_storage(secret_name))
#     if not success:
#         log.error("Decrypt failure")
#         return None
#     if not len(result):
#         log.warning("Empty result")
#         return None
#     return result

# def save_secret(secret_name, data):
#     """ On master """
#     path = master_storage(secret_name)
#     success, encrypted = _encrypt(master_pub(), data, use_base64=False)
#     if success:
#         return write_file(path, encrypted)
#     else:
#         log.error("encryption failed, not writing")
#         return False

# def check_or_generate(secret_name):
#     """ generate a new secret on the master, in master storage"""
#     if not os.path.exists(master_storage(secret_name)):
#         newtoken = generateToken()
#         save_secret(secret_name, newtoken)

# def check_or_set(secret_name, newvalue):
#     """ save a new secret on the master, in master storage, if it doesn't exist already with the same value"""
#     if not os.path.exists(master_storage(secret_name)):
#         save_secret(secret_name, newvalue)
#     else:
#         current_contents_plaintext = decrypt_secret_with(secret_name, master_keypair())
#         if current_contents_plaintext != newvalue:
#             save_secret(secret_name, newvalue)
