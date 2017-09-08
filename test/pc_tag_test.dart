// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:logger/logger.dart';
import 'package:tag/tag.dart';
import 'package:system/server.dart';
import 'package:test/test.dart';

void main() {
  Server.initialize(name: 'pc_tag_test', level: Level.info0);

  test("PrivateCreatorTag ACUSON Test", () {
    PCTag pTag = new PCTag(0x00090010, VR.kUN, "ACUSON");
    expect(pTag is PCTagKnown, true);
    log.debug(pTag.info);
    if (pTag is PCTagDefinition) {
      log.debug('${pTag.name}: ${pTag.dataTags}');
    }
  });

  test("PrivateCreatorTag.unknown Test", () {
    PCTag pTag = new PCTag(0x00090010, VR.kUN, "foo");
    log.debug(pTag.info);
    log.debug('${pTag.name}: ${pTag.dataTags}');
  });

  test("Good CreatorCodeInGroup Test", () {
    List<int> creatorCodes = <int>[0x00090010, 0x001100FF, 0x0035008F];
    List<int> groups = <int>[0x0009, 0x0011, 0x0035];

    for (int i = 0; i < creatorCodes.length; i++) {
      int creator = creatorCodes[i];
      int group = groups[i];
      bool v = Tag.isCreatorCodeInGroup(creator, group);
      log.debug('$v: creator: ${Tag.toDcm(creator)}, '
          'group:  ${Tag.toDcm(group)}');
      expect(v, true);
    }
  });

  test("Bad CreatorCodeInGroup Test", () {
    List<int> creatorCodes = <int>[0x000110010, 0x0011000e, 0x00350008];
    List<int> groups = <int>[0x0009, 0x0011, 0x0035];

    for (int i = 0; i < creatorCodes.length; i++) {
      int creator = creatorCodes[i];
      int group = groups[i];
      bool v = Tag.isCreatorCodeInGroup(creator, group);
      log.debug('$v: creator: ${Tag.toDcm(creator)}, group:  ${Tag.toDcm(group)
      }');
      expect(v, false);
    }
  });

  test("Good isPDataCodeInSubgroup Test", () {
    List<int> codes = <int>[0x00091000, 0x0011FF00, 0x00358FFF];
    List<int> groups = <int>[0x0009, 0x0011, 0x0035];
    List<int> subgroups = <int>[0x10, 0xFF, 0x8F];

    for (int i = 0; i < codes.length; i++) {
      int code = codes[i];
      int group = groups[i];
      int subgroup = subgroups[i];
      bool v = Tag.isPDataCodeInSubgroup(code, group, subgroup);
      log.debug('$v: code: ${Tag.toDcm(code)}, '
          'group:  ${Tag.toDcm(group)}, subgroup:  ${Tag.toDcm(subgroup)}');
      expect(v, true);
    }
  });

  test("Bad isPDatagit CodeInSubgroup Test", () {
    List<int> codes = <int>[0x00111000, 0x0011000e, 0x003508eFF];
    List<int> groups = <int>[0x0009, 0x0011, 0x0035];
    List<int> subgroups = <int>[0x10, 0xFF, 0x8F];

    for (int i = 0; i < codes.length; i++) {
      int code = codes[i];
      int group = groups[i];
      int subgroup = subgroups[i];
      bool v = Tag.isPDataCodeInSubgroup(code, group, subgroup);
      log.debug('$v: code: ${Tag.toDcm(code)}, '
          'group:  ${Tag.toDcm(group)}, subgroup:  ${Tag.toDcm(subgroup)}');
      expect(v, false);
    }
  });
}
