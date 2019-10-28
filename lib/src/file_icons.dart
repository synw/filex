import 'package:flutter/material.dart';

/// Set the icon for a file
Icon setFileIcon(String filename) {
  final _extension = filename.split(".").last;
  if (_extension == "db" || _extension == "sqlite" || _extension == "sqlite3") {
    return const Icon(Icons.dns);
  } else if (_extension == "jpg" ||
      _extension == "jpeg" ||
      _extension == "png") {
    return const Icon(Icons.image);
  }
  // default
  return const Icon(Icons.description, color: Colors.grey);
}
