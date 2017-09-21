// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:date_time/date_time.dart';
import 'package:string/string.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';

import 'vr.dart';

typedef bool Tester<String>(String value, int min, int max);
typedef String ErrorMsg<String>(String value, int min, int max);
typedef E Parser<E>(String s, int min, int max);
typedef E Fixer<E>(String s, int min, int max);

const List<String> emptyList = const <String>[];

abstract class VRString extends VR<String> {
  @override
  final int minValueLength;
  @override
  final int maxValueLength;

  /// Create an integer VR.
  const VRString._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, this.minValueLength, this.maxValueLength)
      : super(index, code, id, 1, vfLengthSize, maxVFLength, keyword);

  String get padChar => ' '; // defaults to ASCII Space

  @override
  bool get isBinary => false;

  @override
  bool get isString => true;

  @override
  bool get isAscii => true;

  @override
  bool get isUtf8 => !isAscii;

  /// Returns [true] if [v] is valid for [this].
  @override
  bool isValid(Object v) =>
      (v is String) &&
      (minValueLength <= v.length) &&
      (v.length <= maxValueLength);

  /// Returns [true] if [values] is [List<String>].
  @override
  bool isValidType(Object values) => values is String;

  /// Returns true if the [Type] of values is [List<String>].
  @override
  bool isValidValuesType(Iterable<String> vList) => vList is List<String>;
/* Flush when working
  {
    if (vList is! List<String>) return false;
    for (var v in vList) if (!isValidType(v)) return false;
    return true;
  }
*/

  /// Returns a [List<String>] converted from [bytes].
  List<String> bytesToValues(Uint8List bytes) {
    if (bytes == null || bytes.length == 0) emptyList;
    if (bytes.length.isEven) {
      if (bytes[bytes.length - 1] == kSpace || bytes[bytes.length - 1] == kNull)
        bytes = bytes.buffer.asUint8List(0, bytes.length - 1);
    }
    var s = (isAscii) ? ASCII.decode(bytes) : UTF8.decode(bytes);
    return s.split('\\');
  }

  Uint8List valuesToBytes(List<String> values) {
    StringBuffer sb = new StringBuffer('${values.join(r"\")}');
    if (sb.length.isOdd) sb.write(padChar);
    var s = sb.toString();
    return (isAscii) ? ASCII.encode(s) : UTF8.encode(s);
  }

  @override
  String check(String s) => (isValid(s)) ? s : null;

  /// Default [String] parser.  If the [String] [isValid] just returns it;
  @override
  dynamic parse(String s) => isValid(s);

  //Fix: complent and doc
  @override
  String fix(String s);

  /// Returns [true] if [minValueLength] <= length <= [maxValueLength].
  @override
  bool isValidLength(int length) =>
      minValueLength <= length && length <= maxValueLength;

  /// Returns [true] if length is NOT valid.
  bool isNotValidLength(String s) => !isValidLength(s.length);

  /// Returns [true] if all characters pass the filter.
  bool _filteredTest(String s, bool filter(int c)) {
    if (s == null || !isValidLength(s.length)) return false;
    for (int i = 0; i < s.length; i++) {
      if (!filter(s.codeUnitAt(i))) return false;
    }
    return true;
  }

  /// The filter for DICOM String characters.
  /// Visible ASCII characters, except Backslash.
  bool _isDcmChar(int c) => c >= kSpace && c < kDelete && c != kBackslash;

  //TODO: this currently returns only the first error -
  //      Should it return all errors?
  /// Returns an error [String] if some character in [s] does not pass
  /// the filter; otherwise, returns the empty [String]("").
  ParseIssues _getStringParseIssues(String s, bool filter(int c), String name) {
    var issues = new ParseIssues(name, s);
    _getLengthIssues(s.length, issues);
    for (int i = 0; i < s.length; i++)
      if (!filter(s.codeUnitAt(i))) issues += '${_invalidChar(s, i)}\n';
    return issues;
  }

  /// Returns a [String] containing an invalid length error message,
  /// or [null] if there are no errors.
  void _getLengthIssues(int length, ParseIssues issues) {
    if (length == null) issues += 'Invalid length(Null)';
    if (length == 0) issues += 'Invalid length(0)';
    if (length < minValueLength || maxValueLength < length)
      issues +=
          'Length error: min($minValueLength) <= value($length) <= max($maxValueLength)';
  }

  /// Returns a [String] containing an invalid character error message.
  String _invalidChar(String s, int pos) =>
      'Invalid character "${s[pos]}"(${s.codeUnitAt(pos)}) '
      'at position($pos) in: "$s" ${s.codeUnits}';
}

/// DICOM DCR Strings -  AE, LO, SH, UC.
class VRDcmString extends VRString {
  const VRDcmString._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool get isAscii => (this == kAE) ? true : false;

  /// VR.kUC can have any number of values.
  @override
  bool get isLengthAlwaysValid => this == VR.kUC;

  @override
  bool isValid(Object s) => (s is String) && _filteredTest(s, _isDcmChar);

  @override
  ParseIssues issues(String s) =>
      _getStringParseIssues(s, _isDcmChar, "DcmString");

  /// Fix
  @override
  String fix(String s) {
    //TODO:
    /// If too long truncate
    /// if illegal chars replace with '?'
    return s;
  }

  //index, code, id, vfLengthSize, maxVFLength, keyword, min, max
  static const VRDcmString kAE =
      const VRDcmString._(1, 0x4541, "AE", 2, kMaxShortVF, "AETitle", 1, 16);
  static const VRDcmString kLO = const VRDcmString._(
      12, 0x4f4c, "LO", 2, kMaxShortVF, "LongString", 1, 64);
  static const VRDcmString kSH = const VRDcmString._(
      20, 0x4853, "SH", 2, kMaxShortVF, "ShortString", 1, 16);
  static const VRDcmString kUC = const VRDcmString._(
      26, 0x4355, "UC", 4, kMaxLongVF, "UnlimitedCharacters", 1, kMaxLongVF);
}

class VRDcmText extends VRString {
  const VRDcmText._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool get isAscii => false;

  @override
  bool get isUtf8 => true;

  @override
  bool isValid(Object s) => (s is String) && _filteredTest(s, _isTextChar);

  @override
  ParseIssues issues(String s) =>
      _getStringParseIssues(s, _isTextChar, "DcmText");

  /// Fix
  @override
  String fix(String s) {
    //TODO
    //If too long truncate
    // if illegal chars replace with ???
    return s;
  }

  /// The filter for DICOM Text characters. All visible ASCII characters
  /// are legal including Backslash.  These [VR]s
  /// must have a VM of VM.k1, i.e. only one value.
  bool _isTextChar(int c) => !(c < kSpace || c == kDelete);

  //index, code, id, vfLengthSize, maxVFLength, keyword, min, max
  static const VRDcmText kLT =
      const VRDcmText._(13, 0x544c, "LT", 2, kMaxShortVF, "LongText", 1, 10240);
  static const VRDcmText kST =
      const VRDcmText._(24, 0x5453, "ST", 2, kMaxShortVF, "ShortText", 1, 1024);
  static const VRDcmText kUT = const VRDcmText._(
      32, 0x5455, "UT", 4, kMaxLongVF, "UnlimitedText", 1, kMaxLongVF);
}

/// DICOM DCR Strings -  AE, LO, SH, UC.
class VRCodeString extends VRString {
  const VRCodeString._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s) =>
      (s is String) && _filteredTest(s, _isCodeStringChar);

  @override
  ParseIssues issues(String s) =>
      _getStringParseIssues(s, _isCodeStringChar, "VR.kCS");

  /// Fix
  @override
  String fix(String s) {
    //TODO:
    // If too long truncate
    // if illegal chars replace with " "
    // if lowercase convert to with uppercase
    if (!isValidLength(s.length)) return null;
    return s.toUpperCase();
  }

  /// The filter for DICOM Code String(CS) characters.
  /// Visible ASCII characters, except Backslash.
  bool _isCodeStringChar(int c) =>
      isUppercaseChar(c) || isDigitChar(c) || c == kSpace || c == kUnderscore;

  //index, code, id, vfLengthSize, maxVFLength, keyword, minValueLength, max
  static const VRCodeString kCS = const VRCodeString._(
      5, 0x5343, "CS", 2, kMaxShortVF, "CodeString", 1, 16);
}

class VRDcmAge extends VRString {
  const VRDcmAge._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override

  /// Returns [true] if [s] is a valid DICOM Age String (AS).
  bool isValid(Object s) {
    if (s is String) {
      assert(s != null);
      if (s.length != 4) return false;
      for (int i = 0; i < 3; i++)
        if (!isDigitChar(s.codeUnitAt(i))) return false;
      return _isAgeMarker(s.codeUnitAt(3)) ? true : false;
    }
    return false;
  }

  /// Returns an error [String] if [s] is invalid; otherwise, "".
  @override
  ParseIssues issues(String s) {
    assert(s != null);
    var issues = new ParseIssues("VR.kAS", s);
    _getLengthIssues(s.length, issues);
    for (int i = 0; i < 3; i++)
      if (!isDigitChar(s.codeUnitAt(i))) issues += '${_invalidChar(s, i)}\n';
    if (!_isAgeMarker(s.codeUnitAt(3))) issues += '${_invalidChar(s, 3)}\n';
    return issues;
  }

  @override
  Duration parse(String s) {
    assert(s != null);
    int n = _getCount(s);
    if (n == null) return null;
    int nDays;
    switch (s[4]) {
      case "D":
        nDays = 1;
        break;
      case "W":
        nDays = 7;
        break;
      case "M":
        nDays = 30;
        break;
      case "Y":
        nDays = 365;
        break;
      default:
        return null;
    }
    return new Duration(days: n * nDays);
  }

  int _getCount(String s) => int.parse(s.substring(0, 3), onError: (s) => null);

  /// Fix
  @override
  String fix(String s) {
    if (_isLowercaseAgeMarker(s.codeUnitAt(4))) return s.toUpperCase();
    //TODO
    // If count is not valid replace with ""
    // If marker is lowercase make uppercase
    return s;
  }

  bool _isAgeMarker(int c) =>
      (c == kD || c == kW || c == kM || c == kY) ? true : false;

  bool _isLowercaseAgeMarker(int c) =>
      (c == kd || c == kw || c == km || c == ky) ? true : false;

  static const VRDcmAge kAS =
      const VRDcmAge._(2, 0x5341, "AS", 2, kMaxShortVF, "AgeString", 4, 4);
}

class VRDcmDate extends VRString {
  const VRDcmDate._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s, {int start = 0, int end}) =>
      (s is String) &&
      (s.length == 8) &&
      Date.isValidString(s.trimRight(), start: start, end: end);

  @override
  Date parse(String s, {int start = 0, int end}) =>
      Date.parse(s.trimRight(), start: start, end: end);

  @override
  ParseIssues issues(String s, {int start = 0, int end}) =>
      Date.issues(s.trimRight(), start: start, end: end);

  /// Fix
  @override
  String fix(String s) {
    var t = s.trimRight();
    //TODO: trucate on error what other fixes?
    return t;
  }

  static const VRDcmDate kDA =
      const VRDcmDate._(6, 0x4144, "DA", 2, kMaxShortVF, "DateString", 8, 8);
}

class VRDcmDateTime extends VRString {
  const VRDcmDateTime._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s, {int start = 0, int end}) =>
      (s is String) &&
      DcmDateTime.isValidString(s.trimRight(), start: start, end: end);

  @override
  DcmDateTime parse(String s, {int start = 0, int end}) =>
      DcmDateTime.parse(s.trimRight(), start: start, end: end);

  @override
  ParseIssues issues(String s, {int start = 0, int end}) =>
      DcmDateTime.issues(s.trimRight(), start: start, end: end);

  /// Fix
  @override
  String fix(String s) {
    var t = s.trimRight();
    //TODO: trucate on error what other fixes?
    //TODO: could remove '-', 'T', ' ', and ':'
    return t;
  }

  static const VRDcmDateTime kDT = const VRDcmDateTime._(
      8, 0x5444, "DT", 2, kMaxShortVF, "DateTimeString", 4, 26);
}

//TODO: doc
class VRDcmTime extends VRString {
  const VRDcmTime._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s, {int start = 0, int end}) =>
      (s is String) &&
      Time.isValidString(s.trimRight(), start: start, end: end);

  @override
  Time parse(String s, {int start = 0, int end}) =>
      Time.parse(s.trimRight(), start: start, end: end);

  @override
  ParseIssues issues(String s, {int start = 0, int end}) =>
      Time.issues(s.trimRight(), start: start, end: end);

/* Enhancement
  @override
  String fix(String s) => Time.fix(s);
*/

  static const VRDcmTime kTM =
      const VRDcmTime._(25, 0x4d54, "TM", 2, kMaxShortVF, "TimeString", 2, 14);
}

class VRDecimalString extends VRString {
  const VRDecimalString._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s) => (s is String) && parse(s) != null;

  @override
  ParseIssues issues(String s) {
    var issues = new ParseIssues("VR.kDS", s);
    if (isNotValid(s)) issues += 'Invalid Decimal value $s';
    return issues;
  }

  @override
  num parse(String s) {
    assert(s != null);
    if (!isValidLength(s.length)) return null;
    return num.parse(s, (s) => null);
  }

/* Enhancement
  @override
  String fix(String s) {
    //TODO:
    // how to fix? replace with no-value;
    return s;
  }
*/

  static const VRDecimalString kDS = const VRDecimalString._(
      7, 0x5344, "DS", 2, kMaxShortVF, "DecimalString", 1, 16);
}

class VRIntString extends VRString {
  const VRIntString._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s) => (s is String) && parse(s) != null;

  @override
  ParseIssues issues(String s) {
    assert(s != null);
    var issues = new ParseIssues("VR.kUR", s);
    if (isNotValid(s)) issues += 'Invalid Integer String (IS) value: $s';
    return issues;
  }

  @override
  int parse(String s) {
    assert(s != null);
    if (!isValidLength(s.length)) return null;
    return int.parse(s.trim(), onError: (s) => null);
  }

  /// Fix
  @override
  String fix(String s) {
    //TODO:
    // how to fix? replace with no-value;
    return s;
  }

  static const VRIntString kIS = const VRIntString._(
      11, 0x5349, "IS", 2, kMaxShortVF, "IntegerString", 1, 12);
}

/// Person Name (PN).
/// Note: Does not support
class VRPersonName extends VRString {
  static int maxComponentGroupLength = 64;

  const VRPersonName._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool get isAscii => false;

  @override
  bool isValid(Object s) {
    if (s is String) {
      var groups = s.split('=');
      if (groups == null) groups = [s];
      for (String group in groups)
        if (group.length > 64 || !_filteredTest(group, _isDcmChar))
          return false;
      return true;
    }
    return false;
  }

  @override
  ParseIssues issues(String s) {
    assert(s != null);
    var issues = new ParseIssues("VR.kPN", s);
    var groups = s.split('=');
    if (groups.length < 1 || groups.length > 3)
      issues += 'Invalid number of ComponentGroups: min(1) '
          '<= value(${groups.length}) <= max(3)\n';
    for (String group in groups) {
      if (group.length > 64)
        issues += 'Invalid Component Group Length: min(1) '
            '<= value(${group.length} <= max(64)\n';
      issues += '{_getFilteredError(s, _isDcmChar)}';
    }
    return issues;
  }

  /// Parses a PN String, but does not change it.
  @override
  List<String> parse(String s) {
    if (s == null || s == "") return null;
    var values = s.split('\\');
    for (String pn in values) {
      var cGroups = splitTrim(pn, '=');
      if (cGroups == null) return null;
      for (String cg in cGroups)
        if (cg.length > 64 || !_filteredTest(cg, _isDcmChar)) return null;
    }
    return values;
  }

  /// Fix
  /// Note: Currently only removed leading and trailing whitespace.
  @override
  String fix(String s) {
    if (s == null || s == "") return null;
    var values = s.split('\\');
    List<String> newPN = [];
    for (String pn in values) {
      var cGroups = splitTrim(pn, '=');
      if (cGroups == null) return null;
      List<String> newCG = [];
      for (String cg in cGroups) {
        if (cg.length > 64 || !_filteredTest(cg, _isDcmChar)) return null;
        newCG.add(splitTrim(cg, '^').join('^'));
      }
      newPN.add(newCG.join('='));
    } //TODO:
    // how to fix? replace with no-value;
    return newPN.join('\\');
  }

  static const VRPersonName kPN = const VRPersonName._(
      19, 0x4e50, "PN", 2, kMaxShortVF, "PersonName", 1, 64 * 3);

  /*Flush if not needed.
  /// The filter for DICOM PersonName characters.  Visible ASCII
  /// characters, except Backslash(\) and Equal Sign(=).
  static bool _isPNComponentGroupChar(int c) =>
      c >= kSpace && c < kDelete && (c != kBackslash && c != kCircumflex);
  */
}

/// _UI_: A DICOM UID (aka OSI OID).
class VRUid extends VRString {
  const VRUid._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  String get padChar => '\u0000';

  @override
  bool isValid(Object s) => (s is String) && Uid.isValidString(s);

  /// Returns [true] if [uidString] starts with the DICOM UID root.
  bool hasDicomRoot(String uidString) => uidString.startsWith(Uid.dicomRoot);

  //TODO: this need to return beter messages
  @override
  ParseIssues issues(String s) {
    var issues = new ParseIssues("VR.kUR", s);
    if (!isValid(s)) issues += 'Invalid Uid: $s';
    return issues;
  }

  /// Fix
  @override
  String fix(String s) {
    //TODO: truncate on error, what other fixes?
    return "";
  }

  //TODO: what should the minimum length be?
  /// Minimum length is based on '1.2.804.xx'.
  static const VRUid kUI =
      const VRUid._(27, 0x4955, "UI", 2, kMaxShortVF, "UniqueID", 10, 64);
}

class VRUri extends VRString {
  const VRUri._(int index, int code, String id, int vfLengthSize,
      int maxVFLength, String keyword, int minValueLength, int maxValueLength)
      : super._(index, code, id, vfLengthSize, maxVFLength, keyword,
            minValueLength, maxValueLength);

  @override
  bool isValid(Object s) => (s is String) && parse(s) != null;

  // Always [true] because UR can only have one value with a length up
  // to [kMaxVFLength];
  @override
  bool get isLengthAlwaysValid => true;

  @override
  ParseIssues issues(String s) {
    assert(s != null);
    var issues = new ParseIssues("VR.kUR", s);
    _getLengthIssues(s.length, issues);
    try {
      Uri.parse(s);
    } on FormatException catch (e) {
      issues += e.toString();
    }
    return issues;
  }

  // Parse DICOM Time.
  @override
  Uri parse(String uriString) {
    assert(uriString != null && uriString != "");
    if (!isValidLength(uriString.length)) return null;
    Uri uri;
    try {
      uri = Uri.parse(uriString);
    } on FormatException {
      return null;
    }
    return uri;
  }

  /// Fix
  @override
  String fix(String s) {
    //TODO:
    // trucate on error
    // what other fixes?
    // if separator (:) present - remove.
    // if time zone marker present??
    return s;
  }

  static const VRUri kUR =
      const VRUri._(30, 0x5255, "UR", 4, kMaxLongVF, "URI", 1, kMaxLongVF);
}
