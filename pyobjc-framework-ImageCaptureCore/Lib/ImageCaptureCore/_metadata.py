# This file is generated by objective.metadata
#
# Last update: Tue Jul  9 20:43:12 2019

import objc, sys

if sys.maxsize > 2 ** 32:
    def sel32or64(a, b): return b
else:
    def sel32or64(a, b): return a
if sys.byteorder == 'little':
    def littleOrBig(a, b): return a
else:
    def littleOrBig(a, b): return b

misc = {
}
constants = '''$ICButtonTypeCopy$ICButtonTypeMail$ICButtonTypePrint$ICButtonTypeScan$ICButtonTypeTransfer$ICButtonTypeWeb$ICCameraDeviceCanAcceptPTPCommands$ICCameraDeviceCanDeleteAllFiles$ICCameraDeviceCanDeleteOneFile$ICCameraDeviceCanReceiveFile$ICCameraDeviceCanSyncClock$ICCameraDeviceCanTakePicture$ICCameraDeviceCanTakePictureUsingShutterReleaseOnCamera$ICCameraDeviceSupportsFastPTP$ICDeleteAfterSuccessfulDownload$ICDeleteCanceled$ICDeleteErrorCanceled$ICDeleteErrorDeviceMissing$ICDeleteErrorFileMissing$ICDeleteErrorReadOnly$ICDeleteFailed$ICDeleteSuccessful$ICDeviceCanEjectOrDisconnect$ICDeviceLocationDescriptionBluetooth$ICDeviceLocationDescriptionFireWire$ICDeviceLocationDescriptionMassStorage$ICDeviceLocationDescriptionUSB$ICDownloadSidecarFiles$ICDownloadsDirectoryURL$ICEnumerationChronologicalOrder$ICErrorDomain$ICImageSourceShouldCache$ICImageSourceThumbnailMaxPixelSize$ICLocalizedStatusNotificationKey$ICOverwrite$ICSaveAsFilename$ICSavedAncillaryFiles$ICSavedFilename$ICScannerStatusRequestsOverviewScan$ICScannerStatusWarmUpDone$ICScannerStatusWarmingUp$ICStatusCodeKey$ICStatusNotificationKey$ICTransportTypeBluetooth$ICTransportTypeExFAT$ICTransportTypeFireWire$ICTransportTypeMassStorage$ICTransportTypeTCPIP$ICTransportTypeUSB$'''
enums = '''$ICDeviceLocationTypeBluetooth@2048$ICDeviceLocationTypeBonjour@1024$ICDeviceLocationTypeLocal@256$ICDeviceLocationTypeMaskBluetooth@2048$ICDeviceLocationTypeMaskBonjour@1024$ICDeviceLocationTypeMaskLocal@256$ICDeviceLocationTypeMaskRemote@65024$ICDeviceLocationTypeMaskShared@512$ICDeviceLocationTypeShared@512$ICDeviceTypeCamera@1$ICDeviceTypeMaskCamera@1$ICDeviceTypeMaskScanner@2$ICDeviceTypeScanner@2$ICEXIFOrientation1@1$ICEXIFOrientation2@2$ICEXIFOrientation3@3$ICEXIFOrientation4@4$ICEXIFOrientation5@5$ICEXIFOrientation6@6$ICEXIFOrientation7@7$ICEXIFOrientation8@8$ICLegacyReturnCodeCannotYieldDevice@-9909$ICLegacyReturnCodeCommunicationErr@-9900$ICLegacyReturnCodeDataTypeNotFoundErr@-9910$ICLegacyReturnCodeDeviceAlreadyOpenErr@-9914$ICLegacyReturnCodeDeviceGUIDNotFoundErr@-9916$ICLegacyReturnCodeDeviceIOServicePathNotFoundErr@-9917$ICLegacyReturnCodeDeviceInternalErr@-9912$ICLegacyReturnCodeDeviceInvalidParamErr@-9913$ICLegacyReturnCodeDeviceLocationIDNotFoundErr@-9915$ICLegacyReturnCodeDeviceMemoryAllocationErr@-9911$ICLegacyReturnCodeDeviceNotFoundErr@-9901$ICLegacyReturnCodeDeviceNotOpenErr@-9902$ICLegacyReturnCodeDeviceUnsupportedErr@-9918$ICLegacyReturnCodeExtensionInternalErr@-9920$ICLegacyReturnCodeFileCorruptedErr@-9903$ICLegacyReturnCodeFrameworkInternalErr@-9919$ICLegacyReturnCodeIOPendingErr@-9904$ICLegacyReturnCodeIndexOutOfRangeErr@-9907$ICLegacyReturnCodeInvalidObjectErr@-9905$ICLegacyReturnCodeInvalidPropertyErr@-9906$ICLegacyReturnCodeInvalidSessionErr@-9921$ICLegacyReturnCodePropertyTypeNotFoundErr@-9908$ICReturnCodeDeleteOffset@-21150$ICReturnCodeDeviceConnection@-21400$ICReturnCodeDeviceOffset@-21350$ICReturnCodeDownloadOffset@-21100$ICReturnCodeExFATOffset@-21200$ICReturnCodeMetadataOffset@-21050$ICReturnCodePTPOffset@-21250$ICReturnCodeSystemOffset@-21300$ICReturnCodeThumbnailOffset@-21000$ICReturnCommunicationTimedOut@-9923$ICReturnConnectionClosedSessionSuddenly@-21351$ICReturnConnectionDriverExited@-21350$ICReturnConnectionEjectFailed@-21354$ICReturnConnectionEjectedSuddenly@-21352$ICReturnConnectionFailedToOpen@-21400$ICReturnConnectionFailedToOpenDevice@-21401$ICReturnConnectionSessionAlreadyOpen@-21353$ICReturnDeleteFilesCanceled@-9942$ICReturnDeleteFilesFailed@-9941$ICReturnDeviceCommandGeneralFailure@-9955$ICReturnDeviceCouldNotPair@-9951$ICReturnDeviceCouldNotUnpair@-9952$ICReturnDeviceFailedToCloseSession@-9928$ICReturnDeviceFailedToCompleteTransfer@-9956$ICReturnDeviceFailedToOpenSession@-9927$ICReturnDeviceFailedToSendData@-9957$ICReturnDeviceFailedToTakePicture@-9944$ICReturnDeviceIsBusyEnumerating@-9954$ICReturnDeviceIsPasscodeLocked@-9943$ICReturnDeviceNeedsCredentials@-9953$ICReturnDeviceSoftwareInstallationCanceled@-9948$ICReturnDeviceSoftwareInstallationCompleted@-9947$ICReturnDeviceSoftwareInstallationFailed@-9949$ICReturnDeviceSoftwareIsBeingInstalled@-9946$ICReturnDeviceSoftwareNotAvailable@-9950$ICReturnDeviceSoftwareNotInstalled@-9945$ICReturnDownloadCanceled@-9937$ICReturnDownloadFailed@-9934$ICReturnErrorDeviceEjected@-21300$ICReturnExFATVolumeInvalid@-21200$ICReturnFailedToCompletePassThroughCommand@-9936$ICReturnFailedToCompleteSendMessageRequest@-9940$ICReturnFailedToDisabeTethering@-9939$ICReturnFailedToEnabeTethering@-9938$ICReturnInvalidParam@-9922$ICReturnMetadataAlreadyFetching@-21051$ICReturnMetadataCanceled@-21052$ICReturnMetadataInvalid@-21053$ICReturnMetadataNotAvailable@-21050$ICReturnMultiErrorDictionary@-30000$ICReturnReceivedUnsolicitedScannerErrorInfo@-9933$ICReturnReceivedUnsolicitedScannerStatusInfo@-9932$ICReturnScanOperationCanceled@-9924$ICReturnScannerFailedToCompleteOverviewScan@-9930$ICReturnScannerFailedToCompleteScan@-9931$ICReturnScannerFailedToSelectFunctionalUnit@-9929$ICReturnScannerInUseByLocalUser@-9925$ICReturnScannerInUseByRemoteUser@-9926$ICReturnSessionNotOpened@-9958$ICReturnSuccess@0$ICReturnThumbnailAlreadyFetching@-21001$ICReturnThumbnailCanceled@-21002$ICReturnThumbnailInvalid@-21003$ICReturnThumbnailNotAvailable@-21000$ICReturnUploadFailed@-9935$ICScannerBitDepth16Bits@16$ICScannerBitDepth1Bit@1$ICScannerBitDepth8Bits@8$ICScannerColorDataFormatTypeChunky@0$ICScannerColorDataFormatTypePlanar@1$ICScannerDocumentType10@25$ICScannerDocumentType10R@67$ICScannerDocumentType110@72$ICScannerDocumentType11R@69$ICScannerDocumentType12R@70$ICScannerDocumentType135@76$ICScannerDocumentType2A0@18$ICScannerDocumentType3R@61$ICScannerDocumentType4A0@17$ICScannerDocumentType4R@62$ICScannerDocumentType5R@63$ICScannerDocumentType6R@64$ICScannerDocumentType8R@65$ICScannerDocumentTypeA0@19$ICScannerDocumentTypeA1@20$ICScannerDocumentTypeA2@21$ICScannerDocumentTypeA3@11$ICScannerDocumentTypeA4@1$ICScannerDocumentTypeA5@5$ICScannerDocumentTypeA6@13$ICScannerDocumentTypeA7@22$ICScannerDocumentTypeA8@23$ICScannerDocumentTypeA9@24$ICScannerDocumentTypeAPSC@74$ICScannerDocumentTypeAPSH@73$ICScannerDocumentTypeAPSP@75$ICScannerDocumentTypeB5@2$ICScannerDocumentTypeBusinessCard@53$ICScannerDocumentTypeC0@44$ICScannerDocumentTypeC1@45$ICScannerDocumentTypeC10@51$ICScannerDocumentTypeC2@46$ICScannerDocumentTypeC3@47$ICScannerDocumentTypeC4@14$ICScannerDocumentTypeC5@15$ICScannerDocumentTypeC6@16$ICScannerDocumentTypeC7@48$ICScannerDocumentTypeC8@49$ICScannerDocumentTypeC9@50$ICScannerDocumentTypeDefault@0$ICScannerDocumentTypeE@60$ICScannerDocumentTypeISOB0@26$ICScannerDocumentTypeISOB1@27$ICScannerDocumentTypeISOB10@33$ICScannerDocumentTypeISOB2@28$ICScannerDocumentTypeISOB3@12$ICScannerDocumentTypeISOB4@6$ICScannerDocumentTypeISOB5@29$ICScannerDocumentTypeISOB6@7$ICScannerDocumentTypeISOB7@30$ICScannerDocumentTypeISOB8@31$ICScannerDocumentTypeISOB9@32$ICScannerDocumentTypeJISB0@34$ICScannerDocumentTypeJISB1@35$ICScannerDocumentTypeJISB10@43$ICScannerDocumentTypeJISB2@36$ICScannerDocumentTypeJISB3@37$ICScannerDocumentTypeJISB4@38$ICScannerDocumentTypeJISB6@39$ICScannerDocumentTypeJISB7@40$ICScannerDocumentTypeJISB8@41$ICScannerDocumentTypeJISB9@42$ICScannerDocumentTypeLF@78$ICScannerDocumentTypeMF@77$ICScannerDocumentTypeS10R@68$ICScannerDocumentTypeS12R@71$ICScannerDocumentTypeS8R@66$ICScannerDocumentTypeUSExecutive@10$ICScannerDocumentTypeUSLedger@9$ICScannerDocumentTypeUSLegal@4$ICScannerDocumentTypeUSLetter@3$ICScannerDocumentTypeUSStatement@52$ICScannerFeatureTypeBoolean@2$ICScannerFeatureTypeEnumeration@0$ICScannerFeatureTypeRange@1$ICScannerFeatureTypeTemplate@3$ICScannerFunctionalUnitStateOverviewScanInProgress@4$ICScannerFunctionalUnitStateReady@1$ICScannerFunctionalUnitStateScanInProgress@2$ICScannerFunctionalUnitTypeDocumentFeeder@3$ICScannerFunctionalUnitTypeFlatbed@0$ICScannerFunctionalUnitTypeNegativeTransparency@2$ICScannerFunctionalUnitTypePositiveTransparency@1$ICScannerMeasurementUnitCentimeters@1$ICScannerMeasurementUnitInches@0$ICScannerMeasurementUnitPicas@2$ICScannerMeasurementUnitPixels@5$ICScannerMeasurementUnitPoints@3$ICScannerMeasurementUnitTwips@4$ICScannerPixelDataTypeBW@0$ICScannerPixelDataTypeCIEXYZ@8$ICScannerPixelDataTypeCMY@4$ICScannerPixelDataTypeCMYK@5$ICScannerPixelDataTypeGray@1$ICScannerPixelDataTypePalette@3$ICScannerPixelDataTypeRGB@2$ICScannerPixelDataTypeYUV@6$ICScannerPixelDataTypeYUVK@7$ICScannerTransferModeFileBased@0$ICScannerTransferModeMemoryBased@1$'''
misc.update({'ICRunLoopMode': b'com.apple.ImageCaptureCore'.decode("utf-8")})
aliases = {'ICReturnThumbnailNotAvailable': 'ICReturnCodeThumbnailOffset', 'ICReturnMetadataNotAvailable': 'ICReturnCodeMetadataOffset', 'ICReturnConnectionFailedToOpen': 'ICReturnCodeDeviceConnection', 'ICRect': 'NSRect', 'ICSize': 'NSSize', 'ICReturnExFATVolumeInvalid': 'ICReturnCodeExFATOffset', 'ICReturnConnectionDriverExited': 'ICReturnCodeDeviceOffset', 'ICPoint': 'NSPoint', 'ICReturnDeviceIsAccessRestrictedAppleDevice': 'ICReturnDeviceIsPasscodeLocked'}
