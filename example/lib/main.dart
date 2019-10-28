import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:filex/filex.dart';
import 'package:path_provider/path_provider.dart';

Directory dir;
final onReady = Completer<void>();

Future<void> getDir() async {
  dir = await getApplicationDocumentsDirectory();
  onReady.complete();
}

void main() {
  runApp(MyApp());
  getDir();
}

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

class _FileExplorerState extends State<FileExplorer> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    onReady.future.then((_) => setState(() => _ready = true));
  }

  @override
  Widget build(BuildContext context) {
    final controller = FilexController(path: dir.path);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Files"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => controller.addDirectory(context),
          )
        ],
      ),
      body: _ready
          ? Filex(
              controller: controller,
              actions: <PredefinedAction>[PredefinedAction.delete],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
