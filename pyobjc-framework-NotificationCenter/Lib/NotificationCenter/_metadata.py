# This file is generated by objective.metadata
#
# Last update: Sun Jul 11 21:43:31 2021
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
enums = """$NCUpdateResultFailed@2$NCUpdateResultNewData@0$NCUpdateResultNoData@1$"""
misc.update({})
r = objc.registerMetaDataForSelector
objc._updatingMetadata(True)
try:
    r(b"NCWidgetController", b"defaultWidgetController", {"deprecated": 1010})
    r(
        b"NCWidgetController",
        b"setHasContent:forWidgetWithBundleIdentifier:",
        {"arguments": {2: {"type": "Z"}}},
    )
    r(b"NCWidgetListViewController", b"editing", {"retval": {"type": "Z"}})
    r(b"NCWidgetListViewController", b"hasDividerLines", {"retval": {"type": "Z"}})
    r(b"NCWidgetListViewController", b"setEditing:", {"arguments": {2: {"type": "Z"}}})
    r(
        b"NCWidgetListViewController",
        b"setHasDividerLines:",
        {"arguments": {2: {"type": "Z"}}},
    )
    r(
        b"NCWidgetListViewController",
        b"setShowsAddButtonWhenEditing:",
        {"arguments": {2: {"type": "Z"}}},
    )
    r(
        b"NCWidgetListViewController",
        b"showsAddButtonWhenEditing",
        {"retval": {"type": "Z"}},
    )
    r(
        b"NCWidgetListViewController",
        b"viewControllerAtRow:makeIfNecessary:",
        {"arguments": {3: {"type": "Z"}}},
    )
    r(b"NSObject", b"widgetAllowsEditing", {"required": False, "retval": {"type": "Z"}})
    r(
        b"NSObject",
        b"widgetDidBeginEditing",
        {"required": False, "retval": {"type": b"v"}},
    )
    r(
        b"NSObject",
        b"widgetDidEndEditing",
        {"required": False, "retval": {"type": b"v"}},
    )
    r(
        b"NSObject",
        b"widgetList:didRemoveRow:",
        {
            "required": False,
            "retval": {"type": b"v"},
            "arguments": {2: {"type": b"@"}, 3: {"type": "Q"}},
        },
    )
    r(
        b"NSObject",
        b"widgetList:didReorderRow:toRow:",
        {
            "required": False,
            "retval": {"type": b"v"},
            "arguments": {2: {"type": b"@"}, 3: {"type": "Q"}, 4: {"type": "Q"}},
        },
    )
    r(
        b"NSObject",
        b"widgetList:shouldRemoveRow:",
        {
            "required": False,
            "retval": {"type": "Z"},
            "arguments": {2: {"type": b"@"}, 3: {"type": "Q"}},
        },
    )
    r(
        b"NSObject",
        b"widgetList:shouldReorderRow:",
        {
            "required": False,
            "retval": {"type": "Z"},
            "arguments": {2: {"type": b"@"}, 3: {"type": "Q"}},
        },
    )
    r(
        b"NSObject",
        b"widgetList:viewControllerForRow:",
        {
            "required": True,
            "retval": {"type": b"@"},
            "arguments": {2: {"type": b"@"}, 3: {"type": "Q"}},
        },
    )
    r(
        b"NSObject",
        b"widgetListPerformAddAction:",
        {"required": False, "retval": {"type": b"v"}, "arguments": {2: {"type": b"@"}}},
    )
    r(
        b"NSObject",
        b"widgetMarginInsetsForProposedMarginInsets:",
        {
            "required": False,
            "retval": {"type": "{NSEdgeInsets=dddd}"},
            "arguments": {2: {"type": "{NSEdgeInsets=dddd}"}},
        },
    )
    r(
        b"NSObject",
        b"widgetPerformUpdateWithCompletionHandler:",
        {
            "required": False,
            "retval": {"type": b"v"},
            "arguments": {
                2: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {
                            0: {"type": b"^v"},
                            1: {"type": sel32or64(b"I", b"Q")},
                        },
                    },
                    "type": "@?",
                }
            },
        },
    )
    r(
        b"NSObject",
        b"widgetSearch:resultSelected:",
        {
            "required": True,
            "retval": {"type": b"v"},
            "arguments": {2: {"type": b"@"}, 3: {"type": b"@"}},
        },
    )
    r(
        b"NSObject",
        b"widgetSearch:searchForTerm:maxResults:",
        {
            "required": True,
            "retval": {"type": b"v"},
            "arguments": {
                2: {"type": b"@"},
                3: {"type": b"@"},
                4: {"type": sel32or64(b"I", b"Q")},
            },
        },
    )
    r(
        b"NSObject",
        b"widgetSearchTermCleared:",
        {"required": True, "retval": {"type": b"v"}, "arguments": {2: {"type": b"@"}}},
    )
finally:
    objc._updatingMetadata(False)
expressions = {}

# END OF FILE
