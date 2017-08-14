// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/system.dart';
import 'package:tag/tag.dart';

class InvalidTagError extends Error {
  Object tag;

  InvalidTagError(this.tag);

  @override
  String toString() => Tag.toMsg(tag);
}

dynamic tagError(Object obj) => throw new InvalidTagError(obj);

//TODO: convert this to handle both int and String and remove next two Errors
class InvalidTagKeyError extends Error {
  dynamic key;
  VR vr;
  String creator;

  InvalidTagKeyError(this.key, [this.vr, this.creator]);

  @override
  String toString() => _msg(key, vr, creator);

  static String _msg(key, VR vr, String creator) =>
      'InvalidTagKeyError: "$_value" $vr creator:"$creator"';

  static String _value(key) {
    if (key == null) return 'null';
    if (key is String) return key;
    if (key is int) return Tag.toDcm(key);
    return key;
  }
}

Null invalidTagKeyError(key, [VR vr, String creator]) {
  log.error(InvalidTagKeyError._msg(key, vr, creator));
  if (throwOnError) throw new InvalidTagKeyError(vr);
  return null;
}

//Flush when replaced with InvalidTagKeyError
class InvalidTagCodeError extends Error {
  int code;

  InvalidTagCodeError(this.code);

  @override
  String toString() => _msg(code);

  static _msg(int code) => 'InvalidTagCodeError: "${_value(code)}"';

  static String _value(code) => (code == null) ? 'null' : Tag.toDcm(code);
}

Null invalidTagCodeError(int code) {
  log.error(InvalidTagCodeError._msg(code));
  if (throwOnError) throw new InvalidTagCodeError(code);
  return null;
}

//Flush when replaced with InvalidTagKeyError
class InvalidTagKeywordError extends Error {
  String keyword;

  InvalidTagKeywordError(this.keyword);

  @override
  String toString() => _msg(keyword);

  static _msg(String keyword) => 'InvalidTagKeywordError: "$keyword"';
}

Null tagKeywordError(String keyword) {
  log.error(InvalidTagKeywordError._msg(keyword));
  if (throwOnError) throw new InvalidTagKeywordError(keyword);
  return null;
}

//TODO: convert this to handle both int and String and remove next two Errors
class InvalidVRError extends Error {
  VR vr;
  String message;

  InvalidVRError(this.vr, [this.message = ""]);

  @override
  String toString() => _msg(vr);

  static String _msg(VR vr, [String message = ""]) =>
      'Error: Invalid VR (Value Representation) "$vr" - $message';
}

Null invalidVRError(VR vr, [String message = ""]) {
  log.error(InvalidVRError._msg(vr, message));
  if (throwOnError) throw new InvalidVRError(vr);
  return null;
}

class InvalidValueFieldLengthError extends Error {
  final Uint8List vfBytes;
  final int elementSize;

  InvalidValueFieldLengthError(this.vfBytes, this.elementSize) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => _msg(vfBytes, elementSize);

  static _msg(Uint8List vfBytes, int elementSize) =>
      'InvalidValueFieldLengthError: lengthInBytes(${vfBytes.length}'
      'elementSize($elementSize)';
}

Null invalidValueFieldLengthError(Uint8List vfBytes, int elementSize) {
  log.error(InvalidValueFieldLengthError._msg(vfBytes, elementSize));
  if (throwOnError)
    throw new InvalidValueFieldLengthError(vfBytes, elementSize);
  return null;
}

class InvalidValuesTypeError extends Error {
  final Tag tag;
  final List values;

  InvalidValuesTypeError(this.tag, this.values) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => _msg(tag, values);

  static String _msg(Tag tag, List values) =>
      'InvalidValuesTypeError:\n  Tag(${tag.info})\n  values: $values';
}

bool invalidValuesTypeError(Tag tag, List values) {
  log.error(InvalidValuesTypeError._msg(tag, values));
  if (throwOnError) throw new InvalidValuesTypeError(tag, values);
  return false;
}

class InvalidValuesLengthError extends Error {
  final Tag tag;
  final List values;

  InvalidValuesLengthError(this.tag, this.values) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => _msg(tag, values);

  static String _msg(Tag tag, List values) =>
      'InvalidValuesLengthError:\n  Tag(${tag.info})\n  values: $values';
}

bool invalidValuesLengthError(Tag tag, List values) {
  log.error(InvalidValuesLengthError._msg(tag, values));
  if (throwOnError) throw new InvalidValuesLengthError(tag, values);
  return false;
}

class InvalidValuesError<V> extends Error {
  final Tag tag;
  final List values;

  InvalidValuesError(this.tag, this.values);

  @override
  String toString() => '${_msg(tag, values)}';

  static String _msg<V>(Tag tag, List<V> values) =>
      'InvalidValuesError: Tag(${tag.info})\n  values: ${values}';
}

Null invalidValuesError<V>(Tag tag, List<V> values) {
  if (log != null) log.error(InvalidValuesError._msg(tag, values));
  if (throwOnError) throw new InvalidValuesError(tag, values);
  return null;
}
