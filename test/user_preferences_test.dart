// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_as

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:user_preferences/user_preferences.dart';

void main() {
  final String path = '${Directory.current.path}/build/prefs.json';
  const Map<String, dynamic> kTestValues = <String, dynamic>{
    'dart.String': 'hello world',
    'dart.bool': true,
    'dart.int': 42,
    'dart.double': 3.14159,
    'dart.List': <String>['foo', 'bar'],
  };

  const Map<String, dynamic> kTestValues2 = <String, dynamic>{
    'dart.String': 'goodbye world',
    'dart.bool': false,
    'dart.int': 1337,
    'dart.double': 2.71828,
    'dart.List': <String>['baz', 'quox'],
  };

  const String testContents =
      '''{"String": "hello world", "bool": true, "int": 42, "double": 3.14159, "List": ["foo", "bar"]}''';

  test('reading', () async {
    File(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(testContents);

    final UserPreferences preferences = await UserPreferences.getInstance(path);

    expect(preferences.getString('String'), kTestValues['dart.String']);
    expect(preferences.getBool('bool'), kTestValues['dart.bool']);
    expect(preferences.getInt('int'), kTestValues['dart.int']);
    expect(preferences.getDouble('double'), kTestValues['dart.double']);
    expect(preferences.getStringList('List'), kTestValues['dart.List']);
  });

  test('writing', () async {
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }

    final UserPreferences preferences = await UserPreferences.getInstance(path);

    final List<String> values = <String>[];
    preferences.onChange.listen(values.add);

    final Editor editor = preferences.edit()
      ..putString('String', kTestValues2['dart.String'] as String)
      ..putBool('bool', kTestValues2['dart.bool'] as bool)
      ..putInt('int', kTestValues2['dart.int'] as int)
      ..putDouble('double', kTestValues2['dart.double'] as double)
      ..putStringList('List', kTestValues2['dart.List'] as List<String>);

    await editor.commit();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    expect(values,
        containsAll(<String>['String', 'bool', 'int', 'double', 'List']));

    expect(preferences.getString('String'), kTestValues2['dart.String']);
    expect(preferences.getBool('bool'), kTestValues2['dart.bool']);
    expect(preferences.getInt('int'), kTestValues2['dart.int']);
    expect(preferences.getDouble('double'), kTestValues2['dart.double']);
    expect(preferences.getStringList('List'), kTestValues2['dart.List']);
  });

  test('removing', () async {
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }
    File(path).writeAsStringSync(testContents);

    final UserPreferences preferences = await UserPreferences.getInstance(path);

    const String key = 'testKey';
    preferences.edit()
      ..putString(key, null)
      ..putBool(key, null)
      ..putInt(key, null)
      ..putDouble(key, null)
      ..putStringList(key, null)
      ..apply();

    await Future<void>.delayed(const Duration(seconds: 1));

    expect(preferences.all, hasLength(5));
    expect(preferences.all, jsonDecode(testContents));

    preferences.edit()
      ..putString('String', null)
      ..apply();
    expect(preferences.all, hasLength(4));

    preferences.edit()
      ..remove('bool')
      ..apply();
    expect(preferences.all, hasLength(3));
  });

  test('clearing', () async {
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }
    File(path).writeAsStringSync(testContents);
    final UserPreferences preferences = await UserPreferences.getInstance(path);

    await (preferences.edit()..clear()).commit();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    expect(preferences.getString('String'), null);
    expect(preferences.getBool('bool'), null);
    expect(preferences.getInt('int'), null);
    expect(preferences.getDouble('double'), null);
    expect(preferences.getStringList('List'), null);
  });
}
