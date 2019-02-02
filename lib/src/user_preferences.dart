// Copyright (C) 2006 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Ported by Lung Razvan <long1eu(home@long1.eu)>

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:user_preferences/src/log.dart';

/// Interface for accessing and modifying preference data returned by
/// [UserPreferences].  For any particular set of preferences, there is a single
/// instance of this class that all clients share. Modifications to the
/// preferences must go through an [Editor] object to ensure the preference
/// values remain in a consistent state and control when they are committed to
/// storage. Objects that are returned from the various <b>get</b> methods must
/// be treated as immutable by the application.
abstract class UserPreferences {
  static const String _defaultName = 'default.json';
  static Directory _baseDir;

  /// Retrieve and hold the contents of the preferences file [name], returning
  /// a [UserPreferences] through which you can retrieve and modify its values.
  /// Only one instance of the [UserPreferences] object is returned to any
  /// callers for the same name, meaning they will see each other's edits as
  /// soon as they are made.
  ///
  /// [name] of the preferences file. If a preferences file does not exist, it
  /// will be created when you retrieve an editor [UserPreferences.edit] and
  /// then commit changes [Editor.commit].
  ///
  /// Returns the single [UserPreferences] instance that can be used to
  /// retrieve and modify the preference values.
  static Future<UserPreferences> initInstance(
      [String name = _defaultName, Directory baseDir]) async {
    if (_UserPreferencesImpl.instances[name] != null) {
      return _UserPreferencesImpl.instances[name];
    } else {
      _baseDir = baseDir ?? _baseDir;
      if (_baseDir == null) {
        throw StateError('Please provide a base directory.');
      }

      final _UserPreferencesImpl prefs =
          _UserPreferencesImpl(File('${_baseDir.path}/$_defaultName'));
      await prefs.completer.future;
      return prefs;
    }
  }

  /// Retrieve and hold the contents of the preference file [name].
  ///
  /// You first must call [initInstance] with this [name] or [init] if you want
  /// to use the [_defaultName]. If you just want the default instance, call
  /// [init] and the use [instance] were ever you want.
  static UserPreferences getInstance([String name = _defaultName]) {
    if (_UserPreferencesImpl.instances[name] != null) {
      return _UserPreferencesImpl.instances[name];
    } else {
      throw StateError(
          'There are no instances with this name initialized. Please first '
          'call [UserPreferences.initInstance($name)]');
    }
  }

  /// Returns the default [UserPreferences] instance that can be used to
  /// retrieve and modify the preference values.
  ///
  /// Make sure to first initialize the default instance by calling init or
  /// [UserPreferences.getInstance()]
  static UserPreferences get instance {
    final UserPreferences prefs = _UserPreferencesImpl.instances[_defaultName];

    if (prefs == null) {
      throw StateError(
          'Make sure to first initialize the default instance by first calling '
          'UserPreferences.getInstance().');
    }

    return prefs;
  }

  /// Initializes the default instance of [UserPreferences].
  ///
  /// [baseDir] represents the base directory in witch all other instances files
  /// wil be stored.
  static Future<void> init(Directory baseDir) async {
    if (_UserPreferencesImpl.instances[_defaultName] == null) {
      _baseDir = baseDir;
      if (_baseDir == null) {
        throw StateError('Please provide a base directory.');
      }

      _UserPreferencesImpl.instances[_defaultName] =
          _UserPreferencesImpl(File('${_baseDir.path}/$_defaultName'));
      return _UserPreferencesImpl.instances[_defaultName].completer.future;
    }
  }

  /// Retrieve all values from the preferences.
  ///
  /// * Note that you <em>must not</em> modify the collection returned by this
  /// method, or alter any of its contents. The consistency of your stored data
  /// is not guaranteed if you do.
  ///
  /// Returns a map containing a list of pairs key/value representing the
  /// preferences.
  Map<String, dynamic> get all;

  /// Retrieve a value from the preferences.
  ///
  /// [key] is the name of the preference to retrieve.
  ///
  /// Returns the preference value if it exists, or null.
  dynamic operator [](String key);

  /// Retrieve a String value from the preferences.
  ///
  /// [key] is the name of the preference to retrieve. [defValue] is the value
  /// to return if this preference does not exist.
  ///
  /// Returns the preference value if it exists, or defValue. Throws [CastError]
  /// if there is a preference with this name that is not a String.
  String getString(String key, [String defValue]);

  /// Retrieve a list of String values from the preferences.
  ///
  /// * Note that you <em>must not</em> modify the set instance returned by this
  /// call. The consistency of the stored data is not guaranteed if you do, nor
  /// is your ability to modify the instance at all.
  ///
  /// [key] is the name of the preference to retrieve. [defValues] is the value
  /// to return if this preference does not exist.
  ///
  /// Returns the preference value if it exists, or defValue. Throws [CastError]
  /// if there is a preference with this name that is not a Set<String>.
  List<String> getStringList(String key, [List<String> defValues]);

  /// Retrieve an int value from the preferences.
  ///
  /// [key] is the name of the preference to retrieve. [defValue] is the value
  /// to return if this preference does not exist.
  ///
  /// Returns the preference value if it exists, or defValue. Throws [CastError]
  /// if there is a preference with this name that is not a int.
  int getInt(String key, [int defValue]);

  /// Retrieve an double value from the preferences.
  ///
  /// [key] is the name of the preference to retrieve. [defValue] is the value
  /// to return if this preference does not exist.
  ///
  /// Returns the preference value if it exists, or defValue. Throws [CastError]
  /// if there is a preference with this name that is not a double.
  double getDouble(String key, [double defValue]);

  /// Retrieve a boolean value from the preferences.
  ///
  /// [key] is the name of the preference to retrieve. [defValue] is the value
  /// to return if this preference does not exist.
  ///
  /// Returns the preference value if it exists, or defValue. Throws [CastError]
  /// if there is a preference with this name that is not a bool.
  // ignore: avoid_positional_boolean_parameters
  bool getBool(String key, [bool defValue]);

  /// Checks whether the preferences contains a preference.
  ///
  /// [key] is the name of the preference to check.
  /// Returns true if the preference exists in the preferences, otherwise false.
  bool contains(String key);

  /// Create a new [Editor] for these preferences, through which you can make
  /// modifications to the data in the preferences and atomically commit those
  /// changes back to the [UserPreferences] object.
  ///
  /// * Note that you <em>must</em> call [Editor.commit] to have any changes you
  /// perform in the Editor actually show up in the [UserPreferences].
  ///
  /// Returns a new instance of the [Editor] abstract class, allowing you to
  /// modify the values in this [UserPreferences] object.
  Editor edit();

  /// The Stream emits the key of a shared preference that was changed, added,
  /// or removed.
  ///
  /// This may be called even if a preference is set to its existing value.
  Stream<String> get onChange;
}

/// Interface used for modifying values in a [UserPreferences] object. All
/// changes you make in an editor are batched, and not copied back to the
/// original [UserPreferences] until you call [commit] or [apply]
abstract class Editor {
  /// Set a value in the preferences editor, to be written back once [commit] or
  /// [apply] are called.
  ///
  /// [key] the name of the preference to modify and [value] is the new value
  /// for the preference. Passing null for this argument is equivalent to
  /// calling [remove] with this key.
  // ignore: avoid_annotating_with_dynamic
  void operator []=(String key, dynamic value);

  /// Set a String value in the preferences editor, to be written back once
  /// [commit] or [apply] are called.
  ///
  /// [key] the name of the preference to modify and [value] is the new value
  /// for the preference. Passing null for this argument is equivalent to
  /// calling [remove] with this key.
  void putString(String key, String value);

  /// Set a List of String values in the preferences editor, to be written back
  /// once [commit] or [apply] is called.
  ///
  /// [key] the name of the preference to modify and [values] is the new value
  /// for the preference. Passing null for this argument is equivalent to
  /// calling [remove] with this key.
  void putStringList(String key, List<String> values);

  /// Set an int value in the preferences editor, to be written back once
  /// [commit] or [apply] are called.
  ///
  /// [key] the name of the preference to modify and [value] is the new value
  /// for the preference. Passing null for this argument is equivalent to
  /// calling [remove] with this key.
  void putInt(String key, int value);

  /// Set an double value in the preferences editor, to be written back once
  /// [commit] or [apply] are called.
  ///
  /// [key] the name of the preference to modify and [value] is the new value
  /// for the preference. Passing null for this argument is equivalent to
  /// calling [remove] with this key.
  void putDouble(String key, double value);

  /// Set a boolean value in the preferences editor, to be written back once
  /// [commit] or [apply] are called.
  ///
  /// [key] the name of the preference to modify and [value] is the new value
  /// for the preference. Passing null for this argument is equivalent to
  /// calling [remove] with this key.
  // ignore: avoid_positional_boolean_parameters
  void putBool(String key, bool value);

  /// Mark in the editor that a preference value should be removed, which will
  /// be done in the actual preferences once [commit] is called.
  ///
  /// * Note that when committing back to the preferences, all removals are done
  /// first, regardless of whether you called remove before or after put methods
  /// on this editor.
  ///
  /// [key] is the name of the preference to remove.
  void remove(String key);

  /// Mark in the editor to remove <em>all</em> values from the preferences.
  /// Once commit is called, the only remaining preferences will be any that you
  /// have defined in this editor.
  ///
  /// * Note that when committing back to the preferences, the clear is done
  /// first, regardless of whether you called clear before or after put methods
  /// on this editor.
  void clear();

  /// Commit your preferences changes back from this Editor to the
  /// [UserPreferences] object it is editing.  This atomically performs the
  /// requested modifications, replacing whatever is currently in the
  /// [UserPreferences].
  ///
  /// * Note that when two editors are modifying preferences at the same time,
  /// the last one to call commit wins.
  ///
  /// * If you don't care about the return value consider using [apply] instead.
  ///
  /// Returns true if the new values were successfully written
  /// to persistent storage.
  Future<bool> commit();

  /// Commit your preferences changes back from this Editor to the
  /// [UserPreferences] object it is editing. This atomically performs the
  /// requested modifications, replacing whatever is currently in the
  /// [UserPreferences].
  ///
  /// * Note that when two editors are modifying preferences at the same time,
  /// the last one to call apply wins.
  ///
  /// * Unlike [commit], which writes its preferences out to persistent storage
  /// synchronously, [apply] commits its changes to the in-memory
  /// [UserPreferences] immediately but starts an asynchronous commit to disk
  /// and you won't be notified of any failures.  If another editor on this
  /// [UserPreferences] does a regular [commit] while a [apply] is still
  /// outstanding, the [commit] will block until all async commits are completed
  /// as well as the commit itself.
  void apply();
}

class _UserPreferencesImpl implements UserPreferences {
  _UserPreferencesImpl(this._file) : _backupFile = File('${_file.path}.bak') {
    instances[_file.path] = this;
    _loadFromDisk();
  }

  static final Map<String, _UserPreferencesImpl> instances =
      <String, _UserPreferencesImpl>{};

  static const String _tag = 'UserPreferencesImpl';
  static const bool _debug = true;

  /// If a fsync takes more than [_maxFsyncDurationMillis] ms, warn
  static const int _maxFsyncDurationMillis = 256;

  // ignore: close_sinks
  final StreamController<String> _onChangeController =
      StreamController<String>.broadcast();

  final File _file;
  final File _backupFile;

  Completer<void> completer;
  HashMap<String, dynamic> _map;
  int _diskWritesInFlight = 0;
  dynamic _error;

  /// Current memory state (always increasing)
  int _currentMemoryStateGeneration = 0;

  /// Latest memory state that was committed to disk
  int _diskStateGeneration = 0;

  void _loadFromDisk() {
    if (completer != null && completer.isCompleted) {
      return;
    }
    completer = Completer<void>();
    if (_backupFile.existsSync()) {
      _file.deleteSync();
      _backupFile.renameSync(_file.path);
    }

    final FileStat stat = _file.statSync();

    // Debugging
    if (stat.type != FileSystemEntityType.notFound &&
        !stat.modeString().startsWith('r')) {
      Log.w(_tag, 'Attempt to read preferences file $_file without permission');
    }

    HashMap<String, dynamic> map;
    dynamic error;
    try {
      if (_canRead(stat)) {
        try {
          final String str = _file.readAsStringSync();
          // ignore: always_specify_types
          final Map decoded = jsonDecode(str);
          map = HashMap<String, dynamic>.from(decoded);
        } on Exception catch (e) {
          Log.w(_tag, 'Cannot read ${_file.absolute.path}', e);
        }
      }
    } catch (t) {
      error = t;
    }

    completer.complete();
    _error = error;

    try {
      if (error == null) {
        if (map != null) {
          _map = map;
        } else {
          _map = HashMap<String, dynamic>();
        }
      }
    } catch (t) {
      _error = t;
    }
  }

  void _checkIfLoaded() {
    if (!completer.isCompleted) {
      throw StateError('Make sure to wait for the init() method to finish '
          'before calling methods on this instance.');
    }

    if (_error != null) {
      throw StateError('$_error');
    }
  }

  @override
  Map<String, Object> get all {
    _checkIfLoaded();
    return HashMap<String, Object>.from(_map);
  }

  @override
  dynamic operator [](String key) => _map[key];

  @override
  String getString(String key, [String defValue]) {
    _checkIfLoaded();
    final String v = _map[key];
    return v != null ? v : defValue;
  }

  @override
  List<String> getStringList(String key, [List<String> defValues]) {
    _checkIfLoaded();
    final List<String> v = _map[key]?.cast<String>();
    return v != null ? v : defValues;
  }

  @override
  double getDouble(String key, [double defValue]) {
    _checkIfLoaded();
    final double v = _map[key];
    return v != null ? v : defValue;
  }

  @override
  int getInt(String key, [int defValue]) {
    _checkIfLoaded();
    final int v = _map[key];
    return v != null ? v : defValue;
  }

  @override
  bool getBool(String key, [bool defValue]) {
    _checkIfLoaded();
    final bool v = _map[key];
    return v != null ? v : defValue;
  }

  @override
  Stream<String> get onChange => _onChangeController.stream;

  @override
  bool contains(String key) {
    _checkIfLoaded();
    return _map.containsKey(key);
  }

  @override
  Editor edit() {
    _checkIfLoaded();
    return _EditorImpl(this);
  }

  /// Enqueue an already-committed-to-memory result to be written
  /// to disk.
  ///
  /// They will be written to disk one-at-a-time in the order
  /// that they're enqueued.
  ///
  /// [postWriteRunnable] if non-null, we're being called
  /// from apply() and this is the runnable to run after
  /// the write proceeds.  if null (from a regular commit()),
  /// then we're allowed to do this disk write on the main
  /// thread (which in addition to reducing allocations and
  /// creating a background thread, this has the advantage that
  /// we catch them in userdebug StrictMode reports to convert
  /// them where possible to apply() ...)
  Future<void> _enqueueDiskWrite(_MemoryCommitResult mcr,
      Future<void> Function() postWriteRunnable) async {
    final bool isFromSyncCommit = postWriteRunnable == null;
    Future<void> writeToDiskRunnable() async {
      await _writeToFile(mcr, isFromSyncCommit);
      _diskWritesInFlight--;
      await postWriteRunnable?.call();
    }

    // Typical #commit() path with fewer allocations, doing a write on
    // the current thread.
    if (isFromSyncCommit) {
      bool wasEmpty = false;

      wasEmpty = _diskWritesInFlight == 1;

      if (wasEmpty) {
        await writeToDiskRunnable();
        return;
      }
    }

    await writeToDiskRunnable();
  }

  static IOSink _createFileSink(File file) {
    IOSink str;
    if (file.existsSync()) {
      str = file.openWrite();
    } else {
      file..parent.createSync()..createSync();

      try {
        str = file.openWrite();
      } catch (e2) {
        Log.e(_tag, 'Couldn\'t create UserPreferences file $file', e2);
      }
    }
    return str;
  }

  Future<void> _writeToFile(
      _MemoryCommitResult mcr, bool isFromSyncCommit) async {
    DateTime startTime;
    DateTime existsTime;
    DateTime backupExistsTime;
    DateTime outputStreamCreateTime;
    DateTime writeTime;
    DateTime fsyncTime;
    DateTime deleteTime;

    if (_debug) {
      startTime = DateTime.now();
    }

    final bool fileExists = _file.existsSync();
    if (_debug) {
      existsTime = DateTime.now();
      // Might not be set, hence init them to a default value
      backupExistsTime = existsTime;
    }
    // Rename the current file so it may be used as a backup during the next
    // read
    if (fileExists) {
      bool needsWrite = false;
      // Only need to write if the disk state is older than this commit
      if (_diskStateGeneration < mcr.memoryStateGeneration) {
        if (isFromSyncCommit) {
          needsWrite = true;
        } else {
          // No need to persist intermediate states. Just wait for the latest
          // state to be persisted.
          if (_currentMemoryStateGeneration == mcr.memoryStateGeneration) {
            needsWrite = true;
          }
        }
      }
      if (!needsWrite) {
        mcr.setDiskWriteResult(wasWritten: false, result: true);
        return;
      }
      final bool backupFileExists = _backupFile.existsSync();
      if (_debug) {
        backupExistsTime = DateTime.now();
      }
      if (!backupFileExists) {
        try {
          _file.renameSync(_backupFile.path);
        } catch (e) {
          Log.e(
              _tag, 'Couldn\'t rename file $_file to backup file $_backupFile');
          mcr.setDiskWriteResult(wasWritten: false, result: false);
          return;
        }
      } else {
        _file.deleteSync();
      }
    }

    // Attempt to write the file, delete the backup and return true as
    // atomically as possible. If any exception occurs, delete the file; next
    // time we will restore from the backup.
    try {
      final IOSink str = _createFileSink(_file);
      if (_debug) {
        outputStreamCreateTime = DateTime.now();
      }
      if (str == null) {
        mcr.setDiskWriteResult(wasWritten: false, result: false);
        return;
      }

      final String data = jsonEncode(mcr.mapToWriteToDisk);
      str.add(utf8.encode(data));
      writeTime = DateTime.now();

      await str.flush();
      fsyncTime = DateTime.now();
      await str.close();

      // Writing was successful, delete the backup file if there is one.
      if (_backupFile.existsSync()) {
        _backupFile.deleteSync();
      }
      if (_debug) {
        deleteTime = DateTime.now();
      }
      _diskStateGeneration = mcr.memoryStateGeneration;
      mcr.setDiskWriteResult(wasWritten: true, result: true);
      if (_debug) {
        Log.d(
            _tag,
            'write: '
            '${existsTime.difference(startTime)}/'
            '${backupExistsTime.difference(startTime)}/'
            '${outputStreamCreateTime.difference(startTime)}/'
            '${writeTime.difference(startTime)}/'
            '${fsyncTime.difference(startTime)}/'
            '${deleteTime.difference(startTime)}');
      }

      return;
    } on IOException catch (e) {
      Log.w(_tag, 'writeToFile: Got exception: IOException', e);
    } catch (e) {
      Log.w(_tag, 'writeToFile: Got exception:', e);
    }

    // Clean up an unsuccessfully written file
    if (_file.existsSync()) {
      try {
        _file.deleteSync();
      } catch (e) {
        Log.e(_tag, 'Couldn\'t clean up partially-written file $_file');
      }
    }
    mcr.setDiskWriteResult(wasWritten: false, result: false);
  }

  bool _canRead(FileStat stat) =>
      stat.type != FileSystemEntityType.notFound &&
      stat.modeString().startsWith('r');
}

// Return value from EditorImpl#commitToMemory()
class _MemoryCommitResult {
  _MemoryCommitResult(
      this.memoryStateGeneration, this.keysModified, this.mapToWriteToDisk);

  final int memoryStateGeneration;
  final List<String> keysModified;
  final Map<String, Object> mapToWriteToDisk;
  final Completer<void> writtenToDiskLatch = Completer<void>();

  bool writeToDiskResult = false;
  bool wasWritten = false;

  void setDiskWriteResult({bool wasWritten, bool result}) {
    this.wasWritten = wasWritten;
    writeToDiskResult = result;
    writtenToDiskLatch.complete();
  }
}

class _EditorImpl implements Editor {
  _EditorImpl(this._prefs);

  final _UserPreferencesImpl _prefs;

  final HashMap<String, dynamic> _modified = HashMap<String, dynamic>();
  bool _clear = false;

  @override
  // ignore: avoid_annotating_with_dynamic
  void operator []=(String key, dynamic value) {
    _modified[key] = value;
  }

  @override
  void putString(String key, String value) {
    _modified[key] = value;
  }

  @override
  void putStringList(String key, List<String> values) {
    _modified[key] = (values == null) ? null : List<String>.from(values);
  }

  @override
  void putInt(String key, int value) {
    _modified[key] = value;
  }

  @override
  void putDouble(String key, double value) {
    _modified[key] = value;
  }

  @override
  void putBool(String key, bool value) {
    _modified[key] = value;
  }

  @override
  void remove(String key) {
    _modified[key] = this;
  }

  @override
  void clear() {
    _clear = true;
  }

  @override
  void apply() {
    final DateTime startTime = DateTime.now();
    final _MemoryCommitResult mcr = _commitToMemory();
    Future<void> awaitCommit() async {
      await mcr.writtenToDiskLatch.future;

      if (_UserPreferencesImpl._debug && mcr.wasWritten) {
        Log.d(
            _UserPreferencesImpl._tag,
            '$_filename:${mcr.memoryStateGeneration} applied after '
            '${DateTime.now().difference(startTime)}');
      }
    }

    _prefs._enqueueDiskWrite(mcr, awaitCommit);
    // Okay to notify the listeners before it's hit disk
    // because the listeners should always get the same
    // UserPreferences instance back, which has the
    // changes reflected in memory.
    _notifyListeners(mcr);
  }

  // Returns true if any changes were made
  _MemoryCommitResult _commitToMemory() {
    int memoryStateGeneration;
    List<String> keysModified;
    Map<String, Object> mapToWriteToDisk;

    // We optimistically don't make a deep copy until
    // a memory commit comes in when we're already
    // writing to disk.
    if (_prefs._diskWritesInFlight > 0) {
      // We can't modify our mMap as a currently
      // in-flight write owns it.  Clone it before
      // modifying it.
      // noinspection unchecked
      _prefs._map = HashMap<String, Object>.from(_prefs._map);
    }
    mapToWriteToDisk = _prefs._map;
    _prefs._diskWritesInFlight++;
    final bool hasListeners = _prefs._onChangeController.hasListener;
    if (hasListeners) {
      keysModified = <String>[];
    }

    bool changesMade = false;
    if (_clear) {
      if (mapToWriteToDisk.isNotEmpty) {
        changesMade = true;
        mapToWriteToDisk.clear();
      }
      _clear = false;
    }
    for (MapEntry<String, Object> e in _modified.entries) {
      final String k = e.key;
      final Object v = e.value;
      // 'this' is the magic value for a removal mutation. In addition,
      // setting a value to 'null' for a given key is specified to be
      // equivalent to calling remove on that key.
      if (v == this || v == null) {
        if (!mapToWriteToDisk.containsKey(k)) {
          continue;
        }
        mapToWriteToDisk.remove(k);
      } else {
        if (mapToWriteToDisk.containsKey(k)) {
          final Object existingValue = mapToWriteToDisk[k];
          if (existingValue != null && existingValue == v) {
            continue;
          }
        }
        mapToWriteToDisk[k] = v;
      }
      changesMade = true;
      if (hasListeners) {
        keysModified.add(k);
      }
    }
    _modified.clear();
    if (changesMade) {
      _prefs._currentMemoryStateGeneration++;
    }
    memoryStateGeneration = _prefs._currentMemoryStateGeneration;

    return _MemoryCommitResult(
      memoryStateGeneration,
      keysModified,
      mapToWriteToDisk,
    );
  }

  @override
  Future<bool> commit() async {
    final DateTime startTime = DateTime.now();
    final _MemoryCommitResult mcr = _commitToMemory();
    await _prefs._enqueueDiskWrite(mcr, null);

    try {
      await mcr.writtenToDiskLatch.future;
    } catch (e) {
      return Future<bool>.value(false);
    } finally {
      if (_UserPreferencesImpl._debug) {
        Log.d(
            _UserPreferencesImpl._tag,
            '$_filename:${mcr.memoryStateGeneration} committed after '
            '${DateTime.now().difference(startTime)}');
      }
    }
    _notifyListeners(mcr);
    return mcr.writeToDiskResult;
  }

  String get _filename => basenameWithoutExtension(_prefs._file.path);

  void _notifyListeners(final _MemoryCommitResult mcr) {
    if (mcr.keysModified == null || mcr.keysModified.isEmpty) {
      return;
    }

    for (int i = mcr.keysModified.length - 1; i >= 0; i--) {
      final String key = mcr.keysModified[i];
      _prefs._onChangeController.add(key);
    }
  }
}
