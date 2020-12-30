import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_file/open_file.dart';
import 'package:pedantic/pedantic.dart';

import 'bloc.dart';
import 'models/actions.dart';
import "models/filesystem.dart";

class _FilexState extends State<Filex> {
  _FilexState(
      {@required this.controller,
      this.showHiddenFiles,
      this.showOnlyDirectories,
      this.fileTrailingBuilder,
      this.directoryTrailingBuilder,
      this.fileLeadingBuilder,
      this.directoryLeadingBuilder,
      this.compact,
      this.actions,
      this.extraActions}) {
    _initialDirectory = controller.directory;
    controller
      ..showOnlyDirectories = showOnlyDirectories
      ..showHiddenFiles = showHiddenFiles
      ..ls();
  }

  final bool showHiddenFiles;
  final bool showOnlyDirectories;
  final FilexActionBuilder fileLeadingBuilder;
  final FilexActionBuilder fileTrailingBuilder;
  final FilexActionBuilder directoryTrailingBuilder;
  final FilexActionBuilder directoryLeadingBuilder;
  final bool compact;
  final List<PredefinedAction> actions;
  final List<FilexSlidableAction> extraActions;
  final FilexController controller;

  SlidableController _slidableController;
  final ScrollController _scrollController = ScrollController();
  bool _isBuilt = false;
  Directory _initialDirectory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DirectoryItem>>(
      stream: controller.changefeed,
      builder:
          (BuildContext context, AsyncSnapshot<List<DirectoryItem>> snapshot) {
        if (snapshot.hasData) {
          if (_isBuilt) {
            _scrollTop();
          }
          final builder = ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                final item = snapshot.data[index];
                Widget w;
                if (actions.isNotEmpty) {
                  w = Slidable(
                    key: Key(item.filename),
                    controller: _slidableController,
                    direction: Axis.horizontal,
                    actionPane: const SlidableDrawerActionPane(),
                    actionExtentRatio: 0.25,
                    child: compact
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
          if (controller.directory.path != _initialDirectory.path) {
            _isBuilt = true;
            return Column(
                children: <Widget>[
                  _topNavigation(),
                  Expanded(child: builder)
                ]
            );
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
    );
  }

  GestureDetector _topNavigation() {
    return GestureDetector(
      child: const ListTile(
        leading: Icon(Icons.arrow_upward),
        title: Text("..", textScaleFactor: 1.5),
      ),
      onTap: () {
        final li = controller.directory.path.split("/")..removeLast();
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
      final p = controller.directory.path + "/" + item.filename;
      controller
        ..directory = Directory(p)
        ..ls();
    } else {
      if (Platform.isIOS || Platform.isAndroid) OpenFile.open(item.path);
    }
  }

  Widget _buildLeading(BuildContext context, DirectoryItem item) {
    Widget w = item.icon;
    if (item.isDirectory) {
      switch (directoryLeadingBuilder != null) {
        case true:
          w = directoryLeadingBuilder(context, item);
      }
    } else {
      switch (fileLeadingBuilder != null) {
        case true:
          w = fileLeadingBuilder(context, item);
          break;
        default:
      }
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
    final ic = <Widget>[];
    if (actions.contains(PredefinedAction.delete)) {
      ic.add(IconSlideAction(
        caption: 'Delete',
        color: Colors.red,
        icon: Icons.delete,
        onTap: () => _confirmDeleteDialog(context, item),
      ));
    }
    if (extraActions.isNotEmpty) {
      for (final action in extraActions) {
        ic.add(IconSlideAction(
          caption: action.name,
          color: action.color,
          icon: action.iconData,
          onTap: () => action.onTap(context, item),
        ));
      }
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
        duration: const Duration(milliseconds: 10), curve: Curves.easeIn);
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
  const Filex(
      {@required this.controller,
      this.showHiddenFiles = false,
      this.showOnlyDirectories = false,
      this.fileTrailingBuilder,
      this.directoryTrailingBuilder,
      this.directoryLeadingBuilder,
      this.actions = const <PredefinedAction>[],
      this.extraActions = const <FilexSlidableAction>[],
      this.compact = false});

  /// The controller to use
  final FilexController controller;

  /// Slidable actions to use
  final List<PredefinedAction> actions;

  /// Show the hidden files
  final bool showHiddenFiles;

  /// Show only the directories
  final bool showOnlyDirectories;

  /// Trailing builder for files
  final FilexActionBuilder fileTrailingBuilder;

  /// Trailing builder for directory
  final FilexActionBuilder directoryTrailingBuilder;

  /// Leading builder for directory
  final FilexActionBuilder directoryLeadingBuilder;

  /// Extra slidable actions
  final List<FilexSlidableAction> extraActions;

  /// Use compact format
  final bool compact;

  @override
  _FilexState createState() => _FilexState(
      controller: controller,
      showHiddenFiles: showHiddenFiles,
      showOnlyDirectories: showOnlyDirectories,
      fileTrailingBuilder: fileTrailingBuilder,
      directoryTrailingBuilder: directoryTrailingBuilder,
      directoryLeadingBuilder: directoryLeadingBuilder,
      actions: actions,
      extraActions: extraActions,
      compact: compact);
}
