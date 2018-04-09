#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright 2017 Andrew Vaughan <hello@andrewvaughan.io>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""
ActionModule definition for the Ansible prompt action plugin.

.. moduleauthor:: Andrew Vaughan <hello@andrewvaughan.io>
"""

__metaclass__ = type

import re
import sys

from ansible.plugins.action import ActionBase


class ActionModule(ActionBase):
    """
    Prompts user with one-or-more messages and optionally waits for input for each.

    .. class:: ActionModule
    .. versionadded:: 0.1.0

    .. versionchanged:: 0.2.0
       Added user input prompting functionality.

    .. versionchanged:: 0.3.0
       Added newline, alignment, and formatting functionality.

    .. versionchanged:: 1.0.0
       Added field postfix, confirm, choices, and defaults.
    """

    TRANSFERS_FILES = False
    VALID_PARAMS = [
        'say', 'newline', 'align',
        'ask', 'postfix', 'default', 'trim', 'confirm'
    ]


    def __init__(self, task, connection, play_context, loader, templar, shared_loader_obj):
        """
        Initialize the prompt Ansible plugin.

        .. versionadded:: 0.1.0

        .. versionchanged:: 0.2.0
           Precompiled regular expressions for input variable validation.  Added input setting.

        .. function:: __init__(task, connection, play_context, loader, templar, shared_loader_obj)
        """
        super(ActionModule, self).__init__(task, connection, play_context, loader, templar, shared_loader_obj)

        self.setOutput(sys.stdout)
        self.setInput('/dev/tty')

        # Pre-compile our regex for checking valid variables
        self.rValidVariable = re.compile(r"^[A-Za-z0-9_]+$")


    def run(self, tmp=None, task_vars=None):
        """
        Perform the plugin task, prompting the user one or more times.

        :kwarg tmp: the temporary directory to use if creating files
        :kwarg task_vars: any variables associated with the task

        :returns: a dictionary of results from the module

        .. versionadded:: 0.1.0
        .. function:: run([tmp=None, task_vars=None])
        """
        task_vars = task_vars or dict()

        result = super(ActionModule, self).run(tmp, task_vars)
        args = self._task.args

        # Expect only the messages parameter
        if 'msg' not in args:
            return self._fail(result, "Required 'msg' parameter missing.")

        if len(args) != 1:
            return self._fail(result, "Expected single 'msg' parameter. Multiple parameters given.")

        return self._prompt(result, args['msg'])


    def setOutput(self, outstr=None):
        """
        Set the output stream to write to.

        :kwarg outstr: an output stream to write to (defaults to sys.stdout)

        .. versionadded:: 0.1.0
        .. function:: setOutput([outstr=None])
        """
        self._outstr = outstr or sys.stdout


    def setInput(self, instr=None):
        """
        Set the input stream to read from.

        :kwarg instr: an input stream to read from (defaults to '/dev/tty')

        .. versionadded:: 0.2.0
        .. function:: setInput([instr=None])
        """
        self._instr = instr or '/dev/tty'


    def _prompt(self, result, msg):
        """
        Prompts the user with a message and optionally asks for a response.

        :kwarg result: the base result dict to build on
        :kwarg msg: the message provided to parse (string, object, or list)

        :returns: an updated dict response with success or failure

        .. versionadded:: 0.1.0

        .. versionchanged:: 0.2.0
           Added user input prompting functionality.

        .. versionchanged:: 0.3.0
           Added newline, alignment, and formatting functionality.

        .. versionchanged:: 1.0.0
           Added postfix, confirm, choices, and defaults.

        .. function:: _prompt(result, msg)
        """
        if not isinstance(msg, list):
            msg = [msg]

        if len(msg) == 0:
            return self._fail(result, "No message provided")

        # Parse each item on the list
        for m in msg:

            if m is not None and not isinstance(m, (str, dict)):
                m = str(m)

            # If no message is provided, fail
            if m is None or len(m) == 0:
                return self._fail(result, "No message provided")

            # If a simple scalar value is provided, simply display it
            if not isinstance(m, dict):
                self._outstr.write("%s\n" % m)
                continue

            # If this is a set of key/value pairs, parse it
            for arg in m:
                if arg not in self.VALID_PARAMS:
                    return self._fail(result, "Unexpected parameter '%s'" % arg)

            # Determine postfix given newline settings
            postfix = "\n"
            if 'newline' in m and not m['newline']:
                postfix = ""

            # If this is a prompt, ask it as such
            if 'ask' in m:

                # Check for valid variable name
                if m['ask'] is None or str(m['ask']).strip() == "":
                    return self._fail(result, "Parameter 'ask' must provide variable name.  Empty received.")

                # Check for illegal ansible characters
                if not self.rValidVariable.search(m['ask']):
                    return self._fail(result, "Invalid character in 'ask' parameter '%s'.", m['ask'])

                # Check if any invalid parameters are provided
                if 'newline' in m and not m['newline']:
                    return self._fail(result, "Option 'newline' is not compatible with option 'ask'.")

                if 'align' in m and m['align'] != 'left':
                    return self._fail(result, "Option 'align' is not compatible with option 'ask'.")

                if 'confirm' in m and 'default' in m:
                    return self._fail(result, "Unexpected 'default' provided with confirmation question.")

                # If no say is provided, just make it blank
                if 'say' not in m:
                    m['say'] = ""

                # If no trim, default to true
                if 'trim' not in m:
                    m['trim'] = True

                # Default to input postfix, if not set
                if 'postfix' not in m:
                    m['postfix'] = "?"

                # Convert to terminal input temporarily
                oldin = sys.stdin

                # Repeat question until answered
                while True:
                    if isinstance(self._instr, str):
                        sys.stdin = open(self._instr)
                    else:
                        sys.stdin = self._instr

                    defaultString = ""

                    if 'confirm' in m:
                        if m['confirm']:
                            defaultString = " [Yn]"
                            m['default'] = "y"
                        else:
                            defaultString = " [yN]"
                            m['default'] = "n"

                    elif 'default' in m:
                        defaultString = " [%s]" % m['default']

                    # Present empty string if "say" not provided
                    askstr = "%s%s%s " % (
                        m['say'],
                        defaultString,
                        m['postfix']
                    )

                    var = raw_input(askstr)

                    if var != "":
                        if 'confirm' in m and var.lower() not in "yn":
                            continue

                        break

                    if 'default' in m:
                        var = m['default']
                        break

                # Revert to previous setting
                sys.stdin = oldin

                if 'ansible_facts' not in result:
                    result['ansible_facts'] = dict()

                # Trim whitespace if set
                if m['trim']:
                    var = var.strip()

                if 'confirm' in m:
                    var = (var.lower() == "y")

                result['ansible_facts'][m['ask']] = var

            # If it's just a message, print it
            elif 'say' in m:
                import subprocess

                if 'default' in m:
                    return self._fail(result, "Unexpected 'default' in non-question prompt.")

                if 'postfix' in m:
                    return self._fail(result, "Unexpected 'postfix' in non-question prompt.")

                if 'trim' in m:
                    return self._fail(result, "Unexpected 'trim' in non-question prompt.")

                if 'confirm' in m:
                    return self._fail(result, "Unexpected 'confirm' in non-question prompt.")

                if 'align' not in m:
                    m['align'] = 'left'

                output = m['say']

                if m['align'] == 'center':
                    rows, columns = subprocess.check_output(['stty', 'size']).decode().split()
                    output = "%s%s" % (output.center(int(columns) - len(postfix)), postfix)
                elif m['align'] == 'right':
                    rows, columns = subprocess.check_output(['stty', 'size']).decode().split()
                    output = "%s%s" % (output.rjust(int(columns) - len(postfix)), postfix)
                elif m['align'] == 'left':
                    output = "%s%s" % (output, postfix)
                else:
                    return self._fail(
                        result,
                        "Align '%s' invalid.  Expected 'left', 'center', or 'right'.",
                        m['align']
                    )

                self._outstr.write(output)

        return result


    def _fail(self, result, message, *args):
        """
        Raise an Ansible exception with a given message.

        :kwarg result: the base result object to build on
        :kwarg message: the message to pass to the Ansible exception
        :kwarg args: an arbitrary number of arguments to replace in the message's formatting

        :returns: an updated dict response with the provided failure condition

        .. versionadded:: 0.1.0
        .. function:: _fail(result, message, *args)
        """
        if not isinstance(result, dict):
            raise TypeError("Invalid result provided. Expected dict, received %s." % type(result))

        if not isinstance(message, (str, unicode)):
            raise TypeError("Invalid message provided. Expected string, received '%s'." % type(message))

        if message == "":
            raise ValueError("Empty message provided. Requires failure message.")

        result['failed'] = True
        result['msg'] = message % (args)

        return result