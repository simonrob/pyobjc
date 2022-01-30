# This file is generated by objective.metadata
#
# Last update: Sun Jul 11 21:41:26 2021
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
constants = """$$"""
enums = """$$"""
misc.update({})
r = objc.registerMetaDataForSelector
objc._updatingMetadata(True)
try:
    r(
        b"NSMailDelivery",
        b"deliverMessage:headers:format:protocol:",
        {"retval": {"type": "Z"}},
    )
    r(b"NSMailDelivery", b"deliverMessage:subject:to:", {"retval": {"type": "Z"}})
    r(b"NSMailDelivery", b"hasDeliveryClassBeenConfigured", {"retval": {"type": "Z"}})
finally:
    objc._updatingMetadata(False)
expressions = {}

# END OF FILE
