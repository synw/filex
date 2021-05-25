import 'package:flutter/material.dart';
import 'filesystem.dart';

/// Actions on slidable
enum PredefinedAction {
  /// Delete items
  delete
}

/// Action builder for leading and trailing widgets
typedef FilexActionBuilder = Widget Function(
    BuildContext context, DirectoryItem item);

/// Action builder for slidable actions
typedef FilexSlidableActionBuilder = void Function(
    BuildContext context, DirectoryItem item);

/// Action for slidable
class FilexSlidableAction {
  /// Default constructor
  FilexSlidableAction(
      {required this.color,
      required this.iconData,
      required this.name,
      required this.onTap});

  final Color color;
  final IconData iconData;
  final String name;
  final FilexSlidableActionBuilder onTap;
}
