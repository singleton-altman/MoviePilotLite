import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_dynamic_source.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_filters.dart';

void main() {
  group('DiscoverFilters serialization', () {
    test('round-trips through JSON preserving every field', () {
      const filters = DiscoverFilters(
        page: 3,
        sortBy: 'vote_average.desc',
        mediaType: '电视剧',
        selectedGenres: ['28', '12'],
        selectedRegions: ['华语', '日本'],
        selectedLanguages: ['中文', '日语'],
        selectedDecade: '2010年代',
        withOriginalLanguage: 'zh',
        withKeywords: 'kw',
        withWatchProviders: '8',
        voteAverage: 7,
        voteCount: 100,
        releaseDate: '2015-2020',
        bangumiCategory: 'anime',
        bangumiYear: '2019',
        anilistGenre: 'Action',
        anilistFormat: 'TV',
        anilistSeason: 'SPRING',
        anilistSeasonYear: '2021',
        anilistStatus: 'FINISHED',
        anilistCountry: 'JP',
      );

      final restored = DiscoverFilters.fromJson(
        jsonDecode(jsonEncode(filters.toJson())) as Map<String, dynamic>,
      );

      expect(restored.page, filters.page);
      expect(restored.sortBy, filters.sortBy);
      expect(restored.mediaType, filters.mediaType);
      expect(restored.selectedGenres, filters.selectedGenres);
      expect(restored.selectedRegions, filters.selectedRegions);
      expect(restored.selectedLanguages, filters.selectedLanguages);
      expect(restored.selectedDecade, filters.selectedDecade);
      expect(restored.withOriginalLanguage, filters.withOriginalLanguage);
      expect(restored.withWatchProviders, filters.withWatchProviders);
      expect(restored.voteAverage, filters.voteAverage);
      expect(restored.voteCount, filters.voteCount);
      expect(restored.releaseDate, filters.releaseDate);
      expect(restored.bangumiCategory, filters.bangumiCategory);
      expect(restored.bangumiYear, filters.bangumiYear);
      expect(restored.anilistGenre, filters.anilistGenre);
      expect(restored.anilistFormat, filters.anilistFormat);
      expect(restored.anilistSeason, filters.anilistSeason);
      expect(restored.anilistSeasonYear, filters.anilistSeasonYear);
      expect(restored.anilistStatus, filters.anilistStatus);
      expect(restored.anilistCountry, filters.anilistCountry);
    });

    test('falls back to defaults for missing or malformed fields', () {
      final restored = DiscoverFilters.fromJson(<String, dynamic>{
        'sortBy': 'popularity.asc',
        'voteAverage': '5',
        'selectedGenres': 'not-a-list',
      });

      const defaults = DiscoverFilters();
      expect(restored.sortBy, 'popularity.asc');
      expect(restored.voteAverage, 5);
      expect(restored.selectedGenres, isEmpty);
      expect(restored.mediaType, defaults.mediaType);
      expect(restored.page, defaults.page);
      expect(restored.voteCount, defaults.voteCount);
    });
  });

  group('DiscoverDynamicFilters serialization', () {
    test('round-trips value map through JSON', () {
      const filters = DiscoverDynamicFilters(
        values: {'mtype': 'movie', 'region': 'us'},
      );

      final restored = DiscoverDynamicFilters.fromJson(
        jsonDecode(jsonEncode(filters.toJson())) as Map<String, dynamic>,
      );

      expect(restored.values, filters.values);
    });

    test('yields empty values for malformed payload', () {
      final restored = DiscoverDynamicFilters.fromJson(<String, dynamic>{
        'values': 'not-a-map',
      });

      expect(restored.values, isEmpty);
    });
  });
}
