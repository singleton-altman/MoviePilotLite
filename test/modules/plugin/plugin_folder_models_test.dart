import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_folder_models.dart';

void main() {
  final document = <String, dynamic>{
    'Legacy': ['A', 'Unknown'],
    'Rich': {
      'plugins': ['B'],
      'order': 4,
      'icon': 'mdi-folder',
      'color': '#ffffff',
      'gradient': 'linear-gradient(...)',
      'background': null,
      'showIcon': false,
      'future': {
        'nested': [1, true],
      },
    },
    'Empty': {'icon': 'mdi-star'},
  };

  test('round trips mixed V2/V3 folders and unknown presentation fields', () {
    final folders = PluginFolders.fromJson(document);
    expect(folders.toJson(), document);
    expect(folders.pluginsIn('Rich'), ['B']);
    expect(folders.pluginsIn('Empty'), isEmpty);
  });

  test('rename keeps representation, metadata, and folder position', () {
    final folders = PluginFolders.fromJson(document).rename('Rich', '重命名');
    expect(folders.names, ['Legacy', '重命名', 'Empty']);
    expect(folders.toJson()['重命名'], document['Rich']);
    expect(folders.toJson()['Legacy'], document['Legacy']);
  });

  test('membership updates retain unknown members and all other fields', () {
    final original = PluginFolders.fromJson(document);
    final updated = original.withPlugins('Rich', ['B', 'C', 'C']);
    expect(updated.pluginsIn('Rich'), ['B', 'C']);
    expect(updated.toJson()['Rich'], {
      ...document['Rich'] as Map,
      'plugins': ['B', 'C'],
    });
    expect(updated.pluginsIn('Legacy'), ['A', 'Unknown']);
    expect(original.toJson(), document);
  });

  test('legacy membership stays a bare list', () {
    final updated = PluginFolders.fromJson(
      document,
    ).withPlugins('Legacy', ['Unknown']);
    expect(updated.toJson()['Legacy'], ['Unknown']);
  });

  test('create and delete affect only the target folder', () {
    final original = PluginFolders.fromJson(document);
    final created = original.create('新建');
    expect(created.toJson()['新建'], []);
    expect(created.delete('新建').toJson(), document);
    expect(original.delete('Rich').names, ['Legacy', 'Empty']);
  });

  test('refuses blank, overlong, duplicate, and missing folder changes', () {
    final folders = PluginFolders.fromJson(document);
    for (final name in ['', ' ', 'Legacy', 'x' * 129]) {
      expect(() => folders.create(name), throwsFormatException);
    }
    expect(() => folders.rename('Legacy', 'Rich'), throwsFormatException);
    expect(() => folders.rename('missing', 'New'), throwsStateError);
    expect(() => folders.withPlugins('missing', []), throwsStateError);
  });

  test('snapshots and returned values cannot mutate the original', () {
    final input = {
      'F': {
        'plugins': ['A'],
        'custom': [1],
      },
    };
    final folders = PluginFolders.fromJson(input);
    (input['F']!['plugins'] as List).clear();
    final exported = folders.toJson();
    (exported['F']['plugins'] as List).clear();
    expect(folders.pluginsIn('F'), ['A']);
    expect(() => folders.pluginsIn('F').clear(), throwsUnsupportedError);
  });

  test(
    'snapshot comparison includes nested metadata and ordered membership',
    () {
      final folders = PluginFolders.fromJson(document);
      expect(folders.sameAs(PluginFolders.fromJson(document)), isTrue);
      expect(
        folders.sameAs(folders.withPlugins('Legacy', ['Unknown', 'A'])),
        isFalse,
      );
      final changed = folders.toJson();
      changed['Rich']['future']['nested'] = [2];
      expect(folders.sameAs(PluginFolders.fromJson(changed)), isFalse);
    },
  );

  test(
    'snapshot detects folder reordering and ignores nested map key order',
    () {
      final original = PluginFolders.fromJson({
        'A': {'plugins': [], 'order': 1},
        'B': [],
      });
      final reordered = PluginFolders.fromJson({
        'B': [],
        'A': {'order': 1, 'plugins': []},
      });
      final equivalent = PluginFolders.fromJson({
        'A': {'order': 1, 'plugins': []},
        'B': [],
      });
      expect(original.sameAs(reordered), isFalse);
      expect(original.sameAs(equivalent), isTrue);
    },
  );

  test('folder named data is not mistaken for an envelope', () {
    final folders = PluginFolders.fromJson({
      'data': {
        'plugins': ['A'],
        'order': 1,
      },
    });
    expect(folders.names, ['data']);
    expect(folders.pluginsIn('data'), ['A']);
  });

  test('malformed membership is rejected rather than erased', () {
    for (final raw in [
      null,
      [],
      {'F': 1},
      {
        'F': ['A', 2],
      },
      {
        'F': {'plugins': 'A'},
      },
    ]) {
      expect(() => PluginFolders.fromJson(raw), throwsFormatException);
    }
  });

  test(
    'remote metadata uses verified id, name, url and optional source ID',
    () {
      final remote = PluginRemote.fromJson({
        'id': 'Plugin2',
        'name': 'Vue Plugin',
        'url': 'plugin/file/plugin/frontend/assets/remoteEntry.js',
        'source_plugin_id': 'Plugin',
      });
      expect(remote.id, 'Plugin2');
      expect(remote.sourcePluginId, 'Plugin');
      expect(remote.url, contains('remoteEntry.js'));
      expect(
        () => PluginRemote.fromJson({'name': 'Missing ID'}),
        throwsFormatException,
      );
    },
  );
}
