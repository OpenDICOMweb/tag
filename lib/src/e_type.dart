// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.

//TODO: document
/// A DICOM Data Element Type.  See PS3.5, Section 7.4.
class EType {
  final int index;
  final bool isConditional;
  final String name;

  const EType(this.index, this.isConditional, this.name);

  /// Use this when the EType is not known.
  static const EType kUnknown = const EType(0, false, "0");

  static const EType k1 = const EType(1, false, "1");
  static const EType k1c = const EType(2, true, "1C");
  static const EType k2 = const EType(3, false, "2");
  static const EType k2c = const EType(4, true, "2C");
  static const EType k3 = const EType(5, false, "3");

  static const List<EType> list = const [kUnknown, k1, k1c, k2, k2c, k3];

  static const Map<String, EType> map = const {
    "0": EType.k1,
    "1": EType.k1,
    "1c": EType.k1,
    "2": EType.k1,
    "2c": EType.k1,
    "3": EType.k1,
  };

  EType lookup(int index) {
    if (index < 0 || 5 < index) return null;
    return list[index];
  }

  @override
  String toString() => 'ElementType($name)';
}
