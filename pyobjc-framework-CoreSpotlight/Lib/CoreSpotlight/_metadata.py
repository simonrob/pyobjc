# This file is generated by objective.metadata
#
# Last update: Sun Jul 11 21:35:29 2021
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
constants = """$CSActionIdentifier$CSIndexErrorDomain$CSMailboxArchive$CSMailboxDrafts$CSMailboxInbox$CSMailboxJunk$CSMailboxSent$CSMailboxTrash$CSQueryContinuationActionType$CSSearchQueryErrorDomain$CSSearchQueryString$CSSearchableItemActionType$CSSearchableItemActivityIdentifier$CoreSpotlightVersionNumber@d$CoreSpotlightVersionString@*$"""
enums = """$CSIndexErrorCodeIndexUnavailableError@-1000$CSIndexErrorCodeIndexingUnsupported@-1005$CSIndexErrorCodeInvalidClientStateError@-1002$CSIndexErrorCodeInvalidItemError@-1001$CSIndexErrorCodeQuotaExceeded@-1004$CSIndexErrorCodeRemoteConnectionError@-1003$CSIndexErrorCodeUnknownError@-1$CSSearchQueryErrorCodeCancelled@-2003$CSSearchQueryErrorCodeIndexUnreachable@-2001$CSSearchQueryErrorCodeInvalidQuery@-2002$CSSearchQueryErrorCodeUnknown@-2000$CoreSpotlightAPIVersion@40$"""
misc.update({})
aliases = {"CS_TVOS_UNAVAILABLE": "__TVOS_PROHIBITED"}
r = objc.registerMetaDataForSelector
objc._updatingMetadata(True)
try:
    r(
        b"CSCustomAttributeKey",
        b"initWithKeyName:searchable:searchableByDefault:unique:multiValued:",
        {
            "arguments": {
                3: {"type": "Z"},
                4: {"type": "Z"},
                5: {"type": "Z"},
                6: {"type": "Z"},
            }
        },
    )
    r(b"CSCustomAttributeKey", b"isMultiValued", {"retval": {"type": "Z"}})
    r(b"CSCustomAttributeKey", b"isSearchable", {"retval": {"type": "Z"}})
    r(b"CSCustomAttributeKey", b"isSearchableByDefault", {"retval": {"type": "Z"}})
    r(b"CSCustomAttributeKey", b"isUnique", {"retval": {"type": "Z"}})
    r(b"CSCustomAttributeKey", b"setMultiValued:", {"arguments": {2: {"type": "Z"}}})
    r(b"CSCustomAttributeKey", b"setSearchable:", {"arguments": {2: {"type": "Z"}}})
    r(
        b"CSCustomAttributeKey",
        b"setSearchableByDefault:",
        {"arguments": {2: {"type": "Z"}}},
    )
    r(b"CSCustomAttributeKey", b"setUnique:", {"arguments": {2: {"type": "Z"}}})
    r(
        b"CSImportExtension",
        b"updateAttributes:forFileAtURL:error:",
        {
            "retval": {"type": "Z"},
            "arguments": {3: {"type_modifier": b"o"}, 4: {"type_modifier": b"o"}},
        },
    )
    r(
        b"CSSearchQuery",
        b"completionHandler",
        {
            "retval": {
                "callable": {
                    "retval": {"type": b"v"},
                    "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                }
            }
        },
    )
    r(
        b"CSSearchQuery",
        b"foundItemsHandler",
        {
            "retval": {
                "callable": {
                    "retval": {"type": b"v"},
                    "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                }
            }
        },
    )
    r(b"CSSearchQuery", b"isCancelled", {"retval": {"type": "Z"}})
    r(
        b"CSSearchQuery",
        b"setCompletionHandler:",
        {
            "arguments": {
                2: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(
        b"CSSearchQuery",
        b"setFoundItemsHandler:",
        {
            "arguments": {
                2: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(
        b"CSSearchableIndex",
        b"deleteAllSearchableItemsWithCompletionHandler:",
        {
            "arguments": {
                2: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(
        b"CSSearchableIndex",
        b"deleteSearchableItemsWithDomainIdentifiers:completionHandler:",
        {
            "arguments": {
                3: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(
        b"CSSearchableIndex",
        b"deleteSearchableItemsWithIdentifiers:completionHandler:",
        {
            "arguments": {
                3: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(
        b"CSSearchableIndex",
        b"endIndexBatchWithClientState:completionHandler:",
        {
            "arguments": {
                3: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(
        b"CSSearchableIndex",
        b"fetchLastClientStateWithCompletionHandler:",
        {
            "arguments": {
                2: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {
                            0: {"type": b"^v"},
                            1: {"type": b"@"},
                            2: {"type": b"@"},
                        },
                    }
                }
            }
        },
    )
    r(
        b"CSSearchableIndex",
        b"indexSearchableItems:completionHandler:",
        {
            "arguments": {
                3: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}, 1: {"type": b"@"}},
                    }
                }
            }
        },
    )
    r(b"CSSearchableIndex", b"isIndexingAvailable", {"retval": {"type": b"Z"}})
    r(
        b"NSObject",
        b"dataForSearchableIndex:itemIdentifier:typeIdentifier:error:",
        {
            "required": False,
            "retval": {"type": b"@"},
            "arguments": {
                2: {"type": b"@"},
                3: {"type": b"@"},
                4: {"type": b"@"},
                5: {"type": "^@", "type_modifier": b"o"},
            },
        },
    )
    r(
        b"NSObject",
        b"fileURLForSearchableIndex:itemIdentifier:typeIdentifier:inPlace:error:",
        {
            "required": False,
            "retval": {"type": b"@"},
            "arguments": {
                2: {"type": b"@"},
                3: {"type": b"@"},
                4: {"type": b"@"},
                5: {"type": "Z"},
                6: {"type": "^@", "type_modifier": b"o"},
            },
        },
    )
    r(
        b"NSObject",
        b"searchableIndex:reindexAllSearchableItemsWithAcknowledgementHandler:",
        {
            "required": True,
            "retval": {"type": b"v"},
            "arguments": {
                2: {"type": b"@"},
                3: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}},
                    },
                    "type": "@?",
                },
            },
        },
    )
    r(
        b"NSObject",
        b"searchableIndex:reindexSearchableItemsWithIdentifiers:acknowledgementHandler:",
        {
            "required": True,
            "retval": {"type": b"v"},
            "arguments": {
                2: {"type": b"@"},
                3: {"type": b"@"},
                4: {
                    "callable": {
                        "retval": {"type": b"v"},
                        "arguments": {0: {"type": b"^v"}},
                    },
                    "type": "@?",
                },
            },
        },
    )
    r(
        b"NSObject",
        b"searchableIndexDidFinishThrottle:",
        {"required": False, "retval": {"type": b"v"}, "arguments": {2: {"type": b"@"}}},
    )
    r(
        b"NSObject",
        b"searchableIndexDidThrottle:",
        {"required": False, "retval": {"type": b"v"}, "arguments": {2: {"type": b"@"}}},
    )
finally:
    objc._updatingMetadata(False)
expressions = {}

# END OF FILE
