import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import "models/filesystem.dart";

Future<void> deleteItem(DirectoryItem item) async {
  try {
    await _rm(item);
  } catch (e) {
    throw ("Can not delete directory: $e.message");
  }
}

Future<void> createDir(String name, String path) async {
  try {
    // trim the filename for leading and trailing spaces
    name = name.trim();
    // create the directory
    await _mkdir(Directory(path), name);
  } catch (e) {
    throw ("Can not create directory: $e.message");
  }
}

Future<ListedDirectory> lsDir(Directory dir,
    {bool showHiddenFiles = false}) async {
  assert(dir != null);
  ListedDirectory lDir;
  try {
    lDir = _getListedDirectory(dir, showHiddenFiles);
  } catch (e) {
    throw ("Can not ls dir: $e");
  }
  return lDir;
}

Future<void> _rm(DirectoryItem item) async {
  try {
    item.item.deleteSync(recursive: true);
  } catch (e) {
    throw ("Error deleting the file: $e");
  }
}

Future<void> _mkdir(Directory currentDir, String name) async {
  try {
    Directory dir = Directory(currentDir.path + "/$name");
    dir.createSync(recursive: true);
  } catch (e) {
    throw ("Can not create directory: $e");
  }
}

ListedDirectory _getListedDirectory(Directory dir, bool showHiddenFiles) {
  //print("LIST DIR ${dir.path}");
  List contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
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
        var file = File(fileOrDir.path);
        files.add(file);
    }
  }
  return ListedDirectory(
      directory: dir, listedDirectories: dirs, listedFiles: files);
}
