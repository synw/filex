import 'dart:io';
import 'package:flutter/material.dart';
import 'package:filex/filex.dart';
import 'package:path_provider/path_provider.dart';

Directory dir;

Future<void> getDir() async {
  dir = await getApplicationDocumentsDirectory();
}

void main() {
  getDir().then((_) => runApp(MyApp()));
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

class FileExplorer extends StatelessWidget {
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
      body: Filex(
        controller: controller,
        actions: <PredefinedAction>[PredefinedAction.delete],
      ),
    );
  }
}
