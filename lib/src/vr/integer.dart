// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:number/number.dart';
import 'package:string/string.dart';
import 'package:system/system.dart';

import 'vr.dart';

// Maximum Value Field length for different [VRInt]s.

// Note: since Value Field Length must be an even number OB, OW, and UN
//       subtract two from kMaxUint32

const int kMaxOB = kUint32Max - 2;
const int kMaxOL = kUint32Max - 4;
const int kMaxOW = kUint32Max - 2;
const int kMaxUN = kUint32Max - 2;

/// Converts [bytes] into a valid [TypedData<List<int>>] and returns it.
/// If [bytes] is [null] or empty (`bytes.length == 0`), returns an
/// empty [List<int>]. If the list cannot be converted returns null.
typedef TypedData BytesToValues(Uint8List bytes,
                                {int offset, int length, bool asView});

/// Verifies [bytes] into a valid [TypedData<List<int>>], and
/// if it is aligned (on a valid byte boundary) returns a View of
/// [bytes]; otherwise, copies [bytes] into a new [TypedData<List<int>>].
/// If [bytes] is [null] or empty (`bytes.length == 0`), returns an empty
/// [TypedData<List<int>>]. If the list cannot be converted returns null.
typedef List<int> IntViewer(Uint8List bytes);

/// Returns a [String] specifying any issues with [value]. If [value]
/// isValidString returns [null].
typedef String IntIssuer(int value);

/// Returns a valid [int]. Iff [value] is a valid string].  It is returned
/// unmodified. If [value] has one or more issues that can be fixed, returns
/// a modified value. If [value] is not valid and cannot be fixed returns
/// [null].
typedef int IntFixer(int value);

/// The class of all integer [VR]s.
class VRInt extends VR<int> {
  /// The minimum length of a value.
  final int minValue;

  /// The minimum length of a value.
  final int maxValue;

  /// The method that converts bytes ([Uint8List]) to values.
  final BytesToValues fromBytes;

  const VRInt._(int index, int code, String id, int elementSize, int vfLengthSize,
      int maxVFLength, String keyword, this.minValue, this.maxValue, this.fromBytes,
      [bool undefinedLengthAllowed = false])
      : super(index, code, id, elementSize, vfLengthSize, maxVFLength, keyword,
            undefinedLengthAllowed: undefinedLengthAllowed);

  @override
  bool get isBinary => true;

  @override
  bool get isInteger => true;

  /// Returns [true] if [n] is valid for this [VRInt].
  @override
  bool isValid(Object n) => (n is int) && (minValue <= n) && (n <= maxValue);

  /// Returns [true] of [value] is [double].
  @override
  bool isValidType(Object value) => value is int;

  /// Returns true if the [Type] of values is [int].
  @override
  bool isValidValuesType(Iterable values) => values is List<int>;

  // [true] if [this] is one of OB, OL, OW, or UN;
  @override
  bool get isLengthAlwaysValid => vfLengthSize == 4;

  /// Returns a [ParseIssues] object indicating the the issues with [n].
  /// If there are no issues returns the empty string ('').
  @override
  ParseIssues issues(int n) {
    if (!isValid(n)) {
      final msg = 'Invalid value: min($minValue) <= value($n) <= max($minValue)';
      return new ParseIssues('VRInt', '$n', 0, 0, [msg]);
    }
    return null;
  }

  /// Returns a valid, possibly coerced, value.
  @override
  int fix(int n) {
    if (n < minValue) return minValue;
    if (n > maxValue) return maxValue;
    return n;
  }

  Uint8List uint8ListViewOfBytes(TypedData list) {
    final length = list.lengthInBytes ~/ list.elementSizeInBytes;
    return fromBytes(list, offset: 0, length:length, asView: true);
  }

  TypedData copyBytes(TypedData list) {
    final length = list.lengthInBytes ~/ list.elementSizeInBytes;
    return fromBytes(list, offset: 0, length: length, asView: false);
  }

  // The constants defined below are in the order of the next line:
  // index, code, id, elementSize, vfLengthFieldSize, maxVFLength, keyword

  //TODO: improve documentation
  // Note: VR.kAT values are a list of Uint16, but with 2x the number of
  // element, since each element is x[0] << 16 + x[1].
  static const VRInt kAT = const VRInt._(3, 0x5441, 'AT', 4, 2, kMaxShortVF,
      'Attribute Tag Code', 0, Uint32.maxValue, Uint16.fromBytes);

  static const VRInt kOB = const VRInt._(14, 0x424f, 'OB', 1, 4, kMaxOB, 'OtherByte', 0,
      Uint8.maxValue, Uint8.fromBytes, true);

  static const VRInt kOL = const VRInt._(
      17, 0x4c4f, 'OL', 4, 4, kMaxOL, 'OtherLong', 0, Uint32.maxValue, Uint32.fromBytes);

  static const VRInt kOW = const VRInt._(18, 0x574f, 'OW', 2, 4, kMaxOW, 'OtherWord', 0,
      Uint16.maxValue, Uint16.fromBytes, true);

  static const VRInt kSL = const VRInt._(21, 0x4c53, 'SL', 4, 2, kMaxShortVF,
      'SignedLong', Int32.minValue, Int32.maxValue, Int32.fromBytes);

  static const VRInt kSS = const VRInt._(23, 0x5353, 'SS', 2, 2, kMaxShortVF,
      'SignedShort', Int16.minValue, Int16.maxValue, Int16.fromBytes);

  static const VRInt kUL = const VRInt._(28, 0x4c55, 'UL', 4, 2, kMaxShortVF,
      'UnsignedLong', 0, Uint32.maxValue, Uint32.fromBytes);

  static const VRInt kUS = const VRInt._(31, 0x5355, 'US', 2, 2, kMaxShortVF,
      'UnsignedShort', 0, Uint16.maxValue, Uint16.fromBytes);

  // **** All VRs below this line are treated as VR.kUN. ****
  static const VRInt kOBOW = const VRInt._(
      29, 0x4e55, 'OBOW', 1, 4, kMaxUN, 'OBorOW', 0, Uint8.maxValue, Uint8.fromBytes);

  static const VRInt kUSSS = const VRInt._(
      29, 0x4e55, 'USSS', 1, 4, kMaxUN, 'USorSS', 0, Uint8.maxValue, Uint8.fromBytes);

  static const VRInt kUSSSOW = const VRInt._(29, 0x4e55, 'USSSOW', 1, 4, kMaxUN,
      'USorSSorOW', 0, Uint8.maxValue, Uint8.fromBytes);

  static const VRInt kUSOW = const VRInt._(
      29, 0x4e55, 'USOW', 1, 4, kMaxUN, 'USorOW', 0, Uint8.maxValue, Uint8.fromBytes);

  static const VRInt kUSOW1 = const VRInt._(
      29, 0x4e55, 'USOW1', 1, 4, kMaxUN, 'USorOW1', 0, Uint8.maxValue, Uint8.fromBytes);
}
