import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';

void main() {
  test('only supported sources are offered for explore', () {
    expect(kMusicExploreSources.map((e) => e.id), [
      'musicbrainz',
      'doubanmusic',
    ]);
    expect(kMusicSources.map((e) => e.id), contains('theaudiodb'));
  });

  test('explore preserves entity type and requested source fallback', () {
    final item = MusicExploreItem.fromJson({
      'music_type': ' recording ',
      'media_source': ' ',
      'media_id': 42,
      'year': '2026',
      'artists': [
        ' A ',
        null,
        {'name': 'not schema'},
        'B',
      ],
      'poster_path': 'https://image.example/cover',
    }, fallbackSource: 'doubanmusic');
    expect(item.musicType, 'recording');
    expect(item.isAlbum, isFalse);
    expect(item.mediaSource, 'doubanmusic');
    expect(item.mediaId, '42');
    expect(item.year, 2026);
    expect(item.displayArtist, 'A / B');
    expect(item.coverUrl, 'https://image.example/cover');
  });

  test(
    'album numeric strings, nullable and malformed optional fields are safe',
    () {
      final album = MusicAlbumDetail.fromJson({
        'title': ' Album ',
        'media_source': 'TheAudioDB',
        'media_id': 123,
        'year': '2026',
        'total_tracks': '10',
        'rating': '8.5',
        'genres': 'not a list',
        'artists': ['Artist', null],
        'tracks': [
          null,
          'bad',
          {
            'title': ' Song ',
            'duration': '245',
            'track_number': '1',
            'disc_number': 2.0,
            'artists': false,
          },
        ],
      });
      expect(album.mediaSource, 'theaudiodb');
      expect(album.displayTitle, 'Album');
      expect(album.displayArtist, 'Artist');
      expect(album.year, 2026);
      expect(album.totalTracks, 10);
      expect(album.rating, 8.5);
      expect(album.genres, isEmpty);
      expect(album.tracks.single.displayDuration, '4:05');
      expect(album.tracks.single.trackNumber, 1);
      expect(album.tracks.single.discNumber, 2);
      expect(album.tracks.single.artists, isEmpty);
    },
  );

  test('missing detail identity remains missing for route source fallback', () {
    final album = MusicAlbumDetail.fromJson({
      'tracks': {},
      'year': true,
      'rating': 'NaN',
    });
    expect(album.mediaSource, isEmpty);
    expect(album.mediaId, isEmpty);
    expect(album.year, isNull);
    expect(album.rating, isNull);
    expect(album.tracks, isEmpty);
    final artist = MusicArtistDetail.fromJson({
      'album_count': '2',
      'aliases': false,
      'poster_path': 'poster',
    });
    expect(artist.albumCount, 2);
    expect(artist.aliases, isEmpty);
    expect(artist.imageUrl, 'poster');
  });
}
