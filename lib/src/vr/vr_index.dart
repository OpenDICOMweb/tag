// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'vr.dart';

// Sequence is 0
const int kSQindex = 0;
// Long, possibly undefined
const int kOBindex = 1;
const int kOWindex = 2;
const int kUNindex = 3;
const int kMaybeUndefinedMin = VR.kOB.index;
const int kMaybeUndefinedMax = VR.kUN.index;
// Long EVR
const int kODindex = 4;
const int kOFindex = 5;
const int kOLindex = 6;
const int kUCindex = 7;
const int kURindex = 8;
const int kUTindex = 9;
const int kEvrLongMin = VR.kOD.index;
const int kEvrLongMax = VR.kUT.index;
// Short EVR

const int kAEindex = 10;
const int kASindex = 11;
const int kATindex = 12;
const int kCSindex = 13;
const int kDAindex = 14;
const int kDSindex = 15;
const int kDTindex = 16;
const int kFDindex = 17;
const int kFLindex = 18;
const int kISindex = 19;
const int kLOindex = 20;
const int kLTindex = 21;
const int kPNindex = 22;
const int kSHindex = 23;
const int kSLindex = 24;
const int kSSindex = 25;
const int kSTindex = 26;
const int kTMindex = 27;
const int kUIindex = 28;
const int kULindex = 29;
const int kUSindex = 30;
const int kOBOWindex = 31;
const int kUSSSindex = 32;
const int kUSSSOWindex = 33;
const int kUSOWindex = 34;
