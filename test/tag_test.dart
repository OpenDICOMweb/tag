// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:system/server.dart';
import 'package:tag/tag.dart';
import 'package:test/test.dart';

List<int> tags = const [
  kSpecificCharacterSet,
  kLanguageCodeSequence,
  kImageType,
  kInstanceCreationDate,
  kInstanceCreationTime,
  kDataSetType,
  kSimpleFrameList,
  kRecommendedDisplayFrameRateInFloat,
  kEventTimeOffset,
  kTagAngleSecondAxis,
  kReferencePixelX0,
  kVectorGridData
];

/// Test the Tag Class
void main() {
  Server.initialize(name: 'tag_test', level: Level.debug);

  test('Simple Tag Test', () {
    for (int i = 0; i < tags.length; i++) {
      Tag tag = PTag.lookupByCode(tags[i], VR.kUN);
      log.debug('${tag.info}');
      log.debug(
          'isShort: ${tag.hasShortVF}, sizeInBytes: ${tag.vr.elementSize}');
      log.debug(
          'min: ${tag.minValues}, max: ${tag.maxValues}, width: ${tag.width}');
    }
  });
}
