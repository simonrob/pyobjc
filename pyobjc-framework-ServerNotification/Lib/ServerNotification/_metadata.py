# This file is generated by objective.metadata
#
# Last update: Sun Feb 20 19:22:01 2022
#
# flake8: noqa

import objc, sys
from typing import NewType

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
constants = """$$"""
enums = """$$"""
misc.update({})
misc.update({})
r = objc.registerMetaDataForSelector
objc._updatingMetadata(True)
try:
    r(
        b"NSServerNotificationCenter",
        b"addObserver:selector:name:object:",
        {"arguments": {3: {"type": ":", "sel_of_type": b"v@:@"}}},
    )
finally:
    objc._updatingMetadata(False)
expressions = {}

# END OF FILE
