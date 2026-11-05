import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/search/controllers/search_index_controller.dart';
import 'package:moviepilot_mobile/modules/search/models/search_suggestion.dart';

List<SearchSuggestionCategory> _categoriesFor({
  bool canSearch = false,
  bool canSubscribe = false,
  bool canManage = false,
  bool musicSupported = false,
}) {
  return SearchIndexController.buildSuggestionsFor(
    '沙丘',
    canSearch: canSearch,
    canSubscribe: canSubscribe,
    canManage: canManage,
    musicSupported: musicSupported,
  ).map((item) => item.category).toList();
}

void main() {
  const mediaCatalog = [
    SearchSuggestionCategory.mediaTitle,
    SearchSuggestionCategory.mediaCollection,
    SearchSuggestionCategory.actor,
  ];

  group('search suggestions follow account permissions', () {
    test('an account without feature permissions only gets media catalog', () {
      expect(_categoriesFor(), mediaCatalog);
    });

    test('music suggestion only depends on server support', () {
      expect(
        _categoriesFor(musicSupported: true),
        [...mediaCatalog, SearchSuggestionCategory.music],
      );
    });

    test('site search suggestion requires the search permission', () {
      expect(
        _categoriesFor(canSearch: true),
        [...mediaCatalog, SearchSuggestionCategory.site],
      );
      expect(
        _categoriesFor(canSubscribe: true, canManage: true),
        isNot(contains(SearchSuggestionCategory.site)),
      );
    });

    test('share and subscription suggestions require subscribe permission', () {
      expect(
        _categoriesFor(canSubscribe: true),
        [
          ...mediaCatalog,
          SearchSuggestionCategory.share,
          SearchSuggestionCategory.subscription,
        ],
      );
      expect(
        _categoriesFor(canSearch: true, canManage: true),
        isNot(
          anyOf(
            contains(SearchSuggestionCategory.share),
            contains(SearchSuggestionCategory.subscription),
          ),
        ),
      );
    });

    test('organize history suggestion requires the manage permission', () {
      expect(
        _categoriesFor(canManage: true),
        [...mediaCatalog, SearchSuggestionCategory.history],
      );
      expect(
        _categoriesFor(canSearch: true, canSubscribe: true),
        isNot(contains(SearchSuggestionCategory.history)),
      );
    });

    test('full permissions keep every category in display order', () {
      expect(
        _categoriesFor(
          canSearch: true,
          canSubscribe: true,
          canManage: true,
          musicSupported: true,
        ),
        [
          ...mediaCatalog,
          SearchSuggestionCategory.music,
          SearchSuggestionCategory.share,
          SearchSuggestionCategory.history,
          SearchSuggestionCategory.subscription,
          SearchSuggestionCategory.site,
        ],
      );
    });

    test('every suggestion carries the raw keyword', () {
      final items = SearchIndexController.buildSuggestionsFor(
        '沙丘',
        canSearch: true,
        canSubscribe: true,
        canManage: true,
        musicSupported: true,
      );
      expect(items.map((item) => item.keyword).toSet(), {'沙丘'});
    });
  });
}
