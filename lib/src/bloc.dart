import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' as rx;

import "commands.dart";
import "models/filesystem.dart";

/// The main controller
class FilexController {
  /// Provide a path
  FilexController({@required this.path}) {
    _bloc = _FilexBloc(path: path, itemController: _itemStream);
    directory = Directory(path);
    assert(
        directory.existsSync(), "Directory ${directory.path} does not exist");
  }

  /// Current directory
  Directory directory;

  /// The current path to use
  final String path;

  _FilexBloc _bloc;
  final _itemStream = rx.ReplaySubject<List<DirectoryItem>>();

  /// Setter for show only dirs setting
  set showOnlyDirectories(bool v) => _bloc.showOnlyDirectories = v;

  /// Setter for show hidden files setting
  set showHiddenFiles(bool v) => _bloc.showHiddenFiles = v;

  /// Stream of directory items
  Stream<List<DirectoryItem>> get changefeed => _itemStream.stream;

  /// Delete a file or directory
  Future<void> delete(DirectoryItem item) async => _bloc.deleteItem(item);

  /// Create a directory
  Future<void> createDirectory(String name) async =>
      _bloc.createDir(directory, name);

  /// List a directory content
  Future<void> ls() async => _bloc.lsDir(directory);

  /// Dispose the controller when finished using
  void dispose() {
    _itemStream.close();
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
  _FilexBloc({@required this.path, @required this.itemController});

  final String path;
  final StreamController<List<DirectoryItem>> itemController;
  bool showOnlyDirectories;
  bool showHiddenFiles;

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
      // create the directory
      await mkdir(dir, name.trim());
      await lsDir(dir);
    } catch (e) {
      print("Can not create directory: $e.message");
    }
  }

  Future<void> lsDir(Directory dir) async {
    try {
      final _d = getListedDirectory(dir,
          showHiddenFiles: showHiddenFiles,
          showOnlyDirectories: showOnlyDirectories);
      if (showOnlyDirectories) {
        itemController.sink.add(_d.items);
      }
      itemController.sink.add(_d.items);
    } catch (e) {
      print("Can not ls dir: $e.message");
    }
  }
}
