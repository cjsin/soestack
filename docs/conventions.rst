.. _docs_conventions:

###########
Conventions
###########

The following conventions are used within this documentation.

Code blocks showing commands which may need to be executed with some sort of elevated privileges (such as, by the ``root`` user), are displayed with the ``#>`` prefix, for example:

.. code-block:: console

    #> example-root-command

Code blocks showing commands which can probably be executed with regular user privileges are displayed with the ``$>`` prefix, for example:

.. code-block:: console

    $> example-regular-user-command

Commentary within a code block may be displayed with a **\#\#** prefix, for example:

.. code-block:: console

    $> this-is-a-command
    ## this is some commentary about the command,
    ## for example this might be used to inform you that you'll need to type something.
    ## Or it might be used to indicate a step that can be skipped in some situations.
    This is some example output from the command 

In code blocks that show example output, the token ``<snip>`` may be used to indicate that some text was cut out for brevity:

.. code-block:: console 

    $> a-command-that-produces-a-lot-of-output
    some example relevant output
    <snip>
    more example relevant output
