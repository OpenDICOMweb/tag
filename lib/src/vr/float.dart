// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:string/string.dart';
import 'package:system/system.dart';
import 'package:tag/src/issues.dart';
import 'package:tag/src/vr/vr.dart';


// Maximum Value Field length for different Float VRs.
const int kMaxOD = kUint32Max - 8;
const int kMaxOF = kUint32Max - 4;

/// The class of all Floating Point [VR]s.
class VRFloat extends VR<double> {
  const VRFloat._(int index, int code, String id, int elementSize,
      int vfLengthFieldSize, int maxVFLength, String keyword)
      : super(index, code, id, elementSize, vfLengthFieldSize, maxVFLength,
            keyword);

  @override
  @override
  bool get isBinary => true;

  @override
  bool get isFloat => true;

  int get valueLength => elementSize;

  /// Returns [true] of [value] is [double].
  @override
  bool isValidValue(Object value, [Issues issues]) =>  value is double;

  /// Returns true if the [Type] of values is [double].
  @override
  bool isValidValuesType(Iterable values, [Issues issues]) => values is Iterable<double>;

  // [true] if [this] is one of OF, OD;
  @override
  bool get isLengthAlwaysValid => vfLengthSize == 4;

  @override
  ParseIssues issues(double n) => null;

  /// Returns a new value for [n] is possible; otherwise, returns null.
  @override
  double fix(double n) => n;

  // *** The fields in order:
  // index, code, id, elementSize, vfLengthFieldSize, maxVFLength, keyword
  /// FD. A 64-bit floating point [List<double>], with a 16-bit value field.
  static const VRFloat kFD =
      const VRFloat._(17, 0x4446, 'FD', 8, 2, kMaxShortVF, 'FloatDouble');

  /// FL. A 32-bit floating point [List<double>], with a 16-bit value field.
  static const VRFloat kFL =
      const VRFloat._(18, 0x4c46, 'FL', 4, 2, kMaxShortVF, 'FloatSingle');

  /// OD. A 64-bit floating point [List<double>], with a 32-bit value field.
  static const VRFloat kOD =
      const VRFloat._(4, 0x444f, 'OD', 8, 4, kMaxOD, 'OtherDouble');

  /// OF. A 32-bit floating point [List<double>], with a 32-bit value field.
  static const VRFloat kOF =
      const VRFloat._(5, 0x464f, 'OF', 4, 4, kMaxOF, 'OtherFloat');
}
