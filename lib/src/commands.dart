import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import "models/filesystem.dart";

/// Delete an item
Future<void> rm(DirectoryItem item) async {
  try {
    item.item.deleteSync(recursive: true);
  } catch (e) {
    throw ("Error deleting the file: $e");
  }
}

/// Create a directory
Future<void> mkdir(Directory currentDir, String name) async {
  try {
    String path = currentDir.path + "/$name";
    Directory dir = Directory(path);
    print("Creating dir ${dir.path}");
    dir.createSync();
  } catch (e) {
    throw ("Can not create directory: $e");
  }
}

/// List items in directory
ListedDirectory getListedDirectory(Directory dir,
    {bool showHiddenFiles, bool showOnlyDirectories}) {
  //print("LIST DIR ${dir.path}");
  List<FileSystemEntity> contents = dir.listSync()
    ..sort((a, b) => a.path.compareTo(b.path));
  var dirs = <Directory>[];
  var files = <File>[];
  for (FileSystemEntity fileOrDir in contents) {
    if (!showHiddenFiles) {
      if (basename(fileOrDir.path).startsWith(".")) continue;
    }
    switch (fileOrDir is Directory) {
      case true:
        var dir = Directory(fileOrDir.path);
        dirs.add(dir);
        break;
      default:
        if (!showOnlyDirectories) {
          var file = File(fileOrDir.path);
          files.add(file);
        }
    }
  }
  return ListedDirectory(
      directory: dir, listedDirectories: dirs, listedFiles: files);
}
