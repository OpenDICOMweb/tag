// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:system/system.dart';
import 'package:tag/src/e_type.dart';
import 'package:tag/src/elt.dart';
import 'package:tag/src/errors.dart';
import 'package:tag/src/group.dart';
import 'package:tag/src/p_tag_code_map.dart';
import 'package:tag/src/p_tag_codes.dart';
import 'package:tag/src/p_tag_keywords.dart';
import 'package:tag/src/tag.dart';
import 'package:tag/src/vm.dart';
import 'package:vr/vr.dart';

//TODO: is hashCode needed?
class PTag extends Tag {
  @override
  final int code;
  @override
  final String keyword;
  @override
  final String name;
  @override
  final VR vr;
  @override
  final VM vm;
  @override
  final EType type;
  @override
  final bool isRetired;

  ///TODO: Tag and Tag.public are inconsistent when new Tag, PrivateTag... files
  ///      are generated make them consistent.
/*
  const PTag(int code, VR vr, this.vm, this.keyword, this.name,
      [this.isRetired = false, this.type = EType.kUnknown])
      : super();
*/

  factory PTag(int code, [VR vr = VR.kUN, String name = '']) {
    final tag = lookupByCode(code, vr);
    return (tag != null) ? tag : new PTag.unknown(code, vr, name);
  }

  //TODO: When regenerating Tag rework constructors as follows:
  // Tag(int code, [vr = VR.kUN, vm = VM.k1_n);
  // Tag._(this.code, this.vr, this.vm, this.keyword, this.name,
  //     [this.isRetired = false, this.type = EType.kUnknown]
  // Tag.private(this.code, this.vr, this.vm, this.keyword, this.name,
  //     [this.isRetired = false, this.type = EType.kUnknown]);
  const PTag._(this.keyword, this.code, this.name, this.vr, this.vm,
      [this.isRetired = false, this.type = EType.kUnknown])
      : super();

  static const String _unknownKeyword = 'UnknownPublicTag';

  PTag.unknown(this.code, this.vr, [this.name = 'Unknown Public Tag'])
      : this.keyword = _unknownKeyword,
        this.vm = VM.k1_n,
        this.isRetired = false,
        this.type = EType.k3,
        super();

  @override
  int get index => pTagCodes.indexOf(code);

  @override
  bool get isValid => keyword != _unknownKeyword;

  bool get isWKFmi => fmiTags.contains(code);

  static PTag maker(int code, VR vr, [Object name]) {
    final tag = lookupByCode(code, vr);
    if (tag != null) return tag;
    return new PTag.unknown(code, vr);
  }

  static PTag unknownMaker(int code, VR vr, [Object name]) => new PTag.unknown(code, vr);

  static PTag lookupByCode(int code, [VR vr = VR.kUN, bool shouldThrow = false]) {
    assert(Tag.isPublicCode(code));
    final tag = pTagCodeMap[code];
    if (tag != null) return tag;

    // This is fromTag Group Length Tag
    if (Elt.fromTag(code) == 0) return new PTagGroupLength(code);

    // **** Retired _special case_ codes that still must be handled
    if ((code >= 0x00283100) && (code <= 0x002031FF)) return PTag.kSourceImageIDs;
    if ((code >= 0x00280410) && (code <= 0x002804F0))
      return PTag.kRowsForNthOrderCoefficients;
    if ((code >= 0x00280411) && (code <= 0x002804F1))
      return PTag.kColumnsForNthOrderCoefficients;
    if ((code >= 0x00280412) && (code <= 0x002804F2)) return PTag.kCoefficientCoding;
    if ((code >= 0x00280413) && (code <= 0x002804F3))
      return PTag.kCoefficientCodingPointers;
    if ((code >= 0x00280810) && (code <= 0x002808F0)) return PTag.kCodeLabel;
    if ((code >= 0x00280812) && (code <= 0x002808F2)) return PTag.kNumberOfTables;
    if ((code >= 0x00280813) && (code <= 0x002808F3)) return PTag.kCodeTableLocation;
    if ((code >= 0x00280814) && (code <= 0x002808F4)) return PTag.kBitsForCodeWord;
    if ((code >= 0x00280818) && (code <= 0x002808F8)) return PTag.kImageDataLocation;

    //**** (1000,xxxy ****
    // (1000,04X2)
    if ((code >= 0x10000000) && (code <= 0x1000FFF0)) return PTag.kEscapeTriplet;
    // (1000,04X3)
    if ((code >= 0x10000001) && (code <= 0x1000FFF1)) return PTag.kRunLengthTriplet;
    // (1000,08x0)
    if ((code >= 0x10000002) && (code <= 0x1000FFF2)) return PTag.kHuffmanTableSize;
    // (1000,08x2)
    if ((code >= 0x10000003) && (code <= 0x1000FFF3)) return PTag.kHuffmanTableTriplet;
    // (1000,08x3)
    if ((code >= 0x10000004) && (code <= 0x1000FFF4)) return PTag.kShiftTableSize;
    // (1000,08x4)
    if ((code >= 0x10000005) && (code <= 0x1000FFF5)) return PTag.kShiftTableTriplet;
    // (1000,08x8)
    if ((code >= 0x10100000) && (code <= 0x1010FFFF)) return PTag.kZonalMap;

    //Urgent v0.5.4: 0x50xx,yyyy Elements
    //Urgent: 0x60xx,yyyy Elements
    //Urgent: 0x7Fxx,yyyy Elements

    // No match return [null]
    if (shouldThrow) throw new InvalidTagCodeError(code);
    return new PTag.unknown(code, vr);
  }

  static int keywordToCode(String keyword) {
    final tag = lookupByKeyword(keyword);
    return (tag == null) ? null : tag.code;
  }

  //TODO: make keyword lookup work
  /// Currently can only be used to lookup Public [PTag]s as Private [PTag]s
  /// don\'t have [keyword]s.
  static PTag lookupByKeyword(String keyword, [VR vr, bool shouldThrow = true]) {
    final tag = pTagKeywords[keyword];
    if (tag != null) return tag;

    // Retired _special case_ keywords that still must be handled
    /* TODO: figure out what to do with this? remove?
    // (0020,31xx)
    if ((keyword >= 0x00283100) && (keyword <= 0x002031FF))
    return Tag.kSourceImageIDs;

    // (0028,04X0)
    if ((keyword >= 0x00280410) && (keyword <= 0x002804F0))
      return Tag.kRowsForNthOrderCoefficients;
    // (0028,04X1)
    if ((keyword >= 0x00280411) && (keyword <= 0x002804F1))
      return Tag.kColumnsForNthOrderCoefficients;
    // (0028,04X2)
    if ((keyword >= 0x00280412) && (keyword <= 0x002804F2))
    return Tag.kCoefficientCoding;
    // (0028,04X3)
    if ((keyword >= 0x00280413) && (keyword <= 0x002804F3))
      return Tag.kCoefficientCodingPointers;

    // (0028,08x0)
    if ((keyword >= 0x00280810) && (keyword <= 0x002808F0))
    return Tag.kCodeLabel;
    // (0028,08x2)
    if ((keyword >= 0x00280812) && (keyword <= 0x002808F2))
    return Tag.kNumberOfTables;
    // (0028,08x3)
    if ((keyword >= 0x00280813) && (keyword <= 0x002808F3))
    return Tag.kCodeTableLocation;
    // (0028,08x4)
    if ((keyword >= 0x00280814) && (keyword <= 0x002808F4))
    return Tag.kBitsForCodeWord;
    // (0028,08x8)
    if ((keyword >= 0x00280818) && (keyword <= 0x002808F8))
    return Tag.kImageDataLocation;

    // **** (1000,xxxy ****
    // (1000,04X2)
    if ((keyword >= 0x10000000) && (keyword <= 0x1000FFF0))
    return Tag.kEscapeTriplet;
    // (1000,04X3)
    if ((keyword >= 0x10000001) && (keyword <= 0x1000FFF1))
    return Tag.kRunLengthTriplet;
    // (1000,08x0)
    if ((keyword >= 0x10000002) && (keyword <= 0x1000FFF2))
    return Tag.kHuffmanTableSize;
    // (1000,08x2)
    if ((keyword >= 0x10000003) && (keyword <= 0x1000FFF3))
      return Tag.kHuffmanTableTriplet;
    // (1000,08x3)
    if ((keyword >= 0x10000004) && (keyword <= 0x1000FFF4))
    return Tag.kShiftTableSize;
    // (1000,08x4)
    if ((keyword >= 0x10000005) && (keyword <= 0x1000FFF5))
    return Tag.kShiftTableTriplet;
    // (1000,08x8)
    if ((keyword >= 0x10100000) && (keyword <= 0x1010FFFF))
    return Tag.kZonalMap;

    //TODO: 0x50xx,yyyy Elements
    //TODO: 0x60xx,yyyy Elements
    //TODO: 0x7Fxx,yyyy Elements
*/
    // No match return [null]
    return tagKeywordError(keyword);
  }

  //**** Message Data Elements begin here ****
  static const PTag kAffectedSOPInstanceUID = const PTag._('AffectedSOPInstanceUID',
      0x00001000, 'Affected SOP Instance UID ', VR.kUI, VM.k1, false);

  static const PTag kRequestedSOPInstanceUID = const PTag._('RequestedSOPInstanceUID',
      0x00001001, 'Requested SOP Instance UID', VR.kUI, VM.k1, false);

  //**** File Meta Information Data Elements begin here ****
  static const PTag kFileMetaInformationGroupLength = const PTag._(
      'FileMetaInformationGroupLength',
      0x00020000,
      'File Meta Information Group Length',
      VR.kUL,
      VM.k1,
      false);

  static const PTag kFileMetaInformationVersion = const PTag._(
      'FileMetaInformationVersion',
      0x00020001,
      'File Meta Information Version',
      VR.kOB,
      VM.k1,
      false);

  static const PTag kMediaStorageSOPClassUID = const PTag._('MediaStorageSOPClassUID',
      0x00020002, 'Media Storage SOP Class UID', VR.kUI, VM.k1, false);

  static const PTag kMediaStorageSOPInstanceUID = const PTag._(
      'MediaStorageSOPInstanceUID',
      0x00020003,
      'Media Storage SOP Instance UID',
      VR.kUI,
      VM.k1,
      false);

  static const PTag kTransferSyntaxUID = const PTag._(
      'TransferSyntaxUID', 0x00020010, 'Transfer Syntax UID', VR.kUI, VM.k1, false);

  static const PTag kImplementationClassUID = const PTag._('ImplementationClassUID',
      0x00020012, 'Implementation Class UID', VR.kUI, VM.k1, false);

  static const PTag kImplementationVersionName = const PTag._('ImplementationVersionName',
      0x00020013, 'Implementation Version Name', VR.kSH, VM.k1, false);

  static const PTag kSourceApplicationEntityTitle = const PTag._(
      'SourceApplicationEntityTitle',
      0x00020016,
      'Source ApplicationEntity Title',
      VR.kAE,
      VM.k1,
      false);

  static const PTag kSendingApplicationEntityTitle = const PTag._(
      'SendingApplicationEntityTitle',
      0x00020017,
      'Sending Application Entity Title',
      VR.kAE,
      VM.k1,
      false);

  static const PTag kReceivingApplicationEntityTitle = const PTag._(
      'ReceivingApplicationEntityTitle',
      0x00020018,
      'Receiving Application Entity Title',
      VR.kAE,
      VM.k1,
      false);

  static const PTag kPrivateInformationCreatorUID = const PTag._(
      'PrivateInformationCreatorUID',
      0x00020100,
      'Private Information Creator UID',
      VR.kUI,
      VM.k1,
      false);

  static const PTag kPrivateInformation = const PTag._(
      'PrivateInformation', 0x00020102, 'Private Information', VR.kOB, VM.k1, false);

  //**** DICOM Directory Tags begin here ****
  static const PTag kFileSetID =
      const PTag._('FileSetID', 0x00041130, 'File-set ID', VR.kCS, VM.k1, false);

  static const PTag kFileSetDescriptorFileID = const PTag._('FileSetDescriptorFileID',
      0x00041141, 'File-set Descriptor File ID', VR.kCS, VM.k1_8, false);

  static const PTag kSpecificCharacterSetOfFileSetDescriptorFile = const PTag._(
      'SpecificCharacterSetOfFileSetDescriptorFile',
      0x00041142,
      'Specific Character Set of File Set Descriptor File',
      VR.kCS,
      VM.k1,
      false);

  static const PTag kOffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity =
      const PTag._(
          'OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity',
          0x00041200,
          'Offset of the First Directory Record of the Root Directory Entity',
          VR.kUL,
          VM.k1,
          false);

  static const PTag kOffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity =
      const PTag._(
          'OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity',
          0x00041202,
          'Offset of the Last Directory Record of the Root Directory Entity',
          VR.kUL,
          VM.k1,
          false);

  static const PTag kFileSetConsistencyFlag = const PTag._('FileSetConsistencyFlag',
      0x00041212, 'File-set Consistency Flag', VR.kUS, VM.k1, false);

  static const PTag kDirectoryRecordSequence = const PTag._('DirectoryRecordSequence',
      0x00041220, 'Directory Record Sequence', VR.kSQ, VM.k1, false);

  static const PTag kOffsetOfTheNextDirectoryRecord = const PTag._(
      'OffsetOfTheNextDirectoryRecord',
      0x00041400,
      'Offset of the Next Directory Record',
      VR.kUL,
      VM.k1,
      false);

  static const PTag kRecordInUseFlag = const PTag._(
      'RecordInUseFlag', 0x00041410, 'Record In-use Flag', VR.kUS, VM.k1, false);

  static const PTag kOffsetOfReferencedLowerLevelDirectoryEntity = const PTag._(
      'OffsetOfReferencedLowerLevelDirectoryEntity',
      0x00041420,
      'Offset of Referenced Lower-Level Directory Entity',
      VR.kUL,
      VM.k1,
      false);

  static const PTag kDirectoryRecordType = const PTag._(
      'DirectoryRecordType', 0x00041430, 'Directory​Record​Type', VR.kCS, VM.k1, false);

  static const PTag kPrivateRecordUID = const PTag._(
      'PrivateRecordUID', 0x00041432, 'Private Record UID', VR.kUI, VM.k1, false);

  static const PTag kReferencedFileID = const PTag._(
      'ReferencedFileID', 0x00041500, 'Referenced File ID', VR.kCS, VM.k1_8, false);

  static const PTag kMRDRDirectoryRecordOffset = const PTag._('MRDRDirectoryRecordOffset',
      0x00041504, 'MRDR Directory Record Offset', VR.kUL, VM.k1, true);

  static const PTag kReferencedSOPClassUIDInFile = const PTag._(
      'ReferencedSOPClassUIDInFile',
      0x00041510,
      'Referenced SOP Class UID in File',
      VR.kUI,
      VM.k1,
      false);

  static const PTag kReferencedSOPInstanceUIDInFile = const PTag._(
      'ReferencedSOPInstanceUIDInFile',
      0x00041511,
      'Referenced SOP Instance UID in File',
      VR.kUI,
      VM.k1,
      false);

  static const PTag kReferencedTransferSyntaxUIDInFile = const PTag._(
      'ReferencedTransferSyntaxUIDInFile',
      0x00041512,
      'Referenced Transfer Syntax UID in File',
      VR.kUI,
      VM.k1,
      false);

  static const PTag kReferencedRelatedGeneralSOPClassUIDInFile = const PTag._(
      'ReferencedRelatedGeneralSOPClassUIDInFile',
      0x0004151a,
      'Referenced Related General SOP Class UID in File',
      VR.kUI,
      VM.k1_n,
      false);

  static const PTag kNumberOfReferences = const PTag._(
      'NumberOfReferences', 0x00041600, 'Number of References', VR.kUL, VM.k1, true);

  //**** Standard Dataset Tags begin here ****

  static const PTag kLengthToEnd
      //(0008,0001) '00080001'
      = const PTag._('LengthToEnd', 0x00080001, 'Length to End', VR.kUL, VM.k1, true);
  static const PTag kSpecificCharacterSet
      //(0008,0005)
      = const PTag._('SpecificCharacterSet', 0x00080005, 'Specific Character Set', VR.kCS,
          VM.k1_n, false);
  static const PTag kLanguageCodeSequence
      //(0008,0006)
      = const PTag._('LanguageCodeSequence', 0x00080006, 'Language Code Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kImageType
      //(0008,0008)
      = const PTag._('ImageType', 0x00080008, 'Image Type', VR.kCS, VM.k2_n, false);
  static const PTag kRecognitionCode
      //(0008,0010)
      = const PTag._(
          'RecognitionCode', 0x00080010, 'Recognition Code', VR.kSH, VM.k1, true);
  static const PTag kInstanceCreationDate
      //(0008,0012)
      = const PTag._('InstanceCreationDate', 0x00080012, 'Instance Creation Date', VR.kDA,
          VM.k1, false);
  static const PTag kInstanceCreationTime
      //(0008,0013)
      = const PTag._('InstanceCreationTime', 0x00080013, 'Instance Creation Time', VR.kTM,
          VM.k1, false);
  static const PTag kInstanceCreatorUID
      //(0008,0014)
      = const PTag._(
          'InstanceCreatorUID', 0x00080014, 'Instance Creator UID', VR.kUI, VM.k1, false);
  static const PTag kInstanceCoercionDateTime
      //(0008,0015)
      = const PTag._('InstanceCoercionDateTime', 0x00080015, 'Instance Coercion DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kSOPClassUID
      //(0008,0016)
      = const PTag._('SOPClassUID', 0x00080016, 'SOP Class UID', VR.kUI, VM.k1, false);
  static const PTag kSOPInstanceUID
      //(0008,0018)
      = const PTag._(
          'SOPInstanceUID', 0x00080018, 'SOP Instance UID', VR.kUI, VM.k1, false);
  static const PTag kRelatedGeneralSOPClassUID
      //(0008,001A)
      = const PTag._('RelatedGeneralSOPClassUID', 0x0008001A,
          'Related General SOP Class UID', VR.kUI, VM.k1_n, false);
  static const PTag kOriginalSpecializedSOPClassUID
      //(0008,001B)
      = const PTag._('OriginalSpecializedSOPClassUID', 0x0008001B,
          'Original Specialized SOP Class UID', VR.kUI, VM.k1, false);
  static const PTag kStudyDate
      //(0008,0020)
      = const PTag._('StudyDate', 0x00080020, 'Study Date', VR.kDA, VM.k1, false);
  static const PTag kSeriesDate
      //(0008,0021)
      = const PTag._('SeriesDate', 0x00080021, 'Series Date', VR.kDA, VM.k1, false);
  static const PTag kAcquisitionDate
      //(0008,0022)
      = const PTag._(
          'AcquisitionDate', 0x00080022, 'Acquisition Date', VR.kDA, VM.k1, false);
  static const PTag kContentDate
      //(0008,0023)
      = const PTag._('ContentDate', 0x00080023, 'Content Date', VR.kDA, VM.k1, false);
  static const PTag kOverlayDate
      //(0008,0024)
      = const PTag._('OverlayDate', 0x00080024, 'Overlay Date', VR.kDA, VM.k1, true);
  static const PTag kCurveDate
      //(0008,0025)
      = const PTag._('CurveDate', 0x00080025, 'Curve Date', VR.kDA, VM.k1, true);
  static const PTag kAcquisitionDateTime
      //(0008,002A)
      = const PTag._('AcquisitionDateTime', 0x0008002A, 'Acquisition DateTime', VR.kDT,
          VM.k1, false);
  static const PTag kStudyTime
      //(0008,0030)
      = const PTag._('StudyTime', 0x00080030, 'Study Time', VR.kTM, VM.k1, false);
  static const PTag kSeriesTime
      //(0008,0031)
      = const PTag._('SeriesTime', 0x00080031, 'Series Time', VR.kTM, VM.k1, false);
  static const PTag kAcquisitionTime
      //(0008,0032)
      = const PTag._(
          'AcquisitionTime', 0x00080032, 'Acquisition Time', VR.kTM, VM.k1, false);
  static const PTag kContentTime
      //(0008,0033)
      = const PTag._('ContentTime', 0x00080033, 'Content Time', VR.kTM, VM.k1, false);
  static const PTag kOverlayTime
      //(0008,0034)
      = const PTag._('OverlayTime', 0x00080034, 'Overlay Time', VR.kTM, VM.k1, true);
  static const PTag kCurveTime
      //(0008,0035)
      = const PTag._('CurveTime', 0x00080035, 'Curve Time', VR.kTM, VM.k1, true);
  static const PTag kDataSetType
      //(0008,0040)
      = const PTag._('DataSetType', 0x00080040, 'Data Set Type', VR.kUS, VM.k1, true);
  static const PTag kDataSetSubtype
      //(0008,0041)
      =
      const PTag._('DataSetSubtype', 0x00080041, 'Data Set Subtype', VR.kLO, VM.k1, true);
  static const PTag kNuclearMedicineSeriesType
      //(0008,0042)
      = const PTag._('NuclearMedicineSeriesType', 0x00080042,
          'Nuclear Medicine Series Type', VR.kCS, VM.k1, true);
  static const PTag kAccessionNumber
      //(0008,0050)
      = const PTag._(
          'AccessionNumber', 0x00080050, 'Accession Number', VR.kSH, VM.k1, false);
  static const PTag kIssuerOfAccessionNumberSequence
      //(0008,0051)
      = const PTag._('IssuerOfAccessionNumberSequence', 0x00080051,
          'Issuer of Accession Number Sequence', VR.kSQ, VM.k1, false);
  static const PTag kQueryRetrieveLevel
      //(0008,0052)
      = const PTag._(
          'QueryRetrieveLevel', 0x00080052, 'Query/Retrieve Level', VR.kCS, VM.k1, false);
  static const PTag kQueryRetrieveView
      //(0008,0053)
      = const PTag._(
          'QueryRetrieveView', 0x00080053, 'Query/Retrieve View', VR.kCS, VM.k1, false);
  static const PTag kRetrieveAETitle
      //(0008,0054)
      = const PTag._(
          'RetrieveAETitle', 0x00080054, 'Retrieve AE Title', VR.kAE, VM.k1_n, false);
  static const PTag kInstanceAvailability
      //(0008,0056)
      = const PTag._('InstanceAvailability', 0x00080056, 'Instance Availability', VR.kCS,
          VM.k1, false);
  static const PTag kFailedSOPInstanceUIDList
      //(0008,0058)
      = const PTag._('FailedSOPInstanceUIDList', 0x00080058,
          'Failed SOP Instance UID List', VR.kUI, VM.k1_n, false);
  static const PTag kModality
      //(0008,0060)
      = const PTag._('Modality', 0x00080060, 'Modality', VR.kCS, VM.k1, false);
  static const PTag kModalitiesInStudy
      //(0008,0061)
      = const PTag._(
          'ModalitiesInStudy', 0x00080061, 'Modalities in Study', VR.kCS, VM.k1_n, false);
  static const PTag kSOPClassesInStudy
      //(0008,0062)
      = const PTag._('SOPClassesInStudy', 0x00080062, 'SOP Classes in Study', VR.kUI,
          VM.k1_n, false);
  static const PTag kConversionType
      //(0008,0064)
      =
      const PTag._('ConversionType', 0x00080064, 'Conversion Type', VR.kCS, VM.k1, false);
  static const PTag kPresentationIntentType
      //(0008,0068)
      = const PTag._('PresentationIntentType', 0x00080068, 'Presentation Intent Type',
          VR.kCS, VM.k1, false);
  static const PTag kManufacturer
      //(0008,0070)
      = const PTag._('Manufacturer', 0x00080070, 'Manufacturer', VR.kLO, VM.k1, false);
  static const PTag kInstitutionName
      //(0008,0080)
      = const PTag._(
          'InstitutionName', 0x00080080, 'Institution Name', VR.kLO, VM.k1, false);
  static const PTag kInstitutionAddress
      //(0008,0081)
      = const PTag._(
          'InstitutionAddress', 0x00080081, 'Institution Address', VR.kST, VM.k1, false);
  static const PTag kInstitutionCodeSequence
      //(0008,0082)
      = const PTag._('InstitutionCodeSequence', 0x00080082, 'Institution Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferringPhysicianName
      //(0008,0090)
      = const PTag._('ReferringPhysicianName', 0x00080090, 'Referring Physician\'s Name',
          VR.kPN, VM.k1, false);
  static const PTag kReferringPhysicianAddress
      //(0008,0092)
      = const PTag._('ReferringPhysicianAddress', 0x00080092,
          'Referring Physician\'s Address', VR.kST, VM.k1, false);
  static const PTag kReferringPhysicianTelephoneNumbers
      //(0008,0094)
      = const PTag._('ReferringPhysicianTelephoneNumbers', 0x00080094,
          'Referring Physician\'s Telephone Numbers', VR.kSH, VM.k1_n, false);
  static const PTag kReferringPhysicianIdentificationSequence
      //(0008,0096)
      = const PTag._('ReferringPhysicianIdentificationSequence', 0x00080096,
          'Referring Physician Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCodeValue
      //(0008,0100)
      = const PTag._('CodeValue', 0x00080100, 'Code Value', VR.kSH, VM.k1, false);
  static const PTag kExtendedCodeValue
      //(0008,0101)
      = const PTag._(
          'ExtendedCodeValue', 0x00080101, 'Extended Code Value', VR.kLO, VM.k1, false);
  static const PTag kCodingSchemeDesignator
      //(0008,0102)
      = const PTag._('CodingSchemeDesignator', 0x00080102, 'Coding Scheme Designator',
          VR.kSH, VM.k1, false);
  static const PTag kCodingSchemeVersion
      //(0008,0103)
      = const PTag._('CodingSchemeVersion', 0x00080103, 'Coding Scheme Version', VR.kSH,
          VM.k1, false);
  static const PTag kCodeMeaning
      //(0008,0104)
      = const PTag._('CodeMeaning', 0x00080104, 'Code Meaning', VR.kLO, VM.k1, false);
  static const PTag kMappingResource
      //(0008,0105)
      = const PTag._(
          'MappingResource', 0x00080105, 'Mapping Resource', VR.kCS, VM.k1, false);
  static const PTag kContextGroupVersion
      //(0008,0106)
      = const PTag._('ContextGroupVersion', 0x00080106, 'Context Group Version', VR.kDT,
          VM.k1, false);
  static const PTag kContextGroupLocalVersion
      //(0008,0107)
      = const PTag._('ContextGroupLocalVersion', 0x00080107,
          'Context Group Local Version', VR.kDT, VM.k1, false);
  static const PTag kExtendedCodeMeaning
      //(0008,0108)
      = const PTag._('ExtendedCodeMeaning', 0x00080108, 'Extended Code Meaning', VR.kLT,
          VM.k1, false);
  static const PTag kContextGroupExtensionFlag
      //(0008,010B)
      = const PTag._('ContextGroupExtensionFlag', 0x0008010B,
          'Context Group Extension Flag', VR.kCS, VM.k1, false);
  static const PTag kCodingSchemeUID
      //(0008,010C)
      = const PTag._(
          'CodingSchemeUID', 0x0008010C, 'Coding Scheme UID', VR.kUI, VM.k1, false);
  static const PTag kContextGroupExtensionCreatorUID
      //(0008,010D)
      = const PTag._('ContextGroupExtensionCreatorUID', 0x0008010D,
          'Context Group Extension Creator UID', VR.kUI, VM.k1, false);
  static const PTag kContextIdentifier
      //(0008,010F)
      = const PTag._(
          'ContextIdentifier', 0x0008010F, 'Context Identifier', VR.kCS, VM.k1, false);
  static const PTag kCodingSchemeIdentificationSequence
      //(0008,0110)
      = const PTag._('CodingSchemeIdentificationSequence', 0x00080110,
          'Coding Scheme Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCodingSchemeRegistry
      //(0008,0112)
      = const PTag._('CodingSchemeRegistry', 0x00080112, 'Coding Scheme Registry', VR.kLO,
          VM.k1, false);
  static const PTag kCodingSchemeExternalID
      //(0008,0114)
      = const PTag._('CodingSchemeExternalID', 0x00080114, 'Coding Scheme External ID',
          VR.kST, VM.k1, false);
  static const PTag kCodingSchemeName
      //(0008,0115)
      = const PTag._(
          'CodingSchemeName', 0x00080115, 'Coding Scheme Name', VR.kST, VM.k1, false);
  static const PTag kCodingSchemeResponsibleOrganization
      //(0008,0116)
      = const PTag._('CodingSchemeResponsibleOrganization', 0x00080116,
          'Coding Scheme Responsible Organization', VR.kST, VM.k1, false);
  static const PTag kContextUID
      //(0008,0117)
      = const PTag._('ContextUID', 0x00080117, 'Context UID', VR.kUI, VM.k1, false);
  static const PTag kTimezoneOffsetFromUTC
      //(0008,0201)
      = const PTag._('TimezoneOffsetFromUTC', 0x00080201, 'Timezone Offset From UTC',
          VR.kSH, VM.k1, false);

  static const PTag kPrivateDataElementCharacteristicsSequence = const PTag._(
      'PrivateDataElementCharacteristicsSequence',
      0x0080300,
      'Private​Data​Element​Characteristics​Sequence',
      VR.kSQ,
      VM.k1,
      false);

  static const PTag kPrivateGroupReference = const PTag._('PrivateGroupReference',
      0x00080301, 'Private Group Reference', VR.kUS, VM.k1, false);

  static const PTag kPrivateCreatorReference = const PTag._('PrivateCreatorReference',
      0x00080302, 'Private Creator Reference', VR.kLO, VM.k1, false);

  static const PTag kBlockIdentifyingInformationStatus = const PTag._(
      'BlockIdentifyingInformationStatus',
      0x00080303,
      'Block Identifying Information Status',
      VR.kCS,
      VM.k1,
      false);

  static const PTag kNonidentifyingPrivateElements = const PTag._(
      'NonidentifyingPrivateElements',
      0x00080304,
      'Nonidentifying Private Elements',
      VR.kUS,
      VM.k1_n,
      false);
  static const PTag kDeidentificationActionSequence = const PTag._(
      'DeidentificationActionSequence',
      0x00080305,
      'Deidentification Action Sequence',
      VR.kSQ,
      VM.k1,
      false);
  static const PTag kIdentifyingPrivateElements = const PTag._(
      'IdentifyingPrivateElements',
      0x00080306,
      'Identifying Private Elements',
      VR.kUS,
      VM.k1_n,
      false);
  static const PTag kDeidentificationAction = const PTag._('DeidentificationAction',
      0x00080307, 'Deidentification Action', VR.kCS, VM.k1, false);
  static const PTag kNetworkID
      //(0008,1000)
      = const PTag._('NetworkID', 0x00081000, 'Network ID', VR.kAE, VM.k1, true);
  static const PTag kStationName
      //(0008,1010)
      = const PTag._('StationName', 0x00081010, 'Station Name', VR.kSH, VM.k1, false);
  static const PTag kStudyDescription
      //(0008,1030)
      = const PTag._(
          'StudyDescription', 0x00081030, 'Study Description', VR.kLO, VM.k1, false);
  static const PTag kProcedureCodeSequence
      //(0008,1032)
      = const PTag._('ProcedureCodeSequence', 0x00081032, 'Procedure Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSeriesDescription
      //(0008,103E)
      = const PTag._(
          'SeriesDescription', 0x0008103E, 'Series Description', VR.kLO, VM.k1, false);
  static const PTag kSeriesDescriptionCodeSequence
      //(0008,103F)
      = const PTag._('SeriesDescriptionCodeSequence', 0x0008103F,
          'Series Description Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kInstitutionalDepartmentName
      //(0008,1040)
      = const PTag._('InstitutionalDepartmentName', 0x00081040,
          'Institutional Department Name', VR.kLO, VM.k1, false);
  static const PTag kPhysiciansOfRecord
      //(0008,1048)
      = const PTag._('PhysiciansOfRecord', 0x00081048, 'Physician(s) of Record', VR.kPN,
          VM.k1_n, false);
  static const PTag kPhysiciansOfRecordIdentificationSequence
      //(0008,1049)
      = const PTag._('PhysiciansOfRecordIdentificationSequence', 0x00081049,
          'Physician(s) of Record Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformingPhysicianName
      //(0008,1050)
      = const PTag._('PerformingPhysicianName', 0x00081050,
          'Performing Physician\'s Name', VR.kPN, VM.k1_n, false);
  static const PTag kPerformingPhysicianIdentificationSequence
      //(0008,1052)
      = const PTag._('PerformingPhysicianIdentificationSequence', 0x00081052,
          'Performing Physician Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNameOfPhysiciansReadingStudy
      //(0008,1060)
      = const PTag._('NameOfPhysiciansReadingStudy', 0x00081060,
          'Name of Physician(s) Reading Study', VR.kPN, VM.k1_n, false);
  static const PTag kPhysiciansReadingStudyIdentificationSequence
      //(0008,1062)
      = const PTag._('PhysiciansReadingStudyIdentificationSequence', 0x00081062,
          'Physician(s) Reading Study Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOperatorsName
      //(0008,1070)
      = const PTag._(
          'OperatorsName', 0x00081070, 'Operators\' Name', VR.kPN, VM.k1_n, false);
  static const PTag kOperatorIdentificationSequence
      //(0008,1072)
      = const PTag._('OperatorIdentificationSequence', 0x00081072,
          'Operator Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAdmittingDiagnosesDescription
      //(0008,1080)
      = const PTag._('AdmittingDiagnosesDescription', 0x00081080,
          'Admitting Diagnoses Description', VR.kLO, VM.k1_n, false);
  static const PTag kAdmittingDiagnosesCodeSequence
      //(0008,1084)
      = const PTag._('AdmittingDiagnosesCodeSequence', 0x00081084,
          'Admitting Diagnoses Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kManufacturerModelName
      //(0008,1090)
      = const PTag._('ManufacturerModelName', 0x00081090, 'Manufacturer\'s Model Name',
          VR.kLO, VM.k1, false);
  static const PTag kReferencedResultsSequence
      //(0008,1100)
      = const PTag._('ReferencedResultsSequence', 0x00081100,
          'Referenced Results Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedStudySequence
      //(0008,1110)
      = const PTag._('ReferencedStudySequence', 0x00081110, 'Referenced Study Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedPerformedProcedureStepSequence
      //(0008,1111)
      = const PTag._('ReferencedPerformedProcedureStepSequence', 0x00081111,
          'Referenced Performed Procedure Step Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSeriesSequence
      //(0008,1115)
      = const PTag._('ReferencedSeriesSequence', 0x00081115, 'Referenced Series Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedPatientSequence
      //(0008,1120)
      = const PTag._('ReferencedPatientSequence', 0x00081120,
          'Referenced Patient Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedVisitSequence
      //(0008,1125)
      = const PTag._('ReferencedVisitSequence', 0x00081125, 'Referenced Visit Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedOverlaySequence
      //(0008,1130)
      = const PTag._('ReferencedOverlaySequence', 0x00081130,
          'Referenced Overlay Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedStereometricInstanceSequence
      //(0008,1134)
      = const PTag._('ReferencedStereometricInstanceSequence', 0x00081134,
          'Referenced Stereometric Instance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedWaveformSequence
      //(0008,113A)
      = const PTag._('ReferencedWaveformSequence', 0x0008113A,
          'Referenced Waveform Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedImageSequence
      //(0008,1140)
      = const PTag._('ReferencedImageSequence', 0x00081140, 'Referenced Image Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedCurveSequence
      //(0008,1145)
      = const PTag._('ReferencedCurveSequence', 0x00081145, 'Referenced Curve Sequence',
          VR.kSQ, VM.k1, true);
  static const PTag kReferencedInstanceSequence
      //(0008,114A)
      = const PTag._('ReferencedInstanceSequence', 0x0008114A,
          'Referenced Instance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedRealWorldValueMappingInstanceSequence
      //(0008,114B)
      = const PTag._('ReferencedRealWorldValueMappingInstanceSequence', 0x0008114B,
          'Referenced Real World Value Mapping Instance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSOPClassUID
      //(0008,1150)
      = const PTag._('ReferencedSOPClassUID', 0x00081150, 'Referenced SOP Class UID',
          VR.kUI, VM.k1, false);
  static const PTag kReferencedSOPInstanceUID
      //(0008,1155)
      = const PTag._('ReferencedSOPInstanceUID', 0x00081155,
          'Referenced SOP Instance UID', VR.kUI, VM.k1, false);
  static const PTag kSOPClassesSupported
      //(0008,115A)
      = const PTag._('SOPClassesSupported', 0x0008115A, 'SOP Classes Supported', VR.kUI,
          VM.k1_n, false);
  static const PTag kReferencedFrameNumber
      //(0008,1160)
      = const PTag._('ReferencedFrameNumber', 0x00081160, 'Referenced Frame Number',
          VR.kIS, VM.k1_n, false);
  static const PTag kSimpleFrameList
      //(0008,1161)
      = const PTag._(
          'SimpleFrameList', 0x00081161, 'Simple Frame List', VR.kUL, VM.k1_n, false);
  static const PTag kCalculatedFrameList
      //(0008,1162)
      = const PTag._('CalculatedFrameList', 0x00081162, 'Calculated Frame List', VR.kUL,
          VM.k3_3n, false);
  static const PTag kTimeRange
      //(0008,1163)
      = const PTag._('TimeRange', 0x00081163, 'TimeRange', VR.kFD, VM.k2, false);
  static const PTag kFrameExtractionSequence
      //(0008,1164)
      = const PTag._('FrameExtractionSequence', 0x00081164, 'Frame Extraction Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kMultiFrameSourceSOPInstanceUID
      //(0008,1167)
      = const PTag._('MultiFrameSourceSOPInstanceUID', 0x00081167,
          'Multi-frame Source SOP Instance UID', VR.kUI, VM.k1, false);
  static const PTag kRetrieveURL
      //(0008,1190)
      = const PTag._('RetrieveURL', 0x00081190, 'Retrieve URL', VR.kUR, VM.k1, false);
  static const PTag kTransactionUID
      //(0008,1195)
      =
      const PTag._('TransactionUID', 0x00081195, 'Transaction UID', VR.kUI, VM.k1, false);
  static const PTag kWarningReason
      //(0008,1196)
      = const PTag._('WarningReason', 0x00081196, 'Warning Reason', VR.kUS, VM.k1, false);
  static const PTag kFailureReason
      //(0008,1197)
      = const PTag._('FailureReason', 0x00081197, 'Failure Reason', VR.kUS, VM.k1, false);
  static const PTag kFailedSOPSequence
      //(0008,1198)
      = const PTag._(
          'FailedSOPSequence', 0x00081198, 'Failed SOP Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSOPSequence
      //(0008,1199)
      = const PTag._('ReferencedSOPSequence', 0x00081199, 'Referenced SOP Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kStudiesContainingOtherReferencedInstancesSequence
      //(0008,1200)
      = const PTag._('StudiesContainingOtherReferencedInstancesSequence', 0x00081200,
          'Studies Containing Other Referenced Instances Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRelatedSeriesSequence
      //(0008,1250)
      = const PTag._('RelatedSeriesSequence', 0x00081250, 'Related Series Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kLossyImageCompressionRetired
      //(0008,2110)
      = const PTag._('LossyImageCompressionRetired', 0x00082110,
          'Lossy Image Compression (Retired)', VR.kCS, VM.k1, true);
  static const PTag kDerivationDescription
      //(0008,2111)
      = const PTag._('DerivationDescription', 0x00082111, 'Derivation Description',
          VR.kST, VM.k1, false);
  static const PTag kSourceImageSequence
      //(0008,2112)
      = const PTag._('SourceImageSequence', 0x00082112, 'Source Image Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kStageName
      //(0008,2120)
      = const PTag._('StageName', 0x00082120, 'Stage Name', VR.kSH, VM.k1, false);
  static const PTag kStageNumber
      //(0008,2122)
      = const PTag._('StageNumber', 0x00082122, 'Stage Number', VR.kIS, VM.k1, false);
  static const PTag kNumberOfStages
      //(0008,2124)
      = const PTag._(
          'NumberOfStages', 0x00082124, 'Number of Stages', VR.kIS, VM.k1, false);
  static const PTag kViewName
      //(0008,2127)
      = const PTag._('ViewName', 0x00082127, 'View Name', VR.kSH, VM.k1, false);
  static const PTag kViewNumber
      //(0008,2128)
      = const PTag._('ViewNumber', 0x00082128, 'View Number', VR.kIS, VM.k1, false);
  static const PTag kNumberOfEventTimers
      //(0008,2129)
      = const PTag._('NumberOfEventTimers', 0x00082129, 'Number of Event Timers', VR.kIS,
          VM.k1, false);
  static const PTag kNumberOfViewsInStage
      //(0008,212A)
      = const PTag._('NumberOfViewsInStage', 0x0008212A, 'Number of Views in Stage',
          VR.kIS, VM.k1, false);
  static const PTag kEventElapsedTimes
      //(0008,2130)
      = const PTag._('EventElapsedTimes', 0x00082130, 'Event Elapsed Time(s)', VR.kDS,
          VM.k1_n, false);
  static const PTag kEventTimerNames
      //(0008,2132)
      = const PTag._(
          'EventTimerNames', 0x00082132, 'Event Timer Name(s)', VR.kLO, VM.k1_n, false);
  static const PTag kEventTimerSequence
      //(0008,2133)
      = const PTag._(
          'EventTimerSequence', 0x00082133, 'Event Timer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEventTimeOffset
      //(0008,2134)
      = const PTag._(
          'EventTimeOffset', 0x00082134, 'Event Time Offset', VR.kFD, VM.k1, false);
  static const PTag kEventCodeSequence
      //(0008,2135)
      = const PTag._(
          'EventCodeSequence', 0x00082135, 'Event Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStartTrim
      //(0008,2142)
      = const PTag._('StartTrim', 0x00082142, 'Start Trim', VR.kIS, VM.k1, false);
  static const PTag kStopTrim
      //(0008,2143)
      = const PTag._('StopTrim', 0x00082143, 'Stop Trim', VR.kIS, VM.k1, false);
  static const PTag kRecommendedDisplayFrameRate
      //(0008,2144)
      = const PTag._('RecommendedDisplayFrameRate', 0x00082144,
          'Recommended Display Frame Rate', VR.kIS, VM.k1, false);
  static const PTag kTransducerPosition
      //(0008,2200)
      = const PTag._(
          'TransducerPosition', 0x00082200, 'Transducer Position', VR.kCS, VM.k1, true);
  static const PTag kTransducerOrientation
      //(0008,2204)
      = const PTag._('TransducerOrientation', 0x00082204, 'Transducer Orientation',
          VR.kCS, VM.k1, true);
  static const PTag kAnatomicStructure
      //(0008,2208)
      = const PTag._(
          'AnatomicStructure', 0x00082208, 'Anatomic Structure', VR.kCS, VM.k1, true);
  static const PTag kAnatomicRegionSequence
      //(0008,2218)
      = const PTag._('AnatomicRegionSequence', 0x00082218, 'Anatomic Region Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kAnatomicRegionModifierSequence
      //(0008,2220)
      = const PTag._('AnatomicRegionModifierSequence', 0x00082220,
          'Anatomic Region Modifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrimaryAnatomicStructureSequence
      //(0008,2228)
      = const PTag._('PrimaryAnatomicStructureSequence', 0x00082228,
          'Primary Anatomic Structure Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAnatomicStructureSpaceOrRegionSequence
      //(0008,2229)
      = const PTag._('AnatomicStructureSpaceOrRegionSequence', 0x00082229,
          'Anatomic Structure: Space or Region Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrimaryAnatomicStructureModifierSequence
      //(0008,2230)
      = const PTag._('PrimaryAnatomicStructureModifierSequence', 0x00082230,
          'Primary Anatomic Structure Modifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTransducerPositionSequence
      //(0008,2240)
      = const PTag._('TransducerPositionSequence', 0x00082240,
          'Transducer Position Sequence', VR.kSQ, VM.k1, true);
  static const PTag kTransducerPositionModifierSequence
      //(0008,2242)
      = const PTag._('TransducerPositionModifierSequence', 0x00082242,
          'Transducer Position Modifier Sequence', VR.kSQ, VM.k1, true);
  static const PTag kTransducerOrientationSequence
      //(0008,2244)
      = const PTag._('TransducerOrientationSequence', 0x00082244,
          'Transducer Orientation Sequence', VR.kSQ, VM.k1, true);
  static const PTag kTransducerOrientationModifierSequence
      //(0008,2246)
      = const PTag._('TransducerOrientationModifierSequence', 0x00082246,
          'Transducer Orientation Modifier Sequence', VR.kSQ, VM.k1, true);
  static const PTag kAnatomicStructureSpaceOrRegionCodeSequenceTrial
      //(0008,2251)
      = const PTag._(
          'AnatomicStructureSpaceOrRegionCodeSequenceTrial',
          0x00082251,
          'Anatomic Structure Space Or Region Code Sequence (Trial)',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kAnatomicPortalOfEntranceCodeSequenceTrial
      //(0008,2253)
      = const PTag._('AnatomicPortalOfEntranceCodeSequenceTrial', 0x00082253,
          'Anatomic Portal Of Entrance Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kAnatomicApproachDirectionCodeSequenceTrial
      //(0008,2255)
      = const PTag._('AnatomicApproachDirectionCodeSequenceTrial', 0x00082255,
          'Anatomic Approach Direction Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kAnatomicPerspectiveDescriptionTrial
      //(0008,2256)
      = const PTag._('AnatomicPerspectiveDescriptionTrial', 0x00082256,
          'Anatomic Perspective Description (Trial)', VR.kST, VM.k1, true);
  static const PTag kAnatomicPerspectiveCodeSequenceTrial
      //(0008,2257)
      = const PTag._('AnatomicPerspectiveCodeSequenceTrial', 0x00082257,
          'Anatomic Perspective Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kAnatomicLocationOfExaminingInstrumentDescriptionTrial
      //(0008,2258)
      = const PTag._(
          'AnatomicLocationOfExaminingInstrumentDescriptionTrial',
          0x00082258,
          'Anatomic Location Of Examining Instrument Description (Trial)',
          VR.kST,
          VM.k1,
          true);
  static const PTag kAnatomicLocationOfExaminingInstrumentCodeSequenceTrial
      //(0008,2259)
      = const PTag._(
          'AnatomicLocationOfExaminingInstrumentCodeSequenceTrial',
          0x00082259,
          'Anatomic Location Of Examining Instrument Code Sequence (Trial)',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kAnatomicStructureSpaceOrRegionModifierCodeSequenceTrial
      //(0008,225A)
      = const PTag._(
          'AnatomicStructureSpaceOrRegionModifierCodeSequenceTrial',
          0x0008225A,
          'Anatomic Structure Space Or Region Modifier Code Sequence (Trial)',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kOnAxisBackgroundAnatomicStructureCodeSequenceTrial
      //(0008,225C)
      = const PTag._(
          'OnAxisBackgroundAnatomicStructureCodeSequenceTrial',
          0x0008225C,
          'OnAxis Background Anatomic Structure Code Sequence (Trial)',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kAlternateRepresentationSequence
      //(0008,3001)
      = const PTag._('AlternateRepresentationSequence', 0x00083001,
          'Alternate Representation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIrradiationEventUID
      //(0008,3010)
      = const PTag._('IrradiationEventUID', 0x00083010, 'Irradiation Event UID', VR.kUI,
          VM.k1_n, false);
  static const PTag kIdentifyingComments
      //(0008,4000)
      = const PTag._(
          'IdentifyingComments', 0x00084000, 'Identifying Comments', VR.kLT, VM.k1, true);
  static const PTag kFrameType
      //(0008,9007)
      = const PTag._('FrameType', 0x00089007, 'Frame Type', VR.kCS, VM.k4, false);
  static const PTag kReferencedImageEvidenceSequence
      //(0008,9092)
      = const PTag._('ReferencedImageEvidenceSequence', 0x00089092,
          'Referenced Image Evidence Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedRawDataSequence
      //(0008,9121)
      = const PTag._('ReferencedRawDataSequence', 0x00089121,
          'Referenced Raw Data Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCreatorVersionUID
      //(0008,9123)
      = const PTag._(
          'CreatorVersionUID', 0x00089123, 'Creator-Version UID', VR.kUI, VM.k1, false);
  static const PTag kDerivationImageSequence
      //(0008,9124)
      = const PTag._('DerivationImageSequence', 0x00089124, 'Derivation Image Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSourceImageEvidenceSequence
      //(0008,9154)
      = const PTag._('SourceImageEvidenceSequence', 0x00089154,
          'Source Image Evidence Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPixelPresentation
      //(0008,9205)
      = const PTag._(
          'PixelPresentation', 0x00089205, 'Pixel Presentation', VR.kCS, VM.k1, false);
  static const PTag kVolumetricProperties
      //(0008,9206)
      = const PTag._('VolumetricProperties', 0x00089206, 'Volumetric Properties', VR.kCS,
          VM.k1, false);
  static const PTag kVolumeBasedCalculationTechnique
      //(0008,9207)
      = const PTag._('VolumeBasedCalculationTechnique', 0x00089207,
          'Volume Based Calculation Technique', VR.kCS, VM.k1, false);
  static const PTag kComplexImageComponent
      //(0008,9208)
      = const PTag._('ComplexImageComponent', 0x00089208, 'Complex Image Component',
          VR.kCS, VM.k1, false);
  static const PTag kAcquisitionContrast
      //(0008,9209)
      = const PTag._('AcquisitionContrast', 0x00089209, 'Acquisition Contrast', VR.kCS,
          VM.k1, false);
  static const PTag kDerivationCodeSequence
      //(0008,9215)
      = const PTag._('DerivationCodeSequence', 0x00089215, 'Derivation Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedPresentationStateSequence
      //(0008,9237)
      = const PTag._('ReferencedPresentationStateSequence', 0x00089237,
          'Referenced Presentation State Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedOtherPlaneSequence
      //(0008,9410)
      = const PTag._('ReferencedOtherPlaneSequence', 0x00089410,
          'Referenced Other Plane Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFrameDisplaySequence
      //(0008,9458)
      = const PTag._('FrameDisplaySequence', 0x00089458, 'Frame Display Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kRecommendedDisplayFrameRateInFloat
      //(0008,9459)
      = const PTag._('RecommendedDisplayFrameRateInFloat', 0x00089459,
          'Recommended Display Frame Rate in Float', VR.kFL, VM.k1, false);
  static const PTag kSkipFrameRangeFlag
      //(0008,9460)
      = const PTag._('SkipFrameRangeFlag', 0x00089460, 'Skip Frame Range Flag', VR.kCS,
          VM.k1, false);
  static const PTag kPatientName
      //(0010,0010)
      = const PTag._('PatientName', 0x00100010, 'Patient\'s Name', VR.kPN, VM.k1, false);
  static const PTag kPatientID
      //(0010,0020)
      = const PTag._('PatientID', 0x00100020, 'Patient ID', VR.kLO, VM.k1, false);
  static const PTag kIssuerOfPatientID
      //(0010,0021)
      = const PTag._(
          'IssuerOfPatientID', 0x00100021, 'Issuer of Patient ID', VR.kLO, VM.k1, false);
  static const PTag kTypeOfPatientID
      //(0010,0022)
      = const PTag._(
          'TypeOfPatientID', 0x00100022, 'Type of Patient ID', VR.kCS, VM.k1, false);
  static const PTag kIssuerOfPatientIDQualifiersSequence
      //(0010,0024)
      = const PTag._('IssuerOfPatientIDQualifiersSequence', 0x00100024,
          'Issuer of Patient ID Qualifiers Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourcePatientGroupIdentificationSequence = const PTag._(
      'SourcePatientGroupIdentificationSequence',
      0x00100026,
      'Source Patient Group Identification Sequence',
      VR.kSQ,
      VM.k1,
      false);
  static const PTag kGroupOfPatientsIdentificationSequence
      //(0010,0027
      = const PTag._('GroupOfPatientsIdentificationSequence', 0x00100027,
          'Group of Patients Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSubjectRelativePositionInImage
      // (0010,0028)
      = const PTag._('SubjectRelativePositionInImage', 0x00100028,
          'Subject Relative Position in Image', VR.kUS, VM.k3, false);
  static const PTag kPatientBirthDate
      //(0010,0030)
      = const PTag._(
          'PatientBirthDate', 0x00100030, 'Patient\'s Birth Date', VR.kDA, VM.k1, false);
  static const PTag kPatientBirthTime
      //(0010,0032)
      = const PTag._(
          'PatientBirthTime', 0x00100032, 'Patient\'s Birth Time', VR.kTM, VM.k1, false);
  static const PTag kPatientSex
      //(0010,0040)
      = const PTag._('PatientSex', 0x00100040, 'Patient\'s Sex', VR.kCS, VM.k1, false);
  static const PTag kPatientInsurancePlanCodeSequence
      //(0010,0050)
      = const PTag._('PatientInsurancePlanCodeSequence', 0x00100050,
          'Patient\'s Insurance Plan Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientPrimaryLanguageCodeSequence
      //(0010,0101)
      = const PTag._('PatientPrimaryLanguageCodeSequence', 0x00100101,
          'Patient\'s Primary Language Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientPrimaryLanguageModifierCodeSequence
      //(0010,0102)
      = const PTag._('PatientPrimaryLanguageModifierCodeSequence', 0x00100102,
          'Patient\'s Primary Language Modifier Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kQualityControlSubject
      //(0010,0200)
      = const PTag._('QualityControlSubject', 0x00100200, 'Quality Control Subject',
          VR.kCS, VM.k1, false);
  static const PTag kQualityControlSubjectTypeCodeSequence
      //(0010,0201)
      = const PTag._('QualityControlSubjectTypeCodeSequence', 0x00100201,
          'Quality Control Subject Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStrainDescription
      //(0010,0212)
      = const PTag._(
          'StrainDescription', 0x00100212, 'Strain Description', VR.kUC, VM.k1, false);
  static const PTag kStrainNomenclature
      //(0010,0213)
      = const PTag._(
          'StrainNomenclature', 0x00100213, 'Strain​Nomenclature', VR.kLO, VM.k1, false);
  static const PTag kStrainStockNumber
      //(0010,0214)
      = const PTag._(
          'StrainStockNumber', 0x00100214, 'Strain​Stock​Number', VR.kLO, VM.k1, false);
  static const PTag kStrainSourceRegistryCodeSequence
      //(0010,0215)
      = const PTag._('StrainSourceRegistryCodeSequence', 0x00100215,
          'Strain Source Registry Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStrainStockSequence
      //(0010,0216)
      = const PTag._('StrainStockSequence', 0x00100216, 'Strain Stock Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kStrainSource
      //(0010,0217)
      = const PTag._('StrainSource', 0x00100217, 'Strain Source', VR.kLO, VM.k1, false);
  static const PTag kStrainAdditionalInformation
      //(0010,0218)
      = const PTag._('StrainAdditionalInformation', 0x00100218,
          'Strain Additional Information', VR.kUT, VM.k1, false);
  static const PTag kStrainCodeSequence
      //(0010,0219)
      = const PTag._(
          'StrainCodeSequence', 0x00100219, 'Strain Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGeneticModificationsSequence
      //(0010,0221)
      = const PTag._('GeneticModificationsSequence', 0x00100221,
          'Genetic Modifications Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGeneticModificationsDescription
      //(0010,0222)
      = const PTag._('GeneticModificationsDescription', 0x00100222,
          'Genetic Modifications Description', VR.kUC, VM.k1, false);
  static const PTag kGeneticModificationsNomenclature
      //(0010,0223)
      = const PTag._('GeneticModificationsNomenclature', 0x00100223,
          'Genetic Modifications Nomenclature', VR.kLO, VM.k1, false);
  static const PTag kGeneticModificationsCodeSequence
      //(0010,0219)
      = const PTag._('GeneticModificationsCodeSequence', 0x00100229,
          'Genetic Modifications Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOtherPatientIDs
      //(0010,1000)
      = const PTag._(
          'OtherPatientIDs', 0x00101000, 'Other Patient IDs', VR.kLO, VM.k1_n, false);
  static const PTag kOtherPatientNames
      //(0010,1001)
      = const PTag._(
          'OtherPatientNames', 0x00101001, 'Other Patient Names', VR.kPN, VM.k1_n, false);
  static const PTag kOtherPatientIDsSequence
      //(0010,1002)
      = const PTag._('OtherPatientIDsSequence', 0x00101002, 'Other Patient IDs Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPatientBirthName
      //(0010,1005)
      = const PTag._(
          'PatientBirthName', 0x00101005, 'Patient\'s Birth Name', VR.kPN, VM.k1, false);
  static const PTag kPatientAge
      //(0010,1010)
      = const PTag._('PatientAge', 0x00101010, 'Patient\'s Age', VR.kAS, VM.k1, false);
  static const PTag kPatientSize
      //(0010,1020)
      = const PTag._('PatientSize', 0x00101020, 'Patient\'s Size', VR.kDS, VM.k1, false);
  static const PTag kPatientSizeCodeSequence
      //(0010,1021)
      = const PTag._('PatientSizeCodeSequence', 0x00101021,
          'Patient\'s Size Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientWeight
      //(0010,1030)
      = const PTag._(
          'PatientWeight', 0x00101030, 'Patient\'s Weight', VR.kDS, VM.k1, false);
  static const PTag kPatientAddress
      //(0010,1040)
      = const PTag._(
          'PatientAddress', 0x00101040, 'Patient\'s Address', VR.kLO, VM.k1, false);
  static const PTag kInsurancePlanIdentification
      //(0010,1050)
      = const PTag._('InsurancePlanIdentification', 0x00101050,
          'Insurance Plan Identification', VR.kLO, VM.k1_n, true);
  static const PTag kPatientMotherBirthName
      //(0010,1060)
      = const PTag._('PatientMotherBirthName', 0x00101060,
          'Patient\'s Mother\'s Birth Name', VR.kPN, VM.k1, false);
  static const PTag kMilitaryRank
      //(0010,1080)
      = const PTag._('MilitaryRank', 0x00101080, 'Military Rank', VR.kLO, VM.k1, false);
  static const PTag kBranchOfService
      //(0010,1081)
      = const PTag._(
          'BranchOfService', 0x00101081, 'Branch of Service', VR.kLO, VM.k1, false);
  static const PTag kMedicalRecordLocator
      //(0010,1090)
      = const PTag._('MedicalRecordLocator', 0x00101090, 'Medical Record Locator', VR.kLO,
          VM.k1, false);
  static const PTag kReferencedPatientPhotoSequence = const PTag._(
      // (0010,1100)
      'ReferencedPatientPhotoSequence',
      0x00101100,
      'Referenced Patient Photo Sequence',
      VR.kSQ,
      VM.k1,
      false);
  static const PTag kMedicalAlerts
      //(0010,2000)
      =
      const PTag._('MedicalAlerts', 0x00102000, 'Medical Alerts', VR.kLO, VM.k1_n, false);
  static const PTag kAllergies
      //(0010,2110)
      = const PTag._('Allergies', 0x00102110, 'Allergies', VR.kLO, VM.k1_n, false);
  static const PTag kCountryOfResidence
      //(0010,2150)
      = const PTag._(
          'CountryOfResidence', 0x00102150, 'Country of Residence', VR.kLO, VM.k1, false);
  static const PTag kRegionOfResidence
      //(0010,2152)
      = const PTag._(
          'RegionOfResidence', 0x00102152, 'Region of Residence', VR.kLO, VM.k1, false);
  static const PTag kPatientTelephoneNumbers
      //(0010,2154)
      = const PTag._('PatientTelephoneNumbers', 0x00102154,
          'Patient\'s Telephone Numbers', VR.kSH, VM.k1_n, false);
  static const PTag kEthnicGroup
      //(0010,2160)
      = const PTag._('EthnicGroup', 0x00102160, 'Ethnic Group', VR.kSH, VM.k1, false);
  static const PTag kOccupation
      //(0010,2180)
      = const PTag._('Occupation', 0x00102180, 'Occupation', VR.kSH, VM.k1, false);
  static const PTag kSmokingStatus
      //(0010,21A0)
      = const PTag._('SmokingStatus', 0x001021A0, 'Smoking Status', VR.kCS, VM.k1, false);
  static const PTag kAdditionalPatientHistory
      //(0010,21B0)
      = const PTag._('AdditionalPatientHistory', 0x001021B0, 'Additional Patient History',
          VR.kLT, VM.k1, false);
  static const PTag kPregnancyStatus
      //(0010,21C0)
      = const PTag._(
          'PregnancyStatus', 0x001021C0, 'Pregnancy Status', VR.kUS, VM.k1, false);
  static const PTag kLastMenstrualDate
      //(0010,21D0)
      = const PTag._(
          'LastMenstrualDate', 0x001021D0, 'Last Menstrual Date', VR.kDA, VM.k1, false);
  static const PTag kPatientReligiousPreference
      //(0010,21F0)
      = const PTag._('PatientReligiousPreference', 0x001021F0,
          'Patient\'s Religious Preference', VR.kLO, VM.k1, false);
  static const PTag kPatientSpeciesDescription
      //(0010,2201)
      = const PTag._('PatientSpeciesDescription', 0x00102201,
          'Patient Species Description', VR.kLO, VM.k1, false);
  static const PTag kPatientSpeciesCodeSequence
      //(0010,2202)
      = const PTag._('PatientSpeciesCodeSequence', 0x00102202,
          'Patient Species Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientSexNeutered
      //(0010,2203)
      = const PTag._('PatientSexNeutered', 0x00102203, 'Patient\'s Sex Neutered', VR.kCS,
          VM.k1, false);
  static const PTag kAnatomicalOrientationType
      //(0010,2210)
      = const PTag._('AnatomicalOrientationType', 0x00102210,
          'Anatomical Orientation Type', VR.kCS, VM.k1, false);
  static const PTag kPatientBreedDescription
      //(0010,2292)
      = const PTag._('PatientBreedDescription', 0x00102292, 'Patient Breed Description',
          VR.kLO, VM.k1, false);
  static const PTag kPatientBreedCodeSequence
      //(0010,2293)
      = const PTag._('PatientBreedCodeSequence', 0x00102293,
          'Patient Breed Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBreedRegistrationSequence
      //(0010,2294)
      = const PTag._('BreedRegistrationSequence', 0x00102294,
          'Breed Registration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBreedRegistrationNumber
      //(0010,2295)
      = const PTag._('BreedRegistrationNumber', 0x00102295, 'Breed Registration Number',
          VR.kLO, VM.k1, false);
  static const PTag kBreedRegistryCodeSequence
      //(0010,2296)
      = const PTag._('BreedRegistryCodeSequence', 0x00102296,
          'Breed Registry Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kResponsiblePerson
      //(0010,2297)
      = const PTag._(
          'ResponsiblePerson', 0x00102297, 'Responsible Person', VR.kPN, VM.k1, false);
  static const PTag kResponsiblePersonRole
      //(0010,2298)
      = const PTag._('ResponsiblePersonRole', 0x00102298, 'Responsible Person Role',
          VR.kCS, VM.k1, false);
  static const PTag kResponsibleOrganization
      //(0010,2299)
      = const PTag._('ResponsibleOrganization', 0x00102299, 'Responsible Organization',
          VR.kLO, VM.k1, false);
  static const PTag kPatientComments
      //(0010,4000)
      = const PTag._(
          'PatientComments', 0x00104000, 'Patient Comments', VR.kLT, VM.k1, false);
  static const PTag kExaminedBodyThickness
      //(0010,9431)
      = const PTag._('ExaminedBodyThickness', 0x00109431, 'Examined Body Thickness',
          VR.kFL, VM.k1, false);
  static const PTag kClinicalTrialSponsorName
      //(0012,0010)
      = const PTag._('ClinicalTrialSponsorName', 0x00120010,
          'Clinical Trial Sponsor Name', VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialProtocolID
      //(0012,0020)
      = const PTag._('ClinicalTrialProtocolID', 0x00120020, 'Clinical Trial Protocol ID',
          VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialProtocolName
      //(0012,0021)
      = const PTag._('ClinicalTrialProtocolName', 0x00120021,
          'Clinical Trial Protocol Name', VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialSiteID
      //(0012,0030)
      = const PTag._('ClinicalTrialSiteID', 0x00120030, 'Clinical Trial Site ID', VR.kLO,
          VM.k1, false);
  static const PTag kClinicalTrialSiteName
      //(0012,0031)
      = const PTag._('ClinicalTrialSiteName', 0x00120031, 'Clinical Trial Site Name',
          VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialSubjectID
      //(0012,0040)
      = const PTag._('ClinicalTrialSubjectID', 0x00120040, 'Clinical Trial Subject ID',
          VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialSubjectReadingID
      //(0012,0042)
      = const PTag._('ClinicalTrialSubjectReadingID', 0x00120042,
          'Clinical Trial Subject Reading ID', VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialTimePointID
      //(0012,0050)
      = const PTag._('ClinicalTrialTimePointID', 0x00120050,
          'Clinical Trial Time Point ID', VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialTimePointDescription
      //(0012,0051)
      = const PTag._('ClinicalTrialTimePointDescription', 0x00120051,
          'Clinical Trial Time Point Description', VR.kST, VM.k1, false);
  static const PTag kClinicalTrialCoordinatingCenterName
      //(0012,0060)
      = const PTag._('ClinicalTrialCoordinatingCenterName', 0x00120060,
          'Clinical Trial Coordinating Center Name', VR.kLO, VM.k1, false);
  static const PTag kPatientIdentityRemoved
      //(0012,0062)
      = const PTag._('PatientIdentityRemoved', 0x00120062, 'Patient Identity Removed',
          VR.kCS, VM.k1, false);
  static const PTag kDeidentificationMethod
      //(0012,0063)
      = const PTag._('DeidentificationMethod', 0x00120063, 'De-identification Method',
          VR.kLO, VM.k1_n, false);
  static const PTag kDeidentificationMethodCodeSequence
      //(0012,0064)
      = const PTag._('DeidentificationMethodCodeSequence', 0x00120064,
          'De-identification Method Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kClinicalTrialSeriesID
      //(0012,0071)
      = const PTag._('ClinicalTrialSeriesID', 0x00120071, 'Clinical Trial Series ID',
          VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialSeriesDescription
      //(0012,0072)
      = const PTag._('ClinicalTrialSeriesDescription', 0x00120072,
          'Clinical Trial Series Description', VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialProtocolEthicsCommitteeName
      //(0012,0081)
      = const PTag._('ClinicalTrialProtocolEthicsCommitteeName', 0x00120081,
          'Clinical Trial Protocol Ethics Committee Name', VR.kLO, VM.k1, false);
  static const PTag kClinicalTrialProtocolEthicsCommitteeApprovalNumber
      //(0012,0082)
      = const PTag._(
          'ClinicalTrialProtocolEthicsCommitteeApprovalNumber',
          0x00120082,
          'Clinical Trial Protocol Ethics Committee Approval Number',
          VR.kLO,
          VM.k1,
          false);
  static const PTag kConsentForClinicalTrialUseSequence
      //(0012,0083)
      = const PTag._('ConsentForClinicalTrialUseSequence', 0x00120083,
          'Consent for Clinical Trial Use Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDistributionType
      //(0012,0084)
      = const PTag._(
          'DistributionType', 0x00120084, 'Distribution Type', VR.kCS, VM.k1, false);
  static const PTag kConsentForDistributionFlag
      //(0012,0085)
      = const PTag._('ConsentForDistributionFlag', 0x00120085,
          'Consent for Distribution Flag', VR.kCS, VM.k1, false);
  static const PTag kCADFileFormat
      //(0014,0023)
      =
      const PTag._('CADFileFormat', 0x00140023, 'CAD File Format', VR.kST, VM.k1_n, true);
  static const PTag kComponentReferenceSystem
      //(0014,0024)
      = const PTag._('ComponentReferenceSystem', 0x00140024, 'Component Reference System',
          VR.kST, VM.k1_n, true);
  static const PTag kComponentManufacturingProcedure
      //(0014,0025)
      = const PTag._('ComponentManufacturingProcedure', 0x00140025,
          'Component Manufacturing Procedure', VR.kST, VM.k1_n, false);
  static const PTag kComponentManufacturer
      //(0014,0028)
      = const PTag._('ComponentManufacturer', 0x00140028, 'Component Manufacturer',
          VR.kST, VM.k1_n, false);
  static const PTag kMaterialThickness
      //(0014,0030)
      = const PTag._(
          'MaterialThickness', 0x00140030, 'Material Thickness', VR.kDS, VM.k1_n, false);
  static const PTag kMaterialPipeDiameter
      //(0014,0032)
      = const PTag._('MaterialPipeDiameter', 0x00140032, 'Material Pipe Diameter', VR.kDS,
          VM.k1_n, false);
  static const PTag kMaterialIsolationDiameter
      //(0014,0034)
      = const PTag._('MaterialIsolationDiameter', 0x00140034,
          'Material Isolation Diameter', VR.kDS, VM.k1_n, false);
  static const PTag kMaterialGrade
      //(0014,0042)
      =
      const PTag._('MaterialGrade', 0x00140042, 'Material Grade', VR.kST, VM.k1_n, false);
  static const PTag kMaterialPropertiesDescription
      //(0014,0044)
      = const PTag._('MaterialPropertiesDescription', 0x00140044,
          'Material Properties Description', VR.kST, VM.k1_n, false);
  static const PTag kMaterialPropertiesFileFormatRetired
      //(0014,0045)
      = const PTag._('MaterialPropertiesFileFormatRetired', 0x00140045,
          'Material Properties File Format (Retired)', VR.kST, VM.k1_n, true);
  static const PTag kMaterialNotes
      //(0014,0046)
      = const PTag._('MaterialNotes', 0x00140046, 'Material Notes', VR.kLT, VM.k1, false);
  static const PTag kComponentShape
      //(0014,0050)
      =
      const PTag._('ComponentShape', 0x00140050, 'Component Shape', VR.kCS, VM.k1, false);
  static const PTag kCurvatureType
      //(0014,0052)
      = const PTag._('CurvatureType', 0x00140052, 'Curvature Type', VR.kCS, VM.k1, false);
  static const PTag kOuterDiameter
      //(0014,0054)
      = const PTag._('OuterDiameter', 0x00140054, 'Outer Diameter', VR.kDS, VM.k1, false);
  static const PTag kInnerDiameter
      //(0014,0056)
      = const PTag._('InnerDiameter', 0x00140056, 'Inner Diameter', VR.kDS, VM.k1, false);
  static const PTag kActualEnvironmentalConditions
      //(0014,1010)
      = const PTag._('ActualEnvironmentalConditions', 0x00141010,
          'Actual Environmental Conditions', VR.kST, VM.k1, false);
  static const PTag kExpiryDate
      //(0014,1020)
      = const PTag._('ExpiryDate', 0x00141020, 'Expiry Date', VR.kDA, VM.k1, false);
  static const PTag kEnvironmentalConditions
      //(0014,1040)
      = const PTag._('EnvironmentalConditions', 0x00141040, 'Environmental Conditions',
          VR.kST, VM.k1, false);
  static const PTag kEvaluatorSequence
      //(0014,2002)
      = const PTag._(
          'EvaluatorSequence', 0x00142002, 'Evaluator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEvaluatorNumber
      //(0014,2004)
      = const PTag._(
          'EvaluatorNumber', 0x00142004, 'Evaluator Number', VR.kIS, VM.k1, false);
  static const PTag kEvaluatorName
      //(0014,2006)
      = const PTag._('EvaluatorName', 0x00142006, 'Evaluator Name', VR.kPN, VM.k1, false);
  static const PTag kEvaluationAttempt
      //(0014,2008)
      = const PTag._(
          'EvaluationAttempt', 0x00142008, 'Evaluation Attempt', VR.kIS, VM.k1, false);
  static const PTag kIndicationSequence
      //(0014,2012)
      = const PTag._(
          'IndicationSequence', 0x00142012, 'Indication Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIndicationNumber
      //(0014,2014)
      = const PTag._(
          'IndicationNumber', 0x00142014, 'Indication Number', VR.kIS, VM.k1, false);
  static const PTag kIndicationLabel
      //(0014,2016)
      = const PTag._(
          'IndicationLabel', 0x00142016, 'Indication Label', VR.kSH, VM.k1, false);
  static const PTag kIndicationDescription
      //(0014,2018)
      = const PTag._('IndicationDescription', 0x00142018, 'Indication Description',
          VR.kST, VM.k1, false);
  static const PTag kIndicationType
      //(0014,201A)
      = const PTag._(
          'IndicationType', 0x0014201A, 'Indication Type', VR.kCS, VM.k1_n, false);
  static const PTag kIndicationDisposition
      //(0014,201C)
      = const PTag._('IndicationDisposition', 0x0014201C, 'Indication Disposition',
          VR.kCS, VM.k1, false);
  static const PTag kIndicationROISequence
      //(0014,201E)
      = const PTag._('IndicationROISequence', 0x0014201E, 'Indication ROI Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kIndicationPhysicalPropertySequence
      //(0014,2030)
      = const PTag._('IndicationPhysicalPropertySequence', 0x00142030,
          'Indication Physical Property Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPropertyLabel
      //(0014,2032)
      = const PTag._('PropertyLabel', 0x00142032, 'Property Label', VR.kSH, VM.k1, false);
  static const PTag kCoordinateSystemNumberOfAxes
      //(0014,2202)
      = const PTag._('CoordinateSystemNumberOfAxes', 0x00142202,
          'Coordinate System Number of Axes', VR.kIS, VM.k1, false);
  static const PTag kCoordinateSystemAxesSequence
      //(0014,2204)
      = const PTag._('CoordinateSystemAxesSequence', 0x00142204,
          'Coordinate System Axes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCoordinateSystemAxisDescription
      //(0014,2206)
      = const PTag._('CoordinateSystemAxisDescription', 0x00142206,
          'Coordinate System Axis Description', VR.kST, VM.k1, false);
  static const PTag kCoordinateSystemDataSetMapping
      //(0014,2208)
      = const PTag._('CoordinateSystemDataSetMapping', 0x00142208,
          'Coordinate System Data Set Mapping', VR.kCS, VM.k1, false);
  static const PTag kCoordinateSystemAxisNumber
      //(0014,220A)
      = const PTag._('CoordinateSystemAxisNumber', 0x0014220A,
          'Coordinate System Axis Number', VR.kIS, VM.k1, false);
  static const PTag kCoordinateSystemAxisType
      //(0014,220C)
      = const PTag._('CoordinateSystemAxisType', 0x0014220C,
          'Coordinate System Axis Type', VR.kCS, VM.k1, false);
  static const PTag kCoordinateSystemAxisUnits
      //(0014,220E)
      = const PTag._('CoordinateSystemAxisUnits', 0x0014220E,
          'Coordinate System Axis Units', VR.kCS, VM.k1, false);
  static const PTag kCoordinateSystemAxisValues
      //(0014,2210)
      = const PTag._('CoordinateSystemAxisValues', 0x00142210,
          'Coordinate System Axis Values', VR.kOB, VM.k1, false);
  static const PTag kCoordinateSystemTransformSequence
      //(0014,2220)
      = const PTag._('CoordinateSystemTransformSequence', 0x00142220,
          'Coordinate System Transform Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTransformDescription
      //(0014,2222)
      = const PTag._('TransformDescription', 0x00142222, 'Transform Description', VR.kST,
          VM.k1, false);
  static const PTag kTransformNumberOfAxes
      //(0014,2224)
      = const PTag._('TransformNumberOfAxes', 0x00142224, 'Transform Number of Axes',
          VR.kIS, VM.k1, false);
  static const PTag kTransformOrderOfAxes
      //(0014,2226)
      = const PTag._('TransformOrderOfAxes', 0x00142226, 'Transform Order of Axes',
          VR.kIS, VM.k1_n, false);
  static const PTag kTransformedAxisUnits
      //(0014,2228)
      = const PTag._('TransformedAxisUnits', 0x00142228, 'Transformed Axis Units', VR.kCS,
          VM.k1, false);
  static const PTag kCoordinateSystemTransformRotationAndScaleMatrix
      //(0014,222A)
      = const PTag._(
          'CoordinateSystemTransformRotationAndScaleMatrix',
          0x0014222A,
          'Coordinate System Transform Rotation and Scale Matrix',
          VR.kDS,
          VM.k1_n,
          false);
  static const PTag kCoordinateSystemTransformTranslationMatrix
      //(0014,222C)
      = const PTag._('CoordinateSystemTransformTranslationMatrix', 0x0014222C,
          'Coordinate System Transform Translation Matrix', VR.kDS, VM.k1_n, false);
  static const PTag kInternalDetectorFrameTime
      //(0014,3011)
      = const PTag._('InternalDetectorFrameTime', 0x00143011,
          'Internal Detector Frame Time', VR.kDS, VM.k1, false);
  static const PTag kNumberOfFramesIntegrated
      //(0014,3012)
      = const PTag._('NumberOfFramesIntegrated', 0x00143012,
          'Number of Frames Integrated', VR.kDS, VM.k1, false);
  static const PTag kDetectorTemperatureSequence
      //(0014,3020)
      = const PTag._('DetectorTemperatureSequence', 0x00143020,
          'Detector Temperature Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSensorName
      //(0014,3022)
      = const PTag._('SensorName', 0x00143022, 'Sensor Name', VR.kST, VM.k1, false);
  static const PTag kHorizontalOffsetOfSensor
      //(0014,3024)
      = const PTag._('HorizontalOffsetOfSensor', 0x00143024,
          'Horizontal Offset of Sensor', VR.kDS, VM.k1, false);
  static const PTag kVerticalOffsetOfSensor
      //(0014,3026)
      = const PTag._('VerticalOffsetOfSensor', 0x00143026, 'Vertical Offset of Sensor',
          VR.kDS, VM.k1, false);
  static const PTag kSensorTemperature
      //(0014,3028)
      = const PTag._(
          'SensorTemperature', 0x00143028, 'Sensor Temperature', VR.kDS, VM.k1, false);
  static const PTag kDarkCurrentSequence
      //(0014,3040)
      = const PTag._('DarkCurrentSequence', 0x00143040, 'Dark Current Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kDarkCurrentCounts
      //(0014,3050)
      = const PTag._(
          'DarkCurrentCounts', 0x00143050, 'Dark Current Counts', VR.kOBOW, VM.k1, false);
  static const PTag kGainCorrectionReferenceSequence
      //(0014,3060)
      = const PTag._('GainCorrectionReferenceSequence', 0x00143060,
          'Gain Correction Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAirCounts
      //(0014,3070)
      = const PTag._('AirCounts', 0x00143070, 'Air Counts', VR.kOBOW, VM.k1, false);
  static const PTag kKVUsedInGainCalibration
      //(0014,3071)
      = const PTag._('KVUsedInGainCalibration', 0x00143071, 'KV Used in Gain Calibration',
          VR.kDS, VM.k1, false);
  static const PTag kMAUsedInGainCalibration
      //(0014,3072)
      = const PTag._('MAUsedInGainCalibration', 0x00143072, 'MA Used in Gain Calibration',
          VR.kDS, VM.k1, false);
  static const PTag kNumberOfFramesUsedForIntegration
      //(0014,3073)
      = const PTag._('NumberOfFramesUsedForIntegration', 0x00143073,
          'Number of Frames Used for Integration', VR.kDS, VM.k1, false);
  static const PTag kFilterMaterialUsedInGainCalibration
      //(0014,3074)
      = const PTag._('FilterMaterialUsedInGainCalibration', 0x00143074,
          'Filter Material Used in Gain Calibration', VR.kLO, VM.k1, false);
  static const PTag kFilterThicknessUsedInGainCalibration
      //(0014,3075)
      = const PTag._('FilterThicknessUsedInGainCalibration', 0x00143075,
          'Filter Thickness Used in Gain Calibration', VR.kDS, VM.k1, false);
  static const PTag kDateOfGainCalibration
      //(0014,3076)
      = const PTag._('DateOfGainCalibration', 0x00143076, 'Date of Gain Calibration',
          VR.kDA, VM.k1, false);
  static const PTag kTimeOfGainCalibration
      //(0014,3077)
      = const PTag._('TimeOfGainCalibration', 0x00143077, 'Time of Gain Calibration',
          VR.kTM, VM.k1, false);
  static const PTag kBadPixelImage
      //(0014,3080)
      =
      const PTag._('BadPixelImage', 0x00143080, 'Bad Pixel Image', VR.kOB, VM.k1, false);
  static const PTag kCalibrationNotes
      //(0014,3099)
      = const PTag._(
          'CalibrationNotes', 0x00143099, 'Calibration Notes', VR.kLT, VM.k1, false);
  static const PTag kPulserEquipmentSequence
      //(0014,4002)
      = const PTag._('PulserEquipmentSequence', 0x00144002, 'Pulser Equipment Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPulserType
      //(0014,4004)
      = const PTag._('PulserType', 0x00144004, 'Pulser Type', VR.kCS, VM.k1, false);
  static const PTag kPulserNotes
      //(0014,4006)
      = const PTag._('PulserNotes', 0x00144006, 'Pulser Notes', VR.kLT, VM.k1, false);
  static const PTag kReceiverEquipmentSequence
      //(0014,4008)
      = const PTag._('ReceiverEquipmentSequence', 0x00144008,
          'Receiver Equipment Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAmplifierType
      //(0014,400A)
      = const PTag._('AmplifierType', 0x0014400A, 'Amplifier Type', VR.kCS, VM.k1, false);
  static const PTag kReceiverNotes
      //(0014,400C)
      = const PTag._('ReceiverNotes', 0x0014400C, 'Receiver Notes', VR.kLT, VM.k1, false);
  static const PTag kPreAmplifierEquipmentSequence
      //(0014,400E)
      = const PTag._('PreAmplifierEquipmentSequence', 0x0014400E,
          'Pre-Amplifier Equipment Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPreAmplifierNotes
      //(0014,400F)
      = const PTag._(
          'PreAmplifierNotes', 0x0014400F, 'Pre-Amplifier Notes', VR.kLT, VM.k1, false);
  static const PTag kTransmitTransducerSequence
      //(0014,4010)
      = const PTag._('TransmitTransducerSequence', 0x00144010,
          'Transmit Transducer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReceiveTransducerSequence
      //(0014,4011)
      = const PTag._('ReceiveTransducerSequence', 0x00144011,
          'Receive Transducer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfElements
      //(0014,4012)
      = const PTag._(
          'NumberOfElements', 0x00144012, 'Number of Elements', VR.kUS, VM.k1, false);
  static const PTag kElementShape
      //(0014,4013)
      = const PTag._('ElementShape', 0x00144013, 'Element Shape', VR.kCS, VM.k1, false);
  static const PTag kElementDimensionA
      //(0014,4014)
      = const PTag._(
          'ElementDimensionA', 0x00144014, 'Element Dimension A', VR.kDS, VM.k1, false);
  static const PTag kElementDimensionB
      //(0014,4015)
      = const PTag._(
          'ElementDimensionB', 0x00144015, 'Element Dimension B', VR.kDS, VM.k1, false);
  static const PTag kElementPitchA
      //(0014,4016)
      =
      const PTag._('ElementPitchA', 0x00144016, 'Element Pitch A', VR.kDS, VM.k1, false);
  static const PTag kMeasuredBeamDimensionA
      //(0014,4017)
      = const PTag._('MeasuredBeamDimensionA', 0x00144017, 'Measured Beam Dimension A',
          VR.kDS, VM.k1, false);
  static const PTag kMeasuredBeamDimensionB
      //(0014,4018)
      = const PTag._('MeasuredBeamDimensionB', 0x00144018, 'Measured Beam Dimension B',
          VR.kDS, VM.k1, false);
  static const PTag kLocationOfMeasuredBeamDiameter
      //(0014,4019)
      = const PTag._('LocationOfMeasuredBeamDiameter', 0x00144019,
          'Location of Measured Beam Diameter', VR.kDS, VM.k1, false);
  static const PTag kNominalFrequency
      //(0014,401A)
      = const PTag._(
          'NominalFrequency', 0x0014401A, 'Nominal Frequency', VR.kDS, VM.k1, false);
  static const PTag kMeasuredCenterFrequency
      //(0014,401B)
      = const PTag._('MeasuredCenterFrequency', 0x0014401B, 'Measured Center Frequency',
          VR.kDS, VM.k1, false);
  static const PTag kMeasuredBandwidth
      //(0014,401C)
      = const PTag._(
          'MeasuredBandwidth', 0x0014401C, 'Measured Bandwidth', VR.kDS, VM.k1, false);
  static const PTag kElementPitchB
      //(0014,401D)
      =
      const PTag._('ElementPitchB', 0x0014401D, 'Element Pitch B', VR.kDS, VM.k1, false);
  static const PTag kPulserSettingsSequence
      //(0014,4020)
      = const PTag._('PulserSettingsSequence', 0x00144020, 'Pulser Settings Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPulseWidth
      //(0014,4022)
      = const PTag._('PulseWidth', 0x00144022, 'Pulse Width', VR.kDS, VM.k1, false);
  static const PTag kExcitationFrequency
      //(0014,4024)
      = const PTag._('ExcitationFrequency', 0x00144024, 'Excitation Frequency', VR.kDS,
          VM.k1, false);
  static const PTag kModulationType
      //(0014,4026)
      =
      const PTag._('ModulationType', 0x00144026, 'Modulation Type', VR.kCS, VM.k1, false);
  static const PTag kDamping
      //(0014,4028)
      = const PTag._('Damping', 0x00144028, 'Damping', VR.kDS, VM.k1, false);
  static const PTag kReceiverSettingsSequence
      //(0014,4030)
      = const PTag._('ReceiverSettingsSequence', 0x00144030, 'Receiver Settings Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kAcquiredSoundpathLength
      //(0014,4031)
      = const PTag._('AcquiredSoundpathLength', 0x00144031, 'Acquired Soundpath Length',
          VR.kDS, VM.k1, false);
  static const PTag kAcquisitionCompressionType
      //(0014,4032)
      = const PTag._('AcquisitionCompressionType', 0x00144032,
          'Acquisition Compression Type', VR.kCS, VM.k1, false);
  static const PTag kAcquisitionSampleSize
      //(0014,4033)
      = const PTag._('AcquisitionSampleSize', 0x00144033, 'Acquisition Sample Size',
          VR.kIS, VM.k1, false);
  static const PTag kRectifierSmoothing
      //(0014,4034)
      = const PTag._(
          'RectifierSmoothing', 0x00144034, 'Rectifier Smoothing', VR.kDS, VM.k1, false);
  static const PTag kDACSequence
      //(0014,4035)
      = const PTag._('DACSequence', 0x00144035, 'DAC Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDACType
      //(0014,4036)
      = const PTag._('DACType', 0x00144036, 'DAC Type', VR.kCS, VM.k1, false);
  static const PTag kDACGainPoints
      //(0014,4038)
      = const PTag._(
          'DACGainPoints', 0x00144038, 'DAC Gain Points', VR.kDS, VM.k1_n, false);
  static const PTag kDACTimePoints
      //(0014,403A)
      = const PTag._(
          'DACTimePoints', 0x0014403A, 'DAC Time Points', VR.kDS, VM.k1_n, false);
  static const PTag kDACAmplitude
      //(0014,403C)
      = const PTag._('DACAmplitude', 0x0014403C, 'DAC Amplitude', VR.kDS, VM.k1_n, false);
  static const PTag kPreAmplifierSettingsSequence
      //(0014,4040)
      = const PTag._('PreAmplifierSettingsSequence', 0x00144040,
          'Pre-Amplifier Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTransmitTransducerSettingsSequence
      //(0014,4050)
      = const PTag._('TransmitTransducerSettingsSequence', 0x00144050,
          'Transmit Transducer Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReceiveTransducerSettingsSequence
      //(0014,4051)
      = const PTag._('ReceiveTransducerSettingsSequence', 0x00144051,
          'Receive Transducer Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIncidentAngle
      //(0014,4052)
      = const PTag._('IncidentAngle', 0x00144052, 'Incident Angle', VR.kDS, VM.k1, false);
  static const PTag kCouplingTechnique
      //(0014,4054)
      = const PTag._(
          'CouplingTechnique', 0x00144054, 'Coupling Technique', VR.kST, VM.k1, false);
  static const PTag kCouplingMedium
      //(0014,4056)
      =
      const PTag._('CouplingMedium', 0x00144056, 'Coupling Medium', VR.kST, VM.k1, false);
  static const PTag kCouplingVelocity
      //(0014,4057)
      = const PTag._(
          'CouplingVelocity', 0x00144057, 'Coupling Velocity', VR.kDS, VM.k1, false);
  static const PTag kProbeCenterLocationX
      //(0014,4058)
      = const PTag._('ProbeCenterLocationX', 0x00144058, 'Probe Center Location X',
          VR.kDS, VM.k1, false);
  static const PTag kProbeCenterLocationZ
      //(0014,4059)
      = const PTag._('ProbeCenterLocationZ', 0x00144059, 'Probe Center Location Z',
          VR.kDS, VM.k1, false);
  static const PTag kSoundPathLength
      //(0014,405A)
      = const PTag._(
          'SoundPathLength', 0x0014405A, 'Sound Path Length', VR.kDS, VM.k1, false);
  static const PTag kDelayLawIdentifier
      //(0014,405C)
      = const PTag._(
          'DelayLawIdentifier', 0x0014405C, 'Delay Law Identifier', VR.kST, VM.k1, false);
  static const PTag kGateSettingsSequence
      //(0014,4060)
      = const PTag._('GateSettingsSequence', 0x00144060, 'Gate Settings Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kGateThreshold
      //(0014,4062)
      = const PTag._('GateThreshold', 0x00144062, 'Gate Threshold', VR.kDS, VM.k1, false);
  static const PTag kVelocityOfSound
      //(0014,4064)
      = const PTag._(
          'VelocityOfSound', 0x00144064, 'Velocity of Sound', VR.kDS, VM.k1, false);
  static const PTag kCalibrationSettingsSequence
      //(0014,4070)
      = const PTag._('CalibrationSettingsSequence', 0x00144070,
          'Calibration Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCalibrationProcedure
      //(0014,4072)
      = const PTag._('CalibrationProcedure', 0x00144072, 'Calibration Procedure', VR.kST,
          VM.k1, false);
  static const PTag kProcedureVersion
      //(0014,4074)
      = const PTag._(
          'ProcedureVersion', 0x00144074, 'Procedure Version', VR.kSH, VM.k1, false);
  static const PTag kProcedureCreationDate
      //(0014,4076)
      = const PTag._('ProcedureCreationDate', 0x00144076, 'Procedure Creation Date',
          VR.kDA, VM.k1, false);
  static const PTag kProcedureExpirationDate
      //(0014,4078)
      = const PTag._('ProcedureExpirationDate', 0x00144078, 'Procedure Expiration Date',
          VR.kDA, VM.k1, false);
  static const PTag kProcedureLastModifiedDate
      //(0014,407A)
      = const PTag._('ProcedureLastModifiedDate', 0x0014407A,
          'Procedure Last Modified Date', VR.kDA, VM.k1, false);
  static const PTag kCalibrationTime
      //(0014,407C)
      = const PTag._(
          'CalibrationTime', 0x0014407C, 'Calibration Time', VR.kTM, VM.k1_n, false);
  static const PTag kCalibrationDate
      //(0014,407E)
      = const PTag._(
          'CalibrationDate', 0x0014407E, 'Calibration Date', VR.kDA, VM.k1_n, false);
  static const PTag kProbeDriveEquipmentSequence
      //(0014,4080)
      = const PTag._('ProbeDriveEquipmentSequence', 0x00144080,
          'Probe Drive Equipment Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDriveType
      //(0014,4081)
      = const PTag._('DriveType', 0x00144081, 'Drive Type', VR.kCS, VM.k1, false);
  static const PTag kProbeDriveNotes
      //(0014,4082)
      = const PTag._(
          'ProbeDriveNotes', 0x00144082, 'Probe Drive Notes', VR.kLT, VM.k1, false);
  static const PTag kDriveProbeSequence
      //(0014,4083)
      = const PTag._(
          'DriveProbeSequence', 0x00144083, 'Drive Probe Sequence', VR.kSQ, VM.k1, false);
  static const PTag kProbeInductance
      //(0014,4084)
      = const PTag._(
          'ProbeInductance', 0x00144084, 'Probe Inductance', VR.kDS, VM.k1, false);
  static const PTag kProbeResistance
      //(0014,4085)
      = const PTag._(
          'ProbeResistance', 0x00144085, 'Probe Resistance', VR.kDS, VM.k1, false);
  static const PTag kReceiveProbeSequence
      //(0014,4086)
      = const PTag._('ReceiveProbeSequence', 0x00144086, 'Receive Probe Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kProbeDriveSettingsSequence
      //(0014,4087)
      = const PTag._('ProbeDriveSettingsSequence', 0x00144087,
          'Probe Drive Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBridgeResistors
      //(0014,4088)
      = const PTag._(
          'BridgeResistors', 0x00144088, 'Bridge Resistors', VR.kDS, VM.k1, false);
  static const PTag kProbeOrientationAngle
      //(0014,4089)
      = const PTag._('ProbeOrientationAngle', 0x00144089, 'Probe Orientation Angle',
          VR.kDS, VM.k1, false);
  static const PTag kUserSelectedGainY
      //(0014,408B)
      = const PTag._(
          'UserSelectedGainY', 0x0014408B, 'User Selected Gain Y', VR.kDS, VM.k1, false);
  static const PTag kUserSelectedPhase
      //(0014,408C)
      = const PTag._(
          'UserSelectedPhase', 0x0014408C, 'User Selected Phase', VR.kDS, VM.k1, false);
  static const PTag kUserSelectedOffsetX
      //(0014,408D)
      = const PTag._('UserSelectedOffsetX', 0x0014408D, 'User Selected Offset X', VR.kDS,
          VM.k1, false);
  static const PTag kUserSelectedOffsetY
      //(0014,408E)
      = const PTag._('UserSelectedOffsetY', 0x0014408E, 'User Selected Offset Y', VR.kDS,
          VM.k1, false);
  static const PTag kChannelSettingsSequence
      //(0014,4091)
      = const PTag._('ChannelSettingsSequence', 0x00144091, 'Channel Settings Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kChannelThreshold
      //(0014,4092)
      = const PTag._(
          'ChannelThreshold', 0x00144092, 'Channel Threshold', VR.kDS, VM.k1, false);
  static const PTag kScannerSettingsSequence
      //(0014,409A)
      = const PTag._('ScannerSettingsSequence', 0x0014409A, 'Scanner Settings Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kScanProcedure
      //(0014,409B)
      = const PTag._('ScanProcedure', 0x0014409B, 'Scan Procedure', VR.kST, VM.k1, false);
  static const PTag kTranslationRateX
      //(0014,409C)
      = const PTag._(
          'TranslationRateX', 0x0014409C, 'Translation Rate X', VR.kDS, VM.k1, false);
  static const PTag kTranslationRateY
      //(0014,409D)
      = const PTag._(
          'TranslationRateY', 0x0014409D, 'Translation Rate Y', VR.kDS, VM.k1, false);
  static const PTag kChannelOverlap
      //(0014,409F)
      =
      const PTag._('ChannelOverlap', 0x0014409F, 'Channel Overlap', VR.kDS, VM.k1, false);
  static const PTag kImageQualityIndicatorType
      //(0014,40A0)
      = const PTag._('ImageQualityIndicatorType', 0x001440A0,
          'Image Quality Indicator Type', VR.kLO, VM.k1, false);
  static const PTag kImageQualityIndicatorMaterial
      //(0014,40A1)
      = const PTag._('ImageQualityIndicatorMaterial', 0x001440A1,
          'Image Quality Indicator Material', VR.kLO, VM.k1, false);
  static const PTag kImageQualityIndicatorSize
      //(0014,40A2)
      = const PTag._('ImageQualityIndicatorSize', 0x001440A2,
          'Image Quality Indicator Size', VR.kLO, VM.k1, false);
  static const PTag kLINACEnergy
      //(0014,5002)
      = const PTag._('LINACEnergy', 0x00145002, 'LINAC Energy', VR.kIS, VM.k1, false);
  static const PTag kLINACOutput
      //(0014,5004)
      = const PTag._('LINACOutput', 0x00145004, 'LINAC Output', VR.kIS, VM.k1, false);
  static const PTag kContrastBolusAgent
      //(0018,0010)
      = const PTag._(
          'ContrastBolusAgent', 0x00180010, 'Contrast/Bolus Agent', VR.kLO, VM.k1, false);
  static const PTag kContrastBolusAgentSequence
      //(0018,0012)
      = const PTag._('ContrastBolusAgentSequence', 0x00180012,
          'Contrast/Bolus Agent Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContrastBolusAdministrationRouteSequence
      //(0018,0014)
      = const PTag._('ContrastBolusAdministrationRouteSequence', 0x00180014,
          'Contrast/Bolus Administration Route Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBodyPartExamined
      //(0018,0015)
      = const PTag._(
          'BodyPartExamined', 0x00180015, 'Body Part Examined', VR.kCS, VM.k1, false);
  static const PTag kScanningSequence
      //(0018,0020)
      = const PTag._(
          'ScanningSequence', 0x00180020, 'Scanning Sequence', VR.kCS, VM.k1_n, false);
  static const PTag kSequenceVariant
      //(0018,0021)
      = const PTag._(
          'SequenceVariant', 0x00180021, 'Sequence Variant', VR.kCS, VM.k1_n, false);
  static const PTag kScanOptions
      //(0018,0022)
      = const PTag._('ScanOptions', 0x00180022, 'Scan Options', VR.kCS, VM.k1_n, false);
  static const PTag kMRAcquisitionType
      //(0018,0023)
      = const PTag._(
          'MRAcquisitionType', 0x00180023, 'MR Acquisition Type', VR.kCS, VM.k1, false);
  static const PTag kSequenceName
      //(0018,0024)
      = const PTag._('SequenceName', 0x00180024, 'Sequence Name', VR.kSH, VM.k1, false);
  static const PTag kAngioFlag
      //(0018,0025)
      = const PTag._('AngioFlag', 0x00180025, 'Angio Flag', VR.kCS, VM.k1, false);
  static const PTag kInterventionDrugInformationSequence
      //(0018,0026)
      = const PTag._('InterventionDrugInformationSequence', 0x00180026,
          'Intervention Drug Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kInterventionDrugStopTime
      //(0018,0027)
      = const PTag._('InterventionDrugStopTime', 0x00180027,
          'Intervention Drug Stop Time', VR.kTM, VM.k1, false);
  static const PTag kInterventionDrugDose
      //(0018,0028)
      = const PTag._('InterventionDrugDose', 0x00180028, 'Intervention Drug Dose', VR.kDS,
          VM.k1, false);
  static const PTag kInterventionDrugCodeSequence
      //(0018,0029)
      = const PTag._('InterventionDrugCodeSequence', 0x00180029,
          'Intervention Drug Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAdditionalDrugSequence
      //(0018,002A)
      = const PTag._('AdditionalDrugSequence', 0x0018002A, 'Additional Drug Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kRadionuclide
      //(0018,0030)
      = const PTag._('Radionuclide', 0x00180030, 'Radionuclide', VR.kLO, VM.k1_n, true);
  static const PTag kRadiopharmaceutical
      //(0018,0031)
      = const PTag._(
          'Radiopharmaceutical', 0x00180031, 'Radiopharmaceutical', VR.kLO, VM.k1, false);
  static const PTag kEnergyWindowCenterline
      //(0018,0032)
      = const PTag._('EnergyWindowCenterline', 0x00180032, 'Energy Window Centerline',
          VR.kDS, VM.k1, true);
  static const PTag kEnergyWindowTotalWidth
      //(0018,0033)
      = const PTag._('EnergyWindowTotalWidth', 0x00180033, 'Energy Window Total Width',
          VR.kDS, VM.k1_n, true);
  static const PTag kInterventionDrugName
      //(0018,0034)
      = const PTag._('InterventionDrugName', 0x00180034, 'Intervention Drug Name', VR.kLO,
          VM.k1, false);
  static const PTag kInterventionDrugStartTime
      //(0018,0035)
      = const PTag._('InterventionDrugStartTime', 0x00180035,
          'Intervention Drug Start Time', VR.kTM, VM.k1, false);
  static const PTag kInterventionSequence
      //(0018,0036)
      = const PTag._('InterventionSequence', 0x00180036, 'Intervention Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kTherapyType
      //(0018,0037)
      = const PTag._('TherapyType', 0x00180037, 'Therapy Type', VR.kCS, VM.k1, true);
  static const PTag kInterventionStatus
      //(0018,0038)
      = const PTag._(
          'InterventionStatus', 0x00180038, 'Intervention Status', VR.kCS, VM.k1, false);
  static const PTag kTherapyDescription
      //(0018,0039)
      = const PTag._(
          'TherapyDescription', 0x00180039, 'Therapy Description', VR.kCS, VM.k1, true);
  static const PTag kInterventionDescription
      //(0018,003A)
      = const PTag._('InterventionDescription', 0x0018003A, 'Intervention Description',
          VR.kST, VM.k1, false);
  static const PTag kCineRate
      //(0018,0040)
      = const PTag._('CineRate', 0x00180040, 'Cine Rate', VR.kIS, VM.k1, false);
  static const PTag kInitialCineRunState
      //(0018,0042)
      = const PTag._('InitialCineRunState', 0x00180042, 'Initial Cine Run State', VR.kCS,
          VM.k1, false);
  static const PTag kSliceThickness
      //(0018,0050)
      =
      const PTag._('SliceThickness', 0x00180050, 'Slice Thickness', VR.kDS, VM.k1, false);
  static const PTag kKVP
      //(0018,0060)
      = const PTag._('KVP', 0x00180060, 'KVP', VR.kDS, VM.k1, false);
  static const PTag kCountsAccumulated
      //(0018,0070)
      = const PTag._(
          'CountsAccumulated', 0x00180070, 'Counts Accumulated', VR.kIS, VM.k1, false);
  static const PTag kAcquisitionTerminationCondition
      //(0018,0071)
      = const PTag._('AcquisitionTerminationCondition', 0x00180071,
          'Acquisition Termination Condition', VR.kCS, VM.k1, false);
  static const PTag kEffectiveDuration
      //(0018,0072)
      = const PTag._(
          'EffectiveDuration', 0x00180072, 'Effective Duration', VR.kDS, VM.k1, false);
  static const PTag kAcquisitionStartCondition
      //(0018,0073)
      = const PTag._('AcquisitionStartCondition', 0x00180073,
          'Acquisition Start Condition', VR.kCS, VM.k1, false);
  static const PTag kAcquisitionStartConditionData
      //(0018,0074)
      = const PTag._('AcquisitionStartConditionData', 0x00180074,
          'Acquisition Start Condition Data', VR.kIS, VM.k1, false);
  static const PTag kAcquisitionTerminationConditionData
      //(0018,0075)
      = const PTag._('AcquisitionTerminationConditionData', 0x00180075,
          'Acquisition Termination Condition Data', VR.kIS, VM.k1, false);
  static const PTag kRepetitionTime
      //(0018,0080)
      =
      const PTag._('RepetitionTime', 0x00180080, 'Repetition Time', VR.kDS, VM.k1, false);
  static const PTag kEchoTime
      //(0018,0081)
      = const PTag._('EchoTime', 0x00180081, 'Echo Time', VR.kDS, VM.k1, false);
  static const PTag kInversionTime
      //(0018,0082)
      = const PTag._('InversionTime', 0x00180082, 'Inversion Time', VR.kDS, VM.k1, false);
  static const PTag kNumberOfAverages
      //(0018,0083)
      = const PTag._(
          'NumberOfAverages', 0x00180083, 'Number of Averages', VR.kDS, VM.k1, false);
  static const PTag kImagingFrequency
      //(0018,0084)
      = const PTag._(
          'ImagingFrequency', 0x00180084, 'Imaging Frequency', VR.kDS, VM.k1, false);
  static const PTag kImagedNucleus
      //(0018,0085)
      = const PTag._('ImagedNucleus', 0x00180085, 'Imaged Nucleus', VR.kSH, VM.k1, false);
  static const PTag kEchoNumbers
      //(0018,0086)
      = const PTag._('EchoNumbers', 0x00180086, 'Echo Number(s)', VR.kIS, VM.k1_n, false);
  static const PTag kMagneticFieldStrength
      //(0018,0087)
      = const PTag._('MagneticFieldStrength', 0x00180087, 'Magnetic Field Strength',
          VR.kDS, VM.k1, false);
  static const PTag kSpacingBetweenSlices
      //(0018,0088)
      = const PTag._('SpacingBetweenSlices', 0x00180088, 'Spacing Between Slices', VR.kDS,
          VM.k1, false);
  static const PTag kNumberOfPhaseEncodingSteps
      //(0018,0089)
      = const PTag._('NumberOfPhaseEncodingSteps', 0x00180089,
          'Number of Phase Encoding Steps', VR.kIS, VM.k1, false);
  static const PTag kDataCollectionDiameter
      //(0018,0090)
      = const PTag._('DataCollectionDiameter', 0x00180090, 'Data Collection Diameter',
          VR.kDS, VM.k1, false);
  static const PTag kEchoTrainLength
      //(0018,0091)
      = const PTag._(
          'EchoTrainLength', 0x00180091, 'Echo Train Length', VR.kIS, VM.k1, false);
  static const PTag kPercentSampling
      //(0018,0093)
      = const PTag._(
          'PercentSampling', 0x00180093, 'Percent Sampling', VR.kDS, VM.k1, false);
  static const PTag kPercentPhaseFieldOfView
      //(0018,0094)
      = const PTag._('PercentPhaseFieldOfView', 0x00180094, 'Percent Phase Field of View',
          VR.kDS, VM.k1, false);
  static const PTag kPixelBandwidth
      //(0018,0095)
      =
      const PTag._('PixelBandwidth', 0x00180095, 'Pixel Bandwidth', VR.kDS, VM.k1, false);
  static const PTag kDeviceSerialNumber
      //(0018,1000)
      = const PTag._(
          'DeviceSerialNumber', 0x00181000, 'Device Serial Number', VR.kLO, VM.k1, false);
  static const PTag kDeviceUID
      //(0018,1002)
      = const PTag._('DeviceUID', 0x00181002, 'Device UID', VR.kUI, VM.k1, false);
  static const PTag kDeviceID
      //(0018,1003)
      = const PTag._('DeviceID', 0x00181003, 'Device ID', VR.kLO, VM.k1, false);
  static const PTag kPlateID
      //(0018,1004)
      = const PTag._('PlateID', 0x00181004, 'Plate ID', VR.kLO, VM.k1, false);
  static const PTag kGeneratorID
      //(0018,1005)
      = const PTag._('GeneratorID', 0x00181005, 'Generator ID', VR.kLO, VM.k1, false);
  static const PTag kGridID
      //(0018,1006)
      = const PTag._('GridID', 0x00181006, 'Grid ID', VR.kLO, VM.k1, false);
  static const PTag kCassetteID
      //(0018,1007)
      = const PTag._('CassetteID', 0x00181007, 'Cassette ID', VR.kLO, VM.k1, false);
  static const PTag kGantryID
      //(0018,1008)
      = const PTag._('GantryID', 0x00181008, 'Gantry ID', VR.kLO, VM.k1, false);
  static const PTag kSecondaryCaptureDeviceID
      //(0018,1010)
      = const PTag._('SecondaryCaptureDeviceID', 0x00181010,
          'Secondary Capture Device ID', VR.kLO, VM.k1, false);
  static const PTag kHardcopyCreationDeviceID
      //(0018,1011)
      = const PTag._('HardcopyCreationDeviceID', 0x00181011,
          'Hardcopy Creation Device ID', VR.kLO, VM.k1, true);
  static const PTag kDateOfSecondaryCapture
      //(0018,1012)
      = const PTag._('DateOfSecondaryCapture', 0x00181012, 'Date of Secondary Capture',
          VR.kDA, VM.k1, false);
  static const PTag kTimeOfSecondaryCapture
      //(0018,1014)
      = const PTag._('TimeOfSecondaryCapture', 0x00181014, 'Time of Secondary Capture',
          VR.kTM, VM.k1, false);
  static const PTag kSecondaryCaptureDeviceManufacturer
      //(0018,1016)
      = const PTag._('SecondaryCaptureDeviceManufacturer', 0x00181016,
          'Secondary Capture Device Manufacturer', VR.kLO, VM.k1, false);
  static const PTag kHardcopyDeviceManufacturer
      //(0018,1017)
      = const PTag._('HardcopyDeviceManufacturer', 0x00181017,
          'Hardcopy Device Manufacturer', VR.kLO, VM.k1, true);
  static const PTag kSecondaryCaptureDeviceManufacturerModelName
      //(0018,1018)
      = const PTag._('SecondaryCaptureDeviceManufacturerModelName', 0x00181018,
          'Secondary Capture Device Manufacturer\'s Model Name', VR.kLO, VM.k1, false);
  static const PTag kSecondaryCaptureDeviceSoftwareVersions
      //(0018,1019)
      = const PTag._('SecondaryCaptureDeviceSoftwareVersions', 0x00181019,
          'Secondary Capture Device Software Versions', VR.kLO, VM.k1_n, false);
  static const PTag kHardcopyDeviceSoftwareVersion
      //(0018,101A)
      = const PTag._('HardcopyDeviceSoftwareVersion', 0x0018101A,
          'Hardcopy Device Software Version', VR.kLO, VM.k1_n, true);
  static const PTag kHardcopyDeviceManufacturerModelName
      //(0018,101B)
      = const PTag._('HardcopyDeviceManufacturerModelName', 0x0018101B,
          'Hardcopy Device Manufacturer\'s Model Name', VR.kLO, VM.k1, true);
  static const PTag kSoftwareVersions
      //(0018,1020)
      = const PTag._(
          'SoftwareVersions', 0x00181020, 'Software Version(s)', VR.kLO, VM.k1_n, false);
  static const PTag kVideoImageFormatAcquired
      //(0018,1022)
      = const PTag._('VideoImageFormatAcquired', 0x00181022,
          'Video Image Format Acquired', VR.kSH, VM.k1, false);
  static const PTag kDigitalImageFormatAcquired
      //(0018,1023)
      = const PTag._('DigitalImageFormatAcquired', 0x00181023,
          'Digital Image Format Acquired', VR.kLO, VM.k1, false);
  static const PTag kProtocolName
      //(0018,1030)
      = const PTag._('ProtocolName', 0x00181030, 'Protocol Name', VR.kLO, VM.k1, false);
  static const PTag kContrastBolusRoute
      //(0018,1040)
      = const PTag._(
          'ContrastBolusRoute', 0x00181040, 'Contrast/Bolus Route', VR.kLO, VM.k1, false);
  static const PTag kContrastBolusVolume
      //(0018,1041)
      = const PTag._('ContrastBolusVolume', 0x00181041, 'Contrast/Bolus Volume', VR.kDS,
          VM.k1, false);
  static const PTag kContrastBolusStartTime
      //(0018,1042)
      = const PTag._('ContrastBolusStartTime', 0x00181042, 'Contrast/Bolus Start Time',
          VR.kTM, VM.k1, false);
  static const PTag kContrastBolusStopTime
      //(0018,1043)
      = const PTag._('ContrastBolusStopTime', 0x00181043, 'Contrast/Bolus Stop Time',
          VR.kTM, VM.k1, false);
  static const PTag kContrastBolusTotalDose
      //(0018,1044)
      = const PTag._('ContrastBolusTotalDose', 0x00181044, 'Contrast/Bolus Total Dose',
          VR.kDS, VM.k1, false);
  static const PTag kSyringeCounts
      //(0018,1045)
      = const PTag._('SyringeCounts', 0x00181045, 'Syringe Counts', VR.kIS, VM.k1, false);
  static const PTag kContrastFlowRate
      //(0018,1046)
      = const PTag._(
          'ContrastFlowRate', 0x00181046, 'Contrast Flow Rate', VR.kDS, VM.k1_n, false);
  static const PTag kContrastFlowDuration
      //(0018,1047)
      = const PTag._('ContrastFlowDuration', 0x00181047, 'Contrast Flow Duration', VR.kDS,
          VM.k1_n, false);
  static const PTag kContrastBolusIngredient
      //(0018,1048)
      = const PTag._('ContrastBolusIngredient', 0x00181048, 'Contrast/Bolus Ingredient',
          VR.kCS, VM.k1, false);
  static const PTag kContrastBolusIngredientConcentration
      //(0018,1049)
      = const PTag._('ContrastBolusIngredientConcentration', 0x00181049,
          'Contrast/Bolus Ingredient Concentration', VR.kDS, VM.k1, false);
  static const PTag kSpatialResolution
      //(0018,1050)
      = const PTag._(
          'SpatialResolution', 0x00181050, 'Spatial Resolution', VR.kDS, VM.k1, false);
  static const PTag kTriggerTime
      //(0018,1060)
      = const PTag._('TriggerTime', 0x00181060, 'Trigger Time', VR.kDS, VM.k1, false);
  static const PTag kTriggerSourceOrType
      //(0018,1061)
      = const PTag._('TriggerSourceOrType', 0x00181061, 'Trigger Source or Type', VR.kLO,
          VM.k1, false);
  static const PTag kNominalInterval
      //(0018,1062)
      = const PTag._(
          'NominalInterval', 0x00181062, 'Nominal Interval', VR.kIS, VM.k1, false);
  static const PTag kFrameTime
      //(0018,1063)
      = const PTag._('FrameTime', 0x00181063, 'Frame Time', VR.kDS, VM.k1, false);
  static const PTag kCardiacFramingType
      //(0018,1064)
      = const PTag._(
          'CardiacFramingType', 0x00181064, 'Cardiac Framing Type', VR.kLO, VM.k1, false);
  static const PTag kFrameTimeVector
      //(0018,1065)
      = const PTag._(
          'FrameTimeVector', 0x00181065, 'Frame Time Vector', VR.kDS, VM.k1_n, false);
  static const PTag kFrameDelay
      //(0018,1066)
      = const PTag._('FrameDelay', 0x00181066, 'Frame Delay', VR.kDS, VM.k1, false);
  static const PTag kImageTriggerDelay
      //(0018,1067)
      = const PTag._(
          'ImageTriggerDelay', 0x00181067, 'Image Trigger Delay', VR.kDS, VM.k1, false);
  static const PTag kMultiplexGroupTimeOffset
      //(0018,1068)
      = const PTag._('MultiplexGroupTimeOffset', 0x00181068,
          'Multiplex Group Time Offset', VR.kDS, VM.k1, false);
  static const PTag kTriggerTimeOffset
      //(0018,1069)
      = const PTag._(
          'TriggerTimeOffset', 0x00181069, 'Trigger Time Offset', VR.kDS, VM.k1, false);
  static const PTag kSynchronizationTrigger
      //(0018,106A)
      = const PTag._('SynchronizationTrigger', 0x0018106A, 'Synchronization Trigger',
          VR.kCS, VM.k1, false);
  static const PTag kSynchronizationChannel
      //(0018,106C)
      = const PTag._('SynchronizationChannel', 0x0018106C, 'Synchronization Channel',
          VR.kUS, VM.k2, false);
  static const PTag kTriggerSamplePosition
      //(0018,106E)
      = const PTag._('TriggerSamplePosition', 0x0018106E, 'Trigger Sample Position',
          VR.kUL, VM.k1, false);
  static const PTag kRadiopharmaceuticalRoute
      //(0018,1070)
      = const PTag._('RadiopharmaceuticalRoute', 0x00181070, 'Radiopharmaceutical Route',
          VR.kLO, VM.k1, false);
  static const PTag kRadiopharmaceuticalVolume
      //(0018,1071)
      = const PTag._('RadiopharmaceuticalVolume', 0x00181071,
          'Radiopharmaceutical Volume', VR.kDS, VM.k1, false);
  static const PTag kRadiopharmaceuticalStartTime
      //(0018,1072)
      = const PTag._('RadiopharmaceuticalStartTime', 0x00181072,
          'Radiopharmaceutical Start Time', VR.kTM, VM.k1, false);
  static const PTag kRadiopharmaceuticalStopTime
      //(0018,1073)
      = const PTag._('RadiopharmaceuticalStopTime', 0x00181073,
          'Radiopharmaceutical Stop Time', VR.kTM, VM.k1, false);
  static const PTag kRadionuclideTotalDose
      //(0018,1074)
      = const PTag._('RadionuclideTotalDose', 0x00181074, 'Radionuclide Total Dose',
          VR.kDS, VM.k1, false);
  static const PTag kRadionuclideHalfLife
      //(0018,1075)
      = const PTag._('RadionuclideHalfLife', 0x00181075, 'Radionuclide Half Life', VR.kDS,
          VM.k1, false);
  static const PTag kRadionuclidePositronFraction
      //(0018,1076)
      = const PTag._('RadionuclidePositronFraction', 0x00181076,
          'Radionuclide Positron Fraction', VR.kDS, VM.k1, false);
  static const PTag kRadiopharmaceuticalSpecificActivity
      //(0018,1077)
      = const PTag._('RadiopharmaceuticalSpecificActivity', 0x00181077,
          'Radiopharmaceutical Specific Activity', VR.kDS, VM.k1, false);
  static const PTag kRadiopharmaceuticalStartDateTime
      //(0018,1078)
      = const PTag._('RadiopharmaceuticalStartDateTime', 0x00181078,
          'Radiopharmaceutical Start DateTime', VR.kDT, VM.k1, false);
  static const PTag kRadiopharmaceuticalStopDateTime
      //(0018,1079)
      = const PTag._('RadiopharmaceuticalStopDateTime', 0x00181079,
          'Radiopharmaceutical Stop DateTime', VR.kDT, VM.k1, false);
  static const PTag kBeatRejectionFlag
      //(0018,1080)
      = const PTag._(
          'BeatRejectionFlag', 0x00181080, 'Beat Rejection Flag', VR.kCS, VM.k1, false);
  static const PTag kLowRRValue
      //(0018,1081)
      = const PTag._('LowRRValue', 0x00181081, 'Low R-R Value', VR.kIS, VM.k1, false);
  static const PTag kHighRRValue
      //(0018,1082)
      = const PTag._('HighRRValue', 0x00181082, 'High R-R Value', VR.kIS, VM.k1, false);
  static const PTag kIntervalsAcquired
      //(0018,1083)
      = const PTag._(
          'IntervalsAcquired', 0x00181083, 'Intervals Acquired', VR.kIS, VM.k1, false);
  static const PTag kIntervalsRejected
      //(0018,1084)
      = const PTag._(
          'IntervalsRejected', 0x00181084, 'Intervals Rejected', VR.kIS, VM.k1, false);
  static const PTag kPVCRejection
      //(0018,1085)
      = const PTag._('PVCRejection', 0x00181085, 'PVC Rejection', VR.kLO, VM.k1, false);
  static const PTag kSkipBeats
      //(0018,1086)
      = const PTag._('SkipBeats', 0x00181086, 'Skip Beats', VR.kIS, VM.k1, false);
  static const PTag kHeartRate
      //(0018,1088)
      = const PTag._('HeartRate', 0x00181088, 'Heart Rate', VR.kIS, VM.k1, false);
  static const PTag kCardiacNumberOfImages
      //(0018,1090)
      = const PTag._('CardiacNumberOfImages', 0x00181090, 'Cardiac Number of Images',
          VR.kIS, VM.k1, false);
  static const PTag kTriggerWindow
      //(0018,1094)
      = const PTag._('TriggerWindow', 0x00181094, 'Trigger Window', VR.kIS, VM.k1, false);
  static const PTag kReconstructionDiameter
      //(0018,1100)
      = const PTag._('ReconstructionDiameter', 0x00181100, 'Reconstruction Diameter',
          VR.kDS, VM.k1, false);
  static const PTag kDistanceSourceToDetector
      //(0018,1110)
      = const PTag._('DistanceSourceToDetector', 0x00181110,
          'Distance Source to Detector', VR.kDS, VM.k1, false);
  static const PTag kDistanceSourceToPatient
      //(0018,1111)
      = const PTag._('DistanceSourceToPatient', 0x00181111, 'Distance Source to Patient',
          VR.kDS, VM.k1, false);
  static const PTag kEstimatedRadiographicMagnificationFactor
      //(0018,1114)
      = const PTag._('EstimatedRadiographicMagnificationFactor', 0x00181114,
          'Estimated Radiographic Magnification Factor', VR.kDS, VM.k1, false);
  static const PTag kGantryDetectorTilt
      //(0018,1120)
      = const PTag._(
          'GantryDetectorTilt', 0x00181120, 'Gantry/Detector Tilt', VR.kDS, VM.k1, false);
  static const PTag kGantryDetectorSlew
      //(0018,1121)
      = const PTag._(
          'GantryDetectorSlew', 0x00181121, 'Gantry/Detector Slew', VR.kDS, VM.k1, false);
  static const PTag kTableHeight
      //(0018,1130)
      = const PTag._('TableHeight', 0x00181130, 'Table Height', VR.kDS, VM.k1, false);
  static const PTag kTableTraverse
      //(0018,1131)
      = const PTag._('TableTraverse', 0x00181131, 'Table Traverse', VR.kDS, VM.k1, false);
  static const PTag kTableMotion
      //(0018,1134)
      = const PTag._('TableMotion', 0x00181134, 'Table Motion', VR.kCS, VM.k1, false);
  static const PTag kTableVerticalIncrement
      //(0018,1135)
      = const PTag._('TableVerticalIncrement', 0x00181135, 'Table Vertical Increment',
          VR.kDS, VM.k1_n, false);
  static const PTag kTableLateralIncrement
      //(0018,1136)
      = const PTag._('TableLateralIncrement', 0x00181136, 'Table Lateral Increment',
          VR.kDS, VM.k1_n, false);
  static const PTag kTableLongitudinalIncrement
      //(0018,1137)
      = const PTag._('TableLongitudinalIncrement', 0x00181137,
          'Table Longitudinal Increment', VR.kDS, VM.k1_n, false);
  static const PTag kTableAngle
      //(0018,1138)
      = const PTag._('TableAngle', 0x00181138, 'Table Angle', VR.kDS, VM.k1, false);
  static const PTag kTableType
      //(0018,113A)
      = const PTag._('TableType', 0x0018113A, 'Table Type', VR.kCS, VM.k1, false);
  static const PTag kRotationDirection
      //(0018,1140)
      = const PTag._(
          'RotationDirection', 0x00181140, 'Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kAngularPosition
      //(0018,1141)
      = const PTag._(
          'AngularPosition', 0x00181141, 'Angular Position', VR.kDS, VM.k1, true);
  static const PTag kRadialPosition
      //(0018,1142)
      = const PTag._(
          'RadialPosition', 0x00181142, 'Radial Position', VR.kDS, VM.k1_n, false);
  static const PTag kScanArc
      //(0018,1143)
      = const PTag._('ScanArc', 0x00181143, 'Scan Arc', VR.kDS, VM.k1, false);
  static const PTag kAngularStep
      //(0018,1144)
      = const PTag._('AngularStep', 0x00181144, 'Angular Step', VR.kDS, VM.k1, false);
  static const PTag kCenterOfRotationOffset
      //(0018,1145)
      = const PTag._('CenterOfRotationOffset', 0x00181145, 'Center of Rotation Offset',
          VR.kDS, VM.k1, false);
  static const PTag kRotationOffset
      //(0018,1146)
      = const PTag._(
          'RotationOffset', 0x00181146, 'Rotation Offset', VR.kDS, VM.k1_n, true);
  static const PTag kFieldOfViewShape
      //(0018,1147)
      = const PTag._(
          'FieldOfViewShape', 0x00181147, 'Field of View Shape', VR.kCS, VM.k1, false);
  static const PTag kFieldOfViewDimensions
      //(0018,1149)
      = const PTag._('FieldOfViewDimensions', 0x00181149, 'Field of View Dimension(s)',
          VR.kIS, VM.k1_2, false);
  static const PTag kExposureTime
      //(0018,1150)
      = const PTag._('ExposureTime', 0x00181150, 'Exposure Time', VR.kIS, VM.k1, false);
  static const PTag kXRayTubeCurrent
      //(0018,1151)
      = const PTag._(
          'XRayTubeCurrent', 0x00181151, 'X-Ray Tube Current', VR.kIS, VM.k1, false);
  static const PTag kExposure
      //(0018,1152)
      = const PTag._('Exposure', 0x00181152, 'Exposure', VR.kIS, VM.k1, false);
  static const PTag kExposureInuAs
      //(0018,1153)
      =
      const PTag._('ExposureInuAs', 0x00181153, 'Exposure in µAs', VR.kIS, VM.k1, false);
  static const PTag kAveragePulseWidth
      //(0018,1154)
      = const PTag._(
          'AveragePulseWidth', 0x00181154, 'Average Pulse Width', VR.kDS, VM.k1, false);
  static const PTag kRadiationSetting
      //(0018,1155)
      = const PTag._(
          'RadiationSetting', 0x00181155, 'Radiation Setting', VR.kCS, VM.k1, false);
  static const PTag kRectificationType
      //(0018,1156)
      = const PTag._(
          'RectificationType', 0x00181156, 'Rectification Type', VR.kCS, VM.k1, false);
  static const PTag kRadiationMode
      //(0018,115A)
      = const PTag._('RadiationMode', 0x0018115A, 'Radiation Mode', VR.kCS, VM.k1, false);
  static const PTag kImageAndFluoroscopyAreaDoseProduct
      //(0018,115E)
      = const PTag._('ImageAndFluoroscopyAreaDoseProduct', 0x0018115E,
          'Image and Fluoroscopy Area Dose Product', VR.kDS, VM.k1, false);
  static const PTag kFilterType
      //(0018,1160)
      = const PTag._('FilterType', 0x00181160, 'Filter Type', VR.kSH, VM.k1, false);
  static const PTag kTypeOfFilters
      //(0018,1161)
      = const PTag._(
          'TypeOfFilters', 0x00181161, 'Type of Filters', VR.kLO, VM.k1_n, false);
  static const PTag kIntensifierSize
      //(0018,1162)
      = const PTag._(
          'IntensifierSize', 0x00181162, 'Intensifier Size', VR.kDS, VM.k1, false);
  static const PTag kImagerPixelSpacing
      //(0018,1164)
      = const PTag._(
          'ImagerPixelSpacing', 0x00181164, 'Imager Pixel Spacing', VR.kDS, VM.k2, false);
  static const PTag kGrid
      //(0018,1166)
      = const PTag._('Grid', 0x00181166, 'Grid', VR.kCS, VM.k1_n, false);
  static const PTag kGeneratorPower
      //(0018,1170)
      =
      const PTag._('GeneratorPower', 0x00181170, 'Generator Power', VR.kIS, VM.k1, false);
  static const PTag kCollimatorGridName
      //(0018,1180)
      = const PTag._(
          'CollimatorGridName', 0x00181180, 'Collimator/grid Name', VR.kSH, VM.k1, false);
  static const PTag kCollimatorType
      //(0018,1181)
      =
      const PTag._('CollimatorType', 0x00181181, 'Collimator Type', VR.kCS, VM.k1, false);
  static const PTag kFocalDistance
      //(0018,1182)
      =
      const PTag._('FocalDistance', 0x00181182, 'Focal Distance', VR.kIS, VM.k1_2, false);
  static const PTag kXFocusCenter
      //(0018,1183)
      =
      const PTag._('XFocusCenter', 0x00181183, 'X Focus Center', VR.kDS, VM.k1_2, false);
  static const PTag kYFocusCenter
      //(0018,1184)
      =
      const PTag._('YFocusCenter', 0x00181184, 'Y Focus Center', VR.kDS, VM.k1_2, false);
  static const PTag kFocalSpots
      //(0018,1190)
      = const PTag._('FocalSpots', 0x00181190, 'Focal Spot(s)', VR.kDS, VM.k1_n, false);
  static const PTag kAnodeTargetMaterial
      //(0018,1191)
      = const PTag._('AnodeTargetMaterial', 0x00181191, 'Anode Target Material', VR.kCS,
          VM.k1, false);
  static const PTag kBodyPartThickness
      //(0018,11A0)
      = const PTag._(
          'BodyPartThickness', 0x001811A0, 'Body Part Thickness', VR.kDS, VM.k1, false);
  static const PTag kCompressionForce
      //(0018,11A2)
      = const PTag._(
          'CompressionForce', 0x001811A2, 'Compression Force', VR.kDS, VM.k1, false);
  static const PTag kPaddleDescription
      //(0018,11A4)
      = const PTag._(
          'PaddleDescription', 0x001811A4, 'Paddle Description', VR.kLO, VM.k1, false);
  static const PTag kDateOfLastCalibration
      //(0018,1200)
      = const PTag._('DateOfLastCalibration', 0x00181200, 'Date of Last Calibration',
          VR.kDA, VM.k1_n, false);
  static const PTag kTimeOfLastCalibration
      //(0018,1201)
      = const PTag._('TimeOfLastCalibration', 0x00181201, 'Time of Last Calibration',
          VR.kTM, VM.k1_n, false);
  static const PTag kDateTimeOfLastCalibration
      //(0018,1201)
      = const PTag._('DateTimeOfLastCalibration', 0x00181202, 'Time of Last Calibration',
          VR.kTM, VM.k1_n, false);
  static const PTag kConvolutionKernel
      //(0018,1210)
      = const PTag._(
          'ConvolutionKernel', 0x00181210, 'Convolution Kernel', VR.kSH, VM.k1_n, false);
  static const PTag kUpperLowerPixelValues
      //(0018,1240)
      = const PTag._('UpperLowerPixelValues', 0x00181240, 'Upper/Lower Pixel Values',
          VR.kIS, VM.k1_n, true);
  static const PTag kActualFrameDuration
      //(0018,1242)
      = const PTag._('ActualFrameDuration', 0x00181242, 'Actual Frame Duration', VR.kIS,
          VM.k1, false);
  static const PTag kCountRate
      //(0018,1243)
      = const PTag._('CountRate', 0x00181243, 'Count Rate', VR.kIS, VM.k1, false);
  static const PTag kPreferredPlaybackSequencing
      //(0018,1244)
      = const PTag._('PreferredPlaybackSequencing', 0x00181244,
          'Preferred Playback Sequencing', VR.kUS, VM.k1, false);
  static const PTag kReceiveCoilName
      //(0018,1250)
      = const PTag._(
          'ReceiveCoilName', 0x00181250, 'Receive Coil Name', VR.kSH, VM.k1, false);
  static const PTag kTransmitCoilName
      //(0018,1251)
      = const PTag._(
          'TransmitCoilName', 0x00181251, 'Transmit Coil Name', VR.kSH, VM.k1, false);
  static const PTag kPlateType
      //(0018,1260)
      = const PTag._('PlateType', 0x00181260, 'Plate Type', VR.kSH, VM.k1, false);
  static const PTag kPhosphorType
      //(0018,1261)
      = const PTag._('PhosphorType', 0x00181261, 'Phosphor Type', VR.kLO, VM.k1, false);
  static const PTag kScanVelocity
      //(0018,1300)
      = const PTag._('ScanVelocity', 0x00181300, 'Scan Velocity', VR.kDS, VM.k1, false);
  static const PTag kWholeBodyTechnique
      //(0018,1301)
      = const PTag._('WholeBodyTechnique', 0x00181301, 'Whole Body Technique', VR.kCS,
          VM.k1_n, false);
  static const PTag kScanLength
      //(0018,1302)
      = const PTag._('ScanLength', 0x00181302, 'Scan Length', VR.kIS, VM.k1, false);
  static const PTag kAcquisitionMatrix
      //(0018,1310)
      = const PTag._(
          'AcquisitionMatrix', 0x00181310, 'Acquisition Matrix', VR.kUS, VM.k4, false);
  static const PTag kInPlanePhaseEncodingDirection
      //(0018,1312)
      = const PTag._('InPlanePhaseEncodingDirection', 0x00181312,
          'In-plane Phase Encoding Direction', VR.kCS, VM.k1, false);
  static const PTag kFlipAngle
      //(0018,1314)
      = const PTag._('FlipAngle', 0x00181314, 'Flip Angle', VR.kDS, VM.k1, false);
  static const PTag kVariableFlipAngleFlag
      //(0018,1315)
      = const PTag._('VariableFlipAngleFlag', 0x00181315, 'Variable Flip Angle Flag',
          VR.kCS, VM.k1, false);
  static const PTag kSAR
      //(0018,1316)
      = const PTag._('SAR', 0x00181316, 'SAR', VR.kDS, VM.k1, false);
  static const PTag kdBdt
      //(0018,1318)
      = const PTag._('dBdt', 0x00181318, 'dB/dt', VR.kDS, VM.k1, false);
  static const PTag kAcquisitionDeviceProcessingDescription
      //(0018,1400)
      = const PTag._('AcquisitionDeviceProcessingDescription', 0x00181400,
          'Acquisition Device Processing Description', VR.kLO, VM.k1, false);
  static const PTag kAcquisitionDeviceProcessingCode
      //(0018,1401)
      = const PTag._('AcquisitionDeviceProcessingCode', 0x00181401,
          'Acquisition Device Processing Code', VR.kLO, VM.k1, false);
  static const PTag kCassetteOrientation
      //(0018,1402)
      = const PTag._('CassetteOrientation', 0x00181402, 'Cassette Orientation', VR.kCS,
          VM.k1, false);
  static const PTag kCassetteSize
      //(0018,1403)
      = const PTag._('CassetteSize', 0x00181403, 'Cassette Size', VR.kCS, VM.k1, false);
  static const PTag kExposuresOnPlate
      //(0018,1404)
      = const PTag._(
          'ExposuresOnPlate', 0x00181404, 'Exposures on Plate', VR.kUS, VM.k1, false);
  static const PTag kRelativeXRayExposure
      //(0018,1405)
      = const PTag._('RelativeXRayExposure', 0x00181405, 'Relative X-Ray Exposure',
          VR.kIS, VM.k1, false);
  static const PTag kExposureIndex
      //(0018,1411)
      = const PTag._('ExposureIndex', 0x00181411, 'Exposure Index', VR.kDS, VM.k1, false);
  static const PTag kTargetExposureIndex
      //(0018,1412)
      = const PTag._('TargetExposureIndex', 0x00181412, 'Target Exposure Index', VR.kDS,
          VM.k1, false);
  static const PTag kDeviationIndex
      //(0018,1413)
      =
      const PTag._('DeviationIndex', 0x00181413, 'Deviation Index', VR.kDS, VM.k1, false);
  static const PTag kColumnAngulation
      //(0018,1450)
      = const PTag._(
          'ColumnAngulation', 0x00181450, 'Column Angulation', VR.kDS, VM.k1, false);
  static const PTag kTomoLayerHeight
      //(0018,1460)
      = const PTag._(
          'TomoLayerHeight', 0x00181460, 'Tomo Layer Height', VR.kDS, VM.k1, false);
  static const PTag kTomoAngle
      //(0018,1470)
      = const PTag._('TomoAngle', 0x00181470, 'Tomo Angle', VR.kDS, VM.k1, false);
  static const PTag kTomoTime
      //(0018,1480)
      = const PTag._('TomoTime', 0x00181480, 'Tomo Time', VR.kDS, VM.k1, false);
  static const PTag kTomoType
      //(0018,1490)
      = const PTag._('TomoType', 0x00181490, 'Tomo Type', VR.kCS, VM.k1, false);
  static const PTag kTomoClass
      //(0018,1491)
      = const PTag._('TomoClass', 0x00181491, 'Tomo Class', VR.kCS, VM.k1, false);
  static const PTag kNumberOfTomosynthesisSourceImages
      //(0018,1495)
      = const PTag._('NumberOfTomosynthesisSourceImages', 0x00181495,
          'Number of Tomosynthesis Source Images', VR.kIS, VM.k1, false);
  static const PTag kPositionerMotion
      //(0018,1500)
      = const PTag._(
          'PositionerMotion', 0x00181500, 'Positioner Motion', VR.kCS, VM.k1, false);
  static const PTag kPositionerType
      //(0018,1508)
      =
      const PTag._('PositionerType', 0x00181508, 'Positioner Type', VR.kCS, VM.k1, false);
  static const PTag kPositionerPrimaryAngle
      //(0018,1510)
      = const PTag._('PositionerPrimaryAngle', 0x00181510, 'Positioner Primary Angle',
          VR.kDS, VM.k1, false);
  static const PTag kPositionerSecondaryAngle
      //(0018,1511)
      = const PTag._('PositionerSecondaryAngle', 0x00181511, 'Positioner Secondary Angle',
          VR.kDS, VM.k1, false);
  static const PTag kPositionerPrimaryAngleIncrement
      //(0018,1520)
      = const PTag._('PositionerPrimaryAngleIncrement', 0x00181520,
          'Positioner Primary Angle Increment', VR.kDS, VM.k1_n, false);
  static const PTag kPositionerSecondaryAngleIncrement
      //(0018,1521)
      = const PTag._('PositionerSecondaryAngleIncrement', 0x00181521,
          'Positioner Secondary Angle Increment', VR.kDS, VM.k1_n, false);
  static const PTag kDetectorPrimaryAngle
      //(0018,1530)
      = const PTag._('DetectorPrimaryAngle', 0x00181530, 'Detector Primary Angle', VR.kDS,
          VM.k1, false);
  static const PTag kDetectorSecondaryAngle
      //(0018,1531)
      = const PTag._('DetectorSecondaryAngle', 0x00181531, 'Detector Secondary Angle',
          VR.kDS, VM.k1, false);
  static const PTag kShutterShape
      //(0018,1600)
      = const PTag._('ShutterShape', 0x00181600, 'Shutter Shape', VR.kCS, VM.k1_3, false);
  static const PTag kShutterLeftVerticalEdge
      //(0018,1602)
      = const PTag._('ShutterLeftVerticalEdge', 0x00181602, 'Shutter Left Vertical Edge',
          VR.kIS, VM.k1, false);
  static const PTag kShutterRightVerticalEdge
      //(0018,1604)
      = const PTag._('ShutterRightVerticalEdge', 0x00181604,
          'Shutter Right Vertical Edge', VR.kIS, VM.k1, false);
  static const PTag kShutterUpperHorizontalEdge
      //(0018,1606)
      = const PTag._('ShutterUpperHorizontalEdge', 0x00181606,
          'Shutter Upper Horizontal Edge', VR.kIS, VM.k1, false);
  static const PTag kShutterLowerHorizontalEdge
      //(0018,1608)
      = const PTag._('ShutterLowerHorizontalEdge', 0x00181608,
          'Shutter Lower Horizontal Edge', VR.kIS, VM.k1, false);
  static const PTag kCenterOfCircularShutter
      //(0018,1610)
      = const PTag._('CenterOfCircularShutter', 0x00181610, 'Center of Circular Shutter',
          VR.kIS, VM.k2, false);
  static const PTag kRadiusOfCircularShutter
      //(0018,1612)
      = const PTag._('RadiusOfCircularShutter', 0x00181612, 'Radius of Circular Shutter',
          VR.kIS, VM.k1, false);
  static const PTag kVerticesOfThePolygonalShutter
      //(0018,1620)
      = const PTag._('VerticesOfThePolygonalShutter', 0x00181620,
          'Vertices of the Polygonal Shutter', VR.kIS, VM.k2_2n, false);
  static const PTag kShutterPresentationValue
      //(0018,1622)
      = const PTag._('ShutterPresentationValue', 0x00181622, 'Shutter Presentation Value',
          VR.kUS, VM.k1, false);
  static const PTag kShutterOverlayGroup
      //(0018,1623)
      = const PTag._('ShutterOverlayGroup', 0x00181623, 'Shutter Overlay Group', VR.kUS,
          VM.k1, false);
  static const PTag kShutterPresentationColorCIELabValue
      //(0018,1624)
      = const PTag._('ShutterPresentationColorCIELabValue', 0x00181624,
          'Shutter Presentation Color CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kCollimatorShape
      //(0018,1700)
      = const PTag._(
          'CollimatorShape', 0x00181700, 'Collimator Shape', VR.kCS, VM.k1_3, false);
  static const PTag kCollimatorLeftVerticalEdge
      //(0018,1702)
      = const PTag._('CollimatorLeftVerticalEdge', 0x00181702,
          'Collimator Left Vertical Edge', VR.kIS, VM.k1, false);
  static const PTag kCollimatorRightVerticalEdge
      //(0018,1704)
      = const PTag._('CollimatorRightVerticalEdge', 0x00181704,
          'Collimator Right Vertical Edge', VR.kIS, VM.k1, false);
  static const PTag kCollimatorUpperHorizontalEdge
      //(0018,1706)
      = const PTag._('CollimatorUpperHorizontalEdge', 0x00181706,
          'Collimator Upper Horizontal Edge', VR.kIS, VM.k1, false);
  static const PTag kCollimatorLowerHorizontalEdge
      //(0018,1708)
      = const PTag._('CollimatorLowerHorizontalEdge', 0x00181708,
          'Collimator Lower Horizontal Edge', VR.kIS, VM.k1, false);
  static const PTag kCenterOfCircularCollimator
      //(0018,1710)
      = const PTag._('CenterOfCircularCollimator', 0x00181710,
          'Center of Circular Collimator', VR.kIS, VM.k2, false);
  static const PTag kRadiusOfCircularCollimator
      //(0018,1712)
      = const PTag._('RadiusOfCircularCollimator', 0x00181712,
          'Radius of Circular Collimator', VR.kIS, VM.k1, false);
  static const PTag kVerticesOfThePolygonalCollimator
      //(0018,1720)
      = const PTag._('VerticesOfThePolygonalCollimator', 0x00181720,
          'Vertices of the Polygonal Collimator', VR.kIS, VM.k2_2n, false);
  static const PTag kAcquisitionTimeSynchronized
      //(0018,1800)
      = const PTag._('AcquisitionTimeSynchronized', 0x00181800,
          'Acquisition Time Synchronized', VR.kCS, VM.k1, false);
  static const PTag kTimeSource
      //(0018,1801)
      = const PTag._('TimeSource', 0x00181801, 'Time Source', VR.kSH, VM.k1, false);
  static const PTag kTimeDistributionProtocol
      //(0018,1802)
      = const PTag._('TimeDistributionProtocol', 0x00181802, 'Time Distribution Protocol',
          VR.kCS, VM.k1, false);
  static const PTag kNTPSourceAddress
      //(0018,1803)
      = const PTag._(
          'NTPSourceAddress', 0x00181803, 'NTP Source Address', VR.kLO, VM.k1, false);
  static const PTag kPageNumberVector
      //(0018,2001)
      = const PTag._(
          'PageNumberVector', 0x00182001, 'Page Number Vector', VR.kIS, VM.k1_n, false);
  static const PTag kFrameLabelVector
      //(0018,2002)
      = const PTag._(
          'FrameLabelVector', 0x00182002, 'Frame Label Vector', VR.kSH, VM.k1_n, false);
  static const PTag kFramePrimaryAngleVector
      //(0018,2003)
      = const PTag._('FramePrimaryAngleVector', 0x00182003, 'Frame Primary Angle Vector',
          VR.kDS, VM.k1_n, false);
  static const PTag kFrameSecondaryAngleVector
      //(0018,2004)
      = const PTag._('FrameSecondaryAngleVector', 0x00182004,
          'Frame Secondary Angle Vector', VR.kDS, VM.k1_n, false);
  static const PTag kSliceLocationVector
      //(0018,2005)
      = const PTag._('SliceLocationVector', 0x00182005, 'Slice Location Vector', VR.kDS,
          VM.k1_n, false);
  static const PTag kDisplayWindowLabelVector
      //(0018,2006)
      = const PTag._('DisplayWindowLabelVector', 0x00182006,
          'Display Window Label Vector', VR.kSH, VM.k1_n, false);
  static const PTag kNominalScannedPixelSpacing
      //(0018,2010)
      = const PTag._('NominalScannedPixelSpacing', 0x00182010,
          'Nominal Scanned Pixel Spacing', VR.kDS, VM.k2, false);
  static const PTag kDigitizingDeviceTransportDirection
      //(0018,2020)
      = const PTag._('DigitizingDeviceTransportDirection', 0x00182020,
          'Digitizing Device Transport Direction', VR.kCS, VM.k1, false);
  static const PTag kRotationOfScannedFilm
      //(0018,2030)
      = const PTag._('RotationOfScannedFilm', 0x00182030, 'Rotation of Scanned Film',
          VR.kDS, VM.k1, false);
  static const PTag kBiopsyTargetSequence
      //(0018,2041)
      = const PTag._('BiopsyTargetSequence', 0x00182041, 'Biopsy Target Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kTargetUID
      //(0018,2042)
      = const PTag._('TargetUID', 0x00182042, 'Target UID', VR.kUI, VM.k1, false);
  static const PTag kLocalizingCursorPosition
      //(0018,2043)
      = const PTag._('LocalizingCursorPosition', 0x00182043, 'Localizing Cursor Position',
          VR.kFL, VM.k2, false);
  static const PTag kCalculatedTargetPosition
      //(0018,2044)
      = const PTag._('CalculatedTargetPosition', 0x00182044, 'Calculated Target Position',
          VR.kFL, VM.k3, false);
  static const PTag kTargetLabel
      //(0018,2045)
      = const PTag._('TargetLabel', 0x00182045, 'Target Label', VR.kSH, VM.k1, false);
  static const PTag kDisplayedZValue
      //(0018,2046)
      = const PTag._(
          'DisplayedZValue', 0x00182046, 'Displayed Z Value', VR.kFL, VM.k1, false);
  static const PTag kIVUSAcquisition
      //(0018,3100)
      = const PTag._(
          'IVUSAcquisition', 0x00183100, 'IVUS Acquisition', VR.kCS, VM.k1, false);
  static const PTag kIVUSPullbackRate
      //(0018,3101)
      = const PTag._(
          'IVUSPullbackRate', 0x00183101, 'IVUS Pullback Rate', VR.kDS, VM.k1, false);
  static const PTag kIVUSGatedRate
      //(0018,3102)
      =
      const PTag._('IVUSGatedRate', 0x00183102, 'IVUS Gated Rate', VR.kDS, VM.k1, false);
  static const PTag kIVUSPullbackStartFrameNumber
      //(0018,3103)
      = const PTag._('IVUSPullbackStartFrameNumber', 0x00183103,
          'IVUS Pullback Start Frame Number', VR.kIS, VM.k1, false);
  static const PTag kIVUSPullbackStopFrameNumber
      //(0018,3104)
      = const PTag._('IVUSPullbackStopFrameNumber', 0x00183104,
          'IVUS Pullback Stop Frame Number', VR.kIS, VM.k1, false);
  static const PTag kLesionNumber
      //(0018,3105)
      = const PTag._('LesionNumber', 0x00183105, 'Lesion Number', VR.kIS, VM.k1_n, false);
  static const PTag kAcquisitionComments
      //(0018,4000)
      = const PTag._(
          'AcquisitionComments', 0x00184000, 'Acquisition Comments', VR.kLT, VM.k1, true);
  static const PTag kOutputPower
      //(0018,5000)
      = const PTag._('OutputPower', 0x00185000, 'Output Power', VR.kSH, VM.k1_n, false);
  static const PTag kTransducerData
      //(0018,5010)
      = const PTag._(
          'TransducerData', 0x00185010, 'Transducer Data', VR.kLO, VM.k1_n, false);
  static const PTag kFocusDepth
      //(0018,5012)
      = const PTag._('FocusDepth', 0x00185012, 'Focus Depth', VR.kDS, VM.k1, false);
  static const PTag kProcessingFunction
      //(0018,5020)
      = const PTag._(
          'ProcessingFunction', 0x00185020, 'Processing Function', VR.kLO, VM.k1, false);
  static const PTag kPostprocessingFunction
      //(0018,5021)
      = const PTag._('PostprocessingFunction', 0x00185021, 'Postprocessing Function',
          VR.kLO, VM.k1, true);
  static const PTag kMechanicalIndex
      //(0018,5022)
      = const PTag._(
          'MechanicalIndex', 0x00185022, 'Mechanical Index', VR.kDS, VM.k1, false);
  static const PTag kBoneThermalIndex
      //(0018,5024)
      = const PTag._(
          'BoneThermalIndex', 0x00185024, 'Bone Thermal Index', VR.kDS, VM.k1, false);
  static const PTag kCranialThermalIndex
      //(0018,5026)
      = const PTag._('CranialThermalIndex', 0x00185026, 'Cranial Thermal Index', VR.kDS,
          VM.k1, false);
  static const PTag kSoftTissueThermalIndex
      //(0018,5027)
      = const PTag._('SoftTissueThermalIndex', 0x00185027, 'Soft Tissue Thermal Index',
          VR.kDS, VM.k1, false);
  static const PTag kSoftTissueFocusThermalIndex
      //(0018,5028)
      = const PTag._('SoftTissueFocusThermalIndex', 0x00185028,
          'Soft Tissue-focus Thermal Index', VR.kDS, VM.k1, false);
  static const PTag kSoftTissueSurfaceThermalIndex
      //(0018,5029)
      = const PTag._('SoftTissueSurfaceThermalIndex', 0x00185029,
          'Soft Tissue-surface Thermal Index', VR.kDS, VM.k1, false);
  static const PTag kDynamicRange
      //(0018,5030)
      = const PTag._('DynamicRange', 0x00185030, 'Dynamic Range', VR.kDS, VM.k1, true);
  static const PTag kTotalGain
      //(0018,5040)
      = const PTag._('TotalGain', 0x00185040, 'Total Gain', VR.kDS, VM.k1, true);
  static const PTag kDepthOfScanField
      //(0018,5050)
      = const PTag._(
          'DepthOfScanField', 0x00185050, 'Depth of Scan Field', VR.kIS, VM.k1, false);
  static const PTag kPatientPosition
      //(0018,5100)
      = const PTag._(
          'PatientPosition', 0x00185100, 'Patient Position', VR.kCS, VM.k1, false);
  static const PTag kViewPosition
      //(0018,5101)
      = const PTag._('ViewPosition', 0x00185101, 'View Position', VR.kCS, VM.k1, false);
  static const PTag kProjectionEponymousNameCodeSequence
      //(0018,5104)
      = const PTag._('ProjectionEponymousNameCodeSequence', 0x00185104,
          'Projection Eponymous Name Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageTransformationMatrix
      //(0018,5210)
      = const PTag._('ImageTransformationMatrix', 0x00185210,
          'Image Transformation Matrix', VR.kDS, VM.k6, true);
  static const PTag kImageTranslationVector
      //(0018,5212)
      = const PTag._('ImageTranslationVector', 0x00185212, 'Image Translation Vector',
          VR.kDS, VM.k3, true);
  static const PTag kSensitivity
      //(0018,6000)
      = const PTag._('Sensitivity', 0x00186000, 'Sensitivity', VR.kDS, VM.k1, false);
  static const PTag kSequenceOfUltrasoundRegions
      //(0018,6011)
      = const PTag._('SequenceOfUltrasoundRegions', 0x00186011,
          'Sequence of Ultrasound Regions', VR.kSQ, VM.k1, false);
  static const PTag kRegionSpatialFormat
      //(0018,6012)
      = const PTag._('RegionSpatialFormat', 0x00186012, 'Region Spatial Format', VR.kUS,
          VM.k1, false);
  static const PTag kRegionDataType
      //(0018,6014)
      = const PTag._(
          'RegionDataType', 0x00186014, 'Region Data Type', VR.kUS, VM.k1, false);
  static const PTag kRegionFlags
      //(0018,6016)
      = const PTag._('RegionFlags', 0x00186016, 'Region Flags', VR.kUL, VM.k1, false);
  static const PTag kRegionLocationMinX0
      //(0018,6018)
      = const PTag._('RegionLocationMinX0', 0x00186018, 'Region Location Min X0', VR.kUL,
          VM.k1, false);
  static const PTag kRegionLocationMinY0
      //(0018,601A)
      = const PTag._('RegionLocationMinY0', 0x0018601A, 'Region Location Min Y0', VR.kUL,
          VM.k1, false);
  static const PTag kRegionLocationMaxX1
      //(0018,601C)
      = const PTag._('RegionLocationMaxX1', 0x0018601C, 'Region Location Max X1', VR.kUL,
          VM.k1, false);
  static const PTag kRegionLocationMaxY1
      //(0018,601E)
      = const PTag._('RegionLocationMaxY1', 0x0018601E, 'Region Location Max Y1', VR.kUL,
          VM.k1, false);
  static const PTag kReferencePixelX0
      //(0018,6020)
      = const PTag._(
          'ReferencePixelX0', 0x00186020, 'Reference Pixel X0', VR.kSL, VM.k1, false);
  static const PTag kReferencePixelY0
      //(0018,6022)
      = const PTag._(
          'ReferencePixelY0', 0x00186022, 'Reference Pixel Y0', VR.kSL, VM.k1, false);
  static const PTag kPhysicalUnitsXDirection
      //(0018,6024)
      = const PTag._('PhysicalUnitsXDirection', 0x00186024, 'Physical Units X Direction',
          VR.kUS, VM.k1, false);
  static const PTag kPhysicalUnitsYDirection
      //(0018,6026)
      = const PTag._('PhysicalUnitsYDirection', 0x00186026, 'Physical Units Y Direction',
          VR.kUS, VM.k1, false);
  static const PTag kReferencePixelPhysicalValueX
      //(0018,6028)
      = const PTag._('ReferencePixelPhysicalValueX', 0x00186028,
          'Reference Pixel Physical Value X', VR.kFD, VM.k1, false);
  static const PTag kReferencePixelPhysicalValueY
      //(0018,602A)
      = const PTag._('ReferencePixelPhysicalValueY', 0x0018602A,
          'Reference Pixel Physical Value Y', VR.kFD, VM.k1, false);
  static const PTag kPhysicalDeltaX
      //(0018,602C)
      = const PTag._(
          'PhysicalDeltaX', 0x0018602C, 'Physical Delta X', VR.kFD, VM.k1, false);
  static const PTag kPhysicalDeltaY
      //(0018,602E)
      = const PTag._(
          'PhysicalDeltaY', 0x0018602E, 'Physical Delta Y', VR.kFD, VM.k1, false);
  static const PTag kTransducerFrequency
      //(0018,6030)
      = const PTag._('TransducerFrequency', 0x00186030, 'Transducer Frequency', VR.kUL,
          VM.k1, false);
  static const PTag kTransducerType
      //(0018,6031)
      =
      const PTag._('TransducerType', 0x00186031, 'Transducer Type', VR.kCS, VM.k1, false);
  static const PTag kPulseRepetitionFrequency
      //(0018,6032)
      = const PTag._('PulseRepetitionFrequency', 0x00186032, 'Pulse Repetition Frequency',
          VR.kUL, VM.k1, false);
  static const PTag kDopplerCorrectionAngle
      //(0018,6034)
      = const PTag._('DopplerCorrectionAngle', 0x00186034, 'Doppler Correction Angle',
          VR.kFD, VM.k1, false);
  static const PTag kSteeringAngle
      //(0018,6036)
      = const PTag._('SteeringAngle', 0x00186036, 'Steering Angle', VR.kFD, VM.k1, false);
  static const PTag kDopplerSampleVolumeXPositionRetired
      //(0018,6038)
      = const PTag._('DopplerSampleVolumeXPositionRetired', 0x00186038,
          'Doppler Sample Volume X Position (Retired)', VR.kUL, VM.k1, true);
  static const PTag kDopplerSampleVolumeXPosition
      //(0018,6039)
      = const PTag._('DopplerSampleVolumeXPosition', 0x00186039,
          'Doppler Sample Volume X Position', VR.kSL, VM.k1, false);
  static const PTag kDopplerSampleVolumeYPositionRetired
      //(0018,603A)
      = const PTag._('DopplerSampleVolumeYPositionRetired', 0x0018603A,
          'Doppler Sample Volume Y Position (Retired)', VR.kUL, VM.k1, true);
  static const PTag kDopplerSampleVolumeYPosition
      //(0018,603B)
      = const PTag._('DopplerSampleVolumeYPosition', 0x0018603B,
          'Doppler Sample Volume Y Position', VR.kSL, VM.k1, false);
  static const PTag kTMLinePositionX0Retired
      //(0018,603C)
      = const PTag._('TMLinePositionX0Retired', 0x0018603C,
          'TM-Line Position X0 (Retired)', VR.kUL, VM.k1, true);
  static const PTag kTMLinePositionX0
      //(0018,603D)
      = const PTag._(
          'TMLinePositionX0', 0x0018603D, 'TM-Line Position X0', VR.kSL, VM.k1, false);
  static const PTag kTMLinePositionY0Retired
      //(0018,603E)
      = const PTag._('TMLinePositionY0Retired', 0x0018603E,
          'TM-Line Position Y0 (Retired)', VR.kUL, VM.k1, true);
  static const PTag kTMLinePositionY0
      //(0018,603F)
      = const PTag._(
          'TMLinePositionY0', 0x0018603F, 'TM-Line Position Y0', VR.kSL, VM.k1, false);
  static const PTag kTMLinePositionX1Retired
      //(0018,6040)
      = const PTag._('TMLinePositionX1Retired', 0x00186040,
          'TM-Line Position X1 (Retired)', VR.kUL, VM.k1, true);
  static const PTag kTMLinePositionX1
      //(0018,6041)
      = const PTag._(
          'TMLinePositionX1', 0x00186041, 'TM-Line Position X1', VR.kSL, VM.k1, false);
  static const PTag kTMLinePositionY1Retired
      //(0018,6042)
      = const PTag._('TMLinePositionY1Retired', 0x00186042,
          'TM-Line Position Y1 (Retired)', VR.kUL, VM.k1, true);
  static const PTag kTMLinePositionY1
      //(0018,6043)
      = const PTag._(
          'TMLinePositionY1', 0x00186043, 'TM-Line Position Y1', VR.kSL, VM.k1, false);
  static const PTag kPixelComponentOrganization
      //(0018,6044)
      = const PTag._('PixelComponentOrganization', 0x00186044,
          'Pixel Component Organization', VR.kUS, VM.k1, false);
  static const PTag kPixelComponentMask
      //(0018,6046)
      = const PTag._(
          'PixelComponentMask', 0x00186046, 'Pixel Component Mask', VR.kUL, VM.k1, false);
  static const PTag kPixelComponentRangeStart
      //(0018,6048)
      = const PTag._('PixelComponentRangeStart', 0x00186048,
          'Pixel Component Range Start', VR.kUL, VM.k1, false);
  static const PTag kPixelComponentRangeStop
      //(0018,604A)
      = const PTag._('PixelComponentRangeStop', 0x0018604A, 'Pixel Component Range Stop',
          VR.kUL, VM.k1, false);
  static const PTag kPixelComponentPhysicalUnits
      //(0018,604C)
      = const PTag._('PixelComponentPhysicalUnits', 0x0018604C,
          'Pixel Component Physical Units', VR.kUS, VM.k1, false);
  static const PTag kPixelComponentDataType
      //(0018,604E)
      = const PTag._('PixelComponentDataType', 0x0018604E, 'Pixel Component Data Type',
          VR.kUS, VM.k1, false);
  static const PTag kNumberOfTableBreakPoints
      //(0018,6050)
      = const PTag._('NumberOfTableBreakPoints', 0x00186050,
          'Number of Table Break Points', VR.kUL, VM.k1, false);
  static const PTag kTableOfXBreakPoints
      //(0018,6052)
      = const PTag._('TableOfXBreakPoints', 0x00186052, 'Table of X Break Points', VR.kUL,
          VM.k1_n, false);
  static const PTag kTableOfYBreakPoints
      //(0018,6054)
      = const PTag._('TableOfYBreakPoints', 0x00186054, 'Table of Y Break Points', VR.kFD,
          VM.k1_n, false);
  static const PTag kNumberOfTableEntries
      //(0018,6056)
      = const PTag._('NumberOfTableEntries', 0x00186056, 'Number of Table Entries',
          VR.kUL, VM.k1, false);
  static const PTag kTableOfPixelValues
      //(0018,6058)
      = const PTag._('TableOfPixelValues', 0x00186058, 'Table of Pixel Values', VR.kUL,
          VM.k1_n, false);
  static const PTag kTableOfParameterValues
      //(0018,605A)
      = const PTag._('TableOfParameterValues', 0x0018605A, 'Table of Parameter Values',
          VR.kFL, VM.k1_n, false);
  static const PTag kRWaveTimeVector
      //(0018,6060)
      = const PTag._(
          'RWaveTimeVector', 0x00186060, 'R Wave Time Vector', VR.kFL, VM.k1_n, false);
  static const PTag kDetectorConditionsNominalFlag
      //(0018,7000)
      = const PTag._('DetectorConditionsNominalFlag', 0x00187000,
          'Detector Conditions Nominal Flag', VR.kCS, VM.k1, false);
  static const PTag kDetectorTemperature
      //(0018,7001)
      = const PTag._('DetectorTemperature', 0x00187001, 'Detector Temperature', VR.kDS,
          VM.k1, false);
  static const PTag kDetectorType
      //(0018,7004)
      = const PTag._('DetectorType', 0x00187004, 'Detector Type', VR.kCS, VM.k1, false);
  static const PTag kDetectorConfiguration
      //(0018,7005)
      = const PTag._('DetectorConfiguration', 0x00187005, 'Detector Configuration',
          VR.kCS, VM.k1, false);
  static const PTag kDetectorDescription
      //(0018,7006)
      = const PTag._('DetectorDescription', 0x00187006, 'Detector Description', VR.kLT,
          VM.k1, false);
  static const PTag kDetectorMode
      //(0018,7008)
      = const PTag._('DetectorMode', 0x00187008, 'Detector Mode', VR.kLT, VM.k1, false);
  static const PTag kDetectorID
      //(0018,700A)
      = const PTag._('DetectorID', 0x0018700A, 'Detector ID', VR.kSH, VM.k1, false);
  static const PTag kDateOfLastDetectorCalibration
      //(0018,700C)
      = const PTag._('DateOfLastDetectorCalibration', 0x0018700C,
          'Date of Last Detector Calibration', VR.kDA, VM.k1, false);
  static const PTag kTimeOfLastDetectorCalibration
      //(0018,700E)
      = const PTag._('TimeOfLastDetectorCalibration', 0x0018700E,
          'Time of Last Detector Calibration', VR.kTM, VM.k1, false);
  static const PTag kExposuresOnDetectorSinceLastCalibration
      //(0018,7010)
      = const PTag._('ExposuresOnDetectorSinceLastCalibration', 0x00187010,
          'Exposures on Detector Since Last Calibration', VR.kIS, VM.k1, false);
  static const PTag kExposuresOnDetectorSinceManufactured
      //(0018,7011)
      = const PTag._('ExposuresOnDetectorSinceManufactured', 0x00187011,
          'Exposures on Detector Since Manufactured', VR.kIS, VM.k1, false);
  static const PTag kDetectorTimeSinceLastExposure
      //(0018,7012)
      = const PTag._('DetectorTimeSinceLastExposure', 0x00187012,
          'Detector Time Since Last Exposure', VR.kDS, VM.k1, false);
  static const PTag kDetectorActiveTime
      //(0018,7014)
      = const PTag._(
          'DetectorActiveTime', 0x00187014, 'Detector Active Time', VR.kDS, VM.k1, false);
  static const PTag kDetectorActivationOffsetFromExposure
      //(0018,7016)
      = const PTag._('DetectorActivationOffsetFromExposure', 0x00187016,
          'Detector Activation Offset From Exposure', VR.kDS, VM.k1, false);
  static const PTag kDetectorBinning
      //(0018,701A)
      = const PTag._(
          'DetectorBinning', 0x0018701A, 'Detector Binning', VR.kDS, VM.k2, false);
  static const PTag kDetectorElementPhysicalSize
      //(0018,7020)
      = const PTag._('DetectorElementPhysicalSize', 0x00187020,
          'Detector Element Physical Size', VR.kDS, VM.k2, false);
  static const PTag kDetectorElementSpacing
      //(0018,7022)
      = const PTag._('DetectorElementSpacing', 0x00187022, 'Detector Element Spacing',
          VR.kDS, VM.k2, false);
  static const PTag kDetectorActiveShape
      //(0018,7024)
      = const PTag._('DetectorActiveShape', 0x00187024, 'Detector Active Shape', VR.kCS,
          VM.k1, false);
  static const PTag kDetectorActiveDimensions
      //(0018,7026)
      = const PTag._('DetectorActiveDimensions', 0x00187026,
          'Detector Active Dimension(s)', VR.kDS, VM.k1_2, false);
  static const PTag kDetectorActiveOrigin
      //(0018,7028)
      = const PTag._('DetectorActiveOrigin', 0x00187028, 'Detector Active Origin', VR.kDS,
          VM.k2, false);
  static const PTag kDetectorManufacturerName
      //(0018,702A)
      = const PTag._('DetectorManufacturerName', 0x0018702A, 'Detector Manufacturer Name',
          VR.kLO, VM.k1, false);
  static const PTag kDetectorManufacturerModelName
      //(0018,702B)
      = const PTag._('DetectorManufacturerModelName', 0x0018702B,
          'Detector Manufacturer\'s Model Name', VR.kLO, VM.k1, false);
  static const PTag kFieldOfViewOrigin
      //(0018,7030)
      = const PTag._(
          'FieldOfViewOrigin', 0x00187030, 'Field of View Origin', VR.kDS, VM.k2, false);
  static const PTag kFieldOfViewRotation
      //(0018,7032)
      = const PTag._('FieldOfViewRotation', 0x00187032, 'Field of View Rotation', VR.kDS,
          VM.k1, false);
  static const PTag kFieldOfViewHorizontalFlip
      //(0018,7034)
      = const PTag._('FieldOfViewHorizontalFlip', 0x00187034,
          'Field of View Horizontal Flip', VR.kCS, VM.k1, false);
  static const PTag kPixelDataAreaOriginRelativeToFOV
      //(0018,7036)
      = const PTag._('PixelDataAreaOriginRelativeToFOV', 0x00187036,
          'Pixel Data Area Origin Relative To FOV', VR.kFL, VM.k2, false);
  static const PTag kPixelDataAreaRotationAngleRelativeToFOV
      //(0018,7038)
      = const PTag._('PixelDataAreaRotationAngleRelativeToFOV', 0x00187038,
          'Pixel Data Area Rotation Angle Relative To FOV', VR.kFL, VM.k1, false);
  static const PTag kGridAbsorbingMaterial
      //(0018,7040)
      = const PTag._('GridAbsorbingMaterial', 0x00187040, 'Grid Absorbing Material',
          VR.kLT, VM.k1, false);
  static const PTag kGridSpacingMaterial
      //(0018,7041)
      = const PTag._('GridSpacingMaterial', 0x00187041, 'Grid Spacing Material', VR.kLT,
          VM.k1, false);
  static const PTag kGridThickness
      //(0018,7042)
      = const PTag._('GridThickness', 0x00187042, 'Grid Thickness', VR.kDS, VM.k1, false);
  static const PTag kGridPitch
      //(0018,7044)
      = const PTag._('GridPitch', 0x00187044, 'Grid Pitch', VR.kDS, VM.k1, false);
  static const PTag kGridAspectRatio
      //(0018,7046)
      = const PTag._(
          'GridAspectRatio', 0x00187046, 'Grid Aspect Ratio', VR.kIS, VM.k2, false);
  static const PTag kGridPeriod
      //(0018,7048)
      = const PTag._('GridPeriod', 0x00187048, 'Grid Period', VR.kDS, VM.k1, false);
  static const PTag kGridFocalDistance
      //(0018,704C)
      = const PTag._(
          'GridFocalDistance', 0x0018704C, 'Grid Focal Distance', VR.kDS, VM.k1, false);
  static const PTag kFilterMaterial
      //(0018,7050)
      = const PTag._(
          'FilterMaterial', 0x00187050, 'Filter Material', VR.kCS, VM.k1_n, false);
  static const PTag kFilterThicknessMinimum
      //(0018,7052)
      = const PTag._('FilterThicknessMinimum', 0x00187052, 'Filter Thickness Minimum',
          VR.kDS, VM.k1_n, false);
  static const PTag kFilterThicknessMaximum
      //(0018,7054)
      = const PTag._('FilterThicknessMaximum', 0x00187054, 'Filter Thickness Maximum',
          VR.kDS, VM.k1_n, false);
  static const PTag kFilterBeamPathLengthMinimum
      //(0018,7056)
      = const PTag._('FilterBeamPathLengthMinimum', 0x00187056,
          'Filter Beam Path Length Minimum', VR.kFL, VM.k1_n, false);
  static const PTag kFilterBeamPathLengthMaximum
      //(0018,7058)
      = const PTag._('FilterBeamPathLengthMaximum', 0x00187058,
          'Filter Beam Path Length Maximum', VR.kFL, VM.k1_n, false);
  static const PTag kExposureControlMode
      //(0018,7060)
      = const PTag._('ExposureControlMode', 0x00187060, 'Exposure Control Mode', VR.kCS,
          VM.k1, false);
  static const PTag kExposureControlModeDescription
      //(0018,7062)
      = const PTag._('ExposureControlModeDescription', 0x00187062,
          'Exposure Control Mode Description', VR.kLT, VM.k1, false);
  static const PTag kExposureStatus
      //(0018,7064)
      =
      const PTag._('ExposureStatus', 0x00187064, 'Exposure Status', VR.kCS, VM.k1, false);
  static const PTag kPhototimerSetting
      //(0018,7065)
      = const PTag._(
          'PhototimerSetting', 0x00187065, 'Phototimer Setting', VR.kDS, VM.k1, false);
  static const PTag kExposureTimeInuS
      //(0018,8150)
      = const PTag._(
          'ExposureTimeInuS', 0x00188150, 'Exposure Time in µS', VR.kDS, VM.k1, false);
  static const PTag kXRayTubeCurrentInuA
      //(0018,8151)
      = const PTag._('XRayTubeCurrentInuA', 0x00188151, 'X-Ray Tube Current in µA',
          VR.kDS, VM.k1, false);
  static const PTag kContentQualification
      //(0018,9004)
      = const PTag._('ContentQualification', 0x00189004, 'Content Qualification', VR.kCS,
          VM.k1, false);
  static const PTag kPulseSequenceName
      //(0018,9005)
      = const PTag._(
          'PulseSequenceName', 0x00189005, 'Pulse Sequence Name', VR.kSH, VM.k1, false);
  static const PTag kMRImagingModifierSequence
      //(0018,9006)
      = const PTag._('MRImagingModifierSequence', 0x00189006,
          'MR Imaging Modifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEchoPulseSequence
      //(0018,9008)
      = const PTag._(
          'EchoPulseSequence', 0x00189008, 'Echo Pulse Sequence', VR.kCS, VM.k1, false);
  static const PTag kInversionRecovery
      //(0018,9009)
      = const PTag._(
          'InversionRecovery', 0x00189009, 'Inversion Recovery', VR.kCS, VM.k1, false);
  static const PTag kFlowCompensation
      //(0018,9010)
      = const PTag._(
          'FlowCompensation', 0x00189010, 'Flow Compensation', VR.kCS, VM.k1, false);
  static const PTag kMultipleSpinEcho
      //(0018,9011)
      = const PTag._(
          'MultipleSpinEcho', 0x00189011, 'Multiple Spin Echo', VR.kCS, VM.k1, false);
  static const PTag kMultiPlanarExcitation
      //(0018,9012)
      = const PTag._('MultiPlanarExcitation', 0x00189012, 'Multi-planar Excitation',
          VR.kCS, VM.k1, false);
  static const PTag kPhaseContrast
      //(0018,9014)
      = const PTag._('PhaseContrast', 0x00189014, 'Phase Contrast', VR.kCS, VM.k1, false);
  static const PTag kTimeOfFlightContrast
      //(0018,9015)
      = const PTag._('TimeOfFlightContrast', 0x00189015, 'Time of Flight Contrast',
          VR.kCS, VM.k1, false);
  static const PTag kSpoiling
      //(0018,9016)
      = const PTag._('Spoiling', 0x00189016, 'Spoiling', VR.kCS, VM.k1, false);
  static const PTag kSteadyStatePulseSequence
      //(0018,9017)
      = const PTag._('SteadyStatePulseSequence', 0x00189017,
          'Steady State Pulse Sequence', VR.kCS, VM.k1, false);
  static const PTag kEchoPlanarPulseSequence
      //(0018,9018)
      = const PTag._('EchoPlanarPulseSequence', 0x00189018, 'Echo Planar Pulse Sequence',
          VR.kCS, VM.k1, false);
  static const PTag kTagAngleFirstAxis
      //(0018,9019)
      = const PTag._(
          'TagAngleFirstAxis', 0x00189019, 'Tag Angle First Axis', VR.kFD, VM.k1, false);
  static const PTag kMagnetizationTransfer
      //(0018,9020)
      = const PTag._('MagnetizationTransfer', 0x00189020, 'Magnetization Transfer',
          VR.kCS, VM.k1, false);
  static const PTag kT2Preparation
      //(0018,9021)
      = const PTag._('T2Preparation', 0x00189021, 'T2 Preparation', VR.kCS, VM.k1, false);
  static const PTag kBloodSignalNulling
      //(0018,9022)
      = const PTag._(
          'BloodSignalNulling', 0x00189022, 'Blood Signal Nulling', VR.kCS, VM.k1, false);
  static const PTag kSaturationRecovery
      //(0018,9024)
      = const PTag._(
          'SaturationRecovery', 0x00189024, 'Saturation Recovery', VR.kCS, VM.k1, false);
  static const PTag kSpectrallySelectedSuppression
      //(0018,9025)
      = const PTag._('SpectrallySelectedSuppression', 0x00189025,
          'Spectrally Selected Suppression', VR.kCS, VM.k1, false);
  static const PTag kSpectrallySelectedExcitation
      //(0018,9026)
      = const PTag._('SpectrallySelectedExcitation', 0x00189026,
          'Spectrally Selected Excitation', VR.kCS, VM.k1, false);
  static const PTag kSpatialPresaturation
      //(0018,9027)
      = const PTag._('SpatialPresaturation', 0x00189027, 'Spatial Pre-saturation', VR.kCS,
          VM.k1, false);
  static const PTag kTagging
      //(0018,9028)
      = const PTag._('Tagging', 0x00189028, 'Tagging', VR.kCS, VM.k1, false);
  static const PTag kOversamplingPhase
      //(0018,9029)
      = const PTag._(
          'OversamplingPhase', 0x00189029, 'Oversampling Phase', VR.kCS, VM.k1, false);
  static const PTag kTagSpacingFirstDimension
      //(0018,9030)
      = const PTag._('TagSpacingFirstDimension', 0x00189030,
          'Tag Spacing First Dimension', VR.kFD, VM.k1, false);
  static const PTag kGeometryOfKSpaceTraversal
      //(0018,9032)
      = const PTag._('GeometryOfKSpaceTraversal', 0x00189032,
          'Geometry of k-Space Traversal', VR.kCS, VM.k1, false);
  static const PTag kSegmentedKSpaceTraversal
      //(0018,9033)
      = const PTag._('SegmentedKSpaceTraversal', 0x00189033,
          'Segmented k-Space Traversal', VR.kCS, VM.k1, false);
  static const PTag kRectilinearPhaseEncodeReordering
      //(0018,9034)
      = const PTag._('RectilinearPhaseEncodeReordering', 0x00189034,
          'Rectilinear Phase Encode Reordering', VR.kCS, VM.k1, false);
  static const PTag kTagThickness
      //(0018,9035)
      = const PTag._('TagThickness', 0x00189035, 'Tag Thickness', VR.kFD, VM.k1, false);
  static const PTag kPartialFourierDirection
      //(0018,9036)
      = const PTag._('PartialFourierDirection', 0x00189036, 'Partial Fourier Direction',
          VR.kCS, VM.k1, false);
  static const PTag kCardiacSynchronizationTechnique
      //(0018,9037)
      = const PTag._('CardiacSynchronizationTechnique', 0x00189037,
          'Cardiac Synchronization Technique', VR.kCS, VM.k1, false);
  static const PTag kReceiveCoilManufacturerName
      //(0018,9041)
      = const PTag._('ReceiveCoilManufacturerName', 0x00189041,
          'Receive Coil Manufacturer Name', VR.kLO, VM.k1, false);
  static const PTag kMRReceiveCoilSequence
      //(0018,9042)
      = const PTag._('MRReceiveCoilSequence', 0x00189042, 'MR Receive Coil Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReceiveCoilType
      //(0018,9043)
      = const PTag._(
          'ReceiveCoilType', 0x00189043, 'Receive Coil Type', VR.kCS, VM.k1, false);
  static const PTag kQuadratureReceiveCoil
      //(0018,9044)
      = const PTag._('QuadratureReceiveCoil', 0x00189044, 'Quadrature Receive Coil',
          VR.kCS, VM.k1, false);
  static const PTag kMultiCoilDefinitionSequence
      //(0018,9045)
      = const PTag._('MultiCoilDefinitionSequence', 0x00189045,
          'Multi-Coil Definition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMultiCoilConfiguration
      //(0018,9046)
      = const PTag._('MultiCoilConfiguration', 0x00189046, 'Multi-Coil Configuration',
          VR.kLO, VM.k1, false);
  static const PTag kMultiCoilElementName
      //(0018,9047)
      = const PTag._('MultiCoilElementName', 0x00189047, 'Multi-Coil Element Name',
          VR.kSH, VM.k1, false);
  static const PTag kMultiCoilElementUsed
      //(0018,9048)
      = const PTag._('MultiCoilElementUsed', 0x00189048, 'Multi-Coil Element Used',
          VR.kCS, VM.k1, false);
  static const PTag kMRTransmitCoilSequence
      //(0018,9049)
      = const PTag._('MRTransmitCoilSequence', 0x00189049, 'MR Transmit Coil Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTransmitCoilManufacturerName
      //(0018,9050)
      = const PTag._('TransmitCoilManufacturerName', 0x00189050,
          'Transmit Coil Manufacturer Name', VR.kLO, VM.k1, false);
  static const PTag kTransmitCoilType
      //(0018,9051)
      = const PTag._(
          'TransmitCoilType', 0x00189051, 'Transmit Coil Type', VR.kCS, VM.k1, false);
  static const PTag kSpectralWidth
      //(0018,9052)
      =
      const PTag._('SpectralWidth', 0x00189052, 'Spectral Width', VR.kFD, VM.k1_2, false);
  static const PTag kChemicalShiftReference
      //(0018,9053)
      = const PTag._('ChemicalShiftReference', 0x00189053, 'Chemical Shift Reference',
          VR.kFD, VM.k1_2, false);
  static const PTag kVolumeLocalizationTechnique
      //(0018,9054)
      = const PTag._('VolumeLocalizationTechnique', 0x00189054,
          'Volume Localization Technique', VR.kCS, VM.k1, false);
  static const PTag kMRAcquisitionFrequencyEncodingSteps
      //(0018,9058)
      = const PTag._('MRAcquisitionFrequencyEncodingSteps', 0x00189058,
          'MR Acquisition Frequency Encoding Steps', VR.kUS, VM.k1, false);
  static const PTag kDecoupling
      //(0018,9059)
      = const PTag._('Decoupling', 0x00189059, 'De-coupling', VR.kCS, VM.k1, false);
  static const PTag kDecoupledNucleus
      //(0018,9060)
      = const PTag._(
          'DecoupledNucleus', 0x00189060, 'De-coupled Nucleus', VR.kCS, VM.k1_2, false);
  static const PTag kDecouplingFrequency
      //(0018,9061)
      = const PTag._('DecouplingFrequency', 0x00189061, 'De-coupling Frequency', VR.kFD,
          VM.k1_2, false);
  static const PTag kDecouplingMethod
      //(0018,9062)
      = const PTag._(
          'DecouplingMethod', 0x00189062, 'De-coupling Method', VR.kCS, VM.k1, false);
  static const PTag kDecouplingChemicalShiftReference
      //(0018,9063)
      = const PTag._('DecouplingChemicalShiftReference', 0x00189063,
          'De-coupling Chemical Shift Reference', VR.kFD, VM.k1_2, false);
  static const PTag kKSpaceFiltering
      //(0018,9064)
      = const PTag._(
          'KSpaceFiltering', 0x00189064, 'k-space Filtering', VR.kCS, VM.k1, false);
  static const PTag kTimeDomainFiltering
      //(0018,9065)
      = const PTag._('TimeDomainFiltering', 0x00189065, 'Time Domain Filtering', VR.kCS,
          VM.k1_2, false);
  static const PTag kNumberOfZeroFills
      //(0018,9066)
      = const PTag._('NumberOfZeroFills', 0x00189066, 'Number of Zero Fills', VR.kUS,
          VM.k1_2, false);
  static const PTag kBaselineCorrection
      //(0018,9067)
      = const PTag._(
          'BaselineCorrection', 0x00189067, 'Baseline Correction', VR.kCS, VM.k1, false);
  static const PTag kParallelReductionFactorInPlane
      //(0018,9069)
      = const PTag._('ParallelReductionFactorInPlane', 0x00189069,
          'Parallel Reduction Factor In-plane', VR.kFD, VM.k1, false);
  static const PTag kCardiacRRIntervalSpecified
      //(0018,9070)
      = const PTag._('CardiacRRIntervalSpecified', 0x00189070,
          'Cardiac R-R Interval Specified', VR.kFD, VM.k1, false);
  static const PTag kAcquisitionDuration
      //(0018,9073)
      = const PTag._('AcquisitionDuration', 0x00189073, 'Acquisition Duration', VR.kFD,
          VM.k1, false);
  static const PTag kFrameAcquisitionDateTime
      //(0018,9074)
      = const PTag._('FrameAcquisitionDateTime', 0x00189074, 'Frame Acquisition DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kDiffusionDirectionality
      //(0018,9075)
      = const PTag._('DiffusionDirectionality', 0x00189075, 'Diffusion Directionality',
          VR.kCS, VM.k1, false);
  static const PTag kDiffusionGradientDirectionSequence
      //(0018,9076)
      = const PTag._('DiffusionGradientDirectionSequence', 0x00189076,
          'Diffusion Gradient Direction Sequence', VR.kSQ, VM.k1, false);
  static const PTag kParallelAcquisition
      //(0018,9077)
      = const PTag._('ParallelAcquisition', 0x00189077, 'Parallel Acquisition', VR.kCS,
          VM.k1, false);
  static const PTag kParallelAcquisitionTechnique
      //(0018,9078)
      = const PTag._('ParallelAcquisitionTechnique', 0x00189078,
          'Parallel Acquisition Technique', VR.kCS, VM.k1, false);
  static const PTag kInversionTimes
      //(0018,9079)
      = const PTag._(
          'InversionTimes', 0x00189079, 'Inversion Times', VR.kFD, VM.k1_n, false);
  static const PTag kMetaboliteMapDescription
      //(0018,9080)
      = const PTag._('MetaboliteMapDescription', 0x00189080, 'Metabolite Map Description',
          VR.kST, VM.k1, false);
  static const PTag kPartialFourier
      //(0018,9081)
      =
      const PTag._('PartialFourier', 0x00189081, 'Partial Fourier', VR.kCS, VM.k1, false);
  static const PTag kEffectiveEchoTime
      //(0018,9082)
      = const PTag._(
          'EffectiveEchoTime', 0x00189082, 'Effective Echo Time', VR.kFD, VM.k1, false);
  static const PTag kMetaboliteMapCodeSequence
      //(0018,9083)
      = const PTag._('MetaboliteMapCodeSequence', 0x00189083,
          'Metabolite Map Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChemicalShiftSequence
      //(0018,9084)
      = const PTag._('ChemicalShiftSequence', 0x00189084, 'Chemical Shift Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCardiacSignalSource
      //(0018,9085)
      = const PTag._('CardiacSignalSource', 0x00189085, 'Cardiac Signal Source', VR.kCS,
          VM.k1, false);
  static const PTag kDiffusionBValue
      //(0018,9087)
      = const PTag._(
          'DiffusionBValue', 0x00189087, 'Diffusion b-value', VR.kFD, VM.k1, false);
  static const PTag kDiffusionGradientOrientation
      //(0018,9089)
      = const PTag._('DiffusionGradientOrientation', 0x00189089,
          'Diffusion Gradient Orientation', VR.kFD, VM.k3, false);
  static const PTag kVelocityEncodingDirection
      //(0018,9090)
      = const PTag._('VelocityEncodingDirection', 0x00189090,
          'Velocity Encoding Direction', VR.kFD, VM.k3, false);
  static const PTag kVelocityEncodingMinimumValue
      //(0018,9091)
      = const PTag._('VelocityEncodingMinimumValue', 0x00189091,
          'Velocity Encoding Minimum Value', VR.kFD, VM.k1, false);
  static const PTag kVelocityEncodingAcquisitionSequence
      //(0018,9092)
      = const PTag._('VelocityEncodingAcquisitionSequence', 0x00189092,
          'Velocity Encoding Acquisition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfKSpaceTrajectories
      //(0018,9093)
      = const PTag._('NumberOfKSpaceTrajectories', 0x00189093,
          'Number of k-Space Trajectories', VR.kUS, VM.k1, false);
  static const PTag kCoverageOfKSpace
      //(0018,9094)
      = const PTag._(
          'CoverageOfKSpace', 0x00189094, 'Coverage of k-Space', VR.kCS, VM.k1, false);
  static const PTag kSpectroscopyAcquisitionPhaseRows
      //(0018,9095)
      = const PTag._('SpectroscopyAcquisitionPhaseRows', 0x00189095,
          'Spectroscopy Acquisition Phase Rows', VR.kUL, VM.k1, false);
  static const PTag kParallelReductionFactorInPlaneRetired
      //(0018,9096)
      = const PTag._('ParallelReductionFactorInPlaneRetired', 0x00189096,
          'Parallel Reduction Factor In-plane (Retired)', VR.kFD, VM.k1, true);
  static const PTag kTransmitterFrequency
      //(0018,9098)
      = const PTag._('TransmitterFrequency', 0x00189098, 'Transmitter Frequency', VR.kFD,
          VM.k1_2, false);
  static const PTag kResonantNucleus
      //(0018,9100)
      = const PTag._(
          'ResonantNucleus', 0x00189100, 'Resonant Nucleus', VR.kCS, VM.k1_2, false);
  static const PTag kFrequencyCorrection
      //(0018,9101)
      = const PTag._('FrequencyCorrection', 0x00189101, 'Frequency Correction', VR.kCS,
          VM.k1, false);
  static const PTag kMRSpectroscopyFOVGeometrySequence
      //(0018,9103)
      = const PTag._('MRSpectroscopyFOVGeometrySequence', 0x00189103,
          'MR Spectroscopy FOV/Geometry Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSlabThickness
      //(0018,9104)
      = const PTag._('SlabThickness', 0x00189104, 'Slab Thickness', VR.kFD, VM.k1, false);
  static const PTag kSlabOrientation
      //(0018,9105)
      = const PTag._(
          'SlabOrientation', 0x00189105, 'Slab Orientation', VR.kFD, VM.k3, false);
  static const PTag kMidSlabPosition
      //(0018,9106)
      = const PTag._(
          'MidSlabPosition', 0x00189106, 'Mid Slab Position', VR.kFD, VM.k3, false);
  static const PTag kMRSpatialSaturationSequence
      //(0018,9107)
      = const PTag._('MRSpatialSaturationSequence', 0x00189107,
          'MR Spatial Saturation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRTimingAndRelatedParametersSequence
      //(0018,9112)
      = const PTag._('MRTimingAndRelatedParametersSequence', 0x00189112,
          'MR Timing and Related Parameters Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMREchoSequence
      //(0018,9114)
      = const PTag._(
          'MREchoSequence', 0x00189114, 'MR Echo Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRModifierSequence
      //(0018,9115)
      = const PTag._(
          'MRModifierSequence', 0x00189115, 'MR Modifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRDiffusionSequence
      //(0018,9117)
      = const PTag._('MRDiffusionSequence', 0x00189117, 'MR Diffusion Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kCardiacSynchronizationSequence
      //(0018,9118)
      = const PTag._('CardiacSynchronizationSequence', 0x00189118,
          'Cardiac Synchronization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRAveragesSequence
      //(0018,9119)
      = const PTag._(
          'MRAveragesSequence', 0x00189119, 'MR Averages Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRFOVGeometrySequence
      //(0018,9125)
      = const PTag._('MRFOVGeometrySequence', 0x00189125, 'MR FOV/Geometry Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kVolumeLocalizationSequence
      //(0018,9126)
      = const PTag._('VolumeLocalizationSequence', 0x00189126,
          'Volume Localization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpectroscopyAcquisitionDataColumns
      //(0018,9127)
      = const PTag._('SpectroscopyAcquisitionDataColumns', 0x00189127,
          'Spectroscopy Acquisition Data Columns', VR.kUL, VM.k1, false);
  static const PTag kDiffusionAnisotropyType
      //(0018,9147)
      = const PTag._('DiffusionAnisotropyType', 0x00189147, 'Diffusion Anisotropy Type',
          VR.kCS, VM.k1, false);
  static const PTag kFrameReferenceDateTime
      //(0018,9151)
      = const PTag._('FrameReferenceDateTime', 0x00189151, 'Frame Reference DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kMRMetaboliteMapSequence
      //(0018,9152)
      = const PTag._('MRMetaboliteMapSequence', 0x00189152, 'MR Metabolite Map Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kParallelReductionFactorOutOfPlane
      //(0018,9155)
      = const PTag._('ParallelReductionFactorOutOfPlane', 0x00189155,
          'Parallel Reduction Factor out-of-plane', VR.kFD, VM.k1, false);
  static const PTag kSpectroscopyAcquisitionOutOfPlanePhaseSteps
      //(0018,9159)
      = const PTag._('SpectroscopyAcquisitionOutOfPlanePhaseSteps', 0x00189159,
          'Spectroscopy Acquisition Out-of-plane Phase Steps', VR.kUL, VM.k1, false);
  static const PTag kBulkMotionStatus
      //(0018,9166)
      = const PTag._(
          'BulkMotionStatus', 0x00189166, 'Bulk Motion Status', VR.kCS, VM.k1, true);
  static const PTag kParallelReductionFactorSecondInPlane
      //(0018,9168)
      = const PTag._('ParallelReductionFactorSecondInPlane', 0x00189168,
          'Parallel Reduction Factor Second In-plane', VR.kFD, VM.k1, false);
  static const PTag kCardiacBeatRejectionTechnique
      //(0018,9169)
      = const PTag._('CardiacBeatRejectionTechnique', 0x00189169,
          'Cardiac Beat Rejection Technique', VR.kCS, VM.k1, false);
  static const PTag kRespiratoryMotionCompensationTechnique
      //(0018,9170)
      = const PTag._('RespiratoryMotionCompensationTechnique', 0x00189170,
          'Respiratory Motion Compensation Technique', VR.kCS, VM.k1, false);
  static const PTag kRespiratorySignalSource
      //(0018,9171)
      = const PTag._('RespiratorySignalSource', 0x00189171, 'Respiratory Signal Source',
          VR.kCS, VM.k1, false);
  static const PTag kBulkMotionCompensationTechnique
      //(0018,9172)
      = const PTag._('BulkMotionCompensationTechnique', 0x00189172,
          'Bulk Motion Compensation Technique', VR.kCS, VM.k1, false);
  static const PTag kBulkMotionSignalSource
      //(0018,9173)
      = const PTag._('BulkMotionSignalSource', 0x00189173, 'Bulk Motion Signal Source',
          VR.kCS, VM.k1, false);
  static const PTag kApplicableSafetyStandardAgency
      //(0018,9174)
      = const PTag._('ApplicableSafetyStandardAgency', 0x00189174,
          'Applicable Safety Standard Agency', VR.kCS, VM.k1, false);
  static const PTag kApplicableSafetyStandardDescription
      //(0018,9175)
      = const PTag._('ApplicableSafetyStandardDescription', 0x00189175,
          'Applicable Safety Standard Description', VR.kLO, VM.k1, false);
  static const PTag kOperatingModeSequence
      //(0018,9176)
      = const PTag._('OperatingModeSequence', 0x00189176, 'Operating Mode Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kOperatingModeType
      //(0018,9177)
      = const PTag._(
          'OperatingModeType', 0x00189177, 'Operating Mode Type', VR.kCS, VM.k1, false);
  static const PTag kOperatingMode
      //(0018,9178)
      = const PTag._('OperatingMode', 0x00189178, 'Operating Mode', VR.kCS, VM.k1, false);
  static const PTag kSpecificAbsorptionRateDefinition
      //(0018,9179)
      = const PTag._('SpecificAbsorptionRateDefinition', 0x00189179,
          'Specific Absorption Rate Definition', VR.kCS, VM.k1, false);
  static const PTag kGradientOutputType
      //(0018,9180)
      = const PTag._(
          'GradientOutputType', 0x00189180, 'Gradient Output Type', VR.kCS, VM.k1, false);
  static const PTag kSpecificAbsorptionRateValue
      //(0018,9181)
      = const PTag._('SpecificAbsorptionRateValue', 0x00189181,
          'Specific Absorption Rate Value', VR.kFD, VM.k1, false);
  static const PTag kGradientOutput
      //(0018,9182)
      =
      const PTag._('GradientOutput', 0x00189182, 'Gradient Output', VR.kFD, VM.k1, false);
  static const PTag kFlowCompensationDirection
      //(0018,9183)
      = const PTag._('FlowCompensationDirection', 0x00189183,
          'Flow Compensation Direction', VR.kCS, VM.k1, false);
  static const PTag kTaggingDelay
      //(0018,9184)
      = const PTag._('TaggingDelay', 0x00189184, 'Tagging Delay', VR.kFD, VM.k1, false);
  static const PTag kRespiratoryMotionCompensationTechniqueDescription
      //(0018,9185)
      = const PTag._('RespiratoryMotionCompensationTechniqueDescription', 0x00189185,
          'Respiratory Motion Compensation Technique Description', VR.kST, VM.k1, false);
  static const PTag kRespiratorySignalSourceID
      //(0018,9186)
      = const PTag._('RespiratorySignalSourceID', 0x00189186,
          'Respiratory Signal Source ID', VR.kSH, VM.k1, false);
  static const PTag kChemicalShiftMinimumIntegrationLimitInHz
      //(0018,9195)
      = const PTag._('ChemicalShiftMinimumIntegrationLimitInHz', 0x00189195,
          'Chemical Shift Minimum Integration Limit in Hz', VR.kFD, VM.k1, true);
  static const PTag kChemicalShiftMaximumIntegrationLimitInHz
      //(0018,9196)
      = const PTag._('ChemicalShiftMaximumIntegrationLimitInHz', 0x00189196,
          'Chemical Shift Maximum Integration Limit in Hz', VR.kFD, VM.k1, true);
  static const PTag kMRVelocityEncodingSequence
      //(0018,9197)
      = const PTag._('MRVelocityEncodingSequence', 0x00189197,
          'MR Velocity Encoding Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFirstOrderPhaseCorrection
      //(0018,9198)
      = const PTag._('FirstOrderPhaseCorrection', 0x00189198,
          'First Order Phase Correction', VR.kCS, VM.k1, false);
  static const PTag kWaterReferencedPhaseCorrection
      //(0018,9199)
      = const PTag._('WaterReferencedPhaseCorrection', 0x00189199,
          'Water Referenced Phase Correction', VR.kCS, VM.k1, false);
  static const PTag kMRSpectroscopyAcquisitionType
      //(0018,9200)
      = const PTag._('MRSpectroscopyAcquisitionType', 0x00189200,
          'MR Spectroscopy Acquisition Type', VR.kCS, VM.k1, false);
  static const PTag kRespiratoryCyclePosition
      //(0018,9214)
      = const PTag._('RespiratoryCyclePosition', 0x00189214, 'Respiratory Cycle Position',
          VR.kCS, VM.k1, false);
  static const PTag kVelocityEncodingMaximumValue
      //(0018,9217)
      = const PTag._('VelocityEncodingMaximumValue', 0x00189217,
          'Velocity Encoding Maximum Value', VR.kFD, VM.k1, false);
  static const PTag kTagSpacingSecondDimension
      //(0018,9218)
      = const PTag._('TagSpacingSecondDimension', 0x00189218,
          'Tag Spacing Second Dimension', VR.kFD, VM.k1, false);
  static const PTag kTagAngleSecondAxis
      //(0018,9219)
      = const PTag._('TagAngleSecondAxis', 0x00189219, 'Tag Angle Second Axis', VR.kSS,
          VM.k1, false);
  static const PTag kFrameAcquisitionDuration
      //(0018,9220)
      = const PTag._('FrameAcquisitionDuration', 0x00189220, 'Frame Acquisition Duration',
          VR.kFD, VM.k1, false);
  static const PTag kMRImageFrameTypeSequence
      //(0018,9226)
      = const PTag._('MRImageFrameTypeSequence', 0x00189226,
          'MR Image Frame Type Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRSpectroscopyFrameTypeSequence
      //(0018,9227)
      = const PTag._('MRSpectroscopyFrameTypeSequence', 0x00189227,
          'MR Spectroscopy Frame Type Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMRAcquisitionPhaseEncodingStepsInPlane
      //(0018,9231)
      = const PTag._('MRAcquisitionPhaseEncodingStepsInPlane', 0x00189231,
          'MR Acquisition Phase Encoding Steps in-plane', VR.kUS, VM.k1, false);
  static const PTag kMRAcquisitionPhaseEncodingStepsOutOfPlane
      //(0018,9232)
      = const PTag._('MRAcquisitionPhaseEncodingStepsOutOfPlane', 0x00189232,
          'MR Acquisition Phase Encoding Steps out-of-plane', VR.kUS, VM.k1, false);
  static const PTag kSpectroscopyAcquisitionPhaseColumns
      //(0018,9234)
      = const PTag._('SpectroscopyAcquisitionPhaseColumns', 0x00189234,
          'Spectroscopy Acquisition Phase Columns', VR.kUL, VM.k1, false);
  static const PTag kCardiacCyclePosition
      //(0018,9236)
      = const PTag._('CardiacCyclePosition', 0x00189236, 'Cardiac Cycle Position', VR.kCS,
          VM.k1, false);
  static const PTag kSpecificAbsorptionRateSequence
      //(0018,9239)
      = const PTag._('SpecificAbsorptionRateSequence', 0x00189239,
          'Specific Absorption Rate Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRFEchoTrainLength
      //(0018,9240)
      = const PTag._(
          'RFEchoTrainLength', 0x00189240, 'RF Echo Train Length', VR.kUS, VM.k1, false);
  static const PTag kGradientEchoTrainLength
      //(0018,9241)
      = const PTag._('GradientEchoTrainLength', 0x00189241, 'Gradient Echo Train Length',
          VR.kUS, VM.k1, false);
  static const PTag kArterialSpinLabelingContrast
      //(0018,9250)
      = const PTag._('ArterialSpinLabelingContrast', 0x00189250,
          'Arterial Spin Labeling Contrast', VR.kCS, VM.k1, false);
  static const PTag kMRArterialSpinLabelingSequence
      //(0018,9251)
      = const PTag._('MRArterialSpinLabelingSequence', 0x00189251,
          'MR Arterial Spin Labeling Sequence', VR.kSQ, VM.k1, false);
  static const PTag kASLTechniqueDescription
      //(0018,9252)
      = const PTag._('ASLTechniqueDescription', 0x00189252, 'ASL Technique Description',
          VR.kLO, VM.k1, false);
  static const PTag kASLSlabNumber
      //(0018,9253)
      =
      const PTag._('ASLSlabNumber', 0x00189253, 'ASL Slab Number', VR.kUS, VM.k1, false);
  static const PTag kASLSlabThickness
      //(0018,9254)
      = const PTag._(
          'ASLSlabThickness', 0x00189254, 'ASL Slab Thickness', VR.kFD, VM.k1, false);
  static const PTag kASLSlabOrientation
      //(0018,9255)
      = const PTag._(
          'ASLSlabOrientation', 0x00189255, 'ASL Slab Orientation', VR.kFD, VM.k3, false);
  static const PTag kASLMidSlabPosition
      //(0018,9256)
      = const PTag._('ASLMidSlabPosition', 0x00189256, 'ASL Mid Slab Position', VR.kFD,
          VM.k3, false);
  static const PTag kASLContext
      //(0018,9257)
      = const PTag._('ASLContext', 0x00189257, 'ASL Context', VR.kCS, VM.k1, false);
  static const PTag kASLPulseTrainDuration
      //(0018,9258)
      = const PTag._('ASLPulseTrainDuration', 0x00189258, 'ASL Pulse Train Duration',
          VR.kUL, VM.k1, false);
  static const PTag kASLCrusherFlag
      //(0018,9259)
      = const PTag._(
          'ASLCrusherFlag', 0x00189259, 'ASL Crusher Flag', VR.kCS, VM.k1, false);
  static const PTag kASLCrusherFlowLimit
      //(0018,925A)
      = const PTag._('ASLCrusherFlowLimit', 0x0018925A, 'ASL Crusher Flow Limit', VR.kFD,
          VM.k1, false);
  static const PTag kASLCrusherDescription
      //(0018,925B)
      = const PTag._('ASLCrusherDescription', 0x0018925B, 'ASL Crusher Description',
          VR.kLO, VM.k1, false);
  static const PTag kASLBolusCutoffFlag
      //(0018,925C)
      = const PTag._('ASLBolusCutoffFlag', 0x0018925C, 'ASL Bolus Cut-off Flag', VR.kCS,
          VM.k1, false);
  static const PTag kASLBolusCutoffTimingSequence
      //(0018,925D)
      = const PTag._('ASLBolusCutoffTimingSequence', 0x0018925D,
          'ASL Bolus Cut-off Timing Sequence', VR.kSQ, VM.k1, false);
  static const PTag kASLBolusCutoffTechnique
      //(0018,925E)
      = const PTag._('ASLBolusCutoffTechnique', 0x0018925E, 'ASL Bolus Cut-off Technique',
          VR.kLO, VM.k1, false);
  static const PTag kASLBolusCutoffDelayTime
      //(0018,925F)
      = const PTag._('ASLBolusCutoffDelayTime', 0x0018925F,
          'ASL Bolus Cut-off Delay Time', VR.kUL, VM.k1, false);
  static const PTag kASLSlabSequence
      //(0018,9260)
      = const PTag._(
          'ASLSlabSequence', 0x00189260, 'ASL Slab Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChemicalShiftMinimumIntegrationLimitInppm
      //(0018,9295)
      = const PTag._('ChemicalShiftMinimumIntegrationLimitInppm', 0x00189295,
          'Chemical Shift Minimum Integration Limit in ppm', VR.kFD, VM.k1, false);
  static const PTag kChemicalShiftMaximumIntegrationLimitInppm
      //(0018,9296)
      = const PTag._('ChemicalShiftMaximumIntegrationLimitInppm', 0x00189296,
          'Chemical Shift Maximum Integration Limit in ppm', VR.kFD, VM.k1, false);
  static const PTag kCTAcquisitionTypeSequence
      //(0018,9301)
      = const PTag._('CTAcquisitionTypeSequence', 0x00189301,
          'CT Acquisition Type Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAcquisitionType
      //(0018,9302)
      = const PTag._(
          'AcquisitionType', 0x00189302, 'Acquisition Type', VR.kCS, VM.k1, false);
  static const PTag kTubeAngle
      //(0018,9303)
      = const PTag._('TubeAngle', 0x00189303, 'Tube Angle', VR.kFD, VM.k1, false);
  static const PTag kCTAcquisitionDetailsSequence
      //(0018,9304)
      = const PTag._('CTAcquisitionDetailsSequence', 0x00189304,
          'CT Acquisition Details Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRevolutionTime
      //(0018,9305)
      =
      const PTag._('RevolutionTime', 0x00189305, 'Revolution Time', VR.kFD, VM.k1, false);
  static const PTag kSingleCollimationWidth
      //(0018,9306)
      = const PTag._('SingleCollimationWidth', 0x00189306, 'Single Collimation Width',
          VR.kFD, VM.k1, false);
  static const PTag kTotalCollimationWidth
      //(0018,9307)
      = const PTag._('TotalCollimationWidth', 0x00189307, 'Total Collimation Width',
          VR.kFD, VM.k1, false);
  static const PTag kCTTableDynamicsSequence
      //(0018,9308)
      = const PTag._('CTTableDynamicsSequence', 0x00189308, 'CT Table Dynamics Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTableSpeed
      //(0018,9309)
      = const PTag._('TableSpeed', 0x00189309, 'Table Speed', VR.kFD, VM.k1, false);
  static const PTag kTableFeedPerRotation
      //(0018,9310)
      = const PTag._('TableFeedPerRotation', 0x00189310, 'Table Feed per Rotation',
          VR.kFD, VM.k1, false);
  static const PTag kSpiralPitchFactor
      //(0018,9311)
      = const PTag._(
          'SpiralPitchFactor', 0x00189311, 'Spiral Pitch Factor', VR.kFD, VM.k1, false);
  static const PTag kCTGeometrySequence
      //(0018,9312)
      = const PTag._(
          'CTGeometrySequence', 0x00189312, 'CT Geometry Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDataCollectionCenterPatient
      //(0018,9313)
      = const PTag._('DataCollectionCenterPatient', 0x00189313,
          'Data Collection Center (Patient)', VR.kFD, VM.k3, false);
  static const PTag kCTReconstructionSequence
      //(0018,9314)
      = const PTag._('CTReconstructionSequence', 0x00189314, 'CT Reconstruction Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReconstructionAlgorithm
      //(0018,9315)
      = const PTag._('ReconstructionAlgorithm', 0x00189315, 'Reconstruction Algorithm',
          VR.kCS, VM.k1, false);
  static const PTag kConvolutionKernelGroup
      //(0018,9316)
      = const PTag._('ConvolutionKernelGroup', 0x00189316, 'Convolution Kernel Group',
          VR.kCS, VM.k1, false);
  static const PTag kReconstructionFieldOfView
      //(0018,9317)
      = const PTag._('ReconstructionFieldOfView', 0x00189317,
          'Reconstruction Field of View', VR.kFD, VM.k2, false);
  static const PTag kReconstructionTargetCenterPatient
      //(0018,9318)
      = const PTag._('ReconstructionTargetCenterPatient', 0x00189318,
          'Reconstruction Target Center (Patient)', VR.kFD, VM.k3, false);
  static const PTag kReconstructionAngle
      //(0018,9319)
      = const PTag._('ReconstructionAngle', 0x00189319, 'Reconstruction Angle', VR.kFD,
          VM.k1, false);
  static const PTag kImageFilter
      //(0018,9320)
      = const PTag._('ImageFilter', 0x00189320, 'Image Filter', VR.kSH, VM.k1, false);
  static const PTag kCTExposureSequence
      //(0018,9321)
      = const PTag._(
          'CTExposureSequence', 0x00189321, 'CT Exposure Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReconstructionPixelSpacing
      //(0018,9322)
      = const PTag._('ReconstructionPixelSpacing', 0x00189322,
          'Reconstruction Pixel Spacing', VR.kFD, VM.k2, false);
  static const PTag kExposureModulationType
      //(0018,9323)
      = const PTag._('ExposureModulationType', 0x00189323, 'Exposure Modulation Type',
          VR.kCS, VM.k1, false);
  static const PTag kEstimatedDoseSaving
      //(0018,9324)
      = const PTag._('EstimatedDoseSaving', 0x00189324, 'Estimated Dose Saving', VR.kFD,
          VM.k1, false);
  static const PTag kCTXRayDetailsSequence
      //(0018,9325)
      = const PTag._('CTXRayDetailsSequence', 0x00189325, 'CT X-Ray Details Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCTPositionSequence
      //(0018,9326)
      = const PTag._(
          'CTPositionSequence', 0x00189326, 'CT Position Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTablePosition
      //(0018,9327)
      = const PTag._('TablePosition', 0x00189327, 'Table Position', VR.kFD, VM.k1, false);
  static const PTag kExposureTimeInms
      //(0018,9328)
      = const PTag._(
          'ExposureTimeInms', 0x00189328, 'Exposure Time in ms', VR.kFD, VM.k1, false);
  static const PTag kCTImageFrameTypeSequence
      //(0018,9329)
      = const PTag._('CTImageFrameTypeSequence', 0x00189329,
          'CT Image Frame Type Sequence', VR.kSQ, VM.k1, false);
  static const PTag kXRayTubeCurrentInmA
      //(0018,9330)
      = const PTag._('XRayTubeCurrentInmA', 0x00189330, 'X-Ray Tube Current in mA',
          VR.kFD, VM.k1, false);
  static const PTag kExposureInmAs
      //(0018,9332)
      =
      const PTag._('ExposureInmAs', 0x00189332, 'Exposure in mAs', VR.kFD, VM.k1, false);
  static const PTag kConstantVolumeFlag
      //(0018,9333)
      = const PTag._(
          'ConstantVolumeFlag', 0x00189333, 'Constant Volume Flag', VR.kCS, VM.k1, false);
  static const PTag kFluoroscopyFlag
      //(0018,9334)
      = const PTag._(
          'FluoroscopyFlag', 0x00189334, 'Fluoroscopy Flag', VR.kCS, VM.k1, false);
  static const PTag kDistanceSourceToDataCollectionCenter
      //(0018,9335)
      = const PTag._('DistanceSourceToDataCollectionCenter', 0x00189335,
          'Distance Source to Data Collection Center', VR.kFD, VM.k1, false);
  static const PTag kContrastBolusAgentNumber
      //(0018,9337)
      = const PTag._('ContrastBolusAgentNumber', 0x00189337,
          'Contrast/Bolus Agent Number', VR.kUS, VM.k1, false);
  static const PTag kContrastBolusIngredientCodeSequence
      //(0018,9338)
      = const PTag._('ContrastBolusIngredientCodeSequence', 0x00189338,
          'Contrast/Bolus Ingredient Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContrastAdministrationProfileSequence
      //(0018,9340)
      = const PTag._('ContrastAdministrationProfileSequence', 0x00189340,
          'Contrast Administration Profile Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContrastBolusUsageSequence
      //(0018,9341)
      = const PTag._('ContrastBolusUsageSequence', 0x00189341,
          'Contrast/Bolus Usage Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContrastBolusAgentAdministered
      //(0018,9342)
      = const PTag._('ContrastBolusAgentAdministered', 0x00189342,
          'Contrast/Bolus Agent Administered', VR.kCS, VM.k1, false);
  static const PTag kContrastBolusAgentDetected
      //(0018,9343)
      = const PTag._('ContrastBolusAgentDetected', 0x00189343,
          'Contrast/Bolus Agent Detected', VR.kCS, VM.k1, false);
  static const PTag kContrastBolusAgentPhase
      //(0018,9344)
      = const PTag._('ContrastBolusAgentPhase', 0x00189344, 'Contrast/Bolus Agent Phase',
          VR.kCS, VM.k1, false);
  static const PTag kCTDIvol
      //(0018,9345)
      = const PTag._('CTDIvol', 0x00189345, 'CTDIvol', VR.kFD, VM.k1, false);
  static const PTag kCTDIPhantomTypeCodeSequence
      //(0018,9346)
      = const PTag._('CTDIPhantomTypeCodeSequence', 0x00189346,
          'CTDI Phantom Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCalciumScoringMassFactorPatient
      //(0018,9351)
      = const PTag._('CalciumScoringMassFactorPatient', 0x00189351,
          'Calcium Scoring Mass Factor Patient', VR.kFL, VM.k1, false);
  static const PTag kCalciumScoringMassFactorDevice
      //(0018,9352)
      = const PTag._('CalciumScoringMassFactorDevice', 0x00189352,
          'Calcium Scoring Mass Factor Device', VR.kFL, VM.k3, false);
  static const PTag kEnergyWeightingFactor
      //(0018,9353)
      = const PTag._('EnergyWeightingFactor', 0x00189353, 'Energy Weighting Factor',
          VR.kFL, VM.k1, false);
  static const PTag kCTAdditionalXRaySourceSequence
      //(0018,9360)
      = const PTag._('CTAdditionalXRaySourceSequence', 0x00189360,
          'CT Additional X-Ray Source Sequence', VR.kSQ, VM.k1, false);
  static const PTag kProjectionPixelCalibrationSequence
      //(0018,9401)
      = const PTag._('ProjectionPixelCalibrationSequence', 0x00189401,
          'Projection Pixel Calibration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDistanceSourceToIsocenter
      //(0018,9402)
      = const PTag._('DistanceSourceToIsocenter', 0x00189402,
          'Distance Source to Isocenter', VR.kFL, VM.k1, false);
  static const PTag kDistanceObjectToTableTop
      //(0018,9403)
      = const PTag._('DistanceObjectToTableTop', 0x00189403,
          'Distance Object to Table Top', VR.kFL, VM.k1, false);
  static const PTag kObjectPixelSpacingInCenterOfBeam
      //(0018,9404)
      = const PTag._('ObjectPixelSpacingInCenterOfBeam', 0x00189404,
          'Object Pixel Spacing in Center of Beam', VR.kFL, VM.k2, false);
  static const PTag kPositionerPositionSequence
      //(0018,9405)
      = const PTag._('PositionerPositionSequence', 0x00189405,
          'Positioner Position Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTablePositionSequence
      //(0018,9406)
      = const PTag._('TablePositionSequence', 0x00189406, 'Table Position Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCollimatorShapeSequence
      //(0018,9407)
      = const PTag._('CollimatorShapeSequence', 0x00189407, 'Collimator Shape Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPlanesInAcquisition
      //(0018,9410)
      = const PTag._('PlanesInAcquisition', 0x00189410, 'Planes in Acquisition', VR.kCS,
          VM.k1, false);
  static const PTag kXAXRFFrameCharacteristicsSequence
      //(0018,9412)
      = const PTag._('XAXRFFrameCharacteristicsSequence', 0x00189412,
          'XA/XRF Frame Characteristics Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFrameAcquisitionSequence
      //(0018,9417)
      = const PTag._('FrameAcquisitionSequence', 0x00189417, 'Frame Acquisition Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kXRayReceptorType
      //(0018,9420)
      = const PTag._(
          'XRayReceptorType', 0x00189420, 'X-Ray Receptor Type', VR.kCS, VM.k1, false);
  static const PTag kAcquisitionProtocolName
      //(0018,9423)
      = const PTag._('AcquisitionProtocolName', 0x00189423, 'Acquisition Protocol Name',
          VR.kLO, VM.k1, false);
  static const PTag kAcquisitionProtocolDescription
      //(0018,9424)
      = const PTag._('AcquisitionProtocolDescription', 0x00189424,
          'Acquisition Protocol Description', VR.kLT, VM.k1, false);
  static const PTag kContrastBolusIngredientOpaque
      //(0018,9425)
      = const PTag._('ContrastBolusIngredientOpaque', 0x00189425,
          'Contrast/Bolus Ingredient Opaque', VR.kCS, VM.k1, false);
  static const PTag kDistanceReceptorPlaneToDetectorHousing
      //(0018,9426)
      = const PTag._('DistanceReceptorPlaneToDetectorHousing', 0x00189426,
          'Distance Receptor Plane to Detector Housing', VR.kFL, VM.k1, false);
  static const PTag kIntensifierActiveShape
      //(0018,9427)
      = const PTag._('IntensifierActiveShape', 0x00189427, 'Intensifier Active Shape',
          VR.kCS, VM.k1, false);
  static const PTag kIntensifierActiveDimensions
      //(0018,9428)
      = const PTag._('IntensifierActiveDimensions', 0x00189428,
          'Intensifier Active Dimension(s)', VR.kFL, VM.k1_2, false);
  static const PTag kPhysicalDetectorSize
      //(0018,9429)
      = const PTag._('PhysicalDetectorSize', 0x00189429, 'Physical Detector Size', VR.kFL,
          VM.k2, false);
  static const PTag kPositionOfIsocenterProjection
      //(0018,9430)
      = const PTag._('PositionOfIsocenterProjection', 0x00189430,
          'Position of Isocenter Projection', VR.kFL, VM.k2, false);
  static const PTag kFieldOfViewSequence
      //(0018,9432)
      = const PTag._('FieldOfViewSequence', 0x00189432, 'Field of View Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kFieldOfViewDescription
      //(0018,9433)
      = const PTag._('FieldOfViewDescription', 0x00189433, 'Field of View Description',
          VR.kLO, VM.k1, false);
  static const PTag kExposureControlSensingRegionsSequence
      //(0018,9434)
      = const PTag._('ExposureControlSensingRegionsSequence', 0x00189434,
          'Exposure Control Sensing Regions Sequence', VR.kSQ, VM.k1, false);
  static const PTag kExposureControlSensingRegionShape
      //(0018,9435)
      = const PTag._('ExposureControlSensingRegionShape', 0x00189435,
          'Exposure Control Sensing Region Shape', VR.kCS, VM.k1, false);
  static const PTag kExposureControlSensingRegionLeftVerticalEdge
      //(0018,9436)
      = const PTag._('ExposureControlSensingRegionLeftVerticalEdge', 0x00189436,
          'Exposure Control Sensing Region Left Vertical Edge', VR.kSS, VM.k1, false);
  static const PTag kExposureControlSensingRegionRightVerticalEdge
      //(0018,9437)
      = const PTag._('ExposureControlSensingRegionRightVerticalEdge', 0x00189437,
          'Exposure Control Sensing Region Right Vertical Edge', VR.kSS, VM.k1, false);
  static const PTag kExposureControlSensingRegionUpperHorizontalEdge
      //(0018,9438)
      = const PTag._('ExposureControlSensingRegionUpperHorizontalEdge', 0x00189438,
          'Exposure Control Sensing Region Upper Horizontal Edge', VR.kSS, VM.k1, false);
  static const PTag kExposureControlSensingRegionLowerHorizontalEdge
      //(0018,9439)
      = const PTag._('ExposureControlSensingRegionLowerHorizontalEdge', 0x00189439,
          'Exposure Control Sensing Region Lower Horizontal Edge', VR.kSS, VM.k1, false);
  static const PTag kCenterOfCircularExposureControlSensingRegion
      //(0018,9440)
      = const PTag._('CenterOfCircularExposureControlSensingRegion', 0x00189440,
          'Center of Circular Exposure Control Sensing Region', VR.kSS, VM.k2, false);
  static const PTag kRadiusOfCircularExposureControlSensingRegion
      //(0018,9441)
      = const PTag._('RadiusOfCircularExposureControlSensingRegion', 0x00189441,
          'Radius of Circular Exposure Control Sensing Region', VR.kUS, VM.k1, false);
  static const PTag kVerticesOfThePolygonalExposureControlSensingRegion
      //(0018,9442)
      = const PTag._(
          'VerticesOfThePolygonalExposureControlSensingRegion',
          0x00189442,
          'Vertices of the Polygonal Exposure Control Sensing Region',
          VR.kSS,
          VM.k2_n,
          false);
  static const PTag kNoName0
      //(0018,9445)
      = const PTag._('NoName0', 0x00189445, 'See Note 3', VR.kUN, VM.kNoVM, true);
  static const PTag kColumnAngulationPatient
      //(0018,9447)
      = const PTag._('ColumnAngulationPatient', 0x00189447, 'Column Angulation (Patient)',
          VR.kFL, VM.k1, false);
  static const PTag kBeamAngle
      //(0018,9449)
      = const PTag._('BeamAngle', 0x00189449, 'Beam Angle', VR.kFL, VM.k1, false);
  static const PTag kFrameDetectorParametersSequence
      //(0018,9451)
      = const PTag._('FrameDetectorParametersSequence', 0x00189451,
          'Frame Detector Parameters Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCalculatedAnatomyThickness
      //(0018,9452)
      = const PTag._('CalculatedAnatomyThickness', 0x00189452,
          'Calculated Anatomy Thickness', VR.kFL, VM.k1, false);
  static const PTag kCalibrationSequence
      //(0018,9455)
      = const PTag._('CalibrationSequence', 0x00189455, 'Calibration Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kObjectThicknessSequence
      //(0018,9456)
      = const PTag._('ObjectThicknessSequence', 0x00189456, 'Object Thickness Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPlaneIdentification
      //(0018,9457)
      = const PTag._('PlaneIdentification', 0x00189457, 'Plane Identification', VR.kCS,
          VM.k1, false);
  static const PTag kFieldOfViewDimensionsInFloat
      //(0018,9461)
      = const PTag._('FieldOfViewDimensionsInFloat', 0x00189461,
          'Field of View Dimension(s) in Float', VR.kFL, VM.k1_2, false);
  static const PTag kIsocenterReferenceSystemSequence
      //(0018,9462)
      = const PTag._('IsocenterReferenceSystemSequence', 0x00189462,
          'Isocenter Reference System Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPositionerIsocenterPrimaryAngle
      //(0018,9463)
      = const PTag._('PositionerIsocenterPrimaryAngle', 0x00189463,
          'Positioner Isocenter Primary Angle', VR.kFL, VM.k1, false);
  static const PTag kPositionerIsocenterSecondaryAngle
      //(0018,9464)
      = const PTag._('PositionerIsocenterSecondaryAngle', 0x00189464,
          'Positioner Isocenter Secondary Angle', VR.kFL, VM.k1, false);
  static const PTag kPositionerIsocenterDetectorRotationAngle
      //(0018,9465)
      = const PTag._('PositionerIsocenterDetectorRotationAngle', 0x00189465,
          'Positioner Isocenter Detector Rotation Angle', VR.kFL, VM.k1, false);
  static const PTag kTableXPositionToIsocenter
      //(0018,9466)
      = const PTag._('TableXPositionToIsocenter', 0x00189466,
          'Table X Position to Isocenter', VR.kFL, VM.k1, false);
  static const PTag kTableYPositionToIsocenter
      //(0018,9467)
      = const PTag._('TableYPositionToIsocenter', 0x00189467,
          'Table Y Position to Isocenter', VR.kFL, VM.k1, false);
  static const PTag kTableZPositionToIsocenter
      //(0018,9468)
      = const PTag._('TableZPositionToIsocenter', 0x00189468,
          'Table Z Position to Isocenter', VR.kFL, VM.k1, false);
  static const PTag kTableHorizontalRotationAngle
      //(0018,9469)
      = const PTag._('TableHorizontalRotationAngle', 0x00189469,
          'Table Horizontal Rotation Angle', VR.kFL, VM.k1, false);
  static const PTag kTableHeadTiltAngle
      //(0018,9470)
      = const PTag._('TableHeadTiltAngle', 0x00189470, 'Table Head Tilt Angle', VR.kFL,
          VM.k1, false);
  static const PTag kTableCradleTiltAngle
      //(0018,9471)
      = const PTag._('TableCradleTiltAngle', 0x00189471, 'Table Cradle Tilt Angle',
          VR.kFL, VM.k1, false);
  static const PTag kFrameDisplayShutterSequence
      //(0018,9472)
      = const PTag._('FrameDisplayShutterSequence', 0x00189472,
          'Frame Display Shutter Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAcquiredImageAreaDoseProduct
      //(0018,9473)
      = const PTag._('AcquiredImageAreaDoseProduct', 0x00189473,
          'Acquired Image Area Dose Product', VR.kFL, VM.k1, false);
  static const PTag kCArmPositionerTabletopRelationship
      //(0018,9474)
      = const PTag._('CArmPositionerTabletopRelationship', 0x00189474,
          'C-arm Positioner Tabletop Relationship', VR.kCS, VM.k1, false);
  static const PTag kXRayGeometrySequence
      //(0018,9476)
      = const PTag._('XRayGeometrySequence', 0x00189476, 'X-Ray Geometry Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kIrradiationEventIdentificationSequence
      //(0018,9477)
      = const PTag._('IrradiationEventIdentificationSequence', 0x00189477,
          'Irradiation Event Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kXRay3DFrameTypeSequence
      //(0018,9504)
      = const PTag._('XRay3DFrameTypeSequence', 0x00189504,
          'X-Ray 3D Frame Type Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContributingSourcesSequence
      //(0018,9506)
      = const PTag._('ContributingSourcesSequence', 0x00189506,
          'Contributing Sources Sequence', VR.kSQ, VM.k1, false);
  static const PTag kXRay3DAcquisitionSequence
      //(0018,9507)
      = const PTag._('XRay3DAcquisitionSequence', 0x00189507,
          'X-Ray 3D Acquisition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrimaryPositionerScanArc
      //(0018,9508)
      = const PTag._('PrimaryPositionerScanArc', 0x00189508,
          'Primary Positioner Scan Arc', VR.kFL, VM.k1, false);
  static const PTag kSecondaryPositionerScanArc
      //(0018,9509)
      = const PTag._('SecondaryPositionerScanArc', 0x00189509,
          'Secondary Positioner Scan Arc', VR.kFL, VM.k1, false);
  static const PTag kPrimaryPositionerScanStartAngle
      //(0018,9510)
      = const PTag._('PrimaryPositionerScanStartAngle', 0x00189510,
          'Primary Positioner Scan Start Angle', VR.kFL, VM.k1, false);
  static const PTag kSecondaryPositionerScanStartAngle
      //(0018,9511)
      = const PTag._('SecondaryPositionerScanStartAngle', 0x00189511,
          'Secondary Positioner Scan Start Angle', VR.kFL, VM.k1, false);
  static const PTag kPrimaryPositionerIncrement
      //(0018,9514)
      = const PTag._('PrimaryPositionerIncrement', 0x00189514,
          'Primary Positioner Increment', VR.kFL, VM.k1, false);
  static const PTag kSecondaryPositionerIncrement
      //(0018,9515)
      = const PTag._('SecondaryPositionerIncrement', 0x00189515,
          'Secondary Positioner Increment', VR.kFL, VM.k1, false);
  static const PTag kStartAcquisitionDateTime
      //(0018,9516)
      = const PTag._('StartAcquisitionDateTime', 0x00189516, 'Start Acquisition DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kEndAcquisitionDateTime
      //(0018,9517)
      = const PTag._('EndAcquisitionDateTime', 0x00189517, 'End Acquisition DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kApplicationName
      //(0018,9524)
      = const PTag._(
          'ApplicationName', 0x00189524, 'Application Name', VR.kLO, VM.k1, false);
  static const PTag kApplicationVersion
      //(0018,9525)
      = const PTag._(
          'ApplicationVersion', 0x00189525, 'Application Version', VR.kLO, VM.k1, false);
  static const PTag kApplicationManufacturer
      //(0018,9526)
      = const PTag._('ApplicationManufacturer', 0x00189526, 'Application Manufacturer',
          VR.kLO, VM.k1, false);
  static const PTag kAlgorithmType
      //(0018,9527)
      = const PTag._('AlgorithmType', 0x00189527, 'Algorithm Type', VR.kCS, VM.k1, false);
  static const PTag kAlgorithmDescription
      //(0018,9528)
      = const PTag._('AlgorithmDescription', 0x00189528, 'Algorithm Description', VR.kLO,
          VM.k1, false);
  static const PTag kXRay3DReconstructionSequence
      //(0018,9530)
      = const PTag._('XRay3DReconstructionSequence', 0x00189530,
          'X-Ray 3D Reconstruction Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReconstructionDescription
      //(0018,9531)
      = const PTag._('ReconstructionDescription', 0x00189531,
          'Reconstruction Description', VR.kLO, VM.k1, false);
  static const PTag kPerProjectionAcquisitionSequence
      //(0018,9538)
      = const PTag._('PerProjectionAcquisitionSequence', 0x00189538,
          'Per Projection Acquisition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDiffusionBMatrixSequence
      //(0018,9601)
      = const PTag._('DiffusionBMatrixSequence', 0x00189601,
          'Diffusion b-matrix Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDiffusionBValueXX
      //(0018,9602)
      = const PTag._(
          'DiffusionBValueXX', 0x00189602, 'Diffusion b-value XX', VR.kFD, VM.k1, false);
  static const PTag kDiffusionBValueXY
      //(0018,9603)
      = const PTag._(
          'DiffusionBValueXY', 0x00189603, 'Diffusion b-value XY', VR.kFD, VM.k1, false);
  static const PTag kDiffusionBValueXZ
      //(0018,9604)
      = const PTag._(
          'DiffusionBValueXZ', 0x00189604, 'Diffusion b-value XZ', VR.kFD, VM.k1, false);
  static const PTag kDiffusionBValueYY
      //(0018,9605)
      = const PTag._(
          'DiffusionBValueYY', 0x00189605, 'Diffusion b-value YY', VR.kFD, VM.k1, false);
  static const PTag kDiffusionBValueYZ
      //(0018,9606)
      = const PTag._(
          'DiffusionBValueYZ', 0x00189606, 'Diffusion b-value YZ', VR.kFD, VM.k1, false);
  static const PTag kDiffusionBValueZZ
      //(0018,9607)
      = const PTag._(
          'DiffusionBValueZZ', 0x00189607, 'Diffusion b-value ZZ', VR.kFD, VM.k1, false);
  static const PTag kDecayCorrectionDateTime
      //(0018,9701)
      = const PTag._('DecayCorrectionDateTime', 0x00189701, 'Decay Correction DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kStartDensityThreshold
      //(0018,9715)
      = const PTag._('StartDensityThreshold', 0x00189715, 'Start Density Threshold',
          VR.kFD, VM.k1, false);
  static const PTag kStartRelativeDensityDifferenceThreshold
      //(0018,9716)
      = const PTag._('StartRelativeDensityDifferenceThreshold', 0x00189716,
          'Start Relative Density Difference Threshold', VR.kFD, VM.k1, false);
  static const PTag kStartCardiacTriggerCountThreshold
      //(0018,9717)
      = const PTag._('StartCardiacTriggerCountThreshold', 0x00189717,
          'Start Cardiac Trigger Count Threshold', VR.kFD, VM.k1, false);
  static const PTag kStartRespiratoryTriggerCountThreshold
      //(0018,9718)
      = const PTag._('StartRespiratoryTriggerCountThreshold', 0x00189718,
          'Start Respiratory Trigger Count Threshold', VR.kFD, VM.k1, false);
  static const PTag kTerminationCountsThreshold
      //(0018,9719)
      = const PTag._('TerminationCountsThreshold', 0x00189719,
          'Termination Counts Threshold', VR.kFD, VM.k1, false);
  static const PTag kTerminationDensityThreshold
      //(0018,9720)
      = const PTag._('TerminationDensityThreshold', 0x00189720,
          'Termination Density Threshold', VR.kFD, VM.k1, false);
  static const PTag kTerminationRelativeDensityThreshold
      //(0018,9721)
      = const PTag._('TerminationRelativeDensityThreshold', 0x00189721,
          'Termination Relative Density Threshold', VR.kFD, VM.k1, false);
  static const PTag kTerminationTimeThreshold
      //(0018,9722)
      = const PTag._('TerminationTimeThreshold', 0x00189722, 'Termination Time Threshold',
          VR.kFD, VM.k1, false);
  static const PTag kTerminationCardiacTriggerCountThreshold
      //(0018,9723)
      = const PTag._('TerminationCardiacTriggerCountThreshold', 0x00189723,
          'Termination Cardiac Trigger Count Threshold', VR.kFD, VM.k1, false);
  static const PTag kTerminationRespiratoryTriggerCountThreshold
      //(0018,9724)
      = const PTag._('TerminationRespiratoryTriggerCountThreshold', 0x00189724,
          'Termination Respiratory Trigger Count Threshold', VR.kFD, VM.k1, false);
  static const PTag kDetectorGeometry
      //(0018,9725)
      = const PTag._(
          'DetectorGeometry', 0x00189725, 'Detector Geometry', VR.kCS, VM.k1, false);
  static const PTag kTransverseDetectorSeparation
      //(0018,9726)
      = const PTag._('TransverseDetectorSeparation', 0x00189726,
          'Transverse Detector Separation', VR.kFD, VM.k1, false);
  static const PTag kAxialDetectorDimension
      //(0018,9727)
      = const PTag._('AxialDetectorDimension', 0x00189727, 'Axial Detector Dimension',
          VR.kFD, VM.k1, false);
  static const PTag kRadiopharmaceuticalAgentNumber
      //(0018,9729)
      = const PTag._('RadiopharmaceuticalAgentNumber', 0x00189729,
          'Radiopharmaceutical Agent Number', VR.kUS, VM.k1, false);
  static const PTag kPETFrameAcquisitionSequence
      //(0018,9732)
      = const PTag._('PETFrameAcquisitionSequence', 0x00189732,
          'PET Frame Acquisition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPETDetectorMotionDetailsSequence
      //(0018,9733)
      = const PTag._('PETDetectorMotionDetailsSequence', 0x00189733,
          'PET Detector Motion Details Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPETTableDynamicsSequence
      //(0018,9734)
      = const PTag._('PETTableDynamicsSequence', 0x00189734,
          'PET Table Dynamics Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPETPositionSequence
      //(0018,9735)
      = const PTag._('PETPositionSequence', 0x00189735, 'PET Position Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kPETFrameCorrectionFactorsSequence
      //(0018,9736)
      = const PTag._('PETFrameCorrectionFactorsSequence', 0x00189736,
          'PET Frame Correction Factors Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRadiopharmaceuticalUsageSequence
      //(0018,9737)
      = const PTag._('RadiopharmaceuticalUsageSequence', 0x00189737,
          'Radiopharmaceutical Usage Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAttenuationCorrectionSource
      //(0018,9738)
      = const PTag._('AttenuationCorrectionSource', 0x00189738,
          'Attenuation Correction Source', VR.kCS, VM.k1, false);
  static const PTag kNumberOfIterations
      //(0018,9739)
      = const PTag._(
          'NumberOfIterations', 0x00189739, 'Number of Iterations', VR.kUS, VM.k1, false);
  static const PTag kNumberOfSubsets
      //(0018,9740)
      = const PTag._(
          'NumberOfSubsets', 0x00189740, 'Number of Subsets', VR.kUS, VM.k1, false);
  static const PTag kPETReconstructionSequence
      //(0018,9749)
      = const PTag._('PETReconstructionSequence', 0x00189749,
          'PET Reconstruction Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPETFrameTypeSequence
      //(0018,9751)
      = const PTag._('PETFrameTypeSequence', 0x00189751, 'PET Frame Type Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTimeOfFlightInformationUsed
      //(0018,9755)
      = const PTag._('TimeOfFlightInformationUsed', 0x00189755,
          'Time of Flight Information Used', VR.kCS, VM.k1, false);
  static const PTag kReconstructionType
      //(0018,9756)
      = const PTag._(
          'ReconstructionType', 0x00189756, 'Reconstruction Type', VR.kCS, VM.k1, false);
  static const PTag kDecayCorrected
      //(0018,9758)
      =
      const PTag._('DecayCorrected', 0x00189758, 'Decay Corrected', VR.kCS, VM.k1, false);
  static const PTag kAttenuationCorrected
      //(0018,9759)
      = const PTag._('AttenuationCorrected', 0x00189759, 'Attenuation Corrected', VR.kCS,
          VM.k1, false);
  static const PTag kScatterCorrected
      //(0018,9760)
      = const PTag._(
          'ScatterCorrected', 0x00189760, 'Scatter Corrected', VR.kCS, VM.k1, false);
  static const PTag kDeadTimeCorrected
      //(0018,9761)
      = const PTag._(
          'DeadTimeCorrected', 0x00189761, 'Dead Time Corrected', VR.kCS, VM.k1, false);
  static const PTag kGantryMotionCorrected
      //(0018,9762)
      = const PTag._('GantryMotionCorrected', 0x00189762, 'Gantry Motion Corrected',
          VR.kCS, VM.k1, false);
  static const PTag kPatientMotionCorrected
      //(0018,9763)
      = const PTag._('PatientMotionCorrected', 0x00189763, 'Patient Motion Corrected',
          VR.kCS, VM.k1, false);
  static const PTag kCountLossNormalizationCorrected
      //(0018,9764)
      = const PTag._('CountLossNormalizationCorrected', 0x00189764,
          'Count Loss Normalization Corrected', VR.kCS, VM.k1, false);
  static const PTag kRandomsCorrected
      //(0018,9765)
      = const PTag._(
          'RandomsCorrected', 0x00189765, 'Randoms Corrected', VR.kCS, VM.k1, false);
  static const PTag kNonUniformRadialSamplingCorrected
      //(0018,9766)
      = const PTag._('NonUniformRadialSamplingCorrected', 0x00189766,
          'Non-uniform Radial Sampling Corrected', VR.kCS, VM.k1, false);
  static const PTag kSensitivityCalibrated
      //(0018,9767)
      = const PTag._('SensitivityCalibrated', 0x00189767, 'Sensitivity Calibrated',
          VR.kCS, VM.k1, false);
  static const PTag kDetectorNormalizationCorrection
      //(0018,9768)
      = const PTag._('DetectorNormalizationCorrection', 0x00189768,
          'Detector Normalization Correction', VR.kCS, VM.k1, false);
  static const PTag kIterativeReconstructionMethod
      //(0018,9769)
      = const PTag._('IterativeReconstructionMethod', 0x00189769,
          'Iterative Reconstruction Method', VR.kCS, VM.k1, false);
  static const PTag kAttenuationCorrectionTemporalRelationship
      //(0018,9770)
      = const PTag._('AttenuationCorrectionTemporalRelationship', 0x00189770,
          'Attenuation Correction Temporal Relationship', VR.kCS, VM.k1, false);
  static const PTag kPatientPhysiologicalStateSequence
      //(0018,9771)
      = const PTag._('PatientPhysiologicalStateSequence', 0x00189771,
          'Patient Physiological State Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientPhysiologicalStateCodeSequence
      //(0018,9772)
      = const PTag._('PatientPhysiologicalStateCodeSequence', 0x00189772,
          'Patient Physiological State Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDepthsOfFocus
      //(0018,9801)
      = const PTag._(
          'DepthsOfFocus', 0x00189801, 'Depth(s) of Focus', VR.kFD, VM.k1_n, false);
  static const PTag kExcludedIntervalsSequence
      //(0018,9803)
      = const PTag._('ExcludedIntervalsSequence', 0x00189803,
          'Excluded Intervals Sequence', VR.kSQ, VM.k1, false);
  static const PTag kExclusionStartDateTime
      //(0018,9804)
      = const PTag._('ExclusionStartDateTime', 0x00189804, 'Exclusion Start DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kExclusionDuration
      //(0018,9805)
      = const PTag._(
          'ExclusionDuration', 0x00189805, 'Exclusion Duration', VR.kFD, VM.k1, false);
  static const PTag kUSImageDescriptionSequence
      //(0018,9806)
      = const PTag._('USImageDescriptionSequence', 0x00189806,
          'US Image Description Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageDataTypeSequence
      //(0018,9807)
      = const PTag._('ImageDataTypeSequence', 0x00189807, 'Image Data Type Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kDataType
      //(0018,9808)
      = const PTag._('DataType', 0x00189808, 'Data Type', VR.kCS, VM.k1, false);
  static const PTag kTransducerScanPatternCodeSequence
      //(0018,9809)
      = const PTag._('TransducerScanPatternCodeSequence', 0x00189809,
          'Transducer Scan Pattern Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAliasedDataType
      //(0018,980B)
      = const PTag._(
          'AliasedDataType', 0x0018980B, 'Aliased Data Type', VR.kCS, VM.k1, false);
  static const PTag kPositionMeasuringDeviceUsed
      //(0018,980C)
      = const PTag._('PositionMeasuringDeviceUsed', 0x0018980C,
          'Position Measuring Device Used', VR.kCS, VM.k1, false);
  static const PTag kTransducerGeometryCodeSequence
      //(0018,980D)
      = const PTag._('TransducerGeometryCodeSequence', 0x0018980D,
          'Transducer Geometry Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTransducerBeamSteeringCodeSequence
      //(0018,980E)
      = const PTag._('TransducerBeamSteeringCodeSequence', 0x0018980E,
          'Transducer Beam Steering Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTransducerApplicationCodeSequence
      //(0018,980F)
      = const PTag._('TransducerApplicationCodeSequence', 0x0018980F,
          'Transducer Application Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kZeroVelocityPixelValue
      //(0018,9810)
      = const PTag._('ZeroVelocityPixelValue', 0x00189810, 'Zero Velocity Pixel Value',
          VR.kUSSS, VM.k1, false);
  static const PTag kInstructionPerformedDateTime
      //(0018,9810)
      = const PTag._('InstructionPerformedDateTime', 0x00189919,
          'Instruction Performed Date Time', VR.kDT, VM.k1, false);
  static const PTag kContributingEquipmentSequence
      //(0018,A001)
      = const PTag._('ContributingEquipmentSequence', 0x0018A001,
          'Contributing Equipment Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContributionDateTime
      //(0018,A002)
      = const PTag._('ContributionDateTime', 0x0018A002, 'Contribution DateTime', VR.kDT,
          VM.k1, false);
  static const PTag kContributionDescription
      //(0018,A003)
      = const PTag._('ContributionDescription', 0x0018A003, 'Contribution Description',
          VR.kST, VM.k1, false);
  static const PTag kStudyInstanceUID
      //(0020,000D)
      = const PTag._(
          'StudyInstanceUID', 0x0020000D, 'Study Instance UID', VR.kUI, VM.k1, false);
  static const PTag kSeriesInstanceUID
      //(0020,000E)
      = const PTag._(
          'SeriesInstanceUID', 0x0020000E, 'Series Instance UID', VR.kUI, VM.k1, false);
  static const PTag kStudyID
      //(0020,0010)
      = const PTag._('StudyID', 0x00200010, 'Study ID', VR.kSH, VM.k1, false);
  static const PTag kSeriesNumber
      //(0020,0011)
      = const PTag._('SeriesNumber', 0x00200011, 'Series Number', VR.kIS, VM.k1, false);
  static const PTag kAcquisitionNumber
      //(0020,0012)
      = const PTag._(
          'AcquisitionNumber', 0x00200012, 'Acquisition Number', VR.kIS, VM.k1, false);
  static const PTag kInstanceNumber
      //(0020,0013)
      =
      const PTag._('InstanceNumber', 0x00200013, 'Instance Number', VR.kIS, VM.k1, false);
  static const PTag kIsotopeNumber
      //(0020,0014)
      = const PTag._('IsotopeNumber', 0x00200014, 'Isotope Number', VR.kIS, VM.k1, true);
  static const PTag kPhaseNumber
      //(0020,0015)
      = const PTag._('PhaseNumber', 0x00200015, 'Phase Number', VR.kIS, VM.k1, true);
  static const PTag kIntervalNumber
      //(0020,0016)
      =
      const PTag._('IntervalNumber', 0x00200016, 'Interval Number', VR.kIS, VM.k1, true);
  static const PTag kTimeSlotNumber
      //(0020,0017)
      =
      const PTag._('TimeSlotNumber', 0x00200017, 'Time Slot Number', VR.kIS, VM.k1, true);
  static const PTag kAngleNumber
      //(0020,0018)
      = const PTag._('AngleNumber', 0x00200018, 'Angle Number', VR.kIS, VM.k1, true);
  static const PTag kItemNumber
      //(0020,0019)
      = const PTag._('ItemNumber', 0x00200019, 'Item Number', VR.kIS, VM.k1, false);
  static const PTag kPatientOrientation
      //(0020,0020)
      = const PTag._(
          'PatientOrientation', 0x00200020, 'Patient Orientation', VR.kCS, VM.k2, false);
  static const PTag kOverlayNumber
      //(0020,0022)
      = const PTag._('OverlayNumber', 0x00200022, 'Overlay Number', VR.kIS, VM.k1, true);
  static const PTag kCurveNumber
      //(0020,0024)
      = const PTag._('CurveNumber', 0x00200024, 'Curve Number', VR.kIS, VM.k1, true);
  static const PTag kLUTNumber
      //(0020,0026)
      = const PTag._('LUTNumber', 0x00200026, 'LUT Number', VR.kIS, VM.k1, true);
  static const PTag kImagePosition
      //(0020,0030)
      = const PTag._('ImagePosition', 0x00200030, 'Image Position', VR.kDS, VM.k3, true);
  static const PTag kImagePositionPatient
      //(0020,0032)
      = const PTag._('ImagePositionPatient', 0x00200032, 'Image Position (Patient)',
          VR.kDS, VM.k3, false);
  static const PTag kImageOrientation
      //(0020,0035)
      = const PTag._(
          'ImageOrientation', 0x00200035, 'Image Orientation', VR.kDS, VM.k6, true);
  static const PTag kImageOrientationPatient
      //(0020,0037)
      = const PTag._('ImageOrientationPatient', 0x00200037, 'Image Orientation (Patient)',
          VR.kDS, VM.k6, false);
  static const PTag kLocation
      //(0020,0050)
      = const PTag._('Location', 0x00200050, 'Location', VR.kDS, VM.k1, true);
  static const PTag kFrameOfReferenceUID
      //(0020,0052)
      = const PTag._('FrameOfReferenceUID', 0x00200052, 'Frame of Reference UID', VR.kUI,
          VM.k1, false);
  static const PTag kLaterality
      //(0020,0060)
      = const PTag._('Laterality', 0x00200060, 'Laterality', VR.kCS, VM.k1, false);
  static const PTag kImageLaterality
      //(0020,0062)
      = const PTag._(
          'ImageLaterality', 0x00200062, 'Image Laterality', VR.kCS, VM.k1, false);
  static const PTag kImageGeometryType
      //(0020,0070)
      = const PTag._(
          'ImageGeometryType', 0x00200070, 'Image Geometry Type', VR.kLO, VM.k1, true);
  static const PTag kMaskingImage
      //(0020,0080)
      = const PTag._('MaskingImage', 0x00200080, 'Masking Image', VR.kCS, VM.k1_n, true);
  static const PTag kReportNumber
      //(0020,00AA)
      = const PTag._('ReportNumber', 0x002000AA, 'Report Number', VR.kIS, VM.k1, true);
  static const PTag kTemporalPositionIdentifier
      //(0020,0100)
      = const PTag._('TemporalPositionIdentifier', 0x00200100,
          'Temporal Position Identifier', VR.kIS, VM.k1, false);
  static const PTag kNumberOfTemporalPositions
      //(0020,0105)
      = const PTag._('NumberOfTemporalPositions', 0x00200105,
          'Number of Temporal Positions', VR.kIS, VM.k1, false);
  static const PTag kTemporalResolution
      //(0020,0110)
      = const PTag._(
          'TemporalResolution', 0x00200110, 'Temporal Resolution', VR.kDS, VM.k1, false);
  static const PTag kSynchronizationFrameOfReferenceUID
      //(0020,0200)
      = const PTag._('SynchronizationFrameOfReferenceUID', 0x00200200,
          'Synchronization Frame of Reference UID', VR.kUI, VM.k1, false);
  static const PTag kSOPInstanceUIDOfConcatenationSource
      //(0020,0242)
      = const PTag._('SOPInstanceUIDOfConcatenationSource', 0x00200242,
          'SOP Instance UID of Concatenation Source', VR.kUI, VM.k1, false);
  static const PTag kSeriesInStudy
      //(0020,1000)
      = const PTag._('SeriesInStudy', 0x00201000, 'Series in Study', VR.kIS, VM.k1, true);
  static const PTag kAcquisitionsInSeries
      //(0020,1001)
      = const PTag._('AcquisitionsInSeries', 0x00201001, 'Acquisitions in Series', VR.kIS,
          VM.k1, true);
  static const PTag kImagesInAcquisition
      //(0020,1002)
      = const PTag._('ImagesInAcquisition', 0x00201002, 'Images in Acquisition', VR.kIS,
          VM.k1, false);
  static const PTag kImagesInSeries
      //(0020,1003)
      =
      const PTag._('ImagesInSeries', 0x00201003, 'Images in Series', VR.kIS, VM.k1, true);
  static const PTag kAcquisitionsInStudy
      //(0020,1004)
      = const PTag._('AcquisitionsInStudy', 0x00201004, 'Acquisitions in Study', VR.kIS,
          VM.k1, true);
  static const PTag kImagesInStudy
      //(0020,1005)
      = const PTag._('ImagesInStudy', 0x00201005, 'Images in Study', VR.kIS, VM.k1, true);
  static const PTag kReference
      //(0020,1020)
      = const PTag._('Reference', 0x00201020, 'Reference', VR.kLO, VM.k1_n, true);
  static const PTag kPositionReferenceIndicator
      //(0020,1040)
      = const PTag._('PositionReferenceIndicator', 0x00201040,
          'Position Reference Indicator', VR.kLO, VM.k1, false);
  static const PTag kSliceLocation
      //(0020,1041)
      = const PTag._('SliceLocation', 0x00201041, 'Slice Location', VR.kDS, VM.k1, false);
  static const PTag kOtherStudyNumbers
      //(0020,1070)
      = const PTag._(
          'OtherStudyNumbers', 0x00201070, 'Other Study Numbers', VR.kIS, VM.k1_n, true);
  static const PTag kNumberOfPatientRelatedStudies
      //(0020,1200)
      = const PTag._('NumberOfPatientRelatedStudies', 0x00201200,
          'Number of Patient Related Studies', VR.kIS, VM.k1, false);
  static const PTag kNumberOfPatientRelatedSeries
      //(0020,1202)
      = const PTag._('NumberOfPatientRelatedSeries', 0x00201202,
          'Number of Patient Related Series', VR.kIS, VM.k1, false);
  static const PTag kNumberOfPatientRelatedInstances
      //(0020,1204)
      = const PTag._('NumberOfPatientRelatedInstances', 0x00201204,
          'Number of Patient Related Instances', VR.kIS, VM.k1, false);
  static const PTag kNumberOfStudyRelatedSeries
      //(0020,1206)
      = const PTag._('NumberOfStudyRelatedSeries', 0x00201206,
          'Number of Study Related Series', VR.kIS, VM.k1, false);
  static const PTag kNumberOfStudyRelatedInstances
      //(0020,1208)
      = const PTag._('NumberOfStudyRelatedInstances', 0x00201208,
          'Number of Study Related Instances', VR.kIS, VM.k1, false);
  static const PTag kNumberOfSeriesRelatedInstances
      //(0020,1209)
      = const PTag._('NumberOfSeriesRelatedInstances', 0x00201209,
          'Number of Series Related Instances', VR.kIS, VM.k1, false);
  static const PTag kSourceImageIDs
      //(0020,3100)
      = const PTag._(
          'SourceImageIDs', 0x00203100, 'Source Image IDs', VR.kCS, VM.k1_n, true);
  static const PTag kModifyingDeviceID
      //(0020,3401)
      = const PTag._(
          'ModifyingDeviceID', 0x00203401, 'Modifying Device ID', VR.kCS, VM.k1, true);
  static const PTag kModifiedImageID
      //(0020,3402)
      = const PTag._(
          'ModifiedImageID', 0x00203402, 'Modified Image ID', VR.kCS, VM.k1, true);
  static const PTag kModifiedImageDate
      //(0020,3403)
      = const PTag._(
          'ModifiedImageDate', 0x00203403, 'Modified Image Date', VR.kDA, VM.k1, true);
  static const PTag kModifyingDeviceManufacturer
      //(0020,3404)
      = const PTag._('ModifyingDeviceManufacturer', 0x00203404,
          'Modifying Device Manufacturer', VR.kLO, VM.k1, true);
  static const PTag kModifiedImageTime
      //(0020,3405)
      = const PTag._(
          'ModifiedImageTime', 0x00203405, 'Modified Image Time', VR.kTM, VM.k1, true);
  static const PTag kModifiedImageDescription
      //(0020,3406)
      = const PTag._('ModifiedImageDescription', 0x00203406, 'Modified Image Description',
          VR.kLO, VM.k1, true);
  static const PTag kImageComments
      //(0020,4000)
      = const PTag._('ImageComments', 0x00204000, 'Image Comments', VR.kLT, VM.k1, false);
  static const PTag kOriginalImageIdentification
      //(0020,5000)
      = const PTag._('OriginalImageIdentification', 0x00205000,
          'Original Image Identification', VR.kAT, VM.k1_n, true);
  static const PTag kOriginalImageIdentificationNomenclature
      //(0020,5002)
      = const PTag._('OriginalImageIdentificationNomenclature', 0x00205002,
          'Original Image Identification Nomenclature', VR.kLO, VM.k1_n, true);
  static const PTag kStackID
      //(0020,9056)
      = const PTag._('StackID', 0x00209056, 'Stack ID', VR.kSH, VM.k1, false);
  static const PTag kInStackPositionNumber
      //(0020,9057)
      = const PTag._('InStackPositionNumber', 0x00209057, 'In-Stack Position Number',
          VR.kUL, VM.k1, false);
  static const PTag kFrameAnatomySequence
      //(0020,9071)
      = const PTag._('FrameAnatomySequence', 0x00209071, 'Frame Anatomy Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kFrameLaterality
      //(0020,9072)
      = const PTag._(
          'FrameLaterality', 0x00209072, 'Frame Laterality', VR.kCS, VM.k1, false);
  static const PTag kFrameContentSequence
      //(0020,9111)
      = const PTag._('FrameContentSequence', 0x00209111, 'Frame Content Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kPlanePositionSequence
      //(0020,9113)
      = const PTag._('PlanePositionSequence', 0x00209113, 'Plane Position Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPlaneOrientationSequence
      //(0020,9116)
      = const PTag._('PlaneOrientationSequence', 0x00209116, 'Plane Orientation Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTemporalPositionIndex
      //(0020,9128)
      = const PTag._('TemporalPositionIndex', 0x00209128, 'Temporal Position Index',
          VR.kUL, VM.k1, false);
  static const PTag kNominalCardiacTriggerDelayTime
      //(0020,9153)
      = const PTag._('NominalCardiacTriggerDelayTime', 0x00209153,
          'Nominal Cardiac Trigger Delay Time', VR.kFD, VM.k1, false);
  static const PTag kNominalCardiacTriggerTimePriorToRPeak
      //(0020,9154)
      = const PTag._('NominalCardiacTriggerTimePriorToRPeak', 0x00209154,
          'Nominal Cardiac Trigger Time Prior To R-Peak', VR.kFL, VM.k1, false);
  static const PTag kActualCardiacTriggerTimePriorToRPeak
      //(0020,9155)
      = const PTag._('ActualCardiacTriggerTimePriorToRPeak', 0x00209155,
          'Actual Cardiac Trigger Time Prior To R-Peak', VR.kFL, VM.k1, false);
  static const PTag kFrameAcquisitionNumber
      //(0020,9156)
      = const PTag._('FrameAcquisitionNumber', 0x00209156, 'Frame Acquisition Number',
          VR.kUS, VM.k1, false);
  static const PTag kDimensionIndexValues
      //(0020,9157)
      = const PTag._('DimensionIndexValues', 0x00209157, 'Dimension Index Values', VR.kUL,
          VM.k1_n, false);
  static const PTag kFrameComments
      //(0020,9158)
      = const PTag._('FrameComments', 0x00209158, 'Frame Comments', VR.kLT, VM.k1, false);
  static const PTag kConcatenationUID
      //(0020,9161)
      = const PTag._(
          'ConcatenationUID', 0x00209161, 'Concatenation UID', VR.kUI, VM.k1, false);
  static const PTag kInConcatenationNumber
      //(0020,9162)
      = const PTag._('InConcatenationNumber', 0x00209162, 'In-concatenation Number',
          VR.kUS, VM.k1, false);
  static const PTag kInConcatenationTotalNumber
      //(0020,9163)
      = const PTag._('InConcatenationTotalNumber', 0x00209163,
          'In-concatenation Total Number', VR.kUS, VM.k1, false);
  static const PTag kDimensionOrganizationUID
      //(0020,9164)
      = const PTag._('DimensionOrganizationUID', 0x00209164, 'Dimension Organization UID',
          VR.kUI, VM.k1, false);
  static const PTag kDimensionIndexPointer
      //(0020,9165)
      = const PTag._('DimensionIndexPointer', 0x00209165, 'Dimension Index Pointer',
          VR.kAT, VM.k1, false);
  static const PTag kFunctionalGroupPointer
      //(0020,9167)
      = const PTag._('FunctionalGroupPointer', 0x00209167, 'Functional Group Pointer',
          VR.kAT, VM.k1, false);
  static const PTag kUnassignedSharedConvertedAttributesSequence
      //(0020,9170)
      = const PTag._('UnassignedSharedConvertedAttributesSequence', 0x00209170,
          'Unassigned Shared Converted Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kUnassignedPerFrameConvertedAttributesSequence
      //(0020,9171)
      = const PTag._('UnassignedPerFrameConvertedAttributesSequence', 0x00209171,
          'Unassigned Per-Frame Converted Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kConversionSourceAttributesSequence
      //(0020,9172)
      = const PTag._('ConversionSourceAttributesSequence', 0x00209172,
          'Conversion Source Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDimensionIndexPrivateCreator
      //(0020,9213)
      = const PTag._('DimensionIndexPrivateCreator', 0x00209213,
          'Dimension Index Private Creator', VR.kLO, VM.k1, false);
  static const PTag kDimensionOrganizationSequence
      //(0020,9221)
      = const PTag._('DimensionOrganizationSequence', 0x00209221,
          'Dimension Organization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDimensionIndexSequence
      //(0020,9222)
      = const PTag._('DimensionIndexSequence', 0x00209222, 'Dimension Index Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kConcatenationFrameOffsetNumber
      //(0020,9228)
      = const PTag._('ConcatenationFrameOffsetNumber', 0x00209228,
          'Concatenation Frame Offset Number', VR.kUL, VM.k1, false);
  static const PTag kFunctionalGroupPrivateCreator
      //(0020,9238)
      = const PTag._('FunctionalGroupPrivateCreator', 0x00209238,
          'Functional Group Private Creator', VR.kLO, VM.k1, false);
  static const PTag kNominalPercentageOfCardiacPhase
      //(0020,9241)
      = const PTag._('NominalPercentageOfCardiacPhase', 0x00209241,
          'Nominal Percentage of Cardiac Phase', VR.kFL, VM.k1, false);
  static const PTag kNominalPercentageOfRespiratoryPhase
      //(0020,9245)
      = const PTag._('NominalPercentageOfRespiratoryPhase', 0x00209245,
          'Nominal Percentage of Respiratory Phase', VR.kFL, VM.k1, false);
  static const PTag kStartingRespiratoryAmplitude
      //(0020,9246)
      = const PTag._('StartingRespiratoryAmplitude', 0x00209246,
          'Starting Respiratory Amplitude', VR.kFL, VM.k1, false);
  static const PTag kStartingRespiratoryPhase
      //(0020,9247)
      = const PTag._('StartingRespiratoryPhase', 0x00209247, 'Starting Respiratory Phase',
          VR.kCS, VM.k1, false);
  static const PTag kEndingRespiratoryAmplitude
      //(0020,9248)
      = const PTag._('EndingRespiratoryAmplitude', 0x00209248,
          'Ending Respiratory Amplitude', VR.kFL, VM.k1, false);
  static const PTag kEndingRespiratoryPhase
      //(0020,9249)
      = const PTag._('EndingRespiratoryPhase', 0x00209249, 'Ending Respiratory Phase',
          VR.kCS, VM.k1, false);
  static const PTag kRespiratoryTriggerType
      //(0020,9250)
      = const PTag._('RespiratoryTriggerType', 0x00209250, 'Respiratory Trigger Type',
          VR.kCS, VM.k1, false);
  static const PTag kRRIntervalTimeNominal
      //(0020,9251)
      = const PTag._('RRIntervalTimeNominal', 0x00209251, 'R-R Interval Time Nominal',
          VR.kFD, VM.k1, false);
  static const PTag kActualCardiacTriggerDelayTime
      //(0020,9252)
      = const PTag._('ActualCardiacTriggerDelayTime', 0x00209252,
          'Actual Cardiac Trigger Delay Time', VR.kFD, VM.k1, false);
  static const PTag kRespiratorySynchronizationSequence
      //(0020,9253)
      = const PTag._('RespiratorySynchronizationSequence', 0x00209253,
          'Respiratory Synchronization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRespiratoryIntervalTime
      //(0020,9254)
      = const PTag._('RespiratoryIntervalTime', 0x00209254, 'Respiratory Interval Time',
          VR.kFD, VM.k1, false);
  static const PTag kNominalRespiratoryTriggerDelayTime
      //(0020,9255)
      = const PTag._('NominalRespiratoryTriggerDelayTime', 0x00209255,
          'Nominal Respiratory Trigger Delay Time', VR.kFD, VM.k1, false);
  static const PTag kRespiratoryTriggerDelayThreshold
      //(0020,9256)
      = const PTag._('RespiratoryTriggerDelayThreshold', 0x00209256,
          'Respiratory Trigger Delay Threshold', VR.kFD, VM.k1, false);
  static const PTag kActualRespiratoryTriggerDelayTime
      //(0020,9257)
      = const PTag._('ActualRespiratoryTriggerDelayTime', 0x00209257,
          'Actual Respiratory Trigger Delay Time', VR.kFD, VM.k1, false);
  static const PTag kImagePositionVolume
      //(0020,9301)
      = const PTag._('ImagePositionVolume', 0x00209301, 'Image Position (Volume)', VR.kFD,
          VM.k3, false);
  static const PTag kImageOrientationVolume
      //(0020,9302)
      = const PTag._('ImageOrientationVolume', 0x00209302, 'Image Orientation (Volume)',
          VR.kFD, VM.k6, false);
  static const PTag kUltrasoundAcquisitionGeometry
      //(0020,9307)
      = const PTag._('UltrasoundAcquisitionGeometry', 0x00209307,
          'Ultrasound Acquisition Geometry', VR.kCS, VM.k1, false);
  static const PTag kApexPosition
      //(0020,9308)
      = const PTag._('ApexPosition', 0x00209308, 'Apex Position', VR.kFD, VM.k3, false);
  static const PTag kVolumeToTransducerMappingMatrix
      //(0020,9309)
      = const PTag._('VolumeToTransducerMappingMatrix', 0x00209309,
          'Volume to Transducer Mapping Matrix', VR.kFD, VM.k16, false);
  static const PTag kVolumeToTableMappingMatrix
      //(0020,930A)
      = const PTag._('VolumeToTableMappingMatrix', 0x0020930A,
          'Volume to Table Mapping Matrix', VR.kFD, VM.k16, false);
  static const PTag kPatientFrameOfReferenceSource
      //(0020,930C)
      = const PTag._('PatientFrameOfReferenceSource', 0x0020930C,
          'Patient Frame of Reference Source', VR.kCS, VM.k1, false);
  static const PTag kTemporalPositionTimeOffset
      //(0020,930D)
      = const PTag._('TemporalPositionTimeOffset', 0x0020930D,
          'Temporal Position Time Offset', VR.kFD, VM.k1, false);
  static const PTag kPlanePositionVolumeSequence
      //(0020,930E)
      = const PTag._('PlanePositionVolumeSequence', 0x0020930E,
          'Plane Position (Volume) Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPlaneOrientationVolumeSequence
      //(0020,930F)
      = const PTag._('PlaneOrientationVolumeSequence', 0x0020930F,
          'Plane Orientation (Volume) Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTemporalPositionSequence
      //(0020,9310)
      = const PTag._('TemporalPositionSequence', 0x00209310, 'Temporal Position Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kDimensionOrganizationType
      //(0020,9311)
      = const PTag._('DimensionOrganizationType', 0x00209311,
          'Dimension Organization Type', VR.kCS, VM.k1, false);
  static const PTag kVolumeFrameOfReferenceUID
      //(0020,9312)
      = const PTag._('VolumeFrameOfReferenceUID', 0x00209312,
          'Volume Frame of Reference UID', VR.kUI, VM.k1, false);
  static const PTag kTableFrameOfReferenceUID
      //(0020,9313)
      = const PTag._('TableFrameOfReferenceUID', 0x00209313,
          'Table Frame of Reference UID', VR.kUI, VM.k1, false);
  static const PTag kDimensionDescriptionLabel
      //(0020,9421)
      = const PTag._('DimensionDescriptionLabel', 0x00209421,
          'Dimension Description Label', VR.kLO, VM.k1, false);
  static const PTag kPatientOrientationInFrameSequence
      //(0020,9450)
      = const PTag._('PatientOrientationInFrameSequence', 0x00209450,
          'Patient Orientation in Frame Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFrameLabel
      //(0020,9453)
      = const PTag._('FrameLabel', 0x00209453, 'Frame Label', VR.kLO, VM.k1, false);
  static const PTag kAcquisitionIndex
      //(0020,9518)
      = const PTag._(
          'AcquisitionIndex', 0x00209518, 'Acquisition Index', VR.kUS, VM.k1_n, false);
  static const PTag kContributingSOPInstancesReferenceSequence
      //(0020,9529)
      = const PTag._('ContributingSOPInstancesReferenceSequence', 0x00209529,
          'Contributing SOP Instances Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReconstructionIndex
      //(0020,9536)
      = const PTag._('ReconstructionIndex', 0x00209536, 'Reconstruction Index', VR.kUS,
          VM.k1, false);
  static const PTag kLightPathFilterPassThroughWavelength
      //(0022,0001)
      = const PTag._('LightPathFilterPassThroughWavelength', 0x00220001,
          'Light Path Filter Pass-Through Wavelength', VR.kUS, VM.k1, false);
  static const PTag kLightPathFilterPassBand
      //(0022,0002)
      = const PTag._('LightPathFilterPassBand', 0x00220002, 'Light Path Filter Pass Band',
          VR.kUS, VM.k2, false);
  static const PTag kImagePathFilterPassThroughWavelength
      //(0022,0003)
      = const PTag._('ImagePathFilterPassThroughWavelength', 0x00220003,
          'Image Path Filter Pass-Through Wavelength', VR.kUS, VM.k1, false);
  static const PTag kImagePathFilterPassBand
      //(0022,0004)
      = const PTag._('ImagePathFilterPassBand', 0x00220004, 'Image Path Filter Pass Band',
          VR.kUS, VM.k2, false);
  static const PTag kPatientEyeMovementCommanded
      //(0022,0005)
      = const PTag._('PatientEyeMovementCommanded', 0x00220005,
          'Patient Eye Movement Commanded', VR.kCS, VM.k1, false);
  static const PTag kPatientEyeMovementCommandCodeSequence
      //(0022,0006)
      = const PTag._('PatientEyeMovementCommandCodeSequence', 0x00220006,
          'Patient Eye Movement Command Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSphericalLensPower
      //(0022,0007)
      = const PTag._(
          'SphericalLensPower', 0x00220007, 'Spherical Lens Power', VR.kFL, VM.k1, false);
  static const PTag kCylinderLensPower
      //(0022,0008)
      = const PTag._(
          'CylinderLensPower', 0x00220008, 'Cylinder Lens Power', VR.kFL, VM.k1, false);
  static const PTag kCylinderAxis
      //(0022,0009)
      = const PTag._('CylinderAxis', 0x00220009, 'Cylinder Axis', VR.kFL, VM.k1, false);
  static const PTag kEmmetropicMagnification
      //(0022,000A)
      = const PTag._('EmmetropicMagnification', 0x0022000A, 'Emmetropic Magnification',
          VR.kFL, VM.k1, false);
  static const PTag kIntraOcularPressure
      //(0022,000B)
      = const PTag._('IntraOcularPressure', 0x0022000B, 'Intra Ocular Pressure', VR.kFL,
          VM.k1, false);
  static const PTag kHorizontalFieldOfView
      //(0022,000C)
      = const PTag._('HorizontalFieldOfView', 0x0022000C, 'Horizontal Field of View',
          VR.kFL, VM.k1, false);
  static const PTag kPupilDilated
      //(0022,000D)
      = const PTag._('PupilDilated', 0x0022000D, 'Pupil Dilated', VR.kCS, VM.k1, false);
  static const PTag kDegreeOfDilation
      //(0022,000E)
      = const PTag._(
          'DegreeOfDilation', 0x0022000E, 'Degree of Dilation', VR.kFL, VM.k1, false);
  static const PTag kStereoBaselineAngle
      //(0022,0010)
      = const PTag._('StereoBaselineAngle', 0x00220010, 'Stereo Baseline Angle', VR.kFL,
          VM.k1, false);
  static const PTag kStereoBaselineDisplacement
      //(0022,0011)
      = const PTag._('StereoBaselineDisplacement', 0x00220011,
          'Stereo Baseline Displacement', VR.kFL, VM.k1, false);
  static const PTag kStereoHorizontalPixelOffset
      //(0022,0012)
      = const PTag._('StereoHorizontalPixelOffset', 0x00220012,
          'Stereo Horizontal Pixel Offset', VR.kFL, VM.k1, false);
  static const PTag kStereoVerticalPixelOffset
      //(0022,0013)
      = const PTag._('StereoVerticalPixelOffset', 0x00220013,
          'Stereo Vertical Pixel Offset', VR.kFL, VM.k1, false);
  static const PTag kStereoRotation
      //(0022,0014)
      =
      const PTag._('StereoRotation', 0x00220014, 'Stereo Rotation', VR.kFL, VM.k1, false);
  static const PTag kAcquisitionDeviceTypeCodeSequence
      //(0022,0015)
      = const PTag._('AcquisitionDeviceTypeCodeSequence', 0x00220015,
          'Acquisition Device Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIlluminationTypeCodeSequence
      //(0022,0016)
      = const PTag._('IlluminationTypeCodeSequence', 0x00220016,
          'Illumination Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLightPathFilterTypeStackCodeSequence
      //(0022,0017)
      = const PTag._('LightPathFilterTypeStackCodeSequence', 0x00220017,
          'Light Path Filter Type Stack Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImagePathFilterTypeStackCodeSequence
      //(0022,0018)
      = const PTag._('ImagePathFilterTypeStackCodeSequence', 0x00220018,
          'Image Path Filter Type Stack Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLensesCodeSequence
      //(0022,0019)
      = const PTag._(
          'LensesCodeSequence', 0x00220019, 'Lenses Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChannelDescriptionCodeSequence
      //(0022,001A)
      = const PTag._('ChannelDescriptionCodeSequence', 0x0022001A,
          'Channel Description Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRefractiveStateSequence
      //(0022,001B)
      = const PTag._('RefractiveStateSequence', 0x0022001B, 'Refractive State Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kMydriaticAgentCodeSequence
      //(0022,001C)
      = const PTag._('MydriaticAgentCodeSequence', 0x0022001C,
          'Mydriatic Agent Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRelativeImagePositionCodeSequence
      //(0022,001D)
      = const PTag._('RelativeImagePositionCodeSequence', 0x0022001D,
          'Relative Image Position Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCameraAngleOfView
      //(0022,001E)
      = const PTag._(
          'CameraAngleOfView', 0x0022001E, 'Camera Angle of View', VR.kFL, VM.k1, false);
  static const PTag kStereoPairsSequence
      //(0022,0020)
      = const PTag._('StereoPairsSequence', 0x00220020, 'Stereo Pairs Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kLeftImageSequence
      //(0022,0021)
      = const PTag._(
          'LeftImageSequence', 0x00220021, 'Left Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRightImageSequence
      //(0022,0022)
      = const PTag._(
          'RightImageSequence', 0x00220022, 'Right Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAxialLengthOfTheEye
      //(0022,0030)
      = const PTag._('AxialLengthOfTheEye', 0x00220030, 'Axial Length of the Eye', VR.kFL,
          VM.k1, false);
  static const PTag kOphthalmicFrameLocationSequence
      //(0022,0031)
      = const PTag._('OphthalmicFrameLocationSequence', 0x00220031,
          'Ophthalmic Frame Location Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferenceCoordinates
      //(0022,0032)
      = const PTag._('ReferenceCoordinates', 0x00220032, 'Reference Coordinates', VR.kFL,
          VM.k2_2n, false);
  static const PTag kDepthSpatialResolution
      //(0022,0035)
      = const PTag._('DepthSpatialResolution', 0x00220035, 'Depth Spatial Resolution',
          VR.kFL, VM.k1, false);
  static const PTag kMaximumDepthDistortion
      //(0022,0036)
      = const PTag._('MaximumDepthDistortion', 0x00220036, 'Maximum Depth Distortion',
          VR.kFL, VM.k1, false);
  static const PTag kAlongScanSpatialResolution
      //(0022,0037)
      = const PTag._('AlongScanSpatialResolution', 0x00220037,
          'Along-scan Spatial Resolution', VR.kFL, VM.k1, false);
  static const PTag kMaximumAlongScanDistortion
      //(0022,0038)
      = const PTag._('MaximumAlongScanDistortion', 0x00220038,
          'Maximum Along-scan Distortion', VR.kFL, VM.k1, false);
  static const PTag kOphthalmicImageOrientation
      //(0022,0039)
      = const PTag._('OphthalmicImageOrientation', 0x00220039,
          'Ophthalmic Image Orientation', VR.kCS, VM.k1, false);
  static const PTag kDepthOfTransverseImage
      //(0022,0041)
      = const PTag._('DepthOfTransverseImage', 0x00220041, 'Depth of Transverse Image',
          VR.kFL, VM.k1, false);
  static const PTag kMydriaticAgentConcentrationUnitsSequence
      //(0022,0042)
      = const PTag._('MydriaticAgentConcentrationUnitsSequence', 0x00220042,
          'Mydriatic Agent Concentration Units Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAcrossScanSpatialResolution
      //(0022,0048)
      = const PTag._('AcrossScanSpatialResolution', 0x00220048,
          'Across-scan Spatial Resolution', VR.kFL, VM.k1, false);
  static const PTag kMaximumAcrossScanDistortion
      //(0022,0049)
      = const PTag._('MaximumAcrossScanDistortion', 0x00220049,
          'Maximum Across-scan Distortion', VR.kFL, VM.k1, false);
  static const PTag kMydriaticAgentConcentration
      //(0022,004E)
      = const PTag._('MydriaticAgentConcentration', 0x0022004E,
          'Mydriatic Agent Concentration', VR.kDS, VM.k1, false);
  static const PTag kIlluminationWaveLength
      //(0022,0055)
      = const PTag._('IlluminationWaveLength', 0x00220055, 'Illumination Wave Length',
          VR.kFL, VM.k1, false);
  static const PTag kIlluminationPower
      //(0022,0056)
      = const PTag._(
          'IlluminationPower', 0x00220056, 'Illumination Power', VR.kFL, VM.k1, false);
  static const PTag kIlluminationBandwidth
      //(0022,0057)
      = const PTag._('IlluminationBandwidth', 0x00220057, 'Illumination Bandwidth',
          VR.kFL, VM.k1, false);
  static const PTag kMydriaticAgentSequence
      //(0022,0058)
      = const PTag._('MydriaticAgentSequence', 0x00220058, 'Mydriatic Agent Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialMeasurementsRightEyeSequence
      //(0022,1007)
      = const PTag._('OphthalmicAxialMeasurementsRightEyeSequence', 0x00221007,
          'Ophthalmic Axial Measurements Right Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialMeasurementsLeftEyeSequence
      //(0022,1008)
      = const PTag._('OphthalmicAxialMeasurementsLeftEyeSequence', 0x00221008,
          'Ophthalmic Axial Measurements Left Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialMeasurementsDeviceType
      //(0022,1009)
      = const PTag._('OphthalmicAxialMeasurementsDeviceType', 0x00221009,
          'Ophthalmic Axial Measurements Device Type', VR.kCS, VM.k1, false);
  static const PTag kOphthalmicAxialLengthMeasurementsType
      //(0022,1010)
      = const PTag._('OphthalmicAxialLengthMeasurementsType', 0x00221010,
          'Ophthalmic Axial Length Measurements Type', VR.kCS, VM.k1, false);
  static const PTag kOphthalmicAxialLengthSequence
      //(0022,1012)
      = const PTag._('OphthalmicAxialLengthSequence', 0x00221012,
          'Ophthalmic Axial Length Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLength
      //(0022,1019)
      = const PTag._('OphthalmicAxialLength', 0x00221019, 'Ophthalmic Axial Length',
          VR.kFL, VM.k1, false);
  static const PTag kLensStatusCodeSequence
      //(0022,1024)
      = const PTag._('LensStatusCodeSequence', 0x00221024, 'Lens Status Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kVitreousStatusCodeSequence
      //(0022,1025)
      = const PTag._('VitreousStatusCodeSequence', 0x00221025,
          'Vitreous Status Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIOLFormulaCodeSequence
      //(0022,1028)
      = const PTag._('IOLFormulaCodeSequence', 0x00221028, 'IOL Formula Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kIOLFormulaDetail
      //(0022,1029)
      = const PTag._(
          'IOLFormulaDetail', 0x00221029, 'IOL Formula Detail', VR.kLO, VM.k1, false);
  static const PTag kKeratometerIndex
      //(0022,1033)
      = const PTag._(
          'KeratometerIndex', 0x00221033, 'Keratometer Index', VR.kFL, VM.k1, false);
  static const PTag kSourceOfOphthalmicAxialLengthCodeSequence
      //(0022,1035)
      = const PTag._('SourceOfOphthalmicAxialLengthCodeSequence', 0x00221035,
          'Source of Ophthalmic Axial Length Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTargetRefraction
      //(0022,1037)
      = const PTag._(
          'TargetRefraction', 0x00221037, 'Target Refraction', VR.kFL, VM.k1, false);
  static const PTag kRefractiveProcedureOccurred
      //(0022,1039)
      = const PTag._('RefractiveProcedureOccurred', 0x00221039,
          'Refractive Procedure Occurred', VR.kCS, VM.k1, false);
  static const PTag kRefractiveSurgeryTypeCodeSequence
      //(0022,1040)
      = const PTag._('RefractiveSurgeryTypeCodeSequence', 0x00221040,
          'Refractive Surgery Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicUltrasoundMethodCodeSequence
      //(0022,1044)
      = const PTag._('OphthalmicUltrasoundMethodCodeSequence', 0x00221044,
          'Ophthalmic Ultrasound Method Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthMeasurementsSequence
      //(0022,1050)
      = const PTag._('OphthalmicAxialLengthMeasurementsSequence', 0x00221050,
          'Ophthalmic Axial Length Measurements Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIOLPower
      //(0022,1053)
      = const PTag._('IOLPower', 0x00221053, 'IOL Power', VR.kFL, VM.k1, false);
  static const PTag kPredictedRefractiveError
      //(0022,1054)
      = const PTag._('PredictedRefractiveError', 0x00221054, 'Predicted Refractive Error',
          VR.kFL, VM.k1, false);
  static const PTag kOphthalmicAxialLengthVelocity
      //(0022,1059)
      = const PTag._('OphthalmicAxialLengthVelocity', 0x00221059,
          'Ophthalmic Axial Length Velocity', VR.kFL, VM.k1, false);
  static const PTag kLensStatusDescription
      //(0022,1065)
      = const PTag._('LensStatusDescription', 0x00221065, 'Lens Status Description',
          VR.kLO, VM.k1, false);
  static const PTag kVitreousStatusDescription
      //(0022,1066)
      = const PTag._('VitreousStatusDescription', 0x00221066,
          'Vitreous Status Description', VR.kLO, VM.k1, false);
  static const PTag kIOLPowerSequence
      //(0022,1090)
      = const PTag._(
          'IOLPowerSequence', 0x00221090, 'IOL Power Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLensConstantSequence
      //(0022,1092)
      = const PTag._('LensConstantSequence', 0x00221092, 'Lens Constant Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kIOLManufacturer
      //(0022,1093)
      = const PTag._(
          'IOLManufacturer', 0x00221093, 'IOL Manufacturer', VR.kLO, VM.k1, false);
  static const PTag kLensConstantDescription
      //(0022,1094)
      = const PTag._('LensConstantDescription', 0x00221094, 'Lens Constant Description',
          VR.kLO, VM.k1, true);
  static const PTag kImplantName
      //(0022,1095)
      = const PTag._('ImplantName', 0x00221095, 'Implant Name', VR.kLO, VM.k1, false);
  static const PTag kKeratometryMeasurementTypeCodeSequence
      //(0022,1096)
      = const PTag._('KeratometryMeasurementTypeCodeSequence', 0x00221096,
          'Keratometry Measurement Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantPartNumber
      //(0022,1097)
      = const PTag._(
          'ImplantPartNumber', 0x00221097, 'Implant Part Number', VR.kLO, VM.k1, false);
  static const PTag kReferencedOphthalmicAxialMeasurementsSequence
      //(0022,1100)
      = const PTag._('ReferencedOphthalmicAxialMeasurementsSequence', 0x00221100,
          'Referenced Ophthalmic Axial Measurements Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthMeasurementsSegmentNameCodeSequence
      //(0022,1101)
      = const PTag._(
          'OphthalmicAxialLengthMeasurementsSegmentNameCodeSequence',
          0x00221101,
          'Ophthalmic Axial Length Measurements Segment Name Code Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kRefractiveErrorBeforeRefractiveSurgeryCodeSequence
      //(0022,1103)
      = const PTag._(
          'RefractiveErrorBeforeRefractiveSurgeryCodeSequence',
          0x00221103,
          'Refractive Error Before Refractive Surgery Code Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kIOLPowerForExactEmmetropia
      //(0022,1121)
      = const PTag._('IOLPowerForExactEmmetropia', 0x00221121,
          'IOL Power For Exact Emmetropia', VR.kFL, VM.k1, false);
  static const PTag kIOLPowerForExactTargetRefraction
      //(0022,1122)
      = const PTag._('IOLPowerForExactTargetRefraction', 0x00221122,
          'IOL Power For Exact Target Refraction', VR.kFL, VM.k1, false);
  static const PTag kAnteriorChamberDepthDefinitionCodeSequence
      //(0022,1125)
      = const PTag._('AnteriorChamberDepthDefinitionCodeSequence', 0x00221125,
          'Anterior Chamber Depth Definition Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLensThicknessSequence
      //(0022,1127)
      = const PTag._('LensThicknessSequence', 0x00221127, 'Lens Thickness Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kAnteriorChamberDepthSequence
      //(0022,1128)
      = const PTag._('AnteriorChamberDepthSequence', 0x00221128,
          'Anterior Chamber Depth Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLensThickness
      //(0022,1130)
      = const PTag._('LensThickness', 0x00221130, 'Lens Thickness', VR.kFL, VM.k1, false);
  static const PTag kAnteriorChamberDepth
      //(0022,1131)
      = const PTag._('AnteriorChamberDepth', 0x00221131, 'Anterior Chamber Depth', VR.kFL,
          VM.k1, false);
  static const PTag kSourceOfLensThicknessDataCodeSequence
      //(0022,1132)
      = const PTag._('SourceOfLensThicknessDataCodeSequence', 0x00221132,
          'Source of Lens Thickness Data Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourceOfAnteriorChamberDepthDataCodeSequence
      //(0022,1133)
      = const PTag._('SourceOfAnteriorChamberDepthDataCodeSequence', 0x00221133,
          'Source of Anterior Chamber Depth Data Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourceOfRefractiveMeasurementsSequence
      //(0022,1134)
      = const PTag._('SourceOfRefractiveMeasurementsSequence', 0x00221134,
          'Source of Refractive Measurements Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourceOfRefractiveMeasurementsCodeSequence
      //(0022,1135)
      = const PTag._('SourceOfRefractiveMeasurementsCodeSequence', 0x00221135,
          'Source of Refractive Measurements Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthMeasurementModified
      //(0022,1140)
      = const PTag._('OphthalmicAxialLengthMeasurementModified', 0x00221140,
          'Ophthalmic Axial Length Measurement Modified', VR.kCS, VM.k1, false);
  static const PTag kOphthalmicAxialLengthDataSourceCodeSequence
      //(0022,1150)
      = const PTag._('OphthalmicAxialLengthDataSourceCodeSequence', 0x00221150,
          'Ophthalmic Axial Length Data Source Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthAcquisitionMethodCodeSequence
      //(0022,1153)
      = const PTag._(
          'OphthalmicAxialLengthAcquisitionMethodCodeSequence',
          0x00221153,
          'Ophthalmic Axial Length Acquisition Method Code Sequence',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kSignalToNoiseRatio
      //(0022,1155)
      = const PTag._('SignalToNoiseRatio', 0x00221155, 'Signal to Noise Ratio', VR.kFL,
          VM.k1, false);
  static const PTag kOphthalmicAxialLengthDataSourceDescription
      //(0022,1159)
      = const PTag._('OphthalmicAxialLengthDataSourceDescription', 0x00221159,
          'Ophthalmic Axial Length Data Source Description', VR.kLO, VM.k1, false);
  static const PTag kOphthalmicAxialLengthMeasurementsTotalLengthSequence
      //(0022,1210)
      = const PTag._(
          'OphthalmicAxialLengthMeasurementsTotalLengthSequence',
          0x00221210,
          'Ophthalmic Axial Length Measurements Total Length Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kOphthalmicAxialLengthMeasurementsSegmentalLengthSequence
      //(0022,1211)
      = const PTag._(
          'OphthalmicAxialLengthMeasurementsSegmentalLengthSequence',
          0x00221211,
          'Ophthalmic Axial Length Measurements Segmental Length Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kOphthalmicAxialLengthMeasurementsLengthSummationSequence
      //(0022,1212)
      = const PTag._(
          'OphthalmicAxialLengthMeasurementsLengthSummationSequence',
          0x00221212,
          'Ophthalmic Axial Length Measurements Length Summation Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kUltrasoundOphthalmicAxialLengthMeasurementsSequence
      //(0022,1220)
      = const PTag._(
          'UltrasoundOphthalmicAxialLengthMeasurementsSequence',
          0x00221220,
          'Ultrasound Ophthalmic Axial Length Measurements Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kOpticalOphthalmicAxialLengthMeasurementsSequence
      //(0022,1225)
      = const PTag._('OpticalOphthalmicAxialLengthMeasurementsSequence', 0x00221225,
          'Optical Ophthalmic Axial Length Measurements Sequence', VR.kSQ, VM.k1, false);
  static const PTag kUltrasoundSelectedOphthalmicAxialLengthSequence
      //(0022,1230)
      = const PTag._('UltrasoundSelectedOphthalmicAxialLengthSequence', 0x00221230,
          'Ultrasound Selected Ophthalmic Axial Length Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthSelectionMethodCodeSequence
      //(0022,1250)
      = const PTag._('OphthalmicAxialLengthSelectionMethodCodeSequence', 0x00221250,
          'Ophthalmic Axial Length Selection Method Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOpticalSelectedOphthalmicAxialLengthSequence
      //(0022,1255)
      = const PTag._('OpticalSelectedOphthalmicAxialLengthSequence', 0x00221255,
          'Optical Selected Ophthalmic Axial Length Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSelectedSegmentalOphthalmicAxialLengthSequence
      //(0022,1257)
      = const PTag._('SelectedSegmentalOphthalmicAxialLengthSequence', 0x00221257,
          'Selected Segmental Ophthalmic Axial Length Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSelectedTotalOphthalmicAxialLengthSequence
      //(0022,1260)
      = const PTag._('SelectedTotalOphthalmicAxialLengthSequence', 0x00221260,
          'Selected Total Ophthalmic Axial Length Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthQualityMetricSequence
      //(0022,1262)
      = const PTag._('OphthalmicAxialLengthQualityMetricSequence', 0x00221262,
          'Ophthalmic Axial Length Quality Metric Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicAxialLengthQualityMetricTypeCodeSequence
      //(0022,1265)
      = const PTag._(
          'OphthalmicAxialLengthQualityMetricTypeCodeSequence',
          0x00221265,
          'Ophthalmic Axial Length Quality Metric Type Code Sequence',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kOphthalmicAxialLengthQualityMetricTypeDescription
      //(0022,1273)
      = const PTag._('OphthalmicAxialLengthQualityMetricTypeDescription', 0x00221273,
          'Ophthalmic Axial Length Quality Metric Type Description', VR.kLO, VM.k1, true);
  static const PTag kIntraocularLensCalculationsRightEyeSequence
      //(0022,1300)
      = const PTag._('IntraocularLensCalculationsRightEyeSequence', 0x00221300,
          'Intraocular Lens Calculations Right Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIntraocularLensCalculationsLeftEyeSequence
      //(0022,1310)
      = const PTag._('IntraocularLensCalculationsLeftEyeSequence', 0x00221310,
          'Intraocular Lens Calculations Left Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedOphthalmicAxialLengthMeasurementQCImageSequence
      //(0022,1330)
      = const PTag._(
          'ReferencedOphthalmicAxialLengthMeasurementQCImageSequence',
          0x00221330,
          'Referenced Ophthalmic Axial Length Measurement QC Image Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kOphthalmicMappingDeviceType
      //(0022,1415)
      = const PTag._('OphthalmicMappingDeviceType', 0x00221415,
          'Ophthalmic Mapping Device Type', VR.kCS, VM.k1, false);
  static const PTag kAcquisitionMethodCodeSequence
      //(0022,1420)
      = const PTag._('AcquisitionMethodCodeSequence', 0x00221420,
          'Acquisition Method Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAcquisitionMethodAlgorithmSequence
      //(0022,1423)
      = const PTag._('AcquisitionMethodAlgorithmSequence', 0x00221423,
          'Acquisition Method Algorithm Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicThicknessMapTypeCodeSequence
      //(0022,1436)
      = const PTag._('OphthalmicThicknessMapTypeCodeSequence', 0x00221436,
          'Ophthalmic Thickness Map Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicThicknessMappingNormalsSequence
      //(0022,1443)
      = const PTag._('OphthalmicThicknessMappingNormalsSequence', 0x00221443,
          'Ophthalmic Thickness Mapping Normals Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRetinalThicknessDefinitionCodeSequence
      //(0022,1445)
      = const PTag._('RetinalThicknessDefinitionCodeSequence', 0x00221445,
          'Retinal Thickness Definition Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPixelValueMappingToCodedConceptSequence
      //(0022,1450)
      = const PTag._('PixelValueMappingToCodedConceptSequence', 0x00221450,
          'Pixel Value Mapping to Coded Concept Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMappedPixelValue
      //(0022,1452)
      = const PTag._(
          'MappedPixelValue', 0x00221452, 'Mapped Pixel Value', VR.kUSSS, VM.k1, false);
  static const PTag kPixelValueMappingExplanation
      //(0022,1454)
      = const PTag._('PixelValueMappingExplanation', 0x00221454,
          'Pixel Value Mapping Explanation', VR.kLO, VM.k1, false);
  static const PTag kOphthalmicThicknessMapQualityThresholdSequence
      //(0022,1458)
      = const PTag._('OphthalmicThicknessMapQualityThresholdSequence', 0x00221458,
          'Ophthalmic Thickness Map Quality Threshold Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOphthalmicThicknessMapThresholdQualityRating
      //(0022,1460)
      = const PTag._('OphthalmicThicknessMapThresholdQualityRating', 0x00221460,
          'Ophthalmic Thickness Map Threshold Quality Rating', VR.kFL, VM.k1, false);
  static const PTag kAnatomicStructureReferencePoint
      //(0022,1463)
      = const PTag._('AnatomicStructureReferencePoint', 0x00221463,
          'Anatomic Structure Reference Point', VR.kFL, VM.k2, false);
  static const PTag kRegistrationToLocalizerSequence
      //(0022,1465)
      = const PTag._('RegistrationToLocalizerSequence', 0x00221465,
          'Registration to Localizer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRegisteredLocalizerUnits
      //(0022,1466)
      = const PTag._('RegisteredLocalizerUnits', 0x00221466, 'Registered Localizer Units',
          VR.kCS, VM.k1, false);
  static const PTag kRegisteredLocalizerTopLeftHandCorner
      //(0022,1467)
      = const PTag._('RegisteredLocalizerTopLeftHandCorner', 0x00221467,
          'Registered Localizer Top Left Hand Corner', VR.kFL, VM.k2, false);
  static const PTag kRegisteredLocalizerBottomRightHandCorner
      //(0022,1468)
      = const PTag._('RegisteredLocalizerBottomRightHandCorner', 0x00221468,
          'Registered Localizer Bottom Right Hand Corner', VR.kFL, VM.k2, false);
  static const PTag kOphthalmicThicknessMapQualityRatingSequence
      //(0022,1470)
      = const PTag._('OphthalmicThicknessMapQualityRatingSequence', 0x00221470,
          'Ophthalmic Thickness Map Quality Rating Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRelevantOPTAttributesSequence
      //(0022,1472)
      = const PTag._('RelevantOPTAttributesSequence', 0x00221472,
          'Relevant OPT Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualFieldHorizontalExtent
      //(0024,0010)
      = const PTag._('VisualFieldHorizontalExtent', 0x00240010,
          'Visual Field Horizontal Extent', VR.kFL, VM.k1, false);
  static const PTag kVisualFieldVerticalExtent
      //(0024,0011)
      = const PTag._('VisualFieldVerticalExtent', 0x00240011,
          'Visual Field Vertical Extent', VR.kFL, VM.k1, false);
  static const PTag kVisualFieldShape
      //(0024,0012)
      = const PTag._(
          'VisualFieldShape', 0x00240012, 'Visual Field Shape', VR.kCS, VM.k1, false);
  static const PTag kScreeningTestModeCodeSequence
      //(0024,0016)
      = const PTag._('ScreeningTestModeCodeSequence', 0x00240016,
          'Screening Test Mode Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMaximumStimulusLuminance
      //(0024,0018)
      = const PTag._('MaximumStimulusLuminance', 0x00240018, 'Maximum Stimulus Luminance',
          VR.kFL, VM.k1, false);
  static const PTag kBackgroundLuminance
      //(0024,0020)
      = const PTag._('BackgroundLuminance', 0x00240020, 'Background Luminance', VR.kFL,
          VM.k1, false);
  static const PTag kStimulusColorCodeSequence
      //(0024,0021)
      = const PTag._('StimulusColorCodeSequence', 0x00240021,
          'Stimulus Color Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBackgroundIlluminationColorCodeSequence
      //(0024,0024)
      = const PTag._('BackgroundIlluminationColorCodeSequence', 0x00240024,
          'Background Illumination Color Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStimulusArea
      //(0024,0025)
      = const PTag._('StimulusArea', 0x00240025, 'Stimulus Area', VR.kFL, VM.k1, false);
  static const PTag kStimulusPresentationTime
      //(0024,0028)
      = const PTag._('StimulusPresentationTime', 0x00240028, 'Stimulus Presentation Time',
          VR.kFL, VM.k1, false);
  static const PTag kFixationSequence
      //(0024,0032)
      = const PTag._(
          'FixationSequence', 0x00240032, 'Fixation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFixationMonitoringCodeSequence
      //(0024,0033)
      = const PTag._('FixationMonitoringCodeSequence', 0x00240033,
          'Fixation Monitoring Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualFieldCatchTrialSequence
      //(0024,0034)
      = const PTag._('VisualFieldCatchTrialSequence', 0x00240034,
          'Visual Field Catch Trial Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFixationCheckedQuantity
      //(0024,0035)
      = const PTag._('FixationCheckedQuantity', 0x00240035, 'Fixation Checked Quantity',
          VR.kUS, VM.k1, false);
  static const PTag kPatientNotProperlyFixatedQuantity
      //(0024,0036)
      = const PTag._('PatientNotProperlyFixatedQuantity', 0x00240036,
          'Patient Not Properly Fixated Quantity', VR.kUS, VM.k1, false);
  static const PTag kPresentedVisualStimuliDataFlag
      //(0024,0037)
      = const PTag._('PresentedVisualStimuliDataFlag', 0x00240037,
          'Presented Visual Stimuli Data Flag', VR.kCS, VM.k1, false);
  static const PTag kNumberOfVisualStimuli
      //(0024,0038)
      = const PTag._('NumberOfVisualStimuli', 0x00240038, 'Number of Visual Stimuli',
          VR.kUS, VM.k1, false);
  static const PTag kExcessiveFixationLossesDataFlag
      //(0024,0039)
      = const PTag._('ExcessiveFixationLossesDataFlag', 0x00240039,
          'Excessive Fixation Losses Data Flag', VR.kCS, VM.k1, false);
  static const PTag kExcessiveFixationLosses
      //(0024,0040)
      = const PTag._('ExcessiveFixationLosses', 0x00240040, 'Excessive Fixation Losses',
          VR.kCS, VM.k1, false);
  static const PTag kStimuliRetestingQuantity
      //(0024,0042)
      = const PTag._('StimuliRetestingQuantity', 0x00240042, 'Stimuli Retesting Quantity',
          VR.kUS, VM.k1, false);
  static const PTag kCommentsOnPatientPerformanceOfVisualField
      //(0024,0044)
      = const PTag._('CommentsOnPatientPerformanceOfVisualField', 0x00240044,
          'Comments on Patient\'s Performance of Visual Field', VR.kLT, VM.k1, false);
  static const PTag kFalseNegativesEstimateFlag
      //(0024,0045)
      = const PTag._('FalseNegativesEstimateFlag', 0x00240045,
          'False Negatives Estimate Flag', VR.kCS, VM.k1, false);
  static const PTag kFalseNegativesEstimate
      //(0024,0046)
      = const PTag._('FalseNegativesEstimate', 0x00240046, 'False Negatives Estimate',
          VR.kFL, VM.k1, false);
  static const PTag kNegativeCatchTrialsQuantity
      //(0024,0048)
      = const PTag._('NegativeCatchTrialsQuantity', 0x00240048,
          'Negative Catch Trials Quantity', VR.kUS, VM.k1, false);
  static const PTag kFalseNegativesQuantity
      //(0024,0050)
      = const PTag._('FalseNegativesQuantity', 0x00240050, 'False Negatives Quantity',
          VR.kUS, VM.k1, false);
  static const PTag kExcessiveFalseNegativesDataFlag
      //(0024,0051)
      = const PTag._('ExcessiveFalseNegativesDataFlag', 0x00240051,
          'Excessive False Negatives Data Flag', VR.kCS, VM.k1, false);
  static const PTag kExcessiveFalseNegatives
      //(0024,0052)
      = const PTag._('ExcessiveFalseNegatives', 0x00240052, 'Excessive False Negatives',
          VR.kCS, VM.k1, false);
  static const PTag kFalsePositivesEstimateFlag
      //(0024,0053)
      = const PTag._('FalsePositivesEstimateFlag', 0x00240053,
          'False Positives Estimate Flag', VR.kCS, VM.k1, false);
  static const PTag kFalsePositivesEstimate
      //(0024,0054)
      = const PTag._('FalsePositivesEstimate', 0x00240054, 'False Positives Estimate',
          VR.kFL, VM.k1, false);
  static const PTag kCatchTrialsDataFlag
      //(0024,0055)
      = const PTag._('CatchTrialsDataFlag', 0x00240055, 'Catch Trials Data Flag', VR.kCS,
          VM.k1, false);
  static const PTag kPositiveCatchTrialsQuantity
      //(0024,0056)
      = const PTag._('PositiveCatchTrialsQuantity', 0x00240056,
          'Positive Catch Trials Quantity', VR.kUS, VM.k1, false);
  static const PTag kTestPointNormalsDataFlag
      //(0024,0057)
      = const PTag._('TestPointNormalsDataFlag', 0x00240057,
          'Test Point Normals Data Flag', VR.kCS, VM.k1, false);
  static const PTag kTestPointNormalsSequence
      //(0024,0058)
      = const PTag._('TestPointNormalsSequence', 0x00240058,
          'Test Point Normals Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGlobalDeviationProbabilityNormalsFlag
      //(0024,0059)
      = const PTag._('GlobalDeviationProbabilityNormalsFlag', 0x00240059,
          'Global Deviation Probability Normals Flag', VR.kCS, VM.k1, false);
  static const PTag kFalsePositivesQuantity
      //(0024,0060)
      = const PTag._('FalsePositivesQuantity', 0x00240060, 'False Positives Quantity',
          VR.kUS, VM.k1, false);
  static const PTag kExcessiveFalsePositivesDataFlag
      //(0024,0061)
      = const PTag._('ExcessiveFalsePositivesDataFlag', 0x00240061,
          'Excessive False Positives Data Flag', VR.kCS, VM.k1, false);
  static const PTag kExcessiveFalsePositives
      //(0024,0062)
      = const PTag._('ExcessiveFalsePositives', 0x00240062, 'Excessive False Positives',
          VR.kCS, VM.k1, false);
  static const PTag kVisualFieldTestNormalsFlag
      //(0024,0063)
      = const PTag._('VisualFieldTestNormalsFlag', 0x00240063,
          'Visual Field Test Normals Flag', VR.kCS, VM.k1, false);
  static const PTag kResultsNormalsSequence
      //(0024,0064)
      = const PTag._('ResultsNormalsSequence', 0x00240064, 'Results Normals Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kAgeCorrectedSensitivityDeviationAlgorithmSequence
      //(0024,0065)
      = const PTag._('AgeCorrectedSensitivityDeviationAlgorithmSequence', 0x00240065,
          'Age Corrected Sensitivity Deviation Algorithm Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGlobalDeviationFromNormal
      //(0024,0066)
      = const PTag._('GlobalDeviationFromNormal', 0x00240066,
          'Global Deviation From Normal', VR.kFL, VM.k1, false);
  static const PTag kGeneralizedDefectSensitivityDeviationAlgorithmSequence
      //(0024,0067)
      = const PTag._(
          'GeneralizedDefectSensitivityDeviationAlgorithmSequence',
          0x00240067,
          'Generalized Defect Sensitivity Deviation Algorithm Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kLocalizedDeviationFromNormal
      //(0024,0068)
      = const PTag._('LocalizedDeviationFromNormal', 0x00240068,
          'Localized Deviation From Normal', VR.kFL, VM.k1, false);
  static const PTag kPatientReliabilityIndicator
      //(0024,0069)
      = const PTag._('PatientReliabilityIndicator', 0x00240069,
          'Patient Reliability Indicator', VR.kLO, VM.k1, false);
  static const PTag kVisualFieldMeanSensitivity
      //(0024,0070)
      = const PTag._('VisualFieldMeanSensitivity', 0x00240070,
          'Visual Field Mean Sensitivity', VR.kFL, VM.k1, false);
  static const PTag kGlobalDeviationProbability
      //(0024,0071)
      = const PTag._('GlobalDeviationProbability', 0x00240071,
          'Global Deviation Probability', VR.kFL, VM.k1, false);
  static const PTag kLocalDeviationProbabilityNormalsFlag
      //(0024,0072)
      = const PTag._('LocalDeviationProbabilityNormalsFlag', 0x00240072,
          'Local Deviation Probability Normals Flag', VR.kCS, VM.k1, false);
  static const PTag kLocalizedDeviationProbability
      //(0024,0073)
      = const PTag._('LocalizedDeviationProbability', 0x00240073,
          'Localized Deviation Probability', VR.kFL, VM.k1, false);
  static const PTag kShortTermFluctuationCalculated
      //(0024,0074)
      = const PTag._('ShortTermFluctuationCalculated', 0x00240074,
          'Short Term Fluctuation Calculated', VR.kCS, VM.k1, false);
  static const PTag kShortTermFluctuation
      //(0024,0075)
      = const PTag._('ShortTermFluctuation', 0x00240075, 'Short Term Fluctuation', VR.kFL,
          VM.k1, false);
  static const PTag kShortTermFluctuationProbabilityCalculated
      //(0024,0076)
      = const PTag._('ShortTermFluctuationProbabilityCalculated', 0x00240076,
          'Short Term Fluctuation Probability Calculated', VR.kCS, VM.k1, false);
  static const PTag kShortTermFluctuationProbability
      //(0024,0077)
      = const PTag._('ShortTermFluctuationProbability', 0x00240077,
          'Short Term Fluctuation Probability', VR.kFL, VM.k1, false);
  static const PTag kCorrectedLocalizedDeviationFromNormalCalculated
      //(0024,0078)
      = const PTag._('CorrectedLocalizedDeviationFromNormalCalculated', 0x00240078,
          'Corrected Localized Deviation From Normal Calculated', VR.kCS, VM.k1, false);
  static const PTag kCorrectedLocalizedDeviationFromNormal
      //(0024,0079)
      = const PTag._('CorrectedLocalizedDeviationFromNormal', 0x00240079,
          'Corrected Localized Deviation From Normal', VR.kFL, VM.k1, false);
  static const PTag kCorrectedLocalizedDeviationFromNormalProbabilityCalculated
      //(0024,0080)
      = const PTag._(
          'CorrectedLocalizedDeviationFromNormalProbabilityCalculated',
          0x00240080,
          'Corrected Localized Deviation From Normal Probability Calculated',
          VR.kCS,
          VM.k1,
          false);
  static const PTag kCorrectedLocalizedDeviationFromNormalProbability
      //(0024,0081)
      = const PTag._('CorrectedLocalizedDeviationFromNormalProbability', 0x00240081,
          'Corrected Localized Deviation From Normal Probability', VR.kFL, VM.k1, false);
  static const PTag kGlobalDeviationProbabilitySequence
      //(0024,0083)
      = const PTag._('GlobalDeviationProbabilitySequence', 0x00240083,
          'Global Deviation Probability Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLocalizedDeviationProbabilitySequence
      //(0024,0085)
      = const PTag._('LocalizedDeviationProbabilitySequence', 0x00240085,
          'Localized Deviation Probability Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFovealSensitivityMeasured
      //(0024,0086)
      = const PTag._('FovealSensitivityMeasured', 0x00240086,
          'Foveal Sensitivity Measured', VR.kCS, VM.k1, false);
  static const PTag kFovealSensitivity
      //(0024,0087)
      = const PTag._(
          'FovealSensitivity', 0x00240087, 'Foveal Sensitivity', VR.kFL, VM.k1, false);
  static const PTag kVisualFieldTestDuration
      //(0024,0088)
      = const PTag._('VisualFieldTestDuration', 0x00240088, 'Visual Field Test Duration',
          VR.kFL, VM.k1, false);
  static const PTag kVisualFieldTestPointSequence
      //(0024,0089)
      = const PTag._('VisualFieldTestPointSequence', 0x00240089,
          'Visual Field Test Point Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualFieldTestPointXCoordinate
      //(0024,0090)
      = const PTag._('VisualFieldTestPointXCoordinate', 0x00240090,
          'Visual Field Test Point X-Coordinate', VR.kFL, VM.k1, false);
  static const PTag kVisualFieldTestPointYCoordinate
      //(0024,0091)
      = const PTag._('VisualFieldTestPointYCoordinate', 0x00240091,
          'Visual Field Test Point Y-Coordinate', VR.kFL, VM.k1, false);
  static const PTag kAgeCorrectedSensitivityDeviationValue
      //(0024,0092)
      = const PTag._('AgeCorrectedSensitivityDeviationValue', 0x00240092,
          'Age Corrected Sensitivity Deviation Value', VR.kFL, VM.k1, false);
  static const PTag kStimulusResults
      //(0024,0093)
      = const PTag._(
          'StimulusResults', 0x00240093, 'Stimulus Results', VR.kCS, VM.k1, false);
  static const PTag kSensitivityValue
      //(0024,0094)
      = const PTag._(
          'SensitivityValue', 0x00240094, 'Sensitivity Value', VR.kFL, VM.k1, false);
  static const PTag kRetestStimulusSeen
      //(0024,0095)
      = const PTag._(
          'RetestStimulusSeen', 0x00240095, 'Retest Stimulus Seen', VR.kCS, VM.k1, false);
  static const PTag kRetestSensitivityValue
      //(0024,0096)
      = const PTag._('RetestSensitivityValue', 0x00240096, 'Retest Sensitivity Value',
          VR.kFL, VM.k1, false);
  static const PTag kVisualFieldTestPointNormalsSequence
      //(0024,0097)
      = const PTag._('VisualFieldTestPointNormalsSequence', 0x00240097,
          'Visual Field Test Point Normals Sequence', VR.kSQ, VM.k1, false);
  static const PTag kQuantifiedDefect
      //(0024,0098)
      = const PTag._(
          'QuantifiedDefect', 0x00240098, 'Quantified Defect', VR.kFL, VM.k1, false);
  static const PTag kAgeCorrectedSensitivityDeviationProbabilityValue
      //(0024,0100)
      = const PTag._('AgeCorrectedSensitivityDeviationProbabilityValue', 0x00240100,
          'Age Corrected Sensitivity Deviation Probability Value', VR.kFL, VM.k1, false);
  static const PTag kGeneralizedDefectCorrectedSensitivityDeviationFlag
      //(0024,0102)
      = const PTag._(
          'GeneralizedDefectCorrectedSensitivityDeviationFlag',
          0x00240102,
          'Generalized Defect Corrected Sensitivity Deviation Flag',
          VR.kCS,
          VM.k1,
          false);
  static const PTag kGeneralizedDefectCorrectedSensitivityDeviationValue
      //(0024,0103)
      = const PTag._(
          'GeneralizedDefectCorrectedSensitivityDeviationValue',
          0x00240103,
          'Generalized Defect Corrected Sensitivity Deviation Value',
          VR.kFL,
          VM.k1,
          false);
  static const PTag kGeneralizedDefectCorrectedSensitivityDeviationProbabilityValue
      //(0024,0104)
      = const PTag._(
          'GeneralizedDefectCorrectedSensitivityDeviationProbabilityValue',
          0x00240104,
          'Generalized Defect Corrected Sensitivity '
          'Deviation Probability Value',
          VR.kFL,
          VM.k1,
          false);
  static const PTag kMinimumSensitivityValue
      //(0024,0105)
      = const PTag._('MinimumSensitivityValue', 0x00240105, 'Minimum Sensitivity Value',
          VR.kFL, VM.k1, false);
  static const PTag kBlindSpotLocalized
      //(0024,0106)
      = const PTag._(
          'BlindSpotLocalized', 0x00240106, 'Blind Spot Localized', VR.kCS, VM.k1, false);
  static const PTag kBlindSpotXCoordinate
      //(0024,0107)
      = const PTag._('BlindSpotXCoordinate', 0x00240107, 'Blind Spot X-Coordinate',
          VR.kFL, VM.k1, false);
  static const PTag kBlindSpotYCoordinate
      //(0024,0108)
      = const PTag._('BlindSpotYCoordinate', 0x00240108, 'Blind Spot Y-Coordinate',
          VR.kFL, VM.k1, false);
  static const PTag kVisualAcuityMeasurementSequence
      //(0024,0110)
      = const PTag._('VisualAcuityMeasurementSequence', 0x00240110,
          'Visual Acuity Measurement Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRefractiveParametersUsedOnPatientSequence
      //(0024,0112)
      = const PTag._('RefractiveParametersUsedOnPatientSequence', 0x00240112,
          'Refractive Parameters Used on Patient Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMeasurementLaterality
      //(0024,0113)
      = const PTag._('MeasurementLaterality', 0x00240113, 'Measurement Laterality',
          VR.kCS, VM.k1, false);
  static const PTag kOphthalmicPatientClinicalInformationLeftEyeSequence
      //(0024,0114)
      = const PTag._(
          'OphthalmicPatientClinicalInformationLeftEyeSequence',
          0x00240114,
          'Ophthalmic Patient Clinical Information Left Eye Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kOphthalmicPatientClinicalInformationRightEyeSequence
      //(0024,0115)
      = const PTag._(
          'OphthalmicPatientClinicalInformationRightEyeSequence',
          0x00240115,
          'Ophthalmic Patient Clinical Information Right Eye Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kFovealPointNormativeDataFlag
      //(0024,0117)
      = const PTag._('FovealPointNormativeDataFlag', 0x00240117,
          'Foveal Point Normative Data Flag', VR.kCS, VM.k1, false);
  static const PTag kFovealPointProbabilityValue
      //(0024,0118)
      = const PTag._('FovealPointProbabilityValue', 0x00240118,
          'Foveal Point Probability Value', VR.kFL, VM.k1, false);
  static const PTag kScreeningBaselineMeasured
      //(0024,0120)
      = const PTag._('ScreeningBaselineMeasured', 0x00240120,
          'Screening Baseline Measured', VR.kCS, VM.k1, false);
  static const PTag kScreeningBaselineMeasuredSequence
      //(0024,0122)
      = const PTag._('ScreeningBaselineMeasuredSequence', 0x00240122,
          'Screening Baseline Measured Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScreeningBaselineType
      //(0024,0124)
      = const PTag._('ScreeningBaselineType', 0x00240124, 'Screening Baseline Type',
          VR.kCS, VM.k1, false);
  static const PTag kScreeningBaselineValue
      //(0024,0126)
      = const PTag._('ScreeningBaselineValue', 0x00240126, 'Screening Baseline Value',
          VR.kFL, VM.k1, false);
  static const PTag kAlgorithmSource
      //(0024,0202)
      = const PTag._(
          'AlgorithmSource', 0x00240202, 'Algorithm Source', VR.kLO, VM.k1, false);
  static const PTag kDataSetName
      //(0024,0306)
      = const PTag._('DataSetName', 0x00240306, 'Data Set Name', VR.kLO, VM.k1, false);
  static const PTag kDataSetVersion
      //(0024,0307)
      = const PTag._(
          'DataSetVersion', 0x00240307, 'Data Set Version', VR.kLO, VM.k1, false);
  static const PTag kDataSetSource
      //(0024,0308)
      =
      const PTag._('DataSetSource', 0x00240308, 'Data Set Source', VR.kLO, VM.k1, false);
  static const PTag kDataSetDescription
      //(0024,0309)
      = const PTag._(
          'DataSetDescription', 0x00240309, 'Data Set Description', VR.kLO, VM.k1, false);
  static const PTag kVisualFieldTestReliabilityGlobalIndexSequence
      //(0024,0317)
      = const PTag._('VisualFieldTestReliabilityGlobalIndexSequence', 0x00240317,
          'Visual Field Test Reliability Global Index Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualFieldGlobalResultsIndexSequence
      //(0024,0320)
      = const PTag._('VisualFieldGlobalResultsIndexSequence', 0x00240320,
          'Visual Field Global Results Index Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDataObservationSequence
      //(0024,0325)
      = const PTag._('DataObservationSequence', 0x00240325, 'Data Observation Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kIndexNormalsFlag
      //(0024,0338)
      = const PTag._(
          'IndexNormalsFlag', 0x00240338, 'Index Normals Flag', VR.kCS, VM.k1, false);
  static const PTag kIndexProbability
      //(0024,0341)
      = const PTag._(
          'IndexProbability', 0x00240341, 'Index Probability', VR.kFL, VM.k1, false);
  static const PTag kIndexProbabilitySequence
      //(0024,0344)
      = const PTag._('IndexProbabilitySequence', 0x00240344, 'Index Probability Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSamplesPerPixel
      //(0028,0002)
      = const PTag._(
          'SamplesPerPixel', 0x00280002, 'Samples per Pixel', VR.kUS, VM.k1, false);
  static const PTag kSamplesPerPixelUsed
      //(0028,0003)
      = const PTag._('SamplesPerPixelUsed', 0x00280003, 'Samples per Pixel Used', VR.kUS,
          VM.k1, false);
  static const PTag kPhotometricInterpretation
      //(0028,0004)
      = const PTag._('PhotometricInterpretation', 0x00280004,
          'Photometric Interpretation', VR.kCS, VM.k1, false);
  static const PTag kImageDimensions
      //(0028,0005)
      = const PTag._(
          'ImageDimensions', 0x00280005, 'Image Dimensions', VR.kUS, VM.k1, true);
  static const PTag kPlanarConfiguration
      //(0028,0006)
      = const PTag._('PlanarConfiguration', 0x00280006, 'Planar Configuration', VR.kUS,
          VM.k1, false);
  static const PTag kNumberOfFrames
      //(0028,0008)
      = const PTag._(
          'NumberOfFrames', 0x00280008, 'Number of Frames', VR.kIS, VM.k1, false);
  static const PTag kFrameIncrementPointer
      //(0028,0009)
      = const PTag._('FrameIncrementPointer', 0x00280009, 'Frame Increment Pointer',
          VR.kAT, VM.k1_n, false);
  static const PTag kFrameDimensionPointer
      //(0028,000A)
      = const PTag._('FrameDimensionPointer', 0x0028000A, 'Frame Dimension Pointer',
          VR.kAT, VM.k1_n, false);
  static const PTag kRows
      //(0028,0010)
      = const PTag._('Rows', 0x00280010, 'Rows', VR.kUS, VM.k1, false);
  static const PTag kColumns
      //(0028,0011)
      = const PTag._('Columns', 0x00280011, 'Columns', VR.kUS, VM.k1, false);
  static const PTag kPlanes
      //(0028,0012)
      = const PTag._('Planes', 0x00280012, 'Planes', VR.kUS, VM.k1, true);
  static const PTag kUltrasoundColorDataPresent
      //(0028,0014)
      = const PTag._('UltrasoundColorDataPresent', 0x00280014,
          'Ultrasound Color Data Present', VR.kUS, VM.k1, false);
  static const PTag kNoName1
      //(0028,0020)
      = const PTag._('NoName1', 0x00280020, 'See Note 3', VR.kUN, VM.kNoVM, true);
  static const PTag kPixelSpacing
      //(0028,0030)
      = const PTag._('PixelSpacing', 0x00280030, 'Pixel Spacing', VR.kDS, VM.k2, false);
  static const PTag kZoomFactor
      //(0028,0031)
      = const PTag._('ZoomFactor', 0x00280031, 'Zoom Factor', VR.kDS, VM.k2, false);
  static const PTag kZoomCenter
      //(0028,0032)
      = const PTag._('ZoomCenter', 0x00280032, 'Zoom Center', VR.kDS, VM.k2, false);
  static const PTag kPixelAspectRatio
      //(0028,0034)
      = const PTag._(
          'PixelAspectRatio', 0x00280034, 'Pixel Aspect Ratio', VR.kIS, VM.k2, false);
  static const PTag kImageFormat
      //(0028,0040)
      = const PTag._('ImageFormat', 0x00280040, 'Image Format', VR.kCS, VM.k1, true);
  static const PTag kManipulatedImage
      //(0028,0050)
      = const PTag._(
          'ManipulatedImage', 0x00280050, 'Manipulated Image', VR.kLO, VM.k1_n, true);
  static const PTag kCorrectedImage
      //(0028,0051)
      = const PTag._(
          'CorrectedImage', 0x00280051, 'Corrected Image', VR.kCS, VM.k1_n, false);
  static const PTag kCompressionRecognitionCode
      //(0028,005F)
      = const PTag._('CompressionRecognitionCode', 0x0028005F,
          'Compression Recognition Code', VR.kLO, VM.k1, true);
  static const PTag kCompressionCode
      //(0028,0060)
      = const PTag._(
          'CompressionCode', 0x00280060, 'Compression Code', VR.kCS, VM.k1, true);
  static const PTag kCompressionOriginator
      //(0028,0061)
      = const PTag._('CompressionOriginator', 0x00280061, 'Compression Originator',
          VR.kSH, VM.k1, true);
  static const PTag kCompressionLabel
      //(0028,0062)
      = const PTag._(
          'CompressionLabel', 0x00280062, 'Compression Label', VR.kLO, VM.k1, true);
  static const PTag kCompressionDescription
      //(0028,0063)
      = const PTag._('CompressionDescription', 0x00280063, 'Compression Description',
          VR.kSH, VM.k1, true);
  static const PTag kCompressionSequence
      //(0028,0065)
      = const PTag._('CompressionSequence', 0x00280065, 'Compression Sequence', VR.kCS,
          VM.k1_n, true);
  static const PTag kCompressionStepPointers
      //(0028,0066)
      = const PTag._('CompressionStepPointers', 0x00280066, 'Compression Step Pointers',
          VR.kAT, VM.k1_n, true);
  static const PTag kRepeatInterval
      //(0028,0068)
      =
      const PTag._('RepeatInterval', 0x00280068, 'Repeat Interval', VR.kUS, VM.k1, true);
  static const PTag kBitsGrouped
      //(0028,0069)
      = const PTag._('BitsGrouped', 0x00280069, 'Bits Grouped', VR.kUS, VM.k1, true);
  static const PTag kPerimeterTable
      //(0028,0070)
      = const PTag._(
          'PerimeterTable', 0x00280070, 'Perimeter Table', VR.kUS, VM.k1_n, true);
  static const PTag kPerimeterValue
      //(0028,0071)
      = const PTag._(
          'PerimeterValue', 0x00280071, 'Perimeter Value', VR.kUSSS, VM.k1, true);
  static const PTag kPredictorRows
      //(0028,0080)
      = const PTag._('PredictorRows', 0x00280080, 'Predictor Rows', VR.kUS, VM.k1, true);
  static const PTag kPredictorColumns
      //(0028,0081)
      = const PTag._(
          'PredictorColumns', 0x00280081, 'Predictor Columns', VR.kUS, VM.k1, true);
  static const PTag kPredictorConstants
      //(0028,0082)
      = const PTag._(
          'PredictorConstants', 0x00280082, 'Predictor Constants', VR.kUS, VM.k1_n, true);
  static const PTag kBlockedPixels
      //(0028,0090)
      = const PTag._('BlockedPixels', 0x00280090, 'Blocked Pixels', VR.kCS, VM.k1, true);
  static const PTag kBlockRows
      //(0028,0091)
      = const PTag._('BlockRows', 0x00280091, 'Block Rows', VR.kUS, VM.k1, true);
  static const PTag kBlockColumns
      //(0028,0092)
      = const PTag._('BlockColumns', 0x00280092, 'Block Columns', VR.kUS, VM.k1, true);
  static const PTag kRowOverlap
      //(0028,0093)
      = const PTag._('RowOverlap', 0x00280093, 'Row Overlap', VR.kUS, VM.k1, true);
  static const PTag kColumnOverlap
      //(0028,0094)
      = const PTag._('ColumnOverlap', 0x00280094, 'Column Overlap', VR.kUS, VM.k1, true);
  static const PTag kBitsAllocated
      //(0028,0100)
      = const PTag._('BitsAllocated', 0x00280100, 'Bits Allocated', VR.kUS, VM.k1, false);
  static const PTag kBitsStored
      //(0028,0101)
      = const PTag._('BitsStored', 0x00280101, 'Bits Stored', VR.kUS, VM.k1, false);
  static const PTag kHighBit
      //(0028,0102)
      = const PTag._('HighBit', 0x00280102, 'High Bit', VR.kUS, VM.k1, false);
  static const PTag kPixelRepresentation
      //(0028,0103)
      = const PTag._('PixelRepresentation', 0x00280103, 'Pixel Representation', VR.kUS,
          VM.k1, false);
  static const PTag kSmallestValidPixelValue
      //(0028,0104)
      = const PTag._('SmallestValidPixelValue', 0x00280104, 'Smallest Valid Pixel Value',
          VR.kUSSS, VM.k1, true);
  static const PTag kLargestValidPixelValue
      //(0028,0105)
      = const PTag._('LargestValidPixelValue', 0x00280105, 'Largest Valid Pixel Value',
          VR.kUSSS, VM.k1, true);
  static const PTag kSmallestImagePixelValue
      //(0028,0106)
      = const PTag._('SmallestImagePixelValue', 0x00280106, 'Smallest Image Pixel Value',
          VR.kUSSS, VM.k1, false);
  static const PTag kLargestImagePixelValue
      //(0028,0107)
      = const PTag._('LargestImagePixelValue', 0x00280107, 'Largest Image Pixel Value',
          VR.kUSSS, VM.k1, false);
  static const PTag kSmallestPixelValueInSeries
      //(0028,0108)
      = const PTag._('SmallestPixelValueInSeries', 0x00280108,
          'Smallest Pixel Value in Series', VR.kUSSS, VM.k1, false);
  static const PTag kLargestPixelValueInSeries
      //(0028,0109)
      = const PTag._('LargestPixelValueInSeries', 0x00280109,
          'Largest Pixel Value in Series', VR.kUSSS, VM.k1, false);
  static const PTag kSmallestImagePixelValueInPlane
      //(0028,0110)
      = const PTag._('SmallestImagePixelValueInPlane', 0x00280110,
          'Smallest Image Pixel Value in Plane', VR.kUSSS, VM.k1, true);
  static const PTag kLargestImagePixelValueInPlane
      //(0028,0111)
      = const PTag._('LargestImagePixelValueInPlane', 0x00280111,
          'Largest Image Pixel Value in Plane', VR.kUSSS, VM.k1, true);
  static const PTag kPixelPaddingValue
      //(0028,0120)
      = const PTag._(
          'PixelPaddingValue', 0x00280120, 'Pixel Padding Value', VR.kUSSS, VM.k1, false);
  static const PTag kPixelPaddingRangeLimit
      //(0028,0121)
      = const PTag._('PixelPaddingRangeLimit', 0x00280121, 'Pixel Padding Range Limit',
          VR.kUSSS, VM.k1, false);
  static const PTag kImageLocation
      //(0028,0200)
      = const PTag._('ImageLocation', 0x00280200, 'Image Location', VR.kUS, VM.k1, true);
  static const PTag kQualityControlImage
      //(0028,0300)
      = const PTag._('QualityControlImage', 0x00280300, 'Quality Control Image', VR.kCS,
          VM.k1, false);
  static const PTag kBurnedInAnnotation
      //(0028,0301)
      = const PTag._(
          'BurnedInAnnotation', 0x00280301, 'Burned In Annotation', VR.kCS, VM.k1, false);
  static const PTag kRecognizableVisualFeatures
      //(0028,0302)
      = const PTag._('RecognizableVisualFeatures', 0x00280302,
          'Recognizable Visual Features', VR.kCS, VM.k1, false);
  static const PTag kLongitudinalTemporalInformationModified
      //(0028,0303)
      = const PTag._('LongitudinalTemporalInformationModified', 0x00280303,
          'Longitudinal Temporal Information Modified', VR.kCS, VM.k1, false);
  static const PTag kReferencedColorPaletteInstanceUID
      //(0028,0304)
      = const PTag._('ReferencedColorPaletteInstanceUID', 0x00280304,
          'Referenced Color Palette Instance UID', VR.kUI, VM.k1, false);
  static const PTag kTransformLabel
      //(0028,0400)
      =
      const PTag._('TransformLabel', 0x00280400, 'Transform Label', VR.kLO, VM.k1, true);
  static const PTag kTransformVersionNumber
      //(0028,0401)
      = const PTag._('TransformVersionNumber', 0x00280401, 'Transform Version Number',
          VR.kLO, VM.k1, true);
  static const PTag kNumberOfTransformSteps
      //(0028,0402)
      = const PTag._('NumberOfTransformSteps', 0x00280402, 'Number of Transform Steps',
          VR.kUS, VM.k1, true);
  static const PTag kSequenceOfCompressedData
      //(0028,0403)
      = const PTag._('SequenceOfCompressedData', 0x00280403,
          'Sequence of Compressed Data', VR.kLO, VM.k1_n, true);
  static const PTag kDetailsOfCoefficients
      //(0028,0404)
      = const PTag._('DetailsOfCoefficients', 0x00280404, 'Details of Coefficients',
          VR.kAT, VM.k1_n, true);

  // *** See below ***
  //static const Tag Element kRowsForNthOrderCoefficients
  //(0028,0400)
  //= const Element('RowsForNthOrderCoefficients', 0x00280400,
  //    'Rows For Nth Order Coefficients',
  //VR.kUS, VM.k1, true);
  // *** See below ***
  //static const Tag Element kColumnsForNthOrderCoefficients
  //(0028,0401)
  //= const Element('ColumnsForNthOrderCoefficients', 0x00280401,
  //    'Columns For Nth Order
  //Coefficients', VR.kUS, VM.k1, true);
  //static const Tag Element kCoefficientCoding
  //(0028,0402)
  //= const Element('CoefficientCoding', 0x00280402, 'Coefficient Coding',
  //    VR.kLO, VM.k1_n, true);
  //static const Tag Element kCoefficientCodingPointers
  //(0028,0403)
  //= const Element('CoefficientCodingPointers', 0x00280403,
  //    'Coefficient Coding Pointers', VR
  //    .kAT, VM.k1_n, true);
  static const PTag kDCTLabel
      //(0028,0700)
      = const PTag._('DCTLabel', 0x00280700, 'DCT Label', VR.kLO, VM.k1, true);
  static const PTag kDataBlockDescription
      //(0028,0701)
      = const PTag._('DataBlockDescription', 0x00280701, 'Data Block Description', VR.kCS,
          VM.k1_n, true);
  static const PTag kDataBlock
      //(0028,0702)
      = const PTag._('DataBlock', 0x00280702, 'Data Block', VR.kAT, VM.k1_n, true);
  static const PTag kNormalizationFactorFormat
      //(0028,0710)
      = const PTag._('NormalizationFactorFormat', 0x00280710,
          'Normalization Factor Format', VR.kUS, VM.k1, true);
  static const PTag kZonalMapNumberFormat
      //(0028,0720)
      = const PTag._('ZonalMapNumberFormat', 0x00280720, 'Zonal Map Number Format',
          VR.kUS, VM.k1, true);
  static const PTag kZonalMapLocation
      //(0028,0721)
      = const PTag._(
          'ZonalMapLocation', 0x00280721, 'Zonal Map Location', VR.kAT, VM.k1_n, true);
  static const PTag kZonalMapFormat
      //(0028,0722)
      =
      const PTag._('ZonalMapFormat', 0x00280722, 'Zonal Map Format', VR.kUS, VM.k1, true);
  static const PTag kAdaptiveMapFormat
      //(0028,0730)
      = const PTag._(
          'AdaptiveMapFormat', 0x00280730, 'Adaptive Map Format', VR.kUS, VM.k1, true);
  static const PTag kCodeNumberFormat
      //(0028,0740)
      = const PTag._(
          'CodeNumberFormat', 0x00280740, 'Code Number Format', VR.kUS, VM.k1, true);
  static const PTag kCodeLabel
      //(0028,0800)
      = const PTag._('CodeLabel', 0x00280800, 'Code Label', VR.kCS, VM.k1_n, true);
  static const PTag kNumberOfTables
      //(0028,0802)
      =
      const PTag._('NumberOfTables', 0x00280802, 'Number of Tables', VR.kUS, VM.k1, true);
  static const PTag kCodeTableLocation
      //(0028,0803)
      = const PTag._(
          'CodeTableLocation', 0x00280803, 'Code Table Location', VR.kAT, VM.k1_n, true);
  static const PTag kBitsForCodeWord
      //(0028,0804)
      = const PTag._(
          'BitsForCodeWord', 0x00280804, 'Bits For Code Word', VR.kUS, VM.k1, true);
  static const PTag kImageDataLocation
      //(0028,0808)
      = const PTag._(
          'ImageDataLocation', 0x00280808, 'Image Data Location', VR.kAT, VM.k1_n, true);
  static const PTag kPixelSpacingCalibrationType
      //(0028,0A02)
      = const PTag._('PixelSpacingCalibrationType', 0x00280A02,
          'Pixel Spacing Calibration Type', VR.kCS, VM.k1, false);
  static const PTag kPixelSpacingCalibrationDescription
      //(0028,0A04)
      = const PTag._('PixelSpacingCalibrationDescription', 0x00280A04,
          'Pixel Spacing Calibration Description', VR.kLO, VM.k1, false);
  static const PTag kPixelIntensityRelationship
      //(0028,1040)
      = const PTag._('PixelIntensityRelationship', 0x00281040,
          'Pixel Intensity Relationship', VR.kCS, VM.k1, false);
  static const PTag kPixelIntensityRelationshipSign
      //(0028,1041)
      = const PTag._('PixelIntensityRelationshipSign', 0x00281041,
          'Pixel Intensity Relationship Sign', VR.kSS, VM.k1, false);
  static const PTag kWindowCenter
      //(0028,1050)
      = const PTag._('WindowCenter', 0x00281050, 'Window Center', VR.kDS, VM.k1_n, false);
  static const PTag kWindowWidth
      //(0028,1051)
      = const PTag._('WindowWidth', 0x00281051, 'Window Width', VR.kDS, VM.k1_n, false);
  static const PTag kRescaleIntercept
      //(0028,1052)
      = const PTag._(
          'RescaleIntercept', 0x00281052, 'Rescale Intercept', VR.kDS, VM.k1, false);
  static const PTag kRescaleSlope
      //(0028,1053)
      = const PTag._('RescaleSlope', 0x00281053, 'Rescale Slope', VR.kDS, VM.k1, false);
  static const PTag kRescaleType
      //(0028,1054)
      = const PTag._('RescaleType', 0x00281054, 'Rescale Type', VR.kLO, VM.k1, false);
  static const PTag kWindowCenterWidthExplanation
      //(0028,1055)
      = const PTag._('WindowCenterWidthExplanation', 0x00281055,
          'Window Center & Width Explanation', VR.kLO, VM.k1_n, false);
  static const PTag kVOILUTFunction
      //(0028,1056)
      = const PTag._(
          'VOILUTFunction', 0x00281056, 'VOI LUT Function', VR.kCS, VM.k1, false);
  static const PTag kGrayScale
      //(0028,1080)
      = const PTag._('GrayScale', 0x00281080, 'Gray Scale', VR.kCS, VM.k1, true);
  static const PTag kRecommendedViewingMode
      //(0028,1090)
      = const PTag._('RecommendedViewingMode', 0x00281090, 'Recommended Viewing Mode',
          VR.kCS, VM.k1, false);
  static const PTag kGrayLookupTableDescriptor
      //(0028,1100)
      = const PTag._('GrayLookupTableDescriptor', 0x00281100,
          'Gray Lookup Table Descriptor', VR.kUSSS, VM.k3, true);
  static const PTag kRedPaletteColorLookupTableDescriptor
      //(0028,1101)
      = const PTag._('RedPaletteColorLookupTableDescriptor', 0x00281101,
          'Red Palette Color Lookup Table Descriptor', VR.kUSSS, VM.k3, false);
  static const PTag kGreenPaletteColorLookupTableDescriptor
      //(0028,1102)
      = const PTag._('GreenPaletteColorLookupTableDescriptor', 0x00281102,
          'Green Palette Color Lookup Table Descriptor', VR.kUSSS, VM.k3, false);
  static const PTag kBluePaletteColorLookupTableDescriptor
      //(0028,1103)
      = const PTag._('BluePaletteColorLookupTableDescriptor', 0x00281103,
          'Blue Palette Color Lookup Table Descriptor', VR.kUSSS, VM.k3, false);
  static const PTag kAlphaPaletteColorLookupTableDescriptor
      //(0028,1104)
      = const PTag._('AlphaPaletteColorLookupTableDescriptor', 0x00281104,
          'AlphaPalette ColorLookup Table Descriptor', VR.kUS, VM.k3, false);
  static const PTag kLargeRedPaletteColorLookupTableDescriptor
      //(0028,1111)
      = const PTag._('LargeRedPaletteColorLookupTableDescriptor', 0x00281111,
          'Large Red Palette Color Lookup Table Descriptor', VR.kUSSS, VM.k4, true);
  static const PTag kLargeGreenPaletteColorLookupTableDescriptor
      //(0028,1112)
      = const PTag._('LargeGreenPaletteColorLookupTableDescriptor', 0x00281112,
          'Large Green Palette Color Lookup Table Descriptor', VR.kUSSS, VM.k4, true);
  static const PTag kLargeBluePaletteColorLookupTableDescriptor
      //(0028,1113)
      = const PTag._('LargeBluePaletteColorLookupTableDescriptor', 0x00281113,
          'Large Blue Palette Color Lookup Table Descriptor', VR.kUSSS, VM.k4, true);
  static const PTag kPaletteColorLookupTableUID
      //(0028,1199)
      = const PTag._('PaletteColorLookupTableUID', 0x00281199,
          'Palette Color Lookup Table UID', VR.kUI, VM.k1, false);
  static const PTag kGrayLookupTableData
      //(0028,1200)
      = const PTag._('GrayLookupTableData', 0x00281200, 'Gray Lookup Table Data',
          VR.kUSSSOW, VM.k1_n, true);
  static const PTag kRedPaletteColorLookupTableData
      //(0028,1201)
      = const PTag._('RedPaletteColorLookupTableData', 0x00281201,
          'Red Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kGreenPaletteColorLookupTableData
      //(0028,1202)
      = const PTag._('GreenPaletteColorLookupTableData', 0x00281202,
          'Green Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kBluePaletteColorLookupTableData
      //(0028,1203)
      = const PTag._('BluePaletteColorLookupTableData', 0x00281203,
          'Blue Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kAlphaPaletteColorLookupTableData
      //(0028,1204)
      = const PTag._('AlphaPaletteColorLookupTableData', 0x00281204,
          'Alpha Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kLargeRedPaletteColorLookupTableData
      //(0028,1211)
      = const PTag._('LargeRedPaletteColorLookupTableData', 0x00281211,
          'Large Red Palette Color Lookup Table Data', VR.kOW, VM.k1, true);
  static const PTag kLargeGreenPaletteColorLookupTableData
      //(0028,1212)
      = const PTag._('LargeGreenPaletteColorLookupTableData', 0x00281212,
          'Large Green Palette Color Lookup Table Data', VR.kOW, VM.k1, true);
  static const PTag kLargeBluePaletteColorLookupTableData
      //(0028,1213)
      = const PTag._('LargeBluePaletteColorLookupTableData', 0x00281213,
          'Large Blue Palette Color Lookup Table Data', VR.kOW, VM.k1, true);
  static const PTag kLargePaletteColorLookupTableUID
      //(0028,1214)
      = const PTag._('LargePaletteColorLookupTableUID', 0x00281214,
          'Large Palette Color Lookup Table UID', VR.kUI, VM.k1, true);
  static const PTag kSegmentedRedPaletteColorLookupTableData
      //(0028,1221)
      = const PTag._('SegmentedRedPaletteColorLookupTableData', 0x00281221,
          'Segmented Red Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kSegmentedGreenPaletteColorLookupTableData
      //(0028,1222)
      = const PTag._('SegmentedGreenPaletteColorLookupTableData', 0x00281222,
          'Segmented Green Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kSegmentedBluePaletteColorLookupTableData
      //(0028,1223)
      = const PTag._('SegmentedBluePaletteColorLookupTableData', 0x00281223,
          'Segmented Blue Palette Color Lookup Table Data', VR.kOW, VM.k1, false);
  static const PTag kBreastImplantPresent
      //(0028,1300)
      = const PTag._('BreastImplantPresent', 0x00281300, 'Breast Implant Present', VR.kCS,
          VM.k1, false);
  static const PTag kPartialView
      //(0028,1350)
      = const PTag._('PartialView', 0x00281350, 'Partial View', VR.kCS, VM.k1, false);
  static const PTag kPartialViewDescription
      //(0028,1351)
      = const PTag._('PartialViewDescription', 0x00281351, 'Partial View Description',
          VR.kST, VM.k1, false);
  static const PTag kPartialViewCodeSequence
      //(0028,1352)
      = const PTag._('PartialViewCodeSequence', 0x00281352, 'Partial View Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSpatialLocationsPreserved
      //(0028,135A)
      = const PTag._('SpatialLocationsPreserved', 0x0028135A,
          'Spatial Locations Preserved', VR.kCS, VM.k1, false);
  static const PTag kDataFrameAssignmentSequence
      //(0028,1401)
      = const PTag._('DataFrameAssignmentSequence', 0x00281401,
          'Data Frame Assignment Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDataPathAssignment
      //(0028,1402)
      = const PTag._(
          'DataPathAssignment', 0x00281402, 'Data Path Assignment', VR.kCS, VM.k1, false);
  static const PTag kBitsMappedToColorLookupTable
      //(0028,1403)
      = const PTag._('BitsMappedToColorLookupTable', 0x00281403,
          'Bits Mapped to Color Lookup Table', VR.kUS, VM.k1, false);
  static const PTag kBlendingLUT1Sequence
      //(0028,1404)
      = const PTag._('BlendingLUT1Sequence', 0x00281404, 'Blending LUT 1 Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kBlendingLUT1TransferFunction
      //(0028,1405)
      = const PTag._('BlendingLUT1TransferFunction', 0x00281405,
          'Blending LUT 1 Transfer Function', VR.kCS, VM.k1, false);
  static const PTag kBlendingWeightConstant
      //(0028,1406)
      = const PTag._('BlendingWeightConstant', 0x00281406, 'Blending Weight Constant',
          VR.kFD, VM.k1, false);
  static const PTag kBlendingLookupTableDescriptor
      //(0028,1407)
      = const PTag._('BlendingLookupTableDescriptor', 0x00281407,
          'Blending Lookup Table Descriptor', VR.kUS, VM.k3, false);
  static const PTag kBlendingLookupTableData
      //(0028,1408)
      = const PTag._('BlendingLookupTableData', 0x00281408, 'Blending Lookup Table Data',
          VR.kOW, VM.k1, false);
  static const PTag kEnhancedPaletteColorLookupTableSequence
      //(0028,140B)
      = const PTag._('EnhancedPaletteColorLookupTableSequence', 0x0028140B,
          'Enhanced Palette Color Lookup Table Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBlendingLUT2Sequence
      //(0028,140C)
      = const PTag._('BlendingLUT2Sequence', 0x0028140C, 'Blending LUT 2 Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kBlendingLUT2TransferFunction
      //(0028,140D)
      = const PTag._('BlendingLUT2TransferFunction', 0x0028140D,
          'Blending LUT 2 Transfer Function', VR.kCS, VM.k1, false);
  static const PTag kDataPathID
      //(0028,140E)
      = const PTag._('DataPathID', 0x0028140E, 'Data Path ID', VR.kCS, VM.k1, false);
  static const PTag kRGBLUTTransferFunction
      //(0028,140F)
      = const PTag._('RGBLUTTransferFunction', 0x0028140F, 'RGB LUT Transfer Function',
          VR.kCS, VM.k1, false);
  static const PTag kAlphaLUTTransferFunction
      //(0028,1410)
      = const PTag._('AlphaLUTTransferFunction', 0x00281410,
          'Alpha LUT Transfer Function', VR.kCS, VM.k1, false);
  static const PTag kICCProfile
      //(0028,2000)
      = const PTag._('ICCProfile', 0x00282000, 'ICC Profile', VR.kOB, VM.k1, false);
  static const PTag kColorSpace
      //(0028,2000)
      = const PTag._('ColorSpace', 0x00282002, 'Color Space', VR.kCS, VM.k1, false);
  static const PTag kLossyImageCompression
      //(0028,2110)
      = const PTag._('LossyImageCompression', 0x00282110, 'Lossy Image Compression',
          VR.kCS, VM.k1, false);
  static const PTag kLossyImageCompressionRatio
      //(0028,2112)
      = const PTag._('LossyImageCompressionRatio', 0x00282112,
          'Lossy Image Compression Ratio', VR.kDS, VM.k1_n, false);
  static const PTag kLossyImageCompressionMethod
      //(0028,2114)
      = const PTag._('LossyImageCompressionMethod', 0x00282114,
          'Lossy Image Compression Method', VR.kCS, VM.k1_n, false);
  static const PTag kModalityLUTSequence
      //(0028,3000)
      = const PTag._('ModalityLUTSequence', 0x00283000, 'Modality LUT Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kLUTDescriptor
      //(0028,3002)
      =
      const PTag._('LUTDescriptor', 0x00283002, 'LUT Descriptor', VR.kUSSS, VM.k3, false);
  static const PTag kLUTExplanation
      //(0028,3003)
      =
      const PTag._('LUTExplanation', 0x00283003, 'LUT Explanation', VR.kLO, VM.k1, false);
  static const PTag kModalityLUTType
      //(0028,3004)
      = const PTag._(
          'ModalityLUTType', 0x00283004, 'Modality LUT Type', VR.kLO, VM.k1, false);
  static const PTag kLUTData
      //(0028,3006)
      = const PTag._('LUTData', 0x00283006, 'LUT Data', VR.kUSOW, VM.k1_n, false);
  static const PTag kVOILUTSequence
      //(0028,3010)
      = const PTag._(
          'VOILUTSequence', 0x00283010, 'VOI LUT Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSoftcopyVOILUTSequence
      //(0028,3110)
      = const PTag._('SoftcopyVOILUTSequence', 0x00283110, 'Softcopy VOI LUT Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kImagePresentationComments
      //(0028,4000)
      = const PTag._('ImagePresentationComments', 0x00284000,
          'Image Presentation Comments', VR.kLT, VM.k1, true);
  static const PTag kBiPlaneAcquisitionSequence
      //(0028,5000)
      = const PTag._('BiPlaneAcquisitionSequence', 0x00285000,
          'Bi-Plane Acquisition Sequence', VR.kSQ, VM.k1, true);
  static const PTag kRepresentativeFrameNumber
      //(0028,6010)
      = const PTag._('RepresentativeFrameNumber', 0x00286010,
          'Representative Frame Number', VR.kUS, VM.k1, false);
  static const PTag kFrameNumbersOfInterest
      //(0028,6020)
      = const PTag._('FrameNumbersOfInterest', 0x00286020,
          'Frame Numbers of Interest (FOI)', VR.kUS, VM.k1_n, false);
  static const PTag kFrameOfInterestDescription
      //(0028,6022)
      = const PTag._('FrameOfInterestDescription', 0x00286022,
          'Frame of Interest Description', VR.kLO, VM.k1_n, false);
  static const PTag kFrameOfInterestType
      //(0028,6023)
      = const PTag._('FrameOfInterestType', 0x00286023, 'Frame of Interest Type', VR.kCS,
          VM.k1_n, false);
  static const PTag kMaskPointers
      //(0028,6030)
      =
      const PTag._('MaskPointers', 0x00286030, 'Mask Pointer(s)', VR.kUS, VM.k1_n, true);
  static const PTag kRWavePointer
      //(0028,6040)
      =
      const PTag._('RWavePointer', 0x00286040, 'R Wave Pointer', VR.kUS, VM.k1_n, false);
  static const PTag kMaskSubtractionSequence
      //(0028,6100)
      = const PTag._('MaskSubtractionSequence', 0x00286100, 'Mask Subtraction Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kMaskOperation
      //(0028,6101)
      = const PTag._('MaskOperation', 0x00286101, 'Mask Operation', VR.kCS, VM.k1, false);
  static const PTag kApplicableFrameRange
      //(0028,6102)
      = const PTag._('ApplicableFrameRange', 0x00286102, 'Applicable Frame Range', VR.kUS,
          VM.k2_2n, false);
  static const PTag kMaskFrameNumbers
      //(0028,6110)
      = const PTag._(
          'MaskFrameNumbers', 0x00286110, 'Mask Frame Numbers', VR.kUS, VM.k1_n, false);
  static const PTag kContrastFrameAveraging
      //(0028,6112)
      = const PTag._('ContrastFrameAveraging', 0x00286112, 'Contrast Frame Averaging',
          VR.kUS, VM.k1, false);
  static const PTag kMaskSubPixelShift
      //(0028,6114)
      = const PTag._(
          'MaskSubPixelShift', 0x00286114, 'Mask Sub-pixel Shift', VR.kFL, VM.k2, false);
  static const PTag kTIDOffset
      //(0028,6120)
      = const PTag._('TIDOffset', 0x00286120, 'TID Offset', VR.kSS, VM.k1, false);
  static const PTag kMaskOperationExplanation
      //(0028,6190)
      = const PTag._('MaskOperationExplanation', 0x00286190, 'Mask Operation Explanation',
          VR.kST, VM.k1, false);
  static const PTag kPixelDataProviderURL
      //(0028,7FE0)
      = const PTag._('PixelDataProviderURL', 0x00287FE0, 'Pixel Data Provider URL',
          VR.kUR, VM.k1, false);
  static const PTag kDataPointRows
      //(0028,9001)
      =
      const PTag._('DataPointRows', 0x00289001, 'Data Point Rows', VR.kUL, VM.k1, false);
  static const PTag kDataPointColumns
      //(0028,9002)
      = const PTag._(
          'DataPointColumns', 0x00289002, 'Data Point Columns', VR.kUL, VM.k1, false);
  static const PTag kSignalDomainColumns
      //(0028,9003)
      = const PTag._('SignalDomainColumns', 0x00289003, 'Signal Domain Columns', VR.kCS,
          VM.k1, false);
  static const PTag kLargestMonochromePixelValue
      //(0028,9099)
      = const PTag._('LargestMonochromePixelValue', 0x00289099,
          'Largest Monochrome Pixel Value', VR.kUS, VM.k1, true);
  static const PTag kDataRepresentation
      //(0028,9108)
      = const PTag._(
          'DataRepresentation', 0x00289108, 'Data Representation', VR.kCS, VM.k1, false);
  static const PTag kPixelMeasuresSequence
      //(0028,9110)
      = const PTag._('PixelMeasuresSequence', 0x00289110, 'Pixel Measures Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kFrameVOILUTSequence
      //(0028,9132)
      = const PTag._('FrameVOILUTSequence', 0x00289132, 'Frame VOI LUT Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kPixelValueTransformationSequence
      //(0028,9145)
      = const PTag._('PixelValueTransformationSequence', 0x00289145,
          'Pixel Value Transformation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSignalDomainRows
      //(0028,9235)
      = const PTag._(
          'SignalDomainRows', 0x00289235, 'Signal Domain Rows', VR.kCS, VM.k1, false);
  static const PTag kDisplayFilterPercentage
      //(0028,9411)
      = const PTag._('DisplayFilterPercentage', 0x00289411, 'Display Filter Percentage',
          VR.kFL, VM.k1, false);
  static const PTag kFramePixelShiftSequence
      //(0028,9415)
      = const PTag._('FramePixelShiftSequence', 0x00289415, 'Frame Pixel Shift Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSubtractionItemID
      //(0028,9416)
      = const PTag._(
          'SubtractionItemID', 0x00289416, 'Subtraction Item ID', VR.kUS, VM.k1, false);
  static const PTag kPixelIntensityRelationshipLUTSequence
      //(0028,9422)
      = const PTag._('PixelIntensityRelationshipLUTSequence', 0x00289422,
          'Pixel Intensity Relationship LUT Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFramePixelDataPropertiesSequence
      //(0028,9443)
      = const PTag._('FramePixelDataPropertiesSequence', 0x00289443,
          'Frame Pixel Data Properties Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGeometricalProperties
      //(0028,9444)
      = const PTag._('GeometricalProperties', 0x00289444, 'Geometrical Properties',
          VR.kCS, VM.k1, false);
  static const PTag kGeometricMaximumDistortion
      //(0028,9445)
      = const PTag._('GeometricMaximumDistortion', 0x00289445,
          'Geometric Maximum Distortion', VR.kFL, VM.k1, false);
  static const PTag kImageProcessingApplied
      //(0028,9446)
      = const PTag._('ImageProcessingApplied', 0x00289446, 'Image Processing Applied',
          VR.kCS, VM.k1_n, false);
  static const PTag kMaskSelectionMode
      //(0028,9454)
      = const PTag._(
          'MaskSelectionMode', 0x00289454, 'Mask Selection Mode', VR.kCS, VM.k1, false);
  static const PTag kLUTFunction
      //(0028,9474)
      = const PTag._('LUTFunction', 0x00289474, 'LUT Function', VR.kCS, VM.k1, false);
  static const PTag kMaskVisibilityPercentage
      //(0028,9478)
      = const PTag._('MaskVisibilityPercentage', 0x00289478, 'Mask Visibility Percentage',
          VR.kFL, VM.k1, false);
  static const PTag kPixelShiftSequence
      //(0028,9501)
      = const PTag._(
          'PixelShiftSequence', 0x00289501, 'Pixel Shift Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRegionPixelShiftSequence
      //(0028,9502)
      = const PTag._('RegionPixelShiftSequence', 0x00289502,
          'Region Pixel Shift Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVerticesOfTheRegion
      //(0028,9503)
      = const PTag._('VerticesOfTheRegion', 0x00289503, 'Vertices of the Region', VR.kSS,
          VM.k2_2n, false);
  static const PTag kMultiFramePresentationSequence
      //(0028,9505)
      = const PTag._('MultiFramePresentationSequence', 0x00289505,
          'Multi-frame Presentation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPixelShiftFrameRange
      //(0028,9506)
      = const PTag._('PixelShiftFrameRange', 0x00289506, 'Pixel Shift Frame Range',
          VR.kUS, VM.k2_2n, false);
  static const PTag kLUTFrameRange
      //(0028,9507)
      = const PTag._(
          'LUTFrameRange', 0x00289507, 'LUT Frame Range', VR.kUS, VM.k2_2n, false);
  static const PTag kImageToEquipmentMappingMatrix
      //(0028,9520)
      = const PTag._('ImageToEquipmentMappingMatrix', 0x00289520,
          'Image to Equipment Mapping Matrix', VR.kDS, VM.k16, false);
  static const PTag kEquipmentCoordinateSystemIdentification
      //(0028,9537)
      = const PTag._('EquipmentCoordinateSystemIdentification', 0x00289537,
          'Equipment Coordinate System Identification', VR.kCS, VM.k1, false);
  static const PTag kStudyStatusID
      //(0032,000A)
      = const PTag._('StudyStatusID', 0x0032000A, 'Study Status ID', VR.kCS, VM.k1, true);
  static const PTag kStudyPriorityID
      //(0032,000C)
      = const PTag._(
          'StudyPriorityID', 0x0032000C, 'Study Priority ID', VR.kCS, VM.k1, true);
  static const PTag kStudyIDIssuer
      //(0032,0012)
      = const PTag._('StudyIDIssuer', 0x00320012, 'Study ID Issuer', VR.kLO, VM.k1, true);
  static const PTag kStudyVerifiedDate
      //(0032,0032)
      = const PTag._(
          'StudyVerifiedDate', 0x00320032, 'Study Verified Date', VR.kDA, VM.k1, true);
  static const PTag kStudyVerifiedTime
      //(0032,0033)
      = const PTag._(
          'StudyVerifiedTime', 0x00320033, 'Study Verified Time', VR.kTM, VM.k1, true);
  static const PTag kStudyReadDate
      //(0032,0034)
      = const PTag._('StudyReadDate', 0x00320034, 'Study Read Date', VR.kDA, VM.k1, true);
  static const PTag kStudyReadTime
      //(0032,0035)
      = const PTag._('StudyReadTime', 0x00320035, 'Study Read Time', VR.kTM, VM.k1, true);
  static const PTag kScheduledStudyStartDate
      //(0032,1000)
      = const PTag._('ScheduledStudyStartDate', 0x00321000, 'Scheduled Study Start Date',
          VR.kDA, VM.k1, true);
  static const PTag kScheduledStudyStartTime
      //(0032,1001)
      = const PTag._('ScheduledStudyStartTime', 0x00321001, 'Scheduled Study Start Time',
          VR.kTM, VM.k1, true);
  static const PTag kScheduledStudyStopDate
      //(0032,1010)
      = const PTag._('ScheduledStudyStopDate', 0x00321010, 'Scheduled Study Stop Date',
          VR.kDA, VM.k1, true);
  static const PTag kScheduledStudyStopTime
      //(0032,1011)
      = const PTag._('ScheduledStudyStopTime', 0x00321011, 'Scheduled Study Stop Time',
          VR.kTM, VM.k1, true);
  static const PTag kScheduledStudyLocation
      //(0032,1020)
      = const PTag._('ScheduledStudyLocation', 0x00321020, 'Scheduled Study Location',
          VR.kLO, VM.k1, true);
  static const PTag kScheduledStudyLocationAETitle
      //(0032,1021)
      = const PTag._('ScheduledStudyLocationAETitle', 0x00321021,
          'Scheduled Study Location AE Title', VR.kAE, VM.k1_n, true);
  static const PTag kReasonForStudy
      //(0032,1030)
      =
      const PTag._('ReasonForStudy', 0x00321030, 'Reason for Study', VR.kLO, VM.k1, true);
  static const PTag kRequestingPhysicianIdentificationSequence
      //(0032,1031)
      = const PTag._('RequestingPhysicianIdentificationSequence', 0x00321031,
          'Requesting Physician Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRequestingPhysician
      //(0032,1032)
      = const PTag._('RequestingPhysician', 0x00321032, 'Requesting Physician', VR.kPN,
          VM.k1, false);
  static const PTag kRequestingService
      //(0032,1033)
      = const PTag._(
          'RequestingService', 0x00321033, 'Requesting Service', VR.kLO, VM.k1, false);
  static const PTag kRequestingServiceCodeSequence
      //(0032,1034)
      = const PTag._('RequestingServiceCodeSequence', 0x00321034,
          'Requesting Service Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStudyArrivalDate
      //(0032,1040)
      = const PTag._(
          'StudyArrivalDate', 0x00321040, 'Study Arrival Date', VR.kDA, VM.k1, true);
  static const PTag kStudyArrivalTime
      //(0032,1041)
      = const PTag._(
          'StudyArrivalTime', 0x00321041, 'Study Arrival Time', VR.kTM, VM.k1, true);
  static const PTag kStudyCompletionDate
      //(0032,1050)
      = const PTag._('StudyCompletionDate', 0x00321050, 'Study Completion Date', VR.kDA,
          VM.k1, true);
  static const PTag kStudyCompletionTime
      //(0032,1051)
      = const PTag._('StudyCompletionTime', 0x00321051, 'Study Completion Time', VR.kTM,
          VM.k1, true);
  static const PTag kStudyComponentStatusID
      //(0032,1055)
      = const PTag._('StudyComponentStatusID', 0x00321055, 'Study Component Status ID',
          VR.kCS, VM.k1, true);
  static const PTag kRequestedProcedureDescription
      //(0032,1060)
      = const PTag._('RequestedProcedureDescription', 0x00321060,
          'Requested Procedure Description', VR.kLO, VM.k1, false);
  static const PTag kRequestedProcedureCodeSequence
      //(0032,1064)
      = const PTag._('RequestedProcedureCodeSequence', 0x00321064,
          'Requested Procedure Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRequestedContrastAgent
      //(0032,1070)
      = const PTag._('RequestedContrastAgent', 0x00321070, 'Requested Contrast Agent',
          VR.kLO, VM.k1, false);
  static const PTag kStudyComments
      //(0032,4000)
      = const PTag._('StudyComments', 0x00324000, 'Study Comments', VR.kLT, VM.k1, true);
  static const PTag kReferencedPatientAliasSequence
      //(0038,0004)
      = const PTag._('ReferencedPatientAliasSequence', 0x00380004,
          'Referenced Patient Alias Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisitStatusID
      //(0038,0008)
      =
      const PTag._('VisitStatusID', 0x00380008, 'Visit Status ID', VR.kCS, VM.k1, false);
  static const PTag kAdmissionID
      //(0038,0010)
      = const PTag._('AdmissionID', 0x00380010, 'Admission ID', VR.kLO, VM.k1, false);
  static const PTag kIssuerOfAdmissionID
      //(0038,0011)
      = const PTag._('IssuerOfAdmissionID', 0x00380011, 'Issuer of Admission ID', VR.kLO,
          VM.k1, true);
  static const PTag kIssuerOfAdmissionIDSequence
      //(0038,0014)
      = const PTag._('IssuerOfAdmissionIDSequence', 0x00380014,
          'Issuer of Admission ID Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRouteOfAdmissions
      //(0038,0016)
      = const PTag._(
          'RouteOfAdmissions', 0x00380016, 'Route of Admissions', VR.kLO, VM.k1, false);
  static const PTag kScheduledAdmissionDate
      //(0038,001A)
      = const PTag._('ScheduledAdmissionDate', 0x0038001A, 'Scheduled Admission Date',
          VR.kDA, VM.k1, true);
  static const PTag kScheduledAdmissionTime
      //(0038,001B)
      = const PTag._('ScheduledAdmissionTime', 0x0038001B, 'Scheduled Admission Time',
          VR.kTM, VM.k1, true);
  static const PTag kScheduledDischargeDate
      //(0038,001C)
      = const PTag._('ScheduledDischargeDate', 0x0038001C, 'Scheduled Discharge Date',
          VR.kDA, VM.k1, true);
  static const PTag kScheduledDischargeTime
      //(0038,001D)
      = const PTag._('ScheduledDischargeTime', 0x0038001D, 'Scheduled Discharge Time',
          VR.kTM, VM.k1, true);
  static const PTag kScheduledPatientInstitutionResidence
      //(0038,001E)
      = const PTag._('ScheduledPatientInstitutionResidence', 0x0038001E,
          'Scheduled Patient Institution Residence', VR.kLO, VM.k1, true);
  static const PTag kAdmittingDate
      //(0038,0020)
      = const PTag._('AdmittingDate', 0x00380020, 'Admitting Date', VR.kDA, VM.k1, false);
  static const PTag kAdmittingTime
      //(0038,0021)
      = const PTag._('AdmittingTime', 0x00380021, 'Admitting Time', VR.kTM, VM.k1, false);
  static const PTag kDischargeDate
      //(0038,0030)
      = const PTag._('DischargeDate', 0x00380030, 'Discharge Date', VR.kDA, VM.k1, true);
  static const PTag kDischargeTime
      //(0038,0032)
      = const PTag._('DischargeTime', 0x00380032, 'Discharge Time', VR.kTM, VM.k1, true);
  static const PTag kDischargeDiagnosisDescription
      //(0038,0040)
      = const PTag._('DischargeDiagnosisDescription', 0x00380040,
          'Discharge Diagnosis Description', VR.kLO, VM.k1, true);
  static const PTag kDischargeDiagnosisCodeSequence
      //(0038,0044)
      = const PTag._('DischargeDiagnosisCodeSequence', 0x00380044,
          'Discharge Diagnosis Code Sequence', VR.kSQ, VM.k1, true);
  static const PTag kSpecialNeeds
      //(0038,0050)
      = const PTag._('SpecialNeeds', 0x00380050, 'Special Needs', VR.kLO, VM.k1, false);
  static const PTag kServiceEpisodeID
      //(0038,0060)
      = const PTag._(
          'ServiceEpisodeID', 0x00380060, 'Service Episode ID', VR.kLO, VM.k1, false);
  static const PTag kIssuerOfServiceEpisodeID
      //(0038,0061)
      = const PTag._('IssuerOfServiceEpisodeID', 0x00380061,
          'Issuer of Service Episode ID', VR.kLO, VM.k1, true);
  static const PTag kServiceEpisodeDescription
      //(0038,0062)
      = const PTag._('ServiceEpisodeDescription', 0x00380062,
          'Service Episode Description', VR.kLO, VM.k1, false);
  static const PTag kIssuerOfServiceEpisodeIDSequence
      //(0038,0064)
      = const PTag._('IssuerOfServiceEpisodeIDSequence', 0x00380064,
          'Issuer of Service Episode ID Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPertinentDocumentsSequence
      //(0038,0100)
      = const PTag._('PertinentDocumentsSequence', 0x00380100,
          'Pertinent Documents Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCurrentPatientLocation
      //(0038,0300)
      = const PTag._('CurrentPatientLocation', 0x00380300, 'Current Patient Location',
          VR.kLO, VM.k1, false);
  static const PTag kPatientInstitutionResidence
      //(0038,0400)
      = const PTag._('PatientInstitutionResidence', 0x00380400,
          'Patient\'s Institution Residence', VR.kLO, VM.k1, false);
  static const PTag kPatientState
      //(0038,0500)
      = const PTag._('PatientState', 0x00380500, 'Patient State', VR.kLO, VM.k1, false);
  static const PTag kPatientClinicalTrialParticipationSequence
      //(0038,0502)
      = const PTag._('PatientClinicalTrialParticipationSequence', 0x00380502,
          'Patient Clinical Trial Participation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisitComments
      //(0038,4000)
      = const PTag._('VisitComments', 0x00384000, 'Visit Comments', VR.kLT, VM.k1, false);
  static const PTag kWaveformOriginality
      //(003A,0004)
      = const PTag._('WaveformOriginality', 0x003A0004, 'Waveform Originality', VR.kCS,
          VM.k1, false);
  static const PTag kNumberOfWaveformChannels
      //(003A,0005)
      = const PTag._('NumberOfWaveformChannels', 0x003A0005,
          'Number of Waveform Channels', VR.kUS, VM.k1, false);
  static const PTag kNumberOfWaveformSamples
      //(003A,0010)
      = const PTag._('NumberOfWaveformSamples', 0x003A0010, 'Number of Waveform Samples',
          VR.kUL, VM.k1, false);
  static const PTag kSamplingFrequency
      //(003A,001A)
      = const PTag._(
          'SamplingFrequency', 0x003A001A, 'Sampling Frequency', VR.kDS, VM.k1, false);
  static const PTag kMultiplexGroupLabel
      //(003A,0020)
      = const PTag._('MultiplexGroupLabel', 0x003A0020, 'Multiplex Group Label', VR.kSH,
          VM.k1, false);
  static const PTag kChannelDefinitionSequence
      //(003A,0200)
      = const PTag._('ChannelDefinitionSequence', 0x003A0200,
          'Channel Definition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kWaveformChannelNumber
      //(003A,0202)
      = const PTag._('WaveformChannelNumber', 0x003A0202, 'Waveform Channel Number',
          VR.kIS, VM.k1, false);
  static const PTag kChannelLabel
      //(003A,0203)
      = const PTag._('ChannelLabel', 0x003A0203, 'Channel Label', VR.kSH, VM.k1, false);
  static const PTag kChannelStatus
      //(003A,0205)
      =
      const PTag._('ChannelStatus', 0x003A0205, 'Channel Status', VR.kCS, VM.k1_n, false);
  static const PTag kChannelSourceSequence
      //(003A,0208)
      = const PTag._('ChannelSourceSequence', 0x003A0208, 'Channel Source Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kChannelSourceModifiersSequence
      //(003A,0209)
      = const PTag._('ChannelSourceModifiersSequence', 0x003A0209,
          'Channel Source Modifiers Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourceWaveformSequence
      //(003A,020A)
      = const PTag._('SourceWaveformSequence', 0x003A020A, 'Source Waveform Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kChannelDerivationDescription
      //(003A,020C)
      = const PTag._('ChannelDerivationDescription', 0x003A020C,
          'Channel Derivation Description', VR.kLO, VM.k1, false);
  static const PTag kChannelSensitivity
      //(003A,0210)
      = const PTag._(
          'ChannelSensitivity', 0x003A0210, 'Channel Sensitivity', VR.kDS, VM.k1, false);
  static const PTag kChannelSensitivityUnitsSequence
      //(003A,0211)
      = const PTag._('ChannelSensitivityUnitsSequence', 0x003A0211,
          'Channel Sensitivity Units Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChannelSensitivityCorrectionFactor
      //(003A,0212)
      = const PTag._('ChannelSensitivityCorrectionFactor', 0x003A0212,
          'Channel Sensitivity Correction Factor', VR.kDS, VM.k1, false);
  static const PTag kChannelBaseline
      //(003A,0213)
      = const PTag._(
          'ChannelBaseline', 0x003A0213, 'Channel Baseline', VR.kDS, VM.k1, false);
  static const PTag kChannelTimeSkew
      //(003A,0214)
      = const PTag._(
          'ChannelTimeSkew', 0x003A0214, 'Channel Time Skew', VR.kDS, VM.k1, false);
  static const PTag kChannelSampleSkew
      //(003A,0215)
      = const PTag._(
          'ChannelSampleSkew', 0x003A0215, 'Channel Sample Skew', VR.kDS, VM.k1, false);
  static const PTag kChannelOffset
      //(003A,0218)
      = const PTag._('ChannelOffset', 0x003A0218, 'Channel Offset', VR.kDS, VM.k1, false);
  static const PTag kWaveformBitsStored
      //(003A,021A)
      = const PTag._(
          'WaveformBitsStored', 0x003A021A, 'Waveform Bits Stored', VR.kUS, VM.k1, false);
  static const PTag kFilterLowFrequency
      //(003A,0220)
      = const PTag._(
          'FilterLowFrequency', 0x003A0220, 'Filter Low Frequency', VR.kDS, VM.k1, false);
  static const PTag kFilterHighFrequency
      //(003A,0221)
      = const PTag._('FilterHighFrequency', 0x003A0221, 'Filter High Frequency', VR.kDS,
          VM.k1, false);
  static const PTag kNotchFilterFrequency
      //(003A,0222)
      = const PTag._('NotchFilterFrequency', 0x003A0222, 'Notch Filter Frequency', VR.kDS,
          VM.k1, false);
  static const PTag kNotchFilterBandwidth
      //(003A,0223)
      = const PTag._('NotchFilterBandwidth', 0x003A0223, 'Notch Filter Bandwidth', VR.kDS,
          VM.k1, false);
  static const PTag kWaveformDataDisplayScale
      //(003A,0230)
      = const PTag._('WaveformDataDisplayScale', 0x003A0230,
          'Waveform Data Display Scale', VR.kFL, VM.k1, false);
  static const PTag kWaveformDisplayBackgroundCIELabValue
      //(003A,0231)
      = const PTag._('WaveformDisplayBackgroundCIELabValue', 0x003A0231,
          'Waveform Display Background CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kWaveformPresentationGroupSequence
      //(003A,0240)
      = const PTag._('WaveformPresentationGroupSequence', 0x003A0240,
          'Waveform Presentation Group Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPresentationGroupNumber
      //(003A,0241)
      = const PTag._('PresentationGroupNumber', 0x003A0241, 'Presentation Group Number',
          VR.kUS, VM.k1, false);
  static const PTag kChannelDisplaySequence
      //(003A,0242)
      = const PTag._('ChannelDisplaySequence', 0x003A0242, 'Channel Display Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kChannelRecommendedDisplayCIELabValue
      //(003A,0244)
      = const PTag._('ChannelRecommendedDisplayCIELabValue', 0x003A0244,
          'Channel Recommended Display CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kChannelPosition
      //(003A,0245)
      = const PTag._(
          'ChannelPosition', 0x003A0245, 'Channel Position', VR.kFL, VM.k1, false);
  static const PTag kDisplayShadingFlag
      //(003A,0246)
      = const PTag._(
          'DisplayShadingFlag', 0x003A0246, 'Display Shading Flag', VR.kCS, VM.k1, false);
  static const PTag kFractionalChannelDisplayScale
      //(003A,0247)
      = const PTag._('FractionalChannelDisplayScale', 0x003A0247,
          'Fractional Channel Display Scale', VR.kFL, VM.k1, false);
  static const PTag kAbsoluteChannelDisplayScale
      //(003A,0248)
      = const PTag._('AbsoluteChannelDisplayScale', 0x003A0248,
          'Absolute Channel Display Scale', VR.kFL, VM.k1, false);
  static const PTag kMultiplexedAudioChannelsDescriptionCodeSequence
      //(003A,0300)
      = const PTag._('MultiplexedAudioChannelsDescriptionCodeSequence', 0x003A0300,
          'Multiplexed Audio Channels Description Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChannelIdentificationCode
      //(003A,0301)
      = const PTag._('ChannelIdentificationCode', 0x003A0301,
          'Channel Identification Code', VR.kIS, VM.k1, false);
  static const PTag kChannelMode
      //(003A,0302)
      = const PTag._('ChannelMode', 0x003A0302, 'Channel Mode', VR.kCS, VM.k1, false);
  static const PTag kScheduledStationAETitle
      //(0040,0001)
      = const PTag._('ScheduledStationAETitle', 0x00400001, 'Scheduled Station AE Title',
          VR.kAE, VM.k1_n, false);
  static const PTag kScheduledProcedureStepStartDate
      //(0040,0002)
      = const PTag._('ScheduledProcedureStepStartDate', 0x00400002,
          'Scheduled Procedure Step Start Date', VR.kDA, VM.k1, false);
  static const PTag kScheduledProcedureStepStartTime
      //(0040,0003)
      = const PTag._('ScheduledProcedureStepStartTime', 0x00400003,
          'Scheduled Procedure Step Start Time', VR.kTM, VM.k1, false);
  static const PTag kScheduledProcedureStepEndDate
      //(0040,0004)
      = const PTag._('ScheduledProcedureStepEndDate', 0x00400004,
          'Scheduled Procedure Step End Date', VR.kDA, VM.k1, false);
  static const PTag kScheduledProcedureStepEndTime
      //(0040,0005)
      = const PTag._('ScheduledProcedureStepEndTime', 0x00400005,
          'Scheduled Procedure Step End Time', VR.kTM, VM.k1, false);
  static const PTag kScheduledPerformingPhysicianName
      //(0040,0006)
      = const PTag._('ScheduledPerformingPhysicianName', 0x00400006,
          'Scheduled Performing Physician\'s Name', VR.kPN, VM.k1, false);
  static const PTag kScheduledProcedureStepDescription
      //(0040,0007)
      = const PTag._('ScheduledProcedureStepDescription', 0x00400007,
          'Scheduled Procedure Step Description', VR.kLO, VM.k1, false);
  static const PTag kScheduledProtocolCodeSequence
      //(0040,0008)
      = const PTag._('ScheduledProtocolCodeSequence', 0x00400008,
          'Scheduled Protocol Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledProcedureStepID
      //(0040,0009)
      = const PTag._('ScheduledProcedureStepID', 0x00400009,
          'Scheduled Procedure Step ID', VR.kSH, VM.k1, false);
  static const PTag kStageCodeSequence
      //(0040,000A)
      = const PTag._(
          'StageCodeSequence', 0x0040000A, 'Stage Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledPerformingPhysicianIdentificationSequence
      //(0040,000B)
      = const PTag._('ScheduledPerformingPhysicianIdentificationSequence', 0x0040000B,
          'Scheduled Performing Physician Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledStationName
      //(0040,0010)
      = const PTag._('ScheduledStationName', 0x00400010, 'Scheduled Station Name', VR.kSH,
          VM.k1_n, false);
  static const PTag kScheduledProcedureStepLocation
      //(0040,0011)
      = const PTag._('ScheduledProcedureStepLocation', 0x00400011,
          'Scheduled Procedure Step Location', VR.kSH, VM.k1, false);
  static const PTag kPreMedication
      //(0040,0012)
      = const PTag._('PreMedication', 0x00400012, 'Pre-Medication', VR.kLO, VM.k1, false);
  static const PTag kScheduledProcedureStepStatus
      //(0040,0020)
      = const PTag._('ScheduledProcedureStepStatus', 0x00400020,
          'Scheduled Procedure Step Status', VR.kCS, VM.k1, false);
  static const PTag kOrderPlacerIdentifierSequence
      //(0040,0026)
      = const PTag._('OrderPlacerIdentifierSequence', 0x00400026,
          'Order Placer Identifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOrderFillerIdentifierSequence
      //(0040,0027)
      = const PTag._('OrderFillerIdentifierSequence', 0x00400027,
          'Order Filler Identifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLocalNamespaceEntityID
      //(0040,0031)
      = const PTag._('LocalNamespaceEntityID', 0x00400031, 'Local Namespace Entity ID',
          VR.kUT, VM.k1, false);
  static const PTag kUniversalEntityID
      //(0040,0032)
      = const PTag._(
          'UniversalEntityID', 0x00400032, 'Universal Entity ID', VR.kUT, VM.k1, false);
  static const PTag kUniversalEntityIDType
      //(0040,0033)
      = const PTag._('UniversalEntityIDType', 0x00400033, 'Universal Entity ID Type',
          VR.kCS, VM.k1, false);
  static const PTag kIdentifierTypeCode
      //(0040,0035)
      = const PTag._(
          'IdentifierTypeCode', 0x00400035, 'Identifier Type Code', VR.kCS, VM.k1, false);
  static const PTag kAssigningFacilitySequence
      //(0040,0036)
      = const PTag._('AssigningFacilitySequence', 0x00400036,
          'Assigning Facility Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAssigningJurisdictionCodeSequence
      //(0040,0039)
      = const PTag._('AssigningJurisdictionCodeSequence', 0x00400039,
          'Assigning Jurisdiction Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAssigningAgencyOrDepartmentCodeSequence
      //(0040,003A)
      = const PTag._('AssigningAgencyOrDepartmentCodeSequence', 0x0040003A,
          'Assigning Agency or Department Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledProcedureStepSequence
      //(0040,0100)
      = const PTag._('ScheduledProcedureStepSequence', 0x00400100,
          'Scheduled Procedure Step Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedNonImageCompositeSOPInstanceSequence
      //(0040,0220)
      = const PTag._('ReferencedNonImageCompositeSOPInstanceSequence', 0x00400220,
          'Referenced Non-Image Composite SOP Instance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedStationAETitle
      //(0040,0241)
      = const PTag._('PerformedStationAETitle', 0x00400241, 'Performed Station AE Title',
          VR.kAE, VM.k1, false);
  static const PTag kPerformedStationName
      //(0040,0242)
      = const PTag._('PerformedStationName', 0x00400242, 'Performed Station Name', VR.kSH,
          VM.k1, false);
  static const PTag kPerformedLocation
      //(0040,0243)
      = const PTag._(
          'PerformedLocation', 0x00400243, 'Performed Location', VR.kSH, VM.k1, false);
  static const PTag kPerformedProcedureStepStartDate
      //(0040,0244)
      = const PTag._('PerformedProcedureStepStartDate', 0x00400244,
          'Performed Procedure Step Start Date', VR.kDA, VM.k1, false);
  static const PTag kPerformedProcedureStepStartTime
      //(0040,0245)
      = const PTag._('PerformedProcedureStepStartTime', 0x00400245,
          'Performed Procedure Step Start Time', VR.kTM, VM.k1, false);
  static const PTag kPerformedProcedureStepEndDate
      //(0040,0250)
      = const PTag._('PerformedProcedureStepEndDate', 0x00400250,
          'Performed Procedure Step End Date', VR.kDA, VM.k1, false);
  static const PTag kPerformedProcedureStepEndTime
      //(0040,0251)
      = const PTag._('PerformedProcedureStepEndTime', 0x00400251,
          'Performed Procedure Step End Time', VR.kTM, VM.k1, false);
  static const PTag kPerformedProcedureStepStatus
      //(0040,0252)
      = const PTag._('PerformedProcedureStepStatus', 0x00400252,
          'Performed Procedure Step Status', VR.kCS, VM.k1, false);
  static const PTag kPerformedProcedureStepID
      //(0040,0253)
      = const PTag._('PerformedProcedureStepID', 0x00400253,
          'Performed Procedure Step ID', VR.kSH, VM.k1, false);
  static const PTag kPerformedProcedureStepDescription
      //(0040,0254)
      = const PTag._('PerformedProcedureStepDescription', 0x00400254,
          'Performed Procedure Step Description', VR.kLO, VM.k1, false);
  static const PTag kPerformedProcedureTypeDescription
      //(0040,0255)
      = const PTag._('PerformedProcedureTypeDescription', 0x00400255,
          'Performed Procedure Type Description', VR.kLO, VM.k1, false);
  static const PTag kPerformedProtocolCodeSequence
      //(0040,0260)
      = const PTag._('PerformedProtocolCodeSequence', 0x00400260,
          'Performed Protocol Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedProtocolType
      //(0040,0261)
      = const PTag._('PerformedProtocolType', 0x00400261, 'Performed Protocol Type',
          VR.kCS, VM.k1, false);
  static const PTag kScheduledStepAttributesSequence
      //(0040,0270)
      = const PTag._('ScheduledStepAttributesSequence', 0x00400270,
          'Scheduled Step Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRequestAttributesSequence
      //(0040,0275)
      = const PTag._('RequestAttributesSequence', 0x00400275,
          'Request Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCommentsOnThePerformedProcedureStep
      //(0040,0280)
      = const PTag._('CommentsOnThePerformedProcedureStep', 0x00400280,
          'Comments on the Performed Procedure Step', VR.kST, VM.k1, false);
  static const PTag kPerformedProcedureStepDiscontinuationReasonCodeSequence
      //(0040,0281)
      = const PTag._(
          'PerformedProcedureStepDiscontinuationReasonCodeSequence',
          0x00400281,
          'Performed Procedure Step Discontinuation Reason Code Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kQuantitySequence
      //(0040,0293)
      = const PTag._(
          'QuantitySequence', 0x00400293, 'Quantity Sequence', VR.kSQ, VM.k1, false);
  static const PTag kQuantity
      //(0040,0294)
      = const PTag._('Quantity', 0x00400294, 'Quantity', VR.kDS, VM.k1, false);
  static const PTag kMeasuringUnitsSequence
      //(0040,0295)
      = const PTag._('MeasuringUnitsSequence', 0x00400295, 'Measuring Units Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kBillingItemSequence
      //(0040,0296)
      = const PTag._('BillingItemSequence', 0x00400296, 'Billing Item Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kTotalTimeOfFluoroscopy
      //(0040,0300)
      = const PTag._('TotalTimeOfFluoroscopy', 0x00400300, 'Total Time of Fluoroscopy',
          VR.kUS, VM.k1, false);
  static const PTag kTotalNumberOfExposures
      //(0040,0301)
      = const PTag._('TotalNumberOfExposures', 0x00400301, 'Total Number of Exposures',
          VR.kUS, VM.k1, false);
  static const PTag kEntranceDose
      //(0040,0302)
      = const PTag._('EntranceDose', 0x00400302, 'Entrance Dose', VR.kUS, VM.k1, false);
  static const PTag kExposedArea
      //(0040,0303)
      = const PTag._('ExposedArea', 0x00400303, 'Exposed Area', VR.kUS, VM.k1_2, false);
  static const PTag kDistanceSourceToEntrance
      //(0040,0306)
      = const PTag._('DistanceSourceToEntrance', 0x00400306,
          'Distance Source to Entrance', VR.kDS, VM.k1, false);
  static const PTag kDistanceSourceToSupport
      //(0040,0307)
      = const PTag._('DistanceSourceToSupport', 0x00400307, 'Distance Source to Support',
          VR.kDS, VM.k1, true);
  static const PTag kExposureDoseSequence
      //(0040,030E)
      = const PTag._('ExposureDoseSequence', 0x0040030E, 'Exposure Dose Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kCommentsOnRadiationDose
      //(0040,0310)
      = const PTag._('CommentsOnRadiationDose', 0x00400310, 'Comments on Radiation Dose',
          VR.kST, VM.k1, false);
  static const PTag kXRayOutput
      //(0040,0312)
      = const PTag._('XRayOutput', 0x00400312, 'X-Ray Output', VR.kDS, VM.k1, false);
  static const PTag kHalfValueLayer
      //(0040,0314)
      = const PTag._(
          'HalfValueLayer', 0x00400314, 'Half Value Layer', VR.kDS, VM.k1, false);
  static const PTag kOrganDose
      //(0040,0316)
      = const PTag._('OrganDose', 0x00400316, 'Organ Dose', VR.kDS, VM.k1, false);
  static const PTag kOrganExposed
      //(0040,0318)
      = const PTag._('OrganExposed', 0x00400318, 'Organ Exposed', VR.kCS, VM.k1, false);
  static const PTag kBillingProcedureStepSequence
      //(0040,0320)
      = const PTag._('BillingProcedureStepSequence', 0x00400320,
          'Billing Procedure Step Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFilmConsumptionSequence
      //(0040,0321)
      = const PTag._('FilmConsumptionSequence', 0x00400321, 'Film Consumption Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kBillingSuppliesAndDevicesSequence
      //(0040,0324)
      = const PTag._('BillingSuppliesAndDevicesSequence', 0x00400324,
          'Billing Supplies and Devices Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedProcedureStepSequence
      //(0040,0330)
      = const PTag._('ReferencedProcedureStepSequence', 0x00400330,
          'Referenced Procedure Step Sequence', VR.kSQ, VM.k1, true);
  static const PTag kPerformedSeriesSequence
      //(0040,0340)
      = const PTag._('PerformedSeriesSequence', 0x00400340, 'Performed Series Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCommentsOnTheScheduledProcedureStep
      //(0040,0400)
      = const PTag._('CommentsOnTheScheduledProcedureStep', 0x00400400,
          'Comments on the Scheduled Procedure Step', VR.kLT, VM.k1, false);
  static const PTag kProtocolContextSequence
      //(0040,0440)
      = const PTag._('ProtocolContextSequence', 0x00400440, 'Protocol Context Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kContentItemModifierSequence
      //(0040,0441)
      = const PTag._('ContentItemModifierSequence', 0x00400441,
          'Content Item Modifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledSpecimenSequence
      //(0040,0500)
      = const PTag._('ScheduledSpecimenSequence', 0x00400500,
          'Scheduled Specimen Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenAccessionNumber
      //(0040,050A)
      = const PTag._('SpecimenAccessionNumber', 0x0040050A, 'Specimen Accession Number',
          VR.kLO, VM.k1, true);
  static const PTag kContainerIdentifier
      //(0040,0512)
      = const PTag._('ContainerIdentifier', 0x00400512, 'Container Identifier', VR.kLO,
          VM.k1, false);
  static const PTag kIssuerOfTheContainerIdentifierSequence
      //(0040,0513)
      = const PTag._('IssuerOfTheContainerIdentifierSequence', 0x00400513,
          'Issuer of the Container Identifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAlternateContainerIdentifierSequence
      //(0040,0515)
      = const PTag._('AlternateContainerIdentifierSequence', 0x00400515,
          'Alternate Container Identifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContainerTypeCodeSequence
      //(0040,0518)
      = const PTag._('ContainerTypeCodeSequence', 0x00400518,
          'Container Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContainerDescription
      //(0040,051A)
      = const PTag._('ContainerDescription', 0x0040051A, 'Container Description', VR.kLO,
          VM.k1, false);
  static const PTag kContainerComponentSequence
      //(0040,0520)
      = const PTag._('ContainerComponentSequence', 0x00400520,
          'Container Component Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenSequence
      //(0040,0550)
      = const PTag._(
          'SpecimenSequence', 0x00400550, 'Specimen Sequence', VR.kSQ, VM.k1, true);
  static const PTag kSpecimenIdentifier
      //(0040,0551)
      = const PTag._(
          'SpecimenIdentifier', 0x00400551, 'Specimen Identifier', VR.kLO, VM.k1, false);
  static const PTag kSpecimenDescriptionSequenceTrial
      //(0040,0552)
      = const PTag._('SpecimenDescriptionSequenceTrial', 0x00400552,
          'Specimen Description Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kSpecimenDescriptionTrial
      //(0040,0553)
      = const PTag._('SpecimenDescriptionTrial', 0x00400553,
          'Specimen Description (Trial)', VR.kST, VM.k1, true);
  static const PTag kSpecimenUID
      //(0040,0554)
      = const PTag._('SpecimenUID', 0x00400554, 'Specimen UID', VR.kUI, VM.k1, false);
  static const PTag kAcquisitionContextSequence
      //(0040,0555)
      = const PTag._('AcquisitionContextSequence', 0x00400555,
          'Acquisition Context Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAcquisitionContextDescription
      //(0040,0556)
      = const PTag._('AcquisitionContextDescription', 0x00400556,
          'Acquisition Context Description', VR.kST, VM.k1, false);
  static const PTag kSpecimenTypeCodeSequence
      //(0040,059A)
      = const PTag._('SpecimenTypeCodeSequence', 0x0040059A,
          'Specimen Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenDescriptionSequence
      //(0040,0560)
      = const PTag._('SpecimenDescriptionSequence', 0x00400560,
          'Specimen Description Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIssuerOfTheSpecimenIdentifierSequence
      //(0040,0562)
      = const PTag._('IssuerOfTheSpecimenIdentifierSequence', 0x00400562,
          'Issuer of the Specimen Identifier Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenShortDescription
      //(0040,0600)
      = const PTag._('SpecimenShortDescription', 0x00400600, 'Specimen Short Description',
          VR.kLO, VM.k1, false);
  static const PTag kSpecimenDetailedDescription
      //(0040,0602)
      = const PTag._('SpecimenDetailedDescription', 0x00400602,
          'Specimen Detailed Description', VR.kUT, VM.k1, false);
  static const PTag kSpecimenPreparationSequence
      //(0040,0610)
      = const PTag._('SpecimenPreparationSequence', 0x00400610,
          'Specimen Preparation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenPreparationStepContentItemSequence
      //(0040,0612)
      = const PTag._('SpecimenPreparationStepContentItemSequence', 0x00400612,
          'Specimen Preparation Step Content Item Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenLocalizationContentItemSequence
      //(0040,0620)
      = const PTag._('SpecimenLocalizationContentItemSequence', 0x00400620,
          'Specimen Localization Content Item Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSlideIdentifier
      //(0040,06FA)
      = const PTag._(
          'SlideIdentifier', 0x004006FA, 'Slide Identifier', VR.kLO, VM.k1, true);
  static const PTag kImageCenterPointCoordinatesSequence
      //(0040,071A)
      = const PTag._('ImageCenterPointCoordinatesSequence', 0x0040071A,
          'Image Center Point Coordinates Sequence', VR.kSQ, VM.k1, false);
  static const PTag kXOffsetInSlideCoordinateSystem
      //(0040,072A)
      = const PTag._('XOffsetInSlideCoordinateSystem', 0x0040072A,
          'X Offset in Slide Coordinate System', VR.kDS, VM.k1, false);
  static const PTag kYOffsetInSlideCoordinateSystem
      //(0040,073A)
      = const PTag._('YOffsetInSlideCoordinateSystem', 0x0040073A,
          'Y Offset in Slide Coordinate System', VR.kDS, VM.k1, false);
  static const PTag kZOffsetInSlideCoordinateSystem
      //(0040,074A)
      = const PTag._('ZOffsetInSlideCoordinateSystem', 0x0040074A,
          'Z Offset in Slide Coordinate System', VR.kDS, VM.k1, false);
  static const PTag kPixelSpacingSequence
      //(0040,08D8)
      = const PTag._('PixelSpacingSequence', 0x004008D8, 'Pixel Spacing Sequence', VR.kSQ,
          VM.k1, true);
  static const PTag kCoordinateSystemAxisCodeSequence
      //(0040,08DA)
      = const PTag._('CoordinateSystemAxisCodeSequence', 0x004008DA,
          'Coordinate System Axis Code Sequence', VR.kSQ, VM.k1, true);
  static const PTag kMeasurementUnitsCodeSequence
      //(0040,08EA)
      = const PTag._('MeasurementUnitsCodeSequence', 0x004008EA,
          'Measurement Units Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVitalStainCodeSequenceTrial
      //(0040,09F8)
      = const PTag._('VitalStainCodeSequenceTrial', 0x004009F8,
          'Vital Stain Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kRequestedProcedureID
      //(0040,1001)
      = const PTag._('RequestedProcedureID', 0x00401001, 'Requested Procedure ID', VR.kSH,
          VM.k1, false);
  static const PTag kReasonForTheRequestedProcedure
      //(0040,1002)
      = const PTag._('ReasonForTheRequestedProcedure', 0x00401002,
          'Reason for the Requested Procedure', VR.kLO, VM.k1, false);
  static const PTag kRequestedProcedurePriority
      //(0040,1003)
      = const PTag._('RequestedProcedurePriority', 0x00401003,
          'Requested Procedure Priority', VR.kSH, VM.k1, false);
  static const PTag kPatientTransportArrangements
      //(0040,1004)
      = const PTag._('PatientTransportArrangements', 0x00401004,
          'Patient Transport Arrangements', VR.kLO, VM.k1, false);
  static const PTag kRequestedProcedureLocation
      //(0040,1005)
      = const PTag._('RequestedProcedureLocation', 0x00401005,
          'Requested Procedure Location', VR.kLO, VM.k1, false);
  static const PTag kPlacerOrderNumberProcedure
      //(0040,1006)
      = const PTag._('PlacerOrderNumberProcedure', 0x00401006,
          'Placer Order Number / Procedure', VR.kSH, VM.k1, true);
  static const PTag kFillerOrderNumberProcedure
      //(0040,1007)
      = const PTag._('FillerOrderNumberProcedure', 0x00401007,
          'Filler Order Number / Procedure', VR.kSH, VM.k1, true);
  static const PTag kConfidentialityCode
      //(0040,1008)
      = const PTag._('ConfidentialityCode', 0x00401008, 'Confidentiality Code', VR.kLO,
          VM.k1, false);
  static const PTag kReportingPriority
      //(0040,1009)
      = const PTag._(
          'ReportingPriority', 0x00401009, 'Reporting Priority', VR.kSH, VM.k1, false);
  static const PTag kReasonForRequestedProcedureCodeSequence
      //(0040,100A)
      = const PTag._('ReasonForRequestedProcedureCodeSequence', 0x0040100A,
          'Reason for Requested Procedure Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNamesOfIntendedRecipientsOfResults
      //(0040,1010)
      = const PTag._('NamesOfIntendedRecipientsOfResults', 0x00401010,
          'Names of Intended Recipients of Results', VR.kPN, VM.k1_n, false);
  static const PTag kIntendedRecipientsOfResultsIdentificationSequence
      //(0040,1011)
      = const PTag._('IntendedRecipientsOfResultsIdentificationSequence', 0x00401011,
          'Intended Recipients of Results Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReasonForPerformedProcedureCodeSequence
      //(0040,1012)
      = const PTag._('ReasonForPerformedProcedureCodeSequence', 0x00401012,
          'Reason For Performed Procedure Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRequestedProcedureDescriptionTrial
      //(0040,1060)
      = const PTag._('RequestedProcedureDescriptionTrial', 0x00401060,
          'Requested Procedure Description (Trial)', VR.kLO, VM.k1, true);
  static const PTag kPersonIdentificationCodeSequence
      //(0040,1101)
      = const PTag._('PersonIdentificationCodeSequence', 0x00401101,
          'Person Identification Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPersonAddress
      //(0040,1102)
      = const PTag._(
          'PersonAddress', 0x00401102, 'Person\'s Address', VR.kST, VM.k1, false);
  static const PTag kPersonTelephoneNumbers
      //(0040,1103)
      = const PTag._('PersonTelephoneNumbers', 0x00401103, 'Person\'s Telephone Numbers',
          VR.kLO, VM.k1_n, false);
  static const PTag kRequestedProcedureComments
      //(0040,1400)
      = const PTag._('RequestedProcedureComments', 0x00401400,
          'Requested Procedure Comments', VR.kLT, VM.k1, false);
  static const PTag kReasonForTheImagingServiceRequest
      //(0040,2001)
      = const PTag._('ReasonForTheImagingServiceRequest', 0x00402001,
          'Reason for the Imaging Service Request', VR.kLO, VM.k1, true);
  static const PTag kIssueDateOfImagingServiceRequest
      //(0040,2004)
      = const PTag._('IssueDateOfImagingServiceRequest', 0x00402004,
          'Issue Date of Imaging Service Request', VR.kDA, VM.k1, false);
  static const PTag kIssueTimeOfImagingServiceRequest
      //(0040,2005)
      = const PTag._('IssueTimeOfImagingServiceRequest', 0x00402005,
          'Issue Time of Imaging Service Request', VR.kTM, VM.k1, false);
  static const PTag kPlacerOrderNumberImagingServiceRequestRetired
      //(0040,2006)
      = const PTag._('PlacerOrderNumberImagingServiceRequestRetired', 0x00402006,
          'Placer Order Number / Imaging Service Request (Retired)', VR.kSH, VM.k1, true);
  static const PTag kFillerOrderNumberImagingServiceRequestRetired
      //(0040,2007)
      = const PTag._('FillerOrderNumberImagingServiceRequestRetired', 0x00402007,
          'Filler Order Number / Imaging Service Request (Retired)', VR.kSH, VM.k1, true);
  static const PTag kOrderEnteredBy
      //(0040,2008)
      = const PTag._(
          'OrderEnteredBy', 0x00402008, 'Order Entered By', VR.kPN, VM.k1, false);
  static const PTag kOrderEntererLocation
      //(0040,2009)
      = const PTag._('OrderEntererLocation', 0x00402009, 'Order Enterer\'s Location',
          VR.kSH, VM.k1, false);
  static const PTag kOrderCallbackPhoneNumber
      //(0040,2010)
      = const PTag._('OrderCallbackPhoneNumber', 0x00402010,
          'Order Callback Phone Number', VR.kSH, VM.k1, false);
  static const PTag kPlacerOrderNumberImagingServiceRequest
      //(0040,2016)
      = const PTag._('PlacerOrderNumberImagingServiceRequest', 0x00402016,
          'Placer Order Number / Imaging Service Request', VR.kLO, VM.k1, false);
  static const PTag kFillerOrderNumberImagingServiceRequest
      //(0040,2017)
      = const PTag._('FillerOrderNumberImagingServiceRequest', 0x00402017,
          'Filler Order Number / Imaging Service Request', VR.kLO, VM.k1, false);
  static const PTag kImagingServiceRequestComments
      //(0040,2400)
      = const PTag._('ImagingServiceRequestComments', 0x00402400,
          'Imaging Service Request Comments', VR.kLT, VM.k1, false);
  static const PTag kConfidentialityConstraintOnPatientDataDescription
      //(0040,3001)
      = const PTag._('ConfidentialityConstraintOnPatientDataDescription', 0x00403001,
          'Confidentiality Constraint on Patient Data Description', VR.kLO, VM.k1, false);
  static const PTag kGeneralPurposeScheduledProcedureStepStatus
      //(0040,4001)
      = const PTag._('GeneralPurposeScheduledProcedureStepStatus', 0x00404001,
          'General Purpose Scheduled Procedure Step Status', VR.kCS, VM.k1, true);
  static const PTag kGeneralPurposePerformedProcedureStepStatus
      //(0040,4002)
      = const PTag._('GeneralPurposePerformedProcedureStepStatus', 0x00404002,
          'General Purpose Performed Procedure Step Status', VR.kCS, VM.k1, true);
  static const PTag kGeneralPurposeScheduledProcedureStepPriority
      //(0040,4003)
      = const PTag._('GeneralPurposeScheduledProcedureStepPriority', 0x00404003,
          'General Purpose Scheduled Procedure Step Priority', VR.kCS, VM.k1, true);
  static const PTag kScheduledProcessingApplicationsCodeSequence
      //(0040,4004)
      = const PTag._('ScheduledProcessingApplicationsCodeSequence', 0x00404004,
          'Scheduled Processing Applications Code Sequence', VR.kSQ, VM.k1, true);
  static const PTag kScheduledProcedureStepStartDateTime
      //(0040,4005)
      = const PTag._('ScheduledProcedureStepStartDateTime', 0x00404005,
          'Scheduled Procedure Step Start DateTime', VR.kDT, VM.k1, true);
  static const PTag kMultipleCopiesFlag
      //(0040,4006)
      = const PTag._(
          'MultipleCopiesFlag', 0x00404006, 'Multiple Copies Flag', VR.kCS, VM.k1, true);
  static const PTag kPerformedProcessingApplicationsCodeSequence
      //(0040,4007)
      = const PTag._('PerformedProcessingApplicationsCodeSequence', 0x00404007,
          'Performed Processing Applications Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHumanPerformerCodeSequence
      //(0040,4009)
      = const PTag._('HumanPerformerCodeSequence', 0x00404009,
          'Human Performer Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledProcedureStepModificationDateTime
      //(0040,4010)
      = const PTag._('ScheduledProcedureStepModificationDateTime', 0x00404010,
          'Scheduled Procedure Step Modification DateTime', VR.kDT, VM.k1, false);
  static const PTag kExpectedCompletionDateTime
      //(0040,4011)
      = const PTag._('ExpectedCompletionDateTime', 0x00404011,
          'Expected Completion DateTime', VR.kDT, VM.k1, false);
  static const PTag kResultingGeneralPurposePerformedProcedureStepsSequence
      //(0040,4015)
      = const PTag._(
          'ResultingGeneralPurposePerformedProcedureStepsSequence',
          0x00404015,
          'Resulting General Purpose Performed Procedure Steps Sequence',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kReferencedGeneralPurposeScheduledProcedureStepSequence
      //(0040,4016)
      = const PTag._(
          'ReferencedGeneralPurposeScheduledProcedureStepSequence',
          0x00404016,
          'Referenced General Purpose Scheduled Procedure Step Sequence',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kScheduledWorkitemCodeSequence
      //(0040,4018)
      = const PTag._('ScheduledWorkitemCodeSequence', 0x00404018,
          'Scheduled Workitem Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedWorkitemCodeSequence
      //(0040,4019)
      = const PTag._('PerformedWorkitemCodeSequence', 0x00404019,
          'Performed Workitem Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kInputAvailabilityFlag
      //(0040,4020)
      = const PTag._('InputAvailabilityFlag', 0x00404020, 'Input Availability Flag',
          VR.kCS, VM.k1, false);
  static const PTag kInputInformationSequence
      //(0040,4021)
      = const PTag._('InputInformationSequence', 0x00404021, 'Input Information Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kRelevantInformationSequence
      //(0040,4022)
      = const PTag._('RelevantInformationSequence', 0x00404022,
          'Relevant Information Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedGeneralPurposeScheduledProcedureStepTransactionUID
      //(0040,4023)
      = const PTag._(
          'ReferencedGeneralPurposeScheduledProcedureStepTransactionUID',
          0x00404023,
          'Referenced General Purpose Scheduled Procedure Step Transaction UID',
          VR.kUI,
          VM.k1,
          true);
  static const PTag kScheduledStationNameCodeSequence
      //(0040,4025)
      = const PTag._('ScheduledStationNameCodeSequence', 0x00404025,
          'Scheduled Station Name Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledStationClassCodeSequence
      //(0040,4026)
      = const PTag._('ScheduledStationClassCodeSequence', 0x00404026,
          'Scheduled Station Class Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledStationGeographicLocationCodeSequence
      //(0040,4027)
      = const PTag._('ScheduledStationGeographicLocationCodeSequence', 0x00404027,
          'Scheduled Station Geographic Location Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedStationNameCodeSequence
      //(0040,4028)
      = const PTag._('PerformedStationNameCodeSequence', 0x00404028,
          'Performed Station Name Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedStationClassCodeSequence
      //(0040,4029)
      = const PTag._('PerformedStationClassCodeSequence', 0x00404029,
          'Performed Station Class Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedStationGeographicLocationCodeSequence
      //(0040,4030)
      = const PTag._('PerformedStationGeographicLocationCodeSequence', 0x00404030,
          'Performed Station Geographic Location Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRequestedSubsequentWorkitemCodeSequence
      //(0040,4031)
      = const PTag._('RequestedSubsequentWorkitemCodeSequence', 0x00404031,
          'Requested Subsequent Workitem Code Sequence', VR.kSQ, VM.k1, true);
  static const PTag kNonDICOMOutputCodeSequence
      //(0040,4032)
      = const PTag._('NonDICOMOutputCodeSequence', 0x00404032,
          'Non-DICOM Output Code Sequence', VR.kSQ, VM.k1, true);
  static const PTag kOutputInformationSequence
      //(0040,4033)
      = const PTag._('OutputInformationSequence', 0x00404033,
          'Output Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScheduledHumanPerformersSequence
      //(0040,4034)
      = const PTag._('ScheduledHumanPerformersSequence', 0x00404034,
          'Scheduled Human Performers Sequence', VR.kSQ, VM.k1, false);
  static const PTag kActualHumanPerformersSequence
      //(0040,4035)
      = const PTag._('ActualHumanPerformersSequence', 0x00404035,
          'Actual Human Performers Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHumanPerformerOrganization
      //(0040,4036)
      = const PTag._('HumanPerformerOrganization', 0x00404036,
          'Human Performer\'s Organization', VR.kLO, VM.k1, false);
  static const PTag kHumanPerformerName
      //(0040,4037)
      = const PTag._('HumanPerformerName', 0x00404037, 'Human Performer\'s Name', VR.kPN,
          VM.k1, false);
  static const PTag kRawDataHandling
      //(0040,4040)
      = const PTag._(
          'RawDataHandling', 0x00404040, 'Raw Data Handling', VR.kCS, VM.k1, false);
  static const PTag kInputReadinessState
      //(0040,4041)
      = const PTag._('InputReadinessState', 0x00404041, 'Input Readiness State', VR.kCS,
          VM.k1, false);
  static const PTag kPerformedProcedureStepStartDateTime
      //(0040,4050)
      = const PTag._('PerformedProcedureStepStartDateTime', 0x00404050,
          'Performed Procedure Step Start DateTime', VR.kDT, VM.k1, false);
  static const PTag kPerformedProcedureStepEndDateTime
      //(0040,4051)
      = const PTag._('PerformedProcedureStepEndDateTime', 0x00404051,
          'Performed Procedure Step End DateTime', VR.kDT, VM.k1, false);
  static const PTag kProcedureStepCancellationDateTime
      //(0040,4052)
      = const PTag._('ProcedureStepCancellationDateTime', 0x00404052,
          'Procedure Step Cancellation DateTime', VR.kDT, VM.k1, false);
  static const PTag kEntranceDoseInmGy
      //(0040,8302)
      = const PTag._(
          'EntranceDoseInmGy', 0x00408302, 'Entrance Dose in mGy', VR.kDS, VM.k1, false);
  static const PTag kReferencedImageRealWorldValueMappingSequence
      //(0040,9094)
      = const PTag._('ReferencedImageRealWorldValueMappingSequence', 0x00409094,
          'Referenced Image Real World Value Mapping Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRealWorldValueMappingSequence
      //(0040,9096)
      = const PTag._('RealWorldValueMappingSequence', 0x00409096,
          'Real World Value Mapping Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPixelValueMappingCodeSequence
      //(0040,9098)
      = const PTag._('PixelValueMappingCodeSequence', 0x00409098,
          'Pixel Value Mapping Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLUTLabel
      //(0040,9210)
      = const PTag._('LUTLabel', 0x00409210, 'LUT Label', VR.kSH, VM.k1, false);
  static const PTag kRealWorldValueLastValueMapped
      //(0040,9211)
      = const PTag._('RealWorldValueLastValueMapped', 0x00409211,
          'Real World Value Last Value Mapped', VR.kUSSS, VM.k1, false);
  static const PTag kRealWorldValueLUTData
      //(0040,9212)
      = const PTag._('RealWorldValueLUTData', 0x00409212, 'Real World Value LUT Data',
          VR.kFD, VM.k1_n, false);
  static const PTag kRealWorldValueFirstValueMapped
      //(0040,9216)
      = const PTag._('RealWorldValueFirstValueMapped', 0x00409216,
          'Real World Value First Value Mapped', VR.kUSSS, VM.k1, false);
  static const PTag kRealWorldValueIntercept
      //(0040,9224)
      = const PTag._('RealWorldValueIntercept', 0x00409224, 'Real World Value Intercept',
          VR.kFD, VM.k1, false);
  static const PTag kRealWorldValueSlope
      //(0040,9225)
      = const PTag._('RealWorldValueSlope', 0x00409225, 'Real World Value Slope', VR.kFD,
          VM.k1, false);
  static const PTag kFindingsFlagTrial
      //(0040,A007)
      = const PTag._(
          'FindingsFlagTrial', 0x0040A007, 'Findings Flag (Trial)', VR.kCS, VM.k1, true);
  static const PTag kRelationshipType
      //(0040,A010)
      = const PTag._(
          'RelationshipType', 0x0040A010, 'Relationship Type', VR.kCS, VM.k1, false);
  static const PTag kFindingsSequenceTrial
      //(0040,A020)
      = const PTag._('FindingsSequenceTrial', 0x0040A020, 'Findings Sequence (Trial)',
          VR.kSQ, VM.k1, true);
  static const PTag kFindingsGroupUIDTrial
      //(0040,A021)
      = const PTag._('FindingsGroupUIDTrial', 0x0040A021, 'Findings Group UID (Trial)',
          VR.kUI, VM.k1, true);
  static const PTag kReferencedFindingsGroupUIDTrial
      //(0040,A022)
      = const PTag._('ReferencedFindingsGroupUIDTrial', 0x0040A022,
          'Referenced Findings Group UID (Trial)', VR.kUI, VM.k1, true);
  static const PTag kFindingsGroupRecordingDateTrial
      //(0040,A023)
      = const PTag._('FindingsGroupRecordingDateTrial', 0x0040A023,
          'Findings Group Recording Date (Trial)', VR.kDA, VM.k1, true);
  static const PTag kFindingsGroupRecordingTimeTrial
      //(0040,A024)
      = const PTag._('FindingsGroupRecordingTimeTrial', 0x0040A024,
          'Findings Group Recording Time (Trial)', VR.kTM, VM.k1, true);
  static const PTag kFindingsSourceCategoryCodeSequenceTrial
      //(0040,A026)
      = const PTag._('FindingsSourceCategoryCodeSequenceTrial', 0x0040A026,
          'Findings Source Category Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kVerifyingOrganization
      //(0040,A027)
      = const PTag._('VerifyingOrganization', 0x0040A027, 'Verifying Organization',
          VR.kLO, VM.k1, false);
  static const PTag kDocumentingOrganizationIdentifierCodeSequenceTrial
      //(0040,A028)
      = const PTag._(
          'DocumentingOrganizationIdentifierCodeSequenceTrial',
          0x0040A028,
          'Documenting Organization Identifier Code Sequence (Trial)',
          VR.kSQ,
          VM.k1,
          true);
  static const PTag kVerificationDateTime
      //(0040,A030)
      = const PTag._('VerificationDateTime', 0x0040A030, 'Verification DateTime', VR.kDT,
          VM.k1, false);
  static const PTag kObservationDateTime
      //(0040,A032)
      = const PTag._('ObservationDateTime', 0x0040A032, 'Observation DateTime', VR.kDT,
          VM.k1, false);
  static const PTag kValueType
      //(0040,A040)
      = const PTag._('ValueType', 0x0040A040, 'Value Type', VR.kCS, VM.k1, false);
  static const PTag kConceptNameCodeSequence
      //(0040,A043)
      = const PTag._('ConceptNameCodeSequence', 0x0040A043, 'Concept Name Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kMeasurementPrecisionDescriptionTrial
      //(0040,A047)
      = const PTag._('MeasurementPrecisionDescriptionTrial', 0x0040A047,
          'Measurement Precision Description (Trial)', VR.kLO, VM.k1, true);
  static const PTag kContinuityOfContent
      //(0040,A050)
      = const PTag._('ContinuityOfContent', 0x0040A050, 'Continuity Of Content', VR.kCS,
          VM.k1, false);
  static const PTag kUrgencyOrPriorityAlertsTrial
      //(0040,A057)
      = const PTag._('UrgencyOrPriorityAlertsTrial', 0x0040A057,
          'Urgency or Priority Alerts (Trial)', VR.kCS, VM.k1_n, true);
  static const PTag kSequencingIndicatorTrial
      //(0040,A060)
      = const PTag._('SequencingIndicatorTrial', 0x0040A060,
          'Sequencing Indicator (Trial)', VR.kLO, VM.k1, true);
  static const PTag kDocumentIdentifierCodeSequenceTrial
      //(0040,A066)
      = const PTag._('DocumentIdentifierCodeSequenceTrial', 0x0040A066,
          'Document Identifier Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kDocumentAuthorTrial
      //(0040,A067)
      = const PTag._('DocumentAuthorTrial', 0x0040A067, 'Document Author (Trial)', VR.kPN,
          VM.k1, true);
  static const PTag kDocumentAuthorIdentifierCodeSequenceTrial
      //(0040,A068)
      = const PTag._('DocumentAuthorIdentifierCodeSequenceTrial', 0x0040A068,
          'Document Author Identifier Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kIdentifierCodeSequenceTrial
      //(0040,A070)
      = const PTag._('IdentifierCodeSequenceTrial', 0x0040A070,
          'Identifier Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kVerifyingObserverSequence
      //(0040,A073)
      = const PTag._('VerifyingObserverSequence', 0x0040A073,
          'Verifying Observer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kObjectBinaryIdentifierTrial
      //(0040,A074)
      = const PTag._('ObjectBinaryIdentifierTrial', 0x0040A074,
          'Object Binary Identifier (Trial)', VR.kOB, VM.k1, true);
  static const PTag kVerifyingObserverName
      //(0040,A075)
      = const PTag._('VerifyingObserverName', 0x0040A075, 'Verifying Observer Name',
          VR.kPN, VM.k1, false);
  static const PTag kDocumentingObserverIdentifierCodeSequenceTrial
      //(0040,A076)
      = const PTag._('DocumentingObserverIdentifierCodeSequenceTrial', 0x0040A076,
          'Documenting Observer Identifier Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kAuthorObserverSequence
      //(0040,A078)
      = const PTag._('AuthorObserverSequence', 0x0040A078, 'Author Observer Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kParticipantSequence
      //(0040,A07A)
      = const PTag._('ParticipantSequence', 0x0040A07A, 'Participant Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kCustodialOrganizationSequence
      //(0040,A07C)
      = const PTag._('CustodialOrganizationSequence', 0x0040A07C,
          'Custodial Organization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kParticipationType
      //(0040,A080)
      = const PTag._(
          'ParticipationType', 0x0040A080, 'Participation Type', VR.kCS, VM.k1, false);
  static const PTag kParticipationDateTime
      //(0040,A082)
      = const PTag._('ParticipationDateTime', 0x0040A082, 'Participation DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kObserverType
      //(0040,A084)
      = const PTag._('ObserverType', 0x0040A084, 'Observer Type', VR.kCS, VM.k1, false);
  static const PTag kProcedureIdentifierCodeSequenceTrial
      //(0040,A085)
      = const PTag._('ProcedureIdentifierCodeSequenceTrial', 0x0040A085,
          'Procedure Identifier Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kVerifyingObserverIdentificationCodeSequence
      //(0040,A088)
      = const PTag._('VerifyingObserverIdentificationCodeSequence', 0x0040A088,
          'Verifying Observer Identification Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kObjectDirectoryBinaryIdentifierTrial
      //(0040,A089)
      = const PTag._('ObjectDirectoryBinaryIdentifierTrial', 0x0040A089,
          'Object Directory Binary Identifier (Trial)', VR.kOB, VM.k1, true);
  static const PTag kEquivalentCDADocumentSequence
      //(0040,A090)
      = const PTag._('EquivalentCDADocumentSequence', 0x0040A090,
          'Equivalent CDA Document Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedWaveformChannels
      //(0040,A0B0)
      = const PTag._('ReferencedWaveformChannels', 0x0040A0B0,
          'Referenced Waveform Channels', VR.kUS, VM.k2_2n, false);
  static const PTag kDateOfDocumentOrVerbalTransactionTrial
      //(0040,A110)
      = const PTag._('DateOfDocumentOrVerbalTransactionTrial', 0x0040A110,
          'Date of Document or Verbal Transaction (Trial)', VR.kDA, VM.k1, true);
  static const PTag kTimeOfDocumentCreationOrVerbalTransactionTrial
      //(0040,A112)
      = const PTag._('TimeOfDocumentCreationOrVerbalTransactionTrial', 0x0040A112,
          'Time of Document Creation or Verbal Transaction (Trial)', VR.kTM, VM.k1, true);
  static const PTag kDateTime
      //(0040,A120)
      = const PTag._('DateTime', 0x0040A120, 'DateTime', VR.kDT, VM.k1, false);
  static const PTag kDate
      //(0040,A121)
      = const PTag._('Date', 0x0040A121, 'Date', VR.kDA, VM.k1, false);
  static const PTag kTime
      //(0040,A122)
      = const PTag._('Time', 0x0040A122, 'Time', VR.kTM, VM.k1, false);
  static const PTag kPersonName
      //(0040,A123)
      = const PTag._('PersonName', 0x0040A123, 'Person Name', VR.kPN, VM.k1, false);
  static const PTag kUID
      //(0040,A124)
      = const PTag._('UID', 0x0040A124, 'UID', VR.kUI, VM.k1, false);
  static const PTag kReportStatusIDTrial
      //(0040,A125)
      = const PTag._('ReportStatusIDTrial', 0x0040A125, 'Report Status ID (Trial)',
          VR.kCS, VM.k2, true);
  static const PTag kTemporalRangeType
      //(0040,A130)
      = const PTag._(
          'TemporalRangeType', 0x0040A130, 'Temporal Range Type', VR.kCS, VM.k1, false);
  static const PTag kReferencedSamplePositions
      //(0040,A132)
      = const PTag._('ReferencedSamplePositions', 0x0040A132,
          'Referenced Sample Positions', VR.kUL, VM.k1_n, false);
  static const PTag kReferencedFrameNumbers
      //(0040,A136)
      = const PTag._('ReferencedFrameNumbers', 0x0040A136, 'Referenced Frame Numbers',
          VR.kUS, VM.k1_n, false);
  static const PTag kReferencedTimeOffsets
      //(0040,A138)
      = const PTag._('ReferencedTimeOffsets', 0x0040A138, 'Referenced Time Offsets',
          VR.kDS, VM.k1_n, false);
  static const PTag kReferencedDateTime
      //(0040,A13A)
      = const PTag._('ReferencedDateTime', 0x0040A13A, 'Referenced DateTime', VR.kDT,
          VM.k1_n, false);
  static const PTag kTextValue
      //(0040,A160)
      = const PTag._('TextValue', 0x0040A160, 'Text Value', VR.kUT, VM.k1, false);
  static const PTag kFloatingPointValue
      //(0040,A161)
      = const PTag._('FloatingPointValue', 0x0040A161, 'Floating Point Value', VR.kFD,
          VM.k1_n, false);
  static const PTag kRationalNumeratorValue
      //(0040,A162)
      = const PTag._('RationalNumeratorValue', 0x0040A162, 'Rational Numerator Value',
          VR.kSL, VM.k1_n, false);
  static const PTag kRationalDenominatorValue
      //(0040,A163)
      = const PTag._('RationalDenominatorValue', 0x0040A163, 'Rational Denominator Value',
          VR.kUL, VM.k1_n, false);
  static const PTag kObservationCategoryCodeSequenceTrial
      //(0040,A167)
      = const PTag._('ObservationCategoryCodeSequenceTrial', 0x0040A167,
          'Observation Category Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kConceptCodeSequence
      //(0040,A168)
      = const PTag._('ConceptCodeSequence', 0x0040A168, 'Concept Code Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kBibliographicCitationTrial
      //(0040,A16A)
      = const PTag._('BibliographicCitationTrial', 0x0040A16A,
          'Bibliographic Citation (Trial)', VR.kST, VM.k1, true);
  static const PTag kPurposeOfReferenceCodeSequence
      //(0040,A170)
      = const PTag._('PurposeOfReferenceCodeSequence', 0x0040A170,
          'Purpose of Reference Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kObservationUID
      //(0040,A171)
      =
      const PTag._('ObservationUID', 0x0040A171, 'Observation UID', VR.kUI, VM.k1, false);
  static const PTag kReferencedObservationUIDTrial
      //(0040,A172)
      = const PTag._('ReferencedObservationUIDTrial', 0x0040A172,
          'Referenced Observation UID (Trial)', VR.kUI, VM.k1, true);
  static const PTag kReferencedObservationClassTrial
      //(0040,A173)
      = const PTag._('ReferencedObservationClassTrial', 0x0040A173,
          'Referenced Observation Class (Trial)', VR.kCS, VM.k1, true);
  static const PTag kReferencedObjectObservationClassTrial
      //(0040,A174)
      = const PTag._('ReferencedObjectObservationClassTrial', 0x0040A174,
          'Referenced Object Observation Class (Trial)', VR.kCS, VM.k1, true);
  static const PTag kAnnotationGroupNumber
      //(0040,A180)
      = const PTag._('AnnotationGroupNumber', 0x0040A180, 'Annotation Group Number',
          VR.kUS, VM.k1, false);
  static const PTag kObservationDateTrial
      //(0040,A192)
      = const PTag._('ObservationDateTrial', 0x0040A192, 'Observation Date (Trial)',
          VR.kDA, VM.k1, true);
  static const PTag kObservationTimeTrial
      //(0040,A193)
      = const PTag._('ObservationTimeTrial', 0x0040A193, 'Observation Time (Trial)',
          VR.kTM, VM.k1, true);
  static const PTag kMeasurementAutomationTrial
      //(0040,A194)
      = const PTag._('MeasurementAutomationTrial', 0x0040A194,
          'Measurement Automation (Trial)', VR.kCS, VM.k1, true);
  static const PTag kModifierCodeSequence
      //(0040,A195)
      = const PTag._('ModifierCodeSequence', 0x0040A195, 'Modifier Code Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kIdentificationDescriptionTrial
      //(0040,A224)
      = const PTag._('IdentificationDescriptionTrial', 0x0040A224,
          'Identification Description (Trial)', VR.kST, VM.k1, true);
  static const PTag kCoordinatesSetGeometricTypeTrial
      //(0040,A290)
      = const PTag._('CoordinatesSetGeometricTypeTrial', 0x0040A290,
          'Coordinates Set Geometric Type (Trial)', VR.kCS, VM.k1, true);
  static const PTag kAlgorithmCodeSequenceTrial
      //(0040,A296)
      = const PTag._('AlgorithmCodeSequenceTrial', 0x0040A296,
          'Algorithm Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kAlgorithmDescriptionTrial
      //(0040,A297)
      = const PTag._('AlgorithmDescriptionTrial', 0x0040A297,
          'Algorithm Description (Trial)', VR.kST, VM.k1, true);
  static const PTag kPixelCoordinatesSetTrial
      //(0040,A29A)
      = const PTag._('PixelCoordinatesSetTrial', 0x0040A29A,
          'Pixel Coordinates Set (Trial)', VR.kSL, VM.k2_2n, true);
  static const PTag kMeasuredValueSequence
      //(0040,A300)
      = const PTag._('MeasuredValueSequence', 0x0040A300, 'Measured Value Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kNumericValueQualifierCodeSequence
      //(0040,A301)
      = const PTag._('NumericValueQualifierCodeSequence', 0x0040A301,
          'Numeric Value Qualifier Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCurrentObserverTrial
      //(0040,A307)
      = const PTag._('CurrentObserverTrial', 0x0040A307, 'Current Observer (Trial)',
          VR.kPN, VM.k1, true);
  static const PTag kNumericValue
      //(0040,A30A)
      = const PTag._('NumericValue', 0x0040A30A, 'Numeric Value', VR.kDS, VM.k1_n, false);
  static const PTag kReferencedAccessionSequenceTrial
      //(0040,A313)
      = const PTag._('ReferencedAccessionSequenceTrial', 0x0040A313,
          'Referenced Accession Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kReportStatusCommentTrial
      //(0040,A33A)
      = const PTag._('ReportStatusCommentTrial', 0x0040A33A,
          'Report Status Comment (Trial)', VR.kST, VM.k1, true);
  static const PTag kProcedureContextSequenceTrial
      //(0040,A340)
      = const PTag._('ProcedureContextSequenceTrial', 0x0040A340,
          'Procedure Context Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kVerbalSourceTrial
      //(0040,A352)
      = const PTag._(
          'VerbalSourceTrial', 0x0040A352, 'Verbal Source (Trial)', VR.kPN, VM.k1, true);
  static const PTag kAddressTrial
      //(0040,A353)
      = const PTag._('AddressTrial', 0x0040A353, 'Address (Trial)', VR.kST, VM.k1, true);
  static const PTag kTelephoneNumberTrial
      //(0040,A354)
      = const PTag._('TelephoneNumberTrial', 0x0040A354, 'Telephone Number (Trial)',
          VR.kLO, VM.k1, true);
  static const PTag kVerbalSourceIdentifierCodeSequenceTrial
      //(0040,A358)
      = const PTag._('VerbalSourceIdentifierCodeSequenceTrial', 0x0040A358,
          'Verbal Source Identifier Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kPredecessorDocumentsSequence
      //(0040,A360)
      = const PTag._('PredecessorDocumentsSequence', 0x0040A360,
          'Predecessor Documents Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedRequestSequence
      //(0040,A370)
      = const PTag._('ReferencedRequestSequence', 0x0040A370,
          'Referenced Request Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedProcedureCodeSequence
      //(0040,A372)
      = const PTag._('PerformedProcedureCodeSequence', 0x0040A372,
          'Performed Procedure Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCurrentRequestedProcedureEvidenceSequence
      //(0040,A375)
      = const PTag._('CurrentRequestedProcedureEvidenceSequence', 0x0040A375,
          'Current Requested Procedure Evidence Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReportDetailSequenceTrial
      //(0040,A380)
      = const PTag._('ReportDetailSequenceTrial', 0x0040A380,
          'Report Detail Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kPertinentOtherEvidenceSequence
      //(0040,A385)
      = const PTag._('PertinentOtherEvidenceSequence', 0x0040A385,
          'Pertinent Other Evidence Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHL7StructuredDocumentReferenceSequence
      //(0040,A390)
      = const PTag._('HL7StructuredDocumentReferenceSequence', 0x0040A390,
          'HL7 Structured Document Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kObservationSubjectUIDTrial
      //(0040,A402)
      = const PTag._('ObservationSubjectUIDTrial', 0x0040A402,
          'Observation Subject UID (Trial)', VR.kUI, VM.k1, true);
  static const PTag kObservationSubjectClassTrial
      //(0040,A403)
      = const PTag._('ObservationSubjectClassTrial', 0x0040A403,
          'Observation Subject Class (Trial)', VR.kCS, VM.k1, true);
  static const PTag kObservationSubjectTypeCodeSequenceTrial
      //(0040,A404)
      = const PTag._('ObservationSubjectTypeCodeSequenceTrial', 0x0040A404,
          'Observation Subject Type Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kCompletionFlag
      //(0040,A491)
      =
      const PTag._('CompletionFlag', 0x0040A491, 'Completion Flag', VR.kCS, VM.k1, false);
  static const PTag kCompletionFlagDescription
      //(0040,A492)
      = const PTag._('CompletionFlagDescription', 0x0040A492,
          'Completion Flag Description', VR.kLO, VM.k1, false);
  static const PTag kVerificationFlag
      //(0040,A493)
      = const PTag._(
          'VerificationFlag', 0x0040A493, 'Verification Flag', VR.kCS, VM.k1, false);
  static const PTag kArchiveRequested
      //(0040,A494)
      = const PTag._(
          'ArchiveRequested', 0x0040A494, 'Archive Requested', VR.kCS, VM.k1, false);
  static const PTag kPreliminaryFlag
      //(0040,A496)
      = const PTag._(
          'PreliminaryFlag', 0x0040A496, 'Preliminary Flag', VR.kCS, VM.k1, false);
  static const PTag kContentTemplateSequence
      //(0040,A504)
      = const PTag._('ContentTemplateSequence', 0x0040A504, 'Content Template Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kIdenticalDocumentsSequence
      //(0040,A525)
      = const PTag._('IdenticalDocumentsSequence', 0x0040A525,
          'Identical Documents Sequence', VR.kSQ, VM.k1, false);
  static const PTag kObservationSubjectContextFlagTrial
      //(0040,A600)
      = const PTag._('ObservationSubjectContextFlagTrial', 0x0040A600,
          'Observation Subject Context Flag (Trial)', VR.kCS, VM.k1, true);
  static const PTag kObserverContextFlagTrial
      //(0040,A601)
      = const PTag._('ObserverContextFlagTrial', 0x0040A601,
          'Observer Context Flag (Trial)', VR.kCS, VM.k1, true);
  static const PTag kProcedureContextFlagTrial
      //(0040,A603)
      = const PTag._('ProcedureContextFlagTrial', 0x0040A603,
          'Procedure Context Flag (Trial)', VR.kCS, VM.k1, true);
  static const PTag kContentSequence
      //(0040,A730)
      = const PTag._(
          'ContentSequence', 0x0040A730, 'Content Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRelationshipSequenceTrial
      //(0040,A731)
      = const PTag._('RelationshipSequenceTrial', 0x0040A731,
          'Relationship Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kRelationshipTypeCodeSequenceTrial
      //(0040,A732)
      = const PTag._('RelationshipTypeCodeSequenceTrial', 0x0040A732,
          'Relationship Type Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kLanguageCodeSequenceTrial
      //(0040,A744)
      = const PTag._('LanguageCodeSequenceTrial', 0x0040A744,
          'Language Code Sequence (Trial)', VR.kSQ, VM.k1, true);
  static const PTag kUniformResourceLocatorTrial
      //(0040,A992)
      = const PTag._('UniformResourceLocatorTrial', 0x0040A992,
          'Uniform Resource Locator (Trial)', VR.kST, VM.k1, true);
  static const PTag kWaveformAnnotationSequence
      //(0040,B020)
      = const PTag._('WaveformAnnotationSequence', 0x0040B020,
          'Waveform Annotation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTemplateIdentifier
      //(0040,DB00)
      = const PTag._(
          'TemplateIdentifier', 0x0040DB00, 'Template Identifier', VR.kCS, VM.k1, false);
  static const PTag kTemplateVersion
      //(0040,DB06)
      = const PTag._(
          'TemplateVersion', 0x0040DB06, 'Template Version', VR.kDT, VM.k1, true);
  static const PTag kTemplateLocalVersion
      //(0040,DB07)
      = const PTag._('TemplateLocalVersion', 0x0040DB07, 'Template Local Version', VR.kDT,
          VM.k1, true);
  static const PTag kTemplateExtensionFlag
      //(0040,DB0B)
      = const PTag._('TemplateExtensionFlag', 0x0040DB0B, 'Template Extension Flag',
          VR.kCS, VM.k1, true);
  static const PTag kTemplateExtensionOrganizationUID
      //(0040,DB0C)
      = const PTag._('TemplateExtensionOrganizationUID', 0x0040DB0C,
          'Template Extension Organization UID', VR.kUI, VM.k1, true);
  static const PTag kTemplateExtensionCreatorUID
      //(0040,DB0D)
      = const PTag._('TemplateExtensionCreatorUID', 0x0040DB0D,
          'Template Extension Creator UID', VR.kUI, VM.k1, true);
  static const PTag kReferencedContentItemIdentifier
      //(0040,DB73)
      = const PTag._('ReferencedContentItemIdentifier', 0x0040DB73,
          'Referenced Content Item Identifier', VR.kUL, VM.k1_n, false);
  static const PTag kHL7InstanceIdentifier
      //(0040,E001)
      = const PTag._('HL7InstanceIdentifier', 0x0040E001, 'HL7 Instance Identifier',
          VR.kST, VM.k1, false);
  static const PTag kHL7DocumentEffectiveTime
      //(0040,E004)
      = const PTag._('HL7DocumentEffectiveTime', 0x0040E004,
          'HL7 Document Effective Time', VR.kDT, VM.k1, false);
  static const PTag kHL7DocumentTypeCodeSequence
      //(0040,E006)
      = const PTag._('HL7DocumentTypeCodeSequence', 0x0040E006,
          'HL7 Document Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDocumentClassCodeSequence
      //(0040,E008)
      = const PTag._('DocumentClassCodeSequence', 0x0040E008,
          'Document Class Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRetrieveURI
      //(0040,E010)
      = const PTag._('RetrieveURI', 0x0040E010, 'Retrieve URI', VR.kUR, VM.k1, false);
  static const PTag kRetrieveLocationUID
      //(0040,E011)
      = const PTag._('RetrieveLocationUID', 0x0040E011, 'Retrieve Location UID', VR.kUI,
          VM.k1, false);
  static const PTag kTypeOfInstances
      //(0040,E020)
      = const PTag._(
          'TypeOfInstances', 0x0040E020, 'Type of Instances', VR.kCS, VM.k1, false);
  static const PTag kDICOMRetrievalSequence
      //(0040,E021)
      = const PTag._('DICOMRetrievalSequence', 0x0040E021, 'DICOM Retrieval Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kDICOMMediaRetrievalSequence
      //(0040,E022)
      = const PTag._('DICOMMediaRetrievalSequence', 0x0040E022,
          'DICOM Media Retrieval Sequence', VR.kSQ, VM.k1, false);
  static const PTag kWADORetrievalSequence
      //(0040,E023)
      = const PTag._('WADORetrievalSequence', 0x0040E023, 'WADO Retrieval Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kXDSRetrievalSequence
      //(0040,E024)
      = const PTag._('XDSRetrievalSequence', 0x0040E024, 'XDS Retrieval Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kRepositoryUniqueID
      //(0040,E030)
      = const PTag._(
          'RepositoryUniqueID', 0x0040E030, 'Repository Unique ID', VR.kUI, VM.k1, false);
  static const PTag kHomeCommunityID
      //(0040,E031)
      = const PTag._(
          'HomeCommunityID', 0x0040E031, 'Home Community ID', VR.kUI, VM.k1, false);
  static const PTag kDocumentTitle
      //(0042,0010)
      = const PTag._('DocumentTitle', 0x00420010, 'Document Title', VR.kST, VM.k1, false);
  static const PTag kEncapsulatedDocument
      //(0042,0011)
      = const PTag._('EncapsulatedDocument', 0x00420011, 'Encapsulated Document', VR.kOB,
          VM.k1, false);
  static const PTag kMIMETypeOfEncapsulatedDocument
      //(0042,0012)
      = const PTag._('MIMETypeOfEncapsulatedDocument', 0x00420012,
          'MIME Type of Encapsulated Document', VR.kLO, VM.k1, false);
  static const PTag kSourceInstanceSequence
      //(0042,0013)
      = const PTag._('SourceInstanceSequence', 0x00420013, 'Source Instance Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kListOfMIMETypes
      //(0042,0014)
      = const PTag._(
          'ListOfMIMETypes', 0x00420014, 'List of MIME Types', VR.kLO, VM.k1_n, false);
  static const PTag kProductPackageIdentifier
      //(0044,0001)
      = const PTag._('ProductPackageIdentifier', 0x00440001, 'Product Package Identifier',
          VR.kST, VM.k1, false);
  static const PTag kSubstanceAdministrationApproval
      //(0044,0002)
      = const PTag._('SubstanceAdministrationApproval', 0x00440002,
          'Substance Administration Approval', VR.kCS, VM.k1, false);
  static const PTag kApprovalStatusFurtherDescription
      //(0044,0003)
      = const PTag._('ApprovalStatusFurtherDescription', 0x00440003,
          'Approval Status Further Description', VR.kLT, VM.k1, false);
  static const PTag kApprovalStatusDateTime
      //(0044,0004)
      = const PTag._('ApprovalStatusDateTime', 0x00440004, 'Approval Status DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kProductTypeCodeSequence
      //(0044,0007)
      = const PTag._('ProductTypeCodeSequence', 0x00440007, 'Product Type Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kProductName
      //(0044,0008)
      = const PTag._('ProductName', 0x00440008, 'Product Name', VR.kLO, VM.k1_n, false);
  static const PTag kProductDescription
      //(0044,0009)
      = const PTag._(
          'ProductDescription', 0x00440009, 'Product Description', VR.kLT, VM.k1, false);
  static const PTag kProductLotIdentifier
      //(0044,000A)
      = const PTag._('ProductLotIdentifier', 0x0044000A, 'Product Lot Identifier', VR.kLO,
          VM.k1, false);
  static const PTag kProductExpirationDateTime
      //(0044,000B)
      = const PTag._('ProductExpirationDateTime', 0x0044000B,
          'Product Expiration DateTime', VR.kDT, VM.k1, false);
  static const PTag kSubstanceAdministrationDateTime
      //(0044,0010)
      = const PTag._('SubstanceAdministrationDateTime', 0x00440010,
          'Substance Administration DateTime', VR.kDT, VM.k1, false);
  static const PTag kSubstanceAdministrationNotes
      //(0044,0011)
      = const PTag._('SubstanceAdministrationNotes', 0x00440011,
          'Substance Administration Notes', VR.kLO, VM.k1, false);
  static const PTag kSubstanceAdministrationDeviceID
      //(0044,0012)
      = const PTag._('SubstanceAdministrationDeviceID', 0x00440012,
          'Substance Administration Device ID', VR.kLO, VM.k1, false);
  static const PTag kProductParameterSequence
      //(0044,0013)
      = const PTag._('ProductParameterSequence', 0x00440013, 'Product Parameter Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSubstanceAdministrationParameterSequence
      //(0044,0019)
      = const PTag._('SubstanceAdministrationParameterSequence', 0x00440019,
          'Substance Administration Parameter Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLensDescription
      //(0046,0012)
      = const PTag._(
          'LensDescription', 0x00460012, 'Lens Description', VR.kLO, VM.k1, false);
  static const PTag kRightLensSequence
      //(0046,0014)
      = const PTag._(
          'RightLensSequence', 0x00460014, 'Right Lens Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLeftLensSequence
      //(0046,0015)
      = const PTag._(
          'LeftLensSequence', 0x00460015, 'Left Lens Sequence', VR.kSQ, VM.k1, false);
  static const PTag kUnspecifiedLateralityLensSequence
      //(0046,0016)
      = const PTag._('UnspecifiedLateralityLensSequence', 0x00460016,
          'Unspecified Laterality Lens Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCylinderSequence
      //(0046,0018)
      = const PTag._(
          'CylinderSequence', 0x00460018, 'Cylinder Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrismSequence
      //(0046,0028)
      = const PTag._('PrismSequence', 0x00460028, 'Prism Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHorizontalPrismPower
      //(0046,0030)
      = const PTag._('HorizontalPrismPower', 0x00460030, 'Horizontal Prism Power', VR.kFD,
          VM.k1, false);
  static const PTag kHorizontalPrismBase
      //(0046,0032)
      = const PTag._('HorizontalPrismBase', 0x00460032, 'Horizontal Prism Base', VR.kCS,
          VM.k1, false);
  static const PTag kVerticalPrismPower
      //(0046,0034)
      = const PTag._(
          'VerticalPrismPower', 0x00460034, 'Vertical Prism Power', VR.kFD, VM.k1, false);
  static const PTag kVerticalPrismBase
      //(0046,0036)
      = const PTag._(
          'VerticalPrismBase', 0x00460036, 'Vertical Prism Base', VR.kCS, VM.k1, false);
  static const PTag kLensSegmentType
      //(0046,0038)
      = const PTag._(
          'LensSegmentType', 0x00460038, 'Lens Segment Type', VR.kCS, VM.k1, false);
  static const PTag kOpticalTransmittance
      //(0046,0040)
      = const PTag._('OpticalTransmittance', 0x00460040, 'Optical Transmittance', VR.kFD,
          VM.k1, false);
  static const PTag kChannelWidth
      //(0046,0042)
      = const PTag._('ChannelWidth', 0x00460042, 'Channel Width', VR.kFD, VM.k1, false);
  static const PTag kPupilSize
      //(0046,0044)
      = const PTag._('PupilSize', 0x00460044, 'Pupil Size', VR.kFD, VM.k1, false);
  static const PTag kCornealSize
      //(0046,0046)
      = const PTag._('CornealSize', 0x00460046, 'Corneal Size', VR.kFD, VM.k1, false);
  static const PTag kAutorefractionRightEyeSequence
      //(0046,0050)
      = const PTag._('AutorefractionRightEyeSequence', 0x00460050,
          'Autorefraction Right Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAutorefractionLeftEyeSequence
      //(0046,0052)
      = const PTag._('AutorefractionLeftEyeSequence', 0x00460052,
          'Autorefraction Left Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDistancePupillaryDistance
      //(0046,0060)
      = const PTag._('DistancePupillaryDistance', 0x00460060,
          'Distance Pupillary Distance', VR.kFD, VM.k1, false);
  static const PTag kNearPupillaryDistance
      //(0046,0062)
      = const PTag._('NearPupillaryDistance', 0x00460062, 'Near Pupillary Distance',
          VR.kFD, VM.k1, false);
  static const PTag kIntermediatePupillaryDistance
      //(0046,0063)
      = const PTag._('IntermediatePupillaryDistance', 0x00460063,
          'Intermediate Pupillary Distance', VR.kFD, VM.k1, false);
  static const PTag kOtherPupillaryDistance
      //(0046,0064)
      = const PTag._('OtherPupillaryDistance', 0x00460064, 'Other Pupillary Distance',
          VR.kFD, VM.k1, false);
  static const PTag kKeratometryRightEyeSequence
      //(0046,0070)
      = const PTag._('KeratometryRightEyeSequence', 0x00460070,
          'Keratometry Right Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kKeratometryLeftEyeSequence
      //(0046,0071)
      = const PTag._('KeratometryLeftEyeSequence', 0x00460071,
          'Keratometry Left Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSteepKeratometricAxisSequence
      //(0046,0074)
      = const PTag._('SteepKeratometricAxisSequence', 0x00460074,
          'Steep Keratometric Axis Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRadiusOfCurvature
      //(0046,0075)
      = const PTag._(
          'RadiusOfCurvature', 0x00460075, 'Radius of Curvature', VR.kFD, VM.k1, false);
  static const PTag kKeratometricPower
      //(0046,0076)
      = const PTag._(
          'KeratometricPower', 0x00460076, 'Keratometric Power', VR.kFD, VM.k1, false);
  static const PTag kKeratometricAxis
      //(0046,0077)
      = const PTag._(
          'KeratometricAxis', 0x00460077, 'Keratometric Axis', VR.kFD, VM.k1, false);
  static const PTag kFlatKeratometricAxisSequence
      //(0046,0080)
      = const PTag._('FlatKeratometricAxisSequence', 0x00460080,
          'Flat Keratometric Axis Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBackgroundColor
      //(0046,0092)
      = const PTag._(
          'BackgroundColor', 0x00460092, 'Background Color', VR.kCS, VM.k1, false);
  static const PTag kOptotype
      //(0046,0094)
      = const PTag._('Optotype', 0x00460094, 'Optotype', VR.kCS, VM.k1, false);
  static const PTag kOptotypePresentation
      //(0046,0095)
      = const PTag._('OptotypePresentation', 0x00460095, 'Optotype Presentation', VR.kCS,
          VM.k1, false);
  static const PTag kSubjectiveRefractionRightEyeSequence
      //(0046,0097)
      = const PTag._('SubjectiveRefractionRightEyeSequence', 0x00460097,
          'Subjective Refraction Right Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSubjectiveRefractionLeftEyeSequence
      //(0046,0098)
      = const PTag._('SubjectiveRefractionLeftEyeSequence', 0x00460098,
          'Subjective Refraction Left Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAddNearSequence
      //(0046,0100)
      = const PTag._(
          'AddNearSequence', 0x00460100, 'Add Near Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAddIntermediateSequence
      //(0046,0101)
      = const PTag._('AddIntermediateSequence', 0x00460101, 'Add Intermediate Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kAddOtherSequence
      //(0046,0102)
      = const PTag._(
          'AddOtherSequence', 0x00460102, 'Add Other Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAddPower
      //(0046,0104)
      = const PTag._('AddPower', 0x00460104, 'Add Power', VR.kFD, VM.k1, false);
  static const PTag kViewingDistance
      //(0046,0106)
      = const PTag._(
          'ViewingDistance', 0x00460106, 'Viewing Distance', VR.kFD, VM.k1, false);
  static const PTag kVisualAcuityTypeCodeSequence
      //(0046,0121)
      = const PTag._('VisualAcuityTypeCodeSequence', 0x00460121,
          'Visual Acuity Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualAcuityRightEyeSequence
      //(0046,0122)
      = const PTag._('VisualAcuityRightEyeSequence', 0x00460122,
          'Visual Acuity Right Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualAcuityLeftEyeSequence
      //(0046,0123)
      = const PTag._('VisualAcuityLeftEyeSequence', 0x00460123,
          'Visual Acuity Left Eye Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVisualAcuityBothEyesOpenSequence
      //(0046,0124)
      = const PTag._('VisualAcuityBothEyesOpenSequence', 0x00460124,
          'Visual Acuity Both Eyes Open Sequence', VR.kSQ, VM.k1, false);
  static const PTag kViewingDistanceType
      //(0046,0125)
      = const PTag._('ViewingDistanceType', 0x00460125, 'Viewing Distance Type', VR.kCS,
          VM.k1, false);
  static const PTag kVisualAcuityModifiers
      //(0046,0135)
      = const PTag._('VisualAcuityModifiers', 0x00460135, 'Visual Acuity Modifiers',
          VR.kSS, VM.k2, false);
  static const PTag kDecimalVisualAcuity
      //(0046,0137)
      = const PTag._('DecimalVisualAcuity', 0x00460137, 'Decimal Visual Acuity', VR.kFD,
          VM.k1, false);
  static const PTag kOptotypeDetailedDefinition
      //(0046,0139)
      = const PTag._('OptotypeDetailedDefinition', 0x00460139,
          'Optotype Detailed Definition', VR.kLO, VM.k1, false);
  static const PTag kReferencedRefractiveMeasurementsSequence
      //(0046,0145)
      = const PTag._('ReferencedRefractiveMeasurementsSequence', 0x00460145,
          'Referenced Refractive Measurements Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpherePower
      //(0046,0146)
      = const PTag._('SpherePower', 0x00460146, 'Sphere Power', VR.kFD, VM.k1, false);
  static const PTag kCylinderPower
      //(0046,0147)
      = const PTag._('CylinderPower', 0x00460147, 'Cylinder Power', VR.kFD, VM.k1, false);
  static const PTag kCornealTopographySurface
      //(0046,0201)
      = const PTag._('CornealTopographySurface', 0x00460201, 'Corneal Topography Surface',
          VR.kCS, VM.k1, false);
  static const PTag kCornealVertexLocation
      //(0046,0202)
      = const PTag._('CornealVertexLocation', 0x00460202, 'Corneal Vertex Location',
          VR.kFL, VM.k2, false);
  static const PTag kPupilCentroidXCoordinate
      //(0046,0203)
      = const PTag._('PupilCentroidXCoordinate', 0x00460203,
          'Pupil Centroid X-Coordinate', VR.kFL, VM.k1, false);
  static const PTag kPupilCentroidYCoordinate
      //(0046,0204)
      = const PTag._('PupilCentroidYCoordinate', 0x00460204,
          'Pupil Centroid Y-Coordinate', VR.kFL, VM.k1, false);
  static const PTag kEquivalentPupilRadius
      //(0046,0205)
      = const PTag._('EquivalentPupilRadius', 0x00460205, 'Equivalent Pupil Radius',
          VR.kFL, VM.k1, false);
  static const PTag kCornealTopographyMapTypeCodeSequence
      //(0046,0207)
      = const PTag._('CornealTopographyMapTypeCodeSequence', 0x00460207,
          'Corneal Topography Map Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVerticesOfTheOutlineOfPupil
      //(0046,0208)
      = const PTag._('VerticesOfTheOutlineOfPupil', 0x00460208,
          'Vertices of the Outline of Pupil', VR.kIS, VM.k2_2n, false);
  static const PTag kCornealTopographyMappingNormalsSequence
      //(0046,0210)
      = const PTag._('CornealTopographyMappingNormalsSequence', 0x00460210,
          'Corneal Topography Mapping Normals Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMaximumCornealCurvatureSequence
      //(0046,0211)
      = const PTag._('MaximumCornealCurvatureSequence', 0x00460211,
          'Maximum Corneal Curvature Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMaximumCornealCurvature
      //(0046,0212)
      = const PTag._('MaximumCornealCurvature', 0x00460212, 'Maximum Corneal Curvature',
          VR.kFL, VM.k1, false);
  static const PTag kMaximumCornealCurvatureLocation
      //(0046,0213)
      = const PTag._('MaximumCornealCurvatureLocation', 0x00460213,
          'Maximum Corneal Curvature Location', VR.kFL, VM.k2, false);
  static const PTag kMinimumKeratometricSequence
      //(0046,0215)
      = const PTag._('MinimumKeratometricSequence', 0x00460215,
          'Minimum Keratometric Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSimulatedKeratometricCylinderSequence
      //(0046,0218)
      = const PTag._('SimulatedKeratometricCylinderSequence', 0x00460218,
          'Simulated Keratometric Cylinder Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAverageCornealPower
      //(0046,0220)
      = const PTag._('AverageCornealPower', 0x00460220, 'Average Corneal Power', VR.kFL,
          VM.k1, false);
  static const PTag kCornealISValue
      //(0046,0224)
      = const PTag._(
          'CornealISValue', 0x00460224, 'Corneal I-S Value', VR.kFL, VM.k1, false);
  static const PTag kAnalyzedArea
      //(0046,0227)
      = const PTag._('AnalyzedArea', 0x00460227, 'Analyzed Area', VR.kFL, VM.k1, false);
  static const PTag kSurfaceRegularityIndex
      //(0046,0230)
      = const PTag._('SurfaceRegularityIndex', 0x00460230, 'Surface Regularity Index',
          VR.kFL, VM.k1, false);
  static const PTag kSurfaceAsymmetryIndex
      //(0046,0232)
      = const PTag._('SurfaceAsymmetryIndex', 0x00460232, 'Surface Asymmetry Index',
          VR.kFL, VM.k1, false);
  static const PTag kCornealEccentricityIndex
      //(0046,0234)
      = const PTag._('CornealEccentricityIndex', 0x00460234, 'Corneal Eccentricity Index',
          VR.kFL, VM.k1, false);
  static const PTag kKeratoconusPredictionIndex
      //(0046,0236)
      = const PTag._('KeratoconusPredictionIndex', 0x00460236,
          'Keratoconus Prediction Index', VR.kFL, VM.k1, false);
  static const PTag kDecimalPotentialVisualAcuity
      //(0046,0238)
      = const PTag._('DecimalPotentialVisualAcuity', 0x00460238,
          'Decimal Potential Visual Acuity', VR.kFL, VM.k1, false);
  static const PTag kCornealTopographyMapQualityEvaluation
      //(0046,0242)
      = const PTag._('CornealTopographyMapQualityEvaluation', 0x00460242,
          'Corneal Topography Map Quality Evaluation', VR.kCS, VM.k1, false);
  static const PTag kSourceImageCornealProcessedDataSequence
      //(0046,0244)
      = const PTag._('SourceImageCornealProcessedDataSequence', 0x00460244,
          'Source Image Corneal Processed Data Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCornealPointLocation
      //(0046,0247)
      = const PTag._('CornealPointLocation', 0x00460247, 'Corneal Point Location', VR.kFL,
          VM.k3, false);
  static const PTag kCornealPointEstimated
      //(0046,0248)
      = const PTag._('CornealPointEstimated', 0x00460248, 'Corneal Point Estimated',
          VR.kCS, VM.k1, false);
  static const PTag kAxialPower
      //(0046,0249)
      = const PTag._('AxialPower', 0x00460249, 'Axial Power', VR.kFL, VM.k1, false);
  static const PTag kTangentialPower
      //(0046,0250)
      = const PTag._(
          'TangentialPower', 0x00460250, 'Tangential Power', VR.kFL, VM.k1, false);
  static const PTag kRefractivePower
      //(0046,0251)
      = const PTag._(
          'RefractivePower', 0x00460251, 'Refractive Power', VR.kFL, VM.k1, false);
  static const PTag kRelativeElevation
      //(0046,0252)
      = const PTag._(
          'RelativeElevation', 0x00460252, 'Relative Elevation', VR.kFL, VM.k1, false);
  static const PTag kCornealWavefront
      //(0046,0253)
      = const PTag._(
          'CornealWavefront', 0x00460253, 'Corneal Wavefront', VR.kFL, VM.k1, false);
  static const PTag kImagedVolumeWidth
      //(0048,0001)
      = const PTag._(
          'ImagedVolumeWidth', 0x00480001, 'Imaged Volume Width', VR.kFL, VM.k1, false);
  static const PTag kImagedVolumeHeight
      //(0048,0002)
      = const PTag._(
          'ImagedVolumeHeight', 0x00480002, 'Imaged Volume Height', VR.kFL, VM.k1, false);
  static const PTag kImagedVolumeDepth
      //(0048,0003)
      = const PTag._(
          'ImagedVolumeDepth', 0x00480003, 'Imaged Volume Depth', VR.kFL, VM.k1, false);
  static const PTag kTotalPixelMatrixColumns
      //(0048,0006)
      = const PTag._('TotalPixelMatrixColumns', 0x00480006, 'Total Pixel Matrix Columns',
          VR.kUL, VM.k1, false);
  static const PTag kTotalPixelMatrixRows
      //(0048,0007)
      = const PTag._('TotalPixelMatrixRows', 0x00480007, 'Total Pixel Matrix Rows',
          VR.kUL, VM.k1, false);
  static const PTag kTotalPixelMatrixOriginSequence
      //(0048,0008)
      = const PTag._('TotalPixelMatrixOriginSequence', 0x00480008,
          'Total Pixel Matrix Origin Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenLabelInImage
      //(0048,0010)
      = const PTag._('SpecimenLabelInImage', 0x00480010, 'Specimen Label in Image',
          VR.kCS, VM.k1, false);
  static const PTag kFocusMethod
      //(0048,0011)
      = const PTag._('FocusMethod', 0x00480011, 'Focus Method', VR.kCS, VM.k1, false);
  static const PTag kExtendedDepthOfField
      //(0048,0012)
      = const PTag._('ExtendedDepthOfField', 0x00480012, 'Extended Depth of Field',
          VR.kCS, VM.k1, false);
  static const PTag kNumberOfFocalPlanes
      //(0048,0013)
      = const PTag._('NumberOfFocalPlanes', 0x00480013, 'Number of Focal Planes', VR.kUS,
          VM.k1, false);
  static const PTag kDistanceBetweenFocalPlanes
      //(0048,0014)
      = const PTag._('DistanceBetweenFocalPlanes', 0x00480014,
          'Distance Between Focal Planes', VR.kFL, VM.k1, false);
  static const PTag kRecommendedAbsentPixelCIELabValue
      //(0048,0015)
      = const PTag._('RecommendedAbsentPixelCIELabValue', 0x00480015,
          'Recommended Absent Pixel CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kIlluminatorTypeCodeSequence
      //(0048,0100)
      = const PTag._('IlluminatorTypeCodeSequence', 0x00480100,
          'Illuminator Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageOrientationSlide
      //(0048,0102)
      = const PTag._('ImageOrientationSlide', 0x00480102, 'Image Orientation (Slide)',
          VR.kDS, VM.k6, false);
  static const PTag kOpticalPathSequence
      //(0048,0105)
      = const PTag._('OpticalPathSequence', 0x00480105, 'Optical Path Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kOpticalPathIdentifier
      //(0048,0106)
      = const PTag._('OpticalPathIdentifier', 0x00480106, 'Optical Path Identifier',
          VR.kSH, VM.k1, false);
  static const PTag kOpticalPathDescription
      //(0048,0107)
      = const PTag._('OpticalPathDescription', 0x00480107, 'Optical Path Description',
          VR.kST, VM.k1, false);
  static const PTag kIlluminationColorCodeSequence
      //(0048,0108)
      = const PTag._('IlluminationColorCodeSequence', 0x00480108,
          'Illumination Color Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecimenReferenceSequence
      //(0048,0110)
      = const PTag._('SpecimenReferenceSequence', 0x00480110,
          'Specimen Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCondenserLensPower
      //(0048,0111)
      = const PTag._(
          'CondenserLensPower', 0x00480111, 'Condenser Lens Power', VR.kDS, VM.k1, false);
  static const PTag kObjectiveLensPower
      //(0048,0112)
      = const PTag._(
          'ObjectiveLensPower', 0x00480112, 'Objective Lens Power', VR.kDS, VM.k1, false);
  static const PTag kObjectiveLensNumericalAperture
      //(0048,0113)
      = const PTag._('ObjectiveLensNumericalAperture', 0x00480113,
          'Objective Lens Numerical Aperture', VR.kDS, VM.k1, false);
  static const PTag kPaletteColorLookupTableSequence
      //(0048,0120)
      = const PTag._('PaletteColorLookupTableSequence', 0x00480120,
          'Palette Color Lookup Table Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedImageNavigationSequence
      //(0048,0200)
      = const PTag._('ReferencedImageNavigationSequence', 0x00480200,
          'Referenced Image Navigation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTopLeftHandCornerOfLocalizerArea
      //(0048,0201)
      = const PTag._('TopLeftHandCornerOfLocalizerArea', 0x00480201,
          'Top Left Hand Corner of Localizer Area', VR.kUS, VM.k2, false);
  static const PTag kBottomRightHandCornerOfLocalizerArea
      //(0048,0202)
      = const PTag._('BottomRightHandCornerOfLocalizerArea', 0x00480202,
          'Bottom Right Hand Corner of Localizer Area', VR.kUS, VM.k2, false);
  static const PTag kOpticalPathIdentificationSequence
      //(0048,0207)
      = const PTag._('OpticalPathIdentificationSequence', 0x00480207,
          'Optical Path Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPlanePositionSlideSequence
      //(0048,021A)
      = const PTag._('PlanePositionSlideSequence', 0x0048021A,
          'Plane Position (Slide) Sequence', VR.kSQ, VM.k1, false);
  static const PTag kColumnPositionInTotalImagePixelMatrix
      //(0048,021E)
      = const PTag._('ColumnPositionInTotalImagePixelMatrix', 0x0048021E,
          'Column Position In Total Image Pixel Matrix', VR.kSL, VM.k1, false);
  static const PTag kRowPositionInTotalImagePixelMatrix
      //(0048,021F)
      = const PTag._('RowPositionInTotalImagePixelMatrix', 0x0048021F,
          'Row Position In Total Image Pixel Matrix', VR.kSL, VM.k1, false);
  static const PTag kPixelOriginInterpretation
      //(0048,0301)
      = const PTag._('PixelOriginInterpretation', 0x00480301,
          'Pixel Origin Interpretation', VR.kCS, VM.k1, false);
  static const PTag kCalibrationImage
      //(0050,0004)
      = const PTag._(
          'CalibrationImage', 0x00500004, 'Calibration Image', VR.kCS, VM.k1, false);
  static const PTag kDeviceSequence
      //(0050,0010)
      =
      const PTag._('DeviceSequence', 0x00500010, 'Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContainerComponentTypeCodeSequence
      //(0050,0012)
      = const PTag._('ContainerComponentTypeCodeSequence', 0x00500012,
          'Container Component Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContainerComponentThickness
      //(0050,0013)
      = const PTag._('ContainerComponentThickness', 0x00500013,
          'Container Component Thickness', VR.kFD, VM.k1, false);
  static const PTag kDeviceLength
      //(0050,0014)
      = const PTag._('DeviceLength', 0x00500014, 'Device Length', VR.kDS, VM.k1, false);
  static const PTag kContainerComponentWidth
      //(0050,0015)
      = const PTag._('ContainerComponentWidth', 0x00500015, 'Container Component Width',
          VR.kFD, VM.k1, false);
  static const PTag kDeviceDiameter
      //(0050,0016)
      =
      const PTag._('DeviceDiameter', 0x00500016, 'Device Diameter', VR.kDS, VM.k1, false);
  static const PTag kDeviceDiameterUnits
      //(0050,0017)
      = const PTag._('DeviceDiameterUnits', 0x00500017, 'Device Diameter Units', VR.kCS,
          VM.k1, false);
  static const PTag kDeviceVolume
      //(0050,0018)
      = const PTag._('DeviceVolume', 0x00500018, 'Device Volume', VR.kDS, VM.k1, false);
  static const PTag kInterMarkerDistance
      //(0050,0019)
      = const PTag._('InterMarkerDistance', 0x00500019, 'Inter-Marker Distance', VR.kDS,
          VM.k1, false);
  static const PTag kContainerComponentMaterial
      //(0050,001A)
      = const PTag._('ContainerComponentMaterial', 0x0050001A,
          'Container Component Material', VR.kCS, VM.k1, false);
  static const PTag kContainerComponentID
      //(0050,001B)
      = const PTag._('ContainerComponentID', 0x0050001B, 'Container Component ID', VR.kLO,
          VM.k1, false);
  static const PTag kContainerComponentLength
      //(0050,001C)
      = const PTag._('ContainerComponentLength', 0x0050001C, 'Container Component Length',
          VR.kFD, VM.k1, false);
  static const PTag kContainerComponentDiameter
      //(0050,001D)
      = const PTag._('ContainerComponentDiameter', 0x0050001D,
          'Container Component Diameter', VR.kFD, VM.k1, false);
  static const PTag kContainerComponentDescription
      //(0050,001E)
      = const PTag._('ContainerComponentDescription', 0x0050001E,
          'Container Component Description', VR.kLO, VM.k1, false);
  static const PTag kDeviceDescription
      //(0050,0020)
      = const PTag._(
          'DeviceDescription', 0x00500020, 'Device Description', VR.kLO, VM.k1, false);
  static const PTag kContrastBolusIngredientPercentByVolume
      //(0052,0001)
      = const PTag._('ContrastBolusIngredientPercentByVolume', 0x00520001,
          'Contrast/Bolus Ingredient Percent by Volume', VR.kFL, VM.k1, false);
  static const PTag kOCTFocalDistance
      //(0052,0002)
      = const PTag._(
          'OCTFocalDistance', 0x00520002, 'OCT Focal Distance', VR.kFD, VM.k1, false);
  static const PTag kBeamSpotSize
      //(0052,0003)
      = const PTag._('BeamSpotSize', 0x00520003, 'Beam Spot Size', VR.kFD, VM.k1, false);
  static const PTag kEffectiveRefractiveIndex
      //(0052,0004)
      = const PTag._('EffectiveRefractiveIndex', 0x00520004, 'Effective Refractive Index',
          VR.kFD, VM.k1, false);
  static const PTag kOCTAcquisitionDomain
      //(0052,0006)
      = const PTag._('OCTAcquisitionDomain', 0x00520006, 'OCT Acquisition Domain', VR.kCS,
          VM.k1, false);
  static const PTag kOCTOpticalCenterWavelength
      //(0052,0007)
      = const PTag._('OCTOpticalCenterWavelength', 0x00520007,
          'OCT Optical Center Wavelength', VR.kFD, VM.k1, false);
  static const PTag kAxialResolution
      //(0052,0008)
      = const PTag._(
          'AxialResolution', 0x00520008, 'Axial Resolution', VR.kFD, VM.k1, false);
  static const PTag kRangingDepth
      //(0052,0009)
      = const PTag._('RangingDepth', 0x00520009, 'Ranging Depth', VR.kFD, VM.k1, false);
  static const PTag kALineRate
      //(0052,0011)
      = const PTag._('ALineRate', 0x00520011, 'A-line Rate', VR.kFD, VM.k1, false);
  static const PTag kALinesPerFrame
      //(0052,0012)
      = const PTag._(
          'ALinesPerFrame', 0x00520012, 'A-lines Per Frame', VR.kUS, VM.k1, false);
  static const PTag kCatheterRotationalRate
      //(0052,0013)
      = const PTag._('CatheterRotationalRate', 0x00520013, 'Catheter Rotational Rate',
          VR.kFD, VM.k1, false);
  static const PTag kALinePixelSpacing
      //(0052,0014)
      = const PTag._(
          'ALinePixelSpacing', 0x00520014, 'A-line Pixel Spacing', VR.kFD, VM.k1, false);
  static const PTag kModeOfPercutaneousAccessSequence
      //(0052,0016)
      = const PTag._('ModeOfPercutaneousAccessSequence', 0x00520016,
          'Mode of Percutaneous Access Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIntravascularOCTFrameTypeSequence
      //(0052,0025)
      = const PTag._('IntravascularOCTFrameTypeSequence', 0x00520025,
          'Intravascular OCT Frame Type Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOCTZOffsetApplied
      //(0052,0026)
      = const PTag._(
          'OCTZOffsetApplied', 0x00520026, 'OCT Z Offset Applied', VR.kCS, VM.k1, false);
  static const PTag kIntravascularFrameContentSequence
      //(0052,0027)
      = const PTag._('IntravascularFrameContentSequence', 0x00520027,
          'Intravascular Frame Content Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIntravascularLongitudinalDistance
      //(0052,0028)
      = const PTag._('IntravascularLongitudinalDistance', 0x00520028,
          'Intravascular Longitudinal Distance', VR.kFD, VM.k1, false);
  static const PTag kIntravascularOCTFrameContentSequence
      //(0052,0029)
      = const PTag._('IntravascularOCTFrameContentSequence', 0x00520029,
          'Intravascular OCT Frame Content Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOCTZOffsetCorrection
      //(0052,0030)
      = const PTag._('OCTZOffsetCorrection', 0x00520030, 'OCT Z Offset Correction',
          VR.kSS, VM.k1, false);
  static const PTag kCatheterDirectionOfRotation
      //(0052,0031)
      = const PTag._('CatheterDirectionOfRotation', 0x00520031,
          'Catheter Direction of Rotation', VR.kCS, VM.k1, false);
  static const PTag kSeamLineLocation
      //(0052,0033)
      = const PTag._(
          'SeamLineLocation', 0x00520033, 'Seam Line Location', VR.kFD, VM.k1, false);
  static const PTag kFirstALineLocation
      //(0052,0034)
      = const PTag._('FirstALineLocation', 0x00520034, 'First A-line Location', VR.kFD,
          VM.k1, false);
  static const PTag kSeamLineIndex
      //(0052,0036)
      =
      const PTag._('SeamLineIndex', 0x00520036, 'Seam Line Index', VR.kUS, VM.k1, false);
  static const PTag kNumberOfPaddedALines
      //(0052,0038)
      = const PTag._('NumberOfPaddedALines', 0x00520038, 'Number of Padded A-lines',
          VR.kUS, VM.k1, false);
  static const PTag kInterpolationType
      //(0052,0039)
      = const PTag._(
          'InterpolationType', 0x00520039, 'Interpolation Type', VR.kCS, VM.k1, false);
  static const PTag kRefractiveIndexApplied
      //(0052,003A)
      = const PTag._('RefractiveIndexApplied', 0x0052003A, 'Refractive Index Applied',
          VR.kCS, VM.k1, false);
  static const PTag kEnergyWindowVector
      //(0054,0010)
      = const PTag._('EnergyWindowVector', 0x00540010, 'Energy Window Vector', VR.kUS,
          VM.k1_n, false);
  static const PTag kNumberOfEnergyWindows
      //(0054,0011)
      = const PTag._('NumberOfEnergyWindows', 0x00540011, 'Number of Energy Windows',
          VR.kUS, VM.k1, false);
  static const PTag kEnergyWindowInformationSequence
      //(0054,0012)
      = const PTag._('EnergyWindowInformationSequence', 0x00540012,
          'Energy Window Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEnergyWindowRangeSequence
      //(0054,0013)
      = const PTag._('EnergyWindowRangeSequence', 0x00540013,
          'Energy Window Range Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEnergyWindowLowerLimit
      //(0054,0014)
      = const PTag._('EnergyWindowLowerLimit', 0x00540014, 'Energy Window Lower Limit',
          VR.kDS, VM.k1, false);
  static const PTag kEnergyWindowUpperLimit
      //(0054,0015)
      = const PTag._('EnergyWindowUpperLimit', 0x00540015, 'Energy Window Upper Limit',
          VR.kDS, VM.k1, false);
  static const PTag kRadiopharmaceuticalInformationSequence
      //(0054,0016)
      = const PTag._('RadiopharmaceuticalInformationSequence', 0x00540016,
          'Radiopharmaceutical Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kResidualSyringeCounts
      //(0054,0017)
      = const PTag._('ResidualSyringeCounts', 0x00540017, 'Residual Syringe Counts',
          VR.kIS, VM.k1, false);
  static const PTag kEnergyWindowName
      //(0054,0018)
      = const PTag._(
          'EnergyWindowName', 0x00540018, 'Energy Window Name', VR.kSH, VM.k1, false);
  static const PTag kDetectorVector
      //(0054,0020)
      = const PTag._(
          'DetectorVector', 0x00540020, 'Detector Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfDetectors
      //(0054,0021)
      = const PTag._(
          'NumberOfDetectors', 0x00540021, 'Number of Detectors', VR.kUS, VM.k1, false);
  static const PTag kDetectorInformationSequence
      //(0054,0022)
      = const PTag._('DetectorInformationSequence', 0x00540022,
          'Detector Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPhaseVector
      //(0054,0030)
      = const PTag._('PhaseVector', 0x00540030, 'Phase Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfPhases
      //(0054,0031)
      = const PTag._(
          'NumberOfPhases', 0x00540031, 'Number of Phases', VR.kUS, VM.k1, false);
  static const PTag kPhaseInformationSequence
      //(0054,0032)
      = const PTag._('PhaseInformationSequence', 0x00540032, 'Phase Information Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kNumberOfFramesInPhase
      //(0054,0033)
      = const PTag._('NumberOfFramesInPhase', 0x00540033, 'Number of Frames in Phase',
          VR.kUS, VM.k1, false);
  static const PTag kPhaseDelay
      //(0054,0036)
      = const PTag._('PhaseDelay', 0x00540036, 'Phase Delay', VR.kIS, VM.k1, false);
  static const PTag kPauseBetweenFrames
      //(0054,0038)
      = const PTag._(
          'PauseBetweenFrames', 0x00540038, 'Pause Between Frames', VR.kIS, VM.k1, false);
  static const PTag kPhaseDescription
      //(0054,0039)
      = const PTag._(
          'PhaseDescription', 0x00540039, 'Phase Description', VR.kCS, VM.k1, false);
  static const PTag kRotationVector
      //(0054,0050)
      = const PTag._(
          'RotationVector', 0x00540050, 'Rotation Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfRotations
      //(0054,0051)
      = const PTag._(
          'NumberOfRotations', 0x00540051, 'Number of Rotations', VR.kUS, VM.k1, false);
  static const PTag kRotationInformationSequence
      //(0054,0052)
      = const PTag._('RotationInformationSequence', 0x00540052,
          'Rotation Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfFramesInRotation
      //(0054,0053)
      = const PTag._('NumberOfFramesInRotation', 0x00540053,
          'Number of Frames in Rotation', VR.kUS, VM.k1, false);
  static const PTag kRRIntervalVector
      //(0054,0060)
      = const PTag._(
          'RRIntervalVector', 0x00540060, 'R-R Interval Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfRRIntervals
      //(0054,0061)
      = const PTag._('NumberOfRRIntervals', 0x00540061, 'Number of R-R Intervals', VR.kUS,
          VM.k1, false);
  static const PTag kGatedInformationSequence
      //(0054,0062)
      = const PTag._('GatedInformationSequence', 0x00540062, 'Gated Information Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kDataInformationSequence
      //(0054,0063)
      = const PTag._('DataInformationSequence', 0x00540063, 'Data Information Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTimeSlotVector
      //(0054,0070)
      = const PTag._(
          'TimeSlotVector', 0x00540070, 'Time Slot Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfTimeSlots
      //(0054,0071)
      = const PTag._(
          'NumberOfTimeSlots', 0x00540071, 'Number of Time Slots', VR.kUS, VM.k1, false);
  static const PTag kTimeSlotInformationSequence
      //(0054,0072)
      = const PTag._('TimeSlotInformationSequence', 0x00540072,
          'Time Slot Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTimeSlotTime
      //(0054,0073)
      = const PTag._('TimeSlotTime', 0x00540073, 'Time Slot Time', VR.kDS, VM.k1, false);
  static const PTag kSliceVector
      //(0054,0080)
      = const PTag._('SliceVector', 0x00540080, 'Slice Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfSlices
      //(0054,0081)
      = const PTag._(
          'NumberOfSlices', 0x00540081, 'Number of Slices', VR.kUS, VM.k1, false);
  static const PTag kAngularViewVector
      //(0054,0090)
      = const PTag._(
          'AngularViewVector', 0x00540090, 'Angular View Vector', VR.kUS, VM.k1_n, false);
  static const PTag kTimeSliceVector
      //(0054,0100)
      = const PTag._(
          'TimeSliceVector', 0x00540100, 'Time Slice Vector', VR.kUS, VM.k1_n, false);
  static const PTag kNumberOfTimeSlices
      //(0054,0101)
      = const PTag._('NumberOfTimeSlices', 0x00540101, 'Number of Time Slices', VR.kUS,
          VM.k1, false);
  static const PTag kStartAngle
      //(0054,0200)
      = const PTag._('StartAngle', 0x00540200, 'Start Angle', VR.kDS, VM.k1, false);
  static const PTag kTypeOfDetectorMotion
      //(0054,0202)
      = const PTag._('TypeOfDetectorMotion', 0x00540202, 'Type of Detector Motion',
          VR.kCS, VM.k1, false);
  static const PTag kTriggerVector
      //(0054,0210)
      =
      const PTag._('TriggerVector', 0x00540210, 'Trigger Vector', VR.kIS, VM.k1_n, false);
  static const PTag kNumberOfTriggersInPhase
      //(0054,0211)
      = const PTag._('NumberOfTriggersInPhase', 0x00540211, 'Number of Triggers in Phase',
          VR.kUS, VM.k1, false);
  static const PTag kViewCodeSequence
      //(0054,0220)
      = const PTag._(
          'ViewCodeSequence', 0x00540220, 'View Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kViewModifierCodeSequence
      //(0054,0222)
      = const PTag._('ViewModifierCodeSequence', 0x00540222,
          'View Modifier Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRadionuclideCodeSequence
      //(0054,0300)
      = const PTag._('RadionuclideCodeSequence', 0x00540300, 'Radionuclide Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kAdministrationRouteCodeSequence
      //(0054,0302)
      = const PTag._('AdministrationRouteCodeSequence', 0x00540302,
          'Administration Route Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRadiopharmaceuticalCodeSequence
      //(0054,0304)
      = const PTag._('RadiopharmaceuticalCodeSequence', 0x00540304,
          'Radiopharmaceutical Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCalibrationDataSequence
      //(0054,0306)
      = const PTag._('CalibrationDataSequence', 0x00540306, 'Calibration Data Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kEnergyWindowNumber
      //(0054,0308)
      = const PTag._(
          'EnergyWindowNumber', 0x00540308, 'Energy Window Number', VR.kUS, VM.k1, false);
  static const PTag kImageID
      //(0054,0400)
      = const PTag._('ImageID', 0x00540400, 'Image ID', VR.kSH, VM.k1, false);
  static const PTag kPatientOrientationCodeSequence
      //(0054,0410)
      = const PTag._('PatientOrientationCodeSequence', 0x00540410,
          'Patient Orientation Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientOrientationModifierCodeSequence
      //(0054,0412)
      = const PTag._('PatientOrientationModifierCodeSequence', 0x00540412,
          'Patient Orientation Modifier Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPatientGantryRelationshipCodeSequence
      //(0054,0414)
      = const PTag._('PatientGantryRelationshipCodeSequence', 0x00540414,
          'Patient Gantry Relationship Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSliceProgressionDirection
      //(0054,0500)
      = const PTag._('SliceProgressionDirection', 0x00540500,
          'Slice Progression Direction', VR.kCS, VM.k1, false);
  static const PTag kSeriesType
      //(0054,1000)
      = const PTag._('SeriesType', 0x00541000, 'Series Type', VR.kCS, VM.k2, false);
  static const PTag kUnits
      //(0054,1001)
      = const PTag._('Units', 0x00541001, 'Units', VR.kCS, VM.k1, false);
  static const PTag kCountsSource
      //(0054,1002)
      = const PTag._('CountsSource', 0x00541002, 'Counts Source', VR.kCS, VM.k1, false);
  static const PTag kReprojectionMethod
      //(0054,1004)
      = const PTag._(
          'ReprojectionMethod', 0x00541004, 'Reprojection Method', VR.kCS, VM.k1, false);
  static const PTag kSUVType
      //(0054,1006)
      = const PTag._('SUVType', 0x00541006, 'SUV Type', VR.kCS, VM.k1, false);
  static const PTag kRandomsCorrectionMethod
      //(0054,1100)
      = const PTag._('RandomsCorrectionMethod', 0x00541100, 'Randoms Correction Method',
          VR.kCS, VM.k1, false);
  static const PTag kAttenuationCorrectionMethod
      //(0054,1101)
      = const PTag._('AttenuationCorrectionMethod', 0x00541101,
          'Attenuation Correction Method', VR.kLO, VM.k1, false);
  static const PTag kDecayCorrection
      //(0054,1102)
      = const PTag._(
          'DecayCorrection', 0x00541102, 'Decay Correction', VR.kCS, VM.k1, false);
  static const PTag kReconstructionMethod
      //(0054,1103)
      = const PTag._('ReconstructionMethod', 0x00541103, 'Reconstruction Method', VR.kLO,
          VM.k1, false);
  static const PTag kDetectorLinesOfResponseUsed
      //(0054,1104)
      = const PTag._('DetectorLinesOfResponseUsed', 0x00541104,
          'Detector Lines of Response Used', VR.kLO, VM.k1, false);
  static const PTag kScatterCorrectionMethod
      //(0054,1105)
      = const PTag._('ScatterCorrectionMethod', 0x00541105, 'Scatter Correction Method',
          VR.kLO, VM.k1, false);
  static const PTag kAxialAcceptance
      //(0054,1200)
      = const PTag._(
          'AxialAcceptance', 0x00541200, 'Axial Acceptance', VR.kDS, VM.k1, false);
  static const PTag kAxialMash
      //(0054,1201)
      = const PTag._('AxialMash', 0x00541201, 'Axial Mash', VR.kIS, VM.k2, false);
  static const PTag kTransverseMash
      //(0054,1202)
      =
      const PTag._('TransverseMash', 0x00541202, 'Transverse Mash', VR.kIS, VM.k1, false);
  static const PTag kDetectorElementSize
      //(0054,1203)
      = const PTag._('DetectorElementSize', 0x00541203, 'Detector Element Size', VR.kDS,
          VM.k2, false);
  static const PTag kCoincidenceWindowWidth
      //(0054,1210)
      = const PTag._('CoincidenceWindowWidth', 0x00541210, 'Coincidence Window Width',
          VR.kDS, VM.k1, false);
  static const PTag kSecondaryCountsType
      //(0054,1220)
      = const PTag._('SecondaryCountsType', 0x00541220, 'Secondary Counts Type', VR.kCS,
          VM.k1_n, false);
  static const PTag kFrameReferenceTime
      //(0054,1300)
      = const PTag._(
          'FrameReferenceTime', 0x00541300, 'Frame Reference Time', VR.kDS, VM.k1, false);
  static const PTag kPrimaryPromptsCountsAccumulated
      //(0054,1310)
      = const PTag._('PrimaryPromptsCountsAccumulated', 0x00541310,
          'Primary (Prompts) Counts Accumulated', VR.kIS, VM.k1, false);
  static const PTag kSecondaryCountsAccumulated
      //(0054,1311)
      = const PTag._('SecondaryCountsAccumulated', 0x00541311,
          'Secondary Counts Accumulated', VR.kIS, VM.k1_n, false);
  static const PTag kSliceSensitivityFactor
      //(0054,1320)
      = const PTag._('SliceSensitivityFactor', 0x00541320, 'Slice Sensitivity Factor',
          VR.kDS, VM.k1, false);
  static const PTag kDecayFactor
      //(0054,1321)
      = const PTag._('DecayFactor', 0x00541321, 'Decay Factor', VR.kDS, VM.k1, false);
  static const PTag kDoseCalibrationFactor
      //(0054,1322)
      = const PTag._('DoseCalibrationFactor', 0x00541322, 'Dose Calibration Factor',
          VR.kDS, VM.k1, false);
  static const PTag kScatterFractionFactor
      //(0054,1323)
      = const PTag._('ScatterFractionFactor', 0x00541323, 'Scatter Fraction Factor',
          VR.kDS, VM.k1, false);
  static const PTag kDeadTimeFactor
      //(0054,1324)
      = const PTag._(
          'DeadTimeFactor', 0x00541324, 'Dead Time Factor', VR.kDS, VM.k1, false);
  static const PTag kImageIndex
      //(0054,1330)
      = const PTag._('ImageIndex', 0x00541330, 'Image Index', VR.kUS, VM.k1, false);
  static const PTag kCountsIncluded
      //(0054,1400)
      = const PTag._(
          'CountsIncluded', 0x00541400, 'Counts Included', VR.kCS, VM.k1_n, true);
  static const PTag kDeadTimeCorrectionFlag
      //(0054,1401)
      = const PTag._('DeadTimeCorrectionFlag', 0x00541401, 'Dead Time Correction Flag',
          VR.kCS, VM.k1, true);
  static const PTag kHistogramSequence
      //(0060,3000)
      = const PTag._(
          'HistogramSequence', 0x00603000, 'Histogram Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHistogramNumberOfBins
      //(0060,3002)
      = const PTag._('HistogramNumberOfBins', 0x00603002, 'Histogram Number of Bins',
          VR.kUS, VM.k1, false);
  static const PTag kHistogramFirstBinValue
      //(0060,3004)
      = const PTag._('HistogramFirstBinValue', 0x00603004, 'Histogram First Bin Value',
          VR.kUSSS, VM.k1, false);
  static const PTag kHistogramLastBinValue
      //(0060,3006)
      = const PTag._('HistogramLastBinValue', 0x00603006, 'Histogram Last Bin Value',
          VR.kUSSS, VM.k1, false);
  static const PTag kHistogramBinWidth
      //(0060,3008)
      = const PTag._(
          'HistogramBinWidth', 0x00603008, 'Histogram Bin Width', VR.kUS, VM.k1, false);
  static const PTag kHistogramExplanation
      //(0060,3010)
      = const PTag._('HistogramExplanation', 0x00603010, 'Histogram Explanation', VR.kLO,
          VM.k1, false);
  static const PTag kHistogramData
      //(0060,3020)
      =
      const PTag._('HistogramData', 0x00603020, 'Histogram Data', VR.kUL, VM.k1_n, false);
  static const PTag kSegmentationType
      //(0062,0001)
      = const PTag._(
          'SegmentationType', 0x00620001, 'Segmentation Type', VR.kCS, VM.k1, false);
  static const PTag kSegmentSequence
      //(0062,0002)
      = const PTag._(
          'SegmentSequence', 0x00620002, 'Segment Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSegmentedPropertyCategoryCodeSequence
      //(0062,0003)
      = const PTag._('SegmentedPropertyCategoryCodeSequence', 0x00620003,
          'Segmented Property Category Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSegmentNumber
      //(0062,0004)
      = const PTag._('SegmentNumber', 0x00620004, 'Segment Number', VR.kUS, VM.k1, false);
  static const PTag kSegmentLabel
      //(0062,0005)
      = const PTag._('SegmentLabel', 0x00620005, 'Segment Label', VR.kLO, VM.k1, false);
  static const PTag kSegmentDescription
      //(0062,0006)
      = const PTag._(
          'SegmentDescription', 0x00620006, 'Segment Description', VR.kST, VM.k1, false);
  static const PTag kSegmentAlgorithmType
      //(0062,0008)
      = const PTag._('SegmentAlgorithmType', 0x00620008, 'Segment Algorithm Type', VR.kCS,
          VM.k1, false);
  static const PTag kSegmentAlgorithmName
      //(0062,0009)
      = const PTag._('SegmentAlgorithmName', 0x00620009, 'Segment Algorithm Name', VR.kLO,
          VM.k1, false);
  static const PTag kSegmentIdentificationSequence
      //(0062,000A)
      = const PTag._('SegmentIdentificationSequence', 0x0062000A,
          'Segment Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSegmentNumber
      //(0062,000B)
      = const PTag._('ReferencedSegmentNumber', 0x0062000B, 'Referenced Segment Number',
          VR.kUS, VM.k1_n, false);
  static const PTag kRecommendedDisplayGrayscaleValue
      //(0062,000C)
      = const PTag._('RecommendedDisplayGrayscaleValue', 0x0062000C,
          'Recommended Display Grayscale Value', VR.kUS, VM.k1, false);
  static const PTag kRecommendedDisplayCIELabValue
      //(0062,000D)
      = const PTag._('RecommendedDisplayCIELabValue', 0x0062000D,
          'Recommended Display CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kMaximumFractionalValue
      //(0062,000E)
      = const PTag._('MaximumFractionalValue', 0x0062000E, 'Maximum Fractional Value',
          VR.kUS, VM.k1, false);
  static const PTag kSegmentedPropertyTypeCodeSequence
      //(0062,000F)
      = const PTag._('SegmentedPropertyTypeCodeSequence', 0x0062000F,
          'Segmented Property Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSegmentationFractionalType
      //(0062,0010)
      = const PTag._('SegmentationFractionalType', 0x00620010,
          'Segmentation Fractional Type', VR.kCS, VM.k1, false);
  static const PTag kSegmentedPropertyTypeModifierCodeSequence
      //(0062,0011)
      = const PTag._('SegmentedPropertyTypeModifierCodeSequence', 0x00620011,
          'Segmented Property Type Modifier Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kUsedSegmentsSequence
      //(0062,0012)
      = const PTag._('UsedSegmentsSequence', 0x00620012, 'Used Segments Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kDeformableRegistrationSequence
      //(0064,0002)
      = const PTag._('DeformableRegistrationSequence', 0x00640002,
          'Deformable Registration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourceFrameOfReferenceUID
      //(0064,0003)
      = const PTag._('SourceFrameOfReferenceUID', 0x00640003,
          'Source Frame of Reference UID', VR.kUI, VM.k1, false);
  static const PTag kDeformableRegistrationGridSequence
      //(0064,0005)
      = const PTag._('DeformableRegistrationGridSequence', 0x00640005,
          'Deformable Registration Grid Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGridDimensions
      //(0064,0007)
      =
      const PTag._('GridDimensions', 0x00640007, 'Grid Dimensions', VR.kUL, VM.k3, false);
  static const PTag kGridResolution
      //(0064,0008)
      =
      const PTag._('GridResolution', 0x00640008, 'Grid Resolution', VR.kFD, VM.k3, false);
  static const PTag kVectorGridData
      //(0064,0009)
      = const PTag._(
          'VectorGridData', 0x00640009, 'Vector Grid Data', VR.kOF, VM.k1, false);
  static const PTag kPreDeformationMatrixRegistrationSequence
      //(0064,000F)
      = const PTag._('PreDeformationMatrixRegistrationSequence', 0x0064000F,
          'Pre Deformation Matrix Registration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPostDeformationMatrixRegistrationSequence
      //(0064,0010)
      = const PTag._('PostDeformationMatrixRegistrationSequence', 0x00640010,
          'Post Deformation Matrix Registration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfSurfaces
      //(0066,0001)
      = const PTag._(
          'NumberOfSurfaces', 0x00660001, 'Number of Surfaces', VR.kUL, VM.k1, false);
  static const PTag kSurfaceSequence
      //(0066,0002)
      = const PTag._(
          'SurfaceSequence', 0x00660002, 'Surface Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSurfaceNumber
      //(0066,0003)
      = const PTag._('SurfaceNumber', 0x00660003, 'Surface Number', VR.kUL, VM.k1, false);
  static const PTag kSurfaceComments
      //(0066,0004)
      = const PTag._(
          'SurfaceComments', 0x00660004, 'Surface Comments', VR.kLT, VM.k1, false);
  static const PTag kSurfaceProcessing
      //(0066,0009)
      = const PTag._(
          'SurfaceProcessing', 0x00660009, 'Surface Processing', VR.kCS, VM.k1, false);
  static const PTag kSurfaceProcessingRatio
      //(0066,000A)
      = const PTag._('SurfaceProcessingRatio', 0x0066000A, 'Surface Processing Ratio',
          VR.kFL, VM.k1, false);
  static const PTag kSurfaceProcessingDescription
      //(0066,000B)
      = const PTag._('SurfaceProcessingDescription', 0x0066000B,
          'Surface Processing Description', VR.kLO, VM.k1, false);
  static const PTag kRecommendedPresentationOpacity
      //(0066,000C)
      = const PTag._('RecommendedPresentationOpacity', 0x0066000C,
          'Recommended Presentation Opacity', VR.kFL, VM.k1, false);
  static const PTag kRecommendedPresentationType
      //(0066,000D)
      = const PTag._('RecommendedPresentationType', 0x0066000D,
          'Recommended Presentation Type', VR.kCS, VM.k1, false);
  static const PTag kFiniteVolume
      //(0066,000E)
      = const PTag._('FiniteVolume', 0x0066000E, 'Finite Volume', VR.kCS, VM.k1, false);
  static const PTag kManifold
      //(0066,0010)
      = const PTag._('Manifold', 0x00660010, 'Manifold', VR.kCS, VM.k1, false);
  static const PTag kSurfacePointsSequence
      //(0066,0011)
      = const PTag._('SurfacePointsSequence', 0x00660011, 'Surface Points Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSurfacePointsNormalsSequence
      //(0066,0012)
      = const PTag._('SurfacePointsNormalsSequence', 0x00660012,
          'Surface Points Normals Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSurfaceMeshPrimitivesSequence
      //(0066,0013)
      = const PTag._('SurfaceMeshPrimitivesSequence', 0x00660013,
          'Surface Mesh Primitives Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfSurfacePoints
      //(0066,0015)
      = const PTag._('NumberOfSurfacePoints', 0x00660015, 'Number of Surface Points',
          VR.kUL, VM.k1, false);
  static const PTag kPointCoordinatesData
      //(0066,0016)
      = const PTag._('PointCoordinatesData', 0x00660016, 'Point Coordinates Data', VR.kOF,
          VM.k1, false);
  static const PTag kPointPositionAccuracy
      //(0066,0017)
      = const PTag._('PointPositionAccuracy', 0x00660017, 'Point Position Accuracy',
          VR.kFL, VM.k3, false);
  static const PTag kMeanPointDistance
      //(0066,0018)
      = const PTag._(
          'MeanPointDistance', 0x00660018, 'Mean Point Distance', VR.kFL, VM.k1, false);
  static const PTag kMaximumPointDistance
      //(0066,0019)
      = const PTag._('MaximumPointDistance', 0x00660019, 'Maximum Point Distance', VR.kFL,
          VM.k1, false);
  static const PTag kPointsBoundingBoxCoordinates
      //(0066,001A)
      = const PTag._('PointsBoundingBoxCoordinates', 0x0066001A,
          'Points Bounding Box Coordinates', VR.kFL, VM.k6, false);
  static const PTag kAxisOfRotation
      //(0066,001B)
      = const PTag._(
          'AxisOfRotation', 0x0066001B, 'Axis of Rotation', VR.kFL, VM.k3, false);
  static const PTag kCenterOfRotation
      //(0066,001C)
      = const PTag._(
          'CenterOfRotation', 0x0066001C, 'Center of Rotation', VR.kFL, VM.k3, false);
  static const PTag kNumberOfVectors
      //(0066,001E)
      = const PTag._(
          'NumberOfVectors', 0x0066001E, 'Number of Vectors', VR.kUL, VM.k1, false);
  static const PTag kVectorDimensionality
      //(0066,001F)
      = const PTag._('VectorDimensionality', 0x0066001F, 'Vector Dimensionality', VR.kUS,
          VM.k1, false);
  static const PTag kVectorAccuracy
      //(0066,0020)
      = const PTag._(
          'VectorAccuracy', 0x00660020, 'Vector Accuracy', VR.kFL, VM.k1_n, false);
  static const PTag kVectorCoordinateData
      //(0066,0021)
      = const PTag._('VectorCoordinateData', 0x00660021, 'Vector Coordinate Data', VR.kOF,
          VM.k1, false);
  static const PTag kTrianglePointIndexList
      //(0066,0023)
      = const PTag._('TrianglePointIndexList', 0x00660023, 'Triangle Point Index List',
          VR.kOW, VM.k1, false);
  static const PTag kEdgePointIndexList
      //(0066,0024)
      = const PTag._('EdgePointIndexList', 0x00660024, 'Edge Point Index List', VR.kOW,
          VM.k1, false);
  static const PTag kVertexPointIndexList
      //(0066,0025)
      = const PTag._('VertexPointIndexList', 0x00660025, 'Vertex Point Index List',
          VR.kOW, VM.k1, false);
  static const PTag kTriangleStripSequence
      //(0066,0026)
      = const PTag._('TriangleStripSequence', 0x00660026, 'Triangle Strip Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTriangleFanSequence
      //(0066,0027)
      = const PTag._('TriangleFanSequence', 0x00660027, 'Triangle Fan Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kLineSequence
      //(0066,0028)
      = const PTag._('LineSequence', 0x00660028, 'Line Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrimitivePointIndexList
      //(0066,0029)
      = const PTag._('PrimitivePointIndexList', 0x00660029, 'Primitive Point Index List',
          VR.kOW, VM.k1, false);
  static const PTag kSurfaceCount
      //(0066,002A)
      = const PTag._('SurfaceCount', 0x0066002A, 'Surface Count', VR.kUL, VM.k1, false);
  static const PTag kReferencedSurfaceSequence
      //(0066,002B)
      = const PTag._('ReferencedSurfaceSequence', 0x0066002B,
          'Referenced Surface Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSurfaceNumber
      //(0066,002C)
      = const PTag._('ReferencedSurfaceNumber', 0x0066002C, 'Referenced Surface Number',
          VR.kUL, VM.k1, false);
  static const PTag kSegmentSurfaceGenerationAlgorithmIdentificationSequence
      //(0066,002D)
      = const PTag._(
          'SegmentSurfaceGenerationAlgorithmIdentificationSequence',
          0x0066002D,
          'Segment Surface Generation Algorithm Identification Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kSegmentSurfaceSourceInstanceSequence
      //(0066,002E)
      = const PTag._('SegmentSurfaceSourceInstanceSequence', 0x0066002E,
          'Segment Surface Source Instance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAlgorithmFamilyCodeSequence
      //(0066,002F)
      = const PTag._('AlgorithmFamilyCodeSequence', 0x0066002F,
          'Algorithm Family Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAlgorithmNameCodeSequence
      //(0066,0030)
      = const PTag._('AlgorithmNameCodeSequence', 0x00660030,
          'Algorithm Name Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAlgorithmVersion
      //(0066,0031)
      = const PTag._(
          'AlgorithmVersion', 0x00660031, 'Algorithm Version', VR.kLO, VM.k1, false);
  static const PTag kAlgorithmParameters
      //(0066,0032)
      = const PTag._('AlgorithmParameters', 0x00660032, 'Algorithm Parameters', VR.kLT,
          VM.k1, false);
  static const PTag kFacetSequence
      //(0066,0034)
      = const PTag._('FacetSequence', 0x00660034, 'Facet Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSurfaceProcessingAlgorithmIdentificationSequence
      //(0066,0035)
      = const PTag._('SurfaceProcessingAlgorithmIdentificationSequence', 0x00660035,
          'Surface Processing Algorithm Identification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAlgorithmName
      //(0066,0036)
      = const PTag._('AlgorithmName', 0x00660036, 'Algorithm Name', VR.kLO, VM.k1, false);
  static const PTag kRecommendedPointRadius
      //(0066,0037)
      = const PTag._('RecommendedPointRadius', 0x00660037, 'Recommended Point Radius',
          VR.kFL, VM.k1, false);
  static const PTag kRecommendedLineThickness
      //(0066,0038)
      = const PTag._('RecommendedLineThickness', 0x00660038, 'Recommended Line Thickness',
          VR.kFL, VM.k1, false);

  static const PTag kLongPrimitivePointIndexList = const PTag._(
      'LongPrimitivePointIndexList',
      0x00660040,
      'Long Primitive Point Index List',
      VR.kOL,
      VM.k1);
  static const PTag kLongTrianglePointIndexList = const PTag._(
      'LongTrianglePointIndexList',
      0x00660041,
      'Long Triangle Point Index List',
      VR.kOL,
      VM.k1);
  static const PTag kLongEdgePointIndexList = const PTag._(
      'LongEdgePointIndexList', 0x00660042, 'Long Edge Point Index List', VR.kOL, VM.k1);
  static const PTag kLongVertexPointIndexList = const PTag._('LongVertexPointIndexList',
      0x00660043, 'Long Vertex Point Index List', VR.kOL, VM.k1);
  static const PTag kTrackSetSequence =
      const PTag._('TrackSetSequence', 0x00660101, 'Track Set Sequence', VR.kSQ, VM.k1);
  static const PTag kTrackSequence =
      const PTag._('TrackSequence', 0x00660102, 'Track Sequence', VR.kSQ, VM.k1);
  static const PTag kRecommendedDisplayCIELabValueList = const PTag._(
      'RecommendedDisplayCIELabValueList',
      0x00660103,
      'Recommended Display CIELab Value List',
      VR.kOW,
      VM.k1);
  static const PTag kTrackingAlgorithmIdentificationSequence = const PTag._(
      'TrackingAlgorithmIdentificationSequence',
      0x00660104,
      'Tracking Algorithm Identification Sequence',
      VR.kSQ,
      VM.k1);
  static const PTag kTrackSetNumber =
      const PTag._('TrackSetNumber', 0x00660105, 'Track Set Number', VR.kUL, VM.k1);
  static const PTag kTrackSetLabel =
      const PTag._('TrackSetLabel', 0x00660106, 'Track Set Label', VR.kLO, VM.k1);
  static const PTag kTrackSetDescription = const PTag._(
      'TrackSetDescription', 0x00660107, 'Track Set Description', VR.kUT, VM.k1);
  static const PTag kTrackSetAnatomicalTypeCodeSequence = const PTag._(
      'TrackSetAnatomicalTypeCodeSequence',
      0x00660108,
      'Track Set Anatomical Type Code Sequence',
      VR.kSQ,
      VM.k1);
  static const PTag kMeasurementsSequence = const PTag._(
      'MeasurementsSequence', 0x00660121, 'Measurements Sequence', VR.kSQ, VM.k1);
  static const PTag kTrackSetStatisticsSequence = const PTag._(
      'TrackSetStatisticsSequence',
      0x00660124,
      'Track Set Statistics Sequence',
      VR.kSQ,
      VM.k1);
  static const PTag kFloatingPointValues = const PTag._(
      'FloatingPointValues', 0x00660125, 'Floating Point Values', VR.kOF, VM.k1);
  static const PTag kTrackPointIndexList = const PTag._(
      'TrackPointIndexList', 0x00660129, 'Track Point Index List', VR.kOL, VM.k1);
  static const PTag kTrackStatisticsSequence = const PTag._(
      'TrackStatisticsSequence', 0x00660130, 'Track Statistics Sequence', VR.kSQ, VM.k1);
  static const PTag kMeasurementValuesSequence = const PTag._('MeasurementValuesSequence',
      0x00660132, 'Measurement Values Sequence', VR.kSQ, VM.k1);
  static const PTag kDiffusionAcquisitionCodeSequence = const PTag._(
      'DiffusionAcquisitionCodeSequence',
      0x00660133,
      'Diffusion Acquisition Code Sequence',
      VR.kSQ,
      VM.k1);
  static const PTag kDiffusionModelCodeSequence = const PTag._(
      'DiffusionModelCodeSequence',
      0x00660134,
      'Diffusion Model Code Sequence',
      VR.kSQ,
      VM.k1);

  static const PTag kImplantSize
      //(0068,6210)
      = const PTag._('ImplantSize', 0x00686210, 'Implant Size', VR.kLO, VM.k1, false);
  static const PTag kImplantTemplateVersion
      //(0068,6221)
      = const PTag._('ImplantTemplateVersion', 0x00686221, 'Implant Template Version',
          VR.kLO, VM.k1, false);
  static const PTag kReplacedImplantTemplateSequence
      //(0068,6222)
      = const PTag._('ReplacedImplantTemplateSequence', 0x00686222,
          'Replaced Implant Template Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantType
      //(0068,6223)
      = const PTag._('ImplantType', 0x00686223, 'Implant Type', VR.kCS, VM.k1, false);
  static const PTag kDerivationImplantTemplateSequence
      //(0068,6224)
      = const PTag._('DerivationImplantTemplateSequence', 0x00686224,
          'Derivation Implant Template Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOriginalImplantTemplateSequence
      //(0068,6225)
      = const PTag._('OriginalImplantTemplateSequence', 0x00686225,
          'Original Implant Template Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEffectiveDateTime
      //(0068,6226)
      = const PTag._(
          'EffectiveDateTime', 0x00686226, 'Effective DateTime', VR.kDT, VM.k1, false);
  static const PTag kImplantTargetAnatomySequence
      //(0068,6230)
      = const PTag._('ImplantTargetAnatomySequence', 0x00686230,
          'Implant Target Anatomy Sequence', VR.kSQ, VM.k1, false);
  static const PTag kInformationFromManufacturerSequence
      //(0068,6260)
      = const PTag._('InformationFromManufacturerSequence', 0x00686260,
          'Information From Manufacturer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNotificationFromManufacturerSequence
      //(0068,6265)
      = const PTag._('NotificationFromManufacturerSequence', 0x00686265,
          'Notification From Manufacturer Sequence', VR.kSQ, VM.k1, false);
  static const PTag kInformationIssueDateTime
      //(0068,6270)
      = const PTag._('InformationIssueDateTime', 0x00686270, 'Information Issue DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kInformationSummary
      //(0068,6280)
      = const PTag._(
          'InformationSummary', 0x00686280, 'Information Summary', VR.kST, VM.k1, false);
  static const PTag kImplantRegulatoryDisapprovalCodeSequence
      //(0068,62A0)
      = const PTag._('ImplantRegulatoryDisapprovalCodeSequence', 0x006862A0,
          'Implant Regulatory Disapproval Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOverallTemplateSpatialTolerance
      //(0068,62A5)
      = const PTag._('OverallTemplateSpatialTolerance', 0x006862A5,
          'Overall Template Spatial Tolerance', VR.kFD, VM.k1, false);
  static const PTag kHPGLDocumentSequence
      //(0068,62C0)
      = const PTag._('HPGLDocumentSequence', 0x006862C0, 'HPGL Document Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kHPGLDocumentID
      //(0068,62D0)
      = const PTag._(
          'HPGLDocumentID', 0x006862D0, 'HPGL Document ID', VR.kUS, VM.k1, false);
  static const PTag kHPGLDocumentLabel
      //(0068,62D5)
      = const PTag._(
          'HPGLDocumentLabel', 0x006862D5, 'HPGL Document Label', VR.kLO, VM.k1, false);
  static const PTag kViewOrientationCodeSequence
      //(0068,62E0)
      = const PTag._('ViewOrientationCodeSequence', 0x006862E0,
          'View Orientation Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kViewOrientationModifier
      //(0068,62F0)
      = const PTag._('ViewOrientationModifier', 0x006862F0, 'View Orientation Modifier',
          VR.kFD, VM.k9, false);
  static const PTag kHPGLDocumentScaling
      //(0068,62F2)
      = const PTag._('HPGLDocumentScaling', 0x006862F2, 'HPGL Document Scaling', VR.kFD,
          VM.k1, false);
  static const PTag kHPGLDocument
      //(0068,6300)
      = const PTag._('HPGLDocument', 0x00686300, 'HPGL Document', VR.kOB, VM.k1, false);
  static const PTag kHPGLContourPenNumber
      //(0068,6310)
      = const PTag._('HPGLContourPenNumber', 0x00686310, 'HPGL Contour Pen Number',
          VR.kUS, VM.k1, false);
  static const PTag kHPGLPenSequence
      //(0068,6320)
      = const PTag._(
          'HPGLPenSequence', 0x00686320, 'HPGL Pen Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHPGLPenNumber
      //(0068,6330)
      =
      const PTag._('HPGLPenNumber', 0x00686330, 'HPGL Pen Number', VR.kUS, VM.k1, false);
  static const PTag kHPGLPenLabel
      //(0068,6340)
      = const PTag._('HPGLPenLabel', 0x00686340, 'HPGL Pen Label', VR.kLO, VM.k1, false);
  static const PTag kHPGLPenDescription
      //(0068,6345)
      = const PTag._(
          'HPGLPenDescription', 0x00686345, 'HPGL Pen Description', VR.kST, VM.k1, false);
  static const PTag kRecommendedRotationPoint
      //(0068,6346)
      = const PTag._('RecommendedRotationPoint', 0x00686346, 'Recommended Rotation Point',
          VR.kFD, VM.k2, false);
  static const PTag kBoundingRectangle
      //(0068,6347)
      = const PTag._(
          'BoundingRectangle', 0x00686347, 'Bounding Rectangle', VR.kFD, VM.k4, false);
  static const PTag kImplantTemplate3DModelSurfaceNumber
      //(0068,6350)
      = const PTag._('ImplantTemplate3DModelSurfaceNumber', 0x00686350,
          'Implant Template 3D Model Surface Number', VR.kUS, VM.k1_n, false);
  static const PTag kSurfaceModelDescriptionSequence
      //(0068,6360)
      = const PTag._('SurfaceModelDescriptionSequence', 0x00686360,
          'Surface Model Description Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSurfaceModelLabel
      //(0068,6380)
      = const PTag._(
          'SurfaceModelLabel', 0x00686380, 'Surface Model Label', VR.kLO, VM.k1, false);
  static const PTag kSurfaceModelScalingFactor
      //(0068,6390)
      = const PTag._('SurfaceModelScalingFactor', 0x00686390,
          'Surface Model Scaling Factor', VR.kFD, VM.k1, false);
  static const PTag kMaterialsCodeSequence
      //(0068,63A0)
      = const PTag._('MaterialsCodeSequence', 0x006863A0, 'Materials Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCoatingMaterialsCodeSequence
      //(0068,63A4)
      = const PTag._('CoatingMaterialsCodeSequence', 0x006863A4,
          'Coating Materials Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantTypeCodeSequence
      //(0068,63A8)
      = const PTag._('ImplantTypeCodeSequence', 0x006863A8, 'Implant Type Code Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kFixationMethodCodeSequence
      //(0068,63AC)
      = const PTag._('FixationMethodCodeSequence', 0x006863AC,
          'Fixation Method Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMatingFeatureSetsSequence
      //(0068,63B0)
      = const PTag._('MatingFeatureSetsSequence', 0x006863B0,
          'Mating Feature Sets Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMatingFeatureSetID
      //(0068,63C0)
      = const PTag._('MatingFeatureSetID', 0x006863C0, 'Mating Feature Set ID', VR.kUS,
          VM.k1, false);
  static const PTag kMatingFeatureSetLabel
      //(0068,63D0)
      = const PTag._('MatingFeatureSetLabel', 0x006863D0, 'Mating Feature Set Label',
          VR.kLO, VM.k1, false);
  static const PTag kMatingFeatureSequence
      //(0068,63E0)
      = const PTag._('MatingFeatureSequence', 0x006863E0, 'Mating Feature Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kMatingFeatureID
      //(0068,63F0)
      = const PTag._(
          'MatingFeatureID', 0x006863F0, 'Mating Feature ID', VR.kUS, VM.k1, false);
  static const PTag kMatingFeatureDegreeOfFreedomSequence
      //(0068,6400)
      = const PTag._('MatingFeatureDegreeOfFreedomSequence', 0x00686400,
          'Mating Feature Degree of Freedom Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDegreeOfFreedomID
      //(0068,6410)
      = const PTag._(
          'DegreeOfFreedomID', 0x00686410, 'Degree of Freedom ID', VR.kUS, VM.k1, false);
  static const PTag kDegreeOfFreedomType
      //(0068,6420)
      = const PTag._('DegreeOfFreedomType', 0x00686420, 'Degree of Freedom Type', VR.kCS,
          VM.k1, false);
  static const PTag kTwoDMatingFeatureCoordinatesSequence
      //(0068,6430)
      = const PTag._('TwoDMatingFeatureCoordinatesSequence', 0x00686430,
          '2D Mating Feature Coordinates Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedHPGLDocumentID
      //(0068,6440)
      = const PTag._('ReferencedHPGLDocumentID', 0x00686440,
          'Referenced HPGL Document ID', VR.kUS, VM.k1, false);
  static const PTag kTwoDMatingPoint
      //(0068,6450)
      = const PTag._(
          'TwoDMatingPoint', 0x00686450, '2D Mating Point', VR.kFD, VM.k2, false);
  static const PTag kTwoDMatingAxes
      //(0068,6460)
      =
      const PTag._('TwoDMatingAxes', 0x00686460, '2D Mating Axes', VR.kFD, VM.k4, false);
  static const PTag kTwoDDegreeOfFreedomSequence
      //(0068,6470)
      = const PTag._('TwoDDegreeOfFreedomSequence', 0x00686470,
          '2D Degree of Freedom Sequence', VR.kSQ, VM.k1, false);
  static const PTag kThreeDDegreeOfFreedomAxis
      //(0068,6490)
      = const PTag._('ThreeDDegreeOfFreedomAxis', 0x00686490, '3D Degree of Freedom Axis',
          VR.kFD, VM.k3, false);
  static const PTag kRangeOfFreedom
      //(0068,64A0)
      = const PTag._(
          'RangeOfFreedom', 0x006864A0, 'Range of Freedom', VR.kFD, VM.k2, false);
  static const PTag kThreeDMatingPoint
      //(0068,64C0)
      = const PTag._(
          'ThreeDMatingPoint', 0x006864C0, '3D Mating Point', VR.kFD, VM.k3, false);
  static const PTag kThreeDMatingAxes
      //(0068,64D0)
      = const PTag._(
          'ThreeDMatingAxes', 0x006864D0, '3D Mating Axes', VR.kFD, VM.k9, false);
  static const PTag kTwoDDegreeOfFreedomAxis
      //(0068,64F0)
      = const PTag._('TwoDDegreeOfFreedomAxis', 0x006864F0, '2D Degree of Freedom Axis',
          VR.kFD, VM.k3, false);
  static const PTag kPlanningLandmarkPointSequence
      //(0068,6500)
      = const PTag._('PlanningLandmarkPointSequence', 0x00686500,
          'Planning Landmark Point Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPlanningLandmarkLineSequence
      //(0068,6510)
      = const PTag._('PlanningLandmarkLineSequence', 0x00686510,
          'Planning Landmark Line Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPlanningLandmarkPlaneSequence
      //(0068,6520)
      = const PTag._('PlanningLandmarkPlaneSequence', 0x00686520,
          'Planning Landmark Plane Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPlanningLandmarkID
      //(0068,6530)
      = const PTag._(
          'PlanningLandmarkID', 0x00686530, 'Planning Landmark ID', VR.kUS, VM.k1, false);
  static const PTag kPlanningLandmarkDescription
      //(0068,6540)
      = const PTag._('PlanningLandmarkDescription', 0x00686540,
          'Planning Landmark Description', VR.kLO, VM.k1, false);
  static const PTag kPlanningLandmarkIdentificationCodeSequence
      //(0068,6545)
      = const PTag._('PlanningLandmarkIdentificationCodeSequence', 0x00686545,
          'Planning Landmark Identification Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTwoDPointCoordinatesSequence
      //(0068,6550)
      = const PTag._('TwoDPointCoordinatesSequence', 0x00686550,
          '2D Point Coordinates Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTwoDPointCoordinates
      //(0068,6560)
      = const PTag._('TwoDPointCoordinates', 0x00686560, '2D Point Coordinates', VR.kFD,
          VM.k2, false);
  static const PTag kThreeDPointCoordinates
      //(0068,6590)
      = const PTag._('ThreeDPointCoordinates', 0x00686590, '3D Point Coordinates', VR.kFD,
          VM.k3, false);
  static const PTag kTwoDLineCoordinatesSequence
      //(0068,65A0)
      = const PTag._('TwoDLineCoordinatesSequence', 0x006865A0,
          '2D Line Coordinates Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTwoDLineCoordinates
      //(0068,65B0)
      = const PTag._(
          'TwoDLineCoordinates', 0x006865B0, '2D Line Coordinates', VR.kFD, VM.k4, false);
  static const PTag kThreeDLineCoordinates
      //(0068,65D0)
      = const PTag._('ThreeDLineCoordinates', 0x006865D0, '3D Line Coordinates', VR.kFD,
          VM.k6, false);
  static const PTag kTwoDPlaneCoordinatesSequence
      //(0068,65E0)
      = const PTag._('TwoDPlaneCoordinatesSequence', 0x006865E0,
          '2D Plane Coordinates Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTwoDPlaneIntersection
      //(0068,65F0)
      = const PTag._('TwoDPlaneIntersection', 0x006865F0, '2D Plane Intersection', VR.kFD,
          VM.k4, false);
  static const PTag kThreeDPlaneOrigin
      //(0068,6610)
      = const PTag._(
          'ThreeDPlaneOrigin', 0x00686610, '3D Plane Origin', VR.kFD, VM.k3, false);
  static const PTag kThreeDPlaneNormal
      //(0068,6620)
      = const PTag._(
          'ThreeDPlaneNormal', 0x00686620, '3D Plane Normal', VR.kFD, VM.k3, false);
  static const PTag kGraphicAnnotationSequence
      //(0070,0001)
      = const PTag._('GraphicAnnotationSequence', 0x00700001,
          'Graphic Annotation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGraphicLayer
      //(0070,0002)
      = const PTag._('GraphicLayer', 0x00700002, 'Graphic Layer', VR.kCS, VM.k1, false);
  static const PTag kBoundingBoxAnnotationUnits
      //(0070,0003)
      = const PTag._('BoundingBoxAnnotationUnits', 0x00700003,
          'Bounding Box Annotation Units', VR.kCS, VM.k1, false);
  static const PTag kAnchorPointAnnotationUnits
      //(0070,0004)
      = const PTag._('AnchorPointAnnotationUnits', 0x00700004,
          'Anchor Point Annotation Units', VR.kCS, VM.k1, false);
  static const PTag kGraphicAnnotationUnits
      //(0070,0005)
      = const PTag._('GraphicAnnotationUnits', 0x00700005, 'Graphic Annotation Units',
          VR.kCS, VM.k1, false);
  static const PTag kUnformattedTextValue
      //(0070,0006)
      = const PTag._('UnformattedTextValue', 0x00700006, 'Unformatted Text Value', VR.kST,
          VM.k1, false);
  static const PTag kTextObjectSequence
      //(0070,0008)
      = const PTag._(
          'TextObjectSequence', 0x00700008, 'Text Object Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGraphicObjectSequence
      //(0070,0009)
      = const PTag._('GraphicObjectSequence', 0x00700009, 'Graphic Object Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kBoundingBoxTopLeftHandCorner
      //(0070,0010)
      = const PTag._('BoundingBoxTopLeftHandCorner', 0x00700010,
          'Bounding Box Top Left Hand Corner', VR.kFL, VM.k2, false);
  static const PTag kBoundingBoxBottomRightHandCorner
      //(0070,0011)
      = const PTag._('BoundingBoxBottomRightHandCorner', 0x00700011,
          'Bounding Box Bottom Right Hand Corner', VR.kFL, VM.k2, false);
  static const PTag kBoundingBoxTextHorizontalJustification
      //(0070,0012)
      = const PTag._('BoundingBoxTextHorizontalJustification', 0x00700012,
          'Bounding Box Text Horizontal Justification', VR.kCS, VM.k1, false);
  static const PTag kAnchorPoint
      //(0070,0014)
      = const PTag._('AnchorPoint', 0x00700014, 'Anchor Point', VR.kFL, VM.k2, false);
  static const PTag kAnchorPointVisibility
      //(0070,0015)
      = const PTag._('AnchorPointVisibility', 0x00700015, 'Anchor Point Visibility',
          VR.kCS, VM.k1, false);
  static const PTag kGraphicDimensions
      //(0070,0020)
      = const PTag._(
          'GraphicDimensions', 0x00700020, 'Graphic Dimensions', VR.kUS, VM.k1, false);
  static const PTag kNumberOfGraphicPoints
      //(0070,0021)
      = const PTag._('NumberOfGraphicPoints', 0x00700021, 'Number of Graphic Points',
          VR.kUS, VM.k1, false);
  static const PTag kGraphicData
      //(0070,0022)
      = const PTag._('GraphicData', 0x00700022, 'Graphic Data', VR.kFL, VM.k2_n, false);
  static const PTag kGraphicType
      //(0070,0023)
      = const PTag._('GraphicType', 0x00700023, 'Graphic Type', VR.kCS, VM.k1, false);
  static const PTag kGraphicFilled
      //(0070,0024)
      = const PTag._('GraphicFilled', 0x00700024, 'Graphic Filled', VR.kCS, VM.k1, false);
  static const PTag kImageRotationRetired
      //(0070,0040)
      = const PTag._('ImageRotationRetired', 0x00700040, 'Image Rotation (Retired)',
          VR.kIS, VM.k1, true);
  static const PTag kImageHorizontalFlip
      //(0070,0041)
      = const PTag._('ImageHorizontalFlip', 0x00700041, 'Image Horizontal Flip', VR.kCS,
          VM.k1, false);
  static const PTag kImageRotation
      //(0070,0042)
      = const PTag._('ImageRotation', 0x00700042, 'Image Rotation', VR.kUS, VM.k1, false);
  static const PTag kDisplayedAreaTopLeftHandCornerTrial
      //(0070,0050)
      = const PTag._('DisplayedAreaTopLeftHandCornerTrial', 0x00700050,
          'Displayed Area Top Left Hand Corner (Trial)', VR.kUS, VM.k2, true);
  static const PTag kDisplayedAreaBottomRightHandCornerTrial
      //(0070,0051)
      = const PTag._('DisplayedAreaBottomRightHandCornerTrial', 0x00700051,
          'Displayed Area Bottom Right Hand Corner (Trial)', VR.kUS, VM.k2, true);
  static const PTag kDisplayedAreaTopLeftHandCorner
      //(0070,0052)
      = const PTag._('DisplayedAreaTopLeftHandCorner', 0x00700052,
          'Displayed Area Top Left Hand Corner', VR.kSL, VM.k2, false);
  static const PTag kDisplayedAreaBottomRightHandCorner
      //(0070,0053)
      = const PTag._('DisplayedAreaBottomRightHandCorner', 0x00700053,
          'Displayed Area Bottom Right Hand Corner', VR.kSL, VM.k2, false);
  static const PTag kDisplayedAreaSelectionSequence
      //(0070,005A)
      = const PTag._('DisplayedAreaSelectionSequence', 0x0070005A,
          'Displayed Area Selection Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGraphicLayerSequence
      //(0070,0060)
      = const PTag._('GraphicLayerSequence', 0x00700060, 'Graphic Layer Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kGraphicLayerOrder
      //(0070,0062)
      = const PTag._(
          'GraphicLayerOrder', 0x00700062, 'Graphic Layer Order', VR.kIS, VM.k1, false);
  static const PTag kGraphicLayerRecommendedDisplayGrayscaleValue
      //(0070,0066)
      = const PTag._('GraphicLayerRecommendedDisplayGrayscaleValue', 0x00700066,
          'Graphic Layer Recommended Display Grayscale Value', VR.kUS, VM.k1, false);
  static const PTag kGraphicLayerRecommendedDisplayRGBValue
      //(0070,0067)
      = const PTag._('GraphicLayerRecommendedDisplayRGBValue', 0x00700067,
          'Graphic Layer Recommended Display RGB Value', VR.kUS, VM.k3, true);
  static const PTag kGraphicLayerDescription
      //(0070,0068)
      = const PTag._('GraphicLayerDescription', 0x00700068, 'Graphic Layer Description',
          VR.kLO, VM.k1, false);
  static const PTag kContentLabel
      //(0070,0080)
      = const PTag._('ContentLabel', 0x00700080, 'Content Label', VR.kCS, VM.k1, false);
  static const PTag kContentDescription
      //(0070,0081)
      = const PTag._(
          'ContentDescription', 0x00700081, 'Content Description', VR.kLO, VM.k1, false);
  static const PTag kPresentationCreationDate
      //(0070,0082)
      = const PTag._('PresentationCreationDate', 0x00700082, 'Presentation Creation Date',
          VR.kDA, VM.k1, false);
  static const PTag kPresentationCreationTime
      //(0070,0083)
      = const PTag._('PresentationCreationTime', 0x00700083, 'Presentation Creation Time',
          VR.kTM, VM.k1, false);
  static const PTag kContentCreatorName
      //(0070,0084)
      = const PTag._('ContentCreatorName', 0x00700084, 'Content Creator\'s Name', VR.kPN,
          VM.k1, false);
  static const PTag kContentCreatorIdentificationCodeSequence
      //(0070,0086)
      = const PTag._('ContentCreatorIdentificationCodeSequence', 0x00700086,
          'Content Creator\'s Identification Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAlternateContentDescriptionSequence
      //(0070,0087)
      = const PTag._('AlternateContentDescriptionSequence', 0x00700087,
          'Alternate Content Description Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPresentationSizeMode
      //(0070,0100)
      = const PTag._('PresentationSizeMode', 0x00700100, 'Presentation Size Mode', VR.kCS,
          VM.k1, false);
  static const PTag kPresentationPixelSpacing
      //(0070,0101)
      = const PTag._('PresentationPixelSpacing', 0x00700101, 'Presentation Pixel Spacing',
          VR.kDS, VM.k2, false);
  static const PTag kPresentationPixelAspectRatio
      //(0070,0102)
      = const PTag._('PresentationPixelAspectRatio', 0x00700102,
          'Presentation Pixel Aspect Ratio', VR.kIS, VM.k2, false);
  static const PTag kPresentationPixelMagnificationRatio
      //(0070,0103)
      = const PTag._('PresentationPixelMagnificationRatio', 0x00700103,
          'Presentation Pixel Magnification Ratio', VR.kFL, VM.k1, false);
  static const PTag kGraphicGroupLabel
      //(0070,0207)
      = const PTag._(
          'GraphicGroupLabel', 0x00700207, 'Graphic Group Label', VR.kLO, VM.k1, false);
  static const PTag kGraphicGroupDescription
      //(0070,0208)
      = const PTag._('GraphicGroupDescription', 0x00700208, 'Graphic Group Description',
          VR.kST, VM.k1, false);
  static const PTag kCompoundGraphicSequence
      //(0070,0209)
      = const PTag._('CompoundGraphicSequence', 0x00700209, 'Compound Graphic Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCompoundGraphicInstanceID
      //(0070,0226)
      = const PTag._('CompoundGraphicInstanceID', 0x00700226,
          'Compound Graphic Instance ID', VR.kUL, VM.k1, false);
  static const PTag kFontName
      //(0070,0227)
      = const PTag._('FontName', 0x00700227, 'Font Name', VR.kLO, VM.k1, false);
  static const PTag kFontNameType
      //(0070,0228)
      = const PTag._('FontNameType', 0x00700228, 'Font Name Type', VR.kCS, VM.k1, false);
  static const PTag kCSSFontName
      //(0070,0229)
      = const PTag._('CSSFontName', 0x00700229, 'CSS Font Name', VR.kLO, VM.k1, false);
  static const PTag kRotationAngle
      //(0070,0230)
      = const PTag._('RotationAngle', 0x00700230, 'Rotation Angle', VR.kFD, VM.k1, false);
  static const PTag kTextStyleSequence
      //(0070,0231)
      = const PTag._(
          'TextStyleSequence', 0x00700231, 'Text Style Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLineStyleSequence
      //(0070,0232)
      = const PTag._(
          'LineStyleSequence', 0x00700232, 'Line Style Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFillStyleSequence
      //(0070,0233)
      = const PTag._(
          'FillStyleSequence', 0x00700233, 'Fill Style Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGraphicGroupSequence
      //(0070,0234)
      = const PTag._('GraphicGroupSequence', 0x00700234, 'Graphic Group Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kTextColorCIELabValue
      //(0070,0241)
      = const PTag._('TextColorCIELabValue', 0x00700241, 'Text Color CIELab Value',
          VR.kUS, VM.k3, false);
  static const PTag kHorizontalAlignment
      //(0070,0242)
      = const PTag._('HorizontalAlignment', 0x00700242, 'Horizontal Alignment', VR.kCS,
          VM.k1, false);
  static const PTag kVerticalAlignment
      //(0070,0243)
      = const PTag._(
          'VerticalAlignment', 0x00700243, 'Vertical Alignment', VR.kCS, VM.k1, false);
  static const PTag kShadowStyle
      //(0070,0244)
      = const PTag._('ShadowStyle', 0x00700244, 'Shadow Style', VR.kCS, VM.k1, false);
  static const PTag kShadowOffsetX
      //(0070,0245)
      =
      const PTag._('ShadowOffsetX', 0x00700245, 'Shadow Offset X', VR.kFL, VM.k1, false);
  static const PTag kShadowOffsetY
      //(0070,0246)
      =
      const PTag._('ShadowOffsetY', 0x00700246, 'Shadow Offset Y', VR.kFL, VM.k1, false);
  static const PTag kShadowColorCIELabValue
      //(0070,0247)
      = const PTag._('ShadowColorCIELabValue', 0x00700247, 'Shadow Color CIELab Value',
          VR.kUS, VM.k3, false);
  static const PTag kUnderlined
      //(0070,0248)
      = const PTag._('Underlined', 0x00700248, 'Underlined', VR.kCS, VM.k1, false);
  static const PTag kBold
      //(0070,0249)
      = const PTag._('Bold', 0x00700249, 'Bold', VR.kCS, VM.k1, false);
  static const PTag kItalic
      //(0070,0250)
      = const PTag._('Italic', 0x00700250, 'Italic', VR.kCS, VM.k1, false);
  static const PTag kPatternOnColorCIELabValue
      //(0070,0251)
      = const PTag._('PatternOnColorCIELabValue', 0x00700251,
          'Pattern On Color CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kPatternOffColorCIELabValue
      //(0070,0252)
      = const PTag._('PatternOffColorCIELabValue', 0x00700252,
          'Pattern Off Color CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kLineThickness
      //(0070,0253)
      = const PTag._('LineThickness', 0x00700253, 'Line Thickness', VR.kFL, VM.k1, false);
  static const PTag kLineDashingStyle
      //(0070,0254)
      = const PTag._(
          'LineDashingStyle', 0x00700254, 'Line Dashing Style', VR.kCS, VM.k1, false);
  static const PTag kLinePattern
      //(0070,0255)
      = const PTag._('LinePattern', 0x00700255, 'Line Pattern', VR.kUL, VM.k1, false);
  static const PTag kFillPattern
      //(0070,0256)
      = const PTag._('FillPattern', 0x00700256, 'Fill Pattern', VR.kOB, VM.k1, false);
  static const PTag kFillMode
      //(0070,0257)
      = const PTag._('FillMode', 0x00700257, 'Fill Mode', VR.kCS, VM.k1, false);
  static const PTag kShadowOpacity
      //(0070,0258)
      = const PTag._('ShadowOpacity', 0x00700258, 'Shadow Opacity', VR.kFL, VM.k1, false);
  static const PTag kGapLength
      //(0070,0261)
      = const PTag._('GapLength', 0x00700261, 'Gap Length', VR.kFL, VM.k1, false);
  static const PTag kDiameterOfVisibility
      //(0070,0262)
      = const PTag._('DiameterOfVisibility', 0x00700262, 'Diameter of Visibility', VR.kFL,
          VM.k1, false);
  static const PTag kRotationPoint
      //(0070,0273)
      = const PTag._('RotationPoint', 0x00700273, 'Rotation Point', VR.kFL, VM.k2, false);
  static const PTag kTickAlignment
      //(0070,0274)
      = const PTag._('TickAlignment', 0x00700274, 'Tick Alignment', VR.kCS, VM.k1, false);
  static const PTag kShowTickLabel
      //(0070,0278)
      =
      const PTag._('ShowTickLabel', 0x00700278, 'Show Tick Label', VR.kCS, VM.k1, false);
  static const PTag kTickLabelAlignment
      //(0070,0279)
      = const PTag._(
          'TickLabelAlignment', 0x00700279, 'Tick Label Alignment', VR.kCS, VM.k1, false);
  static const PTag kCompoundGraphicUnits
      //(0070,0282)
      = const PTag._('CompoundGraphicUnits', 0x00700282, 'Compound Graphic Units', VR.kCS,
          VM.k1, false);
  static const PTag kPatternOnOpacity
      //(0070,0284)
      = const PTag._(
          'PatternOnOpacity', 0x00700284, 'Pattern On Opacity', VR.kFL, VM.k1, false);
  static const PTag kPatternOffOpacity
      //(0070,0285)
      = const PTag._(
          'PatternOffOpacity', 0x00700285, 'Pattern Off Opacity', VR.kFL, VM.k1, false);
  static const PTag kMajorTicksSequence
      //(0070,0287)
      = const PTag._(
          'MajorTicksSequence', 0x00700287, 'Major Ticks Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTickPosition
      //(0070,0288)
      = const PTag._('TickPosition', 0x00700288, 'Tick Position', VR.kFL, VM.k1, false);
  static const PTag kTickLabel
      //(0070,0289)
      = const PTag._('TickLabel', 0x00700289, 'Tick Label', VR.kSH, VM.k1, false);
  static const PTag kCompoundGraphicType
      //(0070,0294)
      = const PTag._('CompoundGraphicType', 0x00700294, 'Compound Graphic Type', VR.kCS,
          VM.k1, false);
  static const PTag kGraphicGroupID
      //(0070,0295)
      = const PTag._(
          'GraphicGroupID', 0x00700295, 'Graphic Group ID', VR.kUL, VM.k1, false);
  static const PTag kShapeType
      //(0070,0306)
      = const PTag._('ShapeType', 0x00700306, 'Shape Type', VR.kCS, VM.k1, false);
  static const PTag kRegistrationSequence
      //(0070,0308)
      = const PTag._('RegistrationSequence', 0x00700308, 'Registration Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kMatrixRegistrationSequence
      //(0070,0309)
      = const PTag._('MatrixRegistrationSequence', 0x00700309,
          'Matrix Registration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMatrixSequence
      //(0070,030A)
      =
      const PTag._('MatrixSequence', 0x0070030A, 'Matrix Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFrameOfReferenceTransformationMatrixType
      //(0070,030C)
      = const PTag._('FrameOfReferenceTransformationMatrixType', 0x0070030C,
          'Frame of Reference Transformation Matrix Type', VR.kCS, VM.k1, false);
  static const PTag kRegistrationTypeCodeSequence
      //(0070,030D)
      = const PTag._('RegistrationTypeCodeSequence', 0x0070030D,
          'Registration Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFiducialDescription
      //(0070,030F)
      = const PTag._('FiducialDescription', 0x0070030F, 'Fiducial Description', VR.kST,
          VM.k1, false);
  static const PTag kFiducialIdentifier
      //(0070,0310)
      = const PTag._(
          'FiducialIdentifier', 0x00700310, 'Fiducial Identifier', VR.kSH, VM.k1, false);
  static const PTag kFiducialIdentifierCodeSequence
      //(0070,0311)
      = const PTag._('FiducialIdentifierCodeSequence', 0x00700311,
          'Fiducial Identifier Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContourUncertaintyRadius
      //(0070,0312)
      = const PTag._('ContourUncertaintyRadius', 0x00700312, 'Contour Uncertainty Radius',
          VR.kFD, VM.k1, false);
  static const PTag kUsedFiducialsSequence
      //(0070,0314)
      = const PTag._('UsedFiducialsSequence', 0x00700314, 'Used Fiducials Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kGraphicCoordinatesDataSequence
      //(0070,0318)
      = const PTag._('GraphicCoordinatesDataSequence', 0x00700318,
          'Graphic Coordinates Data Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFiducialUID
      //(0070,031A)
      = const PTag._('FiducialUID', 0x0070031A, 'Fiducial UID', VR.kUI, VM.k1, false);
  static const PTag kFiducialSetSequence
      //(0070,031C)
      = const PTag._('FiducialSetSequence', 0x0070031C, 'Fiducial Set Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kFiducialSequence
      //(0070,031E)
      = const PTag._(
          'FiducialSequence', 0x0070031E, 'Fiducial Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGraphicLayerRecommendedDisplayCIELabValue
      //(0070,0401)
      = const PTag._('GraphicLayerRecommendedDisplayCIELabValue', 0x00700401,
          'Graphic Layer Recommended Display CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kBlendingSequence
      //(0070,0402)
      = const PTag._(
          'BlendingSequence', 0x00700402, 'Blending Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRelativeOpacity
      //(0070,0403)
      = const PTag._(
          'RelativeOpacity', 0x00700403, 'Relative Opacity', VR.kFL, VM.k1, false);
  static const PTag kReferencedSpatialRegistrationSequence
      //(0070,0404)
      = const PTag._('ReferencedSpatialRegistrationSequence', 0x00700404,
          'Referenced Spatial Registration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBlendingPosition
      //(0070,0405)
      = const PTag._(
          'BlendingPosition', 0x00700405, 'Blending Position', VR.kCS, VM.k1, false);
  static const PTag kHangingProtocolName
      //(0072,0002)
      = const PTag._('HangingProtocolName', 0x00720002, 'Hanging Protocol Name', VR.kSH,
          VM.k1, false);
  static const PTag kHangingProtocolDescription
      //(0072,0004)
      = const PTag._('HangingProtocolDescription', 0x00720004,
          'Hanging Protocol Description', VR.kLO, VM.k1, false);
  static const PTag kHangingProtocolLevel
      //(0072,0006)
      = const PTag._('HangingProtocolLevel', 0x00720006, 'Hanging Protocol Level', VR.kCS,
          VM.k1, false);
  static const PTag kHangingProtocolCreator
      //(0072,0008)
      = const PTag._('HangingProtocolCreator', 0x00720008, 'Hanging Protocol Creator',
          VR.kLO, VM.k1, false);
  static const PTag kHangingProtocolCreationDateTime
      //(0072,000A)
      = const PTag._('HangingProtocolCreationDateTime', 0x0072000A,
          'Hanging Protocol Creation DateTime', VR.kDT, VM.k1, false);
  static const PTag kHangingProtocolDefinitionSequence
      //(0072,000C)
      = const PTag._('HangingProtocolDefinitionSequence', 0x0072000C,
          'Hanging Protocol Definition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHangingProtocolUserIdentificationCodeSequence
      //(0072,000E)
      = const PTag._('HangingProtocolUserIdentificationCodeSequence', 0x0072000E,
          'Hanging Protocol User Identification Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kHangingProtocolUserGroupName
      //(0072,0010)
      = const PTag._('HangingProtocolUserGroupName', 0x00720010,
          'Hanging Protocol User Group Name', VR.kLO, VM.k1, false);
  static const PTag kSourceHangingProtocolSequence
      //(0072,0012)
      = const PTag._('SourceHangingProtocolSequence', 0x00720012,
          'Source Hanging Protocol Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfPriorsReferenced
      //(0072,0014)
      = const PTag._('NumberOfPriorsReferenced', 0x00720014,
          'Number of Priors Referenced', VR.kUS, VM.k1, false);
  static const PTag kImageSetsSequence
      //(0072,0020)
      = const PTag._(
          'ImageSetsSequence', 0x00720020, 'Image Sets Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageSetSelectorSequence
      //(0072,0022)
      = const PTag._('ImageSetSelectorSequence', 0x00720022,
          'Image Set Selector Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageSetSelectorUsageFlag
      //(0072,0024)
      = const PTag._('ImageSetSelectorUsageFlag', 0x00720024,
          'Image Set Selector Usage Flag', VR.kCS, VM.k1, false);
  static const PTag kSelectorAttribute
      //(0072,0026)
      = const PTag._(
          'SelectorAttribute', 0x00720026, 'Selector Attribute', VR.kAT, VM.k1, false);
  static const PTag kSelectorValueNumber
      //(0072,0028)
      = const PTag._('SelectorValueNumber', 0x00720028, 'Selector Value Number', VR.kUS,
          VM.k1, false);
  static const PTag kTimeBasedImageSetsSequence
      //(0072,0030)
      = const PTag._('TimeBasedImageSetsSequence', 0x00720030,
          'Time Based Image Sets Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageSetNumber
      //(0072,0032)
      = const PTag._(
          'ImageSetNumber', 0x00720032, 'Image Set Number', VR.kUS, VM.k1, false);
  static const PTag kImageSetSelectorCategory
      //(0072,0034)
      = const PTag._('ImageSetSelectorCategory', 0x00720034,
          'Image Set Selector Category', VR.kCS, VM.k1, false);
  static const PTag kRelativeTime
      //(0072,0038)
      = const PTag._('RelativeTime', 0x00720038, 'Relative Time', VR.kUS, VM.k2, false);
  static const PTag kRelativeTimeUnits
      //(0072,003A)
      = const PTag._(
          'RelativeTimeUnits', 0x0072003A, 'Relative Time Units', VR.kCS, VM.k1, false);
  static const PTag kAbstractPriorValue
      //(0072,003C)
      = const PTag._(
          'AbstractPriorValue', 0x0072003C, 'Abstract Prior Value', VR.kSS, VM.k2, false);
  static const PTag kAbstractPriorCodeSequence
      //(0072,003E)
      = const PTag._('AbstractPriorCodeSequence', 0x0072003E,
          'Abstract Prior Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageSetLabel
      //(0072,0040)
      =
      const PTag._('ImageSetLabel', 0x00720040, 'Image Set Label', VR.kLO, VM.k1, false);
  static const PTag kSelectorAttributeVR
      //(0072,0050)
      = const PTag._('SelectorAttributeVR', 0x00720050, 'Selector Attribute VR', VR.kCS,
          VM.k1, false);
  static const PTag kSelectorSequencePointer
      //(0072,0052)
      = const PTag._('SelectorSequencePointer', 0x00720052, 'Selector Sequence Pointer',
          VR.kAT, VM.k1_n, false);
  static const PTag kSelectorSequencePointerPrivateCreator
      //(0072,0054)
      = const PTag._('SelectorSequencePointerPrivateCreator', 0x00720054,
          'Selector Sequence Pointer Private Creator', VR.kLO, VM.k1_n, false);
  static const PTag kSelectorAttributePrivateCreator
      //(0072,0056)
      = const PTag._('SelectorAttributePrivateCreator', 0x00720056,
          'Selector Attribute Private Creator', VR.kLO, VM.k1, false);
  static const PTag kSelectorAEValue
      //(0072,005E)
      = const PTag._(
          'SelectorAEValue', 0x0072005E, 'Selector AE Value', VR.kAE, VM.k1_n, false);
  static const PTag kSelectorASValue
      //(0072,005F)
      = const PTag._(
          'SelectorASValue', 0x0072005F, 'Selector AS Value', VR.kAS, VM.k1_n, false);
  static const PTag kSelectorATValue
      //(0072,0060)
      = const PTag._(
          'SelectorATValue', 0x00720060, 'Selector AT Value', VR.kAT, VM.k1_n, false);
  static const PTag kSelectorDAValue
      //(0072,0061)
      = const PTag._(
          'SelectorDAValue', 0x00720061, 'Selector DA Value', VR.kDA, VM.k1_n, false);
  static const PTag kSelectorCSValue
      //(0072,0062)
      = const PTag._(
          'SelectorCSValue', 0x00720062, 'Selector CS Value', VR.kCS, VM.k1_n, false);
  static const PTag kSelectorDTValue
      //(0072,0063)
      = const PTag._(
          'SelectorDTValue', 0x00720063, 'Selector DT Value', VR.kDT, VM.k1_n, false);
  static const PTag kSelectorISValue
      //(0072,0064)
      = const PTag._(
          'SelectorISValue', 0x00720064, 'Selector IS Value', VR.kIS, VM.k1_n, false);
  static const PTag kSelectorOBValue
      //(0072,0065)
      = const PTag._(
          'SelectorOBValue', 0x00720065, 'Selector OB Value', VR.kOB, VM.k1_n, false);
  static const PTag kSelectorLOValue
      //(0072,0066)
      = const PTag._(
          'SelectorLOValue', 0x00720066, 'Selector LO Value', VR.kLO, VM.k1_n, false);
  static const PTag kSelectorOFValue
      //(0072,0067)
      = const PTag._(
          'SelectorOFValue', 0x00720067, 'Selector OF Value', VR.kOF, VM.k1_n, false);
  static const PTag kSelectorLTValue
      //(0072,0068)
      = const PTag._(
          'SelectorLTValue', 0x00720068, 'Selector LT Value', VR.kLT, VM.k1, false);
  static const PTag kSelectorOWValue
      //(0072,0069)
      = const PTag._(
          'SelectorOWValue', 0x00720069, 'Selector OW Value', VR.kOW, VM.k1_n, false);
  static const PTag kSelectorPNValue
      //(0072,006A)
      = const PTag._(
          'SelectorPNValue', 0x0072006A, 'Selector PN Value', VR.kPN, VM.k1_n, false);
  static const PTag kSelectorTMValue
      //(0072,006B)
      = const PTag._(
          'SelectorTMValue', 0x00720069, 'Selector TM Value', VR.kTM, VM.k1_n, false);
  static const PTag kSelectorSHValue
      //(0072,006C)
      = const PTag._(
          'SelectorSHValue', 0x0072006C, 'Selector SH Value', VR.kSH, VM.k1_n, false);
  static const PTag kSelectorUNValue
      //(0072,006D)
      = const PTag._(
          'SelectorUNValue', 0x0072006D, 'Selector UN Value', VR.kUN, VM.k1_n, false);
  static const PTag kSelectorSTValue
      //(0072,006E)
      = const PTag._(
          'SelectorSTValue', 0x0072006E, 'Selector ST Value', VR.kST, VM.k1, false);
  static const PTag kSelectorUCValue
      //(0072,006F)
      = const PTag._(
          'SelectorUCValue', 0x0072006F, 'Selector UC Value', VR.kUC, VM.k1_n, false);
  static const PTag kSelectorUTValue
      //(0072,0070)
      = const PTag._(
          'SelectorUTValue', 0x00720070, 'Selector UT Value', VR.kUT, VM.k1, false);
  static const PTag kSelectorURValue
      //(0072,0071)
      = const PTag._(
          'SelectorURValue', 0x00720071, 'Selector UR Value', VR.kUR, VM.k1_n, false);
  static const PTag kSelectorDSValue
      //(0072,0072)
      = const PTag._(
          'SelectorDSValue', 0x00720072, 'Selector DS Value', VR.kDS, VM.k1_n, false);
  static const PTag kSelectorODValue
      //(0072,0073)
      = const PTag._(
          'SelectorODValue', 0x00720073, 'Selector OD Value', VR.kOD, VM.k1, false);
  static const PTag kSelectorFDValue
      //(0072,0074)
      = const PTag._(
          'SelectorFDValue', 0x00720074, 'Selector FD Value', VR.kFD, VM.k1_n, false);
  static const PTag kSelectorOLValue
      //(0072,0075)
      = const PTag._(
          'SelectorOLValue', 0x00720075, 'Selector OL Value', VR.kOL, VM.k1_n, false);
  static const PTag kSelectorFLValue
      //(0072,0076)
      = const PTag._(
          'SelectorFLValue', 0x00720076, 'Selector FL Value', VR.kFL, VM.k1_n, false);
  static const PTag kSelectorULValue
      //(0072,0078)
      = const PTag._(
          'SelectorULValue', 0x00720078, 'Selector UL Value', VR.kUL, VM.k1_n, false);
  static const PTag kSelectorUSValue
      //(0072,007A)
      = const PTag._(
          'SelectorUSValue', 0x0072007A, 'Selector US Value', VR.kUS, VM.k1_n, false);
  static const PTag kSelectorSLValue
      //(0072,007C)
      = const PTag._(
          'SelectorSLValue', 0x0072007C, 'Selector SL Value', VR.kSL, VM.k1_n, false);
  static const PTag kSelectorSSValue
      //(0072,007E)
      = const PTag._(
          'SelectorSSValue', 0x0072007E, 'Selector SS Value', VR.kSS, VM.k1_n, false);
  static const PTag kSelectorUIValue
      //(0072,007F)
      = const PTag._(
          'SelectorUIValue', 0x0072007F, 'Selector UI Value', VR.kUI, VM.k1_n, false);
  static const PTag kSelectorCodeSequenceValue
      //(0072,0080)
      = const PTag._('SelectorCodeSequenceValue', 0x00720080,
          'Selector Code Sequence Value', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfScreens
      //(0072,0100)
      = const PTag._(
          'NumberOfScreens', 0x00720100, 'Number of Screens', VR.kUS, VM.k1, false);
  static const PTag kNominalScreenDefinitionSequence
      //(0072,0102)
      = const PTag._('NominalScreenDefinitionSequence', 0x00720102,
          'Nominal Screen Definition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNumberOfVerticalPixels
      //(0072,0104)
      = const PTag._('NumberOfVerticalPixels', 0x00720104, 'Number of Vertical Pixels',
          VR.kUS, VM.k1, false);
  static const PTag kNumberOfHorizontalPixels
      //(0072,0106)
      = const PTag._('NumberOfHorizontalPixels', 0x00720106,
          'Number of Horizontal Pixels', VR.kUS, VM.k1, false);
  static const PTag kDisplayEnvironmentSpatialPosition
      //(0072,0108)
      = const PTag._('DisplayEnvironmentSpatialPosition', 0x00720108,
          'Display Environment Spatial Position', VR.kFD, VM.k4, false);
  static const PTag kScreenMinimumGrayscaleBitDepth
      //(0072,010A)
      = const PTag._('ScreenMinimumGrayscaleBitDepth', 0x0072010A,
          'Screen Minimum Grayscale Bit Depth', VR.kUS, VM.k1, false);
  static const PTag kScreenMinimumColorBitDepth
      //(0072,010C)
      = const PTag._('ScreenMinimumColorBitDepth', 0x0072010C,
          'Screen Minimum Color Bit Depth', VR.kUS, VM.k1, false);
  static const PTag kApplicationMaximumRepaintTime
      //(0072,010E)
      = const PTag._('ApplicationMaximumRepaintTime', 0x0072010E,
          'Application Maximum Repaint Time', VR.kUS, VM.k1, false);
  static const PTag kDisplaySetsSequence
      //(0072,0200)
      = const PTag._('DisplaySetsSequence', 0x00720200, 'Display Sets Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kDisplaySetNumber
      //(0072,0202)
      = const PTag._(
          'DisplaySetNumber', 0x00720202, 'Display Set Number', VR.kUS, VM.k1, false);
  static const PTag kDisplaySetLabel
      //(0072,0203)
      = const PTag._(
          'DisplaySetLabel', 0x00720203, 'Display Set Label', VR.kLO, VM.k1, false);
  static const PTag kDisplaySetPresentationGroup
      //(0072,0204)
      = const PTag._('DisplaySetPresentationGroup', 0x00720204,
          'Display Set Presentation Group', VR.kUS, VM.k1, false);
  static const PTag kDisplaySetPresentationGroupDescription
      //(0072,0206)
      = const PTag._('DisplaySetPresentationGroupDescription', 0x00720206,
          'Display Set Presentation Group Description', VR.kLO, VM.k1, false);
  static const PTag kPartialDataDisplayHandling
      //(0072,0208)
      = const PTag._('PartialDataDisplayHandling', 0x00720208,
          'Partial Data Display Handling', VR.kCS, VM.k1, false);
  static const PTag kSynchronizedScrollingSequence
      //(0072,0210)
      = const PTag._('SynchronizedScrollingSequence', 0x00720210,
          'Synchronized Scrolling Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDisplaySetScrollingGroup
      //(0072,0212)
      = const PTag._('DisplaySetScrollingGroup', 0x00720212,
          'Display Set Scrolling Group', VR.kUS, VM.k2_n, false);
  static const PTag kNavigationIndicatorSequence
      //(0072,0214)
      = const PTag._('NavigationIndicatorSequence', 0x00720214,
          'Navigation Indicator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kNavigationDisplaySet
      //(0072,0216)
      = const PTag._('NavigationDisplaySet', 0x00720216, 'Navigation Display Set', VR.kUS,
          VM.k1, false);
  static const PTag kReferenceDisplaySets
      //(0072,0218)
      = const PTag._('ReferenceDisplaySets', 0x00720218, 'Reference Display Sets', VR.kUS,
          VM.k1_n, false);
  static const PTag kImageBoxesSequence
      //(0072,0300)
      = const PTag._(
          'ImageBoxesSequence', 0x00720300, 'Image Boxes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageBoxNumber
      //(0072,0302)
      = const PTag._(
          'ImageBoxNumber', 0x00720302, 'Image Box Number', VR.kUS, VM.k1, false);
  static const PTag kImageBoxLayoutType
      //(0072,0304)
      = const PTag._('ImageBoxLayoutType', 0x00720304, 'Image Box Layout Type', VR.kCS,
          VM.k1, false);
  static const PTag kImageBoxTileHorizontalDimension
      //(0072,0306)
      = const PTag._('ImageBoxTileHorizontalDimension', 0x00720306,
          'Image Box Tile Horizontal Dimension', VR.kUS, VM.k1, false);
  static const PTag kImageBoxTileVerticalDimension
      //(0072,0308)
      = const PTag._('ImageBoxTileVerticalDimension', 0x00720308,
          'Image Box Tile Vertical Dimension', VR.kUS, VM.k1, false);
  static const PTag kImageBoxScrollDirection
      //(0072,0310)
      = const PTag._('ImageBoxScrollDirection', 0x00720310, 'Image Box Scroll Direction',
          VR.kCS, VM.k1, false);
  static const PTag kImageBoxSmallScrollType
      //(0072,0312)
      = const PTag._('ImageBoxSmallScrollType', 0x00720312, 'Image Box Small Scroll Type',
          VR.kCS, VM.k1, false);
  static const PTag kImageBoxSmallScrollAmount
      //(0072,0314)
      = const PTag._('ImageBoxSmallScrollAmount', 0x00720314,
          'Image Box Small Scroll Amount', VR.kUS, VM.k1, false);
  static const PTag kImageBoxLargeScrollType
      //(0072,0316)
      = const PTag._('ImageBoxLargeScrollType', 0x00720316, 'Image Box Large Scroll Type',
          VR.kCS, VM.k1, false);
  static const PTag kImageBoxLargeScrollAmount
      //(0072,0318)
      = const PTag._('ImageBoxLargeScrollAmount', 0x00720318,
          'Image Box Large Scroll Amount', VR.kUS, VM.k1, false);
  static const PTag kImageBoxOverlapPriority
      //(0072,0320)
      = const PTag._('ImageBoxOverlapPriority', 0x00720320, 'Image Box Overlap Priority',
          VR.kUS, VM.k1, false);
  static const PTag kCineRelativeToRealTime
      //(0072,0330)
      = const PTag._('CineRelativeToRealTime', 0x00720330, 'Cine Relative to Real-Time',
          VR.kFD, VM.k1, false);
  static const PTag kFilterOperationsSequence
      //(0072,0400)
      = const PTag._('FilterOperationsSequence', 0x00720400, 'Filter Operations Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kFilterByCategory
      //(0072,0402)
      = const PTag._(
          'FilterByCategory', 0x00720402, 'Filter-by Category', VR.kCS, VM.k1, false);
  static const PTag kFilterByAttributePresence
      //(0072,0404)
      = const PTag._('FilterByAttributePresence', 0x00720404,
          'Filter-by Attribute Presence', VR.kCS, VM.k1, false);
  static const PTag kFilterByOperator
      //(0072,0406)
      = const PTag._(
          'FilterByOperator', 0x00720406, 'Filter-by Operator', VR.kCS, VM.k1, false);
  static const PTag kStructuredDisplayBackgroundCIELabValue
      //(0072,0420)
      = const PTag._('StructuredDisplayBackgroundCIELabValue', 0x00720420,
          'Structured Display Background CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kEmptyImageBoxCIELabValue
      //(0072,0421)
      = const PTag._('EmptyImageBoxCIELabValue', 0x00720421,
          'Empty Image Box CIELab Value', VR.kUS, VM.k3, false);
  static const PTag kStructuredDisplayImageBoxSequence
      //(0072,0422)
      = const PTag._('StructuredDisplayImageBoxSequence', 0x00720422,
          'Structured Display Image Box Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStructuredDisplayTextBoxSequence
      //(0072,0424)
      = const PTag._('StructuredDisplayTextBoxSequence', 0x00720424,
          'Structured Display Text Box Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedFirstFrameSequence
      //(0072,0427)
      = const PTag._('ReferencedFirstFrameSequence', 0x00720427,
          'Referenced First Frame Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageBoxSynchronizationSequence
      //(0072,0430)
      = const PTag._('ImageBoxSynchronizationSequence', 0x00720430,
          'Image Box Synchronization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSynchronizedImageBoxList
      //(0072,0432)
      = const PTag._('SynchronizedImageBoxList', 0x00720432,
          'Synchronized Image Box List', VR.kUS, VM.k2_n, false);
  static const PTag kTypeOfSynchronization
      //(0072,0434)
      = const PTag._('TypeOfSynchronization', 0x00720434, 'Type of Synchronization',
          VR.kCS, VM.k1, false);
  static const PTag kBlendingOperationType
      //(0072,0500)
      = const PTag._('BlendingOperationType', 0x00720500, 'Blending Operation Type',
          VR.kCS, VM.k1, false);
  static const PTag kReformattingOperationType
      //(0072,0510)
      = const PTag._('ReformattingOperationType', 0x00720510,
          'Reformatting Operation Type', VR.kCS, VM.k1, false);
  static const PTag kReformattingThickness
      //(0072,0512)
      = const PTag._('ReformattingThickness', 0x00720512, 'Reformatting Thickness',
          VR.kFD, VM.k1, false);
  static const PTag kReformattingInterval
      //(0072,0514)
      = const PTag._('ReformattingInterval', 0x00720514, 'Reformatting Interval', VR.kFD,
          VM.k1, false);
  static const PTag kReformattingOperationInitialViewDirection
      //(0072,0516)
      = const PTag._('ReformattingOperationInitialViewDirection', 0x00720516,
          'Reformatting Operation Initial View Direction', VR.kCS, VM.k1, false);
  static const PTag kThreeDRenderingType
      //(0072,0520)
      = const PTag._(
          'ThreeDRenderingType', 0x00720520, '3D Rendering Type', VR.kCS, VM.k1_n, false);
  static const PTag kSortingOperationsSequence
      //(0072,0600)
      = const PTag._('SortingOperationsSequence', 0x00720600,
          'Sorting Operations Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSortByCategory
      //(0072,0602)
      = const PTag._(
          'SortByCategory', 0x00720602, 'Sort-by Category', VR.kCS, VM.k1, false);
  static const PTag kSortingDirection
      //(0072,0604)
      = const PTag._(
          'SortingDirection', 0x00720604, 'Sorting Direction', VR.kCS, VM.k1, false);
  static const PTag kDisplaySetPatientOrientation
      //(0072,0700)
      = const PTag._('DisplaySetPatientOrientation', 0x00720700,
          'Display Set Patient Orientation', VR.kCS, VM.k2, false);
  static const PTag kVOIType
      //(0072,0702)
      = const PTag._('VOIType', 0x00720702, 'VOI Type', VR.kCS, VM.k1, false);
  static const PTag kPseudoColorType
      //(0072,0704)
      = const PTag._(
          'PseudoColorType', 0x00720704, 'Pseudo-Color Type', VR.kCS, VM.k1, false);
  static const PTag kPseudoColorPaletteInstanceReferenceSequence
      //(0072,0705)
      = const PTag._('PseudoColorPaletteInstanceReferenceSequence', 0x00720705,
          'Pseudo-Color Palette Instance Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kShowGrayscaleInverted
      //(0072,0706)
      = const PTag._('ShowGrayscaleInverted', 0x00720706, 'Show Grayscale Inverted',
          VR.kCS, VM.k1, false);
  static const PTag kShowImageTrueSizeFlag
      //(0072,0710)
      = const PTag._('ShowImageTrueSizeFlag', 0x00720710, 'Show Image True Size Flag',
          VR.kCS, VM.k1, false);
  static const PTag kShowGraphicAnnotationFlag
      //(0072,0712)
      = const PTag._('ShowGraphicAnnotationFlag', 0x00720712,
          'Show Graphic Annotation Flag', VR.kCS, VM.k1, false);
  static const PTag kShowPatientDemographicsFlag
      //(0072,0714)
      = const PTag._('ShowPatientDemographicsFlag', 0x00720714,
          'Show Patient Demographics Flag', VR.kCS, VM.k1, false);
  static const PTag kShowAcquisitionTechniquesFlag
      //(0072,0716)
      = const PTag._('ShowAcquisitionTechniquesFlag', 0x00720716,
          'Show Acquisition Techniques Flag', VR.kCS, VM.k1, false);
  static const PTag kDisplaySetHorizontalJustification
      //(0072,0717)
      = const PTag._('DisplaySetHorizontalJustification', 0x00720717,
          'Display Set Horizontal Justification', VR.kCS, VM.k1, false);
  static const PTag kDisplaySetVerticalJustification
      //(0072,0718)
      = const PTag._('DisplaySetVerticalJustification', 0x00720718,
          'Display Set Vertical Justification', VR.kCS, VM.k1, false);
  static const PTag kContinuationStartMeterset
      //(0074,0120)
      = const PTag._('ContinuationStartMeterset', 0x00740120,
          'Continuation Start Meterset', VR.kFD, VM.k1, false);
  static const PTag kContinuationEndMeterset
      //(0074,0121)
      = const PTag._('ContinuationEndMeterset', 0x00740121, 'Continuation End Meterset',
          VR.kFD, VM.k1, false);
  static const PTag kProcedureStepState
      //(0074,1000)
      = const PTag._(
          'ProcedureStepState', 0x00741000, 'Procedure Step State', VR.kCS, VM.k1, false);
  static const PTag kProcedureStepProgressInformationSequence
      //(0074,1002)
      = const PTag._('ProcedureStepProgressInformationSequence', 0x00741002,
          'Procedure Step Progress Information Sequence', VR.kSQ, VM.k1, false);
  static const PTag kProcedureStepProgress
      //(0074,1004)
      = const PTag._('ProcedureStepProgress', 0x00741004, 'Procedure Step Progress',
          VR.kDS, VM.k1, false);
  static const PTag kProcedureStepProgressDescription
      //(0074,1006)
      = const PTag._('ProcedureStepProgressDescription', 0x00741006,
          'Procedure Step Progress Description', VR.kST, VM.k1, false);
  static const PTag kProcedureStepCommunicationsURISequence
      //(0074,1008)
      = const PTag._('ProcedureStepCommunicationsURISequence', 0x00741008,
          'Procedure Step Communications URI Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContactURI
      //(0074,100a)
      = const PTag._('ContactURI', 0x0074100a, 'Contact URI', VR.kUR, VM.k1, false);
  static const PTag kContactDisplayName
      //(0074,100c)
      = const PTag._(
          'ContactDisplayName', 0x0074100c, 'Contact Display Name', VR.kLO, VM.k1, false);
  static const PTag kProcedureStepDiscontinuationReasonCodeSequence
      //(0074,100e)
      = const PTag._('ProcedureStepDiscontinuationReasonCodeSequence', 0x0074100e,
          'Procedure Step Discontinuation Reason Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBeamTaskSequence
      //(0074,1020)
      = const PTag._(
          'BeamTaskSequence', 0x00741020, 'Beam Task Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBeamTaskType
      //(0074,1022)
      = const PTag._('BeamTaskType', 0x00741022, 'Beam Task Type', VR.kCS, VM.k1, false);
  static const PTag kBeamOrderIndexTrial
      //(0074,1024)
      = const PTag._('BeamOrderIndexTrial', 0x00741024, 'Beam Order Index (Trial)',
          VR.kIS, VM.k1, true);
  static const PTag kAutosequenceFlag
      //(0074,1025)
      = const PTag._(
          'AutosequenceFlag', 0x00741025, 'Autosequence Flag', VR.kCS, VM.k1, false);
  static const PTag kTableTopVerticalAdjustedPosition
      //(0074,1026)
      = const PTag._('TableTopVerticalAdjustedPosition', 0x00741026,
          'Table Top Vertical Adjusted Position', VR.kFD, VM.k1, false);
  static const PTag kTableTopLongitudinalAdjustedPosition
      //(0074,1027)
      = const PTag._('TableTopLongitudinalAdjustedPosition', 0x00741027,
          'Table Top Longitudinal Adjusted Position', VR.kFD, VM.k1, false);
  static const PTag kTableTopLateralAdjustedPosition
      //(0074,1028)
      = const PTag._('TableTopLateralAdjustedPosition', 0x00741028,
          'Table Top Lateral Adjusted Position', VR.kFD, VM.k1, false);
  static const PTag kPatientSupportAdjustedAngle
      //(0074,102A)
      = const PTag._('PatientSupportAdjustedAngle', 0x0074102A,
          'Patient Support Adjusted Angle', VR.kFD, VM.k1, false);
  static const PTag kTableTopEccentricAdjustedAngle
      //(0074,102B)
      = const PTag._('TableTopEccentricAdjustedAngle', 0x0074102B,
          'Table Top Eccentric Adjusted Angle', VR.kFD, VM.k1, false);
  static const PTag kTableTopPitchAdjustedAngle
      //(0074,102C)
      = const PTag._('TableTopPitchAdjustedAngle', 0x0074102C,
          'Table Top Pitch Adjusted Angle', VR.kFD, VM.k1, false);
  static const PTag kTableTopRollAdjustedAngle
      //(0074,102D)
      = const PTag._('TableTopRollAdjustedAngle', 0x0074102D,
          'Table Top Roll Adjusted Angle', VR.kFD, VM.k1, false);
  static const PTag kDeliveryVerificationImageSequence
      //(0074,1030)
      = const PTag._('DeliveryVerificationImageSequence', 0x00741030,
          'Delivery Verification Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kVerificationImageTiming
      //(0074,1032)
      = const PTag._('VerificationImageTiming', 0x00741032, 'Verification Image Timing',
          VR.kCS, VM.k1, false);
  static const PTag kDoubleExposureFlag
      //(0074,1034)
      = const PTag._(
          'DoubleExposureFlag', 0x00741034, 'Double Exposure Flag', VR.kCS, VM.k1, false);
  static const PTag kDoubleExposureOrdering
      //(0074,1036)
      = const PTag._('DoubleExposureOrdering', 0x00741036, 'Double Exposure Ordering',
          VR.kCS, VM.k1, false);
  static const PTag kDoubleExposureMetersetTrial
      //(0074,1038)
      = const PTag._('DoubleExposureMetersetTrial', 0x00741038,
          'Double Exposure Meterset (Trial)', VR.kDS, VM.k1, true);
  static const PTag kDoubleExposureFieldDeltaTrial
      //(0074,103A)
      = const PTag._('DoubleExposureFieldDeltaTrial', 0x0074103A,
          'Double Exposure Field Delta (Trial)', VR.kDS, VM.k4, true);
  static const PTag kRelatedReferenceRTImageSequence
      //(0074,1040)
      = const PTag._('RelatedReferenceRTImageSequence', 0x00741040,
          'Related Reference RT Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kGeneralMachineVerificationSequence
      //(0074,1042)
      = const PTag._('GeneralMachineVerificationSequence', 0x00741042,
          'General Machine Verification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kConventionalMachineVerificationSequence
      //(0074,1044)
      = const PTag._('ConventionalMachineVerificationSequence', 0x00741044,
          'Conventional Machine Verification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonMachineVerificationSequence
      //(0074,1046)
      = const PTag._('IonMachineVerificationSequence', 0x00741046,
          'Ion Machine Verification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFailedAttributesSequence
      //(0074,1048)
      = const PTag._('FailedAttributesSequence', 0x00741048, 'Failed Attributes Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kOverriddenAttributesSequence
      //(0074,104A)
      = const PTag._('OverriddenAttributesSequence', 0x0074104A,
          'Overridden Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kConventionalControlPointVerificationSequence
      //(0074,104C)
      = const PTag._('ConventionalControlPointVerificationSequence', 0x0074104C,
          'Conventional Control Point Verification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonControlPointVerificationSequence
      //(0074,104E)
      = const PTag._('IonControlPointVerificationSequence', 0x0074104E,
          'Ion Control Point Verification Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAttributeOccurrenceSequence
      //(0074,1050)
      = const PTag._('AttributeOccurrenceSequence', 0x00741050,
          'Attribute Occurrence Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAttributeOccurrencePointer
      //(0074,1052)
      = const PTag._('AttributeOccurrencePointer', 0x00741052,
          'Attribute Occurrence Pointer', VR.kAT, VM.k1, false);
  static const PTag kAttributeItemSelector
      //(0074,1054)
      = const PTag._('AttributeItemSelector', 0x00741054, 'Attribute Item Selector',
          VR.kUL, VM.k1, false);
  static const PTag kAttributeOccurrencePrivateCreator
      //(0074,1056)
      = const PTag._('AttributeOccurrencePrivateCreator', 0x00741056,
          'Attribute Occurrence Private Creator', VR.kLO, VM.k1, false);
  static const PTag kSelectorSequencePointerItems
      //(0074,1057)
      = const PTag._('SelectorSequencePointerItems', 0x00741057,
          'Selector Sequence Pointer Items', VR.kIS, VM.k1_n, false);
  static const PTag kScheduledProcedureStepPriority
      //(0074,1200)
      = const PTag._('ScheduledProcedureStepPriority', 0x00741200,
          'Scheduled Procedure Step Priority', VR.kCS, VM.k1, false);
  static const PTag kWorklistLabel
      //(0074,1202)
      = const PTag._('WorklistLabel', 0x00741202, 'Worklist Label', VR.kLO, VM.k1, false);
  static const PTag kProcedureStepLabel
      //(0074,1204)
      = const PTag._(
          'ProcedureStepLabel', 0x00741204, 'Procedure Step Label', VR.kLO, VM.k1, false);
  static const PTag kScheduledProcessingParametersSequence
      //(0074,1210)
      = const PTag._('ScheduledProcessingParametersSequence', 0x00741210,
          'Scheduled Processing Parameters Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerformedProcessingParametersSequence
      //(0074,1212)
      = const PTag._('PerformedProcessingParametersSequence', 0x00741212,
          'Performed Processing Parameters Sequence', VR.kSQ, VM.k1, false);
  static const PTag kUnifiedProcedureStepPerformedProcedureSequence
      //(0074,1216)
      = const PTag._('UnifiedProcedureStepPerformedProcedureSequence', 0x00741216,
          'Unified Procedure Step Performed Procedure Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRelatedProcedureStepSequence
      //(0074,1220)
      = const PTag._('RelatedProcedureStepSequence', 0x00741220,
          'Related Procedure Step Sequence', VR.kSQ, VM.k1, true);
  static const PTag kProcedureStepRelationshipType
      //(0074,1222)
      = const PTag._('ProcedureStepRelationshipType', 0x00741222,
          'Procedure Step Relationship Type', VR.kLO, VM.k1, true);
  static const PTag kReplacedProcedureStepSequence
      //(0074,1224)
      = const PTag._('ReplacedProcedureStepSequence', 0x00741224,
          'Replaced Procedure Step Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDeletionLock
      //(0074,1230)
      = const PTag._('DeletionLock', 0x00741230, 'Deletion Lock', VR.kLO, VM.k1, false);
  static const PTag kReceivingAE
      //(0074,1234)
      = const PTag._('ReceivingAE', 0x00741234, 'Receiving AE', VR.kAE, VM.k1, false);
  static const PTag kRequestingAE
      //(0074,1236)
      = const PTag._('RequestingAE', 0x00741236, 'Requesting AE', VR.kAE, VM.k1, false);
  static const PTag kReasonForCancellation
      //(0074,1238)
      = const PTag._('ReasonForCancellation', 0x00741238, 'Reason for Cancellation',
          VR.kLT, VM.k1, false);
  static const PTag kSCPStatus
      //(0074,1242)
      = const PTag._('SCPStatus', 0x00741242, 'SCP Status', VR.kCS, VM.k1, false);
  static const PTag kSubscriptionListStatus
      //(0074,1244)
      = const PTag._('SubscriptionListStatus', 0x00741244, 'Subscription List Status',
          VR.kCS, VM.k1, false);
  static const PTag kUnifiedProcedureStepListStatus
      //(0074,1246)
      = const PTag._('UnifiedProcedureStepListStatus', 0x00741246,
          'Unified Procedure StepList Status', VR.kCS, VM.k1, false);
  static const PTag kBeamOrderIndex
      //(0074,1324)
      = const PTag._(
          'BeamOrderIndex', 0x00741324, 'Beam Order Index', VR.kUL, VM.k1, false);
  static const PTag kDoubleExposureMeterset
      //(0074,1338)
      = const PTag._('DoubleExposureMeterset', 0x00741338, 'Double Exposure Meterset',
          VR.kFD, VM.k1, false);
  static const PTag kDoubleExposureFieldDelta
      //(0074,133A)
      = const PTag._('DoubleExposureFieldDelta', 0x0074133A,
          'Double Exposure Field Delta', VR.kFD, VM.k4, false);
  static const PTag kImplantAssemblyTemplateName
      //(0076,0001)
      = const PTag._('ImplantAssemblyTemplateName', 0x00760001,
          'Implant Assembly Template Name', VR.kLO, VM.k1, false);
  static const PTag kImplantAssemblyTemplateIssuer
      //(0076,0003)
      = const PTag._('ImplantAssemblyTemplateIssuer', 0x00760003,
          'Implant Assembly Template Issuer', VR.kLO, VM.k1, false);
  static const PTag kImplantAssemblyTemplateVersion
      //(0076,0006)
      = const PTag._('ImplantAssemblyTemplateVersion', 0x00760006,
          'Implant Assembly Template Version', VR.kLO, VM.k1, false);
  static const PTag kReplacedImplantAssemblyTemplateSequence
      //(0076,0008)
      = const PTag._('ReplacedImplantAssemblyTemplateSequence', 0x00760008,
          'Replaced Implant Assembly Template Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantAssemblyTemplateType
      //(0076,000A)
      = const PTag._('ImplantAssemblyTemplateType', 0x0076000A,
          'Implant Assembly Template Type', VR.kCS, VM.k1, false);
  static const PTag kOriginalImplantAssemblyTemplateSequence
      //(0076,000C)
      = const PTag._('OriginalImplantAssemblyTemplateSequence', 0x0076000C,
          'Original Implant Assembly Template Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDerivationImplantAssemblyTemplateSequence
      //(0076,000E)
      = const PTag._('DerivationImplantAssemblyTemplateSequence', 0x0076000E,
          'Derivation Implant Assembly Template Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantAssemblyTemplateTargetAnatomySequence
      //(0076,0010)
      = const PTag._('ImplantAssemblyTemplateTargetAnatomySequence', 0x00760010,
          'Implant Assembly Template Target Anatomy Sequence', VR.kSQ, VM.k1, false);
  static const PTag kProcedureTypeCodeSequence
      //(0076,0020)
      = const PTag._('ProcedureTypeCodeSequence', 0x00760020,
          'Procedure Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSurgicalTechnique
      //(0076,0030)
      = const PTag._(
          'SurgicalTechnique', 0x00760030, 'Surgical Technique', VR.kLO, VM.k1, false);
  static const PTag kComponentTypesSequence
      //(0076,0032)
      = const PTag._('ComponentTypesSequence', 0x00760032, 'Component Types Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kComponentTypeCodeSequence
      //(0076,0034)
      = const PTag._('ComponentTypeCodeSequence', 0x00760034,
          'Component Type Code Sequence', VR.kCS, VM.k1, false);
  static const PTag kExclusiveComponentType
      //(0076,0036)
      = const PTag._('ExclusiveComponentType', 0x00760036, 'Exclusive Component Type',
          VR.kCS, VM.k1, false);
  static const PTag kMandatoryComponentType
      //(0076,0038)
      = const PTag._('MandatoryComponentType', 0x00760038, 'Mandatory Component Type',
          VR.kCS, VM.k1, false);
  static const PTag kComponentSequence
      //(0076,0040)
      = const PTag._(
          'ComponentSequence', 0x00760040, 'Component Sequence', VR.kSQ, VM.k1, false);
  static const PTag kComponentID
      //(0076,0055)
      = const PTag._('ComponentID', 0x00760055, 'Component ID', VR.kUS, VM.k1, false);
  static const PTag kComponentAssemblySequence
      //(0076,0060)
      = const PTag._('ComponentAssemblySequence', 0x00760060,
          'Component Assembly Sequence', VR.kSQ, VM.k1, false);
  static const PTag kComponent1ReferencedID
      //(0076,0070)
      = const PTag._('Component1ReferencedID', 0x00760070, 'Component 1 Referenced ID',
          VR.kUS, VM.k1, false);
  static const PTag kComponent1ReferencedMatingFeatureSetID
      //(0076,0080)
      = const PTag._('Component1ReferencedMatingFeatureSetID', 0x00760080,
          'Component 1 Referenced Mating Feature Set ID', VR.kUS, VM.k1, false);
  static const PTag kComponent1ReferencedMatingFeatureID
      //(0076,0090)
      = const PTag._('Component1ReferencedMatingFeatureID', 0x00760090,
          'Component 1 Referenced Mating Feature ID', VR.kUS, VM.k1, false);
  static const PTag kComponent2ReferencedID
      //(0076,00A0)
      = const PTag._('Component2ReferencedID', 0x007600A0, 'Component 2 Referenced ID',
          VR.kUS, VM.k1, false);
  static const PTag kComponent2ReferencedMatingFeatureSetID
      //(0076,00B0)
      = const PTag._('Component2ReferencedMatingFeatureSetID', 0x007600B0,
          'Component 2 Referenced Mating Feature Set ID', VR.kUS, VM.k1, false);
  static const PTag kComponent2ReferencedMatingFeatureID
      //(0076,00C0)
      = const PTag._('Component2ReferencedMatingFeatureID', 0x007600C0,
          'Component 2 Referenced Mating Feature ID', VR.kUS, VM.k1, false);
  static const PTag kImplantTemplateGroupName
      //(0078,0001)
      = const PTag._('ImplantTemplateGroupName', 0x00780001,
          'Implant Template Group Name', VR.kLO, VM.k1, false);
  static const PTag kImplantTemplateGroupDescription
      //(0078,0010)
      = const PTag._('ImplantTemplateGroupDescription', 0x00780010,
          'Implant Template Group Description', VR.kST, VM.k1, false);
  static const PTag kImplantTemplateGroupIssuer
      //(0078,0020)
      = const PTag._('ImplantTemplateGroupIssuer', 0x00780020,
          'Implant Template Group Issuer', VR.kLO, VM.k1, false);
  static const PTag kImplantTemplateGroupVersion
      //(0078,0024)
      = const PTag._('ImplantTemplateGroupVersion', 0x00780024,
          'Implant Template Group Version', VR.kLO, VM.k1, false);
  static const PTag kReplacedImplantTemplateGroupSequence
      //(0078,0026)
      = const PTag._('ReplacedImplantTemplateGroupSequence', 0x00780026,
          'Replaced Implant Template Group Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantTemplateGroupTargetAnatomySequence
      //(0078,0028)
      = const PTag._('ImplantTemplateGroupTargetAnatomySequence', 0x00780028,
          'Implant Template Group Target Anatomy Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantTemplateGroupMembersSequence
      //(0078,002A)
      = const PTag._('ImplantTemplateGroupMembersSequence', 0x0078002A,
          'Implant Template Group Members Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantTemplateGroupMemberID
      //(0078,002E)
      = const PTag._('ImplantTemplateGroupMemberID', 0x0078002E,
          'Implant Template Group Member ID', VR.kUS, VM.k1, false);
  static const PTag kThreeDImplantTemplateGroupMemberMatchingPoint
      //(0078,0050)
      = const PTag._('ThreeDImplantTemplateGroupMemberMatchingPoint', 0x00780050,
          '3D Implant Template Group Member Matching Point', VR.kFD, VM.k3, false);
  static const PTag kThreeDImplantTemplateGroupMemberMatchingAxes
      //(0078,0060)
      = const PTag._('ThreeDImplantTemplateGroupMemberMatchingAxes', 0x00780060,
          '3D Implant Template Group Member Matching Axes', VR.kFD, VM.k9, false);
  static const PTag kImplantTemplateGroupMemberMatching2DCoordinatesSequence
      //(0078,0070)
      = const PTag._(
          'ImplantTemplateGroupMemberMatching2DCoordinatesSequence',
          0x00780070,
          'Implant Template Group Member Matching 2D Coordinates Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kTwoDImplantTemplateGroupMemberMatchingPoint
      //(0078,0090)
      = const PTag._('TwoDImplantTemplateGroupMemberMatchingPoint', 0x00780090,
          '2D Implant Template Group Member Matching Point', VR.kFD, VM.k2, false);
  static const PTag kTwoDImplantTemplateGroupMemberMatchingAxes
      //(0078,00A0)
      = const PTag._('TwoDImplantTemplateGroupMemberMatchingAxes', 0x007800A0,
          '2D Implant Template Group Member Matching Axes', VR.kFD, VM.k4, false);
  static const PTag kImplantTemplateGroupVariationDimensionSequence
      //(0078,00B0)
      = const PTag._('ImplantTemplateGroupVariationDimensionSequence', 0x007800B0,
          'Implant Template Group Variation Dimension Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImplantTemplateGroupVariationDimensionName
      //(0078,00B2)
      = const PTag._('ImplantTemplateGroupVariationDimensionName', 0x007800B2,
          'Implant Template Group Variation Dimension Name', VR.kLO, VM.k1, false);
  static const PTag kImplantTemplateGroupVariationDimensionRankSequence
      //(0078,00B4)
      = const PTag._(
          'ImplantTemplateGroupVariationDimensionRankSequence',
          0x007800B4,
          'Implant Template Group Variation Dimension Rank Sequence',
          VR.kSQ,
          VM.k1,
          false);
  static const PTag kReferencedImplantTemplateGroupMemberID
      //(0078,00B6)
      = const PTag._('ReferencedImplantTemplateGroupMemberID', 0x007800B6,
          'Referenced Implant Template Group Member ID', VR.kUS, VM.k1, false);
  static const PTag kImplantTemplateGroupVariationDimensionRank
      //(0078,00B8)
      = const PTag._('ImplantTemplateGroupVariationDimensionRank', 0x007800B8,
          'Implant Template Group Variation Dimension Rank', VR.kUS, VM.k1, false);
  static const PTag kSurfaceScanAcquisitionTypeCodeSequence
      //(0080,0001)
      = const PTag._('SurfaceScanAcquisitionTypeCodeSequence', 0x00800001,
          'Surface Scan Acquisition Type Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSurfaceScanModeCodeSequence
      //(0080,0002)
      = const PTag._('SurfaceScanModeCodeSequence', 0x00800002,
          'Surface Scan Mode Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRegistrationMethodCodeSequence
      //(0080,0003)
      = const PTag._('RegistrationMethodCodeSequence', 0x00800003,
          'Registration Method Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kShotDurationTime
      //(0080,0004)
      = const PTag._(
          'ShotDurationTime', 0x00800004, 'Shot Duration Time', VR.kFD, VM.k1, false);
  static const PTag kShotOffsetTime
      //(0080,0005)
      = const PTag._(
          'ShotOffsetTime', 0x00800005, 'Shot Offset Time', VR.kFD, VM.k1, false);
  static const PTag kSurfacePointPresentationValueData
      //(0080,0006)
      = const PTag._('SurfacePointPresentationValueData', 0x00800006,
          'Surface Point Presentation Value Data', VR.kUS, VM.k1_n, false);
  static const PTag kSurfacePointColorCIELabValueData
      //(0080,0007)
      = const PTag._('SurfacePointColorCIELabValueData', 0x00800007,
          'Surface Point Color CIELab Value Data', VR.kUS, VM.k3_3n, false);
  static const PTag kUVMappingSequence
      //(0080,0008)
      = const PTag._(
          'UVMappingSequence', 0x00800008, 'UV Mapping Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTextureLabel
      //(0080,0009)
      = const PTag._('TextureLabel', 0x00800009, 'Texture Label', VR.kSH, VM.k1, false);
  static const PTag kUValueData
      //(0080,0010)
      = const PTag._('UValueData', 0x00800010, 'U Value Data', VR.kOF, VM.k1_n, false);
  static const PTag kVValueData
      //(0080,0011)
      = const PTag._('VValueData', 0x00800011, 'V Value Data', VR.kOF, VM.k1_n, false);
  static const PTag kReferencedTextureSequence
      //(0080,0012)
      = const PTag._('ReferencedTextureSequence', 0x00800012,
          'Referenced Texture Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSurfaceDataSequence
      //(0080,0013)
      = const PTag._('ReferencedSurfaceDataSequence', 0x00800013,
          'Referenced Surface Data Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStorageMediaFileSetID
      //(0088,0130)
      = const PTag._('StorageMediaFileSetID', 0x00880130, 'Storage Media File-set ID',
          VR.kSH, VM.k1, false);
  static const PTag kStorageMediaFileSetUID
      //(0088,0140)
      = const PTag._('StorageMediaFileSetUID', 0x00880140, 'Storage Media File-set UID',
          VR.kUI, VM.k1, false);
  static const PTag kIconImageSequence
      //(0088,0200)
      = const PTag._(
          'IconImageSequence', 0x00880200, 'Icon Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTopicTitle
      //(0088,0904)
      = const PTag._('TopicTitle', 0x00880904, 'Topic Title', VR.kLO, VM.k1, true);
  static const PTag kTopicSubject
      //(0088,0906)
      = const PTag._('TopicSubject', 0x00880906, 'Topic Subject', VR.kST, VM.k1, true);
  static const PTag kTopicAuthor
      //(0088,0910)
      = const PTag._('TopicAuthor', 0x00880910, 'Topic Author', VR.kLO, VM.k1, true);
  static const PTag kTopicKeywords
      //(0088,0912)
      =
      const PTag._('TopicKeywords', 0x00880912, 'Topic Keywords', VR.kLO, VM.k1_32, true);
  static const PTag kSOPInstanceStatus
      //(0100,0410)
      = const PTag._(
          'SOPInstanceStatus', 0x01000410, 'SOP Instance Status', VR.kCS, VM.k1, false);
  static const PTag kSOPAuthorizationDateTime
      //(0100,0420)
      = const PTag._('SOPAuthorizationDateTime', 0x01000420, 'SOP Authorization DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kSOPAuthorizationComment
      //(0100,0424)
      = const PTag._('SOPAuthorizationComment', 0x01000424, 'SOP Authorization Comment',
          VR.kLT, VM.k1, false);
  static const PTag kAuthorizationEquipmentCertificationNumber
      //(0100,0426)
      = const PTag._('AuthorizationEquipmentCertificationNumber', 0x01000426,
          'Authorization Equipment Certification Number', VR.kLO, VM.k1, false);
  static const PTag kMACIDNumber
      //(0400,0005)
      = const PTag._('MACIDNumber', 0x04000005, 'MAC ID Number', VR.kUS, VM.k1, false);
  static const PTag kMACCalculationTransferSyntaxUID
      //(0400,0010)
      = const PTag._('MACCalculationTransferSyntaxUID', 0x04000010,
          'MAC Calculation Transfer Syntax UID', VR.kUI, VM.k1, false);
  static const PTag kMACAlgorithm
      //(0400,0015)
      = const PTag._('MACAlgorithm', 0x04000015, 'MAC Algorithm', VR.kCS, VM.k1, false);
  static const PTag kDataElementsSigned
      //(0400,0020)
      = const PTag._('DataElementsSigned', 0x04000020, 'Data Elements Signed', VR.kAT,
          VM.k1_n, false);
  static const PTag kDigitalSignatureUID
      //(0400,0100)
      = const PTag._('DigitalSignatureUID', 0x04000100, 'Digital Signature UID', VR.kUI,
          VM.k1, false);
  static const PTag kDigitalSignatureDateTime
      //(0400,0105)
      = const PTag._('DigitalSignatureDateTime', 0x04000105, 'Digital Signature DateTime',
          VR.kDT, VM.k1, false);
  static const PTag kCertificateType
      //(0400,0110)
      = const PTag._(
          'CertificateType', 0x04000110, 'Certificate Type', VR.kCS, VM.k1, false);
  static const PTag kCertificateOfSigner
      //(0400,0115)
      = const PTag._('CertificateOfSigner', 0x04000115, 'Certificate of Signer', VR.kOB,
          VM.k1, false);
  static const PTag kSignature
      //(0400,0120)
      = const PTag._('Signature', 0x04000120, 'Signature', VR.kOB, VM.k1, false);
  static const PTag kCertifiedTimestampType
      //(0400,0305)
      = const PTag._('CertifiedTimestampType', 0x04000305, 'Certified Timestamp Type',
          VR.kCS, VM.k1, false);
  static const PTag kCertifiedTimestamp
      //(0400,0310)
      = const PTag._(
          'CertifiedTimestamp', 0x04000310, 'Certified Timestamp', VR.kOB, VM.k1, false);
  static const PTag kDigitalSignaturePurposeCodeSequence
      //(0400,0401)
      = const PTag._('DigitalSignaturePurposeCodeSequence', 0x04000401,
          'Digital Signature Purpose Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedDigitalSignatureSequence
      //(0400,0402)
      = const PTag._('ReferencedDigitalSignatureSequence', 0x04000402,
          'Referenced Digital Signature Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSOPInstanceMACSequence
      //(0400,0403)
      = const PTag._('ReferencedSOPInstanceMACSequence', 0x04000403,
          'Referenced SOP Instance MAC Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMAC
      //(0400,0404)
      = const PTag._('MAC', 0x04000404, 'MAC', VR.kOB, VM.k1, false);
  static const PTag kEncryptedAttributesSequence
      //(0400,0500)
      = const PTag._('EncryptedAttributesSequence', 0x04000500,
          'Encrypted Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kEncryptedContentTransferSyntaxUID
      //(0400,0510)
      = const PTag._('EncryptedContentTransferSyntaxUID', 0x04000510,
          'Encrypted Content Transfer Syntax UID', VR.kUI, VM.k1, false);
  static const PTag kEncryptedContent
      //(0400,0520)
      = const PTag._(
          'EncryptedContent', 0x04000520, 'Encrypted Content', VR.kOB, VM.k1, false);
  static const PTag kModifiedAttributesSequence
      //(0400,0550)
      = const PTag._('ModifiedAttributesSequence', 0x04000550,
          'Modified Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kOriginalAttributesSequence
      //(0400,0561)
      = const PTag._('OriginalAttributesSequence', 0x04000561,
          'Original Attributes Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAttributeModificationDateTime
      //(0400,0562)
      = const PTag._('AttributeModificationDateTime', 0x04000562,
          'Attribute Modification DateTime', VR.kDT, VM.k1, false);
  static const PTag kModifyingSystem
      //(0400,0563)
      = const PTag._(
          'ModifyingSystem', 0x04000563, 'Modifying System', VR.kLO, VM.k1, false);
  static const PTag kSourceOfPreviousValues
      //(0400,0564)
      = const PTag._('SourceOfPreviousValues', 0x04000564, 'Source of Previous Values',
          VR.kLO, VM.k1, false);
  static const PTag kReasonForTheAttributeModification
      //(0400,0565)
      = const PTag._('ReasonForTheAttributeModification', 0x04000565,
          'Reason for the Attribute Modification', VR.kCS, VM.k1, false);
  static const PTag kEscapeTriplet
      //(1000,0000)
      = const PTag._('EscapeTriplet', 0x10000000, 'Escape Triplet', VR.kUS, VM.k3, true);
  static const PTag kRunLengthTriplet
      //(1000,0001)
      = const PTag._(
          'RunLengthTriplet', 0x10000001, 'Run Length Triplet', VR.kUS, VM.k3, true);
  static const PTag kHuffmanTableSize
      //(1000,0002)
      = const PTag._(
          'HuffmanTableSize', 0x10000002, 'Huffman Table Size', VR.kUS, VM.k1, true);
  static const PTag kHuffmanTableTriplet
      //(1000,0003)
      = const PTag._('HuffmanTableTriplet', 0x10000003, 'Huffman Table Triplet', VR.kUS,
          VM.k3, true);
  static const PTag kShiftTableSize
      //(1000,0004)
      =
      const PTag._('ShiftTableSize', 0x10000004, 'Shift Table Size', VR.kUS, VM.k1, true);
  static const PTag kShiftTableTriplet
      //(1000,0005)
      = const PTag._(
          'ShiftTableTriplet', 0x10000005, 'Shift Table Triplet', VR.kUS, VM.k3, true);
  static const PTag kZonalMap
      //(1010,0000)
      = const PTag._('ZonalMap', 0x10100000, 'Zonal Map', VR.kUS, VM.k1_n, true);
  static const PTag kNumberOfCopies
      //(2000,0010)
      = const PTag._(
          'NumberOfCopies', 0x20000010, 'Number of Copies', VR.kIS, VM.k1, false);
  static const PTag kPrinterConfigurationSequence
      //(2000,001E)
      = const PTag._('PrinterConfigurationSequence', 0x2000001E,
          'Printer Configuration Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrintPriority
      //(2000,0020)
      = const PTag._('PrintPriority', 0x20000020, 'Print Priority', VR.kCS, VM.k1, false);
  static const PTag kMediumType
      //(2000,0030)
      = const PTag._('MediumType', 0x20000030, 'Medium Type', VR.kCS, VM.k1, false);
  static const PTag kFilmDestination
      //(2000,0040)
      = const PTag._(
          'FilmDestination', 0x20000040, 'Film Destination', VR.kCS, VM.k1, false);
  static const PTag kFilmSessionLabel
      //(2000,0050)
      = const PTag._(
          'FilmSessionLabel', 0x20000050, 'Film Session Label', VR.kLO, VM.k1, false);
  static const PTag kMemoryAllocation
      //(2000,0060)
      = const PTag._(
          'MemoryAllocation', 0x20000060, 'Memory Allocation', VR.kIS, VM.k1, false);
  static const PTag kMaximumMemoryAllocation
      //(2000,0061)
      = const PTag._('MaximumMemoryAllocation', 0x20000061, 'Maximum Memory Allocation',
          VR.kIS, VM.k1, false);
  static const PTag kColorImagePrintingFlag
      //(2000,0062)
      = const PTag._('ColorImagePrintingFlag', 0x20000062, 'Color Image Printing Flag',
          VR.kCS, VM.k1, true);
  static const PTag kCollationFlag
      //(2000,0063)
      = const PTag._('CollationFlag', 0x20000063, 'Collation Flag', VR.kCS, VM.k1, true);
  static const PTag kAnnotationFlag
      //(2000,0065)
      =
      const PTag._('AnnotationFlag', 0x20000065, 'Annotation Flag', VR.kCS, VM.k1, true);
  static const PTag kImageOverlayFlag
      //(2000,0067)
      = const PTag._(
          'ImageOverlayFlag', 0x20000067, 'Image Overlay Flag', VR.kCS, VM.k1, true);
  static const PTag kPresentationLUTFlag
      //(2000,0069)
      = const PTag._('PresentationLUTFlag', 0x20000069, 'Presentation LUT Flag', VR.kCS,
          VM.k1, true);
  static const PTag kImageBoxPresentationLUTFlag
      //(2000,006A)
      = const PTag._('ImageBoxPresentationLUTFlag', 0x2000006A,
          'Image Box Presentation LUT Flag', VR.kCS, VM.k1, true);
  static const PTag kMemoryBitDepth
      //(2000,00A0)
      = const PTag._(
          'MemoryBitDepth', 0x200000A0, 'Memory Bit Depth', VR.kUS, VM.k1, false);
  static const PTag kPrintingBitDepth
      //(2000,00A1)
      = const PTag._(
          'PrintingBitDepth', 0x200000A1, 'Printing Bit Depth', VR.kUS, VM.k1, false);
  static const PTag kMediaInstalledSequence
      //(2000,00A2)
      = const PTag._('MediaInstalledSequence', 0x200000A2, 'Media Installed Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kOtherMediaAvailableSequence
      //(2000,00A4)
      = const PTag._('OtherMediaAvailableSequence', 0x200000A4,
          'Other Media Available Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSupportedImageDisplayFormatsSequence
      //(2000,00A8)
      = const PTag._('SupportedImageDisplayFormatsSequence', 0x200000A8,
          'Supported Image Display Formats Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedFilmBoxSequence
      //(2000,0500)
      = const PTag._('ReferencedFilmBoxSequence', 0x20000500,
          'Referenced Film Box Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedStoredPrintSequence
      //(2000,0510)
      = const PTag._('ReferencedStoredPrintSequence', 0x20000510,
          'Referenced Stored Print Sequence', VR.kSQ, VM.k1, true);
  static const PTag kImageDisplayFormat
      //(2010,0010)
      = const PTag._(
          'ImageDisplayFormat', 0x20100010, 'Image Display Format', VR.kST, VM.k1, false);
  static const PTag kAnnotationDisplayFormatID
      //(2010,0030)
      = const PTag._('AnnotationDisplayFormatID', 0x20100030,
          'Annotation Display Format ID', VR.kCS, VM.k1, false);
  static const PTag kFilmOrientation
      //(2010,0040)
      = const PTag._(
          'FilmOrientation', 0x20100040, 'Film Orientation', VR.kCS, VM.k1, false);
  static const PTag kFilmSizeID
      //(2010,0050)
      = const PTag._('FilmSizeID', 0x20100050, 'Film Size ID', VR.kCS, VM.k1, false);
  static const PTag kPrinterResolutionID
      //(2010,0052)
      = const PTag._('PrinterResolutionID', 0x20100052, 'Printer Resolution ID', VR.kCS,
          VM.k1, false);
  static const PTag kDefaultPrinterResolutionID
      //(2010,0054)
      = const PTag._('DefaultPrinterResolutionID', 0x20100054,
          'Default Printer Resolution ID', VR.kCS, VM.k1, false);
  static const PTag kMagnificationType
      //(2010,0060)
      = const PTag._(
          'MagnificationType', 0x20100060, 'Magnification Type', VR.kCS, VM.k1, false);
  static const PTag kSmoothingType
      //(2010,0080)
      = const PTag._('SmoothingType', 0x20100080, 'Smoothing Type', VR.kCS, VM.k1, false);
  static const PTag kDefaultMagnificationType
      //(2010,00A6)
      = const PTag._('DefaultMagnificationType', 0x201000A6, 'Default Magnification Type',
          VR.kCS, VM.k1, false);
  static const PTag kOtherMagnificationTypesAvailable
      //(2010,00A7)
      = const PTag._('OtherMagnificationTypesAvailable', 0x201000A7,
          'Other Magnification Types Available', VR.kCS, VM.k1_n, false);
  static const PTag kDefaultSmoothingType
      //(2010,00A8)
      = const PTag._('DefaultSmoothingType', 0x201000A8, 'Default Smoothing Type', VR.kCS,
          VM.k1, false);
  static const PTag kOtherSmoothingTypesAvailable
      //(2010,00A9)
      = const PTag._('OtherSmoothingTypesAvailable', 0x201000A9,
          'Other Smoothing Types Available', VR.kCS, VM.k1_n, false);
  static const PTag kBorderDensity
      //(2010,0100)
      = const PTag._('BorderDensity', 0x20100100, 'Border Density', VR.kCS, VM.k1, false);
  static const PTag kEmptyImageDensity
      //(2010,0110)
      = const PTag._(
          'EmptyImageDensity', 0x20100110, 'Empty Image Density', VR.kCS, VM.k1, false);
  static const PTag kMinDensity
      //(2010,0120)
      = const PTag._('MinDensity', 0x20100120, 'Min Density', VR.kUS, VM.k1, false);
  static const PTag kMaxDensity
      //(2010,0130)
      = const PTag._('MaxDensity', 0x20100130, 'Max Density', VR.kUS, VM.k1, false);
  static const PTag kTrim
      //(2010,0140)
      = const PTag._('Trim', 0x20100140, 'Trim', VR.kCS, VM.k1, false);
  static const PTag kConfigurationInformation
      //(2010,0150)
      = const PTag._('ConfigurationInformation', 0x20100150, 'Configuration Information',
          VR.kST, VM.k1, false);
  static const PTag kConfigurationInformationDescription
      //(2010,0152)
      = const PTag._('ConfigurationInformationDescription', 0x20100152,
          'Configuration Information Description', VR.kLT, VM.k1, false);
  static const PTag kMaximumCollatedFilms
      //(2010,0154)
      = const PTag._('MaximumCollatedFilms', 0x20100154, 'Maximum Collated Films', VR.kIS,
          VM.k1, false);
  static const PTag kIllumination
      //(2010,015E)
      = const PTag._('Illumination', 0x2010015E, 'Illumination', VR.kUS, VM.k1, false);
  static const PTag kReflectedAmbientLight
      //(2010,0160)
      = const PTag._('ReflectedAmbientLight', 0x20100160, 'Reflected Ambient Light',
          VR.kUS, VM.k1, false);
  static const PTag kPrinterPixelSpacing
      //(2010,0376)
      = const PTag._('PrinterPixelSpacing', 0x20100376, 'Printer Pixel Spacing', VR.kDS,
          VM.k2, false);
  static const PTag kReferencedFilmSessionSequence
      //(2010,0500)
      = const PTag._('ReferencedFilmSessionSequence', 0x20100500,
          'Referenced Film Session Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedImageBoxSequence
      //(2010,0510)
      = const PTag._('ReferencedImageBoxSequence', 0x20100510,
          'Referenced Image Box Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedBasicAnnotationBoxSequence
      //(2010,0520)
      = const PTag._('ReferencedBasicAnnotationBoxSequence', 0x20100520,
          'Referenced Basic Annotation Box Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImageBoxPosition
      //(2020,0010)
      = const PTag._(
          'ImageBoxPosition', 0x20200010, 'Image Box Position', VR.kUS, VM.k1, false);
  static const PTag kPolarity
      //(2020,0020)
      = const PTag._('Polarity', 0x20200020, 'Polarity', VR.kCS, VM.k1, false);
  static const PTag kRequestedImageSize
      //(2020,0030)
      = const PTag._(
          'RequestedImageSize', 0x20200030, 'Requested Image Size', VR.kDS, VM.k1, false);
  static const PTag kRequestedDecimateCropBehavior
      //(2020,0040)
      = const PTag._('RequestedDecimateCropBehavior', 0x20200040,
          'Requested Decimate/Crop Behavior', VR.kCS, VM.k1, false);
  static const PTag kRequestedResolutionID
      //(2020,0050)
      = const PTag._('RequestedResolutionID', 0x20200050, 'Requested Resolution ID',
          VR.kCS, VM.k1, false);
  static const PTag kRequestedImageSizeFlag
      //(2020,00A0)
      = const PTag._('RequestedImageSizeFlag', 0x202000A0, 'Requested Image Size Flag',
          VR.kCS, VM.k1, false);
  static const PTag kDecimateCropResult
      //(2020,00A2)
      = const PTag._(
          'DecimateCropResult', 0x202000A2, 'Decimate/Crop Result', VR.kCS, VM.k1, false);
  static const PTag kBasicGrayscaleImageSequence
      //(2020,0110)
      = const PTag._('BasicGrayscaleImageSequence', 0x20200110,
          'Basic Grayscale Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBasicColorImageSequence
      //(2020,0111)
      = const PTag._('BasicColorImageSequence', 0x20200111, 'Basic Color Image Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedImageOverlayBoxSequence
      //(2020,0130)
      = const PTag._('ReferencedImageOverlayBoxSequence', 0x20200130,
          'Referenced Image Overlay Box Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedVOILUTBoxSequence
      //(2020,0140)
      = const PTag._('ReferencedVOILUTBoxSequence', 0x20200140,
          'Referenced VOI LUT Box Sequence', VR.kSQ, VM.k1, true);
  static const PTag kAnnotationPosition
      //(2030,0010)
      = const PTag._(
          'AnnotationPosition', 0x20300010, 'Annotation Position', VR.kUS, VM.k1, false);
  static const PTag kTextString
      //(2030,0020)
      = const PTag._('TextString', 0x20300020, 'Text String', VR.kLO, VM.k1, false);
  static const PTag kReferencedOverlayPlaneSequence
      //(2040,0010)
      = const PTag._('ReferencedOverlayPlaneSequence', 0x20400010,
          'Referenced Overlay Plane Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedOverlayPlaneGroups
      //(2040,0011)
      = const PTag._('ReferencedOverlayPlaneGroups', 0x20400011,
          'Referenced Overlay Plane Groups', VR.kUS, VM.k1_99, true);
  static const PTag kOverlayPixelDataSequence
      //(2040,0020)
      = const PTag._('OverlayPixelDataSequence', 0x20400020,
          'Overlay Pixel Data Sequence', VR.kSQ, VM.k1, true);
  static const PTag kOverlayMagnificationType
      //(2040,0060)
      = const PTag._('OverlayMagnificationType', 0x20400060, 'Overlay Magnification Type',
          VR.kCS, VM.k1, true);
  static const PTag kOverlaySmoothingType
      //(2040,0070)
      = const PTag._('OverlaySmoothingType', 0x20400070, 'Overlay Smoothing Type', VR.kCS,
          VM.k1, true);
  static const PTag kOverlayOrImageMagnification
      //(2040,0072)
      = const PTag._('OverlayOrImageMagnification', 0x20400072,
          'Overlay or Image Magnification', VR.kCS, VM.k1, true);
  static const PTag kMagnifyToNumberOfColumns
      //(2040,0074)
      = const PTag._('MagnifyToNumberOfColumns', 0x20400074,
          'Magnify to Number of Columns', VR.kUS, VM.k1, true);
  static const PTag kOverlayForegroundDensity
      //(2040,0080)
      = const PTag._('OverlayForegroundDensity', 0x20400080, 'Overlay Foreground Density',
          VR.kCS, VM.k1, true);
  static const PTag kOverlayBackgroundDensity
      //(2040,0082)
      = const PTag._('OverlayBackgroundDensity', 0x20400082, 'Overlay Background Density',
          VR.kCS, VM.k1, true);
  static const PTag kOverlayMode
      //(2040,0090)
      = const PTag._('OverlayMode', 0x20400090, 'Overlay Mode', VR.kCS, VM.k1, true);
  static const PTag kThresholdDensity
      //(2040,0100)
      = const PTag._(
          'ThresholdDensity', 0x20400100, 'Threshold Density', VR.kCS, VM.k1, true);
  static const PTag kReferencedImageBoxSequenceRetired
      //(2040,0500)
      = const PTag._('ReferencedImageBoxSequenceRetired', 0x20400500,
          'Referenced Image Box Sequence (Retired)', VR.kSQ, VM.k1, true);
  static const PTag kPresentationLUTSequence
      //(2050,0010)
      = const PTag._('PresentationLUTSequence', 0x20500010, 'Presentation LUT Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kPresentationLUTShape
      //(2050,0020)
      = const PTag._('PresentationLUTShape', 0x20500020, 'Presentation LUT Shape', VR.kCS,
          VM.k1, false);
  static const PTag kReferencedPresentationLUTSequence
      //(2050,0500)
      = const PTag._('ReferencedPresentationLUTSequence', 0x20500500,
          'Referenced Presentation LUT Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPrintJobID
      //(2100,0010)
      = const PTag._('PrintJobID', 0x21000010, 'Print Job ID', VR.kSH, VM.k1, true);
  static const PTag kExecutionStatus
      //(2100,0020)
      = const PTag._(
          'ExecutionStatus', 0x21000020, 'Execution Status', VR.kCS, VM.k1, false);
  static const PTag kExecutionStatusInfo
      //(2100,0030)
      = const PTag._('ExecutionStatusInfo', 0x21000030, 'Execution Status Info', VR.kCS,
          VM.k1, false);
  static const PTag kCreationDate
      //(2100,0040)
      = const PTag._('CreationDate', 0x21000040, 'Creation Date', VR.kDA, VM.k1, false);
  static const PTag kCreationTime
      //(2100,0050)
      = const PTag._('CreationTime', 0x21000050, 'Creation Time', VR.kTM, VM.k1, false);
  static const PTag kOriginator
      //(2100,0070)
      = const PTag._('Originator', 0x21000070, 'Originator', VR.kAE, VM.k1, false);
  static const PTag kDestinationAE
      //(2100,0140)
      = const PTag._('DestinationAE', 0x21000140, 'Destination AE', VR.kAE, VM.k1, true);
  static const PTag kOwnerID
      //(2100,0160)
      = const PTag._('OwnerID', 0x21000160, 'Owner ID', VR.kSH, VM.k1, false);
  static const PTag kNumberOfFilms
      //(2100,0170)
      =
      const PTag._('NumberOfFilms', 0x21000170, 'Number of Films', VR.kIS, VM.k1, false);
  static const PTag kReferencedPrintJobSequencePullStoredPrint
      //(2100,0500)
      = const PTag._('ReferencedPrintJobSequencePullStoredPrint', 0x21000500,
          'Referenced Print Job Sequence (Pull Stored Print)', VR.kSQ, VM.k1, true);
  static const PTag kPrinterStatus
      //(2110,0010)
      = const PTag._('PrinterStatus', 0x21100010, 'Printer Status', VR.kCS, VM.k1, false);
  static const PTag kPrinterStatusInfo
      //(2110,0020)
      = const PTag._(
          'PrinterStatusInfo', 0x21100020, 'Printer Status Info', VR.kCS, VM.k1, false);
  static const PTag kPrinterName
      //(2110,0030)
      = const PTag._('PrinterName', 0x21100030, 'Printer Name', VR.kLO, VM.k1, false);
  static const PTag kPrintQueueID
      //(2110,0099)
      = const PTag._('PrintQueueID', 0x21100099, 'Print Queue ID', VR.kSH, VM.k1, true);
  static const PTag kQueueStatus
      //(2120,0010)
      = const PTag._('QueueStatus', 0x21200010, 'Queue Status', VR.kCS, VM.k1, true);
  static const PTag kPrintJobDescriptionSequence
      //(2120,0050)
      = const PTag._('PrintJobDescriptionSequence', 0x21200050,
          'Print Job Description Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReferencedPrintJobSequence
      //(2120,0070)
      = const PTag._('ReferencedPrintJobSequence', 0x21200070,
          'Referenced Print Job Sequence', VR.kSQ, VM.k1, true);
  static const PTag kPrintManagementCapabilitiesSequence
      //(2130,0010)
      = const PTag._('PrintManagementCapabilitiesSequence', 0x21300010,
          'Print Management Capabilities Sequence', VR.kSQ, VM.k1, true);
  static const PTag kPrinterCharacteristicsSequence
      //(2130,0015)
      = const PTag._('PrinterCharacteristicsSequence', 0x21300015,
          'Printer Characteristics Sequence', VR.kSQ, VM.k1, true);
  static const PTag kFilmBoxContentSequence
      //(2130,0030)
      = const PTag._('FilmBoxContentSequence', 0x21300030, 'Film Box Content Sequence',
          VR.kSQ, VM.k1, true);
  static const PTag kImageBoxContentSequence
      //(2130,0040)
      = const PTag._('ImageBoxContentSequence', 0x21300040, 'Image Box Content Sequence',
          VR.kSQ, VM.k1, true);
  static const PTag kAnnotationContentSequence
      //(2130,0050)
      = const PTag._('AnnotationContentSequence', 0x21300050,
          'Annotation Content Sequence', VR.kSQ, VM.k1, true);
  static const PTag kImageOverlayBoxContentSequence
      //(2130,0060)
      = const PTag._('ImageOverlayBoxContentSequence', 0x21300060,
          'Image Overlay Box Content Sequence', VR.kSQ, VM.k1, true);
  static const PTag kPresentationLUTContentSequence
      //(2130,0080)
      = const PTag._('PresentationLUTContentSequence', 0x21300080,
          'Presentation LUT Content Sequence', VR.kSQ, VM.k1, true);
  static const PTag kProposedStudySequence
      //(2130,00A0)
      = const PTag._('ProposedStudySequence', 0x213000A0, 'Proposed Study Sequence',
          VR.kSQ, VM.k1, true);
  static const PTag kOriginalImageSequence
      //(2130,00C0)
      = const PTag._('OriginalImageSequence', 0x213000C0, 'Original Image Sequence',
          VR.kSQ, VM.k1, true);
  static const PTag kLabelUsingInformationExtractedFromInstances
      //(2200,0001)
      = const PTag._('LabelUsingInformationExtractedFromInstances', 0x22000001,
          'Label Using Information Extracted From Instances', VR.kCS, VM.k1, false);
  static const PTag kLabelText
      //(2200,0002)
      = const PTag._('LabelText', 0x22000002, 'Label Text', VR.kUT, VM.k1, false);
  static const PTag kLabelStyleSelection
      //(2200,0003)
      = const PTag._('LabelStyleSelection', 0x22000003, 'Label Style Selection', VR.kCS,
          VM.k1, false);
  static const PTag kMediaDisposition
      //(2200,0004)
      = const PTag._(
          'MediaDisposition', 0x22000004, 'Media Disposition', VR.kLT, VM.k1, false);
  static const PTag kBarcodeValue
      //(2200,0005)
      = const PTag._('BarcodeValue', 0x22000005, 'Barcode Value', VR.kLT, VM.k1, false);
  static const PTag kBarcodeSymbology
      //(2200,0006)
      = const PTag._(
          'BarcodeSymbology', 0x22000006, 'Barcode Symbology', VR.kCS, VM.k1, false);
  static const PTag kAllowMediaSplitting
      //(2200,0007)
      = const PTag._('AllowMediaSplitting', 0x22000007, 'Allow Media Splitting', VR.kCS,
          VM.k1, false);
  static const PTag kIncludeNonDICOMObjects
      //(2200,0008)
      = const PTag._('IncludeNonDICOMObjects', 0x22000008, 'Include Non-DICOM Objects',
          VR.kCS, VM.k1, false);
  static const PTag kIncludeDisplayApplication
      //(2200,0009)
      = const PTag._('IncludeDisplayApplication', 0x22000009,
          'Include Display Application', VR.kCS, VM.k1, false);
  static const PTag kPreserveCompositeInstancesAfterMediaCreation
      //(2200,000A)
      = const PTag._('PreserveCompositeInstancesAfterMediaCreation', 0x2200000A,
          'Preserve Composite Instances After Media Creation', VR.kCS, VM.k1, false);
  static const PTag kTotalNumberOfPiecesOfMediaCreated
      //(2200,000B)
      = const PTag._('TotalNumberOfPiecesOfMediaCreated', 0x2200000B,
          'Total Number of Pieces of Media Created', VR.kUS, VM.k1, false);
  static const PTag kRequestedMediaApplicationProfile
      //(2200,000C)
      = const PTag._('RequestedMediaApplicationProfile', 0x2200000C,
          'Requested Media Application Profile', VR.kLO, VM.k1, false);
  static const PTag kReferencedStorageMediaSequence
      //(2200,000D)
      = const PTag._('ReferencedStorageMediaSequence', 0x2200000D,
          'Referenced Storage Media Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFailureAttributes
      //(2200,000E)
      = const PTag._(
          'FailureAttributes', 0x2200000E, 'Failure Attributes', VR.kAT, VM.k1_n, false);
  static const PTag kAllowLossyCompression
      //(2200,000F)
      = const PTag._('AllowLossyCompression', 0x2200000F, 'Allow Lossy Compression',
          VR.kCS, VM.k1, false);
  static const PTag kRequestPriority
      //(2200,0020)
      = const PTag._(
          'RequestPriority', 0x22000020, 'Request Priority', VR.kCS, VM.k1, false);
  static const PTag kRTImageLabel
      //(3002,0002)
      = const PTag._('RTImageLabel', 0x30020002, 'RT Image Label', VR.kSH, VM.k1, false);
  static const PTag kRTImageName
      //(3002,0003)
      = const PTag._('RTImageName', 0x30020003, 'RT Image Name', VR.kLO, VM.k1, false);
  static const PTag kRTImageDescription
      //(3002,0004)
      = const PTag._(
          'RTImageDescription', 0x30020004, 'RT Image Description', VR.kST, VM.k1, false);
  static const PTag kReportedValuesOrigin
      //(3002,000A)
      = const PTag._('ReportedValuesOrigin', 0x3002000A, 'Reported Values Origin', VR.kCS,
          VM.k1, false);
  static const PTag kRTImagePlane
      //(3002,000C)
      = const PTag._('RTImagePlane', 0x3002000C, 'RT Image Plane', VR.kCS, VM.k1, false);
  static const PTag kXRayImageReceptorTranslation
      //(3002,000D)
      = const PTag._('XRayImageReceptorTranslation', 0x3002000D,
          'X-Ray Image Receptor Translation', VR.kDS, VM.k3, false);
  static const PTag kXRayImageReceptorAngle
      //(3002,000E)
      = const PTag._('XRayImageReceptorAngle', 0x3002000E, 'X-Ray Image Receptor Angle',
          VR.kDS, VM.k1, false);
  static const PTag kRTImageOrientation
      //(3002,0010)
      = const PTag._(
          'RTImageOrientation', 0x30020010, 'RT Image Orientation', VR.kDS, VM.k6, false);
  static const PTag kImagePlanePixelSpacing
      //(3002,0011)
      = const PTag._('ImagePlanePixelSpacing', 0x30020011, 'Image Plane Pixel Spacing',
          VR.kDS, VM.k2, false);
  static const PTag kRTImagePosition
      //(3002,0012)
      = const PTag._(
          'RTImagePosition', 0x30020012, 'RT Image Position', VR.kDS, VM.k2, false);
  static const PTag kRadiationMachineName
      //(3002,0020)
      = const PTag._('RadiationMachineName', 0x30020020, 'Radiation Machine Name', VR.kSH,
          VM.k1, false);
  static const PTag kRadiationMachineSAD
      //(3002,0022)
      = const PTag._('RadiationMachineSAD', 0x30020022, 'Radiation Machine SAD', VR.kDS,
          VM.k1, false);
  static const PTag kRadiationMachineSSD
      //(3002,0024)
      = const PTag._('RadiationMachineSSD', 0x30020024, 'Radiation Machine SSD', VR.kDS,
          VM.k1, false);
  static const PTag kRTImageSID
      //(3002,0026)
      = const PTag._('RTImageSID', 0x30020026, 'RT Image SID', VR.kDS, VM.k1, false);
  static const PTag kSourceToReferenceObjectDistance
      //(3002,0028)
      = const PTag._('SourceToReferenceObjectDistance', 0x30020028,
          'Source to Reference Object Distance', VR.kDS, VM.k1, false);
  static const PTag kFractionNumber
      //(3002,0029)
      =
      const PTag._('FractionNumber', 0x30020029, 'Fraction Number', VR.kIS, VM.k1, false);
  static const PTag kExposureSequence
      //(3002,0030)
      = const PTag._(
          'ExposureSequence', 0x30020030, 'Exposure Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMetersetExposure
      //(3002,0032)
      = const PTag._(
          'MetersetExposure', 0x30020032, 'Meterset Exposure', VR.kDS, VM.k1, false);
  static const PTag kDiaphragmPosition
      //(3002,0034)
      = const PTag._(
          'DiaphragmPosition', 0x30020034, 'Diaphragm Position', VR.kDS, VM.k4, false);
  static const PTag kFluenceMapSequence
      //(3002,0040)
      = const PTag._(
          'FluenceMapSequence', 0x30020040, 'Fluence Map Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFluenceDataSource
      //(3002,0041)
      = const PTag._(
          'FluenceDataSource', 0x30020041, 'Fluence Data Source', VR.kCS, VM.k1, false);
  static const PTag kFluenceDataScale
      //(3002,0042)
      = const PTag._(
          'FluenceDataScale', 0x30020042, 'Fluence Data Scale', VR.kDS, VM.k1, false);
  static const PTag kPrimaryFluenceModeSequence
      //(3002,0050)
      = const PTag._('PrimaryFluenceModeSequence', 0x30020050,
          'Primary Fluence Mode Sequence', VR.kSQ, VM.k1, false);
  static const PTag kFluenceMode
      //(3002,0051)
      = const PTag._('FluenceMode', 0x30020051, 'Fluence Mode', VR.kCS, VM.k1, false);
  static const PTag kFluenceModeID
      //(3002,0052)
      =
      const PTag._('FluenceModeID', 0x30020052, 'Fluence Mode ID', VR.kSH, VM.k1, false);
  static const PTag kDVHType
      //(3004,0001)
      = const PTag._('DVHType', 0x30040001, 'DVH Type', VR.kCS, VM.k1, false);
  static const PTag kDoseUnits
      //(3004,0002)
      = const PTag._('DoseUnits', 0x30040002, 'Dose Units', VR.kCS, VM.k1, false);
  static const PTag kDoseType
      //(3004,0004)
      = const PTag._('DoseType', 0x30040004, 'Dose Type', VR.kCS, VM.k1, false);
  static const PTag kSpatialTransformOfDose
      //(3004,0005)
      = const PTag._('SpatialTransformOfDose', 0x30040005, 'Spatial Transform of Dose',
          VR.kCS, VM.k1, false);
  static const PTag kDoseComment
      //(3004,0006)
      = const PTag._('DoseComment', 0x30040006, 'Dose Comment', VR.kLO, VM.k1, false);
  static const PTag kNormalizationPoint
      //(3004,0008)
      = const PTag._(
          'NormalizationPoint', 0x30040008, 'Normalization Point', VR.kDS, VM.k3, false);
  static const PTag kDoseSummationType
      //(3004,000A)
      = const PTag._(
          'DoseSummationType', 0x3004000A, 'Dose Summation Type', VR.kCS, VM.k1, false);
  static const PTag kGridFrameOffsetVector
      //(3004,000C)
      = const PTag._('GridFrameOffsetVector', 0x3004000C, 'Grid Frame Offset Vector',
          VR.kDS, VM.k2_n, false);
  static const PTag kDoseGridScaling
      //(3004,000E)
      = const PTag._(
          'DoseGridScaling', 0x3004000E, 'Dose Grid Scaling', VR.kDS, VM.k1, false);
  static const PTag kRTDoseROISequence
      //(3004,0010)
      = const PTag._(
          'RTDoseROISequence', 0x30040010, 'RT Dose ROI Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDoseValue
      //(3004,0012)
      = const PTag._('DoseValue', 0x30040012, 'Dose Value', VR.kDS, VM.k1, false);
  static const PTag kTissueHeterogeneityCorrection
      //(3004,0014)
      = const PTag._('TissueHeterogeneityCorrection', 0x30040014,
          'Tissue Heterogeneity Correction', VR.kCS, VM.k1_3, false);
  static const PTag kDVHNormalizationPoint
      //(3004,0040)
      = const PTag._('DVHNormalizationPoint', 0x30040040, 'DVH Normalization Point',
          VR.kDS, VM.k3, false);
  static const PTag kDVHNormalizationDoseValue
      //(3004,0042)
      = const PTag._('DVHNormalizationDoseValue', 0x30040042,
          'DVH Normalization Dose Value', VR.kDS, VM.k1, false);
  static const PTag kDVHSequence
      //(3004,0050)
      = const PTag._('DVHSequence', 0x30040050, 'DVH Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDVHDoseScaling
      //(3004,0052)
      = const PTag._(
          'DVHDoseScaling', 0x30040052, 'DVH Dose Scaling', VR.kDS, VM.k1, false);
  static const PTag kDVHVolumeUnits
      //(3004,0054)
      = const PTag._(
          'DVHVolumeUnits', 0x30040054, 'DVH Volume Units', VR.kCS, VM.k1, false);
  static const PTag kDVHNumberOfBins
      //(3004,0056)
      = const PTag._(
          'DVHNumberOfBins', 0x30040056, 'DVH Number of Bins', VR.kIS, VM.k1, false);
  static const PTag kDVHData
      //(3004,0058)
      = const PTag._('DVHData', 0x30040058, 'DVH Data', VR.kDS, VM.k2_2n, false);
  static const PTag kDVHReferencedROISequence
      //(3004,0060)
      = const PTag._('DVHReferencedROISequence', 0x30040060,
          'DVH Referenced ROI Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDVHROIContributionType
      //(3004,0062)
      = const PTag._('DVHROIContributionType', 0x30040062, 'DVH ROI Contribution Type',
          VR.kCS, VM.k1, false);
  static const PTag kDVHMinimumDose
      //(3004,0070)
      = const PTag._(
          'DVHMinimumDose', 0x30040070, 'DVH Minimum Dose', VR.kDS, VM.k1, false);
  static const PTag kDVHMaximumDose
      //(3004,0072)
      = const PTag._(
          'DVHMaximumDose', 0x30040072, 'DVH Maximum Dose', VR.kDS, VM.k1, false);
  static const PTag kDVHMeanDose
      //(3004,0074)
      = const PTag._('DVHMeanDose', 0x30040074, 'DVH Mean Dose', VR.kDS, VM.k1, false);
  static const PTag kStructureSetLabel
      //(3006,0002)
      = const PTag._(
          'StructureSetLabel', 0x30060002, 'Structure Set Label', VR.kSH, VM.k1, false);
  static const PTag kStructureSetName
      //(3006,0004)
      = const PTag._(
          'StructureSetName', 0x30060004, 'Structure Set Name', VR.kLO, VM.k1, false);
  static const PTag kStructureSetDescription
      //(3006,0006)
      = const PTag._('StructureSetDescription', 0x30060006, 'Structure Set Description',
          VR.kST, VM.k1, false);
  static const PTag kStructureSetDate
      //(3006,0008)
      = const PTag._(
          'StructureSetDate', 0x30060008, 'Structure Set Date', VR.kDA, VM.k1, false);
  static const PTag kStructureSetTime
      //(3006,0009)
      = const PTag._(
          'StructureSetTime', 0x30060009, 'Structure Set Time', VR.kTM, VM.k1, false);
  static const PTag kReferencedFrameOfReferenceSequence
      //(3006,0010)
      = const PTag._('ReferencedFrameOfReferenceSequence', 0x30060010,
          'Referenced Frame of Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRTReferencedStudySequence
      //(3006,0012)
      = const PTag._('RTReferencedStudySequence', 0x30060012,
          'RT Referenced Study Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRTReferencedSeriesSequence
      //(3006,0014)
      = const PTag._('RTReferencedSeriesSequence', 0x30060014,
          'RT Referenced Series Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContourImageSequence
      //(3006,0016)
      = const PTag._('ContourImageSequence', 0x30060016, 'Contour Image Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kPredecessorStructureSetSequence
      //(3006,0018)
      = const PTag._('PredecessorStructureSetSequence', 0x30060018,
          'Predecessor Structure Set Sequence', VR.kSQ, VM.k1, false);
  static const PTag kStructureSetROISequence
      //(3006,0020)
      = const PTag._('StructureSetROISequence', 0x30060020, 'Structure Set ROI Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kROINumber
      //(3006,0022)
      = const PTag._('ROINumber', 0x30060022, 'ROI Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedFrameOfReferenceUID
      //(3006,0024)
      = const PTag._('ReferencedFrameOfReferenceUID', 0x30060024,
          'Referenced Frame of Reference UID', VR.kUI, VM.k1, false);
  static const PTag kROIName
      //(3006,0026)
      = const PTag._('ROIName', 0x30060026, 'ROI Name', VR.kLO, VM.k1, false);
  static const PTag kROIDescription
      //(3006,0028)
      =
      const PTag._('ROIDescription', 0x30060028, 'ROI Description', VR.kST, VM.k1, false);
  static const PTag kROIDisplayColor
      //(3006,002A)
      = const PTag._(
          'ROIDisplayColor', 0x3006002A, 'ROI Display Color', VR.kIS, VM.k3, false);
  static const PTag kROIVolume
      //(3006,002C)
      = const PTag._('ROIVolume', 0x3006002C, 'ROI Volume', VR.kDS, VM.k1, false);
  static const PTag kRTRelatedROISequence
      //(3006,0030)
      = const PTag._('RTRelatedROISequence', 0x30060030, 'RT Related ROI Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kRTROIRelationship
      //(3006,0033)
      = const PTag._(
          'RTROIRelationship', 0x30060033, 'RT ROI Relationship', VR.kCS, VM.k1, false);
  static const PTag kROIGenerationAlgorithm
      //(3006,0036)
      = const PTag._('ROIGenerationAlgorithm', 0x30060036, 'ROI Generation Algorithm',
          VR.kCS, VM.k1, false);
  static const PTag kROIGenerationDescription
      //(3006,0038)
      = const PTag._('ROIGenerationDescription', 0x30060038, 'ROI Generation Description',
          VR.kLO, VM.k1, false);
  static const PTag kROIContourSequence
      //(3006,0039)
      = const PTag._(
          'ROIContourSequence', 0x30060039, 'ROI Contour Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContourSequence
      //(3006,0040)
      = const PTag._(
          'ContourSequence', 0x30060040, 'Contour Sequence', VR.kSQ, VM.k1, false);
  static const PTag kContourGeometricType
      //(3006,0042)
      = const PTag._('ContourGeometricType', 0x30060042, 'Contour Geometric Type', VR.kCS,
          VM.k1, false);
  static const PTag kContourSlabThickness
      //(3006,0044)
      = const PTag._('ContourSlabThickness', 0x30060044, 'Contour Slab Thickness', VR.kDS,
          VM.k1, false);
  static const PTag kContourOffsetVector
      //(3006,0045)
      = const PTag._('ContourOffsetVector', 0x30060045, 'Contour Offset Vector', VR.kDS,
          VM.k3, false);
  static const PTag kNumberOfContourPoints
      //(3006,0046)
      = const PTag._('NumberOfContourPoints', 0x30060046, 'Number of Contour Points',
          VR.kIS, VM.k1, false);
  static const PTag kContourNumber
      //(3006,0048)
      = const PTag._('ContourNumber', 0x30060048, 'Contour Number', VR.kIS, VM.k1, false);
  static const PTag kAttachedContours
      //(3006,0049)
      = const PTag._(
          'AttachedContours', 0x30060049, 'Attached Contours', VR.kIS, VM.k1_n, false);
  static const PTag kContourData
      //(3006,0050)
      = const PTag._('ContourData', 0x30060050, 'Contour Data', VR.kDS, VM.k3_3n, false);
  static const PTag kRTROIObservationsSequence
      //(3006,0080)
      = const PTag._('RTROIObservationsSequence', 0x30060080,
          'RT ROI Observations Sequence', VR.kSQ, VM.k1, false);
  static const PTag kObservationNumber
      //(3006,0082)
      = const PTag._(
          'ObservationNumber', 0x30060082, 'Observation Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedROINumber
      //(3006,0084)
      = const PTag._('ReferencedROINumber', 0x30060084, 'Referenced ROI Number', VR.kIS,
          VM.k1, false);
  static const PTag kROIObservationLabel
      //(3006,0085)
      = const PTag._('ROIObservationLabel', 0x30060085, 'ROI Observation Label', VR.kSH,
          VM.k1, false);
  static const PTag kRTROIIdentificationCodeSequence
      //(3006,0086)
      = const PTag._('RTROIIdentificationCodeSequence', 0x30060086,
          'RT ROI Identification Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kROIObservationDescription
      //(3006,0088)
      = const PTag._('ROIObservationDescription', 0x30060088,
          'ROI Observation Description', VR.kST, VM.k1, false);
  static const PTag kRelatedRTROIObservationsSequence
      //(3006,00A0)
      = const PTag._('RelatedRTROIObservationsSequence', 0x300600A0,
          'Related RT ROI Observations Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRTROIInterpretedType
      //(3006,00A4)
      = const PTag._('RTROIInterpretedType', 0x300600A4, 'RT ROI Interpreted Type',
          VR.kCS, VM.k1, false);
  static const PTag kROIInterpreter
      //(3006,00A6)
      =
      const PTag._('ROIInterpreter', 0x300600A6, 'ROI Interpreter', VR.kPN, VM.k1, false);
  static const PTag kROIPhysicalPropertiesSequence
      //(3006,00B0)
      = const PTag._('ROIPhysicalPropertiesSequence', 0x300600B0,
          'ROI Physical Properties Sequence', VR.kSQ, VM.k1, false);
  static const PTag kROIPhysicalProperty
      //(3006,00B2)
      = const PTag._('ROIPhysicalProperty', 0x300600B2, 'ROI Physical Property', VR.kCS,
          VM.k1, false);
  static const PTag kROIPhysicalPropertyValue
      //(3006,00B4)
      = const PTag._('ROIPhysicalPropertyValue', 0x300600B4,
          'ROI Physical Property Value', VR.kDS, VM.k1, false);
  static const PTag kROIElementalCompositionSequence
      //(3006,00B6)
      = const PTag._('ROIElementalCompositionSequence', 0x300600B6,
          'ROI Elemental Composition Sequence', VR.kSQ, VM.k1, false);
  static const PTag kROIElementalCompositionAtomicNumber
      //(3006,00B7)
      = const PTag._('ROIElementalCompositionAtomicNumber', 0x300600B7,
          'ROI Elemental Composition Atomic Number', VR.kUS, VM.k1, false);
  static const PTag kROIElementalCompositionAtomicMassFraction
      //(3006,00B8)
      = const PTag._('ROIElementalCompositionAtomicMassFraction', 0x300600B8,
          'ROI Elemental Composition Atomic Mass Fraction', VR.kFL, VM.k1, false);
  static const PTag kFrameOfReferenceRelationshipSequence
      //(3006,00C0)
      = const PTag._('FrameOfReferenceRelationshipSequence', 0x300600C0,
          'Frame of Reference Relationship Sequence', VR.kSQ, VM.k1, true);
  static const PTag kRelatedFrameOfReferenceUID
      //(3006,00C2)
      = const PTag._('RelatedFrameOfReferenceUID', 0x300600C2,
          'Related Frame of Reference UID', VR.kUI, VM.k1, true);
  static const PTag kFrameOfReferenceTransformationType
      //(3006,00C4)
      = const PTag._('FrameOfReferenceTransformationType', 0x300600C4,
          'Frame of Reference Transformation Type', VR.kCS, VM.k1, true);
  static const PTag kFrameOfReferenceTransformationMatrix
      //(3006,00C6)
      = const PTag._('FrameOfReferenceTransformationMatrix', 0x300600C6,
          'Frame of Reference Transformation Matrix', VR.kDS, VM.k16, false);
  static const PTag kFrameOfReferenceTransformationComment
      //(3006,00C8)
      = const PTag._('FrameOfReferenceTransformationComment', 0x300600C8,
          'Frame of Reference Transformation Comment', VR.kLO, VM.k1, false);
  static const PTag kMeasuredDoseReferenceSequence
      //(3008,0010)
      = const PTag._('MeasuredDoseReferenceSequence', 0x30080010,
          'Measured Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kMeasuredDoseDescription
      //(3008,0012)
      = const PTag._('MeasuredDoseDescription', 0x30080012, 'Measured Dose Description',
          VR.kST, VM.k1, false);
  static const PTag kMeasuredDoseType
      //(3008,0014)
      = const PTag._(
          'MeasuredDoseType', 0x30080014, 'Measured Dose Type', VR.kCS, VM.k1, false);
  static const PTag kMeasuredDoseValue
      //(3008,0016)
      = const PTag._(
          'MeasuredDoseValue', 0x30080016, 'Measured Dose Value', VR.kDS, VM.k1, false);
  static const PTag kTreatmentSessionBeamSequence
      //(3008,0020)
      = const PTag._('TreatmentSessionBeamSequence', 0x30080020,
          'Treatment Session Beam Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTreatmentSessionIonBeamSequence
      //(3008,0021)
      = const PTag._('TreatmentSessionIonBeamSequence', 0x30080021,
          'Treatment Session Ion Beam Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCurrentFractionNumber
      //(3008,0022)
      = const PTag._('CurrentFractionNumber', 0x30080022, 'Current Fraction Number',
          VR.kIS, VM.k1, false);
  static const PTag kTreatmentControlPointDate
      //(3008,0024)
      = const PTag._('TreatmentControlPointDate', 0x30080024,
          'Treatment Control Point Date', VR.kDA, VM.k1, false);
  static const PTag kTreatmentControlPointTime
      //(3008,0025)
      = const PTag._('TreatmentControlPointTime', 0x30080025,
          'Treatment Control Point Time', VR.kTM, VM.k1, false);
  static const PTag kTreatmentTerminationStatus
      //(3008,002A)
      = const PTag._('TreatmentTerminationStatus', 0x3008002A,
          'Treatment Termination Status', VR.kCS, VM.k1, false);
  static const PTag kTreatmentTerminationCode
      //(3008,002B)
      = const PTag._('TreatmentTerminationCode', 0x3008002B, 'Treatment Termination Code',
          VR.kSH, VM.k1, false);
  static const PTag kTreatmentVerificationStatus
      //(3008,002C)
      = const PTag._('TreatmentVerificationStatus', 0x3008002C,
          'Treatment Verification Status', VR.kCS, VM.k1, false);
  static const PTag kReferencedTreatmentRecordSequence
      //(3008,0030)
      = const PTag._('ReferencedTreatmentRecordSequence', 0x30080030,
          'Referenced Treatment Record Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecifiedPrimaryMeterset
      //(3008,0032)
      = const PTag._('SpecifiedPrimaryMeterset', 0x30080032, 'Specified Primary Meterset',
          VR.kDS, VM.k1, false);
  static const PTag kSpecifiedSecondaryMeterset
      //(3008,0033)
      = const PTag._('SpecifiedSecondaryMeterset', 0x30080033,
          'Specified Secondary Meterset', VR.kDS, VM.k1, false);
  static const PTag kDeliveredPrimaryMeterset
      //(3008,0036)
      = const PTag._('DeliveredPrimaryMeterset', 0x30080036, 'Delivered Primary Meterset',
          VR.kDS, VM.k1, false);
  static const PTag kDeliveredSecondaryMeterset
      //(3008,0037)
      = const PTag._('DeliveredSecondaryMeterset', 0x30080037,
          'Delivered Secondary Meterset', VR.kDS, VM.k1, false);
  static const PTag kSpecifiedTreatmentTime
      //(3008,003A)
      = const PTag._('SpecifiedTreatmentTime', 0x3008003A, 'Specified Treatment Time',
          VR.kDS, VM.k1, false);
  static const PTag kDeliveredTreatmentTime
      //(3008,003B)
      = const PTag._('DeliveredTreatmentTime', 0x3008003B, 'Delivered Treatment Time',
          VR.kDS, VM.k1, false);
  static const PTag kControlPointDeliverySequence
      //(3008,0040)
      = const PTag._('ControlPointDeliverySequence', 0x30080040,
          'Control Point Delivery Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonControlPointDeliverySequence
      //(3008,0041)
      = const PTag._('IonControlPointDeliverySequence', 0x30080041,
          'Ion Control Point Delivery Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSpecifiedMeterset
      //(3008,0042)
      = const PTag._(
          'SpecifiedMeterset', 0x30080042, 'Specified Meterset', VR.kDS, VM.k1, false);
  static const PTag kDeliveredMeterset
      //(3008,0044)
      = const PTag._(
          'DeliveredMeterset', 0x30080044, 'Delivered Meterset', VR.kDS, VM.k1, false);
  static const PTag kMetersetRateSet
      //(3008,0045)
      = const PTag._(
          'MetersetRateSet', 0x30080045, 'Meterset Rate Set', VR.kFL, VM.k1, false);
  static const PTag kMetersetRateDelivered
      //(3008,0046)
      = const PTag._('MetersetRateDelivered', 0x30080046, 'Meterset Rate Delivered',
          VR.kFL, VM.k1, false);
  static const PTag kScanSpotMetersetsDelivered
      //(3008,0047)
      = const PTag._('ScanSpotMetersetsDelivered', 0x30080047,
          'Scan Spot Metersets Delivered', VR.kFL, VM.k1_n, false);
  static const PTag kDoseRateDelivered
      //(3008,0048)
      = const PTag._(
          'DoseRateDelivered', 0x30080048, 'Dose Rate Delivered', VR.kDS, VM.k1, false);
  static const PTag kTreatmentSummaryCalculatedDoseReferenceSequence
      //(3008,0050)
      = const PTag._('TreatmentSummaryCalculatedDoseReferenceSequence', 0x30080050,
          'Treatment Summary Calculated Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCumulativeDoseToDoseReference
      //(3008,0052)
      = const PTag._('CumulativeDoseToDoseReference', 0x30080052,
          'Cumulative Dose to Dose Reference', VR.kDS, VM.k1, false);
  static const PTag kFirstTreatmentDate
      //(3008,0054)
      = const PTag._(
          'FirstTreatmentDate', 0x30080054, 'First Treatment Date', VR.kDA, VM.k1, false);
  static const PTag kMostRecentTreatmentDate
      //(3008,0056)
      = const PTag._('MostRecentTreatmentDate', 0x30080056, 'Most Recent Treatment Date',
          VR.kDA, VM.k1, false);
  static const PTag kNumberOfFractionsDelivered
      //(3008,005A)
      = const PTag._('NumberOfFractionsDelivered', 0x3008005A,
          'Number of Fractions Delivered', VR.kIS, VM.k1, false);
  static const PTag kOverrideSequence
      //(3008,0060)
      = const PTag._(
          'OverrideSequence', 0x30080060, 'Override Sequence', VR.kSQ, VM.k1, false);
  static const PTag kParameterSequencePointer
      //(3008,0061)
      = const PTag._('ParameterSequencePointer', 0x30080061, 'Parameter Sequence Pointer',
          VR.kAT, VM.k1, false);
  static const PTag kOverrideParameterPointer
      //(3008,0062)
      = const PTag._('OverrideParameterPointer', 0x30080062, 'Override Parameter Pointer',
          VR.kAT, VM.k1, false);
  static const PTag kParameterItemIndex
      //(3008,0063)
      = const PTag._(
          'ParameterItemIndex', 0x30080063, 'Parameter Item Index', VR.kIS, VM.k1, false);
  static const PTag kMeasuredDoseReferenceNumber
      //(3008,0064)
      = const PTag._('MeasuredDoseReferenceNumber', 0x30080064,
          'Measured Dose Reference Number', VR.kIS, VM.k1, false);
  static const PTag kParameterPointer
      //(3008,0065)
      = const PTag._(
          'ParameterPointer', 0x30080065, 'Parameter Pointer', VR.kAT, VM.k1, false);
  static const PTag kOverrideReason
      //(3008,0066)
      =
      const PTag._('OverrideReason', 0x30080066, 'Override Reason', VR.kST, VM.k1, false);
  static const PTag kCorrectedParameterSequence
      //(3008,0068)
      = const PTag._('CorrectedParameterSequence', 0x30080068,
          'Corrected Parameter Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCorrectionValue
      //(3008,006A)
      = const PTag._(
          'CorrectionValue', 0x3008006A, 'Correction Value', VR.kFL, VM.k1, false);
  static const PTag kCalculatedDoseReferenceSequence
      //(3008,0070)
      = const PTag._('CalculatedDoseReferenceSequence', 0x30080070,
          'Calculated Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCalculatedDoseReferenceNumber
      //(3008,0072)
      = const PTag._('CalculatedDoseReferenceNumber', 0x30080072,
          'Calculated Dose Reference Number', VR.kIS, VM.k1, false);
  static const PTag kCalculatedDoseReferenceDescription
      //(3008,0074)
      = const PTag._('CalculatedDoseReferenceDescription', 0x30080074,
          'Calculated Dose Reference Description', VR.kST, VM.k1, false);
  static const PTag kCalculatedDoseReferenceDoseValue
      //(3008,0076)
      = const PTag._('CalculatedDoseReferenceDoseValue', 0x30080076,
          'Calculated Dose Reference Dose Value', VR.kDS, VM.k1, false);
  static const PTag kStartMeterset
      //(3008,0078)
      = const PTag._('StartMeterset', 0x30080078, 'Start Meterset', VR.kDS, VM.k1, false);
  static const PTag kEndMeterset
      //(3008,007A)
      = const PTag._('EndMeterset', 0x3008007A, 'End Meterset', VR.kDS, VM.k1, false);
  static const PTag kReferencedMeasuredDoseReferenceSequence
      //(3008,0080)
      = const PTag._('ReferencedMeasuredDoseReferenceSequence', 0x30080080,
          'Referenced Measured Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedMeasuredDoseReferenceNumber
      //(3008,0082)
      = const PTag._('ReferencedMeasuredDoseReferenceNumber', 0x30080082,
          'Referenced Measured Dose Reference Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedCalculatedDoseReferenceSequence
      //(3008,0090)
      = const PTag._('ReferencedCalculatedDoseReferenceSequence', 0x30080090,
          'Referenced Calculated Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedCalculatedDoseReferenceNumber
      //(3008,0092)
      = const PTag._('ReferencedCalculatedDoseReferenceNumber', 0x30080092,
          'Referenced Calculated Dose Reference Number', VR.kIS, VM.k1, false);
  static const PTag kBeamLimitingDeviceLeafPairsSequence
      //(3008,00A0)
      = const PTag._('BeamLimitingDeviceLeafPairsSequence', 0x300800A0,
          'Beam Limiting Device Leaf Pairs Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRecordedWedgeSequence
      //(3008,00B0)
      = const PTag._('RecordedWedgeSequence', 0x300800B0, 'Recorded Wedge Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kRecordedCompensatorSequence
      //(3008,00C0)
      = const PTag._('RecordedCompensatorSequence', 0x300800C0,
          'Recorded Compensator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRecordedBlockSequence
      //(3008,00D0)
      = const PTag._('RecordedBlockSequence', 0x300800D0, 'Recorded Block Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTreatmentSummaryMeasuredDoseReferenceSequence
      //(3008,00E0)
      = const PTag._('TreatmentSummaryMeasuredDoseReferenceSequence', 0x300800E0,
          'Treatment Summary Measured Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRecordedSnoutSequence
      //(3008,00F0)
      = const PTag._('RecordedSnoutSequence', 0x300800F0, 'Recorded Snout Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kRecordedRangeShifterSequence
      //(3008,00F2)
      = const PTag._('RecordedRangeShifterSequence', 0x300800F2,
          'Recorded Range Shifter Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRecordedLateralSpreadingDeviceSequence
      //(3008,00F4)
      = const PTag._('RecordedLateralSpreadingDeviceSequence', 0x300800F4,
          'Recorded Lateral Spreading Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRecordedRangeModulatorSequence
      //(3008,00F6)
      = const PTag._('RecordedRangeModulatorSequence', 0x300800F6,
          'Recorded Range Modulator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRecordedSourceSequence
      //(3008,0100)
      = const PTag._('RecordedSourceSequence', 0x30080100, 'Recorded Source Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSourceSerialNumber
      //(3008,0105)
      = const PTag._(
          'SourceSerialNumber', 0x30080105, 'Source Serial Number', VR.kLO, VM.k1, false);
  static const PTag kTreatmentSessionApplicationSetupSequence
      //(3008,0110)
      = const PTag._('TreatmentSessionApplicationSetupSequence', 0x30080110,
          'Treatment Session Application Setup Sequence', VR.kSQ, VM.k1, false);
  static const PTag kApplicationSetupCheck
      //(3008,0116)
      = const PTag._('ApplicationSetupCheck', 0x30080116, 'Application Setup Check',
          VR.kCS, VM.k1, false);
  static const PTag kRecordedBrachyAccessoryDeviceSequence
      //(3008,0120)
      = const PTag._('RecordedBrachyAccessoryDeviceSequence', 0x30080120,
          'Recorded Brachy Accessory Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedBrachyAccessoryDeviceNumber
      //(3008,0122)
      = const PTag._('ReferencedBrachyAccessoryDeviceNumber', 0x30080122,
          'Referenced Brachy Accessory Device Number', VR.kIS, VM.k1, false);
  static const PTag kRecordedChannelSequence
      //(3008,0130)
      = const PTag._('RecordedChannelSequence', 0x30080130, 'Recorded Channel Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSpecifiedChannelTotalTime
      //(3008,0132)
      = const PTag._('SpecifiedChannelTotalTime', 0x30080132,
          'Specified Channel Total Time', VR.kDS, VM.k1, false);
  static const PTag kDeliveredChannelTotalTime
      //(3008,0134)
      = const PTag._('DeliveredChannelTotalTime', 0x30080134,
          'Delivered Channel Total Time', VR.kDS, VM.k1, false);
  static const PTag kSpecifiedNumberOfPulses
      //(3008,0136)
      = const PTag._('SpecifiedNumberOfPulses', 0x30080136, 'Specified Number of Pulses',
          VR.kIS, VM.k1, false);
  static const PTag kDeliveredNumberOfPulses
      //(3008,0138)
      = const PTag._('DeliveredNumberOfPulses', 0x30080138, 'Delivered Number of Pulses',
          VR.kIS, VM.k1, false);
  static const PTag kSpecifiedPulseRepetitionInterval
      //(3008,013A)
      = const PTag._('SpecifiedPulseRepetitionInterval', 0x3008013A,
          'Specified Pulse Repetition Interval', VR.kDS, VM.k1, false);
  static const PTag kDeliveredPulseRepetitionInterval
      //(3008,013C)
      = const PTag._('DeliveredPulseRepetitionInterval', 0x3008013C,
          'Delivered Pulse Repetition Interval', VR.kDS, VM.k1, false);
  static const PTag kRecordedSourceApplicatorSequence
      //(3008,0140)
      = const PTag._('RecordedSourceApplicatorSequence', 0x30080140,
          'Recorded Source Applicator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSourceApplicatorNumber
      //(3008,0142)
      = const PTag._('ReferencedSourceApplicatorNumber', 0x30080142,
          'Referenced Source Applicator Number', VR.kIS, VM.k1, false);
  static const PTag kRecordedChannelShieldSequence
      //(3008,0150)
      = const PTag._('RecordedChannelShieldSequence', 0x30080150,
          'Recorded Channel Shield Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedChannelShieldNumber
      //(3008,0152)
      = const PTag._('ReferencedChannelShieldNumber', 0x30080152,
          'Referenced Channel Shield Number', VR.kIS, VM.k1, false);
  static const PTag kBrachyControlPointDeliveredSequence
      //(3008,0160)
      = const PTag._('BrachyControlPointDeliveredSequence', 0x30080160,
          'Brachy Control Point Delivered Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSafePositionExitDate
      //(3008,0162)
      = const PTag._('SafePositionExitDate', 0x30080162, 'Safe Position Exit Date',
          VR.kDA, VM.k1, false);
  static const PTag kSafePositionExitTime
      //(3008,0164)
      = const PTag._('SafePositionExitTime', 0x30080164, 'Safe Position Exit Time',
          VR.kTM, VM.k1, false);
  static const PTag kSafePositionReturnDate
      //(3008,0166)
      = const PTag._('SafePositionReturnDate', 0x30080166, 'Safe Position Return Date',
          VR.kDA, VM.k1, false);
  static const PTag kSafePositionReturnTime
      //(3008,0168)
      = const PTag._('SafePositionReturnTime', 0x30080168, 'Safe Position Return Time',
          VR.kTM, VM.k1, false);
  static const PTag kCurrentTreatmentStatus
      //(3008,0200)
      = const PTag._('CurrentTreatmentStatus', 0x30080200, 'Current Treatment Status',
          VR.kCS, VM.k1, false);
  static const PTag kTreatmentStatusComment
      //(3008,0202)
      = const PTag._('TreatmentStatusComment', 0x30080202, 'Treatment Status Comment',
          VR.kST, VM.k1, false);
  static const PTag kFractionGroupSummarySequence
      //(3008,0220)
      = const PTag._('FractionGroupSummarySequence', 0x30080220,
          'Fraction Group Summary Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedFractionNumber
      //(3008,0223)
      = const PTag._('ReferencedFractionNumber', 0x30080223, 'Referenced Fraction Number',
          VR.kIS, VM.k1, false);
  static const PTag kFractionGroupType
      //(3008,0224)
      = const PTag._(
          'FractionGroupType', 0x30080224, 'Fraction Group Type', VR.kCS, VM.k1, false);
  static const PTag kBeamStopperPosition
      //(3008,0230)
      = const PTag._('BeamStopperPosition', 0x30080230, 'Beam Stopper Position', VR.kCS,
          VM.k1, false);
  static const PTag kFractionStatusSummarySequence
      //(3008,0240)
      = const PTag._('FractionStatusSummarySequence', 0x30080240,
          'Fraction Status Summary Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTreatmentDate
      //(3008,0250)
      = const PTag._('TreatmentDate', 0x30080250, 'Treatment Date', VR.kDA, VM.k1, false);
  static const PTag kTreatmentTime
      //(3008,0251)
      = const PTag._('TreatmentTime', 0x30080251, 'Treatment Time', VR.kTM, VM.k1, false);
  static const PTag kRTPlanLabel
      //(300A,0002)
      = const PTag._('RTPlanLabel', 0x300A0002, 'RT Plan Label', VR.kSH, VM.k1, false);
  static const PTag kRTPlanName
      //(300A,0003)
      = const PTag._('RTPlanName', 0x300A0003, 'RT Plan Name', VR.kLO, VM.k1, false);
  static const PTag kRTPlanDescription
      //(300A,0004)
      = const PTag._(
          'RTPlanDescription', 0x300A0004, 'RT Plan Description', VR.kST, VM.k1, false);
  static const PTag kRTPlanDate
      //(300A,0006)
      = const PTag._('RTPlanDate', 0x300A0006, 'RT Plan Date', VR.kDA, VM.k1, false);
  static const PTag kRTPlanTime
      //(300A,0007)
      = const PTag._('RTPlanTime', 0x300A0007, 'RT Plan Time', VR.kTM, VM.k1, false);
  static const PTag kTreatmentProtocols
      //(300A,0009)
      = const PTag._('TreatmentProtocols', 0x300A0009, 'Treatment Protocols', VR.kLO,
          VM.k1_n, false);
  static const PTag kPlanIntent
      //(300A,000A)
      = const PTag._('PlanIntent', 0x300A000A, 'Plan Intent', VR.kCS, VM.k1, false);
  static const PTag kTreatmentSites
      //(300A,000B)
      = const PTag._(
          'TreatmentSites', 0x300A000B, 'Treatment Sites', VR.kLO, VM.k1_n, false);
  static const PTag kRTPlanGeometry
      //(300A,000C)
      = const PTag._(
          'RTPlanGeometry', 0x300A000C, 'RT Plan Geometry', VR.kCS, VM.k1, false);
  static const PTag kPrescriptionDescription
      //(300A,000E)
      = const PTag._('PrescriptionDescription', 0x300A000E, 'Prescription Description',
          VR.kST, VM.k1, false);
  static const PTag kDoseReferenceSequence
      //(300A,0010)
      = const PTag._('DoseReferenceSequence', 0x300A0010, 'Dose Reference Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kDoseReferenceNumber
      //(300A,0012)
      = const PTag._('DoseReferenceNumber', 0x300A0012, 'Dose Reference Number', VR.kIS,
          VM.k1, false);
  static const PTag kDoseReferenceUID
      //(300A,0013)
      = const PTag._(
          'DoseReferenceUID', 0x300A0013, 'Dose Reference UID', VR.kUI, VM.k1, false);
  static const PTag kDoseReferenceStructureType
      //(300A,0014)
      = const PTag._('DoseReferenceStructureType', 0x300A0014,
          'Dose Reference Structure Type', VR.kCS, VM.k1, false);
  static const PTag kNominalBeamEnergyUnit
      //(300A,0015)
      = const PTag._('NominalBeamEnergyUnit', 0x300A0015, 'Nominal Beam Energy Unit',
          VR.kCS, VM.k1, false);
  static const PTag kDoseReferenceDescription
      //(300A,0016)
      = const PTag._('DoseReferenceDescription', 0x300A0016, 'Dose Reference Description',
          VR.kLO, VM.k1, false);
  static const PTag kDoseReferencePointCoordinates
      //(300A,0018)
      = const PTag._('DoseReferencePointCoordinates', 0x300A0018,
          'Dose Reference Point Coordinates', VR.kDS, VM.k3, false);
  static const PTag kNominalPriorDose
      //(300A,001A)
      = const PTag._(
          'NominalPriorDose', 0x300A001A, 'Nominal Prior Dose', VR.kDS, VM.k1, false);
  static const PTag kDoseReferenceType
      //(300A,0020)
      = const PTag._(
          'DoseReferenceType', 0x300A0020, 'Dose Reference Type', VR.kCS, VM.k1, false);
  static const PTag kConstraintWeight
      //(300A,0021)
      = const PTag._(
          'ConstraintWeight', 0x300A0021, 'Constraint Weight', VR.kDS, VM.k1, false);
  static const PTag kDeliveryWarningDose
      //(300A,0022)
      = const PTag._('DeliveryWarningDose', 0x300A0022, 'Delivery Warning Dose', VR.kDS,
          VM.k1, false);
  static const PTag kDeliveryMaximumDose
      //(300A,0023)
      = const PTag._('DeliveryMaximumDose', 0x300A0023, 'Delivery Maximum Dose', VR.kDS,
          VM.k1, false);
  static const PTag kTargetMinimumDose
      //(300A,0025)
      = const PTag._(
          'TargetMinimumDose', 0x300A0025, 'Target Minimum Dose', VR.kDS, VM.k1, false);
  static const PTag kTargetPrescriptionDose
      //(300A,0026)
      = const PTag._('TargetPrescriptionDose', 0x300A0026, 'Target Prescription Dose',
          VR.kDS, VM.k1, false);
  static const PTag kTargetMaximumDose
      //(300A,0027)
      = const PTag._(
          'TargetMaximumDose', 0x300A0027, 'Target Maximum Dose', VR.kDS, VM.k1, false);
  static const PTag kTargetUnderdoseVolumeFraction
      //(300A,0028)
      = const PTag._('TargetUnderdoseVolumeFraction', 0x300A0028,
          'Target Underdose Volume Fraction', VR.kDS, VM.k1, false);
  static const PTag kOrganAtRiskFullVolumeDose
      //(300A,002A)
      = const PTag._('OrganAtRiskFullVolumeDose', 0x300A002A,
          'Organ at Risk Full-volume Dose', VR.kDS, VM.k1, false);
  static const PTag kOrganAtRiskLimitDose
      //(300A,002B)
      = const PTag._('OrganAtRiskLimitDose', 0x300A002B, 'Organ at Risk Limit Dose',
          VR.kDS, VM.k1, false);
  static const PTag kOrganAtRiskMaximumDose
      //(300A,002C)
      = const PTag._('OrganAtRiskMaximumDose', 0x300A002C, 'Organ at Risk Maximum Dose',
          VR.kDS, VM.k1, false);
  static const PTag kOrganAtRiskOverdoseVolumeFraction
      //(300A,002D)
      = const PTag._('OrganAtRiskOverdoseVolumeFraction', 0x300A002D,
          'Organ at Risk Overdose Volume Fraction', VR.kDS, VM.k1, false);
  static const PTag kToleranceTableSequence
      //(300A,0040)
      = const PTag._('ToleranceTableSequence', 0x300A0040, 'Tolerance Table Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kToleranceTableNumber
      //(300A,0042)
      = const PTag._('ToleranceTableNumber', 0x300A0042, 'Tolerance Table Number', VR.kIS,
          VM.k1, false);
  static const PTag kToleranceTableLabel
      //(300A,0043)
      = const PTag._('ToleranceTableLabel', 0x300A0043, 'Tolerance Table Label', VR.kSH,
          VM.k1, false);
  static const PTag kGantryAngleTolerance
      //(300A,0044)
      = const PTag._('GantryAngleTolerance', 0x300A0044, 'Gantry Angle Tolerance', VR.kDS,
          VM.k1, false);
  static const PTag kBeamLimitingDeviceAngleTolerance
      //(300A,0046)
      = const PTag._('BeamLimitingDeviceAngleTolerance', 0x300A0046,
          'Beam Limiting Device Angle Tolerance', VR.kDS, VM.k1, false);
  static const PTag kBeamLimitingDeviceToleranceSequence
      //(300A,0048)
      = const PTag._('BeamLimitingDeviceToleranceSequence', 0x300A0048,
          'Beam Limiting Device Tolerance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBeamLimitingDevicePositionTolerance
      //(300A,004A)
      = const PTag._('BeamLimitingDevicePositionTolerance', 0x300A004A,
          'Beam Limiting Device Position Tolerance', VR.kDS, VM.k1, false);
  static const PTag kSnoutPositionTolerance
      //(300A,004B)
      = const PTag._('SnoutPositionTolerance', 0x300A004B, 'Snout Position Tolerance',
          VR.kFL, VM.k1, false);
  static const PTag kPatientSupportAngleTolerance
      //(300A,004C)
      = const PTag._('PatientSupportAngleTolerance', 0x300A004C,
          'Patient Support Angle Tolerance', VR.kDS, VM.k1, false);
  static const PTag kTableTopEccentricAngleTolerance
      //(300A,004E)
      = const PTag._('TableTopEccentricAngleTolerance', 0x300A004E,
          'Table Top Eccentric Angle Tolerance', VR.kDS, VM.k1, false);
  static const PTag kTableTopPitchAngleTolerance
      //(300A,004F)
      = const PTag._('TableTopPitchAngleTolerance', 0x300A004F,
          'Table Top Pitch Angle Tolerance', VR.kFL, VM.k1, false);
  static const PTag kTableTopRollAngleTolerance
      //(300A,0050)
      = const PTag._('TableTopRollAngleTolerance', 0x300A0050,
          'Table Top Roll Angle Tolerance', VR.kFL, VM.k1, false);
  static const PTag kTableTopVerticalPositionTolerance
      //(300A,0051)
      = const PTag._('TableTopVerticalPositionTolerance', 0x300A0051,
          'Table Top Vertical Position Tolerance', VR.kDS, VM.k1, false);
  static const PTag kTableTopLongitudinalPositionTolerance
      //(300A,0052)
      = const PTag._('TableTopLongitudinalPositionTolerance', 0x300A0052,
          'Table Top Longitudinal Position Tolerance', VR.kDS, VM.k1, false);
  static const PTag kTableTopLateralPositionTolerance
      //(300A,0053)
      = const PTag._('TableTopLateralPositionTolerance', 0x300A0053,
          'Table Top Lateral Position Tolerance', VR.kDS, VM.k1, false);
  static const PTag kRTPlanRelationship
      //(300A,0055)
      = const PTag._(
          'RTPlanRelationship', 0x300A0055, 'RT Plan Relationship', VR.kCS, VM.k1, false);
  static const PTag kFractionGroupSequence
      //(300A,0070)
      = const PTag._('FractionGroupSequence', 0x300A0070, 'Fraction Group Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kFractionGroupNumber
      //(300A,0071)
      = const PTag._('FractionGroupNumber', 0x300A0071, 'Fraction Group Number', VR.kIS,
          VM.k1, false);
  static const PTag kFractionGroupDescription
      //(300A,0072)
      = const PTag._('FractionGroupDescription', 0x300A0072, 'Fraction Group Description',
          VR.kLO, VM.k1, false);
  static const PTag kNumberOfFractionsPlanned
      //(300A,0078)
      = const PTag._('NumberOfFractionsPlanned', 0x300A0078,
          'Number of Fractions Planned', VR.kIS, VM.k1, false);
  static const PTag kNumberOfFractionPatternDigitsPerDay
      //(300A,0079)
      = const PTag._('NumberOfFractionPatternDigitsPerDay', 0x300A0079,
          'Number of Fraction Pattern Digits Per Day', VR.kIS, VM.k1, false);
  static const PTag kRepeatFractionCycleLength
      //(300A,007A)
      = const PTag._('RepeatFractionCycleLength', 0x300A007A,
          'Repeat Fraction Cycle Length', VR.kIS, VM.k1, false);
  static const PTag kFractionPattern
      //(300A,007B)
      = const PTag._(
          'FractionPattern', 0x300A007B, 'Fraction Pattern', VR.kLT, VM.k1, false);
  static const PTag kNumberOfBeams
      //(300A,0080)
      =
      const PTag._('NumberOfBeams', 0x300A0080, 'Number of Beams', VR.kIS, VM.k1, false);
  static const PTag kBeamDoseSpecificationPoint
      //(300A,0082)
      = const PTag._('BeamDoseSpecificationPoint', 0x300A0082,
          'Beam Dose Specification Point', VR.kDS, VM.k3, false);
  static const PTag kBeamDose
      //(300A,0084)
      = const PTag._('BeamDose', 0x300A0084, 'Beam Dose', VR.kDS, VM.k1, false);
  static const PTag kBeamMeterset
      //(300A,0086)
      = const PTag._('BeamMeterset', 0x300A0086, 'Beam Meterset', VR.kDS, VM.k1, false);
  static const PTag kBeamDosePointDepth
      //(300A,0088)
      = const PTag._(
          'BeamDosePointDepth', 0x300A0088, 'Beam Dose Point Depth', VR.kFL, VM.k1, true);
  static const PTag kBeamDosePointEquivalentDepth
      //(300A,0089)
      = const PTag._('BeamDosePointEquivalentDepth', 0x300A0089,
          'Beam Dose Point Equivalent Depth', VR.kFL, VM.k1, true);
  static const PTag kBeamDosePointSSD
      //(300A,008A)
      = const PTag._(
          'BeamDosePointSSD', 0x300A008A, 'Beam Dose Point SSD', VR.kFL, VM.k1, true);
  static const PTag kBeamDoseMeaning
      //(300A,008B)
      = const PTag._(
          'BeamDoseMeaning', 0x300A008B, 'Beam Dose Meaning', VR.kCS, VM.k1, false);
  static const PTag kBeamDoseVerificationControlPointSequence
      //(300A,008C)
      = const PTag._('BeamDoseVerificationControlPointSequence', 0x300A008C,
          'Beam Dose Verification Control Point Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAverageBeamDosePointDepth
      //(300A,008D)
      = const PTag._('AverageBeamDosePointDepth', 0x300A008D,
          'Average Beam Dose Point Depth', VR.kFL, VM.k1, false);
  static const PTag kAverageBeamDosePointEquivalentDepth
      //(300A,008E)
      = const PTag._('AverageBeamDosePointEquivalentDepth', 0x300A008E,
          'Average Beam Dose Point Equivalent Depth', VR.kFL, VM.k1, false);
  static const PTag kAverageBeamDosePointSSD
      //(300A,008F)
      = const PTag._('AverageBeamDosePointSSD', 0x300A008F, 'Average Beam Dose Point SSD',
          VR.kFL, VM.k1, false);
  static const PTag kNumberOfBrachyApplicationSetups
      //(300A,00A0)
      = const PTag._('NumberOfBrachyApplicationSetups', 0x300A00A0,
          'Number of Brachy Application Setups', VR.kIS, VM.k1, false);
  static const PTag kBrachyApplicationSetupDoseSpecificationPoint
      //(300A,00A2)
      = const PTag._('BrachyApplicationSetupDoseSpecificationPoint', 0x300A00A2,
          'Brachy Application Setup Dose Specification Point', VR.kDS, VM.k3, false);
  static const PTag kBrachyApplicationSetupDose
      //(300A,00A4)
      = const PTag._('BrachyApplicationSetupDose', 0x300A00A4,
          'Brachy Application Setup Dose', VR.kDS, VM.k1, false);
  static const PTag kBeamSequence
      //(300A,00B0)
      = const PTag._('BeamSequence', 0x300A00B0, 'Beam Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTreatmentMachineName
      //(300A,00B2)
      = const PTag._('TreatmentMachineName', 0x300A00B2, 'Treatment Machine Name', VR.kSH,
          VM.k1, false);
  static const PTag kPrimaryDosimeterUnit
      //(300A,00B3)
      = const PTag._('PrimaryDosimeterUnit', 0x300A00B3, 'Primary Dosimeter Unit', VR.kCS,
          VM.k1, false);
  static const PTag kSourceAxisDistance
      //(300A,00B4)
      = const PTag._(
          'SourceAxisDistance', 0x300A00B4, 'Source-Axis Distance', VR.kDS, VM.k1, false);
  static const PTag kBeamLimitingDeviceSequence
      //(300A,00B6)
      = const PTag._('BeamLimitingDeviceSequence', 0x300A00B6,
          'Beam Limiting Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRTBeamLimitingDeviceType
      //(300A,00B8)
      = const PTag._('RTBeamLimitingDeviceType', 0x300A00B8,
          'RT Beam Limiting Device Type', VR.kCS, VM.k1, false);
  static const PTag kSourceToBeamLimitingDeviceDistance
      //(300A,00BA)
      = const PTag._('SourceToBeamLimitingDeviceDistance', 0x300A00BA,
          'Source to Beam Limiting Device Distance', VR.kDS, VM.k1, false);
  static const PTag kIsocenterToBeamLimitingDeviceDistance
      //(300A,00BB)
      = const PTag._('IsocenterToBeamLimitingDeviceDistance', 0x300A00BB,
          'Isocenter to Beam Limiting Device Distance', VR.kFL, VM.k1, false);
  static const PTag kNumberOfLeafJawPairs
      //(300A,00BC)
      = const PTag._('NumberOfLeafJawPairs', 0x300A00BC, 'Number of Leaf/Jaw Pairs',
          VR.kIS, VM.k1, false);
  static const PTag kLeafPositionBoundaries
      //(300A,00BE)
      = const PTag._('LeafPositionBoundaries', 0x300A00BE, 'Leaf Position Boundaries',
          VR.kDS, VM.k3_n, false);
  static const PTag kBeamNumber
      //(300A,00C0)
      = const PTag._('BeamNumber', 0x300A00C0, 'Beam Number', VR.kIS, VM.k1, false);
  static const PTag kBeamName
      //(300A,00C2)
      = const PTag._('BeamName', 0x300A00C2, 'Beam Name', VR.kLO, VM.k1, false);
  static const PTag kBeamDescription
      //(300A,00C3)
      = const PTag._(
          'BeamDescription', 0x300A00C3, 'Beam Description', VR.kST, VM.k1, false);
  static const PTag kBeamType
      //(300A,00C4)
      = const PTag._('BeamType', 0x300A00C4, 'Beam Type', VR.kCS, VM.k1, false);
  static const PTag kRadiationType
      //(300A,00C6)
      = const PTag._('RadiationType', 0x300A00C6, 'Radiation Type', VR.kCS, VM.k1, false);
  static const PTag kHighDoseTechniqueType
      //(300A,00C7)
      = const PTag._('HighDoseTechniqueType', 0x300A00C7, 'High-Dose Technique Type',
          VR.kCS, VM.k1, false);
  static const PTag kReferenceImageNumber
      //(300A,00C8)
      = const PTag._('ReferenceImageNumber', 0x300A00C8, 'Reference Image Number', VR.kIS,
          VM.k1, false);
  static const PTag kPlannedVerificationImageSequence
      //(300A,00CA)
      = const PTag._('PlannedVerificationImageSequence', 0x300A00CA,
          'Planned Verification Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kImagingDeviceSpecificAcquisitionParameters
      //(300A,00CC)
      = const PTag._('ImagingDeviceSpecificAcquisitionParameters', 0x300A00CC,
          'Imaging Device-Specific Acquisition Parameters', VR.kLO, VM.k1_n, false);
  static const PTag kTreatmentDeliveryType
      //(300A,00CE)
      = const PTag._('TreatmentDeliveryType', 0x300A00CE, 'Treatment Delivery Type',
          VR.kCS, VM.k1, false);
  static const PTag kNumberOfWedges
      //(300A,00D0)
      = const PTag._(
          'NumberOfWedges', 0x300A00D0, 'Number of Wedges', VR.kIS, VM.k1, false);
  static const PTag kWedgeSequence
      //(300A,00D1)
      = const PTag._('WedgeSequence', 0x300A00D1, 'Wedge Sequence', VR.kSQ, VM.k1, false);
  static const PTag kWedgeNumber
      //(300A,00D2)
      = const PTag._('WedgeNumber', 0x300A00D2, 'Wedge Number', VR.kIS, VM.k1, false);
  static const PTag kWedgeType
      //(300A,00D3)
      = const PTag._('WedgeType', 0x300A00D3, 'Wedge Type', VR.kCS, VM.k1, false);
  static const PTag kWedgeID
      //(300A,00D4)
      = const PTag._('WedgeID', 0x300A00D4, 'Wedge ID', VR.kSH, VM.k1, false);
  static const PTag kWedgeAngle
      //(300A,00D5)
      = const PTag._('WedgeAngle', 0x300A00D5, 'Wedge Angle', VR.kIS, VM.k1, false);
  static const PTag kWedgeFactor
      //(300A,00D6)
      = const PTag._('WedgeFactor', 0x300A00D6, 'Wedge Factor', VR.kDS, VM.k1, false);
  static const PTag kTotalWedgeTrayWaterEquivalentThickness
      //(300A,00D7)
      = const PTag._('TotalWedgeTrayWaterEquivalentThickness', 0x300A00D7,
          'Total Wedge Tray Water-Equivalent Thickness', VR.kFL, VM.k1, false);
  static const PTag kWedgeOrientation
      //(300A,00D8)
      = const PTag._(
          'WedgeOrientation', 0x300A00D8, 'Wedge Orientation', VR.kDS, VM.k1, false);
  static const PTag kIsocenterToWedgeTrayDistance
      //(300A,00D9)
      = const PTag._('IsocenterToWedgeTrayDistance', 0x300A00D9,
          'Isocenter to Wedge Tray Distance', VR.kFL, VM.k1, false);
  static const PTag kSourceToWedgeTrayDistance
      //(300A,00DA)
      = const PTag._('SourceToWedgeTrayDistance', 0x300A00DA,
          'Source to Wedge Tray Distance', VR.kDS, VM.k1, false);
  static const PTag kWedgeThinEdgePosition
      //(300A,00DB)
      = const PTag._('WedgeThinEdgePosition', 0x300A00DB, 'Wedge Thin Edge Position',
          VR.kFL, VM.k1, false);
  static const PTag kBolusID
      //(300A,00DC)
      = const PTag._('BolusID', 0x300A00DC, 'Bolus ID', VR.kSH, VM.k1, false);
  static const PTag kBolusDescription
      //(300A,00DD)
      = const PTag._(
          'BolusDescription', 0x300A00DD, 'Bolus Description', VR.kST, VM.k1, false);
  static const PTag kNumberOfCompensators
      //(300A,00E0)
      = const PTag._('NumberOfCompensators', 0x300A00E0, 'Number of Compensators', VR.kIS,
          VM.k1, false);
  static const PTag kMaterialID
      //(300A,00E1)
      = const PTag._('MaterialID', 0x300A00E1, 'Material ID', VR.kSH, VM.k1, false);
  static const PTag kTotalCompensatorTrayFactor
      //(300A,00E2)
      = const PTag._('TotalCompensatorTrayFactor', 0x300A00E2,
          'Total Compensator Tray Factor', VR.kDS, VM.k1, false);
  static const PTag kCompensatorSequence
      //(300A,00E3)
      = const PTag._('CompensatorSequence', 0x300A00E3, 'Compensator Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kCompensatorNumber
      //(300A,00E4)
      = const PTag._(
          'CompensatorNumber', 0x300A00E4, 'Compensator Number', VR.kIS, VM.k1, false);
  static const PTag kCompensatorID
      //(300A,00E5)
      = const PTag._('CompensatorID', 0x300A00E5, 'Compensator ID', VR.kSH, VM.k1, false);
  static const PTag kSourceToCompensatorTrayDistance
      //(300A,00E6)
      = const PTag._('SourceToCompensatorTrayDistance', 0x300A00E6,
          'Source to Compensator Tray Distance', VR.kDS, VM.k1, false);
  static const PTag kCompensatorRows
      //(300A,00E7)
      = const PTag._(
          'CompensatorRows', 0x300A00E7, 'Compensator Rows', VR.kIS, VM.k1, false);
  static const PTag kCompensatorColumns
      //(300A,00E8)
      = const PTag._(
          'CompensatorColumns', 0x300A00E8, 'Compensator Columns', VR.kIS, VM.k1, false);
  static const PTag kCompensatorPixelSpacing
      //(300A,00E9)
      = const PTag._('CompensatorPixelSpacing', 0x300A00E9, 'Compensator Pixel Spacing',
          VR.kDS, VM.k2, false);
  static const PTag kCompensatorPosition
      //(300A,00EA)
      = const PTag._('CompensatorPosition', 0x300A00EA, 'Compensator Position', VR.kDS,
          VM.k2, false);
  static const PTag kCompensatorTransmissionData
      //(300A,00EB)
      = const PTag._('CompensatorTransmissionData', 0x300A00EB,
          'Compensator Transmission Data', VR.kDS, VM.k1_n, false);
  static const PTag kCompensatorThicknessData
      //(300A,00EC)
      = const PTag._('CompensatorThicknessData', 0x300A00EC, 'Compensator Thickness Data',
          VR.kDS, VM.k1_n, false);
  static const PTag kNumberOfBoli
      //(300A,00ED)
      = const PTag._('NumberOfBoli', 0x300A00ED, 'Number of Boli', VR.kIS, VM.k1, false);
  static const PTag kCompensatorType
      //(300A,00EE)
      = const PTag._(
          'CompensatorType', 0x300A00EE, 'Compensator Type', VR.kCS, VM.k1, false);
  static const PTag kCompensatorTrayID
      //(300A,00EF)
      = const PTag._(
          'CompensatorTrayID', 0x300A00EF, 'Compensator Tray ID', VR.kSH, VM.k1, false);
  static const PTag kNumberOfBlocks
      //(300A,00F0)
      = const PTag._(
          'NumberOfBlocks', 0x300A00F0, 'Number of Blocks', VR.kIS, VM.k1, false);
  static const PTag kTotalBlockTrayFactor
      //(300A,00F2)
      = const PTag._('TotalBlockTrayFactor', 0x300A00F2, 'Total Block Tray Factor',
          VR.kDS, VM.k1, false);
  static const PTag kTotalBlockTrayWaterEquivalentThickness
      //(300A,00F3)
      = const PTag._('TotalBlockTrayWaterEquivalentThickness', 0x300A00F3,
          'Total Block Tray Water-Equivalent Thickness', VR.kFL, VM.k1, false);
  static const PTag kBlockSequence
      //(300A,00F4)
      = const PTag._('BlockSequence', 0x300A00F4, 'Block Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBlockTrayID
      //(300A,00F5)
      = const PTag._('BlockTrayID', 0x300A00F5, 'Block Tray ID', VR.kSH, VM.k1, false);
  static const PTag kSourceToBlockTrayDistance
      //(300A,00F6)
      = const PTag._('SourceToBlockTrayDistance', 0x300A00F6,
          'Source to Block Tray Distance', VR.kDS, VM.k1, false);
  static const PTag kIsocenterToBlockTrayDistance
      //(300A,00F7)
      = const PTag._('IsocenterToBlockTrayDistance', 0x300A00F7,
          'Isocenter to Block Tray Distance', VR.kFL, VM.k1, false);
  static const PTag kBlockType
      //(300A,00F8)
      = const PTag._('BlockType', 0x300A00F8, 'Block Type', VR.kCS, VM.k1, false);
  static const PTag kAccessoryCode
      //(300A,00F9)
      = const PTag._('AccessoryCode', 0x300A00F9, 'Accessory Code', VR.kLO, VM.k1, false);
  static const PTag kBlockDivergence
      //(300A,00FA)
      = const PTag._(
          'BlockDivergence', 0x300A00FA, 'Block Divergence', VR.kCS, VM.k1, false);
  static const PTag kBlockMountingPosition
      //(300A,00FB)
      = const PTag._('BlockMountingPosition', 0x300A00FB, 'Block Mounting Position',
          VR.kCS, VM.k1, false);
  static const PTag kBlockNumber
      //(300A,00FC)
      = const PTag._('BlockNumber', 0x300A00FC, 'Block Number', VR.kIS, VM.k1, false);
  static const PTag kBlockName
      //(300A,00FE)
      = const PTag._('BlockName', 0x300A00FE, 'Block Name', VR.kLO, VM.k1, false);
  static const PTag kBlockThickness
      //(300A,0100)
      =
      const PTag._('BlockThickness', 0x300A0100, 'Block Thickness', VR.kDS, VM.k1, false);
  static const PTag kBlockTransmission
      //(300A,0102)
      = const PTag._(
          'BlockTransmission', 0x300A0102, 'Block Transmission', VR.kDS, VM.k1, false);
  static const PTag kBlockNumberOfPoints
      //(300A,0104)
      = const PTag._('BlockNumberOfPoints', 0x300A0104, 'Block Number of Points', VR.kIS,
          VM.k1, false);
  static const PTag kBlockData
      //(300A,0106)
      = const PTag._('BlockData', 0x300A0106, 'Block Data', VR.kDS, VM.k2_2n, false);
  static const PTag kApplicatorSequence
      //(300A,0107)
      = const PTag._(
          'ApplicatorSequence', 0x300A0107, 'Applicator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kApplicatorID
      //(300A,0108)
      = const PTag._('ApplicatorID', 0x300A0108, 'Applicator ID', VR.kSH, VM.k1, false);
  static const PTag kApplicatorType
      //(300A,0109)
      =
      const PTag._('ApplicatorType', 0x300A0109, 'Applicator Type', VR.kCS, VM.k1, false);
  static const PTag kApplicatorDescription
      //(300A,010A)
      = const PTag._('ApplicatorDescription', 0x300A010A, 'Applicator Description',
          VR.kLO, VM.k1, false);
  static const PTag kCumulativeDoseReferenceCoefficient
      //(300A,010C)
      = const PTag._('CumulativeDoseReferenceCoefficient', 0x300A010C,
          'Cumulative Dose Reference Coefficient', VR.kDS, VM.k1, false);
  static const PTag kFinalCumulativeMetersetWeight
      //(300A,010E)
      = const PTag._('FinalCumulativeMetersetWeight', 0x300A010E,
          'Final Cumulative Meterset Weight', VR.kDS, VM.k1, false);
  static const PTag kNumberOfControlPoints
      //(300A,0110)
      = const PTag._('NumberOfControlPoints', 0x300A0110, 'Number of Control Points',
          VR.kIS, VM.k1, false);
  static const PTag kControlPointSequence
      //(300A,0111)
      = const PTag._('ControlPointSequence', 0x300A0111, 'Control Point Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kControlPointIndex
      //(300A,0112)
      = const PTag._(
          'ControlPointIndex', 0x300A0112, 'Control Point Index', VR.kIS, VM.k1, false);
  static const PTag kNominalBeamEnergy
      //(300A,0114)
      = const PTag._(
          'NominalBeamEnergy', 0x300A0114, 'Nominal Beam Energy', VR.kDS, VM.k1, false);
  static const PTag kDoseRateSet
      //(300A,0115)
      = const PTag._('DoseRateSet', 0x300A0115, 'Dose Rate Set', VR.kDS, VM.k1, false);
  static const PTag kWedgePositionSequence
      //(300A,0116)
      = const PTag._('WedgePositionSequence', 0x300A0116, 'Wedge Position Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kWedgePosition
      //(300A,0118)
      = const PTag._('WedgePosition', 0x300A0118, 'Wedge Position', VR.kCS, VM.k1, false);
  static const PTag kBeamLimitingDevicePositionSequence
      //(300A,011A)
      = const PTag._('BeamLimitingDevicePositionSequence', 0x300A011A,
          'Beam Limiting Device Position Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLeafJawPositions
      //(300A,011C)
      = const PTag._(
          'LeafJawPositions', 0x300A011C, 'Leaf/Jaw Positions', VR.kDS, VM.k2_2n, false);
  static const PTag kGantryAngle
      //(300A,011E)
      = const PTag._('GantryAngle', 0x300A011E, 'Gantry Angle', VR.kDS, VM.k1, false);
  static const PTag kGantryRotationDirection
      //(300A,011F)
      = const PTag._('GantryRotationDirection', 0x300A011F, 'Gantry Rotation Direction',
          VR.kCS, VM.k1, false);
  static const PTag kBeamLimitingDeviceAngle
      //(300A,0120)
      = const PTag._('BeamLimitingDeviceAngle', 0x300A0120, 'Beam Limiting Device Angle',
          VR.kDS, VM.k1, false);
  static const PTag kBeamLimitingDeviceRotationDirection
      //(300A,0121)
      = const PTag._('BeamLimitingDeviceRotationDirection', 0x300A0121,
          'Beam Limiting Device Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kPatientSupportAngle
      //(300A,0122)
      = const PTag._('PatientSupportAngle', 0x300A0122, 'Patient Support Angle', VR.kDS,
          VM.k1, false);
  static const PTag kPatientSupportRotationDirection
      //(300A,0123)
      = const PTag._('PatientSupportRotationDirection', 0x300A0123,
          'Patient Support Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kTableTopEccentricAxisDistance
      //(300A,0124)
      = const PTag._('TableTopEccentricAxisDistance', 0x300A0124,
          'Table Top Eccentric Axis Distance', VR.kDS, VM.k1, false);
  static const PTag kTableTopEccentricAngle
      //(300A,0125)
      = const PTag._('TableTopEccentricAngle', 0x300A0125, 'Table Top Eccentric Angle',
          VR.kDS, VM.k1, false);
  static const PTag kTableTopEccentricRotationDirection
      //(300A,0126)
      = const PTag._('TableTopEccentricRotationDirection', 0x300A0126,
          'Table Top Eccentric Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kTableTopVerticalPosition
      //(300A,0128)
      = const PTag._('TableTopVerticalPosition', 0x300A0128,
          'Table Top Vertical Position', VR.kDS, VM.k1, false);
  static const PTag kTableTopLongitudinalPosition
      //(300A,0129)
      = const PTag._('TableTopLongitudinalPosition', 0x300A0129,
          'Table Top Longitudinal Position', VR.kDS, VM.k1, false);
  static const PTag kTableTopLateralPosition
      //(300A,012A)
      = const PTag._('TableTopLateralPosition', 0x300A012A, 'Table Top Lateral Position',
          VR.kDS, VM.k1, false);
  static const PTag kIsocenterPosition
      //(300A,012C)
      = const PTag._(
          'IsocenterPosition', 0x300A012C, 'Isocenter Position', VR.kDS, VM.k3, false);
  static const PTag kSurfaceEntryPoint
      //(300A,012E)
      = const PTag._(
          'SurfaceEntryPoint', 0x300A012E, 'Surface Entry Point', VR.kDS, VM.k3, false);
  static const PTag kSourceToSurfaceDistance
      //(300A,0130)
      = const PTag._('SourceToSurfaceDistance', 0x300A0130, 'Source to Surface Distance',
          VR.kDS, VM.k1, false);
  static const PTag kCumulativeMetersetWeight
      //(300A,0134)
      = const PTag._('CumulativeMetersetWeight', 0x300A0134, 'Cumulative Meterset Weight',
          VR.kDS, VM.k1, false);
  static const PTag kTableTopPitchAngle
      //(300A,0140)
      = const PTag._('TableTopPitchAngle', 0x300A0140, 'Table Top Pitch Angle', VR.kFL,
          VM.k1, false);
  static const PTag kTableTopPitchRotationDirection
      //(300A,0142)
      = const PTag._('TableTopPitchRotationDirection', 0x300A0142,
          'Table Top Pitch Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kTableTopRollAngle
      //(300A,0144)
      = const PTag._(
          'TableTopRollAngle', 0x300A0144, 'Table Top Roll Angle', VR.kFL, VM.k1, false);
  static const PTag kTableTopRollRotationDirection
      //(300A,0146)
      = const PTag._('TableTopRollRotationDirection', 0x300A0146,
          'Table Top Roll Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kHeadFixationAngle
      //(300A,0148)
      = const PTag._(
          'HeadFixationAngle', 0x300A0148, 'Head Fixation Angle', VR.kFL, VM.k1, false);
  static const PTag kGantryPitchAngle
      //(300A,014A)
      = const PTag._(
          'GantryPitchAngle', 0x300A014A, 'Gantry Pitch Angle', VR.kFL, VM.k1, false);
  static const PTag kGantryPitchRotationDirection
      //(300A,014C)
      = const PTag._('GantryPitchRotationDirection', 0x300A014C,
          'Gantry Pitch Rotation Direction', VR.kCS, VM.k1, false);
  static const PTag kGantryPitchAngleTolerance
      //(300A,014E)
      = const PTag._('GantryPitchAngleTolerance', 0x300A014E,
          'Gantry Pitch Angle Tolerance', VR.kFL, VM.k1, false);
  static const PTag kPatientSetupSequence
      //(300A,0180)
      = const PTag._('PatientSetupSequence', 0x300A0180, 'Patient Setup Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kPatientSetupNumber
      //(300A,0182)
      = const PTag._(
          'PatientSetupNumber', 0x300A0182, 'Patient Setup Number', VR.kIS, VM.k1, false);
  static const PTag kPatientSetupLabel
      //(300A,0183)
      = const PTag._(
          'PatientSetupLabel', 0x300A0183, 'Patient Setup Label', VR.kLO, VM.k1, false);
  static const PTag kPatientAdditionalPosition
      //(300A,0184)
      = const PTag._('PatientAdditionalPosition', 0x300A0184,
          'Patient Additional Position', VR.kLO, VM.k1, false);
  static const PTag kFixationDeviceSequence
      //(300A,0190)
      = const PTag._('FixationDeviceSequence', 0x300A0190, 'Fixation Device Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kFixationDeviceType
      //(300A,0192)
      = const PTag._(
          'FixationDeviceType', 0x300A0192, 'Fixation Device Type', VR.kCS, VM.k1, false);
  static const PTag kFixationDeviceLabel
      //(300A,0194)
      = const PTag._('FixationDeviceLabel', 0x300A0194, 'Fixation Device Label', VR.kSH,
          VM.k1, false);
  static const PTag kFixationDeviceDescription
      //(300A,0196)
      = const PTag._('FixationDeviceDescription', 0x300A0196,
          'Fixation Device Description', VR.kST, VM.k1, false);
  static const PTag kFixationDevicePosition
      //(300A,0198)
      = const PTag._('FixationDevicePosition', 0x300A0198, 'Fixation Device Position',
          VR.kSH, VM.k1, false);
  static const PTag kFixationDevicePitchAngle
      //(300A,0199)
      = const PTag._('FixationDevicePitchAngle', 0x300A0199,
          'Fixation Device Pitch Angle', VR.kFL, VM.k1, false);
  static const PTag kFixationDeviceRollAngle
      //(300A,019A)
      = const PTag._('FixationDeviceRollAngle', 0x300A019A, 'Fixation Device Roll Angle',
          VR.kFL, VM.k1, false);
  static const PTag kShieldingDeviceSequence
      //(300A,01A0)
      = const PTag._('ShieldingDeviceSequence', 0x300A01A0, 'Shielding Device Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kShieldingDeviceType
      //(300A,01A2)
      = const PTag._('ShieldingDeviceType', 0x300A01A2, 'Shielding Device Type', VR.kCS,
          VM.k1, false);
  static const PTag kShieldingDeviceLabel
      //(300A,01A4)
      = const PTag._('ShieldingDeviceLabel', 0x300A01A4, 'Shielding Device Label', VR.kSH,
          VM.k1, false);
  static const PTag kShieldingDeviceDescription
      //(300A,01A6)
      = const PTag._('ShieldingDeviceDescription', 0x300A01A6,
          'Shielding Device Description', VR.kST, VM.k1, false);
  static const PTag kShieldingDevicePosition
      //(300A,01A8)
      = const PTag._('ShieldingDevicePosition', 0x300A01A8, 'Shielding Device Position',
          VR.kSH, VM.k1, false);
  static const PTag kSetupTechnique
      //(300A,01B0)
      =
      const PTag._('SetupTechnique', 0x300A01B0, 'Setup Technique', VR.kCS, VM.k1, false);
  static const PTag kSetupTechniqueDescription
      //(300A,01B2)
      = const PTag._('SetupTechniqueDescription', 0x300A01B2,
          'Setup Technique Description', VR.kST, VM.k1, false);
  static const PTag kSetupDeviceSequence
      //(300A,01B4)
      = const PTag._('SetupDeviceSequence', 0x300A01B4, 'Setup Device Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kSetupDeviceType
      //(300A,01B6)
      = const PTag._(
          'SetupDeviceType', 0x300A01B6, 'Setup Device Type', VR.kCS, VM.k1, false);
  static const PTag kSetupDeviceLabel
      //(300A,01B8)
      = const PTag._(
          'SetupDeviceLabel', 0x300A01B8, 'Setup Device Label', VR.kSH, VM.k1, false);
  static const PTag kSetupDeviceDescription
      //(300A,01BA)
      = const PTag._('SetupDeviceDescription', 0x300A01BA, 'Setup Device Description',
          VR.kST, VM.k1, false);
  static const PTag kSetupDeviceParameter
      //(300A,01BC)
      = const PTag._('SetupDeviceParameter', 0x300A01BC, 'Setup Device Parameter', VR.kDS,
          VM.k1, false);
  static const PTag kSetupReferenceDescription
      //(300A,01D0)
      = const PTag._('SetupReferenceDescription', 0x300A01D0,
          'Setup Reference Description', VR.kST, VM.k1, false);
  static const PTag kTableTopVerticalSetupDisplacement
      //(300A,01D2)
      = const PTag._('TableTopVerticalSetupDisplacement', 0x300A01D2,
          'Table Top Vertical Setup Displacement', VR.kDS, VM.k1, false);
  static const PTag kTableTopLongitudinalSetupDisplacement
      //(300A,01D4)
      = const PTag._('TableTopLongitudinalSetupDisplacement', 0x300A01D4,
          'Table Top Longitudinal Setup Displacement', VR.kDS, VM.k1, false);
  static const PTag kTableTopLateralSetupDisplacement
      //(300A,01D6)
      = const PTag._('TableTopLateralSetupDisplacement', 0x300A01D6,
          'Table Top Lateral Setup Displacement', VR.kDS, VM.k1, false);
  static const PTag kBrachyTreatmentTechnique
      //(300A,0200)
      = const PTag._('BrachyTreatmentTechnique', 0x300A0200, 'Brachy Treatment Technique',
          VR.kCS, VM.k1, false);
  static const PTag kBrachyTreatmentType
      //(300A,0202)
      = const PTag._('BrachyTreatmentType', 0x300A0202, 'Brachy Treatment Type', VR.kCS,
          VM.k1, false);
  static const PTag kTreatmentMachineSequence
      //(300A,0206)
      = const PTag._('TreatmentMachineSequence', 0x300A0206, 'Treatment Machine Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSourceSequence
      //(300A,0210)
      =
      const PTag._('SourceSequence', 0x300A0210, 'Source Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSourceNumber
      //(300A,0212)
      = const PTag._('SourceNumber', 0x300A0212, 'Source Number', VR.kIS, VM.k1, false);
  static const PTag kSourceType
      //(300A,0214)
      = const PTag._('SourceType', 0x300A0214, 'Source Type', VR.kCS, VM.k1, false);
  static const PTag kSourceManufacturer
      //(300A,0216)
      = const PTag._(
          'SourceManufacturer', 0x300A0216, 'Source Manufacturer', VR.kLO, VM.k1, false);
  static const PTag kActiveSourceDiameter
      //(300A,0218)
      = const PTag._('ActiveSourceDiameter', 0x300A0218, 'Active Source Diameter', VR.kDS,
          VM.k1, false);
  static const PTag kActiveSourceLength
      //(300A,021A)
      = const PTag._(
          'ActiveSourceLength', 0x300A021A, 'Active Source Length', VR.kDS, VM.k1, false);
  static const PTag kSourceModelID
      //(300A,021B)
      =
      const PTag._('SourceModelID', 0x300A021B, 'Source Model ID', VR.kSH, VM.k1, false);
  static const PTag kSourceDescription
      //(300A,021C)
      = const PTag._(
          'SourceDescription', 0x300A021C, 'Source Description', VR.kLO, VM.k1, false);
  static const PTag kSourceEncapsulationNominalThickness
      //(300A,0222)
      = const PTag._('SourceEncapsulationNominalThickness', 0x300A0222,
          'Source Encapsulation Nominal Thickness', VR.kDS, VM.k1, false);
  static const PTag kSourceEncapsulationNominalTransmission
      //(300A,0224)
      = const PTag._('SourceEncapsulationNominalTransmission', 0x300A0224,
          'Source Encapsulation Nominal Transmission', VR.kDS, VM.k1, false);
  static const PTag kSourceIsotopeName
      //(300A,0226)
      = const PTag._(
          'SourceIsotopeName', 0x300A0226, 'Source Isotope Name', VR.kLO, VM.k1, false);
  static const PTag kSourceIsotopeHalfLife
      //(300A,0228)
      = const PTag._('SourceIsotopeHalfLife', 0x300A0228, 'Source Isotope Half Life',
          VR.kDS, VM.k1, false);
  static const PTag kSourceStrengthUnits
      //(300A,0229)
      = const PTag._('SourceStrengthUnits', 0x300A0229, 'Source Strength Units', VR.kCS,
          VM.k1, false);
  static const PTag kReferenceAirKermaRate
      //(300A,022A)
      = const PTag._('ReferenceAirKermaRate', 0x300A022A, 'Reference Air Kerma Rate',
          VR.kDS, VM.k1, false);
  static const PTag kSourceStrength
      //(300A,022B)
      =
      const PTag._('SourceStrength', 0x300A022B, 'Source Strength', VR.kDS, VM.k1, false);
  static const PTag kSourceStrengthReferenceDate
      //(300A,022C)
      = const PTag._('SourceStrengthReferenceDate', 0x300A022C,
          'Source Strength Reference Date', VR.kDA, VM.k1, false);
  static const PTag kSourceStrengthReferenceTime
      //(300A,022E)
      = const PTag._('SourceStrengthReferenceTime', 0x300A022E,
          'Source Strength Reference Time', VR.kTM, VM.k1, false);
  static const PTag kApplicationSetupSequence
      //(300A,0230)
      = const PTag._('ApplicationSetupSequence', 0x300A0230, 'Application Setup Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kApplicationSetupType
      //(300A,0232)
      = const PTag._('ApplicationSetupType', 0x300A0232, 'Application Setup Type', VR.kCS,
          VM.k1, false);
  static const PTag kApplicationSetupNumber
      //(300A,0234)
      = const PTag._('ApplicationSetupNumber', 0x300A0234, 'Application Setup Number',
          VR.kIS, VM.k1, false);
  static const PTag kApplicationSetupName
      //(300A,0236)
      = const PTag._('ApplicationSetupName', 0x300A0236, 'Application Setup Name', VR.kLO,
          VM.k1, false);
  static const PTag kApplicationSetupManufacturer
      //(300A,0238)
      = const PTag._('ApplicationSetupManufacturer', 0x300A0238,
          'Application Setup Manufacturer', VR.kLO, VM.k1, false);
  static const PTag kTemplateNumber
      //(300A,0240)
      =
      const PTag._('TemplateNumber', 0x300A0240, 'Template Number', VR.kIS, VM.k1, false);
  static const PTag kTemplateType
      //(300A,0242)
      = const PTag._('TemplateType', 0x300A0242, 'Template Type', VR.kSH, VM.k1, false);
  static const PTag kTemplateName
      //(300A,0244)
      = const PTag._('TemplateName', 0x300A0244, 'Template Name', VR.kLO, VM.k1, false);
  static const PTag kTotalReferenceAirKerma
      //(300A,0250)
      = const PTag._('TotalReferenceAirKerma', 0x300A0250, 'Total Reference Air Kerma',
          VR.kDS, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceSequence
      //(300A,0260)
      = const PTag._('BrachyAccessoryDeviceSequence', 0x300A0260,
          'Brachy Accessory Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceNumber
      //(300A,0262)
      = const PTag._('BrachyAccessoryDeviceNumber', 0x300A0262,
          'Brachy Accessory Device Number', VR.kIS, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceID
      //(300A,0263)
      = const PTag._('BrachyAccessoryDeviceID', 0x300A0263, 'Brachy Accessory Device ID',
          VR.kSH, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceType
      //(300A,0264)
      = const PTag._('BrachyAccessoryDeviceType', 0x300A0264,
          'Brachy Accessory Device Type', VR.kCS, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceName
      //(300A,0266)
      = const PTag._('BrachyAccessoryDeviceName', 0x300A0266,
          'Brachy Accessory Device Name', VR.kLO, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceNominalThickness
      //(300A,026A)
      = const PTag._('BrachyAccessoryDeviceNominalThickness', 0x300A026A,
          'Brachy Accessory Device Nominal Thickness', VR.kDS, VM.k1, false);
  static const PTag kBrachyAccessoryDeviceNominalTransmission
      //(300A,026C)
      = const PTag._('BrachyAccessoryDeviceNominalTransmission', 0x300A026C,
          'Brachy Accessory Device Nominal Transmission', VR.kDS, VM.k1, false);
  static const PTag kChannelSequence
      //(300A,0280)
      = const PTag._(
          'ChannelSequence', 0x300A0280, 'Channel Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChannelNumber
      //(300A,0282)
      = const PTag._('ChannelNumber', 0x300A0282, 'Channel Number', VR.kIS, VM.k1, false);
  static const PTag kChannelLength
      //(300A,0284)
      = const PTag._('ChannelLength', 0x300A0284, 'Channel Length', VR.kDS, VM.k1, false);
  static const PTag kChannelTotalTime
      //(300A,0286)
      = const PTag._(
          'ChannelTotalTime', 0x300A0286, 'Channel Total Time', VR.kDS, VM.k1, false);
  static const PTag kSourceMovementType
      //(300A,0288)
      = const PTag._(
          'SourceMovementType', 0x300A0288, 'Source Movement Type', VR.kCS, VM.k1, false);
  static const PTag kNumberOfPulses
      //(300A,028A)
      = const PTag._(
          'NumberOfPulses', 0x300A028A, 'Number of Pulses', VR.kIS, VM.k1, false);
  static const PTag kPulseRepetitionInterval
      //(300A,028C)
      = const PTag._('PulseRepetitionInterval', 0x300A028C, 'Pulse Repetition Interval',
          VR.kDS, VM.k1, false);
  static const PTag kSourceApplicatorNumber
      //(300A,0290)
      = const PTag._('SourceApplicatorNumber', 0x300A0290, 'Source Applicator Number',
          VR.kIS, VM.k1, false);
  static const PTag kSourceApplicatorID
      //(300A,0291)
      = const PTag._(
          'SourceApplicatorID', 0x300A0291, 'Source Applicator ID', VR.kSH, VM.k1, false);
  static const PTag kSourceApplicatorType
      //(300A,0292)
      = const PTag._('SourceApplicatorType', 0x300A0292, 'Source Applicator Type', VR.kCS,
          VM.k1, false);
  static const PTag kSourceApplicatorName
      //(300A,0294)
      = const PTag._('SourceApplicatorName', 0x300A0294, 'Source Applicator Name', VR.kLO,
          VM.k1, false);
  static const PTag kSourceApplicatorLength
      //(300A,0296)
      = const PTag._('SourceApplicatorLength', 0x300A0296, 'Source Applicator Length',
          VR.kDS, VM.k1, false);
  static const PTag kSourceApplicatorManufacturer
      //(300A,0298)
      = const PTag._('SourceApplicatorManufacturer', 0x300A0298,
          'Source Applicator Manufacturer', VR.kLO, VM.k1, false);
  static const PTag kSourceApplicatorWallNominalThickness
      //(300A,029C)
      = const PTag._('SourceApplicatorWallNominalThickness', 0x300A029C,
          'Source Applicator Wall Nominal Thickness', VR.kDS, VM.k1, false);
  static const PTag kSourceApplicatorWallNominalTransmission
      //(300A,029E)
      = const PTag._('SourceApplicatorWallNominalTransmission', 0x300A029E,
          'Source Applicator Wall Nominal Transmission', VR.kDS, VM.k1, false);
  static const PTag kSourceApplicatorStepSize
      //(300A,02A0)
      = const PTag._('SourceApplicatorStepSize', 0x300A02A0,
          'Source Applicator Step Size', VR.kDS, VM.k1, false);
  static const PTag kTransferTubeNumber
      //(300A,02A2)
      = const PTag._(
          'TransferTubeNumber', 0x300A02A2, 'Transfer Tube Number', VR.kIS, VM.k1, false);
  static const PTag kTransferTubeLength
      //(300A,02A4)
      = const PTag._(
          'TransferTubeLength', 0x300A02A4, 'Transfer Tube Length', VR.kDS, VM.k1, false);
  static const PTag kChannelShieldSequence
      //(300A,02B0)
      = const PTag._('ChannelShieldSequence', 0x300A02B0, 'Channel Shield Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kChannelShieldNumber
      //(300A,02B2)
      = const PTag._('ChannelShieldNumber', 0x300A02B2, 'Channel Shield Number', VR.kIS,
          VM.k1, false);
  static const PTag kChannelShieldID
      //(300A,02B3)
      = const PTag._(
          'ChannelShieldID', 0x300A02B3, 'Channel Shield ID', VR.kSH, VM.k1, false);
  static const PTag kChannelShieldName
      //(300A,02B4)
      = const PTag._(
          'ChannelShieldName', 0x300A02B4, 'Channel Shield Name', VR.kLO, VM.k1, false);
  static const PTag kChannelShieldNominalThickness
      //(300A,02B8)
      = const PTag._('ChannelShieldNominalThickness', 0x300A02B8,
          'Channel Shield Nominal Thickness', VR.kDS, VM.k1, false);
  static const PTag kChannelShieldNominalTransmission
      //(300A,02BA)
      = const PTag._('ChannelShieldNominalTransmission', 0x300A02BA,
          'Channel Shield Nominal Transmission', VR.kDS, VM.k1, false);
  static const PTag kFinalCumulativeTimeWeight
      //(300A,02C8)
      = const PTag._('FinalCumulativeTimeWeight', 0x300A02C8,
          'Final Cumulative Time Weight', VR.kDS, VM.k1, false);
  static const PTag kBrachyControlPointSequence
      //(300A,02D0)
      = const PTag._('BrachyControlPointSequence', 0x300A02D0,
          'Brachy Control Point Sequence', VR.kSQ, VM.k1, false);
  static const PTag kControlPointRelativePosition
      //(300A,02D2)
      = const PTag._('ControlPointRelativePosition', 0x300A02D2,
          'Control Point Relative Position', VR.kDS, VM.k1, false);
  static const PTag kControlPoint3DPosition
      //(300A,02D4)
      = const PTag._('ControlPoint3DPosition', 0x300A02D4, 'Control Point 3D Position',
          VR.kDS, VM.k3, false);
  static const PTag kCumulativeTimeWeight
      //(300A,02D6)
      = const PTag._('CumulativeTimeWeight', 0x300A02D6, 'Cumulative Time Weight', VR.kDS,
          VM.k1, false);
  static const PTag kCompensatorDivergence
      //(300A,02E0)
      = const PTag._('CompensatorDivergence', 0x300A02E0, 'Compensator Divergence',
          VR.kCS, VM.k1, false);
  static const PTag kCompensatorMountingPosition
      //(300A,02E1)
      = const PTag._('CompensatorMountingPosition', 0x300A02E1,
          'Compensator Mounting Position', VR.kCS, VM.k1, false);
  static const PTag kSourceToCompensatorDistance
      //(300A,02E2)
      = const PTag._('SourceToCompensatorDistance', 0x300A02E2,
          'Source to Compensator Distance', VR.kDS, VM.k1_n, false);
  static const PTag kTotalCompensatorTrayWaterEquivalentThickness
      //(300A,02E3)
      = const PTag._('TotalCompensatorTrayWaterEquivalentThickness', 0x300A02E3,
          'Total Compensator Tray Water-Equivalent Thickness', VR.kFL, VM.k1, false);
  static const PTag kIsocenterToCompensatorTrayDistance
      //(300A,02E4)
      = const PTag._('IsocenterToCompensatorTrayDistance', 0x300A02E4,
          'Isocenter to Compensator Tray Distance', VR.kFL, VM.k1, false);
  static const PTag kCompensatorColumnOffset
      //(300A,02E5)
      = const PTag._('CompensatorColumnOffset', 0x300A02E5, 'Compensator Column Offset',
          VR.kFL, VM.k1, false);
  static const PTag kIsocenterToCompensatorDistances
      //(300A,02E6)
      = const PTag._('IsocenterToCompensatorDistances', 0x300A02E6,
          'Isocenter to Compensator Distances', VR.kFL, VM.k1_n, false);
  static const PTag kCompensatorRelativeStoppingPowerRatio
      //(300A,02E7)
      = const PTag._('CompensatorRelativeStoppingPowerRatio', 0x300A02E7,
          'Compensator Relative Stopping Power Ratio', VR.kFL, VM.k1, false);
  static const PTag kCompensatorMillingToolDiameter
      //(300A,02E8)
      = const PTag._('CompensatorMillingToolDiameter', 0x300A02E8,
          'Compensator Milling Tool Diameter', VR.kFL, VM.k1, false);
  static const PTag kIonRangeCompensatorSequence
      //(300A,02EA)
      = const PTag._('IonRangeCompensatorSequence', 0x300A02EA,
          'Ion Range Compensator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kCompensatorDescription
      //(300A,02EB)
      = const PTag._('CompensatorDescription', 0x300A02EB, 'Compensator Description',
          VR.kLT, VM.k1, false);
  static const PTag kRadiationMassNumber
      //(300A,0302)
      = const PTag._('RadiationMassNumber', 0x300A0302, 'Radiation Mass Number', VR.kIS,
          VM.k1, false);
  static const PTag kRadiationAtomicNumber
      //(300A,0304)
      = const PTag._('RadiationAtomicNumber', 0x300A0304, 'Radiation Atomic Number',
          VR.kIS, VM.k1, false);
  static const PTag kRadiationChargeState
      //(300A,0306)
      = const PTag._('RadiationChargeState', 0x300A0306, 'Radiation Charge State', VR.kSS,
          VM.k1, false);
  static const PTag kScanMode
      //(300A,0308)
      = const PTag._('ScanMode', 0x300A0308, 'Scan Mode', VR.kCS, VM.k1, false);
  static const PTag kVirtualSourceAxisDistances
      //(300A,030A)
      = const PTag._('VirtualSourceAxisDistances', 0x300A030A,
          'Virtual Source-Axis Distances', VR.kFL, VM.k2, false);
  static const PTag kSnoutSequence
      //(300A,030C)
      = const PTag._('SnoutSequence', 0x300A030C, 'Snout Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSnoutPosition
      //(300A,030D)
      = const PTag._('SnoutPosition', 0x300A030D, 'Snout Position', VR.kFL, VM.k1, false);
  static const PTag kSnoutID
      //(300A,030F)
      = const PTag._('SnoutID', 0x300A030F, 'Snout ID', VR.kSH, VM.k1, false);
  static const PTag kNumberOfRangeShifters
      //(300A,0312)
      = const PTag._('NumberOfRangeShifters', 0x300A0312, 'Number of Range Shifters',
          VR.kIS, VM.k1, false);
  static const PTag kRangeShifterSequence
      //(300A,0314)
      = const PTag._('RangeShifterSequence', 0x300A0314, 'Range Shifter Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kRangeShifterNumber
      //(300A,0316)
      = const PTag._(
          'RangeShifterNumber', 0x300A0316, 'Range Shifter Number', VR.kIS, VM.k1, false);
  static const PTag kRangeShifterID
      //(300A,0318)
      = const PTag._(
          'RangeShifterID', 0x300A0318, 'Range Shifter ID', VR.kSH, VM.k1, false);
  static const PTag kRangeShifterType
      //(300A,0320)
      = const PTag._(
          'RangeShifterType', 0x300A0320, 'Range Shifter Type', VR.kCS, VM.k1, false);
  static const PTag kRangeShifterDescription
      //(300A,0322)
      = const PTag._('RangeShifterDescription', 0x300A0322, 'Range Shifter Description',
          VR.kLO, VM.k1, false);
  static const PTag kNumberOfLateralSpreadingDevices
      //(300A,0330)
      = const PTag._('NumberOfLateralSpreadingDevices', 0x300A0330,
          'Number of Lateral Spreading Devices', VR.kIS, VM.k1, false);
  static const PTag kLateralSpreadingDeviceSequence
      //(300A,0332)
      = const PTag._('LateralSpreadingDeviceSequence', 0x300A0332,
          'Lateral Spreading Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLateralSpreadingDeviceNumber
      //(300A,0334)
      = const PTag._('LateralSpreadingDeviceNumber', 0x300A0334,
          'Lateral Spreading Device Number', VR.kIS, VM.k1, false);
  static const PTag kLateralSpreadingDeviceID
      //(300A,0336)
      = const PTag._('LateralSpreadingDeviceID', 0x300A0336,
          'Lateral Spreading Device ID', VR.kSH, VM.k1, false);
  static const PTag kLateralSpreadingDeviceType
      //(300A,0338)
      = const PTag._('LateralSpreadingDeviceType', 0x300A0338,
          'Lateral Spreading Device Type', VR.kCS, VM.k1, false);
  static const PTag kLateralSpreadingDeviceDescription
      //(300A,033A)
      = const PTag._('LateralSpreadingDeviceDescription', 0x300A033A,
          'Lateral Spreading Device Description', VR.kLO, VM.k1, false);
  static const PTag kLateralSpreadingDeviceWaterEquivalentThickness
      //(300A,033C)
      = const PTag._('LateralSpreadingDeviceWaterEquivalentThickness', 0x300A033C,
          'Lateral Spreading Device Water Equivalent Thickness', VR.kFL, VM.k1, false);
  static const PTag kNumberOfRangeModulators
      //(300A,0340)
      = const PTag._('NumberOfRangeModulators', 0x300A0340, 'Number of Range Modulators',
          VR.kIS, VM.k1, false);
  static const PTag kRangeModulatorSequence
      //(300A,0342)
      = const PTag._('RangeModulatorSequence', 0x300A0342, 'Range Modulator Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kRangeModulatorNumber
      //(300A,0344)
      = const PTag._('RangeModulatorNumber', 0x300A0344, 'Range Modulator Number', VR.kIS,
          VM.k1, false);
  static const PTag kRangeModulatorID
      //(300A,0346)
      = const PTag._(
          'RangeModulatorID', 0x300A0346, 'Range Modulator ID', VR.kSH, VM.k1, false);
  static const PTag kRangeModulatorType
      //(300A,0348)
      = const PTag._(
          'RangeModulatorType', 0x300A0348, 'Range Modulator Type', VR.kCS, VM.k1, false);
  static const PTag kRangeModulatorDescription
      //(300A,034A)
      = const PTag._('RangeModulatorDescription', 0x300A034A,
          'Range Modulator Description', VR.kLO, VM.k1, false);
  static const PTag kBeamCurrentModulationID
      //(300A,034C)
      = const PTag._('BeamCurrentModulationID', 0x300A034C, 'Beam Current Modulation ID',
          VR.kSH, VM.k1, false);
  static const PTag kPatientSupportType
      //(300A,0350)
      = const PTag._(
          'PatientSupportType', 0x300A0350, 'Patient Support Type', VR.kCS, VM.k1, false);
  static const PTag kPatientSupportID
      //(300A,0352)
      = const PTag._(
          'PatientSupportID', 0x300A0352, 'Patient Support ID', VR.kSH, VM.k1, false);
  static const PTag kPatientSupportAccessoryCode
      //(300A,0354)
      = const PTag._('PatientSupportAccessoryCode', 0x300A0354,
          'Patient Support Accessory Code', VR.kLO, VM.k1, false);
  static const PTag kFixationLightAzimuthalAngle
      //(300A,0356)
      = const PTag._('FixationLightAzimuthalAngle', 0x300A0356,
          'Fixation Light Azimuthal Angle', VR.kFL, VM.k1, false);
  static const PTag kFixationLightPolarAngle
      //(300A,0358)
      = const PTag._('FixationLightPolarAngle', 0x300A0358, 'Fixation Light Polar Angle',
          VR.kFL, VM.k1, false);
  static const PTag kMetersetRate
      //(300A,035A)
      = const PTag._('MetersetRate', 0x300A035A, 'Meterset Rate', VR.kFL, VM.k1, false);
  static const PTag kRangeShifterSettingsSequence
      //(300A,0360)
      = const PTag._('RangeShifterSettingsSequence', 0x300A0360,
          'Range Shifter Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRangeShifterSetting
      //(300A,0362)
      = const PTag._('RangeShifterSetting', 0x300A0362, 'Range Shifter Setting', VR.kLO,
          VM.k1, false);
  static const PTag kIsocenterToRangeShifterDistance
      //(300A,0364)
      = const PTag._('IsocenterToRangeShifterDistance', 0x300A0364,
          'Isocenter to Range Shifter Distance', VR.kFL, VM.k1, false);
  static const PTag kRangeShifterWaterEquivalentThickness
      //(300A,0366)
      = const PTag._('RangeShifterWaterEquivalentThickness', 0x300A0366,
          'Range Shifter Water Equivalent Thickness', VR.kFL, VM.k1, false);
  static const PTag kLateralSpreadingDeviceSettingsSequence
      //(300A,0370)
      = const PTag._('LateralSpreadingDeviceSettingsSequence', 0x300A0370,
          'Lateral Spreading Device Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kLateralSpreadingDeviceSetting
      //(300A,0372)
      = const PTag._('LateralSpreadingDeviceSetting', 0x300A0372,
          'Lateral Spreading Device Setting', VR.kLO, VM.k1, false);
  static const PTag kIsocenterToLateralSpreadingDeviceDistance
      //(300A,0374)
      = const PTag._('IsocenterToLateralSpreadingDeviceDistance', 0x300A0374,
          'Isocenter to Lateral Spreading Device Distance', VR.kFL, VM.k1, false);
  static const PTag kRangeModulatorSettingsSequence
      //(300A,0380)
      = const PTag._('RangeModulatorSettingsSequence', 0x300A0380,
          'Range Modulator Settings Sequence', VR.kSQ, VM.k1, false);
  static const PTag kRangeModulatorGatingStartValue
      //(300A,0382)
      = const PTag._('RangeModulatorGatingStartValue', 0x300A0382,
          'Range Modulator Gating Start Value', VR.kFL, VM.k1, false);
  static const PTag kRangeModulatorGatingStopValue
      //(300A,0384)
      = const PTag._('RangeModulatorGatingStopValue', 0x300A0384,
          'Range Modulator Gating Stop Value', VR.kFL, VM.k1, false);
  static const PTag kRangeModulatorGatingStartWaterEquivalentThickness
      //(300A,0386)
      = const PTag._(
          'RangeModulatorGatingStartWaterEquivalentThickness',
          0x300A0386,
          'Range Modulator Gating Start Water Equivalent Thickness',
          VR.kFL,
          VM.k1,
          false);
  static const PTag kRangeModulatorGatingStopWaterEquivalentThickness
      //(300A,0388)
      = const PTag._('RangeModulatorGatingStopWaterEquivalentThickness', 0x300A0388,
          'Range Modulator Gating Stop Water Equivalent Thickness', VR.kFL, VM.k1, false);
  static const PTag kIsocenterToRangeModulatorDistance
      //(300A,038A)
      = const PTag._('IsocenterToRangeModulatorDistance', 0x300A038A,
          'Isocenter to Range Modulator Distance', VR.kFL, VM.k1, false);
  static const PTag kScanSpotTuneID
      //(300A,0390)
      = const PTag._(
          'ScanSpotTuneID', 0x300A0390, 'Scan Spot Tune ID', VR.kSH, VM.k1, false);
  static const PTag kNumberOfScanSpotPositions
      //(300A,0392)
      = const PTag._('NumberOfScanSpotPositions', 0x300A0392,
          'Number of Scan Spot Positions', VR.kIS, VM.k1, false);
  static const PTag kScanSpotPositionMap
      //(300A,0394)
      = const PTag._('ScanSpotPositionMap', 0x300A0394, 'Scan Spot Position Map', VR.kFL,
          VM.k1_n, false);
  static const PTag kScanSpotMetersetWeights
      //(300A,0396)
      = const PTag._('ScanSpotMetersetWeights', 0x300A0396, 'Scan Spot Meterset Weights',
          VR.kFL, VM.k1_n, false);
  static const PTag kScanningSpotSize
      //(300A,0398)
      = const PTag._(
          'ScanningSpotSize', 0x300A0398, 'Scanning Spot Size', VR.kFL, VM.k2, false);
  static const PTag kNumberOfPaintings
      //(300A,039A)
      = const PTag._(
          'NumberOfPaintings', 0x300A039A, 'Number of Paintings', VR.kIS, VM.k1, false);
  static const PTag kIonToleranceTableSequence
      //(300A,03A0)
      = const PTag._('IonToleranceTableSequence', 0x300A03A0,
          'Ion Tolerance Table Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonBeamSequence
      //(300A,03A2)
      = const PTag._(
          'IonBeamSequence', 0x300A03A2, 'Ion Beam Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonBeamLimitingDeviceSequence
      //(300A,03A4)
      = const PTag._('IonBeamLimitingDeviceSequence', 0x300A03A4,
          'Ion Beam Limiting Device Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonBlockSequence
      //(300A,03A6)
      = const PTag._(
          'IonBlockSequence', 0x300A03A6, 'Ion Block Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonControlPointSequence
      //(300A,03A8)
      = const PTag._('IonControlPointSequence', 0x300A03A8, 'Ion Control Point Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kIonWedgeSequence
      //(300A,03AA)
      = const PTag._(
          'IonWedgeSequence', 0x300A03AA, 'Ion Wedge Sequence', VR.kSQ, VM.k1, false);
  static const PTag kIonWedgePositionSequence
      //(300A,03AC)
      = const PTag._('IonWedgePositionSequence', 0x300A03AC,
          'Ion Wedge Position Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedSetupImageSequence
      //(300A,0401)
      = const PTag._('ReferencedSetupImageSequence', 0x300A0401,
          'Referenced Setup Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kSetupImageComment
      //(300A,0402)
      = const PTag._(
          'SetupImageComment', 0x300A0402, 'Setup Image Comment', VR.kST, VM.k1, false);
  static const PTag kMotionSynchronizationSequence
      //(300A,0410)
      = const PTag._('MotionSynchronizationSequence', 0x300A0410,
          'Motion Synchronization Sequence', VR.kSQ, VM.k1, false);
  static const PTag kControlPointOrientation
      //(300A,0412)
      = const PTag._('ControlPointOrientation', 0x300A0412, 'Control Point Orientation',
          VR.kFL, VM.k3, false);
  static const PTag kGeneralAccessorySequence
      //(300A,0420)
      = const PTag._('GeneralAccessorySequence', 0x300A0420, 'General Accessory Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kGeneralAccessoryID
      //(300A,0421)
      = const PTag._(
          'GeneralAccessoryID', 0x300A0421, 'General Accessory ID', VR.kSH, VM.k1, false);
  static const PTag kGeneralAccessoryDescription
      //(300A,0422)
      = const PTag._('GeneralAccessoryDescription', 0x300A0422,
          'General Accessory Description', VR.kST, VM.k1, false);
  static const PTag kGeneralAccessoryType
      //(300A,0423)
      = const PTag._('GeneralAccessoryType', 0x300A0423, 'General Accessory Type', VR.kCS,
          VM.k1, false);
  static const PTag kGeneralAccessoryNumber
      //(300A,0424)
      = const PTag._('GeneralAccessoryNumber', 0x300A0424, 'General Accessory Number',
          VR.kIS, VM.k1, false);
  static const PTag kSourceToGeneralAccessoryDistance
      //(300A,0425)
      = const PTag._('SourceToGeneralAccessoryDistance', 0x300A0425,
          'Source to General Accessory Distance', VR.kFL, VM.k1, false);
  static const PTag kApplicatorGeometrySequence
      //(300A,0431)
      = const PTag._('ApplicatorGeometrySequence', 0x300A0431,
          'Applicator Geometry Sequence', VR.kSQ, VM.k1, false);
  static const PTag kApplicatorApertureShape
      //(300A,0432)
      = const PTag._('ApplicatorApertureShape', 0x300A0432, 'Applicator Aperture Shape',
          VR.kCS, VM.k1, false);
  static const PTag kApplicatorOpening
      //(300A,0433)
      = const PTag._(
          'ApplicatorOpening', 0x300A0433, 'Applicator Opening', VR.kFL, VM.k1, false);
  static const PTag kApplicatorOpeningX
      //(300A,0434)
      = const PTag._(
          'ApplicatorOpeningX', 0x300A0434, 'Applicator Opening X', VR.kFL, VM.k1, false);
  static const PTag kApplicatorOpeningY
      //(300A,0435)
      = const PTag._(
          'ApplicatorOpeningY', 0x300A0435, 'Applicator Opening Y', VR.kFL, VM.k1, false);
  static const PTag kSourceToApplicatorMountingPositionDistance
      //(300A,0436)
      = const PTag._('SourceToApplicatorMountingPositionDistance', 0x300A0436,
          'Source to Applicator Mounting Position Distance', VR.kFL, VM.k1, false);
  static const PTag kReferencedRTPlanSequence
      //(300C,0002)
      = const PTag._('ReferencedRTPlanSequence', 0x300C0002,
          'Referenced RT Plan Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedBeamSequence
      //(300C,0004)
      = const PTag._('ReferencedBeamSequence', 0x300C0004, 'Referenced Beam Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedBeamNumber
      //(300C,0006)
      = const PTag._('ReferencedBeamNumber', 0x300C0006, 'Referenced Beam Number', VR.kIS,
          VM.k1, false);
  static const PTag kReferencedReferenceImageNumber
      //(300C,0007)
      = const PTag._('ReferencedReferenceImageNumber', 0x300C0007,
          'Referenced Reference Image Number', VR.kIS, VM.k1, false);
  static const PTag kStartCumulativeMetersetWeight
      //(300C,0008)
      = const PTag._('StartCumulativeMetersetWeight', 0x300C0008,
          'Start Cumulative Meterset Weight', VR.kDS, VM.k1, false);
  static const PTag kEndCumulativeMetersetWeight
      //(300C,0009)
      = const PTag._('EndCumulativeMetersetWeight', 0x300C0009,
          'End Cumulative Meterset Weight', VR.kDS, VM.k1, false);
  static const PTag kReferencedBrachyApplicationSetupSequence
      //(300C,000A)
      = const PTag._('ReferencedBrachyApplicationSetupSequence', 0x300C000A,
          'Referenced Brachy Application Setup Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedBrachyApplicationSetupNumber
      //(300C,000C)
      = const PTag._('ReferencedBrachyApplicationSetupNumber', 0x300C000C,
          'Referenced Brachy Application Setup Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedSourceNumber
      //(300C,000E)
      = const PTag._('ReferencedSourceNumber', 0x300C000E, 'Referenced Source Number',
          VR.kIS, VM.k1, false);
  static const PTag kReferencedFractionGroupSequence
      //(300C,0020)
      = const PTag._('ReferencedFractionGroupSequence', 0x300C0020,
          'Referenced Fraction Group Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedFractionGroupNumber
      //(300C,0022)
      = const PTag._('ReferencedFractionGroupNumber', 0x300C0022,
          'Referenced Fraction Group Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedVerificationImageSequence
      //(300C,0040)
      = const PTag._('ReferencedVerificationImageSequence', 0x300C0040,
          'Referenced Verification Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedReferenceImageSequence
      //(300C,0042)
      = const PTag._('ReferencedReferenceImageSequence', 0x300C0042,
          'Referenced Reference Image Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedDoseReferenceSequence
      //(300C,0050)
      = const PTag._('ReferencedDoseReferenceSequence', 0x300C0050,
          'Referenced Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedDoseReferenceNumber
      //(300C,0051)
      = const PTag._('ReferencedDoseReferenceNumber', 0x300C0051,
          'Referenced Dose Reference Number', VR.kIS, VM.k1, false);
  static const PTag kBrachyReferencedDoseReferenceSequence
      //(300C,0055)
      = const PTag._('BrachyReferencedDoseReferenceSequence', 0x300C0055,
          'Brachy Referenced Dose Reference Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedStructureSetSequence
      //(300C,0060)
      = const PTag._('ReferencedStructureSetSequence', 0x300C0060,
          'Referenced Structure Set Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedPatientSetupNumber
      //(300C,006A)
      = const PTag._('ReferencedPatientSetupNumber', 0x300C006A,
          'Referenced Patient Setup Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedDoseSequence
      //(300C,0080)
      = const PTag._('ReferencedDoseSequence', 0x300C0080, 'Referenced Dose Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedToleranceTableNumber
      //(300C,00A0)
      = const PTag._('ReferencedToleranceTableNumber', 0x300C00A0,
          'Referenced Tolerance Table Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedBolusSequence
      //(300C,00B0)
      = const PTag._('ReferencedBolusSequence', 0x300C00B0, 'Referenced Bolus Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedWedgeNumber
      //(300C,00C0)
      = const PTag._('ReferencedWedgeNumber', 0x300C00C0, 'Referenced Wedge Number',
          VR.kIS, VM.k1, false);
  static const PTag kReferencedCompensatorNumber
      //(300C,00D0)
      = const PTag._('ReferencedCompensatorNumber', 0x300C00D0,
          'Referenced Compensator Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedBlockNumber
      //(300C,00E0)
      = const PTag._('ReferencedBlockNumber', 0x300C00E0, 'Referenced Block Number',
          VR.kIS, VM.k1, false);
  static const PTag kReferencedControlPointIndex
      //(300C,00F0)
      = const PTag._('ReferencedControlPointIndex', 0x300C00F0,
          'Referenced Control Point Index', VR.kIS, VM.k1, false);
  static const PTag kReferencedControlPointSequence
      //(300C,00F2)
      = const PTag._('ReferencedControlPointSequence', 0x300C00F2,
          'Referenced Control Point Sequence', VR.kSQ, VM.k1, false);
  static const PTag kReferencedStartControlPointIndex
      //(300C,00F4)
      = const PTag._('ReferencedStartControlPointIndex', 0x300C00F4,
          'Referenced Start Control Point Index', VR.kIS, VM.k1, false);
  static const PTag kReferencedStopControlPointIndex
      //(300C,00F6)
      = const PTag._('ReferencedStopControlPointIndex', 0x300C00F6,
          'Referenced Stop Control Point Index', VR.kIS, VM.k1, false);
  static const PTag kReferencedRangeShifterNumber
      //(300C,0100)
      = const PTag._('ReferencedRangeShifterNumber', 0x300C0100,
          'Referenced Range Shifter Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedLateralSpreadingDeviceNumber
      //(300C,0102)
      = const PTag._('ReferencedLateralSpreadingDeviceNumber', 0x300C0102,
          'Referenced Lateral Spreading Device Number', VR.kIS, VM.k1, false);
  static const PTag kReferencedRangeModulatorNumber
      //(300C,0104)
      = const PTag._('ReferencedRangeModulatorNumber', 0x300C0104,
          'Referenced Range Modulator Number', VR.kIS, VM.k1, false);
  static const PTag kApprovalStatus
      //(300E,0002)
      =
      const PTag._('ApprovalStatus', 0x300E0002, 'Approval Status', VR.kCS, VM.k1, false);
  static const PTag kReviewDate
      //(300E,0004)
      = const PTag._('ReviewDate', 0x300E0004, 'Review Date', VR.kDA, VM.k1, false);
  static const PTag kReviewTime
      //(300E,0005)
      = const PTag._('ReviewTime', 0x300E0005, 'Review Time', VR.kTM, VM.k1, false);
  static const PTag kReviewerName
      //(300E,0008)
      = const PTag._('ReviewerName', 0x300E0008, 'Reviewer Name', VR.kPN, VM.k1, false);
  static const PTag kArbitrary
      //(4000,0010)
      = const PTag._('Arbitrary', 0x40000010, 'Arbitrary', VR.kLT, VM.k1, true);
  static const PTag kTextComments
      //(4000,4000)
      = const PTag._('TextComments', 0x40004000, 'Text Comments', VR.kLT, VM.k1, true);
  static const PTag kResultsID
      //(4008,0040)
      = const PTag._('ResultsID', 0x40080040, 'Results ID', VR.kSH, VM.k1, true);
  static const PTag kResultsIDIssuer
      //(4008,0042)
      = const PTag._(
          'ResultsIDIssuer', 0x40080042, 'Results ID Issuer', VR.kLO, VM.k1, true);
  static const PTag kReferencedInterpretationSequence
      //(4008,0050)
      = const PTag._('ReferencedInterpretationSequence', 0x40080050,
          'Referenced Interpretation Sequence', VR.kSQ, VM.k1, true);
  static const PTag kReportProductionStatusTrial
      //(4008,00FF)
      = const PTag._('ReportProductionStatusTrial', 0x400800FF,
          'Report Production Status (Trial)', VR.kCS, VM.k1, true);
  static const PTag kInterpretationRecordedDate
      //(4008,0100)
      = const PTag._('InterpretationRecordedDate', 0x40080100,
          'Interpretation Recorded Date', VR.kDA, VM.k1, true);
  static const PTag kInterpretationRecordedTime
      //(4008,0101)
      = const PTag._('InterpretationRecordedTime', 0x40080101,
          'Interpretation Recorded Time', VR.kTM, VM.k1, true);
  static const PTag kInterpretationRecorder
      //(4008,0102)
      = const PTag._('InterpretationRecorder', 0x40080102, 'Interpretation Recorder',
          VR.kPN, VM.k1, true);
  static const PTag kReferenceToRecordedSound
      //(4008,0103)
      = const PTag._('ReferenceToRecordedSound', 0x40080103,
          'Reference to Recorded Sound', VR.kLO, VM.k1, true);
  static const PTag kInterpretationTranscriptionDate
      //(4008,0108)
      = const PTag._('InterpretationTranscriptionDate', 0x40080108,
          'Interpretation Transcription Date', VR.kDA, VM.k1, true);
  static const PTag kInterpretationTranscriptionTime
      //(4008,0109)
      = const PTag._('InterpretationTranscriptionTime', 0x40080109,
          'Interpretation Transcription Time', VR.kTM, VM.k1, true);
  static const PTag kInterpretationTranscriber
      //(4008,010A)
      = const PTag._('InterpretationTranscriber', 0x4008010A,
          'Interpretation Transcriber', VR.kPN, VM.k1, true);
  static const PTag kInterpretationText
      //(4008,010B)
      = const PTag._(
          'InterpretationText', 0x4008010B, 'Interpretation Text', VR.kST, VM.k1, true);
  static const PTag kInterpretationAuthor
      //(4008,010C)
      = const PTag._('InterpretationAuthor', 0x4008010C, 'Interpretation Author', VR.kPN,
          VM.k1, true);
  static const PTag kInterpretationApproverSequence
      //(4008,0111)
      = const PTag._('InterpretationApproverSequence', 0x40080111,
          'Interpretation Approver Sequence', VR.kSQ, VM.k1, true);
  static const PTag kInterpretationApprovalDate
      //(4008,0112)
      = const PTag._('InterpretationApprovalDate', 0x40080112,
          'Interpretation Approval Date', VR.kDA, VM.k1, true);
  static const PTag kInterpretationApprovalTime
      //(4008,0113)
      = const PTag._('InterpretationApprovalTime', 0x40080113,
          'Interpretation Approval Time', VR.kTM, VM.k1, true);
  static const PTag kPhysicianApprovingInterpretation
      //(4008,0114)
      = const PTag._('PhysicianApprovingInterpretation', 0x40080114,
          'Physician Approving Interpretation', VR.kPN, VM.k1, true);
  static const PTag kInterpretationDiagnosisDescription
      //(4008,0115)
      = const PTag._('InterpretationDiagnosisDescription', 0x40080115,
          'Interpretation Diagnosis Description', VR.kLT, VM.k1, true);
  static const PTag kInterpretationDiagnosisCodeSequence
      //(4008,0117)
      = const PTag._('InterpretationDiagnosisCodeSequence', 0x40080117,
          'Interpretation Diagnosis Code Sequence', VR.kSQ, VM.k1, true);
  static const PTag kResultsDistributionListSequence
      //(4008,0118)
      = const PTag._('ResultsDistributionListSequence', 0x40080118,
          'Results Distribution List Sequence', VR.kSQ, VM.k1, true);
  static const PTag kDistributionName
      //(4008,0119)
      = const PTag._(
          'DistributionName', 0x40080119, 'Distribution Name', VR.kPN, VM.k1, true);
  static const PTag kDistributionAddress
      //(4008,011A)
      = const PTag._(
          'DistributionAddress', 0x4008011A, 'Distribution Address', VR.kLO, VM.k1, true);
  static const PTag kInterpretationID
      //(4008,0200)
      = const PTag._(
          'InterpretationID', 0x40080200, 'Interpretation ID', VR.kSH, VM.k1, true);
  static const PTag kInterpretationIDIssuer
      //(4008,0202)
      = const PTag._('InterpretationIDIssuer', 0x40080202, 'Interpretation ID Issuer',
          VR.kLO, VM.k1, true);
  static const PTag kInterpretationTypeID
      //(4008,0210)
      = const PTag._('InterpretationTypeID', 0x40080210, 'Interpretation Type ID', VR.kCS,
          VM.k1, true);
  static const PTag kInterpretationStatusID
      //(4008,0212)
      = const PTag._('InterpretationStatusID', 0x40080212, 'Interpretation Status ID',
          VR.kCS, VM.k1, true);
  static const PTag kImpressions
      //(4008,0300)
      = const PTag._('Impressions', 0x40080300, 'Impressions', VR.kST, VM.k1, true);
  static const PTag kResultsComments
      //(4008,4000)
      = const PTag._(
          'ResultsComments', 0x40084000, 'Results Comments', VR.kST, VM.k1, true);
  static const PTag kLowEnergyDetectors
      //(4010,0001)
      = const PTag._(
          'LowEnergyDetectors', 0x40100001, 'Low Energy Detectors', VR.kCS, VM.k1, false);
  static const PTag kHighEnergyDetectors
      //(4010,0002)
      = const PTag._('HighEnergyDetectors', 0x40100002, 'High Energy Detectors', VR.kCS,
          VM.k1, false);
  static const PTag kDetectorGeometrySequence
      //(4010,0004)
      = const PTag._('DetectorGeometrySequence', 0x40100004, 'Detector Geometry Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kThreatROIVoxelSequence
      //(4010,1001)
      = const PTag._('ThreatROIVoxelSequence', 0x40101001, 'Threat ROI Voxel Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kThreatROIBase
      //(4010,1004)
      =
      const PTag._('ThreatROIBase', 0x40101004, 'Threat ROI Base', VR.kFL, VM.k3, false);
  static const PTag kThreatROIExtents
      //(4010,1005)
      = const PTag._(
          'ThreatROIExtents', 0x40101005, 'Threat ROI Extents', VR.kFL, VM.k3, false);
  static const PTag kThreatROIBitmap
      //(4010,1006)
      = const PTag._(
          'ThreatROIBitmap', 0x40101006, 'Threat ROI Bitmap', VR.kOB, VM.k1, false);
  static const PTag kRouteSegmentID
      //(4010,1007)
      = const PTag._(
          'RouteSegmentID', 0x40101007, 'Route Segment ID', VR.kSH, VM.k1, false);
  static const PTag kGantryType
      //(4010,1008)
      = const PTag._('GantryType', 0x40101008, 'Gantry Type', VR.kCS, VM.k1, false);
  static const PTag kOOIOwnerType
      //(4010,1009)
      = const PTag._('OOIOwnerType', 0x40101009, 'OOI Owner Type', VR.kCS, VM.k1, false);
  static const PTag kRouteSegmentSequence
      //(4010,100A)
      = const PTag._('RouteSegmentSequence', 0x4010100A, 'Route Segment Sequence', VR.kSQ,
          VM.k1, false);
  static const PTag kPotentialThreatObjectID
      //(4010,1010)
      = const PTag._('PotentialThreatObjectID', 0x40101010, 'Potential Threat Object ID',
          VR.kUS, VM.k1, false);
  static const PTag kThreatSequence
      //(4010,1011)
      =
      const PTag._('ThreatSequence', 0x40101011, 'Threat Sequence', VR.kSQ, VM.k1, false);
  static const PTag kThreatCategory
      //(4010,1012)
      =
      const PTag._('ThreatCategory', 0x40101012, 'Threat Category', VR.kCS, VM.k1, false);
  static const PTag kThreatCategoryDescription
      //(4010,1013)
      = const PTag._('ThreatCategoryDescription', 0x40101013,
          'Threat Category Description', VR.kLT, VM.k1, false);
  static const PTag kATDAbilityAssessment
      //(4010,1014)
      = const PTag._('ATDAbilityAssessment', 0x40101014, 'ATD Ability Assessment', VR.kCS,
          VM.k1, false);
  static const PTag kATDAssessmentFlag
      //(4010,1015)
      = const PTag._(
          'ATDAssessmentFlag', 0x40101015, 'ATD Assessment Flag', VR.kCS, VM.k1, false);
  static const PTag kATDAssessmentProbability
      //(4010,1016)
      = const PTag._('ATDAssessmentProbability', 0x40101016, 'ATD Assessment Probability',
          VR.kFL, VM.k1, false);
  static const PTag kMass
      //(4010,1017)
      = const PTag._('Mass', 0x40101017, 'Mass', VR.kFL, VM.k1, false);
  static const PTag kDensity
      //(4010,1018)
      = const PTag._('Density', 0x40101018, 'Density', VR.kFL, VM.k1, false);
  static const PTag kZEffective
      //(4010,1019)
      = const PTag._('ZEffective', 0x40101019, 'Z Effective', VR.kFL, VM.k1, false);
  static const PTag kBoardingPassID
      //(4010,101A)
      = const PTag._(
          'BoardingPassID', 0x4010101A, 'Boarding Pass ID', VR.kSH, VM.k1, false);
  static const PTag kCenterOfMass
      //(4010,101B)
      = const PTag._('CenterOfMass', 0x4010101B, 'Center of Mass', VR.kFL, VM.k3, false);
  static const PTag kCenterOfPTO
      //(4010,101C)
      = const PTag._('CenterOfPTO', 0x4010101C, 'Center of PTO', VR.kFL, VM.k3, false);
  static const PTag kBoundingPolygon
      //(4010,101D)
      = const PTag._(
          'BoundingPolygon', 0x4010101D, 'Bounding Polygon', VR.kFL, VM.k6_n, false);
  static const PTag kRouteSegmentStartLocationID
      //(4010,101E)
      = const PTag._('RouteSegmentStartLocationID', 0x4010101E,
          'Route Segment Start Location ID', VR.kSH, VM.k1, false);
  static const PTag kRouteSegmentEndLocationID
      //(4010,101F)
      = const PTag._('RouteSegmentEndLocationID', 0x4010101F,
          'Route Segment End Location ID', VR.kSH, VM.k1, false);
  static const PTag kRouteSegmentLocationIDType
      //(4010,1020)
      = const PTag._('RouteSegmentLocationIDType', 0x40101020,
          'Route Segment Location ID Type', VR.kCS, VM.k1, false);
  static const PTag kAbortReason
      //(4010,1021)
      = const PTag._('AbortReason', 0x40101021, 'Abort Reason', VR.kCS, VM.k1_n, false);
  static const PTag kVolumeOfPTO
      //(4010,1023)
      = const PTag._('VolumeOfPTO', 0x40101023, 'Volume of PTO', VR.kFL, VM.k1, false);
  static const PTag kAbortFlag
      //(4010,1024)
      = const PTag._('AbortFlag', 0x40101024, 'Abort Flag', VR.kCS, VM.k1, false);
  static const PTag kRouteSegmentStartTime
      //(4010,1025)
      = const PTag._('RouteSegmentStartTime', 0x40101025, 'Route Segment Start Time',
          VR.kDT, VM.k1, false);
  static const PTag kRouteSegmentEndTime
      //(4010,1026)
      = const PTag._('RouteSegmentEndTime', 0x40101026, 'Route Segment End Time', VR.kDT,
          VM.k1, false);
  static const PTag kTDRType
      //(4010,1027)
      = const PTag._('TDRType', 0x40101027, 'TDR Type', VR.kCS, VM.k1, false);
  static const PTag kInternationalRouteSegment
      //(4010,1028)
      = const PTag._('InternationalRouteSegment', 0x40101028,
          'International Route Segment', VR.kCS, VM.k1, false);
  static const PTag kThreatDetectionAlgorithmandVersion
      //(4010,1029)
      = const PTag._('ThreatDetectionAlgorithmandVersion', 0x40101029,
          'Threat Detection Algorithm and Version', VR.kLO, VM.k1_n, false);
  static const PTag kAssignedLocation
      //(4010,102A)
      = const PTag._(
          'AssignedLocation', 0x4010102A, 'Assigned Location', VR.kSH, VM.k1, false);
  static const PTag kAlarmDecisionTime
      //(4010,102B)
      = const PTag._(
          'AlarmDecisionTime', 0x4010102B, 'Alarm Decision Time', VR.kDT, VM.k1, false);
  static const PTag kAlarmDecision
      //(4010,1031)
      = const PTag._('AlarmDecision', 0x40101031, 'Alarm Decision', VR.kCS, VM.k1, false);
  static const PTag kNumberOfTotalObjects
      //(4010,1033)
      = const PTag._('NumberOfTotalObjects', 0x40101033, 'Number of Total Objects',
          VR.kUS, VM.k1, false);
  static const PTag kNumberOfAlarmObjects
      //(4010,1034)
      = const PTag._('NumberOfAlarmObjects', 0x40101034, 'Number of Alarm Objects',
          VR.kUS, VM.k1, false);
  static const PTag kPTORepresentationSequence
      //(4010,1037)
      = const PTag._('PTORepresentationSequence', 0x40101037,
          'PTO Representation Sequence', VR.kSQ, VM.k1, false);
  static const PTag kATDAssessmentSequence
      //(4010,1038)
      = const PTag._('ATDAssessmentSequence', 0x40101038, 'ATD Assessment Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTIPType
      //(4010,1039)
      = const PTag._('TIPType', 0x40101039, 'TIP Type', VR.kCS, VM.k1, false);
  static const PTag kDICOSVersion
      //(4010,103A)
      = const PTag._('DICOSVersion', 0x4010103A, 'DICOS Version', VR.kCS, VM.k1, false);
  static const PTag kOOIOwnerCreationTime
      //(4010,1041)
      = const PTag._('OOIOwnerCreationTime', 0x40101041, 'OOI Owner Creation Time',
          VR.kDT, VM.k1, false);
  static const PTag kOOIType
      //(4010,1042)
      = const PTag._('OOIType', 0x40101042, 'OOI Type', VR.kCS, VM.k1, false);
  static const PTag kOOISize
      //(4010,1043)
      = const PTag._('OOISize', 0x40101043, 'OOI Size', VR.kFL, VM.k3, false);
  static const PTag kAcquisitionStatus
      //(4010,1044)
      = const PTag._(
          'AcquisitionStatus', 0x40101044, 'Acquisition Status', VR.kCS, VM.k1, false);
  static const PTag kBasisMaterialsCodeSequence
      //(4010,1045)
      = const PTag._('BasisMaterialsCodeSequence', 0x40101045,
          'Basis Materials Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPhantomType
      //(4010,1046)
      = const PTag._('PhantomType', 0x40101046, 'Phantom Type', VR.kCS, VM.k1, false);
  static const PTag kOOIOwnerSequence
      //(4010,1047)
      = const PTag._(
          'OOIOwnerSequence', 0x40101047, 'OOI Owner Sequence', VR.kSQ, VM.k1, false);
  static const PTag kScanType
      //(4010,1048)
      = const PTag._('ScanType', 0x40101048, 'Scan Type', VR.kCS, VM.k1, false);
  static const PTag kItineraryID
      //(4010,1051)
      = const PTag._('ItineraryID', 0x40101051, 'Itinerary ID', VR.kLO, VM.k1, false);
  static const PTag kItineraryIDType
      //(4010,1052)
      = const PTag._(
          'ItineraryIDType', 0x40101052, 'Itinerary ID Type', VR.kSH, VM.k1, false);
  static const PTag kItineraryIDAssigningAuthority
      //(4010,1053)
      = const PTag._('ItineraryIDAssigningAuthority', 0x40101053,
          'Itinerary ID Assigning Authority', VR.kLO, VM.k1, false);
  static const PTag kRouteID
      //(4010,1054)
      = const PTag._('RouteID', 0x40101054, 'Route ID', VR.kSH, VM.k1, false);
  static const PTag kRouteIDAssigningAuthority
      //(4010,1055)
      = const PTag._('RouteIDAssigningAuthority', 0x40101055,
          'Route ID Assigning Authority', VR.kSH, VM.k1, false);
  static const PTag kInboundArrivalType
      //(4010,1056)
      = const PTag._(
          'InboundArrivalType', 0x40101056, 'Inbound Arrival Type', VR.kCS, VM.k1, false);
  static const PTag kCarrierID
      //(4010,1058)
      = const PTag._('CarrierID', 0x40101058, 'Carrier ID', VR.kSH, VM.k1, false);
  static const PTag kCarrierIDAssigningAuthority
      //(4010,1059)
      = const PTag._('CarrierIDAssigningAuthority', 0x40101059,
          'Carrier ID Assigning Authority', VR.kCS, VM.k1, false);
  static const PTag kSourceOrientation
      //(4010,1060)
      = const PTag._(
          'SourceOrientation', 0x40101060, 'Source Orientation', VR.kFL, VM.k3, false);
  static const PTag kSourcePosition
      //(4010,1061)
      =
      const PTag._('SourcePosition', 0x40101061, 'Source Position', VR.kFL, VM.k3, false);
  static const PTag kBeltHeight
      //(4010,1062)
      = const PTag._('BeltHeight', 0x40101062, 'Belt Height', VR.kFL, VM.k1, false);
  static const PTag kAlgorithmRoutingCodeSequence
      //(4010,1064)
      = const PTag._('AlgorithmRoutingCodeSequence', 0x40101064,
          'Algorithm Routing Code Sequence', VR.kSQ, VM.k1, false);
  static const PTag kTransportClassification
      //(4010,1067)
      = const PTag._('TransportClassification', 0x40101067, 'Transport Classification',
          VR.kCS, VM.k1, false);
  static const PTag kOOITypeDescriptor
      //(4010,1068)
      = const PTag._(
          'OOITypeDescriptor', 0x40101068, 'OOI Type Descriptor', VR.kLT, VM.k1, false);
  static const PTag kTotalProcessingTime
      //(4010,1069)
      = const PTag._('TotalProcessingTime', 0x40101069, 'Total Processing Time', VR.kFL,
          VM.k1, false);
  static const PTag kDetectorCalibrationData
      //(4010,106C)
      = const PTag._('DetectorCalibrationData', 0x4010106C, 'Detector Calibration Data',
          VR.kOB, VM.k1, false);
  static const PTag kAdditionalScreeningPerformed
      //(4010,106D)
      = const PTag._('AdditionalScreeningPerformed', 0x4010106D,
          'Additional Screening Performed', VR.kCS, VM.k1, false);
  static const PTag kAdditionalInspectionSelectionCriteria
      //(4010,106E)
      = const PTag._('AdditionalInspectionSelectionCriteria', 0x4010106E,
          'Additional Inspection Selection Criteria', VR.kCS, VM.k1, false);
  static const PTag kAdditionalInspectionMethodSequence
      //(4010,106F)
      = const PTag._('AdditionalInspectionMethodSequence', 0x4010106F,
          'Additional Inspection Method Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAITDeviceType
      //(4010,1070)
      =
      const PTag._('AITDeviceType', 0x40101070, 'AIT Device Type', VR.kCS, VM.k1, false);
  static const PTag kQRMeasurementsSequence
      //(4010,1071)
      = const PTag._('QRMeasurementsSequence', 0x40101071, 'QR Measurements Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kTargetMaterialSequence
      //(4010,1072)
      = const PTag._('TargetMaterialSequence', 0x40101072, 'Target Material Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kSNRThreshold
      //(4010,1073)
      = const PTag._('SNRThreshold', 0x40101073, 'SNR Threshold', VR.kFD, VM.k1, false);
  static const PTag kImageScaleRepresentation
      //(4010,1075)
      = const PTag._('ImageScaleRepresentation', 0x40101075, 'Image Scale Representation',
          VR.kDS, VM.k1, false);
  static const PTag kReferencedPTOSequence
      //(4010,1076)
      = const PTag._('ReferencedPTOSequence', 0x40101076, 'Referenced PTO Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kReferencedTDRInstanceSequence
      //(4010,1077)
      = const PTag._('ReferencedTDRInstanceSequence', 0x40101077,
          'Referenced TDR Instance Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPTOLocationDescription
      //(4010,1078)
      = const PTag._('PTOLocationDescription', 0x40101078, 'PTO Location Description',
          VR.kST, VM.k1, false);
  static const PTag kAnomalyLocatorIndicatorSequence
      //(4010,1079)
      = const PTag._('AnomalyLocatorIndicatorSequence', 0x40101079,
          'Anomaly Locator Indicator Sequence', VR.kSQ, VM.k1, false);
  static const PTag kAnomalyLocatorIndicator
      //(4010,107A)
      = const PTag._('AnomalyLocatorIndicator', 0x4010107A, 'Anomaly Locator Indicator',
          VR.kFL, VM.k3, false);
  static const PTag kPTORegionSequence
      //(4010,107B)
      = const PTag._(
          'PTORegionSequence', 0x4010107B, 'PTO Region Sequence', VR.kSQ, VM.k1, false);
  static const PTag kInspectionSelectionCriteria
      //(4010,107C)
      = const PTag._('InspectionSelectionCriteria', 0x4010107C,
          'Inspection Selection Criteria', VR.kCS, VM.k1, false);
  static const PTag kSecondaryInspectionMethodSequence
      //(4010,107D)
      = const PTag._('SecondaryInspectionMethodSequence', 0x4010107D,
          'Secondary Inspection Method Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPRCSToRCSOrientation
      //(4010,107E)
      = const PTag._('PRCSToRCSOrientation', 0x4010107E, 'PRCS to RCS Orientation',
          VR.kDS, VM.k6, false);
  static const PTag kMACParametersSequence
      //(4FFE,0001)
      = const PTag._('MACParametersSequence', 0x4FFE0001, 'MAC Parameters Sequence',
          VR.kSQ, VM.k1, false);
  static const PTag kCurveDimensions
      //(5000,0005)
      = const PTag._(
          'CurveDimensions', 0x50000005, 'Curve Dimensions', VR.kUS, VM.k1, true);
  static const PTag kNumberOfPoints
      //(5000,0010)
      =
      const PTag._('NumberOfPoints', 0x50000010, 'Number of Points', VR.kUS, VM.k1, true);
  static const PTag kTypeOfData
      //(5000,0020)
      = const PTag._('TypeOfData', 0x50000020, 'Type of Data', VR.kCS, VM.k1, true);
  static const PTag kCurveDescription
      //(5000,0022)
      = const PTag._(
          'CurveDescription', 0x50000022, 'Curve Description', VR.kLO, VM.k1, true);
  static const PTag kAxisUnits
      //(5000,0030)
      = const PTag._('AxisUnits', 0x50000030, 'Axis Units', VR.kSH, VM.k1_n, true);
  static const PTag kAxisLabels
      //(5000,0040)
      = const PTag._('AxisLabels', 0x50000040, 'Axis Labels', VR.kSH, VM.k1_n, true);
  static const PTag kDataValueRepresentation
      //(5000,0103)
      = const PTag._('DataValueRepresentation', 0x50000103, 'Data Value Representation',
          VR.kUS, VM.k1, true);
  static const PTag kMinimumCoordinateValue
      //(5000,0104)
      = const PTag._('MinimumCoordinateValue', 0x50000104, 'Minimum Coordinate Value',
          VR.kUS, VM.k1_n, true);
  static const PTag kMaximumCoordinateValue
      //(5000,0105)
      = const PTag._('MaximumCoordinateValue', 0x50000105, 'Maximum Coordinate Value',
          VR.kUS, VM.k1_n, true);
  static const PTag kCurveRange
      //(5000,0106)
      = const PTag._('CurveRange', 0x50000106, 'Curve Range', VR.kSH, VM.k1_n, true);
  static const PTag kCurveDataDescriptor
      //(5000,0110)
      = const PTag._('CurveDataDescriptor', 0x50000110, 'Curve Data Descriptor', VR.kUS,
          VM.k1_n, true);
  static const PTag kCoordinateStartValue
      //(5000,0112)
      = const PTag._('CoordinateStartValue', 0x50000112, 'Coordinate Start Value', VR.kUS,
          VM.k1_n, true);
  static const PTag kCoordinateStepValue
      //(5000,0114)
      = const PTag._('CoordinateStepValue', 0x50000114, 'Coordinate Step Value', VR.kUS,
          VM.k1_n, true);
  static const PTag kCurveActivationLayer
      //(5000,1001)
      = const PTag._('CurveActivationLayer', 0x50001001, 'Curve Activation Layer', VR.kCS,
          VM.k1, true);
  static const PTag kAudioType
      //(5000,2000)
      = const PTag._('AudioType', 0x50002000, 'Audio Type', VR.kUS, VM.k1, true);
  static const PTag kAudioSampleFormat
      //(5000,2002)
      = const PTag._(
          'AudioSampleFormat', 0x50002002, 'Audio Sample Format', VR.kUS, VM.k1, true);
  static const PTag kNumberOfChannels
      //(5000,2004)
      = const PTag._(
          'NumberOfChannels', 0x50002004, 'Number of Channels', VR.kUS, VM.k1, true);
  static const PTag kNumberOfSamples
      //(5000,2006)
      = const PTag._(
          'NumberOfSamples', 0x50002006, 'Number of Samples', VR.kUL, VM.k1, true);
  static const PTag kSampleRate
      //(5000,2008)
      = const PTag._('SampleRate', 0x50002008, 'Sample Rate', VR.kUL, VM.k1, true);
  static const PTag kTotalTime
      //(5000,200A)
      = const PTag._('TotalTime', 0x5000200A, 'Total Time', VR.kUL, VM.k1, true);
  static const PTag kAudioSampleData
      //(5000,200C)
      = const PTag._(
          'AudioSampleData', 0x5000200C, 'Audio Sample Data', VR.kOBOW, VM.k1, true);
  static const PTag kAudioComments
      //(5000,200E)
      = const PTag._('AudioComments', 0x5000200E, 'Audio Comments', VR.kLT, VM.k1, true);
  static const PTag kCurveLabel
      //(5000,2500)
      = const PTag._('CurveLabel', 0x50002500, 'Curve Label', VR.kLO, VM.k1, true);
  static const PTag kCurveReferencedOverlaySequence
      //(5000,2600)
      = const PTag._('CurveReferencedOverlaySequence', 0x50002600,
          'Curve Referenced Overlay Sequence', VR.kSQ, VM.k1, true);
  static const PTag kCurveReferencedOverlayGroup
      //(5000,2610)
      = const PTag._('CurveReferencedOverlayGroup', 0x50002610,
          'Curve Referenced Overlay Group', VR.kUS, VM.k1, true);
  static const PTag kCurveData
      //(5000,3000)
      = const PTag._('CurveData', 0x50003000, 'Curve Data', VR.kOBOW, VM.k1, true);
  static const PTag kSharedFunctionalGroupsSequence
      //(5200,9229)
      = const PTag._('SharedFunctionalGroupsSequence', 0x52009229,
          'Shared Functional Groups Sequence', VR.kSQ, VM.k1, false);
  static const PTag kPerFrameFunctionalGroupsSequence
      //(5200,9230)
      = const PTag._('PerFrameFunctionalGroupsSequence', 0x52009230,
          'Per-frame Functional Groups Sequence', VR.kSQ, VM.k1, false);
  static const PTag kWaveformSequence
      //(5400,0100)
      = const PTag._(
          'WaveformSequence', 0x54000100, 'Waveform Sequence', VR.kSQ, VM.k1, false);
  static const PTag kChannelMinimumValue
      //(5400,0110)
      = const PTag._('ChannelMinimumValue', 0x54000110, 'Channel Minimum Value', VR.kOBOW,
          VM.k1, false);
  static const PTag kChannelMaximumValue
      //(5400,0112)
      = const PTag._('ChannelMaximumValue', 0x54000112, 'Channel Maximum Value', VR.kOBOW,
          VM.k1, false);
  static const PTag kWaveformBitsAllocated
      //(5400,1004)
      = const PTag._('WaveformBitsAllocated', 0x54001004, 'Waveform Bits Allocated',
          VR.kUS, VM.k1, false);
  static const PTag kWaveformSampleInterpretation
      //(5400,1006)
      = const PTag._('WaveformSampleInterpretation', 0x54001006,
          'Waveform Sample Interpretation', VR.kCS, VM.k1, false);
  static const PTag kWaveformPaddingValue
      //(5400,100A)
      = const PTag._('WaveformPaddingValue', 0x5400100A, 'Waveform Padding Value',
          VR.kOBOW, VM.k1, false);
  static const PTag kWaveformData
      //(5400,1010)
      = const PTag._('WaveformData', 0x54001010, 'Waveform Data', VR.kOBOW, VM.k1, false);
  static const PTag kFirstOrderPhaseCorrectionAngle
      //(5600,0010)
      = const PTag._('FirstOrderPhaseCorrectionAngle', 0x56000010,
          'First Order Phase Correction Angle', VR.kOF, VM.k1, false);
  static const PTag kSpectroscopyData
      //(5600,0020)
      = const PTag._(
          'SpectroscopyData', 0x56000020, 'Spectroscopy Data', VR.kOF, VM.k1, false);
  static const PTag kOverlayRows
      //(6000,0010)
      = const PTag._('OverlayRows', 0x60000010, 'Overlay Rows', VR.kUS, VM.k1, false);
  static const PTag kOverlayColumns
      //(6000,0011)
      =
      const PTag._('OverlayColumns', 0x60000011, 'Overlay Columns', VR.kUS, VM.k1, false);
  static const PTag kOverlayPlanes
      //(6000,0012)
      = const PTag._('OverlayPlanes', 0x60000012, 'Overlay Planes', VR.kUS, VM.k1, true);
  static const PTag kNumberOfFramesInOverlay
      //(6000,0015)
      = const PTag._('NumberOfFramesInOverlay', 0x60000015, 'Number of Frames in Overlay',
          VR.kIS, VM.k1, false);
  static const PTag kOverlayDescription
      //(6000,0022)
      = const PTag._(
          'OverlayDescription', 0x60000022, 'Overlay Description', VR.kLO, VM.k1, false);
  static const PTag kOverlayType
      //(6000,0040)
      = const PTag._('OverlayType', 0x60000040, 'Overlay Type', VR.kCS, VM.k1, false);
  static const PTag kOverlaySubtype
      //(6000,0045)
      =
      const PTag._('OverlaySubtype', 0x60000045, 'Overlay Subtype', VR.kLO, VM.k1, false);
  static const PTag kOverlayOrigin
      //(6000,0050)
      = const PTag._('OverlayOrigin', 0x60000050, 'Overlay Origin', VR.kSS, VM.k2, false);
  static const PTag kImageFrameOrigin
      //(6000,0051)
      = const PTag._(
          'ImageFrameOrigin', 0x60000051, 'Image Frame Origin', VR.kUS, VM.k1, false);
  static const PTag kOverlayPlaneOrigin
      //(6000,0052)
      = const PTag._(
          'OverlayPlaneOrigin', 0x60000052, 'Overlay Plane Origin', VR.kUS, VM.k1, true);
  static const PTag kOverlayCompressionCode
      //(6000,0060)
      = const PTag._('OverlayCompressionCode', 0x60000060, 'Overlay Compression Code',
          VR.kCS, VM.k1, true);
  static const PTag kOverlayCompressionOriginator
      //(6000,0061)
      = const PTag._('OverlayCompressionOriginator', 0x60000061,
          'Overlay Compression Originator', VR.kSH, VM.k1, true);
  static const PTag kOverlayCompressionLabel
      //(6000,0062)
      = const PTag._('OverlayCompressionLabel', 0x60000062, 'Overlay Compression Label',
          VR.kSH, VM.k1, true);
  static const PTag kOverlayCompressionDescription
      //(6000,0063)
      = const PTag._('OverlayCompressionDescription', 0x60000063,
          'Overlay Compression Description', VR.kCS, VM.k1, true);
  static const PTag kOverlayCompressionStepPointers
      //(6000,0066)
      = const PTag._('OverlayCompressionStepPointers', 0x60000066,
          'Overlay Compression Step Pointers', VR.kAT, VM.k1_n, true);
  static const PTag kOverlayRepeatInterval
      //(6000,0068)
      = const PTag._('OverlayRepeatInterval', 0x60000068, 'Overlay Repeat Interval',
          VR.kUS, VM.k1, true);
  static const PTag kOverlayBitsGrouped
      //(6000,0069)
      = const PTag._(
          'OverlayBitsGrouped', 0x60000069, 'Overlay Bits Grouped', VR.kUS, VM.k1, true);
  static const PTag kOverlayBitsAllocated
      //(6000,0100)
      = const PTag._('OverlayBitsAllocated', 0x60000100, 'Overlay Bits Allocated', VR.kUS,
          VM.k1, false);
  static const PTag kOverlayBitPosition
      //(6000,0102)
      = const PTag._(
          'OverlayBitPosition', 0x60000102, 'Overlay Bit Position', VR.kUS, VM.k1, false);
  static const PTag kOverlayFormat
      //(6000,0110)
      = const PTag._('OverlayFormat', 0x60000110, 'Overlay Format', VR.kCS, VM.k1, true);
  static const PTag kOverlayLocation
      //(6000,0200)
      = const PTag._(
          'OverlayLocation', 0x60000200, 'Overlay Location', VR.kUS, VM.k1, true);
  static const PTag kOverlayCodeLabel
      //(6000,0800)
      = const PTag._(
          'OverlayCodeLabel', 0x60000800, 'Overlay Code Label', VR.kCS, VM.k1_n, true);
  static const PTag kOverlayNumberOfTables
      //(6000,0802)
      = const PTag._('OverlayNumberOfTables', 0x60000802, 'Overlay Number of Tables',
          VR.kUS, VM.k1, true);
  static const PTag kOverlayCodeTableLocation
      //(6000,0803)
      = const PTag._('OverlayCodeTableLocation', 0x60000803,
          'Overlay Code Table Location', VR.kAT, VM.k1_n, true);
  static const PTag kOverlayBitsForCodeWord
      //(6000,0804)
      = const PTag._('OverlayBitsForCodeWord', 0x60000804, 'Overlay Bits For Code Word',
          VR.kUS, VM.k1, true);
  static const PTag kOverlayActivationLayer
      //(6000,1001)
      = const PTag._('OverlayActivationLayer', 0x60001001, 'Overlay Activation Layer',
          VR.kCS, VM.k1, false);
  static const PTag kOverlayDescriptorGray
      //(6000,1100)
      = const PTag._('OverlayDescriptorGray', 0x60001100, 'Overlay Descriptor - Gray',
          VR.kUS, VM.k1, true);
  static const PTag kOverlayDescriptorRed
      //(6000,1101)
      = const PTag._('OverlayDescriptorRed', 0x60001101, 'Overlay Descriptor - Red',
          VR.kUS, VM.k1, true);
  static const PTag kOverlayDescriptorGreen
      //(6000,1102)
      = const PTag._('OverlayDescriptorGreen', 0x60001102, 'Overlay Descriptor - Green',
          VR.kUS, VM.k1, true);
  static const PTag kOverlayDescriptorBlue
      //(6000,1103)
      = const PTag._('OverlayDescriptorBlue', 0x60001103, 'Overlay Descriptor - Blue',
          VR.kUS, VM.k1, true);
  static const PTag kOverlaysGray
      //(6000,1200)
      =
      const PTag._('OverlaysGray', 0x60001200, 'Overlays - Gray', VR.kUS, VM.k1_n, true);
  static const PTag kOverlaysRed
      //(6000,1201)
      = const PTag._('OverlaysRed', 0x60001201, 'Overlays - Red', VR.kUS, VM.k1_n, true);
  static const PTag kOverlaysGreen
      //(6000,1202)
      = const PTag._(
          'OverlaysGreen', 0x60001202, 'Overlays - Green', VR.kUS, VM.k1_n, true);
  static const PTag kOverlaysBlue
      //(6000,1203)
      =
      const PTag._('OverlaysBlue', 0x60001203, 'Overlays - Blue', VR.kUS, VM.k1_n, true);
  static const PTag kROIArea
      //(6000,1301)
      = const PTag._('ROIArea', 0x60001301, 'ROI Area', VR.kIS, VM.k1, false);
  static const PTag kROIMean
      //(6000,1302)
      = const PTag._('ROIMean', 0x60001302, 'ROI Mean', VR.kDS, VM.k1, false);
  static const PTag kROIStandardDeviation
      //(6000,1303)
      = const PTag._('ROIStandardDeviation', 0x60001303, 'ROI Standard Deviation', VR.kDS,
          VM.k1, false);
  static const PTag kOverlayLabel
      //(6000,1500)
      = const PTag._('OverlayLabel', 0x60001500, 'Overlay Label', VR.kLO, VM.k1, false);
  static const PTag kOverlayData
      //(6000,3000)
      = const PTag._('OverlayData', 0x60003000, 'Overlay Data', VR.kOBOW, VM.k1, false);
  static const PTag kOverlayComments
      //(6000,4000)
      = const PTag._(
          'OverlayComments', 0x60004000, 'Overlay Comments', VR.kLT, VM.k1, true);
  static const PTag kFloatPixelData = const PTag._(
      'FloatPixelData', 0x7FE00008, 'Float Pixel Data', VR.kOF, VM.k1, false);

  static const PTag kDoubleFloatPixelData = const PTag._('DoubleFloatPixelData',
      0x7FE00009, 'Double Float Pixel Data', VR.kOD, VM.k1, false);

  static const PTag kPixelData =
      const PTag._('PixelData', 0x7FE00010, 'Pixel Data', VR.kOBOW, VM.k1, false);

/*
  static const PTag kPixelDataOB =
      const PTag._('PixelData', 0x7FE00010, 'Pixel Data', VR.kOB, VM.k1, false);

  static const PTag kPixelDataOW =
      const PTag._('PixelData', 0x7FE00010, 'Pixel Data', VR.kOW, VM.k1, false);

  static const PTag kPixelDataUN =
      const PTag._('PixelData', 0x7FE00010, 'Pixel Data', VR.kOBOW, VM.k1, false);
*/

  static const PTag kCoefficientsSDVN
      //(7FE0,0020)
      = const PTag._(
          'CoefficientsSDVN', 0x7FE00020, 'Coefficients SDVN', VR.kOW, VM.k1, true);
  static const PTag kCoefficientsSDHN
      //(7FE0,0030)
      = const PTag._(
          'CoefficientsSDHN', 0x7FE00030, 'Coefficients SDHN', VR.kOW, VM.k1, true);
  static const PTag kCoefficientsSDDN
      //(7FE0,0040)
      = const PTag._(
          'CoefficientsSDDN', 0x7FE00040, 'Coefficients SDDN', VR.kOW, VM.k1, true);
  static const PTag kVariablePixelData
      //(7F00,0010)
      = const PTag._(
          'VariablePixelData', 0x7F000010, 'Variable Pixel Data', VR.kOBOW, VM.k1, true);
  static const PTag kVariableNextDataGroup
      //(7F00,0011)
      = const PTag._('VariableNextDataGroup', 0x7F000011, 'Variable Next Data Group',
          VR.kUS, VM.k1, true);
  static const PTag kVariableCoefficientsSDVN
      //(7F00,0020)
      = const PTag._('VariableCoefficientsSDVN', 0x7F000020, 'Variable Coefficients SDVN',
          VR.kOW, VM.k1, true);
  static const PTag kVariableCoefficientsSDHN
      //(7F00,0030)
      = const PTag._('VariableCoefficientsSDHN', 0x7F000030, 'Variable Coefficients SDHN',
          VR.kOW, VM.k1, true);
  static const PTag kVariableCoefficientsSDDN
      //(7F00,0040)
      = const PTag._('VariableCoefficientsSDDN', 0x7F000040, 'Variable Coefficients SDDN',
          VR.kOW, VM.k1, true);
  static const PTag kDigitalSignaturesSequence
      //(FFFA,FFFA)
      = const PTag._('DigitalSignaturesSequence', 0xFFFAFFFA,
          'Digital Signatures Sequence', VR.kSQ, VM.k1, false);
  static const PTag kDataSetTrailingPadding
      //(FFFC,FFFC)
      = const PTag._('DataSetTrailingPadding', 0xFFFCFFFC, 'Data Set Trailing Padding',
          VR.kOB, VM.k1, false);

  //**** Special Elements where multiple tag codes map to the same definition

  //(0028,04X0)
  static const PTag kRowsForNthOrderCoefficients = const PTag._(
      'RowsForNthOrderCoefficients',
      0x002804F0,
      'Rows For Nth Order Coefficients',
      VR.kUS,
      VM.k1,
      true);

  //(0028,04X1)
  static const PTag kColumnsForNthOrderCoefficients = const PTag._(
      'ColumnsForNthOrderCoefficients',
      0x00280401,
      'Columns For Nth Order Coefficients',
      VR.kUS,
      VM.k1,
      true);

  //(0028,0402)
  static const PTag kCoefficientCoding = const PTag._(
      'CoefficientCoding', 0x00280402, 'Coefficient Coding', VR.kLO, VM.k1_n, true);

  //(0028,0403)
  static const PTag kCoefficientCodingPointers = const PTag._('CoefficientCodingPointers',
      0x00280403, 'Coefficient Coding Pointers', VR.kAT, VM.k1_n, true);

  //**** DcmDir Group Length Tags - Note: these are not included in PS3.6 ****
  static const PTag kGroup4Length =
      const PTag._('Group4Length', 0x00040000, 'Group 0004 Length', VR.kUL, VM.k1, true);

  //**** Public Group Length Tags - Note: these are not included in PS3.6 ****
  static const PTag kGroup8Length =
      const PTag._('Group8Length', 0x00080000, 'Group 0008 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup10Length =
      const PTag._('Group10Length', 0x00100000, 'Group 0010 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup12Length =
      const PTag._('Group12Length', 0x00120000, 'Group 0012 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup14Length = const PTag._(
      'Group14Length', 0x000140000, 'Group 00014 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup18Length =
      const PTag._('Group18Length', 0x00180000, 'Group 0018 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup20Length =
      const PTag._('Group20Length', 0x00200000, 'Group 0020 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup22Length =
      const PTag._('Group22Length', 0x00220000, 'Group 0022 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup24Length =
      const PTag._('Group24Length', 0x00240000, 'Group 0024 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup28Length =
      const PTag._('Group28Length', 0x00280000, 'Group 0028 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup32Length =
      const PTag._('Group32Length', 0x00320000, 'Group 0032 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup38Length =
      const PTag._('Group38Length', 0x00380000, 'Group 0038 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup3aLength =
      const PTag._('Group3aLength', 0x003a0000, 'Group 003a Length', VR.kUL, VM.k1, true);

  static const PTag kGroup40Length =
      const PTag._('Group40Length', 0x00400000, 'Group 0040 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup42Length =
      const PTag._('Group42Length', 0x00420000, 'Group 0042 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup44Length =
      const PTag._('Group44Length', 0x00440000, 'Group 0044 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup46Length =
      const PTag._('Group46Length', 0x00460000, 'Group 0046 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup48Length =
      const PTag._('Group48Length', 0x00480000, 'Group 0048 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup50Length =
      const PTag._('Group50Length', 0x00500000, 'Group 0050 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup52Length =
      const PTag._('Group52Length', 0x00520000, 'Group 0052 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup54Length =
      const PTag._('Group54Length', 0x00540000, 'Group 0054 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup60Length =
      const PTag._('Group60Length', 0x00600000, 'Group 0060 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup62Length =
      const PTag._('Group62Length', 0x00620000, 'Group 0062 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup64Length =
      const PTag._('Group64Length', 0x00640000, 'Group 0064 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup66Length =
      const PTag._('Group66Length', 0x00660000, 'Group 0066 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup68Length =
      const PTag._('Group68Length', 0x00680000, 'Group 0068 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup70Length =
      const PTag._('Group70Length', 0x00700000, 'Group 0070 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup72Length =
      const PTag._('Group72Length', 0x00720000, 'Group 0072 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup74Length =
      const PTag._('Group74Length', 0x00740000, 'Group 0074 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup76Length =
      const PTag._('Group76Length', 0x00760000, 'Group 0076 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup78Length =
      const PTag._('Group78Length', 0x00780000, 'Group 0078 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup80Length =
      const PTag._('Group80Length', 0x00800000, 'Group 0080 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup88Length =
      const PTag._('Group88Length', 0x00880000, 'Group 0088 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup100Length = const PTag._(
      'Group100Length', 0x01000000, 'Group 0100 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup400Length = const PTag._(
      'Group400Length', 0x04000000, 'Group 0400 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2000Length = const PTag._(
      'Group2000Length', 0x20000000, 'Group 2000 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2010Length = const PTag._(
      'Group2010Length', 0x20010000, 'Group 2010 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2020Length = const PTag._(
      'Group2020Length', 0x20200000, 'Group 2020 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2030Length = const PTag._(
      'Group2030Length', 0x20300000, 'Group 2030 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2040Length = const PTag._(
      'Group2040Length', 0x20400000, 'Group 2040 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2050Length = const PTag._(
      'Group2050Length', 0x20500000, 'Group 2050 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2100Length = const PTag._(
      'Group2100Length', 0x21000000, 'Group 2100 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2110Length = const PTag._(
      'Group2110Length', 0x21100000, 'Group 2110 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2120Length = const PTag._(
      'Group2120Length', 0x21200000, 'Group 2120 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2130Length = const PTag._(
      'Group2130Length', 0x21300000, 'Group 2130 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup2200Length = const PTag._(
      'Group2200Length', 0x22000000, 'Group 2200 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup3002Length = const PTag._(
      'Group3002Length', 0x30020000, 'Group 3002 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup3004Length = const PTag._(
      'Group3004Length', 0x30040000, 'Group 3004 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup3006Length = const PTag._(
      'Group3006Length', 0x30060000, 'Group 3006 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup3008Length = const PTag._(
      'Group3008Length', 0x30080000, 'Group 3008 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup300aLength = const PTag._(
      'Group300aLength', 0x300a0000, 'Group 300a Length', VR.kUL, VM.k1, true);

  static const PTag kGroup300cLength = const PTag._(
      'Group300cLength', 0x300c0000, 'Group 300c Length', VR.kUL, VM.k1, true);

  static const PTag kGroup300eLength = const PTag._(
      'Group300eLength', 0x300e0000, 'Group 300e Length', VR.kUL, VM.k1, true);

  static const PTag kGroup4000Length = const PTag._(
      'Group4000Length', 0x40000000, 'Group 4000 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup4008Length = const PTag._(
      'Group4008Length', 0x40080000, 'Group 4008 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup4010Length = const PTag._(
      'Group4010Length', 0x40100000, 'Group 4010 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup4ffeLength = const PTag._(
      'Group4ffeLength', 0x4ffe0000, 'Group 4ffe Length', VR.kUL, VM.k1, true);

  static const PTag kGroup5000Length = const PTag._(
      'Group5000Length', 0x50000000, 'Group 5000 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup5200Length = const PTag._(
      'Group5200Length', 0x52000000, 'Group 5200 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup5400Length = const PTag._(
      'Group5400Length', 0x54000000, 'Group 5400 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup5600Length = const PTag._(
      'Group5600Length', 0x56000000, 'Group 5600 Length', VR.kUL, VM.k1, true);

  static const PTag kGroup6000Length = const PTag._(
      'Group6000Length', 0x60000000, 'Group 6000 Length', VR.kUL, VM.k1, true);

  static const List<PTag> fmiTags = const <PTag>[
    kFileMetaInformationGroupLength,
    kFileMetaInformationVersion,
    kMediaStorageSOPClassUID,
    kMediaStorageSOPInstanceUID,
    kTransferSyntaxUID,
    kImplementationClassUID,
    kImplementationVersionName,
    kSourceApplicationEntityTitle,
    kSendingApplicationEntityTitle,
    kReceivingApplicationEntityTitle,
    kPrivateInformationCreatorUID,
    kPrivateInformation
  ];

//TODO: Move 0x002831xx elements down to here and change name
//TODO: Move 0x002804xY elements down to here and change name
//TODO: Move 0x002808xY elements down to here and change name
//TODO: Move 0x1000xxxY elements down to here and change name
//TODO: Move 0x50xx,yyyy elements down to here and change name
//TODO: Move 0x60xx,yyyy elements down to here and change name
//TODO: Move 0x7Fxx,yyyy elements down to here and change name

}

class PTagGroupLength extends PTag {
  // Note: While Group Length tags are retired (See PS3.5 Section 7), they are
  // still present in some DICOM objects.  This tag is used to handle all
  // Group Length Tags
  PTagGroupLength(int code)
      : super._('kPublicGroupLength${hex(code)}', code,
            'Public Group Length for ${Tag.toDcm(code)}', VR.kUL, VM.k1, true, EType.k3);

  PTagGroupLength.keyword(String keyword)
      : super._('kPublicGroupLength$keyword', int.parse(keyword),
            'Public Group Length for $keyword', VR.kUL, VM.k1, true, EType.k3);

/*
  static Tag maker(int code, VR _, [__]) => new PTagGroupLength(code);
*/

}

//Flush not used
class PTagUnknown extends PTag {
  // Note: While Group Length tags are retired (See PS3.5 Section 7), they are
  // still present in some DICOM objects.  This tag is used to handle all
  // Group Length Tags
  PTagUnknown(int code, VR vr)
      : super._('kUnknownPublicTag_${hex16(Group.fromTag(code))}', code,
            'Unknown DICOM Tag ${Tag.toDcm(code)}', vr, VM.k1_n, false, EType.k3);

  PTagUnknown.keyword(String keyword, VR vr)
      : super._('kUnknownPublicKeyword_$keyword', int.parse(keyword),
            'Unknown DICOM Tag $keyword', vr, VM.k1_n, false, EType.k3);

  @override
  bool get isKnown => false;
}

/// A [Tag] with a known key, but invalid [VR].
class PTagInvalidVR extends Tag {
  PTag tag;
  @override
  VR badVR;
  PTagInvalidVR(this.tag, VR badVR) : super();

  @override
  int get code => tag.code;
  @override
  int get index => tag.index;
  @override
  VR get vr => tag.vr;

  @override
  bool get isKnown => false;

  @override
  String toString() => '*Invalid VR($badVR)* $tag';
}
