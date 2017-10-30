// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.

// Sequence is 0
const int kSQindex = 0;

// Long, Maybe Undefined
const int kOBindex = 1; // Maybe Undefined Min
const int kOWindex = 2;
const int kUNindex = 3; // Maybe Undefined Max

// Long EVR
const int kODindex = 4; // Long EVR and IVR Min
const int kOFindex = 5;
const int kOLindex = 6;
const int kUCindex = 7;
const int kURindex = 8;
const int kUTindex = 9; // Long EVR Max

// Short EVR
const int kAEindex = 10; // Short IVR Min
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
const int kUSindex = 30; // Short EVR Max and IVR Max
const int kOBOWindex = 31;
const int kUSSSindex = 32;
const int kUSSSOWindex = 33;
const int kUSOWindex = 34;

const int kVRIndexMin = 0;
const int kVRMaybeUndefinedIndexMin = 1; // OB
const int kVRMaybeUndefinedIndexMax = 3; // UN

const int kVRIvrIndexMin = 4; // OD
const int kVRIvrIndexMax = 30; // US

const int kVREvrLongIndexMin = 4; // OD
const int kVREvrLongIndexMax = 9; // UT
const int kVREvrShortIndexMin = 10; // AE
const int kVREvrShortIndexMax = 30; // US

const int kVRSpecialIndexMin = 31; // OBOW
const int kVRSpecialIndexMax = 34; // USOW

const int kVRNormalIndexMin = 0; // SQ
const int kVRNormalIndexMax = 30; // US

// Const [VR.code]s as 16-bit values

const int kAE = 0x4541;
const int kAS = 0x5341;
const int kAT = 0x5441;
const int kCS = 0x5343;
const int kDA = 0x4144;
const int kDS = 0x5344;
const int kDT = 0x5444;
const int kFD = 0x4446;
const int kFL = 0x4c46;
const int kIS = 0x5349;
const int kLO = 0x4f4c;
const int kLT = 0x544c;
const int kOB = 0x424f;
const int kOD = 0x444f;
const int kOF = 0x464f;
const int kOL = 0x4c4f;
const int kOW = 0x574f;
const int kPN = 0x4e50;
const int kSH = 0x4853;
const int kSL = 0x4c53;
const int kSQ = 0x5153;
const int kSS = 0x5353;
const int kST = 0x5453;
const int kTM = 0x4d54;
const int kUC = 0x4355;
const int kUI = 0x4955;
const int kUL = 0x4c55;
const int kUN = 0x4e55;
const int kUR = 0x5255;
const int kUS = 0x5355;
const int kUT = 0x5455;
