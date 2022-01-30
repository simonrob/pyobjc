# This file is generated by objective.metadata
#
# Last update: Sun Jul 11 21:37:16 2021
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
constants = """$NSStackTraceKey$NSUncaughtRuntimeErrorException$NSUncaughtSystemExceptionException$"""
enums = """$NSHandleOtherExceptionMask@512$NSHandleTopLevelExceptionMask@128$NSHandleUncaughtExceptionMask@2$NSHandleUncaughtRuntimeErrorMask@32$NSHandleUncaughtSystemExceptionMask@8$NSHangOnOtherExceptionMask@16$NSHangOnTopLevelExceptionMask@8$NSHangOnUncaughtExceptionMask@1$NSHangOnUncaughtRuntimeErrorMask@4$NSHangOnUncaughtSystemExceptionMask@2$NSLogOtherExceptionMask@256$NSLogTopLevelExceptionMask@64$NSLogUncaughtExceptionMask@1$NSLogUncaughtRuntimeErrorMask@16$NSLogUncaughtSystemExceptionMask@4$"""
misc.update({})
functions = {"NSExceptionHandlerResume": (b"v",)}
r = objc.registerMetaDataForSelector
objc._updatingMetadata(True)
try:
    r(
        b"NSObject",
        b"exceptionHandler:shouldHandleException:mask:",
        {
            "retval": {"type": "Z"},
            "arguments": {2: {"type": b"@"}, 3: {"type": b"@"}, 4: {"type": b"Q"}},
        },
    )
    r(
        b"NSObject",
        b"exceptionHandler:shouldLogException:mask:",
        {
            "retval": {"type": "Z"},
            "arguments": {2: {"type": b"@"}, 3: {"type": b"@"}, 4: {"type": b"Q"}},
        },
    )
finally:
    objc._updatingMetadata(False)
protocols = {
    "NSExceptionHandlerDelegate": objc.informal_protocol(
        "NSExceptionHandlerDelegate",
        [
            objc.selector(
                None,
                b"exceptionHandler:shouldLogException:mask:",
                b"Z@:@@Q",
                isRequired=False,
            ),
            objc.selector(
                None,
                b"exceptionHandler:shouldHandleException:mask:",
                b"Z@:@@Q",
                isRequired=False,
            ),
        ],
    )
}
expressions = {
    "NSHangOnEveryExceptionMask": "(NSHangOnUncaughtExceptionMask|NSHangOnUncaughtSystemExceptionMask|NSHangOnUncaughtRuntimeErrorMask|NSHangOnTopLevelExceptionMask|NSHangOnOtherExceptionMask)",
    "NSLogAndHandleEveryExceptionMask": "(NSLogUncaughtExceptionMask|NSLogUncaughtSystemExceptionMask|NSLogUncaughtRuntimeErrorMask|NSHandleUncaughtExceptionMask|NSHandleUncaughtSystemExceptionMask|NSHandleUncaughtRuntimeErrorMask|NSLogTopLevelExceptionMask|NSHandleTopLevelExceptionMask|NSLogOtherExceptionMask|NSHandleOtherExceptionMask)",
}

# END OF FILE
