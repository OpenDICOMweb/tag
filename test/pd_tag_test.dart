// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.

import 'package:logger/logger.dart';
import 'package:tag/tag.dart';
import 'package:test/test.dart';

final Logger log = new Logger('DateTimeTests', Level.debug);

void main() {
  privateDataTag();
}

void privateDataTag() {
  test("PrivatedataTag Test", () {
    int code = 0x00190010;
    var pcTag = new PCTag(code, VR.kLO, "Unknown");
    PDTag pdt = new PDTag(code, VR.kUN, pcTag);
    expect((pdt.isPrivate), true);
    expect((pdt.isCreator), false);
    log.debug(pdt.toString());
  });
}
