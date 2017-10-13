// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';

typedef List<Element> DeIdMethod<K>(Dataset ds, K key, [Function f]);

//TODO: document
/// A DICOM Data Element Type.  See PS3.5, Section 7.4.
abstract class DeIdOptionBase {
  int get index;
  String get name;
  DeIdMethod get method;


//  static  List<DeIdOptionBase> get kByIndex;

//  static  Map<String, DeIdOptionBase> get kByKeyword;


// static  DeIdOptionBase lookup(int index);


  @override
  String toString() => '$runtimeType($name)';
}
