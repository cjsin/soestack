#######################################
Steps to do before generating USB stick
#######################################

.. _modifying default passwords:

Modifying default passwords
---------------------------

.. _root_passwords:

- Generate an encrypted root password with:

    . code-block:: console

        > openssl passwd -1

.. _grub_passwords:

- Generate a grub password with:

    .. code-block:: console

        > grub2-mkpasswd-pbkdf2

- Pass these as ss.ROOT_PW and ss.GRUB_PW on the kernel boot commandline (set in bundler-usb.properties), or alternatively, update the FALLBACK_xxx_PASSWORD variables in the file ``password-fallbacks.sh``

- See ``provision/usb/README.rst`` for further info.

