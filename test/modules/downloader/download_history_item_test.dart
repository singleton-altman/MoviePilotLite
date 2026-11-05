import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/downloader/models/download_history_item.dart';

void main() {
  test('parses published string season, episode and user identifiers', () {
    final item = DownloadHistoryItem.fromJson({
      'id': 9,
      'title': 'Example',
      'seasons': 'S01-S02',
      'episodes': 'E01-E12',
      'userid': 'external-user',
      'episode_group': 'group-id',
      'note': {'source': 'manual'},
    });
    expect(item.seasons, 'S01-S02');
    expect(item.episodes, 'E01-E12');
    expect(item.userid, 'external-user');
    expect(item.buildMetaLine(), 'S01-S02 · E01-E12');
    expect(item.episodeGroup, 'group-id');
    expect(item.note, {'source': 'manual'});
  });

  test('delete payload preserves unknown fields and original types', () {
    final input = <String, dynamic>{
      'id': 9,
      'seasons': '1',
      'episodes': '1,2',
      'userid': '007',
      'note': {
        'nested': ['private-value'],
      },
      'future_field': {'enabled': true},
    };
    final item = DownloadHistoryItem.fromJson(input);
    expect(item.toJson(), input);
    (input['note'] as Map)['nested'] = <String>[];
    final output = item.toJson();
    expect(output['note'], {
      'nested': ['private-value'],
    });
    (output['future_field'] as Map)['enabled'] = false;
    expect(item.toJson()['future_field'], {'enabled': true});
  });

  test('tolerates legacy list and numeric identifiers without cast errors', () {
    final item = DownloadHistoryItem.fromJson({
      'id': '3',
      'seasons': [1, 2],
      'episodes': [3, 4],
      'userid': 7,
      'tmdbid': '100',
    });
    expect(item.id, 3);
    expect(item.tmdbid, 100);
    expect(item.seasons, '1/2');
    expect(item.userid, '7');
    expect(item.toJson()['seasons'], [1, 2]);
  });
}
