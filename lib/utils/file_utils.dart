import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:new_pass/models/password_entry.dart';

PasswordEntry buildTree(String rootPath) {
  final dir = Directory(rootPath);
  final Map<String, PasswordEntry> pathMap = {};

  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.gpg')) {
      final relative = p.relative(entity.path, from: rootPath);
      final parts = p.split(relative);
      _addToTree(pathMap, parts, entity.path);
    }
  }

  return PasswordEntry(name: 'root', fullPath: rootPath, isFolder: true, children: pathMap.values.toList());
}

void _addToTree(Map<String, PasswordEntry> map, List<String> parts, String fullPath, [int depth = 0]) {
  if (parts.isEmpty) return;

  final key = parts.first;
  if (parts.length == 1) {
    map[key] = PasswordEntry(name: key, fullPath: fullPath, isFolder: false);
  } else {
    map[key] ??= PasswordEntry(name: key, fullPath: key, isFolder: true, children: []);
    final childMap = {for (var c in map[key]!.children) c.name: c};
    _addToTree(childMap, parts.sublist(1), fullPath, depth + 1);
    map[key] = PasswordEntry(
      name: key,
      fullPath: fullPath,
      isFolder: true,
      children: childMap.values.toList(),
    );
  }
}