# User preferences

[![pub package](https://img.shields.io/pub/v/user_preferences.svg)](https://pub.dartlang.org/packages/user_preferences)

This is a port of Android SharedPreferences, providing, a persistent store for simple data. Data is persisted to disk 
asynchronously. This package does not guarantee that writes will be persisted to disk after returning and this library 
must not be used for storing critical data.

## Usage
To use this plugin, add `user_preferences` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### Example

``` dart
import 'dart:io';

import 'package:user_preferences/user_preferences.dart';

void main() async {
  // Initialize the default value, after this I can use UserPreferences.instance
  await UserPreferences.init(Directory('/some/directory/that/I/can/use'));

  final String name = UserPreferences.instance.getString('name', 'Mike');
  print('My name is $name/');

  UserPreferences.instance.edit()
    ..putString('name', 'Joe')
    ..apply();
}
```

for flutter you can use it like this:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:user_preferences/user_preferences.dart';

void main() async {
  final Directory baseDir = await getApplicationDocumentsDirectory();
  await UserPreferences.init(baseDir);

  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: RaisedButton(
          onPressed: _incrementCounter,
          child: Text('Increment Counter'),
        ),
      ),
    ),
  ));
}

void _incrementCounter() async {
  UserPreferences prefs = UserPreferences.instance;
  final int counter = (prefs.getInt('counter') ?? 0) + 1;
  print('Pressed $counter times.');

  prefs.edit()
    ..putInt('counter', counter)
    ..apply();
}
```