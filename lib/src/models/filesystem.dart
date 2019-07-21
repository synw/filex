import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:filesize/filesize.dart' as fs;
import '../file_icons.dart';

/// A directory content with files and directories
class ListedDirectory {
  /// Default constructor
  ListedDirectory(
      {@required this.directory,
      @required this.listedDirectories,
      @required this.listedFiles}) {
    _getItems();
  }

  /// The directory
  final Directory directory;

  /// The subdirectories
  final List<Directory> listedDirectories;

  /// The files in the directory
  final List<File> listedFiles;

  List<DirectoryItem> _items;

  /// All the directory items
  List<DirectoryItem> get items => _items;

  void _getItems() {
    var _d = <DirectoryItem>[];
    for (var _item in listedDirectories) {
      _d.add(DirectoryItem(item: _item));
    }
    var _f = <DirectoryItem>[];
    for (var _item in listedFiles) {
      _f.add(DirectoryItem(item: _item));
    }
    _items = new List.from(_d)..addAll(_f);
  }
}

/// A subdirectory item: file or directory
class DirectoryItem {
  /// Default constructor
  DirectoryItem({@required this.item}) {
    _filesize = _getFilesize(item);
    _filename = basename(item.path);
    _icon = _setIcon(item, _filename);
  }

  /// The subdirectory or file
  final FileSystemEntity item;

  String _filename;
  Icon _icon;
  String _filesize = "";

  /// The icon too display
  Icon get icon => _icon;

  /// The humanized size of the file
  String get filesize => _filesize;

  /// The filesize in bytes
  String get rawFilesize => _getFilesize(item, raw: true);

  /// The name of the file or directory
  String get filename => _filename;

  /// Is the item a directory
  bool get isDirectory => item is Directory;

  /// The path of the item
  String get path => item.path;

  /// The parent directory
  Directory get parent => item.parent;

  String _getFilesize(FileSystemEntity _item, {bool raw = false}) {
    if (_item is File) {
      int s = _item.lengthSync();
      String size;
      if (raw == false) {
        size = fs.filesize(s);
      } else {
        size = "$s";
      }
      return size;
    } else {
      return "";
    }
  }

  Icon _setIcon(dynamic _item, String _filename) {
    if (_item is Directory) {
      return const Icon(Icons.folder, color: Colors.yellow);
    }
    return setFileIcon(_filename);
  }
}
