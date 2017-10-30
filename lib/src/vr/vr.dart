// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/dataset.dart';
import 'package:string/string.dart';
import 'package:system/system.dart';

import 'package:tag/src/issues.dart';
import 'package:tag/src/vr/float.dart';
import 'package:tag/src/vr/integer.dart';
import 'package:tag/src/vr/string.dart';

//TODO: Explain VR class structure

abstract class VR<V> {
  final int index;
  final int code;
  final String id;
  final int elementSize;
  final int vfLengthSize;
  final int maxVFLength;
  final String keyword;

  const VR(this.index, this.code, this.id, this.elementSize, this.vfLengthSize,
      this.maxVFLength, this.keyword);

  VR operator [](int i) => vrAlphabeticList[i];

  /// Is the kUndefinedLength value allowed as a Value Field Length.
  bool get undefinedLengthAllowed => false;

  bool get isAscii => false;
  bool get isUtf8 => false;

  @deprecated
  bool get isBinary => false;
  @deprecated
  bool get isInteger => false;
  @deprecated
  bool get isFloat => false;
  @deprecated
  bool get isString => false;
  @deprecated
  bool get isSequence => false;
  @deprecated
  bool get isUnknown => false;
  @deprecated
  bool get isItem => false;

  /// The minimum length of a value.
  int get minValueLength => elementSize;

  /// The maximum number of values for [this].
  int get maxLength => maxVFLength ~/ elementSize;

  bool get hasShortVF => vfLengthSize == 2;
  bool get hasLongVF => !hasShortVF;

  /// Returns the [VR] as a [String].
  String get asString => 'VR.k$id';

  String _toHex(int code) => code.toRadixString(16);
  String get info => '$runtimeType: $keyword $id(${_toHex(code)})[$index]: '
      'elementSize($elementSize) vfLengthSize($vfLengthSize), '
      'maxVFLength($maxVFLength)';

  int headerLength({bool isEVR}) => (isEVR) ? ((hasShortVF) ? 8 : 12) : 8;

  /// Returns the length in number of elements.
  int toLength(int lengthInBytes) => lengthInBytes ~/ elementSize;

  /// Returns [true] if any number of values is always valid.
  bool get isLengthAlwaysValid => false;

  /// Returns [true] if [value] is valid for [this].
  bool isValidValue(V value, [Issues issues]);

  /// Returns [true] of [value] is not valid for this VR.kUN.
  bool isNotValidValue(V value, [Issues issues]) => !isValidValue(value, issues);

  /// Returns true if the [List] [Type] of values is valid for [this].
  @deprecated
  bool isValidValuesType(Iterable<V> values, [Issues issues]);

  bool isValidLength(int length) => false;

  V check(V value) => (isValidValue(value)) ? value : null;

  // **** Must be overridden.
  /// Returns a valid value, or if not parsable, [null].
  dynamic parse(String s) => null;

  // **** Must be overridden.
  /// Returns a [ParseIssues] object indicating any issues with value.
  /// If there are no issues returns the empty string ('').
  //Urgent: finish
  ParseIssues issues(V value) => null;

  // **** Must be overridden.
  /// Returns a new value that is legal and a best practice.
  V fix(V value) => null;

  // **** Must be overridden.
  /// Returns [true] if [bytes] has a valid Value Field length.
  bool isValidBytes(Uint8List bytes) => bytes.length < maxVFLength;

  @override
  String toString() => asString;

  // **** Static methods

  static bool invalid(VR vr, Issues issues, VR correctVR) {
    final msg = 'Invalid VR($vr) Error, correct VR is $correctVR.';
    return _doError(msg, issues);
  }

  static bool invalidIndex(int index, Issues issues, VR correctVR) {
    final msg =
        'Invalid VR index($index = ${vrAlphabeticList[index]}), correct VR is $correctVR.';
    return _doError(msg, issues);
  }

  static bool invalidCode(int code, Issues issues, VR correctVR) {
    final msg = 'Invalid VR code($code = ${vrByCode[code]}), correct VR is $correctVR.';
    return _doError(msg, issues);
  }

  static bool _doError(String msg, Issues issues) {
    log.error(msg);
    issues.add(msg);
    if (throwOnError) throw new _InvalidVRError(msg);
    return false;
  }

  // **** Constant members

  // Unknown
  static const VR kUN = VRUnknown.kUN;
  // Sequence
  static const VR kSQ = VRSequence.kSQ;

  // Integers
  static const VR kSS = VRInt.kSS;
  static const VR kSL = VRInt.kSL;
  static const VR kOB = VRInt.kOB;
  static const VR kOW = VRInt.kOW;
  static const VR kUS = VRInt.kUS;
  static const VR kUL = VRInt.kUL;
  static const VR kOL = VRInt.kOL;
  static const VR kAT = VRInt.kAT;

  // Floats
  static const VR kFD = VRFloat.kFD;
  static const VR kFL = VRFloat.kFL;
  static const VR kOD = VRFloat.kOD;
  static const VR kOF = VRFloat.kOF;

  // String.numbers
  static const VR kIS = VRIntString.kIS;
  static const VR kDS = VRDecimalString.kDS;

  // String.dcm
  static const VR kAE = VRDcmString.kAE;
  static const VR kLO = VRDcmString.kLO;
  static const VR kSH = VRDcmString.kSH;

  // Code String
  static const VR kCS = VRCodeString.kCS;

  // String.Text
  static const VR kST = VRDcmText.kST;
  static const VR kLT = VRDcmText.kLT;

  // String.DateTime
  static const VR kDA = VRDcmDate.kDA;
  static const VR kDT = VRDcmDateTime.kDT;
  static const VR kTM = VRDcmTime.kTM;

  // String.Other
  static const VR kPN = VRPersonName.kPN;
  static const VR kUI = VRUid.kUI;
  static const VR kAS = VRDcmAge.kAS;

  // String with long Value Field
  static const VR kUC = VRDcmString.kUC;
  static const VR kUR = VRUri.kUR;
  static const VR kUT = VRDcmText.kUT;

  // Special values used by Tag
  static const VR kOBOW = VRIntSpecial.kOBOW;
  static const VR kUSSS = VRIntSpecial.kUSSS;
  static const VR kUSSSOW = VRIntSpecial.kUSSSOW;
  static const VR kUSOW = VRIntSpecial.kUSOW;
  //TODO: decide if this is needed
  static const VR kUSOW1 = VRIntSpecial.kUSOW1;

  // Sequence is 0
  static const int kSQindex = 0;
  // Long, possibly undefined
  static const int kOBindex = 1;
  static const int kOWindex = 2;
  static const int kUNindex = 3;
  static const int kMaybeUndefinedMin = kOBindex;
  static const int kMaybeUndefinedMax = kUNindex;
  // Long EVR
  static const int kODindex = 4;
  static const int kOFindex = 5;
  static const int kOLindex = 6;
  static const int kUCindex = 7;
  static const int kURindex = 8;
  static const int kUTindex = 9;
  static const int kEvrLongMin = kODindex;
  static const int kEvrLongMax = kUTindex;
  // Short EVR
  static const int kAEindex = 10;
  static const int kASindex = 12;
  static const int kATindex = 13;
  static const int kCSindex = 14;
  static const int kDAindex = 15;
  static const int kDSindex = 16;
  static const int kDTindex = 17;
  static const int kFDindex = 18;
  static const int kFLindex = 19;
  static const int kISindex = 20;
  static const int kLOindex = 21;
  static const int kLTindex = 22;
  static const int kPNindex = 23;
  static const int kSHindex = 24;
  static const int kSLindex = 25;
  static const int kSSindex = 26;
  static const int kSTindex = 27;
  static const int kTMindex = 28;
  static const int kUIindex = 29;
  static const int kULindex = 30;
  static const int kUSindex = 31;
  static const int kEvrShortMin = kAEindex;
  static const int kEvrShortMax = kUSindex;
  static const int kVRIndexMax = kUSindex;

  static const List<VR> vrByIndex = const <VR>[
    // Sequence == 0
    kSQ,
    // EVR Long maybe undefined
    kOB, kOW, kUN,
    // EVR Long
    kOD, kOF, kOL, kUC, kUR, kUT,
    // EVR Short
    kAE, kAS, kAT, kCS, kDA, kDS, kDT, kFD, kFL, kIS,
    kLO, kLT, kPN, kSH, kSL, kSS, kST, kTM, kUI, kUS,
    // EVR Special
    kOBOW, kUSSS, kUSSSOW, kUSOW, kUSOW1
  ];

  static VR lookupByIndex(int vrIndex) {
    if (vrIndex < 0 || vrIndex > kVRIndexMax) return null;
    return vrByIndex[vrIndex];
  }

  static const List<VR> vrAlphabeticList = const <VR>[
    null,
    kAE, kAS, kAT, kUN, kCS,
    kDA, kDS, kDT, kFD, kFL,
    kIS, kLO, kLT, kOB, kOD,
    kOF, kOL, kOW, kPN, kSH,
    kSL, kSQ, kSS, kST, kTM,
    kUC, kUI, kUL, kUN, kUR,
    kUS, kUT // stop reformat
  ];

//Urgent remove nulls
  static const Map<int, VR> vrByCode = const <int, VR>{
    0x0000: null,
    0x4541: kAE, 0x5341: kAS, 0x5441: kAT, 0x5242: null, 0x5343: kCS,
    0x4144: kDA, 0x5344: kDS, 0x5444: kDT, 0x4446: kFD, 0x4c46: kFL,
    0x5349: kIS, 0x4f4c: kLO, 0x544c: kLT, 0x424f: kOB, 0x444f: kOD,
    0x464f: kOF, 0x4c4f: kOL, 0x574f: kOW, 0x4e50: kPN, 0x4853: kSH,
    0x4c53: kSL, 0x5153: kSQ, 0x5353: kSS, 0x5453: kST, 0x4d54: kTM,
    0x4355: kUC, 0x4955: kUI, 0x4c55: kUL, 0x4e55: kUN, 0x5255: kUR,
    0x5355: kUS, 0x5455: kUT // stop reformat
  };

  static VR lookupByCode(int vrCode) => vrByCode[vrCode];

  static const Map<String, VR> vrById = const <String, VR>{
    'AE': kAE, 'AS': kAS, 'CS': kCS,
    'DA': kDA, 'DS': kDS, 'DT': kDT, 'IS': kIS,
    'LO': kLO, 'LT': kLT, 'PN': kPN, 'SH': kSH,
    'ST': kST, 'TM': kTM, 'UC': kUC, 'UI': kUI,
    'UR': kUR, 'UT': kUT, 'AT': kAT, 'OB': kOB,
    'OW': kOW, 'SL': kSL, 'SS': kSS, 'UL': kUL,
    'US': kUS, 'FD': kFD, 'FL': kFL, 'OD': kOD,
    'OF': VR.kOF // prevent reformat
  };

  static VR lookupId(String id) => vrById[id];
}

class VRSequence extends VR<Dataset> {
  // 8 is the size of an empty [Item].
  @override
  final int minValueLength = 8;
  final int maxValueLength = kMaxLongVF;

  const VRSequence._(int index, int code, String id, int elementSize, int vfLengthSize,
      int maxVFLength, String keyword)
      : super(index, code, id, 1, 4, kMaxLongVF, keyword);

  @override
  bool get isSequence => true;

  bool get isUndefinedLengthAllowed => true;

  @override
  bool isValidValue(Object value, [Issues issues]) => unsupportedError();

  /// Returns true if the [Type] of values is [List<int>].
  @override
  bool isValidValuesType(Iterable<Dataset> vList, [Issues issues]) =>
      vList is Iterable<Dataset>;

  //index, code, id, elementSize, vfLengthSize, maxVFLength, keyword
  static const VR kSQ =
      const VRSequence._(22, 0x5153, 'SQ', 1, 4, kMaxLongVF, 'Sequence');
}

// Urgent: jim to fix
class _InvalidVRError extends Error {
  String msg;

  _InvalidVRError(this.msg);

  @override
  String toString() => msg;
}
