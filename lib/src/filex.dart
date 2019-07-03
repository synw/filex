import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_file/open_file.dart';
import "models/filesystem.dart";
import 'commands.dart';

typedef Widget FilexActionBuilder(BuildContext context, DirectoryItem item);

class _FilexState extends State<Filex> {
  _FilexState(
      {@required this.directory,
      this.showHiddenFiles = false,
      this.fileTrailingBuilder,
      this.directoryTrailingBuilder,
      this.directoryLeadingBuilder,
      this.compact = false})
      : assert(directory.existsSync()),
        _directory = directory,
        _initialDirectory = directory;

  final Directory directory;
  final bool showHiddenFiles;
  final FilexActionBuilder fileTrailingBuilder;
  final FilexActionBuilder directoryTrailingBuilder;
  final FilexActionBuilder directoryLeadingBuilder;
  final bool compact;

  Directory _directory;
  ListedDirectory _lsDirectory;
  Directory _initialDirectory;

  SlidableController _slidableController;
  final _addDirController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    ls(_directory);
    super.initState();
  }

  List<Widget> buildList() {
    var w = <Widget>[];
    if (_directory.path != _initialDirectory.path) w.add(_topNavigation());
    for (var item in _lsDirectory.items) {
      //print("ITEM ${item.filename}: dir ? ${item.isDirectory}");
      w.add(Slidable(
        key: Key(item.filename),
        controller: _slidableController,
        direction: Axis.horizontal,
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        child: (compact)
            ? _buildCompactVerticalListItem(context, item)
            : _buildVerticalListItem(context, item),
        actions: _getSlideIconActions(context, item),
      ));
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    (_lsDirectory == null)
        ? w = Center(child: const CircularProgressIndicator())
        : w = (compact)
            ? SingleChildScrollView(
                child: Column(
                children: buildList(),
              ))
            : ListView(controller: _scrollController, children: buildList());
    return w;
  }

  void ls(Directory dir) {
    lsDir(_directory).then((lsd) {
      setState(() => _lsDirectory = lsd);
      try {
        _scrollTop();
      } catch (e) {}
    });
  }

  GestureDetector _topNavigation() {
    return GestureDetector(
      child: ListTile(
        leading: const Icon(Icons.arrow_upward),
        title: const Text("..", textScaleFactor: 1.5),
      ),
      onTap: () {
        var li = _directory.path.split("/");
        li.removeLast();
        _directory = Directory(li.join("/"));
        ls(_directory);
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
      String p = _directory.path + "/" + item.filename;
      _directory = Directory(p);
      ls(_directory);
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
        if (directoryTrailingBuilder != null)
          w = directoryTrailingBuilder(context, item);
        else
          w = const Text("");
        break;
      default:
        if (fileTrailingBuilder != null)
          w = fileTrailingBuilder(context, item);
        else
          w = Text("${item.filesize}");
    }
    return w;
  }

  List<Widget> _getSlideIconActions(BuildContext context, DirectoryItem item) {
    List<Widget> ic = [];
    ic.add(IconSlideAction(
      caption: 'Delete',
      color: Colors.red,
      icon: Icons.delete,
      onTap: () => _confirmDeleteDialog(context, item),
    ));
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
                deleteItem(item).then((_) {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _addDir(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
                  createDir(_addDirController.text, _directory.path);
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

  _scrollTop() {
    _scrollController.animateTo(_scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 10), curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class Filex extends StatefulWidget {
  Filex(
      {@required this.directory,
      this.showHiddenFiles = false,
      this.fileTrailingBuilder,
      this.directoryTrailingBuilder,
      this.directoryLeadingBuilder,
      this.compact = false});

  final Directory directory;
  final bool showHiddenFiles;
  final FilexActionBuilder fileTrailingBuilder;
  final FilexActionBuilder directoryTrailingBuilder;
  final FilexActionBuilder directoryLeadingBuilder;
  final bool compact;

  @override
  _FilexState createState() => _FilexState(
      directory: directory,
      showHiddenFiles: showHiddenFiles,
      fileTrailingBuilder: fileTrailingBuilder,
      directoryTrailingBuilder: directoryTrailingBuilder,
      directoryLeadingBuilder: directoryLeadingBuilder,
      compact: compact);
}
