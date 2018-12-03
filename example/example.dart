// File created by
// Lung Razvan <long1eu>
// on 2018-12-03

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
