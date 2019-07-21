import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pedantic/pedantic.dart';
import 'package:open_file/open_file.dart';
import "models/filesystem.dart";
import 'bloc.dart';
import 'conf.dart';

/// Actions on slidable
enum PredefinedAction {
  /// Delete items
  delete
}

/// Action to perform on click
typedef Widget FilexActionBuilder(BuildContext context, DirectoryItem item);

class _FilexState extends State<Filex> {
  _FilexState(
      {@required this.controller,
      this.showHiddenFiles,
      this.fileTrailingBuilder,
      this.directoryTrailingBuilder,
      this.directoryLeadingBuilder,
      this.compact,
      this.actions}) {
    controller.ls();
  }

  final bool showHiddenFiles;
  final FilexActionBuilder fileTrailingBuilder;
  final FilexActionBuilder directoryTrailingBuilder;
  final FilexActionBuilder directoryLeadingBuilder;
  final bool compact;
  final List<PredefinedAction> actions;
  final FilexController controller;

  SlidableController _slidableController;
  final ScrollController _scrollController = ScrollController();
  bool _isBuilt = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        controller: _scrollController,
        child: StreamBuilder<List<DirectoryItem>>(
          stream: controller.changefeed,
          builder: (BuildContext context,
              AsyncSnapshot<List<DirectoryItem>> snapshot) {
            if (snapshot.hasData) {
              if (_isBuilt) {
                _scrollTop();
              }
              ListView builder = ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    DirectoryItem item = snapshot.data[index];
                    Widget w;
                    if (actions.isNotEmpty) {
                      w = Slidable(
                        key: Key(item.filename),
                        controller: _slidableController,
                        direction: Axis.horizontal,
                        actionPane: const SlidableDrawerActionPane(),
                        actionExtentRatio: 0.25,
                        child: (compact)
                            ? _buildCompactVerticalListItem(context, item)
                            : _buildVerticalListItem(context, item),
                        actions: _getSlideIconActions(context, item),
                      );
                    } else {
                      if (compact) {
                        w = _buildCompactVerticalListItem(context, item);
                      } else {
                        w = _buildVerticalListItem(context, item);
                      }
                    }
                    return w;
                  });
              if (controller.directory.path != confInitialDirectory.path) {
                _isBuilt = true;
                return Column(children: <Widget>[_topNavigation(), builder]);
              } else {
                _isBuilt = true;
                return builder;
              }
            } else {
              return Center(
                  child: Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height / 0.8),
                      child: const CircularProgressIndicator()));
            }
          },
        ));
  }

  GestureDetector _topNavigation() {
    return GestureDetector(
      child: ListTile(
        leading: const Icon(Icons.arrow_upward),
        title: const Text("..", textScaleFactor: 1.5),
      ),
      onTap: () {
        var li = controller.directory.path.split("/");
        li.removeLast();
        controller.directory = Directory(li.join("/"));
        unawaited(controller.ls());
      },
    );
  }

  Widget _buildVerticalListItem(BuildContext context, DirectoryItem item) {
    return ListTile(
      title: Text(item.filename),
      dense: true,
      leading: _buildLeading(context, item),
      trailing: _buildTrailing(context, item),
      onTap: () => _onTapDirectory(item),
    );
  }

  Widget _buildCompactVerticalListItem(
      BuildContext context, DirectoryItem item) {
    //print("ITEM ${item.filename} / ? isdir ${item.isDirectory}");
    return Padding(
        padding: const EdgeInsets.all(3.0),
        child: Row(children: <Widget>[
          _buildLeading(context, item),
          Expanded(
              child: GestureDetector(
            child: Text(" ${item.filename}", overflow: TextOverflow.clip),
            onTap: () => _onTapDirectory(item),
          )),
          _buildTrailing(context, item)
        ]));
  }

  void _onTapDirectory(DirectoryItem item) {
    if (item.isDirectory) {
      String p = controller.directory.path + "/" + item.filename;
      controller.directory = Directory(p);
      controller.ls();
    } else {
      if (Platform.isIOS || Platform.isAndroid) OpenFile.open(item.path);
    }
  }

  Widget _buildLeading(BuildContext context, DirectoryItem item) {
    Widget w = item.icon;
    switch (directoryLeadingBuilder != null) {
      case true:
        if (item.isDirectory) w = directoryLeadingBuilder(context, item);
    }
    return w;
  }

  Widget _buildTrailing(BuildContext context, DirectoryItem item) {
    Widget w;
    switch (item.isDirectory) {
      case true:
        if (directoryTrailingBuilder != null) {
          w = directoryTrailingBuilder(context, item);
        } else {
          w = const Text("");
        }
        break;
      default:
        if (fileTrailingBuilder != null) {
          w = fileTrailingBuilder(context, item);
        } else {
          w = Text("${item.filesize}");
        }
    }
    return w;
  }

  List<Widget> _getSlideIconActions(BuildContext context, DirectoryItem item) {
    List<Widget> ic = [];
    if (actions.contains(PredefinedAction.delete)) {
      ic.add(IconSlideAction(
        caption: 'Delete',
        color: Colors.red,
        icon: Icons.delete,
        onTap: () => _confirmDeleteDialog(context, item),
      ));
    }
    return ic;
  }

  void _confirmDeleteDialog(BuildContext context, DirectoryItem item) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete ${item.filename}?"),
          actions: <Widget>[
            FlatButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: const Text("Delete"),
              color: Colors.red,
              onPressed: () {
                controller.delete(item).then((_) {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _scrollTop() {
    _scrollController.animateTo(_scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 10), curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// The file explorer
class Filex extends StatefulWidget {
  /// Provide a directory to start from
  Filex(
      {@required this.controller,
      this.showHiddenFiles = false,
      this.fileTrailingBuilder,
      this.directoryTrailingBuilder,
      this.directoryLeadingBuilder,
      this.actions = const <PredefinedAction>[],
      this.compact = false});

  /// The controller to use
  final FilexController controller;

  /// Slidable actions to use
  final List<PredefinedAction> actions;

  /// Show the hidden files
  final bool showHiddenFiles;

  /// Trailing builder for files
  final FilexActionBuilder fileTrailingBuilder;

  /// Trailing builder for directory
  final FilexActionBuilder directoryTrailingBuilder;

  /// Leading builder for directory
  final FilexActionBuilder directoryLeadingBuilder;

  /// Use compact format
  final bool compact;

  @override
  _FilexState createState() => _FilexState(
      controller: controller,
      showHiddenFiles: showHiddenFiles,
      fileTrailingBuilder: fileTrailingBuilder,
      directoryTrailingBuilder: directoryTrailingBuilder,
      directoryLeadingBuilder: directoryLeadingBuilder,
      actions: actions,
      compact: compact);
}
