class DiscoverFilters {
  const DiscoverFilters({
    this.page = 1,
    this.sortBy = 'popularity.desc',
    this.mediaType = '电影',
    this.selectedGenres = const <String>[],
    this.selectedRegions = const <String>[],
    this.selectedLanguages = const <String>[],
    this.selectedDecade = '',
    this.withOriginalLanguage = '',
    this.withKeywords = '',
    this.withWatchProviders = '',
    this.voteAverage = 0,
    this.voteCount = 10,
    this.releaseDate = '',
    this.bangumiCategory = '',
    this.bangumiYear = '',
    this.anilistGenre = '',
    this.anilistFormat = '',
    this.anilistSeason = '',
    this.anilistSeasonYear = '',
    this.anilistStatus = '',
    this.anilistCountry = '',
  });

  final int page;
  final String sortBy;
  final String mediaType;
  final List<String> selectedGenres;
  final List<String> selectedRegions;
  final List<String> selectedLanguages;
  final String selectedDecade;
  final String withOriginalLanguage;
  final String withKeywords;
  final String withWatchProviders;
  final int voteAverage;
  final int voteCount;
  final String releaseDate;
  final String bangumiCategory;
  final String bangumiYear;
  final String anilistGenre;
  final String anilistFormat;
  final String anilistSeason;
  final String anilistSeasonYear;
  final String anilistStatus;
  final String anilistCountry;

  DiscoverFilters copyWith({
    int? page,
    String? sortBy,
    String? mediaType,
    List<String>? selectedGenres,
    List<String>? selectedRegions,
    List<String>? selectedLanguages,
    String? selectedDecade,
    String? withOriginalLanguage,
    String? withKeywords,
    String? withWatchProviders,
    int? voteAverage,
    int? voteCount,
    String? releaseDate,
    String? bangumiCategory,
    String? bangumiYear,
    String? anilistGenre,
    String? anilistFormat,
    String? anilistSeason,
    String? anilistSeasonYear,
    String? anilistStatus,
    String? anilistCountry,
  }) {
    return DiscoverFilters(
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
      mediaType: mediaType ?? this.mediaType,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedRegions: selectedRegions ?? this.selectedRegions,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      selectedDecade: selectedDecade ?? this.selectedDecade,
      withOriginalLanguage: withOriginalLanguage ?? this.withOriginalLanguage,
      withKeywords: withKeywords ?? this.withKeywords,
      withWatchProviders: withWatchProviders ?? this.withWatchProviders,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      bangumiCategory: bangumiCategory ?? this.bangumiCategory,
      bangumiYear: bangumiYear ?? this.bangumiYear,
      anilistGenre: anilistGenre ?? this.anilistGenre,
      anilistFormat: anilistFormat ?? this.anilistFormat,
      anilistSeason: anilistSeason ?? this.anilistSeason,
      anilistSeasonYear: anilistSeasonYear ?? this.anilistSeasonYear,
      anilistStatus: anilistStatus ?? this.anilistStatus,
      anilistCountry: anilistCountry ?? this.anilistCountry,
    );
  }

  Map<String, String> toQueryParameters({
    bool useOriginCountry = false,
    bool useProductionCountries = false,
  }) {
    final genres = List<String>.from(selectedGenres)..sort();
    final regions = List<String>.from(selectedRegions)..sort();
    final languages = List<String>.from(selectedLanguages)..sort();
    final regionCodes = _mapRegionCodes(regions);
    final languageCodes = _mapLanguageCodes(languages);
    final originalLanguage = languageCodes.isNotEmpty
        ? languageCodes.join('|')
        : (withOriginalLanguage.isNotEmpty ? withOriginalLanguage : '');
    final release = releaseDate.isNotEmpty
        ? releaseDate
        : (bangumiYear.isNotEmpty
              ? bangumiYear
              : _encodeReleaseDate(selectedDecade));
    final params = <String, String>{
      'page': page.toString(),
      'sort_by': sortBy,
      'with_genres': genres.join(','),
      'with_original_language': originalLanguage,
      'with_keywords': '',
      'with_watch_providers': withWatchProviders,
      'vote_average': voteAverage.toString(),
      'vote_count': voteCount.toString(),
      'release_date': release,
      'year': release,
    };
    if (useOriginCountry && regionCodes.isNotEmpty) {
      params['origin_country'] = regionCodes.join('|');
    }
    if (useProductionCountries && regionCodes.isNotEmpty) {
      params['production_countries'] = regionCodes.join('|');
    }
    return params;
  }

  Map<String, String> toAnilistQueryParameters() {
    final params = <String, String>{
      'page': page.toString(),
      'count': '20',
    };
    if (anilistGenre.isNotEmpty) params['genre'] = anilistGenre;
    if (anilistFormat.isNotEmpty) params['format'] = anilistFormat;
    if (anilistSeason.isNotEmpty) params['season'] = anilistSeason;
    if (anilistSeasonYear.isNotEmpty) {
      params['season_year'] = anilistSeasonYear;
    }
    if (anilistStatus.isNotEmpty) params['status'] = anilistStatus;
    if (anilistCountry.isNotEmpty) params['country'] = anilistCountry;
    if (sortBy.isNotEmpty) params['sort'] = sortBy;
    return params;
  }

  String signature({
    bool useOriginCountry = false,
    bool useProductionCountries = false,
  }) {
    final params = toQueryParameters(
      useOriginCountry: useOriginCountry,
      useProductionCountries: useProductionCountries,
    );
    final keys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer.write('$key=${params[key]};');
    }
    return buffer.toString();
  }

  static List<String> _mapRegionCodes(List<String> regions) {
    if (regions.isEmpty) return const <String>[];
    const mapping = <String, String>{
      '华语': 'CN,TW,HK',
      '欧美': 'US,FR,GB,DE,ES,IT,NL,PT,RU,UK',
      '韩国': 'KR',
      '日本': 'JP',
      '中国大陆': 'CN',
      '美国': 'US',
      '中国香港': 'HK',
      '中国台湾': 'TW',
      '英国': 'GB',
      '法国': 'FR',
      '德国': 'DE',
      '意大利': 'IT',
      '西班牙': 'ES',
      '印度': 'IN',
      '泰国': 'TH',
      '俄罗斯': 'RU',
      '加拿大': 'CA',
      '澳大利亚': 'AU',
    };
    return _expandCodes(regions, mapping);
  }

  static List<String> _mapLanguageCodes(List<String> languages) {
    if (languages.isEmpty) return const <String>[];
    const mapping = <String, String>{
      '中文': 'zh',
      '英语': 'en',
      '日语': 'ja',
      '韩语': 'ko',
      '粤语': 'zh',
      '法语': 'fr',
      '德语': 'de',
      '西班牙语': 'es',
      '意大利语': 'it',
      '俄语': 'ru',
      '葡萄牙语': 'pt',
      '阿拉伯语': 'ar',
      '印地语': 'hi',
      '泰语': 'th',
    };
    return _expandCodes(languages, mapping);
  }

  static List<String> _expandCodes(
    List<String> values,
    Map<String, String> mapping,
  ) {
    final result = <String>[];
    for (final value in values) {
      final mapped = mapping[value] ?? value;
      final parts = mapped.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      }
    }
    return result;
  }

  static String _encodeReleaseDate(String decadeLabel) {
    final trimmed = decadeLabel.trim();
    if (trimmed.isEmpty) return '';
    if (RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return trimmed;
    }
    if (trimmed.endsWith('年代')) {
      final number = trimmed.replaceAll('年代', '').trim();
      if (number.length == 2) {
        final start = int.tryParse('19$number');
        if (start == null) return trimmed;
        return '$start-${start + 9}';
      }
      if (number.length == 4) {
        final start = int.tryParse(number);
        if (start == null) return trimmed;
        return '$start-${start + 9}';
      }
    }
    return trimmed;
  }
}
