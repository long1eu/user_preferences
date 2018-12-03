// File created by
// Lung Razvan <long1eu>
// on 16/09/2018

// ignore_for_file: avoid_classes_with_only_static_members, always_specify_types
// ignore_for_file: avoid_annotating_with_dynamic

/// API for sending log output.
class Log {
  /// Send an INFO log message.
  ///
  /// [tag] is used to identify the source of a log message. It usually
  /// identifies the class where the log call occurs. The [message] you
  /// would like logged.
  static void i(String tag, dynamic message) {
    print('${_formatTag('I:$tag')}||$message');
  }

  /// Send a DEBUG log message.
  ///
  /// [tag] is used to identify the source of a log message. It usually
  /// identifies the class where the log call occurs. The [message] you
  /// would like logged.
  static void d(String tag, dynamic message) {
    print('${_formatTag('D:$tag')}||$message');
  }

  /// Send a WARN log message.
  ///
  /// [tag] is used to identify the source of a log message. It usually
  /// identifies the class where the log call occurs. The [message] you
  /// would like logged.
  static void w(String tag, dynamic message, [dynamic e]) {
    print('${_formatTag('W:$tag')}||$message');
    Log.e(tag, e);
  }

  /// Send an ERROR log message.
  ///
  /// [tag] is used to identify the source of a log message. It usually
  /// identifies the class where the log call occurs. The [message] you
  /// would like logged.
  static void e(String tag, dynamic message, [dynamic e]) {
    print('${_formatTag('E:$tag')}||$message');
    Log.e(tag, e);
  }

  static String _formatTag(String tag) => tag.padRight(30, ' ');
}
