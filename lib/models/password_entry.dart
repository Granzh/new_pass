class PasswordEntry {
  final String name;
  final String fullPath;
  final bool isFolder;
  final List<PasswordEntry> children;

  PasswordEntry({
    required this.name,
    required this.fullPath,
    required this.isFolder,
    this.children = const [],
  });
}