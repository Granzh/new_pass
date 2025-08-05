import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:new_pass/services/password_structure_item.dart';
import 'package:new_pass/services/local_password_structure_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('LocalPasswordStructureService', () {
    late MemoryFileSystem fileSystem;
    late ProfilePathResolver mockProfilePathResolver;
    late LocalPasswordStructureService service;
    late String profileRootPath;

    setUp(() {
      fileSystem = MemoryFileSystem();
      mockProfilePathResolver = ProfilePathResolver();
      service = LocalPasswordStructureService(
        fileSystem: fileSystem,
        profilePathResolver: mockProfilePathResolver,
      );
      profileRootPath = '/test/profile';
    });

    group('listItems', () {
      test('returns empty list when directory does not exist', () async {
        final result = await service.listItems(profileId: 'test-profile');
        expect(result, isEmpty);
      });

      test('returns empty list when directory is empty', () async {
        await fileSystem.directory(profileRootPath).create(recursive: true);

        final result = await service.listItems(profileId: 'test-profile');
        expect(result, isEmpty);
      });

      test('lists files and folders correctly', () async {
        // Создаем тестовую структуру
        await fileSystem.directory(profileRootPath).create(recursive: true);
        await fileSystem.directory('$profileRootPath/folder1').create();
        await fileSystem.directory('$profileRootPath/folder2').create();
        await fileSystem.file('$profileRootPath/password1.gpg').create();
        await fileSystem.file('$profileRootPath/password2.gpg').create();
        await fileSystem.file('$profileRootPath/readme.txt').create(); // Не .gpg файл

        final result = await service.listItems(profileId: 'test-profile');

        expect(result, hasLength(4)); // 2 папки + 2 .gpg файла

        // Проверяем сортировку: сначала папки, потом файлы
        expect(result[0].type, PasswordStructureItemType.folder);
        expect(result[0].name, 'folder1');
        expect(result[1].type, PasswordStructureItemType.folder);
        expect(result[1].name, 'folder2');
        expect(result[2].type, PasswordStructureItemType.file);
        expect(result[2].name, 'password1.gpg');
        expect(result[3].type, PasswordStructureItemType.file);
        expect(result[3].name, 'password2.gpg');
      });

      test('sorts items correctly (folders first, then alphabetically)', () async {
        await fileSystem.directory(profileRootPath).create(recursive: true);
        await fileSystem.directory('$profileRootPath/zfolder').create();
        await fileSystem.directory('$profileRootPath/afolder').create();
        await fileSystem.file('$profileRootPath/zpassword.gpg').create();
        await fileSystem.file('$profileRootPath/apassword.gpg').create();

        final result = await service.listItems(profileId: 'test-profile');

        expect(result, hasLength(4));
        expect(result[0].name, 'afolder');
        expect(result[1].name, 'zfolder');
        expect(result[2].name, 'apassword.gpg');
        expect(result[3].name, 'zpassword.gpg');
      });

      test('handles subdirectory path correctly', () async {
        await fileSystem.directory('$profileRootPath/subfolder').create(recursive: true);
        await fileSystem.file('$profileRootPath/subfolder/password.gpg').create();

        final result = await service.listItems(
          profileId: 'test-profile',
          directoryPath: 'subfolder',
        );

        expect(result, hasLength(1));
        expect(result[0].name, 'password.gpg');
        expect(result[0].relativePath, 'subfolder/password.gpg');
        expect(result[0].parentPath, 'subfolder');
      });

      test('throws error when directoryPath tries to escape profile root', () async {
        expect(
              () => service.listItems(
            profileId: 'test-profile',
            directoryPath: '../escape',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('ignores non-gpg files', () async {
        await fileSystem.directory(profileRootPath).create(recursive: true);
        await fileSystem.file('$profileRootPath/password.gpg').create();
        await fileSystem.file('$profileRootPath/readme.txt').create();
        await fileSystem.file('$profileRootPath/config.json').create();

        final result = await service.listItems(profileId: 'test-profile');

        expect(result, hasLength(1));
        expect(result[0].name, 'password.gpg');
      });

      test('handles case-insensitive .gpg extension', () async {
        await fileSystem.directory(profileRootPath).create(recursive: true);
        await fileSystem.file('$profileRootPath/password1.gpg').create();
        await fileSystem.file('$profileRootPath/password2.GPG').create();
        await fileSystem.file('$profileRootPath/password3.Gpg').create();

        final result = await service.listItems(profileId: 'test-profile');

        expect(result, hasLength(3));
      });

      test('handles deep directory structure', () async {
        String deepPath = '$profileRootPath/level1/level2/level3';
        await fileSystem.directory(deepPath).create(recursive: true);
        await fileSystem.file('$deepPath/deep_password.gpg').create();

        final result = await service.listItems(
          profileId: 'test-profile',
          directoryPath: 'level1/level2/level3',
        );

        expect(result, hasLength(1));
        expect(result[0].name, 'deep_password.gpg');
        expect(result[0].relativePath, 'level1/level2/level3/deep_password.gpg');
        expect(result[0].parentPath, 'level1/level2/level3');
      });

      test('handles ProfilePathResolver error', () async {
        when(mockProfilePathResolver.getRootPathForProfile('invalid-profile'))
            .thenThrow(Exception('Profile not found'));

        expect(
              () => service.listItems(profileId: 'invalid-profile'),
          throwsException,
        );
      });
    });

    group('PasswordStructureItem', () {
      test('equality works correctly', () {
        final item1 = PasswordStructureItem(
          id: 'test.gpg',
          name: 'test.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'test.gpg',
          parentPath: '',
        );

        final item2 = PasswordStructureItem(
          id: 'test.gpg',
          name: 'test.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'test.gpg',
          parentPath: '',
        );

        final item3 = PasswordStructureItem(
          id: 'other.gpg',
          name: 'other.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'other.gpg',
          parentPath: '',
        );

        expect(item1, equals(item2));
        expect(item1, isNot(equals(item3)));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('toString provides useful information', () {
        final item = PasswordStructureItem(
          id: 'test.gpg',
          name: 'test.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'folder/test.gpg',
          parentPath: 'folder',
        );

        final result = item.toString();
        expect(result, contains('test.gpg'));
        expect(result, contains('folder/test.gpg'));
        expect(result, contains('file'));
      });
    });

    group('helper methods', () {
      setUp(() async {
        await fileSystem.directory(profileRootPath).create(recursive: true);
        await fileSystem.file('$profileRootPath/test.gpg').create();
        await fileSystem.directory('$profileRootPath/testfolder').create();
      });

      test('getFullPath returns correct path', () async {
        final item = PasswordStructureItem(
          id: 'test.gpg',
          name: 'test.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'test.gpg',
          parentPath: '',
        );

        final fullPath = await service.getFullPath('test-profile', item);
        expect(fullPath, equals('$profileRootPath/test.gpg'));
      });

      test('exists returns true for existing file', () async {
        final item = PasswordStructureItem(
          id: 'test.gpg',
          name: 'test.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'test.gpg',
          parentPath: '',
        );

        final exists = await service.exists('test-profile', item);
        expect(exists, isTrue);
      });

      test('exists returns false for non-existing file', () async {
        final item = PasswordStructureItem(
          id: 'nonexistent.gpg',
          name: 'nonexistent.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'nonexistent.gpg',
          parentPath: '',
        );

        final exists = await service.exists('test-profile', item);
        expect(exists, isFalse);
      });

      test('createFile creates file correctly', () async {
        final item = PasswordStructureItem(
          id: 'new.gpg',
          name: 'new.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'new.gpg',
          parentPath: '',
        );

        final file = await service.createFile('test-profile', item);
        expect(await file.exists(), isTrue);
        expect(file.path, equals('$profileRootPath/new.gpg'));
      });

      test('createFile throws error for folder item', () async {
        final item = PasswordStructureItem(
          id: 'folder',
          name: 'folder',
          type: PasswordStructureItemType.folder,
          relativePath: 'folder',
          parentPath: '',
        );

        expect(
              () => service.createFile('test-profile', item),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('createDirectory creates directory correctly', () async {
        final item = PasswordStructureItem(
          id: 'newfolder',
          name: 'newfolder',
          type: PasswordStructureItemType.folder,
          relativePath: 'newfolder',
          parentPath: '',
        );

        final directory = await service.createDirectory('test-profile', item);
        expect(await directory.exists(), isTrue);
        expect(directory.path, equals('$profileRootPath/newfolder'));
      });

      test('createDirectory throws error for file item', () async {
        final item = PasswordStructureItem(
          id: 'test.gpg',
          name: 'test.gpg',
          type: PasswordStructureItemType.file,
          relativePath: 'test.gpg',
          parentPath: '',
        );

        expect(
              () => service.createDirectory('test-profile', item),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('edge cases', () {
      test('handles empty file and folder names gracefully', () async {
        // Этот тест может быть специфичным для файловой системы
        await fileSystem.directory(profileRootPath).create(recursive: true);

        final result = await service.listItems(profileId: 'test-profile');
        expect(result, isEmpty);
      });

      test('handles special characters in file names', () async {
        await fileSystem.directory(profileRootPath).create(recursive: true);
        await fileSystem.file('$profileRootPath/test@#\$%.gpg').create();
        await fileSystem.file('$profileRootPath/тест.gpg').create(); // Unicode

        final result = await service.listItems(profileId: 'test-profile');
        expect(result, hasLength(2));
      });

      test('handles very long paths', () async {
        final longPath = 'very/long/path/with/many/levels/that/might/cause/issues';
        await fileSystem.directory('$profileRootPath/$longPath').create(recursive: true);
        await fileSystem.file('$profileRootPath/$longPath/test.gpg').create();

        final result = await service.listItems(
          profileId: 'test-profile',
          directoryPath: longPath,
        );

        expect(result, hasLength(1));
        expect(result[0].name, 'test.gpg');
      });
    });
  });
}
