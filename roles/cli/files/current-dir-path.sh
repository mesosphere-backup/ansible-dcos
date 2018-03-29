#!/bin/sh --this-shebang-is-just-here-to-inform-shellcheck--

# Expand $PATH to include the executable binaries in current working directory.
if [ "${PATH#.*}" = "${PATH}" ]; then
    PATH=.:$PATH
fi