// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:base/base.dart';
import 'package:tag/src/e_type.dart';
import 'package:tag/src/elt.dart';
import 'package:tag/src/errors.dart';
import 'package:tag/src/group.dart';
import 'package:tag/src/p_tag.dart';
import 'package:tag/src/private/pc_tag.dart';
import 'package:tag/src/private/pd_tag.dart';
import 'package:tag/src/private/private_tag.dart';
import 'package:tag/src/vm.dart';
import 'package:tag/src/vr/vr.dart';

const int kGroupMask = 0xFFFF0000;
const int kElementMask = 0x0000FFFF;

/// //Fix:
/// A [Tag] defines the [Type] of a DICOM Attribute.  There are different
/// types of Tags in the following class hierarchy:
///   Tag <abstract>
///     PTag
///     PTagGroupLength
///     PTagUnknown
///     PrivateTag<abstract>
///       PrivateTagGroupLength
///       PrivateTagIllegal
///       PCTag
///       PCTagUnknown
///       PDTag
///       PDTagUnknown
//TODO: is hashCode needed?
// Fix: make this class abstract
abstract class Tag {
  ///TODO: Tag and Tag.public are inconsistent when new Tag, PrivateTag... files
  ///      are generated make them consistent.
  const Tag();

  /// Returns an appropriate [Tag] based on the arguments.
  static Tag fromCode(int code, VR vr, [dynamic creator]) {
    if (Tag.isPublicCode(code)) return Tag.lookupPublicCode(code, vr);
    if (Tag.isPrivateCreatorCode(code)) return new PCTag(code, vr, creator);
    if (Tag.isPrivateDataCode(code)) return new PDTag(code, vr, creator);
    // This should never happen
    throw 'Error: Unknown Tag Code${Tag.toDcm}';
  }

  //TODO: When regenerating Tag rework constructors as follows:
  // Tag(int code, [vr = VR.kUN, vm = VM.k1_n);
  // Tag._(this.code, this.vr, this.vm, this.keyword, this.name,
  //     [this.isRetired = false, this.type = EType.kUnknown]
  // Tag.const(this.code, this.vr, this.vm, this.keyword, this.name,
  //     [this.isRetired = false, this.type = EType.kUnknown]
  // Tag.private(this.code, this.vr, this.vm, this.keyword, this.name,
  //     [this.isRetired = false, this.type = EType.kUnknown]);
  int get code;
  VR get vr;
  String get keyword => "UnknownTag";
  String get name => "Unknown Tag";
  VM get vm => VM.k1_n;

  bool get isRetired => true;
  EType get type => EType.k3;

  /// Returns [true] if [this] is a [Tag] defined by the DICOM Standard
  /// or one of the known private [Tag]s ([PCTag] or [PDTag]) defined
  /// in the ODW SDK.
  bool get isKnown => keyword != "UnknownTag";

  bool get isUnKnown => !isKnown;

  // **** Code Getters

  /// Returns a [String] for the [code] in DICOM format, i.e. (gggg,eeee).
  String get dcm => '${Tag.toDcm(code)}';

  /// Returns a [String] for the [code] in hexadecimal format, i.e. '0xggggeeee.
  String get hex => hex32(code);

  /// Returns the [group] number for [this] [Tag].
  int get group => code >> 16;

  /// Returns the [group] number for [this] in hexadecimal format.
  String get groupHex => Group.hex(group);

  /// Returns the DICOM element [Elt] number for [this] [Tag].
  int get elt => code & kElementMask;

  /// Returns the DICOM element [Elt] number for [this] in hexadecimal format.
  String get eltHex => Elt.hex(elt);

  // **** VR Getters

  int get vrIndex => vr.index;

  @deprecated
  int get sizeInBytes => elementSize;

  int get elementSize => vr.elementSize;

  @deprecated
  bool get isShort => hasShortVF;

  bool get hasShortVF => vr.hasShortVF;

  bool get hasLongVF => vr.hasLongVF;

  /// Returns the length of a DICOM Element header field.
  /// Used for encoding DICOM media types
  int get dcmHeaderLength => (hasShortVF) ? 8 : 12;

  bool get isAscii => vr.isAscii;
  bool get isUtf8 => vr.isUtf8;

  // **** VM Getters

  /// The minimum number that MUST be present, if any values are present.
  int get minValues => vm.min;

  int get _vfLimit => (vr.hasShortVF) ? kMaxShortVF : kMaxLongVF;

  /// The maximum number that MAY be present, if any values are present.
  int get maxValues => (vm.max != -1) ? vm.max : _vfLimit ~/ vr.minValueLength;

  /// The minimum length of the Value Field.
  int get minVFLength => vm.min * vr.minValueLength;

  /// The maximum length of the Value Field.
  int get maxVFLength {
    // Optimization - for most Tags vm.max == 1
    if (vm.max == 1) return vr.maxValueLength * vr.elementSize;
    if (vm.max == -1) {
      return vr.maxVFLength;
    } else {
      var maxVF = maxValues * vr.maxValueLength;
      return (maxVF > vr.maxVFLength) ? vr.maxVFLength : maxVF;
    }
  }

  //TODO: Validate that the number of values is legal
  //TODO write unit tests to ensure this is correct
  //TODO: make this work for PrivateTags

  /// Returns the maximum number of values allowed for this [Tag].
  /*
  int get maxLength {
    if (vm.max == -1) {
      int max = (vr.hasShortVF) ? kMaxShortVF : kMaxLongVF;
      return max ~/ vr.elementSize;
    }
    return vm.max;
  }
  */

  int get width => vm.width;

  /* TODO: remove when sure they are not used.
  int codeGroup(int code) => code >> 16;

  int codeElt(int code) => code & 0xFFFF;

  bool codeGroupIsPrivate(int code) {
    int g = codeGroup(code);
    return g.isOdd && (g > 0x0008 && g < 0xFFFE);
  }
  */
  int get hashcode => code;

  /// Returns true if the Tag is defined by DICOM, false otherwise.
  /// All DICOM Public tags have group numbers that are even integers.
  /// Note: This only checks that the group number is an even.
  bool get isPublic => code.isEven;

  bool get isPrivate => false;

  bool get isCreator => false;

  //bool get isPrivateCreator => false;
  bool get isPrivateData => false;

  int get fmiMin => kMinFmiTag;

  int get fmiMax => kMaxFmiTag;

  /// Returns [true] if the [group] is in the File Meta Information group.
  bool get isFmiGroup => group == 0x0002;

  /// Returns [true] if [code] is in the range of File Meta Information
  /// [Tag] [code]s.
  ///
  /// Note: Does not test tag validity.
  bool get inFmiRange => kMinFmiTag <= code && code <= kMaxFmiTag;

  int get dcmDirMin => kMinDcmDirTag;

  int get dcmDirMax => kMaxDcmDirTag;

  /// Returns [true] if [code] is in the range of DICOM Directory [Tag] [code]s.
  ///
  /// Note: Does not test tag validity.
  bool get isDcmDir => kMinDcmDirTag <= code && code <= kMaxDcmDirTag;

  /// Returns [true] if [code] is in the range of DICOM Directory
  /// [Tag] [code]s.
  ///
  /// Note: Does not test tag validity.
  bool get inDcmDirRange => kMinDcmDirTag <= code && code <= kMaxDcmDirTag;

  String get info {
    String retired = (isRetired) ? '- Retired' : '';
    return '$runtimeType$dcm $vr $vm $keyword $retired';
  }

  /// Returns [true] is [this] is a valid [Tag].
  /// Valid [Tag]s are those defined in PS3.6 and Private [Tag]s that
  /// conform to the DICOM Standard.
  bool get isValid => false;

  /// Returns True if [vList].length, i.e. is valid for this [Tag].
  ///
  /// _Note_: A length of zero is always valid.
  ///
  /// [min]: The minimum number of values.
  /// [max]: The maximum number of values. If -1 then max length of
  ///     Value Field; otherwise, must be greater than or equal to [min].
  /// [width]: The [width] of the matrix of values. If [width == 0,
  /// then singleton; otherwise must be greater than 0;
  //TODO: should be modified when EType info is available.
  bool hasValidValues<V>(List<V> vList, [bool throwOnError = false]) {
    if (vr == VR.kUN) return true;
    if (vList == null) return false;
    if (!isValidValuesType(vList))
      return invalidValuesTypeError(this, vList);
    if (isNotValidLength(vList.length))
      return invalidValuesLengthError(this, vList);
    for (int i = 0; i < vList.length; i++)
      if (isNotValidValue(vList[i])) {
        invalidValuesError(this, vList);
        return false;
      }
    return true;
  }

  bool isValidValuesType<V>(List<V> values) => vr.isValidValuesType(values);

/*  bool isValidElement(Element e) {
    if (e == null) return false;
    return hasValidValues(e.values);
  }*/

/* Flush when working
  bool hasValidValues<V>(List<V> values) {
    assert(values != null);
    //   if (values == null) return false;
    if (vr == VR.kUN) return true;
    if (isNotValidLength(values.length)) return false;
    for (int i = 0; i < values.length; i++)
      if (isNotValidValue(values[i])) return false;
    return true;
  }
*/

  bool isValidValue<V>(V value) => vr.isValid(value);
  bool isNotValidValue<V>(V value) => vr.isNotValid(value);

  /// Returns a [list<E>] of valid values for this [Tag], or [null] if
  /// and of the [String]s in [sList] are not parsable.
  List<E> parseValues<E>(List<String> sList) {
    //print('parseList: $sList');
    if (isNotValidLength(sList.length)) return null;
    List<E> values = new List<E>(sList.length);
    for (int i = 0; i < values.length; i++) {
      //log.debug('sList[$i]: ${sList[i]}');
      E v = vr.parse(sList[i]);
      //log.debug('v: $v');
      if (v == null) return null;
      values[i] = v;
    }
    return values;
  }

  // If a VR has a long Value Field, then it has [VM.k1],
  // and its length is always valid.
  String lengthIssue(int length) => (vr.hasShortVF && isNotValidLength(length))
      ? 'Invalid Length: min($minValues) <= value($length) <= max($maxValues)'
      : null;

  //TODO: make this work with [ParseIssues]
  List<String> issues<E>(List<E> values) {
    print('issues: $values');
    List<String> sList = [];
    for (int i = 0; i < values.length; i++) {
      var s = vr.issues(values[i]);
      if (s != null) sList.add('$i: $s');
    }
    return sList;
  }

  List<V> checkValues<V>(List<V> values) =>
      (hasValidValues(values)) ? values : null;

  // Placeholder until VR is integrated into TagBase
  List<E> checkValue<E>(dynamic value) => vr.isValid(value) ? value : null;

  /// Returns [true] if [length] is a valid number of values for [this].
  bool isValidLength(int length) {
    // If a VR has a long Value Field, then it has [VM.k1], and its length is always valid.
    if (vr.isLengthAlwaysValid == true) return true;
    // These are the most common cases.
    if (length == 0 || (length == 1 && width == 0)) return true;
    return length >= minValues && length <= maxValues && (length % width) == 0;
  }

  bool isValidWidth(int length) => width == 0 || (length % width) == 0;

  bool isNotValidLength(int length) => !isValidLength(length);

  int checkLength(int length) => (isValidLength(length)) ? length : null;

  //Flush?
  String widthError(int length) => 'Invalid Width for Tag$dcm}: '
      'values length($length) is not a multiple of vmWidth($width)';

  //Flush?
  String lengthError(int length) =>
      'Invalid Length: min($minValues) <= length($length) <= max($maxValues)';

  bool isValidVFLength(int lengthInBytes) =>
      (lengthInBytes >= minVFLength && lengthInBytes <= maxVFLength);

  Uint8List checkVFLength(Uint8List bytes) =>
      (isValidVFLength(bytes.length)) ? bytes : null;

  //Fix or Flush
  //Uint8List checkBytes(Uint8List bytes) => vr.checkBytes(bytes);

  E parse<E>(String s) => vr.parse(s);

  /// Converts a DICOM [keyword] to the equivalent DICOM name.
  ///
  /// Given a keyword in camelCase, returns a [String] with a
  /// space (' ') inserted before each uppercase letter.
  ///
  /// Note: This algorithm does not return the exact DICOM name string,
  /// for example some names have apostrophes ("'") in them,
  /// but they are not in the [keyword]. Also, all dashes ('-') in
  /// keywords have been converted to underscores ('_'), because
  /// dashes are illegal in Dart identifiers.
  String keywordToName(String keyword) {
    List<int> kw = keyword.codeUnits;
    List<int> name = new List<int>();
    name[0] = kw[0];
    for (int i = 0; i < kw.length; i++) {
      int char = kw[i];
      if (isUppercaseChar(char)) name.add(kSpace);
      name.add(char);
    }
    return UTF8.decode(name);
  }

  String stringToKeyword(String s) {
    s = s.replaceAll(' ', '_');
    s = s.replaceAll('-', '_');
    s = s.replaceAll('.', '_');
    return s;
  }

  @override
  String toString() {
    String retired = (isRetired == false) ? "" : ", (Retired)";
    return '$runtimeType: $dcm $keyword, $vr, $vm$retired';
  }

  static Tag lookup(dynamic key, [VR vr = VR.kUN, dynamic creator]) {
    if (key is int) return lookupByCode(key, vr, creator);
    if (key is String) return lookupByKeyword(key, vr, creator);
    return invalidTagKeyError(key, vr, creator);
  }

  //TODO: redoc
  /// Returns an appropriate [Tag] based on the arguments.
  static Tag lookupByCode(int code, [VR vr = VR.kUN, dynamic creator]) {
    if (Tag.isPublicCode(code)) return Tag.lookupPublicCode(code, vr);
    if (Tag.isPrivateCode(code)) {
      if (Tag.isPrivateGroupLengthCode(code))
        return new PrivateTagGroupLength(code, vr);
      if (Tag.isPrivateCreatorCode(code)) return new PCTag(code, vr, creator);
      if (Tag.isPrivateDataCode(code)) return new PDTag(code, vr, creator);
      throw 'Error: Unknown Private Tag Code${Tag.toDcm(code)}';
    } else {
      // This should never happen
      return invalidTagCodeError(code);
    }
  }

  static Tag lookupByKeyword(String keyword,
      [VR vr = VR.kUN, dynamic creator]) {
/*    Tag tag = Tag.lookupKeyword(keyword, vr);
    if (tag != null) return tag;
    tag = Tag.lookupPrivateCreatorKeyword(keyword, vr) {
      if (Tag.isPrivateGroupLengthKeyword(keyword))
        return new PrivateGroupLengthTagFromKeyword(keyword, vr);
      if (Tag.isPrivateCreatorKeyword(keyword))
        return new PCTag.keyword(keyword, vr, creator);
      if (Tag.isPrivateDataKeyword(keyword))
        return new PDTag.keyword(keyword, vr, creator);
      throw 'Error: Unknown Private Tag Code$keyword';
    } else {
      // This should never happen
      //throw 'Error: Unknown Tag Code${Tag.toDcm(code)}';
      return null;
    }*/
    throw new UnimplementedError();
  }

  //TODO: Use the 'package:collection/collection.dart' ListEquality
  //TODO:  decide if this ahould be here
  /// Compares the elements of two [List]s and returns [true] if all
  /// elements are equal; otherwise, returns [false].
  /// Note: this is not recursive!
  static bool listEquals<E>(List<E> e1, List<E> e2) {
    if (identical(e1, e2)) return true;
    if (e1 == null || e2 == null) return false;
    if (e1.length != e2.length) return false;
    for (int i = 0; i < e1.length; i++) if (e1[i] != e2[i]) return false;
    return true;
  }

  //TODO: needed or used?
  static Tag lookupPublicCode(int code, VR vr) {
    Tag tag = PTag.lookupByCode(code, vr);
    if (tag != null) return tag;
    if (Tag.isPublicGroupLengthCode(code)) return new PTagGroupLength(code);
    return new PTagUnknown(code, vr);
  }

  static Tag lookupPublicKeyword(String keyword, VR vr) {
    Tag tag = PTag.lookupByKeyword(keyword, vr);
    if (tag != null) return tag;
    if (Tag.isPublicGroupLengthKeyword(keyword))
      return new PTagGroupLength.keyword(keyword);
    return new PTagUnknown.keyword(keyword, vr);
  }

  static Tag lookupPrivateCreatorCode(int code, VR vr, String token) {
    if (Tag.isPrivateGroupLengthCode(code))
      return new PrivateTagGroupLength(code, vr);
    if (isPrivateCreatorCode(code)) return new PCTag(code, vr, token);
    throw new InvalidTagCodeError(code);
  }

/*  static PDTagKnown lookupPrivateDataCode(
      int code, VR vr, PCTag creator) =>
      (creator is PCTagKnown) ? creator.lookupData(code)
          : new PDTagUnknown(code, vr, creator);
  */


  /// Returns a [String] corresponding to [tag], which might be an
  /// [int], [String], or [Tag].
  static String toMsg(dynamic tag) {
    String msg;
    if (tag is int) {
      msg = 'Code ${Tag.toDcm(tag)}';
    } else if (tag is String) {
      msg = 'Keyword "$tag"';
    } else {
      msg = '${tag.runtimeType}: $tag';
    }
    return '$msg';
  }

  static List<String> lengthChecker(
      List values, int minLength, int maxLength, int width) {
    int length = values.length;
    // These are the most common cases.
    if (length == 0 || (length == 1 && width == 0)) return null;
    List<String> msgs;
    if (length % width != 0)
      msgs = ['Invalid Length($length) not a multiple of vmWidth($width)'];
    if (length < minLength) {
      var msg = 'Invalid Length($length) less than minLength($minLength)';
      msgs = msgs ??= [];
      msgs.add(msg);
    }
    if (length > maxLength) {
      var msg = 'Invalid Length($length) greater than maxLength($maxLength)';
      msgs = msgs ??= [];
      msgs.add(msg); //TODO: test Not sure this is working
    }
    return (msgs == null) ? null : msgs;
  }

  // *** Private Tag Code methods
  static bool isPrivateCode(int code) => Group.isPrivate(Group.fromTag(code));

  static bool isPublicCode(int code) => Group.isPublic(Group.fromTag(code));

  static bool isGroupLengthCode(int code) => Elt.fromTag(code) == 0;

  static bool isPublicGroupLengthCode(int code) =>
      Group.isPublic(Group.fromTag(code)) && Elt.fromTag(code) == 0;

  static bool isPublicGroupLengthKeyword(String keyword) =>
      keyword == 'PublicGroupLengthKeyword' ||
      isPublicGroupLengthKeywordCode(keyword);

  //TODO: test - needs to handle 'oxGGGGEEEE' and 'GGGGEEEE'
  static bool isPublicGroupLengthKeywordCode(String keywordCode) {
    int code = int.parse(keywordCode, radix: 16, onError: (String s) => null);
    return (Elt.fromTag(code) == 0) ? true : false;
  }

  /// Returns true if [code] is a valid Private Creator Code.
  static bool isPrivateCreatorCode(int code) =>
      isPrivateCode(code) && Elt.isPrivateCreator(Elt.fromTag(code));

  static bool isCreatorCodeInGroup(int code, int group) {
    int g = group << 16;
    return (code >= (g + 0x10)) && (code <= (g + 0xFF));
  }

  static bool isPDataCodeInSubgroup(int code, int group, int subgroup) {
    int sg = (group << 16) + (subgroup << 8);
    return (code >= sg && (code <= (sg + 0xFF)));
  }

  static bool isPrivateDataCode(int code) =>
      Group.isPrivate(Group.fromTag(code)) &&
      Elt.isPrivateData(Elt.fromTag(code));

  static int privateCreatorBase(int code) => Elt.pcBase(Elt.fromTag(code));

  static int privateCreatorLimit(int code) => Elt.pcLimit(Elt.fromTag(code));

  static bool isPrivateGroupLengthCode(int code) =>
      Group.isPrivate(Group.fromTag(code)) && Elt.fromTag(code) == 0;

  /// Returns true if [pd] is a valid Private Data Code for the
  /// [pc] the Private Creator Code.
  ///
  /// If the [PCTag ]is present, verifies that [pd] and [pc]
  /// have the same [group], and that [pd] has a valid [Elt].
  static bool isValidPrivateDataTag(int pd, int pc) {
    int pdg = Group.checkPrivate(Group.fromTag(pd));
    int pcg = Group.checkPrivate(Group.fromTag(pc));
    if (pdg == null || pcg == null || pdg != pcg) return false;
    return Elt.isValidPrivateData(Elt.fromTag(pd), Elt.fromTag(pc));
  }

  //**** Private Tag Code "Constructors" ****
  static bool isPCIndex(int pcIndex) => 0x0010 <= pcIndex && pcIndex <= 0x00FF;

  /// Returns a valid [PCTag], or [null].
  static int toPrivateCreator(int group, int pcIndex) {
    if (Group.isPrivate(group) && _isPCIndex(pcIndex))
      return _toPrivateCreator(group, pcIndex);
    return null;
  }

  /// Returns a valid [PDTagKnown], or [null].
  static int toPrivateData(int group, int pcIndex, int pdIndex) {
    if (Group.isPrivate(group) &&
        _isPCIndex(pcIndex) &&
        _isPDIndex(pcIndex, pdIndex))
      return _toPrivateData(group, pcIndex, pcIndex);
    return null;
  }

  /// Returns a [PCTag], without checking arguments.
  static int _toPrivateCreator(int group, int pcIndex) =>
      (group << 16) + pcIndex;

  /// Returns a [PDTagKnown], without checking arguments.
  static int _toPrivateData(int group, int pcIndex, int pdIndex) =>
      (group << 16) + (pcIndex << 8) + pdIndex;

  // **** Private Tag Code Internal Utility functions ****

  /// Return [true] if [pdCode] is a valid Private Creator Index.
  static bool _isPCIndex(int pdCode) => 0x10 <= pdCode && pdCode <= 0xFF;

  // Returns [true] if [pde] in a valid Private Data Index
  //static bool _isSimplePDIndex(int pde) => 0x1000 >= pde && pde <= 0xFFFF;

  /// Return [true] if [pdi] is a valid Private Data Index.
  static bool _isPDIndex(int pci, int pdi) =>
      _pdBase(pci) <= pdi && pdi <= _pdLimit(pci);

  /// Returns the offset base for a Private Data Element with the
  /// Private Creator [pcIndex].
  static int _pdBase(int pcIndex) => pcIndex << 8;

  /// Returns the limit for a [PDTagKnown] with a base of [pdBase].
  static int _pdLimit(int pdBase) => pdBase + 0x00FF;

  /// Returns [true] if [tag] is in the range of DICOM Dataset Tags.
  /// Note: Does not test tag validity.
  static bool inDatasetRange(int tag) =>
      (kMinDatasetTag <= tag) && (tag <= kMaxDatasetTag);

  static void checkDatasetRange(int tag) {
    if (!inDatasetRange(tag)) rangeError(tag, kMinDatasetTag, kMaxDatasetTag);
  }

  /// Returns [code] in DICOM format '(gggg,eeee)'.
  static String toHex(int code) => hex32(code);

  /// Returns [code] in DICOM format '(gggg,eeee)'.
  static String toDcm(int code) {
    if (code == null) return '"null"';
    return '(${Group.hex(Group.fromTag(code), "")},'
        '${Elt.hex(Elt.fromTag(code), "")})';
  }

  /// Returns a [List] of DICOM tag codes in '(gggg,eeee)' format
  static Iterable<String> listToDcm(List<int> tags) => tags.map(toDcm);

  /// Takes a [String] in format "(gggg,eeee)" and returns [int].
  static int toInt(String s) {
    String tmp = s.substring(1, 5) + s.substring(6, 10);
    return int.parse(tmp, radix: 16);
  }

  static bool rangeError(int tag, int min, int max) {
    String msg = 'Invalid tag: $tag not in $min <= x <= $max';
    throw new RangeError(msg);
  }
}
