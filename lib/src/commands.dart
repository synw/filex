import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

import 'exceptions.dart';
import "models/filesystem.dart";

/// Delete an item
Future<void> rm(DirectoryItem item) async {
  try {
    item.item.deleteSync(recursive: true);
  } catch (e) {
    throw FileSystemException("Error deleting the file: $e");
  }
}

/// Create a directory
Future<void> mkdir(Directory currentDir, String name) async {
  try {
    final path = currentDir.path + "/$name";
    final dir = Directory(path);
    print("Creating dir ${dir.path}");
    dir.createSync();
  } catch (e) {
    throw FileSystemException("Can not create directory: $e");
  }
}

/// List items in directory
ListedDirectory getListedDirectory(Directory dir,
    {bool? showHiddenFiles, bool? showOnlyDirectories}) {
  //print("LIST DIR ${dir.path}");
  final contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  final dirs = <Directory>[];
  final files = <File>[];
  for (final fileOrDir in contents) {
    if (!showHiddenFiles!) {
      if (basename(fileOrDir.path).startsWith(".")) continue;
    }
    switch (fileOrDir is Directory) {
      case true:
        final dir = Directory(fileOrDir.path);
        dirs.add(dir);
        break;
      default:
        if (!showOnlyDirectories!) {
          final file = File(fileOrDir.path);
          files.add(file);
        }
    }
  }
  return ListedDirectory(
      directory: dir, listedDirectories: dirs, listedFiles: files);
}
