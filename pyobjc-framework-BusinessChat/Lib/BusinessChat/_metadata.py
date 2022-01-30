# This file is generated by objective.metadata
#
# Last update: Sun Jul 11 21:23:49 2021
#
# flake8: noqa

import objc, sys

if sys.maxsize > 2**32:

    def sel32or64(a, b):
        return b

else:

    def sel32or64(a, b):
        return a


if objc.arch == "arm64":

    def selAorI(a, b):
        return a

else:

    def selAorI(a, b):
        return b


misc = {}
constants = """$BCParameterNameBody$BCParameterNameGroup$BCParameterNameIntent$"""
enums = """$BCChatButtonStyleDark@1$BCChatButtonStyleLight@0$"""
misc.update({})
expressions = {}

# END OF FILE
