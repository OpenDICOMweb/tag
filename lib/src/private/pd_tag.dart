// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:common/number.dart';
import 'package:tag/src/private/pc_tag.dart';
import 'package:tag/src/private/pd_tag_definitions.dart';
import 'package:tag/src/private/private_tag.dart';
import 'package:tag/src/vm.dart';
import 'package:tag/src/vr/vr.dart';

///TODO add constant Tag for PDTag.kUnknownCreator
class PDTag extends PrivateTag {
  /// The [PCTag.name]
  final PCTag creator;

  factory PDTag(int code, VR vr, [PCTag creator]) {
    if (creator != null) {
      var definition = creator.lookupData(code);
      if (definition != null)
        return new PDTagKnown(code, vr, creator, definition);
      return new PDTagUnknown(code, vr, creator);
    }
    return new PDTagUnknown(code, vr, PCTagUnknown.kUnknownCreator);
  }

  const PDTag._(int code, VR vr, this.creator) : super(code, vr);

  @override
  bool get isPrivateData => true;

  VM get vm => VM.k1_n;

  static PDTag maker(int code, VR vr, [PCTag creator]) =>
      new PDTag(code, vr, creator);
}


class PDTagUnknown extends PDTag {

  PDTagUnknown(int code, VR vr, [PCTag creator = PCTagUnknown
      .kUnknownCreator])
      : super._(code, vr, creator);

  @override
  bool get isKnown => false;

  static PDTagUnknown maker(int code, VR vr, [PCTag creator]) =>
      new PDTagUnknown(code, vr, creator);
}

class PDTagKnown extends PDTag {
  final PDTagDefinition definition;

  const PDTagKnown(int code, VR vr, creator, this.definition)
      : super._(code, vr, creator);

  @override
  bool get isKnown => true;

  @override
  VM get vm => definition.vm;

  @override
  String get name =>
      (definition == null) ? 'Unknown' : definition.name;

  int get offset => code & 0xFF;

  String get offsetHex => Uint8.hex(offset);

  VR get expectedVR => definition.vr;

  int get expectedGroup => definition.group;

  int get expectedOffset => definition.offset;

  String get token => definition.token;

  @override
  int get index => definition.index;

  @override
  bool get isValid => creator.isValidDataCode(code);

  @override
  String get info =>
      '$runtimeType$dcm $groupHex, "$token", subgroup($subgroupHex), '
          'offset($offsetHex), $vr, $vm, "$name"';

  @override
  String toString() => '$runtimeType$dcm $name $subgroup($subgroupHex), creator'
      '(${creator.name})';

/* Flush if not used
  static PDTagKnown maker(int code, VR vr, PCTag creator,
      PDTagDefinition definition) =>
      new PDTagKnown(code, vr, creator, definition);
*/

}
