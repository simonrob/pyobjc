# This file is generated by objective.metadata
#
# Last update: Sun Jul 11 21:42:09 2021
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
constants = """$MTKModelErrorDomain$MTKModelErrorKey$MTKTextureLoaderCubeLayoutVertical$MTKTextureLoaderErrorDomain$MTKTextureLoaderErrorKey$MTKTextureLoaderOptionAllocateMipmaps$MTKTextureLoaderOptionCubeLayout$MTKTextureLoaderOptionGenerateMipmaps$MTKTextureLoaderOptionOrigin$MTKTextureLoaderOptionSRGB$MTKTextureLoaderOptionTextureCPUCacheMode$MTKTextureLoaderOptionTextureStorageMode$MTKTextureLoaderOptionTextureUsage$MTKTextureLoaderOriginBottomLeft$MTKTextureLoaderOriginFlippedVertically$MTKTextureLoaderOriginTopLeft$"""
enums = """$$"""
misc.update({})
functions = {
    "MTKModelIOVertexFormatFromMetal": (b"QQ",),
    "MTKMetalVertexDescriptorFromModelIOWithError": (
        b"@@^@",
        "",
        {"arguments": {1: {"type_modifier": "o"}}},
    ),
    "MTKMetalVertexDescriptorFromModelIO": (b"@@",),
    "MTKModelIOVertexDescriptorFromMetalWithError": (
        b"@@^@",
        "",
        {"arguments": {1: {"type_modifier": "o"}}},
    ),
    "MTKModelIOVertexDescriptorFromMetal": (b"@@",),
    "MTKMetalVertexFormatFromModelIO": (b"QQ",),
}
r = objc.registerMetaDataForSelector
objc._updatingMetadata(True)
try:
    r(
        b"MTKMesh",
        b"initWithMesh:device:error:",
        {"arguments": {4: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKMesh",
        b"newMeshesFromAsset:device:sourceMeshes:error:",
        {"arguments": {5: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTextureWithCGImage:options:completionHandler:",
        {
            "arguments": {
                4: {
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
        b"MTKTextureLoader",
        b"newTextureWithCGImage:options:error:",
        {"arguments": {4: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTextureWithContentsOfURL:options:completionHandler:",
        {
            "arguments": {
                4: {
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
        b"MTKTextureLoader",
        b"newTextureWithContentsOfURL:options:error:",
        {"arguments": {4: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTextureWithData:options:completionHandler:",
        {
            "arguments": {
                4: {
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
        b"MTKTextureLoader",
        b"newTextureWithData:options:error:",
        {"arguments": {4: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTextureWithMDLTexture:options:completionHandler:",
        {
            "arguments": {
                4: {
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
        b"MTKTextureLoader",
        b"newTextureWithMDLTexture:options:error:",
        {"arguments": {4: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTextureWithName:scaleFactor:bundle:options:completionHandler:",
        {
            "arguments": {
                6: {
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
        b"MTKTextureLoader",
        b"newTextureWithName:scaleFactor:bundle:options:error:",
        {"arguments": {6: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTextureWithName:scaleFactor:displayGamut:bundle:options:completionHandler:",
        {
            "arguments": {
                7: {
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
        b"MTKTextureLoader",
        b"newTextureWithName:scaleFactor:displayGamut:bundle:options:error:",
        {"arguments": {7: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTexturesWithContentsOfURLs:options:completionHandler:",
        {
            "arguments": {
                4: {
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
        b"MTKTextureLoader",
        b"newTexturesWithContentsOfURLs:options:error:",
        {"arguments": {4: {"type_modifier": b"o"}}},
    )
    r(
        b"MTKTextureLoader",
        b"newTexturesWithNames:scaleFactor:bundle:options:completionHandler:",
        {
            "arguments": {
                6: {
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
        b"MTKTextureLoader",
        b"newTexturesWithNames:scaleFactor:displayGamut:bundle:options:completionHandler:",
        {
            "arguments": {
                7: {
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
    r(b"MTKView", b"autoResizeDrawable", {"retval": {"type": b"Z"}})
    r(b"MTKView", b"clearColor", {"retval": {"type": b"{_MTLClearColor=dddd}"}})
    r(b"MTKView", b"enableSetNeedsDisplay", {"retval": {"type": b"Z"}})
    r(b"MTKView", b"framebufferOnly", {"retval": {"type": b"Z"}})
    r(b"MTKView", b"isPaused", {"retval": {"type": b"Z"}})
    r(b"MTKView", b"presentsWithTransaction", {"retval": {"type": b"Z"}})
    r(b"MTKView", b"setAutoResizeDrawable:", {"arguments": {2: {"type": b"Z"}}})
    r(
        b"MTKView",
        b"setClearColor:",
        {"arguments": {2: {"type": b"{_MTLClearColor=dddd}"}}},
    )
    r(b"MTKView", b"setEnableSetNeedsDisplay:", {"arguments": {2: {"type": b"Z"}}})
    r(b"MTKView", b"setFramebufferOnly:", {"arguments": {2: {"type": b"Z"}}})
    r(b"MTKView", b"setPaused:", {"arguments": {2: {"type": b"Z"}}})
    r(b"MTKView", b"setPresentsWithTransaction:", {"arguments": {2: {"type": b"Z"}}})
    r(
        b"NSObject",
        b"drawInMTKView:",
        {"required": True, "retval": {"type": b"v"}, "arguments": {2: {"type": b"@"}}},
    )
    r(
        b"NSObject",
        b"mtkView:drawableSizeWillChange:",
        {
            "required": True,
            "retval": {"type": b"v"},
            "arguments": {2: {"type": b"@"}, 3: {"type": b"{CGSize=dd}"}},
        },
    )
finally:
    objc._updatingMetadata(False)
expressions = {}

# END OF FILE
