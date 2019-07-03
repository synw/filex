# Filex

Configurable file explorer widget for Flutter

## Usage

Simple:

   ```dart
   Filex(directory: Directory("some_dir_path"))
   ```

With options:

   ```dart
   import 'package:filex/filex.dart';

   Filex(
     compact: true,
     directory: Directory("some_dir_path"),
     directoryTrailingBuilder: (context, item) {
       return GestureDetector(
         child: Padding(
           padding: const EdgeInsets.fromLTRB(0, 0, 3.0, 0),
           child: Icon(Icons.file_download,
             color: Colors.grey, size: 20.0)),
           onTap: () => doSomething(item));
   })
   ```

Other options are: `fileTrailingBuilder` and `directoryLeadingBuilder`
