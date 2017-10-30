// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:number/number.dart';
import 'package:string/string.dart';
import 'package:system/system.dart';
import 'package:tag/src/issues.dart';
import 'package:tag/src/vr/vr.dart';

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
typedef TypedData BytesToValues(Uint8List bytes, {int offset, int length, bool asView});

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

  final bool undefinedAllowed;

  const VRInt._(int index, int code, String id, int elementSize, int vfLengthSize,
      int maxVFLength, String keyword, this.minValue, this.maxValue, this.fromBytes,
      [bool undefinedLengthAllowed = false])
      : super(index, code, id, elementSize, vfLengthSize, maxVFLength, keyword);

  @override
  bool get isBinary => true;

  @override
  bool get isInteger => true;

  /// Returns [true] if [v] is valid for this [VRInt].
  @override
  bool isValidValue(int v, [Issues issues]) {
    print('n: $v, min: $minValue, max: $maxValue');
    return v >= minValue && v <= maxValue;
  }

  /// Returns true if the [Type] of values is [int].
  @override
  bool isValidValuesType(Iterable<int> values, [Issues issues]) =>
      values is Iterable<int>;

  // [true] if [this] is one of OB, OL, OW, or UN;
  @override
  bool get isLengthAlwaysValid => vfLengthSize == 4;

  /// Returns a [ParseIssues] object indicating the the issues with [n].
  /// If there are no issues returns the empty string ('').
  @override
  ParseIssues issues(int n) {
    if (!isValidValue(n)) {
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

  TypedData viewOfBytes(TypedData list) {
    final length = list.lengthInBytes ~/ list.elementSizeInBytes;
    return fromBytes(list, offset: 0, length: length, asView: true);
  }

  TypedData copyBytes(TypedData list) {
    final length = list.lengthInBytes ~/ list.elementSizeInBytes;
    return fromBytes(list, offset: 0, length: length, asView: true);
  }

  // The constants defined below are in the order of the next line:
  // index, code, id, elementSize, vfLengthFieldSize, maxVFLength, keyword

  //TODO: improve documentation
  // Note: VR.kAT values are a list of Uint16, but with 2x the number of
  // element, since each element is x[0] << 16 + x[1].
  static const VRInt kAT = const VRInt._(12, 0x5441, 'AT', 4, 2, kMaxShortVF,
      'Attribute Tag Code', 0, Uint32.maxValue, Uint16.fromBytes);

  static const VRInt kOB = const VRInt._(1, 0x424f, 'OB', 1, 4, kMaxOB, 'OtherByte', 0,
      Uint8.maxValue, Uint8.fromBytes, true);

  static const VRInt kOL = const VRInt._(
      6, 0x4c4f, 'OL', 4, 4, kMaxOL, 'OtherLong', 0, Uint32.maxValue, Uint32.fromBytes);

  static const VRInt kOW = const VRInt._(2, 0x574f, 'OW', 2, 4, kMaxOW, 'OtherWord', 0,
      Uint16.maxValue, Uint16.fromBytes, true);

  static const VRInt kSL = const VRInt._(24, 0x4c53, 'SL', 4, 2, kMaxShortVF,
      'SignedLong', Int32.minValue, Int32.maxValue, Int32.fromBytes);

  static const VRInt kSS = const VRInt._(25, 0x5353, 'SS', 2, 2, kMaxShortVF,
      'SignedShort', Int16.minValue, Int16.maxValue, Int16.fromBytes);

  static const VRInt kUL = const VRInt._(29, 0x4c55, 'UL', 4, 2, kMaxShortVF,
      'UnsignedLong', 0, Uint32.maxValue, Uint32.fromBytes);

  static const VRInt kUS = const VRInt._(30, 0x5355, 'US', 2, 2, kMaxShortVF,
      'UnsignedShort', 0, Uint16.maxValue, Uint16.fromBytes);
}

class VRUnknown extends VR<int> {
	const VRUnknown._(int index, int code, String id, int elementSize, int vfLengthSize,
	                  int maxVFLength, String keyword)
			: super(index, code, id, 1, 4, kMaxLongVF, keyword);

	bool get isUndefinedLengthAllowed => true;

	@deprecated
	@override
	bool get isUnknown => true;

	bool _inRange(int value) => value >= 0 && value < 256;

	/// Returns [true] of [value] is UN.
	@override
	bool isValidValue(int value, [Issues issues]) => _inRange(value);

	/// Returns true if the [Type] of values is [List<int>].
	@override
	bool isValidValuesType(Iterable<int> values, [Issues issues]) => values is List<int>;

	//index, code, id, elementSize, vfLengthSize, maxVFLength, keyword
	/// UN - Unknown. The supertype of all VRs.
	static const VRUnknown kUN =
	const VRUnknown._(3, 0x4e55, 'UN', 1, 4, kMaxUN, 'Unknown');
}

/// The class of all integer [VR]s.
class VRIntSpecial extends VR<int> {
  final List<VR> vrs;

  const VRIntSpecial._(int index, String id, String keyword, this.vrs)
      : super(index, -1, id, -1, -1, -1, keyword);

  @override
  bool get isBinary => true;

  @override
  bool get isInteger => true;

  @override
  bool isValidValuesType(Iterable<int> values, [Issues issues]) =>  false;

  /// Returns true if the [Type] of values is [int].
  @override
  bool isValidValue(int value, [Issues issues]) => false;

  @override
  bool isValidVR(VR vr) => vrs.contains(vr);

  // **** All VRs below this line are special and used for validation only. ****
  // The constants defined below are in the order of the next line:
  // index, code, id, elementSize, vfLengthFieldSize, maxVFLength, keyword
  static const VRIntSpecial kOBOW =
      const VRIntSpecial._(32, 'OBOW', 'OBorOW', const <VR>[VRInt.kOB, VRInt.kOW]);

  static const VRIntSpecial kUSSS =
      const VRIntSpecial._(33, 'USSS', 'USorSS', const <VR>[VRInt.kUS, VRInt.kSS]);

  static const VRIntSpecial kUSSSOW = const VRIntSpecial._(
      34, 'USSSOW', 'USorSSorOW', const <VR>[VRInt.kUS, VRInt.kSS, VRInt.kOW]);

  static const VRIntSpecial kUSOW =
      const VRIntSpecial._(35, 'USOW', 'USorOW', const <VR>[VRInt.kUS, VRInt.kOW]);
}
