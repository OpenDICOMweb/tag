// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:tag/tag.dart';
import 'package:test/test.dart';

void main() {
  test('VR Index', () {
    expect(VR.kSQ.index == VR.kSQindex, true);
    expect(VR.kSQ.index == 0, true);

    expect(VR.kOB.index == VR.kOBindex, true);
    expect(VR.kOB.index == 1, true);

    expect(VR.kOB.index == VR.kMaybeUndefinedMin, true);
    expect(VR.kOB.index == 1, true);

    expect(VR.kOW.index == VR.kOWindex, true);
    expect(VR.kOW.index == 2, true);

    expect(VR.kUN.index == VR.kUNindex, true);
    expect(VR.kUN.index == 3, true);

    expect(VR.kUN.index == VR.kMaybeUndefinedMax, true);
    expect(VR.kUN.index == 3, true);

    expect(VR.kOD.index == VR.kODindex, true);
    expect(VR.kOD.index == 4, true);

    expect(VR.kOD.index == VR.kEvrLongMin, true);
    expect(VR.kOD.index == 4, true);

    expect(VR.kOF.index == VR.kOFindex, true);
    expect(VR.kOF.index == 5, true);

    expect(VR.kOL.index == VR.kOLindex, true);
    expect(VR.kOL.index == 6, true);

    expect(VR.kUC.index == VR.kUCindex, true);
    expect(VR.kUC.index == 7, true);

    expect(VR.kUR.index == VR.kURindex, true);
    expect(VR.kUR.index == 8, true);

    expect(VR.kUT.index == VR.kUTindex, true);
    expect(VR.kUT.index == 9, true);

    expect(VR.kUT.index == VR.kEvrLongMax, true);
    expect(VR.kUT.index == 9, true);

    expect(VR.kAE.index == VR.kAEindex, true);
    expect(VR.kAE.index == 10, true);

    expect(VR.kAE.index == VR.kEvrShortMin, true);
    expect(VR.kAE.index == 10, true);

    expect(VR.kAS.index == VR.kASindex, true);
    expect(VR.kAS.index == 11, true);

    expect(VR.kAT.index == VR.kATindex, true);
    expect(VR.kAT.index == 12, true);

    expect(VR.kCS.index == VR.kCSindex, true);
    expect(VR.kCS.index == 13, true);

    expect(VR.kDA.index == VR.kDAindex, true);
    expect(VR.kDA.index == 14, true);

    expect(VR.kDS.index == VR.kDSindex, true);
    expect(VR.kDS.index == 15, true);

    expect(VR.kDT.index == VR.kDTindex, true);
    expect(VR.kDT.index == 16, true);

    expect(VR.kFD.index == VR.kFDindex, true);
    expect(VR.kFD.index == 17, true);

    expect(VR.kFL.index == VR.kFLindex, true);
    expect(VR.kFL.index == 18, true);

    expect(VR.kIS.index == VR.kISindex, true);
    expect(VR.kIS.index == 19, true);

    expect(VR.kLO.index == VR.kLOindex, true);
    expect(VR.kLO.index == 20, true);

    expect(VR.kLT.index == VR.kLTindex, true);
    expect(VR.kLT.index == 21, true);

    expect(VR.kPN.index == VR.kPNindex, true);
    expect(VR.kPN.index == 22, true);

    expect(VR.kSH.index == VR.kSHindex, true);
    expect(VR.kSH.index == 23, true);

    expect(VR.kSL.index == VR.kSLindex, true);
    expect(VR.kSL.index == 24, true);

    expect(VR.kSS.index == VR.kSSindex, true);
    expect(VR.kSS.index == 25, true);

    expect(VR.kST.index == VR.kSTindex, true);
    expect(VR.kST.index == 26, true);

    expect(VR.kTM.index == VR.kTMindex, true);
    expect(VR.kTM.index == 27, true);

    expect(VR.kUI.index == VR.kUIindex, true);
    expect(VR.kUI.index == 28, true);

    expect(VR.kUL.index == VR.kULindex, true);
    expect(VR.kUL.index == 29, true);

    expect(VR.kUS.index == VR.kUSindex, true);
    expect(VR.kUS.index == 30, true);

    expect(VR.kUS.index == VR.kEvrShortMax, true);
    expect(VR.kUS.index == 30, true);

    expect(VR.kUS.index == VR.kVRIndexMax, true);
    expect(VR.kUS.index == 30, true);

    expect(VR.kOBOW.index == VR.kOBOWindex, true);
    expect(VR.kOBOW.index == 31, true);

    expect(VR.kOBOW.index == VR.kVRSpecialIndexMin, true);
    expect(VR.kOBOW.index == 31, true);

    expect(VR.kUSSS.index == VR.kUSSSindex, true);
    expect(VR.kUSSS.index == 32, true);

    expect(VR.kUSSSOW.index == VR.kUSSSOWindex, true);
    expect(VR.kUSSSOW.index == 33, true);

    expect(VR.kUSOW.index == VR.kUSOWindex, true);
    expect(VR.kUSOW.index == 34, true);

    expect(VR.kUSOW.index == VR.kVRSpecialIndexMax, true);
    expect(VR.kUSOW.index == 34, true);
  });
}
