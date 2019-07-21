import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "models/filesystem.dart";
import "commands.dart";
import 'conf.dart';

/// The main controller
class FilexController {
  /// Provide a path
  FilexController({@required this.path, this.showHiddenFiles = false}) {
    _bloc = _FilexBloc(path: path);
    directory = Directory(path);
    confShowHiddenFiles = showHiddenFiles;
    assert(
        directory.existsSync(), "Directory ${directory.path} does not exist");
    confInitialDirectory = directory;
  }

  /// Current directory
  Directory directory;

  /// Config: show hidden files in listing
  final bool showHiddenFiles;

  /// The current path to use
  final String path;

  _FilexBloc _bloc;

  /// Stream of directory items
  Stream<List<DirectoryItem>> get changefeed => _bloc.itemController.stream;

  /// Delete a file or directory
  Future<void> delete(DirectoryItem item) async => _bloc.deleteItem(item);

  /// Create a directory
  Future<void> createDirectory(String name) async =>
      _bloc.createDir(directory, name);

  /// List a directory content
  Future<void> ls() async => _bloc.lsDir(directory);

  /// Dispose the controller when finished using
  void dispose() {
    _bloc.dispose();
  }

  /// Create a directory
  void addDirectory(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final _addDirController = TextEditingController();
        return AlertDialog(
            title: const Text("Create a directory"),
            actions: <Widget>[
              FlatButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: const Text("Create"),
                onPressed: () {
                  createDirectory(_addDirController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: _addDirController,
                    autofocus: true,
                    autocorrect: false,
                  ),
                ],
              ),
            ));
      },
    );
  }
}

class _FilexBloc {
  _FilexBloc({@required this.path});

  final String path;
  final itemController = StreamController<List<DirectoryItem>>();

  Future<void> deleteItem(DirectoryItem item) async {
    try {
      await rm(item);
      await lsDir(item.parent);
    } catch (e) {
      print("Can not delete directory: $e.message");
    }
  }

  Future<void> createDir(Directory dir, String name) async {
    try {
      // trim the filename for leading and trailing spaces
      name = name.trim();
      // create the directory
      await mkdir(dir, name);
      await lsDir(dir);
    } catch (e) {
      print("Can not create directory: $e.message");
    }
  }

  Future<void> lsDir(Directory dir) async {
    try {
      ListedDirectory _d = await getListedDirectory(dir, false);
      itemController.sink.add(_d.items);
    } catch (e) {
      print("Can not ls dir: $e.message");
    }
  }

  void dispose() {
    itemController.close();
  }
}
