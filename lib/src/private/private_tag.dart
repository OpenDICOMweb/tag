// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/number.dart';
import 'package:tag/src/e_type.dart';
import 'package:tag/src/tag.dart';
import 'package:tag/src/vm.dart';
import 'package:tag/src/vr/vr.dart';

typedef Tag TagMaker<E>(int code, VR<E> vr, [dynamic name]);

abstract class PrivateTag extends Tag {
  @override
  final int code;
  @override
  final VR vr;

  const PrivateTag(this.code, [this.vr = VR.kUN]);

  PrivateTag._(this.code, [this.vr = VR.kUN]);

  @override
  bool get isPrivate => true;

  @override
  VM get vm => VM.k1_n;

  @override
  String get name => "Illegal Private Tag";

  int get index => -1;

  /// The Private Subgroup for this Tag.
  // Note: MUST be overridden in all subclasses.
  int get subgroup => (isCreator) ? code & 0xFF : (code & 0xFF00) >> 8;

  @override
  EType get type => EType.k3;

  String get subgroupHex => Uint8.hex(subgroup);

  String get asString => toString();

  @override
  String get info => '$runtimeType$dcm $groupHex, "$name", $eltHex $vr, $vm';

  @override
  String toString() => '$runtimeType$dcm subgroup($subgroup)';

/*  static PrivateTag maker(int code, VR vr, String name) =>
      new PrivateTag._(code, vr);*/
}

/// Private Group Length Tags have codes that are (gggg,eeee),
/// where gggg is odd, and eeee is zero.  For example (0009,0000).
class PrivateTagGroupLength extends PrivateTag {
  static const int kUnknownIndex = -1;

  PrivateTagGroupLength(int code, VR vr) : super(code, vr);

  @override
  VR get vr => VR.kUL;

  @override
  VM get vm => VM.k1;

  @override
  String get name => "Private Group Length Tag";

  //Flush at V0.9.0 if not used.
  static PrivateTagGroupLength maker(int code, VR vr, [_]) =>
      new PrivateTagGroupLength(code, vr);
}

/// Private Illegal Tags have have codes that are (gggg,eeee),
/// where gggg is odd, and eeee is between 01 and 09 hexadecimal.
/// For example (0009,0005).
// Flush at v0.9.0 if not used by then
class PrivateTagIllegal extends PrivateTag {
  static const int kUnknownIndex = -1;

  PrivateTagIllegal(int code, VR vr) : super(code, vr);

  @override
  String get name => "Private Illegal Tag";

  static PrivateTagIllegal maker(int code, VR vr, String name) =>
      new PrivateTagIllegal(code, vr);
}
