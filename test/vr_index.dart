// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:tag/src/vr/constants.dart';
import 'package:tag/tag.dart';
import 'package:test/test.dart';

void main() {
  test('VR Index', () {
    expect(VR.kSQ.index == kSQindex, true);
    expect(VR.kSQ.index == 0, true);

    expect(VR.kOB.index == kOBindex, true);
    expect(VR.kOB.index == 1, true);

    expect(VR.kOB.index == VR.kMaybeUndefinedMin, true);
    expect(VR.kOB.index == 1, true);

    expect(VR.kOW.index == kOWindex, true);
    expect(VR.kOW.index == 2, true);

    expect(VR.kUN.index == kUNindex, true);
    expect(VR.kUN.index == 3, true);

    expect(VR.kUN.index == VR.kMaybeUndefinedMax, true);
    expect(VR.kUN.index == 3, true);

    expect(VR.kOD.index == kODindex, true);
    expect(VR.kOD.index == 4, true);

    expect(VR.kOD.index == VR.kEvrLongMin, true);
    expect(VR.kOD.index == 4, true);

    expect(VR.kOF.index == kOFindex, true);
    expect(VR.kOF.index == 5, true);

    expect(VR.kOL.index == kOLindex, true);
    expect(VR.kOL.index == 6, true);

    expect(VR.kUC.index == kUCindex, true);
    expect(VR.kUC.index == 7, true);

    expect(VR.kUR.index == kURindex, true);
    expect(VR.kUR.index == 8, true);

    expect(VR.kUT.index == kUTindex, true);
    expect(VR.kUT.index == 9, true);

    expect(VR.kUT.index == VR.kEvrLongMax, true);
    expect(VR.kUT.index == 9, true);

    expect(VR.kAE.index == kAEindex, true);
    expect(VR.kAE.index == 10, true);

    expect(VR.kAE.index == VR.kEvrShortMin, true);
    expect(VR.kAE.index == 10, true);

    expect(VR.kAS.index == kASindex, true);
    expect(VR.kAS.index == 11, true);

    expect(VR.kAT.index == kATindex, true);
    expect(VR.kAT.index == 12, true);

    expect(VR.kCS.index == kCSindex, true);
    expect(VR.kCS.index == 13, true);

    expect(VR.kDA.index == kDAindex, true);
    expect(VR.kDA.index == 14, true);

    expect(VR.kDS.index == kDSindex, true);
    expect(VR.kDS.index == 15, true);

    expect(VR.kDT.index == kDTindex, true);
    expect(VR.kDT.index == 16, true);

    expect(VR.kFD.index == kFDindex, true);
    expect(VR.kFD.index == 17, true);

    expect(VR.kFL.index == kFLindex, true);
    expect(VR.kFL.index == 18, true);

    expect(VR.kIS.index == kISindex, true);
    expect(VR.kIS.index == 19, true);

    expect(VR.kLO.index == kLOindex, true);
    expect(VR.kLO.index == 20, true);

    expect(VR.kLT.index == kLTindex, true);
    expect(VR.kLT.index == 21, true);

    expect(VR.kPN.index == kPNindex, true);
    expect(VR.kPN.index == 22, true);

    expect(VR.kSH.index == kSHindex, true);
    expect(VR.kSH.index == 23, true);

    expect(VR.kSL.index == kSLindex, true);
    expect(VR.kSL.index == 24, true);

    expect(VR.kSS.index == kSSindex, true);
    expect(VR.kSS.index == 25, true);

    expect(VR.kST.index == kSTindex, true);
    expect(VR.kST.index == 26, true);

    expect(VR.kTM.index == kTMindex, true);
    expect(VR.kTM.index == 27, true);

    expect(VR.kUI.index == kUIindex, true);
    expect(VR.kUI.index == 28, true);

    expect(VR.kUL.index == kULindex, true);
    expect(VR.kUL.index == 29, true);

    expect(VR.kUS.index == kUSindex, true);
    expect(VR.kUS.index == 30, true);

    expect(VR.kUS.index == VR.kEvrShortMax, true);
    expect(VR.kUS.index == 30, true);

    expect(VR.kUS.index == VR.kNormalIndexMax, true);
    expect(VR.kUS.index == 30, true);

    expect(VR.kOBOW.index == kOBOWindex, true);
    expect(VR.kOBOW.index == 31, true);

    expect(VR.kOBOW.index == VR.kSpecialIndexMin, true);
    expect(VR.kOBOW.index == 31, true);

    expect(VR.kUSSS.index == kUSSSindex, true);
    expect(VR.kUSSS.index == 32, true);

    expect(VR.kUSSSOW.index == kUSSSOWindex, true);
    expect(VR.kUSSSOW.index == 33, true);

    expect(VR.kUSOW.index == kUSOWindex, true);
    expect(VR.kUSOW.index == 34, true);

    expect(VR.kUSOW.index == VR.kSpecialIndexMax, true);
    expect(VR.kUSOW.index == 34, true);
  });
}
