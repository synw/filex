import 'dart:async';

import 'package:filex/filex.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class _FileExplorerState extends State<FileExplorer> {
  var _ready = false;
  FilexController? controller;

  String _dirPath = '';
  final _onReady = Completer<void>();

  Future<void> getDir() async {
    //dir = await getApplicationDocumentsDirectory();
    final dir = await getApplicationDocumentsDirectory();
    _dirPath = dir.path;
    print("Storage dir: $_dirPath");
    _onReady.complete();
  }

  @override
  void initState() {
    getDir();
    if (_onReady.isCompleted) {
      controller = FilexController(path: _dirPath);
      setState(() {
        _ready = true;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Files"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => controller!.addDirectory(context),
          )
        ],
      ),
      body: _ready
          ? Filex(
              controller: controller!,
              actions: <PredefinedAction>[PredefinedAction.delete],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Filex Demo',
      home: FileExplorer(),
    );
  }
}

class FileExplorer extends StatefulWidget {
  @override
  _FileExplorerState createState() => _FileExplorerState();
}
