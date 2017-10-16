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

  static String _msg<K>(Object tag) => 'InvalidTagError: $tag';
}

Null invalidTagError(Object obj) {
  log.error(InvalidTagKeyError._msg(obj));
  if (throwOnError) throw new InvalidTagError(obj);
  return null;
}

//TODO: convert this to handle both int and String and remove next two Errors
class InvalidTagKeyError<K> extends Error {
  K key;
  VR vr;
  String creator;

  InvalidTagKeyError(this.key, [this.vr, this.creator]);

  @override
  String toString() => _msg(key, vr, creator);

  static String _msg<K>(K key, [VR vr, String creator]) =>
      'InvalidTagKeyError: "$_value" $vr creator:"$creator"';

  static String _value(Object key) {
    if (key == null) return 'null';
    if (key is String) return key;
    if (key is int) return Tag.toDcm(key);
    return key;
  }
}

Null invalidTagKey<K>(K key, [VR vr, String creator]) {
  log.error(InvalidTagKeyError._msg(key, vr, creator));
  if (throwOnError) throw new InvalidTagKeyError(key);
  return null;
}

//Flush when replaced with InvalidTagKeyError
class InvalidTagCodeError extends Error {
  int code;
  String msg;

  InvalidTagCodeError(this.code, [this.msg]);

  @override
  String toString() => _msg(code, msg);

  static String _msg(int code, String msg) =>
      'InvalidTagCodeError: "${_value(code)}": $msg';

  static String _value(int code) => (code == null) ? 'null' : Tag.toDcm(code);
}

Null invalidTagCode(int code, [String msg]) {
  log.error(InvalidTagCodeError._msg(code, msg));
  if (throwOnError) throw new InvalidTagCodeError(code, msg);
  return null;
}

//Flush when replaced with InvalidTagKeyError
class InvalidTagKeywordError extends Error {
  String keyword;

  InvalidTagKeywordError(this.keyword);

  @override
  String toString() => _msg(keyword);

  static String _msg(String keyword) => 'InvalidTagKeywordError: "$keyword"';
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

  InvalidVRError(this.vr, [this.message = '']);

  @override
  String toString() => _msg(vr);

  static String _msg(VR vr, [String message = '']) =>
      'Error: Invalid VR (Value Representation) "$vr" - $message';
}

Null invalidVRError(VR vr, [String message = '']) {
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

  static String _msg(Uint8List vfBytes, int elementSize) =>
      'InvalidValueFieldLengthError: lengthInBytes(${vfBytes.length}'
      'elementSize($elementSize)';
}

Null invalidValueFieldLengthError(Uint8List vfBytes, int elementSize) {
  log.error(InvalidValueFieldLengthError._msg(vfBytes, elementSize));
  if (throwOnError) throw new InvalidValueFieldLengthError(vfBytes, elementSize);
  return null;
}

class InvalidValuesTypeError<V> extends Error {
  final Tag tag;
  final Iterable<V> values;

  InvalidValuesTypeError(this.tag, this.values) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => _msg(tag, values);

  static String _msg<V>(Tag tag, Iterable<V> values) =>
      'InvalidValuesTypeError:\n  Tag(${tag.info})\n  values: $values';
}

Null invalidValuesTypeError<V>(Tag tag, Iterable<V> values) {
  log.error(InvalidValuesTypeError._msg(tag, values));
  if (throwOnError) throw new InvalidValuesTypeError(tag, values);
  return null;
}

class InvalidValuesLengthError<V> extends Error {
  final Tag tag;
  final Iterable<V> values;

  InvalidValuesLengthError(this.tag, this.values) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => _msg(tag, values);

  static String _msg<V>(Tag tag, Iterable<V> values) =>
      'InvalidValuesLengthError:\n  Tag(${tag.info})\n  values: $values';
}

Null invalidValuesLengthError<V>(Tag tag, Iterable<V> values, [Issues issues]) {
	final msg = InvalidValuesLengthError._msg(tag, values);
  log.error(msg);
  if (issues != null) issues.add(msg);
  if (throwOnError) throw new InvalidValuesLengthError(tag, values);
  return null;
}

class InvalidValuesError<V> extends Error {
  final Tag tag;
  final Iterable<V> values;

  InvalidValuesError(this.tag, this.values);

  @override
  String toString() => '${_msg(tag, values)}';

  static String _msg<V>(Tag tag, Iterable<V> values) =>
      'InvalidValuesError: ${tag.info}\n  values: $values';
}

Null invalidValuesError<V>(Tag tag, Iterable<V> values) {
  if (log != null) log.error(InvalidValuesError._msg<V>(tag, values));
  if (throwOnError) throw new InvalidValuesError<V>(tag, values);
  return null;
}

/// An invalid DICOM Group number [Error].
/// Note: Don't use this directly, use [invalidGroupError] instead.
class InvalidGroupError extends Error {
  int group;

  InvalidGroupError(this.group);

  @override
  String toString() => _msg(group);

  static String _msg(int group) => 'Invalid DICOM Group Error: ${hex16(group)}';
}

Null invalidGroupError(int group) {
  if (log != null) log.error(InvalidGroupError._msg(group));
  if (throwOnError) throw new InvalidGroupError(group);
  return null;
}
