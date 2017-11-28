// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:vr/vr.dart';

import 'package:tag/src/vm.dart';

//TODO: add these to DED and then create a Map from this file.
class DcmDir {
  final String keyword;
  final int code;
  final String name;
  final VR vr;
  final VM vm;
  final bool isRetired;

  const DcmDir(
      this.keyword, this.code, this.name, this.vr, this.vm, {this.isRetired});

  static const DcmDir kFileSetID = const DcmDir(
      'FileSetID', 0x00041130, 'File-set ID', VR.kCS, VM.k1, isRetired: false);

  static const DcmDir kFileSetDescriptorFileID = const DcmDir(
      'FileSetDescriptorFileID',
      0x00041130,
      'File-set Descriptor File ID',
      VR.kCS,
      VM.k1_8,
      isRetired: false);

  static const DcmDir kSpecificCharacterSetOfFileSetDescriptorFile =
      const DcmDir(
          'SpecificCharacterSetOfFileSetDescriptorFile',
          0x00041142,
          'Specific Character Set of File Set Descriptor File',
          VR.kCS,
          VM.k1,
          isRetired: false);

  static const DcmDir kOffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity =
      const DcmDir(
          'OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity',
          0x00041200,
          'SOffset of the First Directory Record of the Root Directory Entity',
          VR.kUL,
          VM.k1,
          isRetired: false);

  static const DcmDir kOffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity =
      const DcmDir(
          'OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity',
          0x00041202,
          'Offset of the Last Directory Record of the Root Directory Entity',
          VR.kUL,
          VM.k1,
          isRetired: false);

  static const DcmDir kFileSetConsistencyFlag = const DcmDir(
      'FileSetConsistencyFlag',
      0x00041212,
      'File-set Consistency Flag',
      VR.kUS,
      VM.k1,
      isRetired: false);

  static const DcmDir kDirectoryRecordSequence = const DcmDir(
      'DirectoryRecordSequence',
      0x00041220,
      'Directory Record Sequence',
      VR.kSQ,
      VM.k1,
      isRetired: false);

  static const DcmDir kOffsetOfTheNextDirectoryRecord = const DcmDir(
      'OffsetOfTheNextDirectoryRecord',
      0x00041400,
      'Offset of the Next Directory Record',
      VR.kUL,
      VM.k1,
      isRetired: false);

  static const DcmDir kRecordInUseFlag = const DcmDir('RecordInUseFlag',
      0x00041410, 'Record In-use Flag', VR.kUS, VM.k1, isRetired: false);

  static const DcmDir kOffsetOfReferencedLowerLevelDirectoryEntity =
      const DcmDir(
          'OffsetOfReferencedLowerLevelDirectoryEntity',
          0x00041420,
          'Offset of Referenced Lower-Level Directory Entity',
          VR.kUL,
          VM.k1,
          isRetired: false);

  static const DcmDir kDirectoryRecordType = const DcmDir('DirectoryRecordType',
      0x00041430, 'Directory​Record​Type', VR.kCS, VM.k1, isRetired: false);

  static const DcmDir kPrivateRecordUID = const DcmDir(
      'PrivateRecordUID', 0x0004, 'Private Record UID', VR.kUI, VM.k1, isRetired: false);

  static const DcmDir kReferencedFileID = const DcmDir('ReferencedFileID',
      0x00041500, 'Referenced File ID', VR.kCS, VM.k1_8, isRetired: false);

  static const DcmDir kMRDRDirectoryRecordOffset = const DcmDir(
      'MRDRDirectoryRecordOffset',
      0x0004,
      'MRDR Directory Record Offset',
      VR.kUL,
      VM.k1,
      isRetired: true);

  static const DcmDir kReferencedSOPClassUIDInFile = const DcmDir(
      'ReferencedSOPClassUIDInFile',
      0x00041510,
      'Referenced SOP Class UID in File',
      VR.kUI,
      VM.k1,
      isRetired: false);

  static const DcmDir kReferencedSOPInstanceUIDInFile = const DcmDir(
      'ReferencedSOPInstanceUIDInFile',
      0x00041511,
      'Referenced SOP Instance UID in File',
      VR.kUI,
      VM.k1,
      isRetired: false);

  static const DcmDir kReferencedTransferSyntaxUIDInFile = const DcmDir(
      'ReferencedTransferSyntaxUIDInFile',
      0x00041512,
      'Referenced Transfer Syntax UID in File',
      VR.kUI,
      VM.k1,
      isRetired: false);

  static const DcmDir kReferencedRelatedGeneralSOPClassUIDInFile = const DcmDir(
      'ReferencedRelatedGeneralSOPClassUIDInFile',
      0x0004151a,
      'Referenced Related General SOP Class UID in File',
      VR.kUI,
      VM.k1_n,
      isRetired: false);

  static const DcmDir kNumberOfReferences = const DcmDir('NumberOfReferences',
      0x00041600, 'Number of References', VR.kUL, VM.k1, isRetired: true);

  static const List<DcmDir> dcmDirTags = const <DcmDir>[
    kFileSetID, // (0004,1130)
    kFileSetDescriptorFileID, // (0004,1141)
    kSpecificCharacterSetOfFileSetDescriptorFile, // (0004,1142)
    kOffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity, // (0004,1200)
    kOffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity, // (0004,1202)
    kFileSetConsistencyFlag, // (0004,1212)
    kDirectoryRecordSequence, // (0004,1220)
    kOffsetOfTheNextDirectoryRecord, // (0004,1400)
    kRecordInUseFlag, // (0004,1410)
    kOffsetOfReferencedLowerLevelDirectoryEntity, // (0004,1420)
    kDirectoryRecordType, // (0004,1430)
    kPrivateRecordUID, // (0004,1432)
    kReferencedFileID, // (0004,1500)
    kMRDRDirectoryRecordOffset, // (0004,1504)
    kReferencedSOPClassUIDInFile, // (0004,1510)
    kReferencedSOPInstanceUIDInFile, // (0004,1511)
    kReferencedTransferSyntaxUIDInFile, // (0004,1512)
    kReferencedRelatedGeneralSOPClassUIDInFile, // (0004,151A)
    kNumberOfReferences, // (0004,1600)
  ];
}
