import AppKit
import objc
from PyObjCTools.TestSupport import TestCase, min_os_level


class FindHelper(AppKit.NSObject):
    def rectsForCharacterRange_(self, r):
        return 1

    def replaceCharactersInRange_withString_(self, r, s):
        pass

    def stringLength(self):
        return 0

    def isSelectable(self):
        pass

    def allowsMultipleSelection(self):
        pass

    def isEditable(self):
        pass

    def stringAtIndex_effectiveRange_endswithSearchBoundary_(self, a, b, c):
        pass

    def firstSelectedRange(self):
        pass

    def scrollRangeToVisible_(self, a):
        pass

    def shouldReplaceCharactersInRanges_withStrings_(self, a, b):
        pass

    def contentViewAtIndex_effectiveCharacterRange_(self, a, b):
        pass

    def drawCharactersInRange_forContentView_(self, a, b):
        pass

    def isFindBarVisible(self):
        return 1

    def setFindBarVisible_(self, a):
        pass


class TestNSTextFinder(TestCase):
    def test_typed_enum(self):
        self.assertIsTypedEnum(AppKit.NSPasteboardTypeTextFinderOptionKey, str)

    def test_enum_types(self):
        self.assertIsEnumType(AppKit.NSTextFinderAction)
        self.assertIsEnumType(AppKit.NSTextFinderMatchingType)

    @min_os_level("10.7")
    def testConstants10_7(self):
        self.assertEqual(AppKit.NSTextFinderActionShowFindInterface, 1)
        self.assertEqual(AppKit.NSTextFinderActionNextMatch, 2)
        self.assertEqual(AppKit.NSTextFinderActionPreviousMatch, 3)
        self.assertEqual(AppKit.NSTextFinderActionReplaceAll, 4)
        self.assertEqual(AppKit.NSTextFinderActionReplace, 5)
        self.assertEqual(AppKit.NSTextFinderActionReplaceAndFind, 6)
        self.assertEqual(AppKit.NSTextFinderActionSetSearchString, 7)
        self.assertEqual(AppKit.NSTextFinderActionReplaceAllInSelection, 8)
        self.assertEqual(AppKit.NSTextFinderActionSelectAll, 9)
        self.assertEqual(AppKit.NSTextFinderActionSelectAllInSelection, 10)
        self.assertEqual(AppKit.NSTextFinderActionHideFindInterface, 11)
        self.assertEqual(AppKit.NSTextFinderActionShowReplaceInterface, 12)
        self.assertEqual(AppKit.NSTextFinderActionHideReplaceInterface, 13)

        self.assertIsInstance(AppKit.NSTextFinderCaseInsensitiveKey, str)
        self.assertIsInstance(AppKit.NSTextFinderMatchingTypeKey, str)

        self.assertEqual(AppKit.NSTextFinderMatchingTypeContains, 0)
        self.assertEqual(AppKit.NSTextFinderMatchingTypeStartsWith, 1)
        self.assertEqual(AppKit.NSTextFinderMatchingTypeFullWord, 2)
        self.assertEqual(AppKit.NSTextFinderMatchingTypeEndsWith, 3)

    @min_os_level("10.7")
    def testMethods10_7(self):
        self.assertResultIsBOOL(AppKit.NSTextFinder.validateAction_)
        self.assertResultIsBOOL(AppKit.NSTextFinder.findIndicatorNeedsUpdate)
        self.assertArgIsBOOL(AppKit.NSTextFinder.setFindIndicatorNeedsUpdate_, 0)
        self.assertResultIsBOOL(AppKit.NSTextFinder.isIncrementalSearchingEnabled)
        self.assertArgIsBOOL(AppKit.NSTextFinder.setIncrementalSearchingEnabled_, 0)
        self.assertResultIsBOOL(
            AppKit.NSTextFinder.incrementalSearchingShouldDimContentView
        )
        self.assertArgIsBOOL(
            AppKit.NSTextFinder.setIncrementalSearchingShouldDimContentView_, 0
        )

    @min_os_level("10.10")
    def testProtocolObjects(self):
        objc.protocolNamed("NSTextFinderClient")

    @min_os_level("10.7")
    def testProtocol10_7(self):
        self.assertResultIsBOOL(FindHelper.isSelectable)
        self.assertResultIsBOOL(FindHelper.allowsMultipleSelection)
        self.assertResultIsBOOL(FindHelper.isEditable)

        self.assertArgHasType(
            FindHelper.stringAtIndex_effectiveRange_endswithSearchBoundary_,
            0,
            objc._C_NSUInteger,
        )
        self.assertArgHasType(
            FindHelper.stringAtIndex_effectiveRange_endswithSearchBoundary_,
            1,
            b"o^" + AppKit.NSRange.__typestr__,
        )
        self.assertArgHasType(
            FindHelper.stringAtIndex_effectiveRange_endswithSearchBoundary_,
            2,
            b"o^" + objc._C_NSBOOL,
        )

        self.assertResultHasType(FindHelper.stringLength, objc._C_NSUInteger)

        self.assertResultHasType(
            FindHelper.firstSelectedRange, AppKit.NSRange.__typestr__
        )
        self.assertArgHasType(
            FindHelper.scrollRangeToVisible_, 0, AppKit.NSRange.__typestr__
        )
        self.assertResultIsBOOL(FindHelper.shouldReplaceCharactersInRanges_withStrings_)
        self.assertArgHasType(
            FindHelper.replaceCharactersInRange_withString_,
            0,
            AppKit.NSRange.__typestr__,
        )
        self.assertArgHasType(
            FindHelper.rectsForCharacterRange_, 0, AppKit.NSRange.__typestr__
        )
        self.assertArgHasType(
            FindHelper.contentViewAtIndex_effectiveCharacterRange_,
            0,
            objc._C_NSUInteger,
        )
        self.assertArgHasType(
            FindHelper.contentViewAtIndex_effectiveCharacterRange_,
            1,
            b"o^" + AppKit.NSRange.__typestr__,
        )
        self.assertArgHasType(
            FindHelper.drawCharactersInRange_forContentView_,
            0,
            AppKit.NSRange.__typestr__,
        )

        objc.protocolNamed("NSTextFinderBarContainer")

        self.assertResultIsBOOL(FindHelper.isFindBarVisible)
        self.assertArgIsBOOL(FindHelper.setFindBarVisible_, 0)
