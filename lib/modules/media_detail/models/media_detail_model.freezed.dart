// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_detail_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MediaDetail _$MediaDetailFromJson(Map<String, dynamic> json) {
  return _MediaDetail.fromJson(json);
}

/// @nodoc
mixin _$MediaDetail {
  String? get source => throw _privateConstructorUsedError;
  String? get media_source => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get en_title => throw _privateConstructorUsedError;
  String? get hk_title => throw _privateConstructorUsedError;
  String? get tw_title => throw _privateConstructorUsedError;
  String? get sg_title => throw _privateConstructorUsedError;
  String? get year => throw _privateConstructorUsedError;
  String? get title_year => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get season => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get tmdb_id => throw _privateConstructorUsedError;
  String? get imdb_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get tvdb_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get douban_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get bangumi_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get anilist_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get anidb_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get collection_id => throw _privateConstructorUsedError;
  String? get mediaid_prefix => throw _privateConstructorUsedError;
  String? get media_id => throw _privateConstructorUsedError;
  String? get scrape_source => throw _privateConstructorUsedError;
  String? get original_language => throw _privateConstructorUsedError;
  String? get original_title => throw _privateConstructorUsedError;
  String? get release_date => throw _privateConstructorUsedError;
  String? get backdrop_path => throw _privateConstructorUsedError;
  String? get poster_path => throw _privateConstructorUsedError;
  String? get logo_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average => throw _privateConstructorUsedError;
  String? get overview => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get library_category => throw _privateConstructorUsedError;
  String? get metadata_category => throw _privateConstructorUsedError;
  String? get content_rating => throw _privateConstructorUsedError;
  String? get tvdb_slug => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
  List<SeasonEpisodes>? get seasons => throw _privateConstructorUsedError;
  List<SeasonInfo>? get season_info => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get names => throw _privateConstructorUsedError;
  List<Actor>? get actors => throw _privateConstructorUsedError;
  List<Director>? get directors => throw _privateConstructorUsedError;
  String? get detail_link => throw _privateConstructorUsedError;
  bool? get adult => throw _privateConstructorUsedError;
  List<CreatedBy>? get created_by => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_run_time => throw _privateConstructorUsedError;
  List<Genre>? get genres => throw _privateConstructorUsedError;
  String? get first_air_date => throw _privateConstructorUsedError;
  String? get homepage => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get languages => throw _privateConstructorUsedError;
  String? get last_air_date => throw _privateConstructorUsedError;
  List<Network>? get networks => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_episodes => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_seasons => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get origin_country => throw _privateConstructorUsedError;
  String? get original_name => throw _privateConstructorUsedError;
  List<ProductionCompany>? get production_companies =>
      throw _privateConstructorUsedError;
  List<ProductionCountry>? get production_countries =>
      throw _privateConstructorUsedError;
  List<SpokenLanguage>? get spoken_languages =>
      throw _privateConstructorUsedError;
  List<ReleaseDate>? get release_dates => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get tagline => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get genre_ids => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get runtime => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
  NextEpisodeToAir? get next_episode_to_air =>
      throw _privateConstructorUsedError;
  List<EpisodeGroup>? get episode_groups => throw _privateConstructorUsedError;
  EpisodeGroup? get episode_group => throw _privateConstructorUsedError;

  /// Serializes this MediaDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaDetailCopyWith<MediaDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaDetailCopyWith<$Res> {
  factory $MediaDetailCopyWith(
    MediaDetail value,
    $Res Function(MediaDetail) then,
  ) = _$MediaDetailCopyWithImpl<$Res, MediaDetail>;
  @useResult
  $Res call({
    String? source,
    String? media_source,
    String? type,
    String? title,
    String? en_title,
    String? hk_title,
    String? tw_title,
    String? sg_title,
    String? year,
    String? title_year,
    @JsonKey(fromJson: _intFromJson) int? season,
    @JsonKey(fromJson: _intFromJson) int? tmdb_id,
    String? imdb_id,
    @JsonKey(fromJson: _intFromJson) int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) int? douban_id,
    @JsonKey(fromJson: _intFromJson) int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) int? anilist_id,
    @JsonKey(fromJson: _intFromJson) int? anidb_id,
    @JsonKey(fromJson: _intFromJson) int? collection_id,
    String? mediaid_prefix,
    String? media_id,
    String? scrape_source,
    String? original_language,
    String? original_title,
    String? release_date,
    String? backdrop_path,
    String? poster_path,
    String? logo_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    String? overview,
    String? category,
    String? library_category,
    String? metadata_category,
    String? content_rating,
    String? tvdb_slug,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    List<SeasonEpisodes>? seasons,
    List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? names,
    List<Actor>? actors,
    List<Director>? directors,
    String? detail_link,
    bool? adult,
    List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_run_time,
    List<Genre>? genres,
    String? first_air_date,
    String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? languages,
    String? last_air_date,
    List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? origin_country,
    String? original_name,
    List<ProductionCompany>? production_companies,
    List<ProductionCountry>? production_countries,
    List<SpokenLanguage>? spoken_languages,
    List<ReleaseDate>? release_dates,
    String? status,
    String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    NextEpisodeToAir? next_episode_to_air,
    List<EpisodeGroup>? episode_groups,
    EpisodeGroup? episode_group,
  });

  $NextEpisodeToAirCopyWith<$Res>? get next_episode_to_air;
  $EpisodeGroupCopyWith<$Res>? get episode_group;
}

/// @nodoc
class _$MediaDetailCopyWithImpl<$Res, $Val extends MediaDetail>
    implements $MediaDetailCopyWith<$Res> {
  _$MediaDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = freezed,
    Object? media_source = freezed,
    Object? type = freezed,
    Object? title = freezed,
    Object? en_title = freezed,
    Object? hk_title = freezed,
    Object? tw_title = freezed,
    Object? sg_title = freezed,
    Object? year = freezed,
    Object? title_year = freezed,
    Object? season = freezed,
    Object? tmdb_id = freezed,
    Object? imdb_id = freezed,
    Object? tvdb_id = freezed,
    Object? douban_id = freezed,
    Object? bangumi_id = freezed,
    Object? anilist_id = freezed,
    Object? anidb_id = freezed,
    Object? collection_id = freezed,
    Object? mediaid_prefix = freezed,
    Object? media_id = freezed,
    Object? scrape_source = freezed,
    Object? original_language = freezed,
    Object? original_title = freezed,
    Object? release_date = freezed,
    Object? backdrop_path = freezed,
    Object? poster_path = freezed,
    Object? logo_path = freezed,
    Object? vote_average = freezed,
    Object? overview = freezed,
    Object? category = freezed,
    Object? library_category = freezed,
    Object? metadata_category = freezed,
    Object? content_rating = freezed,
    Object? tvdb_slug = freezed,
    Object? seasons = freezed,
    Object? season_info = freezed,
    Object? names = freezed,
    Object? actors = freezed,
    Object? directors = freezed,
    Object? detail_link = freezed,
    Object? adult = freezed,
    Object? created_by = freezed,
    Object? episode_run_time = freezed,
    Object? genres = freezed,
    Object? first_air_date = freezed,
    Object? homepage = freezed,
    Object? languages = freezed,
    Object? last_air_date = freezed,
    Object? networks = freezed,
    Object? number_of_episodes = freezed,
    Object? number_of_seasons = freezed,
    Object? origin_country = freezed,
    Object? original_name = freezed,
    Object? production_companies = freezed,
    Object? production_countries = freezed,
    Object? spoken_languages = freezed,
    Object? release_dates = freezed,
    Object? status = freezed,
    Object? tagline = freezed,
    Object? genre_ids = freezed,
    Object? vote_count = freezed,
    Object? popularity = freezed,
    Object? runtime = freezed,
    Object? next_episode_to_air = freezed,
    Object? episode_groups = freezed,
    Object? episode_group = freezed,
  }) {
    return _then(
      _value.copyWith(
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            media_source: freezed == media_source
                ? _value.media_source
                : media_source // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            en_title: freezed == en_title
                ? _value.en_title
                : en_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            hk_title: freezed == hk_title
                ? _value.hk_title
                : hk_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            tw_title: freezed == tw_title
                ? _value.tw_title
                : tw_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            sg_title: freezed == sg_title
                ? _value.sg_title
                : sg_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            year: freezed == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as String?,
            title_year: freezed == title_year
                ? _value.title_year
                : title_year // ignore: cast_nullable_to_non_nullable
                      as String?,
            season: freezed == season
                ? _value.season
                : season // ignore: cast_nullable_to_non_nullable
                      as int?,
            tmdb_id: freezed == tmdb_id
                ? _value.tmdb_id
                : tmdb_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            imdb_id: freezed == imdb_id
                ? _value.imdb_id
                : imdb_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            tvdb_id: freezed == tvdb_id
                ? _value.tvdb_id
                : tvdb_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            douban_id: freezed == douban_id
                ? _value.douban_id
                : douban_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            bangumi_id: freezed == bangumi_id
                ? _value.bangumi_id
                : bangumi_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            anilist_id: freezed == anilist_id
                ? _value.anilist_id
                : anilist_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            anidb_id: freezed == anidb_id
                ? _value.anidb_id
                : anidb_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            collection_id: freezed == collection_id
                ? _value.collection_id
                : collection_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            mediaid_prefix: freezed == mediaid_prefix
                ? _value.mediaid_prefix
                : mediaid_prefix // ignore: cast_nullable_to_non_nullable
                      as String?,
            media_id: freezed == media_id
                ? _value.media_id
                : media_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            scrape_source: freezed == scrape_source
                ? _value.scrape_source
                : scrape_source // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_language: freezed == original_language
                ? _value.original_language
                : original_language // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_title: freezed == original_title
                ? _value.original_title
                : original_title // ignore: cast_nullable_to_non_nullable
                      as String?,
            release_date: freezed == release_date
                ? _value.release_date
                : release_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            backdrop_path: freezed == backdrop_path
                ? _value.backdrop_path
                : backdrop_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            poster_path: freezed == poster_path
                ? _value.poster_path
                : poster_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            logo_path: freezed == logo_path
                ? _value.logo_path
                : logo_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            vote_average: freezed == vote_average
                ? _value.vote_average
                : vote_average // ignore: cast_nullable_to_non_nullable
                      as double?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            library_category: freezed == library_category
                ? _value.library_category
                : library_category // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata_category: freezed == metadata_category
                ? _value.metadata_category
                : metadata_category // ignore: cast_nullable_to_non_nullable
                      as String?,
            content_rating: freezed == content_rating
                ? _value.content_rating
                : content_rating // ignore: cast_nullable_to_non_nullable
                      as String?,
            tvdb_slug: freezed == tvdb_slug
                ? _value.tvdb_slug
                : tvdb_slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            seasons: freezed == seasons
                ? _value.seasons
                : seasons // ignore: cast_nullable_to_non_nullable
                      as List<SeasonEpisodes>?,
            season_info: freezed == season_info
                ? _value.season_info
                : season_info // ignore: cast_nullable_to_non_nullable
                      as List<SeasonInfo>?,
            names: freezed == names
                ? _value.names
                : names // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            actors: freezed == actors
                ? _value.actors
                : actors // ignore: cast_nullable_to_non_nullable
                      as List<Actor>?,
            directors: freezed == directors
                ? _value.directors
                : directors // ignore: cast_nullable_to_non_nullable
                      as List<Director>?,
            detail_link: freezed == detail_link
                ? _value.detail_link
                : detail_link // ignore: cast_nullable_to_non_nullable
                      as String?,
            adult: freezed == adult
                ? _value.adult
                : adult // ignore: cast_nullable_to_non_nullable
                      as bool?,
            created_by: freezed == created_by
                ? _value.created_by
                : created_by // ignore: cast_nullable_to_non_nullable
                      as List<CreatedBy>?,
            episode_run_time: freezed == episode_run_time
                ? _value.episode_run_time
                : episode_run_time // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            genres: freezed == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<Genre>?,
            first_air_date: freezed == first_air_date
                ? _value.first_air_date
                : first_air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            homepage: freezed == homepage
                ? _value.homepage
                : homepage // ignore: cast_nullable_to_non_nullable
                      as String?,
            languages: freezed == languages
                ? _value.languages
                : languages // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            last_air_date: freezed == last_air_date
                ? _value.last_air_date
                : last_air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            networks: freezed == networks
                ? _value.networks
                : networks // ignore: cast_nullable_to_non_nullable
                      as List<Network>?,
            number_of_episodes: freezed == number_of_episodes
                ? _value.number_of_episodes
                : number_of_episodes // ignore: cast_nullable_to_non_nullable
                      as int?,
            number_of_seasons: freezed == number_of_seasons
                ? _value.number_of_seasons
                : number_of_seasons // ignore: cast_nullable_to_non_nullable
                      as int?,
            origin_country: freezed == origin_country
                ? _value.origin_country
                : origin_country // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            production_companies: freezed == production_companies
                ? _value.production_companies
                : production_companies // ignore: cast_nullable_to_non_nullable
                      as List<ProductionCompany>?,
            production_countries: freezed == production_countries
                ? _value.production_countries
                : production_countries // ignore: cast_nullable_to_non_nullable
                      as List<ProductionCountry>?,
            spoken_languages: freezed == spoken_languages
                ? _value.spoken_languages
                : spoken_languages // ignore: cast_nullable_to_non_nullable
                      as List<SpokenLanguage>?,
            release_dates: freezed == release_dates
                ? _value.release_dates
                : release_dates // ignore: cast_nullable_to_non_nullable
                      as List<ReleaseDate>?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            tagline: freezed == tagline
                ? _value.tagline
                : tagline // ignore: cast_nullable_to_non_nullable
                      as String?,
            genre_ids: freezed == genre_ids
                ? _value.genre_ids
                : genre_ids // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            vote_count: freezed == vote_count
                ? _value.vote_count
                : vote_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double?,
            runtime: freezed == runtime
                ? _value.runtime
                : runtime // ignore: cast_nullable_to_non_nullable
                      as int?,
            next_episode_to_air: freezed == next_episode_to_air
                ? _value.next_episode_to_air
                : next_episode_to_air // ignore: cast_nullable_to_non_nullable
                      as NextEpisodeToAir?,
            episode_groups: freezed == episode_groups
                ? _value.episode_groups
                : episode_groups // ignore: cast_nullable_to_non_nullable
                      as List<EpisodeGroup>?,
            episode_group: freezed == episode_group
                ? _value.episode_group
                : episode_group // ignore: cast_nullable_to_non_nullable
                      as EpisodeGroup?,
          )
          as $Val,
    );
  }

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NextEpisodeToAirCopyWith<$Res>? get next_episode_to_air {
    if (_value.next_episode_to_air == null) {
      return null;
    }

    return $NextEpisodeToAirCopyWith<$Res>(_value.next_episode_to_air!, (
      value,
    ) {
      return _then(_value.copyWith(next_episode_to_air: value) as $Val);
    });
  }

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EpisodeGroupCopyWith<$Res>? get episode_group {
    if (_value.episode_group == null) {
      return null;
    }

    return $EpisodeGroupCopyWith<$Res>(_value.episode_group!, (value) {
      return _then(_value.copyWith(episode_group: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MediaDetailImplCopyWith<$Res>
    implements $MediaDetailCopyWith<$Res> {
  factory _$$MediaDetailImplCopyWith(
    _$MediaDetailImpl value,
    $Res Function(_$MediaDetailImpl) then,
  ) = __$$MediaDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? source,
    String? media_source,
    String? type,
    String? title,
    String? en_title,
    String? hk_title,
    String? tw_title,
    String? sg_title,
    String? year,
    String? title_year,
    @JsonKey(fromJson: _intFromJson) int? season,
    @JsonKey(fromJson: _intFromJson) int? tmdb_id,
    String? imdb_id,
    @JsonKey(fromJson: _intFromJson) int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) int? douban_id,
    @JsonKey(fromJson: _intFromJson) int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) int? anilist_id,
    @JsonKey(fromJson: _intFromJson) int? anidb_id,
    @JsonKey(fromJson: _intFromJson) int? collection_id,
    String? mediaid_prefix,
    String? media_id,
    String? scrape_source,
    String? original_language,
    String? original_title,
    String? release_date,
    String? backdrop_path,
    String? poster_path,
    String? logo_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    String? overview,
    String? category,
    String? library_category,
    String? metadata_category,
    String? content_rating,
    String? tvdb_slug,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    List<SeasonEpisodes>? seasons,
    List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? names,
    List<Actor>? actors,
    List<Director>? directors,
    String? detail_link,
    bool? adult,
    List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_run_time,
    List<Genre>? genres,
    String? first_air_date,
    String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? languages,
    String? last_air_date,
    List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? origin_country,
    String? original_name,
    List<ProductionCompany>? production_companies,
    List<ProductionCountry>? production_countries,
    List<SpokenLanguage>? spoken_languages,
    List<ReleaseDate>? release_dates,
    String? status,
    String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    NextEpisodeToAir? next_episode_to_air,
    List<EpisodeGroup>? episode_groups,
    EpisodeGroup? episode_group,
  });

  @override
  $NextEpisodeToAirCopyWith<$Res>? get next_episode_to_air;
  @override
  $EpisodeGroupCopyWith<$Res>? get episode_group;
}

/// @nodoc
class __$$MediaDetailImplCopyWithImpl<$Res>
    extends _$MediaDetailCopyWithImpl<$Res, _$MediaDetailImpl>
    implements _$$MediaDetailImplCopyWith<$Res> {
  __$$MediaDetailImplCopyWithImpl(
    _$MediaDetailImpl _value,
    $Res Function(_$MediaDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = freezed,
    Object? media_source = freezed,
    Object? type = freezed,
    Object? title = freezed,
    Object? en_title = freezed,
    Object? hk_title = freezed,
    Object? tw_title = freezed,
    Object? sg_title = freezed,
    Object? year = freezed,
    Object? title_year = freezed,
    Object? season = freezed,
    Object? tmdb_id = freezed,
    Object? imdb_id = freezed,
    Object? tvdb_id = freezed,
    Object? douban_id = freezed,
    Object? bangumi_id = freezed,
    Object? anilist_id = freezed,
    Object? anidb_id = freezed,
    Object? collection_id = freezed,
    Object? mediaid_prefix = freezed,
    Object? media_id = freezed,
    Object? scrape_source = freezed,
    Object? original_language = freezed,
    Object? original_title = freezed,
    Object? release_date = freezed,
    Object? backdrop_path = freezed,
    Object? poster_path = freezed,
    Object? logo_path = freezed,
    Object? vote_average = freezed,
    Object? overview = freezed,
    Object? category = freezed,
    Object? library_category = freezed,
    Object? metadata_category = freezed,
    Object? content_rating = freezed,
    Object? tvdb_slug = freezed,
    Object? seasons = freezed,
    Object? season_info = freezed,
    Object? names = freezed,
    Object? actors = freezed,
    Object? directors = freezed,
    Object? detail_link = freezed,
    Object? adult = freezed,
    Object? created_by = freezed,
    Object? episode_run_time = freezed,
    Object? genres = freezed,
    Object? first_air_date = freezed,
    Object? homepage = freezed,
    Object? languages = freezed,
    Object? last_air_date = freezed,
    Object? networks = freezed,
    Object? number_of_episodes = freezed,
    Object? number_of_seasons = freezed,
    Object? origin_country = freezed,
    Object? original_name = freezed,
    Object? production_companies = freezed,
    Object? production_countries = freezed,
    Object? spoken_languages = freezed,
    Object? release_dates = freezed,
    Object? status = freezed,
    Object? tagline = freezed,
    Object? genre_ids = freezed,
    Object? vote_count = freezed,
    Object? popularity = freezed,
    Object? runtime = freezed,
    Object? next_episode_to_air = freezed,
    Object? episode_groups = freezed,
    Object? episode_group = freezed,
  }) {
    return _then(
      _$MediaDetailImpl(
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        media_source: freezed == media_source
            ? _value.media_source
            : media_source // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        en_title: freezed == en_title
            ? _value.en_title
            : en_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        hk_title: freezed == hk_title
            ? _value.hk_title
            : hk_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        tw_title: freezed == tw_title
            ? _value.tw_title
            : tw_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        sg_title: freezed == sg_title
            ? _value.sg_title
            : sg_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        year: freezed == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as String?,
        title_year: freezed == title_year
            ? _value.title_year
            : title_year // ignore: cast_nullable_to_non_nullable
                  as String?,
        season: freezed == season
            ? _value.season
            : season // ignore: cast_nullable_to_non_nullable
                  as int?,
        tmdb_id: freezed == tmdb_id
            ? _value.tmdb_id
            : tmdb_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        imdb_id: freezed == imdb_id
            ? _value.imdb_id
            : imdb_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        tvdb_id: freezed == tvdb_id
            ? _value.tvdb_id
            : tvdb_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        douban_id: freezed == douban_id
            ? _value.douban_id
            : douban_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        bangumi_id: freezed == bangumi_id
            ? _value.bangumi_id
            : bangumi_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        anilist_id: freezed == anilist_id
            ? _value.anilist_id
            : anilist_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        anidb_id: freezed == anidb_id
            ? _value.anidb_id
            : anidb_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        collection_id: freezed == collection_id
            ? _value.collection_id
            : collection_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        mediaid_prefix: freezed == mediaid_prefix
            ? _value.mediaid_prefix
            : mediaid_prefix // ignore: cast_nullable_to_non_nullable
                  as String?,
        media_id: freezed == media_id
            ? _value.media_id
            : media_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        scrape_source: freezed == scrape_source
            ? _value.scrape_source
            : scrape_source // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_language: freezed == original_language
            ? _value.original_language
            : original_language // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_title: freezed == original_title
            ? _value.original_title
            : original_title // ignore: cast_nullable_to_non_nullable
                  as String?,
        release_date: freezed == release_date
            ? _value.release_date
            : release_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        backdrop_path: freezed == backdrop_path
            ? _value.backdrop_path
            : backdrop_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        poster_path: freezed == poster_path
            ? _value.poster_path
            : poster_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        logo_path: freezed == logo_path
            ? _value.logo_path
            : logo_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        vote_average: freezed == vote_average
            ? _value.vote_average
            : vote_average // ignore: cast_nullable_to_non_nullable
                  as double?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        library_category: freezed == library_category
            ? _value.library_category
            : library_category // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata_category: freezed == metadata_category
            ? _value.metadata_category
            : metadata_category // ignore: cast_nullable_to_non_nullable
                  as String?,
        content_rating: freezed == content_rating
            ? _value.content_rating
            : content_rating // ignore: cast_nullable_to_non_nullable
                  as String?,
        tvdb_slug: freezed == tvdb_slug
            ? _value.tvdb_slug
            : tvdb_slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        seasons: freezed == seasons
            ? _value._seasons
            : seasons // ignore: cast_nullable_to_non_nullable
                  as List<SeasonEpisodes>?,
        season_info: freezed == season_info
            ? _value._season_info
            : season_info // ignore: cast_nullable_to_non_nullable
                  as List<SeasonInfo>?,
        names: freezed == names
            ? _value._names
            : names // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        actors: freezed == actors
            ? _value._actors
            : actors // ignore: cast_nullable_to_non_nullable
                  as List<Actor>?,
        directors: freezed == directors
            ? _value._directors
            : directors // ignore: cast_nullable_to_non_nullable
                  as List<Director>?,
        detail_link: freezed == detail_link
            ? _value.detail_link
            : detail_link // ignore: cast_nullable_to_non_nullable
                  as String?,
        adult: freezed == adult
            ? _value.adult
            : adult // ignore: cast_nullable_to_non_nullable
                  as bool?,
        created_by: freezed == created_by
            ? _value._created_by
            : created_by // ignore: cast_nullable_to_non_nullable
                  as List<CreatedBy>?,
        episode_run_time: freezed == episode_run_time
            ? _value._episode_run_time
            : episode_run_time // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        genres: freezed == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<Genre>?,
        first_air_date: freezed == first_air_date
            ? _value.first_air_date
            : first_air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        homepage: freezed == homepage
            ? _value.homepage
            : homepage // ignore: cast_nullable_to_non_nullable
                  as String?,
        languages: freezed == languages
            ? _value._languages
            : languages // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        last_air_date: freezed == last_air_date
            ? _value.last_air_date
            : last_air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        networks: freezed == networks
            ? _value._networks
            : networks // ignore: cast_nullable_to_non_nullable
                  as List<Network>?,
        number_of_episodes: freezed == number_of_episodes
            ? _value.number_of_episodes
            : number_of_episodes // ignore: cast_nullable_to_non_nullable
                  as int?,
        number_of_seasons: freezed == number_of_seasons
            ? _value.number_of_seasons
            : number_of_seasons // ignore: cast_nullable_to_non_nullable
                  as int?,
        origin_country: freezed == origin_country
            ? _value._origin_country
            : origin_country // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        production_companies: freezed == production_companies
            ? _value._production_companies
            : production_companies // ignore: cast_nullable_to_non_nullable
                  as List<ProductionCompany>?,
        production_countries: freezed == production_countries
            ? _value._production_countries
            : production_countries // ignore: cast_nullable_to_non_nullable
                  as List<ProductionCountry>?,
        spoken_languages: freezed == spoken_languages
            ? _value._spoken_languages
            : spoken_languages // ignore: cast_nullable_to_non_nullable
                  as List<SpokenLanguage>?,
        release_dates: freezed == release_dates
            ? _value._release_dates
            : release_dates // ignore: cast_nullable_to_non_nullable
                  as List<ReleaseDate>?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        tagline: freezed == tagline
            ? _value.tagline
            : tagline // ignore: cast_nullable_to_non_nullable
                  as String?,
        genre_ids: freezed == genre_ids
            ? _value._genre_ids
            : genre_ids // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        vote_count: freezed == vote_count
            ? _value.vote_count
            : vote_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double?,
        runtime: freezed == runtime
            ? _value.runtime
            : runtime // ignore: cast_nullable_to_non_nullable
                  as int?,
        next_episode_to_air: freezed == next_episode_to_air
            ? _value.next_episode_to_air
            : next_episode_to_air // ignore: cast_nullable_to_non_nullable
                  as NextEpisodeToAir?,
        episode_groups: freezed == episode_groups
            ? _value._episode_groups
            : episode_groups // ignore: cast_nullable_to_non_nullable
                  as List<EpisodeGroup>?,
        episode_group: freezed == episode_group
            ? _value.episode_group
            : episode_group // ignore: cast_nullable_to_non_nullable
                  as EpisodeGroup?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaDetailImpl implements _MediaDetail {
  const _$MediaDetailImpl({
    this.source,
    this.media_source,
    this.type,
    this.title,
    this.en_title,
    this.hk_title,
    this.tw_title,
    this.sg_title,
    this.year,
    this.title_year,
    @JsonKey(fromJson: _intFromJson) this.season,
    @JsonKey(fromJson: _intFromJson) this.tmdb_id,
    this.imdb_id,
    @JsonKey(fromJson: _intFromJson) this.tvdb_id,
    @JsonKey(fromJson: _intFromJson) this.douban_id,
    @JsonKey(fromJson: _intFromJson) this.bangumi_id,
    @JsonKey(fromJson: _intFromJson) this.anilist_id,
    @JsonKey(fromJson: _intFromJson) this.anidb_id,
    @JsonKey(fromJson: _intFromJson) this.collection_id,
    this.mediaid_prefix,
    this.media_id,
    this.scrape_source,
    this.original_language,
    this.original_title,
    this.release_date,
    this.backdrop_path,
    this.poster_path,
    this.logo_path,
    @JsonKey(fromJson: _doubleFromJson) this.vote_average,
    this.overview,
    this.category,
    this.library_category,
    this.metadata_category,
    this.content_rating,
    this.tvdb_slug,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    final List<SeasonEpisodes>? seasons,
    final List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? names,
    final List<Actor>? actors,
    final List<Director>? directors,
    this.detail_link,
    this.adult,
    final List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? episode_run_time,
    final List<Genre>? genres,
    this.first_air_date,
    this.homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? languages,
    this.last_air_date,
    final List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) this.number_of_episodes,
    @JsonKey(fromJson: _intFromJson) this.number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? origin_country,
    this.original_name,
    final List<ProductionCompany>? production_companies,
    final List<ProductionCountry>? production_countries,
    final List<SpokenLanguage>? spoken_languages,
    final List<ReleaseDate>? release_dates,
    this.status,
    this.tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) this.vote_count,
    @JsonKey(fromJson: _doubleFromJson) this.popularity,
    @JsonKey(fromJson: _intFromJson) this.runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    this.next_episode_to_air,
    final List<EpisodeGroup>? episode_groups,
    this.episode_group,
  }) : _seasons = seasons,
       _season_info = season_info,
       _names = names,
       _actors = actors,
       _directors = directors,
       _created_by = created_by,
       _episode_run_time = episode_run_time,
       _genres = genres,
       _languages = languages,
       _networks = networks,
       _origin_country = origin_country,
       _production_companies = production_companies,
       _production_countries = production_countries,
       _spoken_languages = spoken_languages,
       _release_dates = release_dates,
       _genre_ids = genre_ids,
       _episode_groups = episode_groups;

  factory _$MediaDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaDetailImplFromJson(json);

  @override
  final String? source;
  @override
  final String? media_source;
  @override
  final String? type;
  @override
  final String? title;
  @override
  final String? en_title;
  @override
  final String? hk_title;
  @override
  final String? tw_title;
  @override
  final String? sg_title;
  @override
  final String? year;
  @override
  final String? title_year;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? season;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? tmdb_id;
  @override
  final String? imdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? tvdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? douban_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? bangumi_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? anilist_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? anidb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? collection_id;
  @override
  final String? mediaid_prefix;
  @override
  final String? media_id;
  @override
  final String? scrape_source;
  @override
  final String? original_language;
  @override
  final String? original_title;
  @override
  final String? release_date;
  @override
  final String? backdrop_path;
  @override
  final String? poster_path;
  @override
  final String? logo_path;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? vote_average;
  @override
  final String? overview;
  @override
  final String? category;
  @override
  final String? library_category;
  @override
  final String? metadata_category;
  @override
  final String? content_rating;
  @override
  final String? tvdb_slug;
  final List<SeasonEpisodes>? _seasons;
  @override
  @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
  List<SeasonEpisodes>? get seasons {
    final value = _seasons;
    if (value == null) return null;
    if (_seasons is EqualUnmodifiableListView) return _seasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<SeasonInfo>? _season_info;
  @override
  List<SeasonInfo>? get season_info {
    final value = _season_info;
    if (value == null) return null;
    if (_season_info is EqualUnmodifiableListView) return _season_info;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _names;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get names {
    final value = _names;
    if (value == null) return null;
    if (_names is EqualUnmodifiableListView) return _names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Actor>? _actors;
  @override
  List<Actor>? get actors {
    final value = _actors;
    if (value == null) return null;
    if (_actors is EqualUnmodifiableListView) return _actors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Director>? _directors;
  @override
  List<Director>? get directors {
    final value = _directors;
    if (value == null) return null;
    if (_directors is EqualUnmodifiableListView) return _directors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? detail_link;
  @override
  final bool? adult;
  final List<CreatedBy>? _created_by;
  @override
  List<CreatedBy>? get created_by {
    final value = _created_by;
    if (value == null) return null;
    if (_created_by is EqualUnmodifiableListView) return _created_by;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<int>? _episode_run_time;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_run_time {
    final value = _episode_run_time;
    if (value == null) return null;
    if (_episode_run_time is EqualUnmodifiableListView)
      return _episode_run_time;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Genre>? _genres;
  @override
  List<Genre>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? first_air_date;
  @override
  final String? homepage;
  final List<String>? _languages;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get languages {
    final value = _languages;
    if (value == null) return null;
    if (_languages is EqualUnmodifiableListView) return _languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? last_air_date;
  final List<Network>? _networks;
  @override
  List<Network>? get networks {
    final value = _networks;
    if (value == null) return null;
    if (_networks is EqualUnmodifiableListView) return _networks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? number_of_episodes;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? number_of_seasons;
  final List<String>? _origin_country;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get origin_country {
    final value = _origin_country;
    if (value == null) return null;
    if (_origin_country is EqualUnmodifiableListView) return _origin_country;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? original_name;
  final List<ProductionCompany>? _production_companies;
  @override
  List<ProductionCompany>? get production_companies {
    final value = _production_companies;
    if (value == null) return null;
    if (_production_companies is EqualUnmodifiableListView)
      return _production_companies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ProductionCountry>? _production_countries;
  @override
  List<ProductionCountry>? get production_countries {
    final value = _production_countries;
    if (value == null) return null;
    if (_production_countries is EqualUnmodifiableListView)
      return _production_countries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<SpokenLanguage>? _spoken_languages;
  @override
  List<SpokenLanguage>? get spoken_languages {
    final value = _spoken_languages;
    if (value == null) return null;
    if (_spoken_languages is EqualUnmodifiableListView)
      return _spoken_languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ReleaseDate>? _release_dates;
  @override
  List<ReleaseDate>? get release_dates {
    final value = _release_dates;
    if (value == null) return null;
    if (_release_dates is EqualUnmodifiableListView) return _release_dates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? status;
  @override
  final String? tagline;
  final List<int>? _genre_ids;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get genre_ids {
    final value = _genre_ids;
    if (value == null) return null;
    if (_genre_ids is EqualUnmodifiableListView) return _genre_ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? vote_count;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? popularity;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? runtime;
  @override
  @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
  final NextEpisodeToAir? next_episode_to_air;
  final List<EpisodeGroup>? _episode_groups;
  @override
  List<EpisodeGroup>? get episode_groups {
    final value = _episode_groups;
    if (value == null) return null;
    if (_episode_groups is EqualUnmodifiableListView) return _episode_groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final EpisodeGroup? episode_group;

  @override
  String toString() {
    return 'MediaDetail(source: $source, media_source: $media_source, type: $type, title: $title, en_title: $en_title, hk_title: $hk_title, tw_title: $tw_title, sg_title: $sg_title, year: $year, title_year: $title_year, season: $season, tmdb_id: $tmdb_id, imdb_id: $imdb_id, tvdb_id: $tvdb_id, douban_id: $douban_id, bangumi_id: $bangumi_id, anilist_id: $anilist_id, anidb_id: $anidb_id, collection_id: $collection_id, mediaid_prefix: $mediaid_prefix, media_id: $media_id, scrape_source: $scrape_source, original_language: $original_language, original_title: $original_title, release_date: $release_date, backdrop_path: $backdrop_path, poster_path: $poster_path, logo_path: $logo_path, vote_average: $vote_average, overview: $overview, category: $category, library_category: $library_category, metadata_category: $metadata_category, content_rating: $content_rating, tvdb_slug: $tvdb_slug, seasons: $seasons, season_info: $season_info, names: $names, actors: $actors, directors: $directors, detail_link: $detail_link, adult: $adult, created_by: $created_by, episode_run_time: $episode_run_time, genres: $genres, first_air_date: $first_air_date, homepage: $homepage, languages: $languages, last_air_date: $last_air_date, networks: $networks, number_of_episodes: $number_of_episodes, number_of_seasons: $number_of_seasons, origin_country: $origin_country, original_name: $original_name, production_companies: $production_companies, production_countries: $production_countries, spoken_languages: $spoken_languages, release_dates: $release_dates, status: $status, tagline: $tagline, genre_ids: $genre_ids, vote_count: $vote_count, popularity: $popularity, runtime: $runtime, next_episode_to_air: $next_episode_to_air, episode_groups: $episode_groups, episode_group: $episode_group)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaDetailImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.media_source, media_source) ||
                other.media_source == media_source) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.en_title, en_title) ||
                other.en_title == en_title) &&
            (identical(other.hk_title, hk_title) ||
                other.hk_title == hk_title) &&
            (identical(other.tw_title, tw_title) ||
                other.tw_title == tw_title) &&
            (identical(other.sg_title, sg_title) ||
                other.sg_title == sg_title) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.title_year, title_year) ||
                other.title_year == title_year) &&
            (identical(other.season, season) || other.season == season) &&
            (identical(other.tmdb_id, tmdb_id) || other.tmdb_id == tmdb_id) &&
            (identical(other.imdb_id, imdb_id) || other.imdb_id == imdb_id) &&
            (identical(other.tvdb_id, tvdb_id) || other.tvdb_id == tvdb_id) &&
            (identical(other.douban_id, douban_id) ||
                other.douban_id == douban_id) &&
            (identical(other.bangumi_id, bangumi_id) ||
                other.bangumi_id == bangumi_id) &&
            (identical(other.anilist_id, anilist_id) ||
                other.anilist_id == anilist_id) &&
            (identical(other.anidb_id, anidb_id) ||
                other.anidb_id == anidb_id) &&
            (identical(other.collection_id, collection_id) ||
                other.collection_id == collection_id) &&
            (identical(other.mediaid_prefix, mediaid_prefix) ||
                other.mediaid_prefix == mediaid_prefix) &&
            (identical(other.media_id, media_id) ||
                other.media_id == media_id) &&
            (identical(other.scrape_source, scrape_source) ||
                other.scrape_source == scrape_source) &&
            (identical(other.original_language, original_language) ||
                other.original_language == original_language) &&
            (identical(other.original_title, original_title) ||
                other.original_title == original_title) &&
            (identical(other.release_date, release_date) ||
                other.release_date == release_date) &&
            (identical(other.backdrop_path, backdrop_path) ||
                other.backdrop_path == backdrop_path) &&
            (identical(other.poster_path, poster_path) ||
                other.poster_path == poster_path) &&
            (identical(other.logo_path, logo_path) ||
                other.logo_path == logo_path) &&
            (identical(other.vote_average, vote_average) ||
                other.vote_average == vote_average) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.library_category, library_category) ||
                other.library_category == library_category) &&
            (identical(other.metadata_category, metadata_category) ||
                other.metadata_category == metadata_category) &&
            (identical(other.content_rating, content_rating) ||
                other.content_rating == content_rating) &&
            (identical(other.tvdb_slug, tvdb_slug) ||
                other.tvdb_slug == tvdb_slug) &&
            const DeepCollectionEquality().equals(other._seasons, _seasons) &&
            const DeepCollectionEquality().equals(
              other._season_info,
              _season_info,
            ) &&
            const DeepCollectionEquality().equals(other._names, _names) &&
            const DeepCollectionEquality().equals(other._actors, _actors) &&
            const DeepCollectionEquality().equals(
              other._directors,
              _directors,
            ) &&
            (identical(other.detail_link, detail_link) ||
                other.detail_link == detail_link) &&
            (identical(other.adult, adult) || other.adult == adult) &&
            const DeepCollectionEquality().equals(
              other._created_by,
              _created_by,
            ) &&
            const DeepCollectionEquality().equals(
              other._episode_run_time,
              _episode_run_time,
            ) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.first_air_date, first_air_date) ||
                other.first_air_date == first_air_date) &&
            (identical(other.homepage, homepage) ||
                other.homepage == homepage) &&
            const DeepCollectionEquality().equals(
              other._languages,
              _languages,
            ) &&
            (identical(other.last_air_date, last_air_date) ||
                other.last_air_date == last_air_date) &&
            const DeepCollectionEquality().equals(other._networks, _networks) &&
            (identical(other.number_of_episodes, number_of_episodes) ||
                other.number_of_episodes == number_of_episodes) &&
            (identical(other.number_of_seasons, number_of_seasons) ||
                other.number_of_seasons == number_of_seasons) &&
            const DeepCollectionEquality().equals(
              other._origin_country,
              _origin_country,
            ) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            const DeepCollectionEquality().equals(
              other._production_companies,
              _production_companies,
            ) &&
            const DeepCollectionEquality().equals(
              other._production_countries,
              _production_countries,
            ) &&
            const DeepCollectionEquality().equals(
              other._spoken_languages,
              _spoken_languages,
            ) &&
            const DeepCollectionEquality().equals(
              other._release_dates,
              _release_dates,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            const DeepCollectionEquality().equals(
              other._genre_ids,
              _genre_ids,
            ) &&
            (identical(other.vote_count, vote_count) ||
                other.vote_count == vote_count) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.runtime, runtime) || other.runtime == runtime) &&
            (identical(other.next_episode_to_air, next_episode_to_air) ||
                other.next_episode_to_air == next_episode_to_air) &&
            const DeepCollectionEquality().equals(
              other._episode_groups,
              _episode_groups,
            ) &&
            (identical(other.episode_group, episode_group) ||
                other.episode_group == episode_group));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    source,
    media_source,
    type,
    title,
    en_title,
    hk_title,
    tw_title,
    sg_title,
    year,
    title_year,
    season,
    tmdb_id,
    imdb_id,
    tvdb_id,
    douban_id,
    bangumi_id,
    anilist_id,
    anidb_id,
    collection_id,
    mediaid_prefix,
    media_id,
    scrape_source,
    original_language,
    original_title,
    release_date,
    backdrop_path,
    poster_path,
    logo_path,
    vote_average,
    overview,
    category,
    library_category,
    metadata_category,
    content_rating,
    tvdb_slug,
    const DeepCollectionEquality().hash(_seasons),
    const DeepCollectionEquality().hash(_season_info),
    const DeepCollectionEquality().hash(_names),
    const DeepCollectionEquality().hash(_actors),
    const DeepCollectionEquality().hash(_directors),
    detail_link,
    adult,
    const DeepCollectionEquality().hash(_created_by),
    const DeepCollectionEquality().hash(_episode_run_time),
    const DeepCollectionEquality().hash(_genres),
    first_air_date,
    homepage,
    const DeepCollectionEquality().hash(_languages),
    last_air_date,
    const DeepCollectionEquality().hash(_networks),
    number_of_episodes,
    number_of_seasons,
    const DeepCollectionEquality().hash(_origin_country),
    original_name,
    const DeepCollectionEquality().hash(_production_companies),
    const DeepCollectionEquality().hash(_production_countries),
    const DeepCollectionEquality().hash(_spoken_languages),
    const DeepCollectionEquality().hash(_release_dates),
    status,
    tagline,
    const DeepCollectionEquality().hash(_genre_ids),
    vote_count,
    popularity,
    runtime,
    next_episode_to_air,
    const DeepCollectionEquality().hash(_episode_groups),
    episode_group,
  ]);

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaDetailImplCopyWith<_$MediaDetailImpl> get copyWith =>
      __$$MediaDetailImplCopyWithImpl<_$MediaDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaDetailImplToJson(this);
  }
}

abstract class _MediaDetail implements MediaDetail {
  const factory _MediaDetail({
    final String? source,
    final String? media_source,
    final String? type,
    final String? title,
    final String? en_title,
    final String? hk_title,
    final String? tw_title,
    final String? sg_title,
    final String? year,
    final String? title_year,
    @JsonKey(fromJson: _intFromJson) final int? season,
    @JsonKey(fromJson: _intFromJson) final int? tmdb_id,
    final String? imdb_id,
    @JsonKey(fromJson: _intFromJson) final int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) final int? douban_id,
    @JsonKey(fromJson: _intFromJson) final int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) final int? anilist_id,
    @JsonKey(fromJson: _intFromJson) final int? anidb_id,
    @JsonKey(fromJson: _intFromJson) final int? collection_id,
    final String? mediaid_prefix,
    final String? media_id,
    final String? scrape_source,
    final String? original_language,
    final String? original_title,
    final String? release_date,
    final String? backdrop_path,
    final String? poster_path,
    final String? logo_path,
    @JsonKey(fromJson: _doubleFromJson) final double? vote_average,
    final String? overview,
    final String? category,
    final String? library_category,
    final String? metadata_category,
    final String? content_rating,
    final String? tvdb_slug,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    final List<SeasonEpisodes>? seasons,
    final List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? names,
    final List<Actor>? actors,
    final List<Director>? directors,
    final String? detail_link,
    final bool? adult,
    final List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? episode_run_time,
    final List<Genre>? genres,
    final String? first_air_date,
    final String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? languages,
    final String? last_air_date,
    final List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) final int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) final int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    final List<String>? origin_country,
    final String? original_name,
    final List<ProductionCompany>? production_companies,
    final List<ProductionCountry>? production_countries,
    final List<SpokenLanguage>? spoken_languages,
    final List<ReleaseDate>? release_dates,
    final String? status,
    final String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    final List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) final int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) final double? popularity,
    @JsonKey(fromJson: _intFromJson) final int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    final NextEpisodeToAir? next_episode_to_air,
    final List<EpisodeGroup>? episode_groups,
    final EpisodeGroup? episode_group,
  }) = _$MediaDetailImpl;

  factory _MediaDetail.fromJson(Map<String, dynamic> json) =
      _$MediaDetailImpl.fromJson;

  @override
  String? get source;
  @override
  String? get media_source;
  @override
  String? get type;
  @override
  String? get title;
  @override
  String? get en_title;
  @override
  String? get hk_title;
  @override
  String? get tw_title;
  @override
  String? get sg_title;
  @override
  String? get year;
  @override
  String? get title_year;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get season;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get tmdb_id;
  @override
  String? get imdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get tvdb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get douban_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get bangumi_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get anilist_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get anidb_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get collection_id;
  @override
  String? get mediaid_prefix;
  @override
  String? get media_id;
  @override
  String? get scrape_source;
  @override
  String? get original_language;
  @override
  String? get original_title;
  @override
  String? get release_date;
  @override
  String? get backdrop_path;
  @override
  String? get poster_path;
  @override
  String? get logo_path;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average;
  @override
  String? get overview;
  @override
  String? get category;
  @override
  String? get library_category;
  @override
  String? get metadata_category;
  @override
  String? get content_rating;
  @override
  String? get tvdb_slug;
  @override
  @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
  List<SeasonEpisodes>? get seasons;
  @override
  List<SeasonInfo>? get season_info;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get names;
  @override
  List<Actor>? get actors;
  @override
  List<Director>? get directors;
  @override
  String? get detail_link;
  @override
  bool? get adult;
  @override
  List<CreatedBy>? get created_by;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get episode_run_time;
  @override
  List<Genre>? get genres;
  @override
  String? get first_air_date;
  @override
  String? get homepage;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get languages;
  @override
  String? get last_air_date;
  @override
  List<Network>? get networks;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_episodes;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get number_of_seasons;
  @override
  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  List<String>? get origin_country;
  @override
  String? get original_name;
  @override
  List<ProductionCompany>? get production_companies;
  @override
  List<ProductionCountry>? get production_countries;
  @override
  List<SpokenLanguage>? get spoken_languages;
  @override
  List<ReleaseDate>? get release_dates;
  @override
  String? get status;
  @override
  String? get tagline;
  @override
  @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
  List<int>? get genre_ids;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get runtime;
  @override
  @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
  NextEpisodeToAir? get next_episode_to_air;
  @override
  List<EpisodeGroup>? get episode_groups;
  @override
  EpisodeGroup? get episode_group;

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaDetailImplCopyWith<_$MediaDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeasonEpisodes _$SeasonEpisodesFromJson(Map<String, dynamic> json) {
  return _SeasonEpisodes.fromJson(json);
}

/// @nodoc
mixin _$SeasonEpisodes {
  int get season => throw _privateConstructorUsedError;
  List<int> get episodes => throw _privateConstructorUsedError;

  /// Serializes this SeasonEpisodes to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonEpisodesCopyWith<SeasonEpisodes> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonEpisodesCopyWith<$Res> {
  factory $SeasonEpisodesCopyWith(
    SeasonEpisodes value,
    $Res Function(SeasonEpisodes) then,
  ) = _$SeasonEpisodesCopyWithImpl<$Res, SeasonEpisodes>;
  @useResult
  $Res call({int season, List<int> episodes});
}

/// @nodoc
class _$SeasonEpisodesCopyWithImpl<$Res, $Val extends SeasonEpisodes>
    implements $SeasonEpisodesCopyWith<$Res> {
  _$SeasonEpisodesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? season = null, Object? episodes = null}) {
    return _then(
      _value.copyWith(
            season: null == season
                ? _value.season
                : season // ignore: cast_nullable_to_non_nullable
                      as int,
            episodes: null == episodes
                ? _value.episodes
                : episodes // ignore: cast_nullable_to_non_nullable
                      as List<int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonEpisodesImplCopyWith<$Res>
    implements $SeasonEpisodesCopyWith<$Res> {
  factory _$$SeasonEpisodesImplCopyWith(
    _$SeasonEpisodesImpl value,
    $Res Function(_$SeasonEpisodesImpl) then,
  ) = __$$SeasonEpisodesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int season, List<int> episodes});
}

/// @nodoc
class __$$SeasonEpisodesImplCopyWithImpl<$Res>
    extends _$SeasonEpisodesCopyWithImpl<$Res, _$SeasonEpisodesImpl>
    implements _$$SeasonEpisodesImplCopyWith<$Res> {
  __$$SeasonEpisodesImplCopyWithImpl(
    _$SeasonEpisodesImpl _value,
    $Res Function(_$SeasonEpisodesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? season = null, Object? episodes = null}) {
    return _then(
      _$SeasonEpisodesImpl(
        season: null == season
            ? _value.season
            : season // ignore: cast_nullable_to_non_nullable
                  as int,
        episodes: null == episodes
            ? _value._episodes
            : episodes // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonEpisodesImpl implements _SeasonEpisodes {
  const _$SeasonEpisodesImpl({
    required this.season,
    required final List<int> episodes,
  }) : _episodes = episodes;

  factory _$SeasonEpisodesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonEpisodesImplFromJson(json);

  @override
  final int season;
  final List<int> _episodes;
  @override
  List<int> get episodes {
    if (_episodes is EqualUnmodifiableListView) return _episodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_episodes);
  }

  @override
  String toString() {
    return 'SeasonEpisodes(season: $season, episodes: $episodes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonEpisodesImpl &&
            (identical(other.season, season) || other.season == season) &&
            const DeepCollectionEquality().equals(other._episodes, _episodes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    season,
    const DeepCollectionEquality().hash(_episodes),
  );

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonEpisodesImplCopyWith<_$SeasonEpisodesImpl> get copyWith =>
      __$$SeasonEpisodesImplCopyWithImpl<_$SeasonEpisodesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonEpisodesImplToJson(this);
  }
}

abstract class _SeasonEpisodes implements SeasonEpisodes {
  const factory _SeasonEpisodes({
    required final int season,
    required final List<int> episodes,
  }) = _$SeasonEpisodesImpl;

  factory _SeasonEpisodes.fromJson(Map<String, dynamic> json) =
      _$SeasonEpisodesImpl.fromJson;

  @override
  int get season;
  @override
  List<int> get episodes;

  /// Create a copy of SeasonEpisodes
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonEpisodesImplCopyWith<_$SeasonEpisodesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeasonInfo _$SeasonInfoFromJson(Map<String, dynamic> json) {
  return _SeasonInfo.fromJson(json);
}

/// @nodoc
mixin _$SeasonInfo {
  String? get air_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get overview => throw _privateConstructorUsedError;
  String? get poster_path => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get season_number => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average => throw _privateConstructorUsedError;

  /// Serializes this SeasonInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonInfoCopyWith<SeasonInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonInfoCopyWith<$Res> {
  factory $SeasonInfoCopyWith(
    SeasonInfo value,
    $Res Function(SeasonInfo) then,
  ) = _$SeasonInfoCopyWithImpl<$Res, SeasonInfo>;
  @useResult
  $Res call({
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    String? poster_path,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
  });
}

/// @nodoc
class _$SeasonInfoCopyWithImpl<$Res, $Val extends SeasonInfo>
    implements $SeasonInfoCopyWith<$Res> {
  _$SeasonInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? air_date = freezed,
    Object? episode_count = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? poster_path = freezed,
    Object? season_number = freezed,
    Object? vote_average = freezed,
  }) {
    return _then(
      _value.copyWith(
            air_date: freezed == air_date
                ? _value.air_date
                : air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_count: freezed == episode_count
                ? _value.episode_count
                : episode_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            poster_path: freezed == poster_path
                ? _value.poster_path
                : poster_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            season_number: freezed == season_number
                ? _value.season_number
                : season_number // ignore: cast_nullable_to_non_nullable
                      as int?,
            vote_average: freezed == vote_average
                ? _value.vote_average
                : vote_average // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonInfoImplCopyWith<$Res>
    implements $SeasonInfoCopyWith<$Res> {
  factory _$$SeasonInfoImplCopyWith(
    _$SeasonInfoImpl value,
    $Res Function(_$SeasonInfoImpl) then,
  ) = __$$SeasonInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    String? poster_path,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
  });
}

/// @nodoc
class __$$SeasonInfoImplCopyWithImpl<$Res>
    extends _$SeasonInfoCopyWithImpl<$Res, _$SeasonInfoImpl>
    implements _$$SeasonInfoImplCopyWith<$Res> {
  __$$SeasonInfoImplCopyWithImpl(
    _$SeasonInfoImpl _value,
    $Res Function(_$SeasonInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? air_date = freezed,
    Object? episode_count = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? poster_path = freezed,
    Object? season_number = freezed,
    Object? vote_average = freezed,
  }) {
    return _then(
      _$SeasonInfoImpl(
        air_date: freezed == air_date
            ? _value.air_date
            : air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_count: freezed == episode_count
            ? _value.episode_count
            : episode_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        poster_path: freezed == poster_path
            ? _value.poster_path
            : poster_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        season_number: freezed == season_number
            ? _value.season_number
            : season_number // ignore: cast_nullable_to_non_nullable
                  as int?,
        vote_average: freezed == vote_average
            ? _value.vote_average
            : vote_average // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonInfoImpl implements _SeasonInfo {
  const _$SeasonInfoImpl({
    this.air_date,
    @JsonKey(fromJson: _intFromJson) this.episode_count,
    @JsonKey(fromJson: _intFromJson) this.id,
    this.name,
    this.overview,
    this.poster_path,
    @JsonKey(fromJson: _intFromJson) this.season_number,
    @JsonKey(fromJson: _doubleFromJson) this.vote_average,
  });

  factory _$SeasonInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonInfoImplFromJson(json);

  @override
  final String? air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? name;
  @override
  final String? overview;
  @override
  final String? poster_path;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? season_number;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? vote_average;

  @override
  String toString() {
    return 'SeasonInfo(air_date: $air_date, episode_count: $episode_count, id: $id, name: $name, overview: $overview, poster_path: $poster_path, season_number: $season_number, vote_average: $vote_average)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonInfoImpl &&
            (identical(other.air_date, air_date) ||
                other.air_date == air_date) &&
            (identical(other.episode_count, episode_count) ||
                other.episode_count == episode_count) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.poster_path, poster_path) ||
                other.poster_path == poster_path) &&
            (identical(other.season_number, season_number) ||
                other.season_number == season_number) &&
            (identical(other.vote_average, vote_average) ||
                other.vote_average == vote_average));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    air_date,
    episode_count,
    id,
    name,
    overview,
    poster_path,
    season_number,
    vote_average,
  );

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonInfoImplCopyWith<_$SeasonInfoImpl> get copyWith =>
      __$$SeasonInfoImplCopyWithImpl<_$SeasonInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonInfoImplToJson(this);
  }
}

abstract class _SeasonInfo implements SeasonInfo {
  const factory _SeasonInfo({
    final String? air_date,
    @JsonKey(fromJson: _intFromJson) final int? episode_count,
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? name,
    final String? overview,
    final String? poster_path,
    @JsonKey(fromJson: _intFromJson) final int? season_number,
    @JsonKey(fromJson: _doubleFromJson) final double? vote_average,
  }) = _$SeasonInfoImpl;

  factory _SeasonInfo.fromJson(Map<String, dynamic> json) =
      _$SeasonInfoImpl.fromJson;

  @override
  String? get air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get name;
  @override
  String? get overview;
  @override
  String? get poster_path;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get season_number;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average;

  /// Create a copy of SeasonInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonInfoImplCopyWith<_$SeasonInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Actor _$ActorFromJson(Map<String, dynamic> json) {
  return _Actor.fromJson(json);
}

/// @nodoc
mixin _$Actor {
  bool? get adult => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get gender => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get known_for_department => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get original_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity => throw _privateConstructorUsedError;
  String? get profile_path => throw _privateConstructorUsedError;
  String? get character => throw _privateConstructorUsedError;
  String? get credit_id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get order => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
  ActorAvatar? get avatar => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
  ActorImages? get images => throw _privateConstructorUsedError;
  String? get sharing_url => throw _privateConstructorUsedError;

  /// Serializes this Actor to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActorCopyWith<Actor> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActorCopyWith<$Res> {
  factory $ActorCopyWith(Actor value, $Res Function(Actor) then) =
      _$ActorCopyWithImpl<$Res, Actor>;
  @useResult
  $Res call({
    bool? adult,
    String? source,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? known_for_department,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    String? profile_path,
    String? character,
    String? credit_id,
    @JsonKey(fromJson: _intFromJson) int? order,
    @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
    ActorAvatar? avatar,
    @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
    ActorImages? images,
    String? sharing_url,
  });

  $ActorAvatarCopyWith<$Res>? get avatar;
  $ActorImagesCopyWith<$Res>? get images;
}

/// @nodoc
class _$ActorCopyWithImpl<$Res, $Val extends Actor>
    implements $ActorCopyWith<$Res> {
  _$ActorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adult = freezed,
    Object? source = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? known_for_department = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
    Object? character = freezed,
    Object? credit_id = freezed,
    Object? order = freezed,
    Object? avatar = freezed,
    Object? images = freezed,
    Object? sharing_url = freezed,
  }) {
    return _then(
      _value.copyWith(
            adult: freezed == adult
                ? _value.adult
                : adult // ignore: cast_nullable_to_non_nullable
                      as bool?,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            known_for_department: freezed == known_for_department
                ? _value.known_for_department
                : known_for_department // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double?,
            profile_path: freezed == profile_path
                ? _value.profile_path
                : profile_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            character: freezed == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                      as String?,
            credit_id: freezed == credit_id
                ? _value.credit_id
                : credit_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            order: freezed == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as ActorAvatar?,
            images: freezed == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as ActorImages?,
            sharing_url: freezed == sharing_url
                ? _value.sharing_url
                : sharing_url // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActorAvatarCopyWith<$Res>? get avatar {
    if (_value.avatar == null) {
      return null;
    }

    return $ActorAvatarCopyWith<$Res>(_value.avatar!, (value) {
      return _then(_value.copyWith(avatar: value) as $Val);
    });
  }

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActorImagesCopyWith<$Res>? get images {
    if (_value.images == null) {
      return null;
    }

    return $ActorImagesCopyWith<$Res>(_value.images!, (value) {
      return _then(_value.copyWith(images: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ActorImplCopyWith<$Res> implements $ActorCopyWith<$Res> {
  factory _$$ActorImplCopyWith(
    _$ActorImpl value,
    $Res Function(_$ActorImpl) then,
  ) = __$$ActorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool? adult,
    String? source,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? known_for_department,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    String? profile_path,
    String? character,
    String? credit_id,
    @JsonKey(fromJson: _intFromJson) int? order,
    @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
    ActorAvatar? avatar,
    @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
    ActorImages? images,
    String? sharing_url,
  });

  @override
  $ActorAvatarCopyWith<$Res>? get avatar;
  @override
  $ActorImagesCopyWith<$Res>? get images;
}

/// @nodoc
class __$$ActorImplCopyWithImpl<$Res>
    extends _$ActorCopyWithImpl<$Res, _$ActorImpl>
    implements _$$ActorImplCopyWith<$Res> {
  __$$ActorImplCopyWithImpl(
    _$ActorImpl _value,
    $Res Function(_$ActorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adult = freezed,
    Object? source = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? known_for_department = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
    Object? character = freezed,
    Object? credit_id = freezed,
    Object? order = freezed,
    Object? avatar = freezed,
    Object? images = freezed,
    Object? sharing_url = freezed,
  }) {
    return _then(
      _$ActorImpl(
        adult: freezed == adult
            ? _value.adult
            : adult // ignore: cast_nullable_to_non_nullable
                  as bool?,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        known_for_department: freezed == known_for_department
            ? _value.known_for_department
            : known_for_department // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double?,
        profile_path: freezed == profile_path
            ? _value.profile_path
            : profile_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        character: freezed == character
            ? _value.character
            : character // ignore: cast_nullable_to_non_nullable
                  as String?,
        credit_id: freezed == credit_id
            ? _value.credit_id
            : credit_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        order: freezed == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as ActorAvatar?,
        images: freezed == images
            ? _value.images
            : images // ignore: cast_nullable_to_non_nullable
                  as ActorImages?,
        sharing_url: freezed == sharing_url
            ? _value.sharing_url
            : sharing_url // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActorImpl implements _Actor {
  const _$ActorImpl({
    this.adult,
    this.source,
    @JsonKey(fromJson: _intFromJson) this.gender,
    @JsonKey(fromJson: _intFromJson) this.id,
    this.known_for_department,
    this.name,
    this.original_name,
    @JsonKey(fromJson: _doubleFromJson) this.popularity,
    this.profile_path,
    this.character,
    this.credit_id,
    @JsonKey(fromJson: _intFromJson) this.order,
    @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
    this.avatar,
    @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
    this.images,
    this.sharing_url,
  });

  factory _$ActorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActorImplFromJson(json);

  @override
  final bool? adult;
  @override
  final String? source;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? known_for_department;
  @override
  final String? name;
  @override
  final String? original_name;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? popularity;
  @override
  final String? profile_path;
  @override
  final String? character;
  @override
  final String? credit_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? order;
  @override
  @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
  final ActorAvatar? avatar;
  @override
  @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
  final ActorImages? images;
  @override
  final String? sharing_url;

  @override
  String toString() {
    return 'Actor(adult: $adult, source: $source, gender: $gender, id: $id, known_for_department: $known_for_department, name: $name, original_name: $original_name, popularity: $popularity, profile_path: $profile_path, character: $character, credit_id: $credit_id, order: $order, avatar: $avatar, images: $images, sharing_url: $sharing_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActorImpl &&
            (identical(other.adult, adult) || other.adult == adult) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.known_for_department, known_for_department) ||
                other.known_for_department == known_for_department) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.profile_path, profile_path) ||
                other.profile_path == profile_path) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.credit_id, credit_id) ||
                other.credit_id == credit_id) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.images, images) || other.images == images) &&
            (identical(other.sharing_url, sharing_url) ||
                other.sharing_url == sharing_url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    adult,
    source,
    gender,
    id,
    known_for_department,
    name,
    original_name,
    popularity,
    profile_path,
    character,
    credit_id,
    order,
    avatar,
    images,
    sharing_url,
  );

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActorImplCopyWith<_$ActorImpl> get copyWith =>
      __$$ActorImplCopyWithImpl<_$ActorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActorImplToJson(this);
  }
}

abstract class _Actor implements Actor {
  const factory _Actor({
    final bool? adult,
    final String? source,
    @JsonKey(fromJson: _intFromJson) final int? gender,
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? known_for_department,
    final String? name,
    final String? original_name,
    @JsonKey(fromJson: _doubleFromJson) final double? popularity,
    final String? profile_path,
    final String? character,
    final String? credit_id,
    @JsonKey(fromJson: _intFromJson) final int? order,
    @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
    final ActorAvatar? avatar,
    @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
    final ActorImages? images,
    final String? sharing_url,
  }) = _$ActorImpl;

  factory _Actor.fromJson(Map<String, dynamic> json) = _$ActorImpl.fromJson;

  @override
  bool? get adult;
  @override
  String? get source;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get known_for_department;
  @override
  String? get name;
  @override
  String? get original_name;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity;
  @override
  String? get profile_path;
  @override
  String? get character;
  @override
  String? get credit_id;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get order;
  @override
  @JsonKey(fromJson: _actorAvatarFromJson, toJson: _actorAvatarToJson)
  ActorAvatar? get avatar;
  @override
  @JsonKey(fromJson: _actorImagesFromJson, toJson: _actorImagesToJson)
  ActorImages? get images;
  @override
  String? get sharing_url;

  /// Create a copy of Actor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActorImplCopyWith<_$ActorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActorImages _$ActorImagesFromJson(Map<String, dynamic> json) {
  return _ActorImages.fromJson(json);
}

/// @nodoc
mixin _$ActorImages {
  ActorImage? get large => throw _privateConstructorUsedError;
  ActorImage? get normal => throw _privateConstructorUsedError;

  /// Serializes this ActorImages to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActorImagesCopyWith<ActorImages> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActorImagesCopyWith<$Res> {
  factory $ActorImagesCopyWith(
    ActorImages value,
    $Res Function(ActorImages) then,
  ) = _$ActorImagesCopyWithImpl<$Res, ActorImages>;
  @useResult
  $Res call({ActorImage? large, ActorImage? normal});

  $ActorImageCopyWith<$Res>? get large;
  $ActorImageCopyWith<$Res>? get normal;
}

/// @nodoc
class _$ActorImagesCopyWithImpl<$Res, $Val extends ActorImages>
    implements $ActorImagesCopyWith<$Res> {
  _$ActorImagesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? large = freezed, Object? normal = freezed}) {
    return _then(
      _value.copyWith(
            large: freezed == large
                ? _value.large
                : large // ignore: cast_nullable_to_non_nullable
                      as ActorImage?,
            normal: freezed == normal
                ? _value.normal
                : normal // ignore: cast_nullable_to_non_nullable
                      as ActorImage?,
          )
          as $Val,
    );
  }

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActorImageCopyWith<$Res>? get large {
    if (_value.large == null) {
      return null;
    }

    return $ActorImageCopyWith<$Res>(_value.large!, (value) {
      return _then(_value.copyWith(large: value) as $Val);
    });
  }

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActorImageCopyWith<$Res>? get normal {
    if (_value.normal == null) {
      return null;
    }

    return $ActorImageCopyWith<$Res>(_value.normal!, (value) {
      return _then(_value.copyWith(normal: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ActorImagesImplCopyWith<$Res>
    implements $ActorImagesCopyWith<$Res> {
  factory _$$ActorImagesImplCopyWith(
    _$ActorImagesImpl value,
    $Res Function(_$ActorImagesImpl) then,
  ) = __$$ActorImagesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ActorImage? large, ActorImage? normal});

  @override
  $ActorImageCopyWith<$Res>? get large;
  @override
  $ActorImageCopyWith<$Res>? get normal;
}

/// @nodoc
class __$$ActorImagesImplCopyWithImpl<$Res>
    extends _$ActorImagesCopyWithImpl<$Res, _$ActorImagesImpl>
    implements _$$ActorImagesImplCopyWith<$Res> {
  __$$ActorImagesImplCopyWithImpl(
    _$ActorImagesImpl _value,
    $Res Function(_$ActorImagesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? large = freezed, Object? normal = freezed}) {
    return _then(
      _$ActorImagesImpl(
        large: freezed == large
            ? _value.large
            : large // ignore: cast_nullable_to_non_nullable
                  as ActorImage?,
        normal: freezed == normal
            ? _value.normal
            : normal // ignore: cast_nullable_to_non_nullable
                  as ActorImage?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActorImagesImpl implements _ActorImages {
  const _$ActorImagesImpl({this.large, this.normal});

  factory _$ActorImagesImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActorImagesImplFromJson(json);

  @override
  final ActorImage? large;
  @override
  final ActorImage? normal;

  @override
  String toString() {
    return 'ActorImages(large: $large, normal: $normal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActorImagesImpl &&
            (identical(other.large, large) || other.large == large) &&
            (identical(other.normal, normal) || other.normal == normal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, large, normal);

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActorImagesImplCopyWith<_$ActorImagesImpl> get copyWith =>
      __$$ActorImagesImplCopyWithImpl<_$ActorImagesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActorImagesImplToJson(this);
  }
}

abstract class _ActorImages implements ActorImages {
  const factory _ActorImages({
    final ActorImage? large,
    final ActorImage? normal,
  }) = _$ActorImagesImpl;

  factory _ActorImages.fromJson(Map<String, dynamic> json) =
      _$ActorImagesImpl.fromJson;

  @override
  ActorImage? get large;
  @override
  ActorImage? get normal;

  /// Create a copy of ActorImages
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActorImagesImplCopyWith<_$ActorImagesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActorImage _$ActorImageFromJson(Map<String, dynamic> json) {
  return _ActorImage.fromJson(json);
}

/// @nodoc
mixin _$ActorImage {
  String? get url => throw _privateConstructorUsedError;

  /// Serializes this ActorImage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActorImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActorImageCopyWith<ActorImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActorImageCopyWith<$Res> {
  factory $ActorImageCopyWith(
    ActorImage value,
    $Res Function(ActorImage) then,
  ) = _$ActorImageCopyWithImpl<$Res, ActorImage>;
  @useResult
  $Res call({String? url});
}

/// @nodoc
class _$ActorImageCopyWithImpl<$Res, $Val extends ActorImage>
    implements $ActorImageCopyWith<$Res> {
  _$ActorImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActorImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? url = freezed}) {
    return _then(
      _value.copyWith(
            url: freezed == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActorImageImplCopyWith<$Res>
    implements $ActorImageCopyWith<$Res> {
  factory _$$ActorImageImplCopyWith(
    _$ActorImageImpl value,
    $Res Function(_$ActorImageImpl) then,
  ) = __$$ActorImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? url});
}

/// @nodoc
class __$$ActorImageImplCopyWithImpl<$Res>
    extends _$ActorImageCopyWithImpl<$Res, _$ActorImageImpl>
    implements _$$ActorImageImplCopyWith<$Res> {
  __$$ActorImageImplCopyWithImpl(
    _$ActorImageImpl _value,
    $Res Function(_$ActorImageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActorImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? url = freezed}) {
    return _then(
      _$ActorImageImpl(
        url: freezed == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActorImageImpl implements _ActorImage {
  const _$ActorImageImpl({this.url});

  factory _$ActorImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActorImageImplFromJson(json);

  @override
  final String? url;

  @override
  String toString() {
    return 'ActorImage(url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActorImageImpl &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url);

  /// Create a copy of ActorImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActorImageImplCopyWith<_$ActorImageImpl> get copyWith =>
      __$$ActorImageImplCopyWithImpl<_$ActorImageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActorImageImplToJson(this);
  }
}

abstract class _ActorImage implements ActorImage {
  const factory _ActorImage({final String? url}) = _$ActorImageImpl;

  factory _ActorImage.fromJson(Map<String, dynamic> json) =
      _$ActorImageImpl.fromJson;

  @override
  String? get url;

  /// Create a copy of ActorImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActorImageImplCopyWith<_$ActorImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActorAvatar _$ActorAvatarFromJson(Map<String, dynamic> json) {
  return _ActorAvatar.fromJson(json);
}

/// @nodoc
mixin _$ActorAvatar {
  String? get large => throw _privateConstructorUsedError;
  String? get normal => throw _privateConstructorUsedError;

  /// Serializes this ActorAvatar to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActorAvatar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActorAvatarCopyWith<ActorAvatar> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActorAvatarCopyWith<$Res> {
  factory $ActorAvatarCopyWith(
    ActorAvatar value,
    $Res Function(ActorAvatar) then,
  ) = _$ActorAvatarCopyWithImpl<$Res, ActorAvatar>;
  @useResult
  $Res call({String? large, String? normal});
}

/// @nodoc
class _$ActorAvatarCopyWithImpl<$Res, $Val extends ActorAvatar>
    implements $ActorAvatarCopyWith<$Res> {
  _$ActorAvatarCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActorAvatar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? large = freezed, Object? normal = freezed}) {
    return _then(
      _value.copyWith(
            large: freezed == large
                ? _value.large
                : large // ignore: cast_nullable_to_non_nullable
                      as String?,
            normal: freezed == normal
                ? _value.normal
                : normal // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActorAvatarImplCopyWith<$Res>
    implements $ActorAvatarCopyWith<$Res> {
  factory _$$ActorAvatarImplCopyWith(
    _$ActorAvatarImpl value,
    $Res Function(_$ActorAvatarImpl) then,
  ) = __$$ActorAvatarImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? large, String? normal});
}

/// @nodoc
class __$$ActorAvatarImplCopyWithImpl<$Res>
    extends _$ActorAvatarCopyWithImpl<$Res, _$ActorAvatarImpl>
    implements _$$ActorAvatarImplCopyWith<$Res> {
  __$$ActorAvatarImplCopyWithImpl(
    _$ActorAvatarImpl _value,
    $Res Function(_$ActorAvatarImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActorAvatar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? large = freezed, Object? normal = freezed}) {
    return _then(
      _$ActorAvatarImpl(
        large: freezed == large
            ? _value.large
            : large // ignore: cast_nullable_to_non_nullable
                  as String?,
        normal: freezed == normal
            ? _value.normal
            : normal // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActorAvatarImpl implements _ActorAvatar {
  const _$ActorAvatarImpl({this.large, this.normal});

  factory _$ActorAvatarImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActorAvatarImplFromJson(json);

  @override
  final String? large;
  @override
  final String? normal;

  @override
  String toString() {
    return 'ActorAvatar(large: $large, normal: $normal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActorAvatarImpl &&
            (identical(other.large, large) || other.large == large) &&
            (identical(other.normal, normal) || other.normal == normal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, large, normal);

  /// Create a copy of ActorAvatar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActorAvatarImplCopyWith<_$ActorAvatarImpl> get copyWith =>
      __$$ActorAvatarImplCopyWithImpl<_$ActorAvatarImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActorAvatarImplToJson(this);
  }
}

abstract class _ActorAvatar implements ActorAvatar {
  const factory _ActorAvatar({final String? large, final String? normal}) =
      _$ActorAvatarImpl;

  factory _ActorAvatar.fromJson(Map<String, dynamic> json) =
      _$ActorAvatarImpl.fromJson;

  @override
  String? get large;
  @override
  String? get normal;

  /// Create a copy of ActorAvatar
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActorAvatarImplCopyWith<_$ActorAvatarImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Director _$DirectorFromJson(Map<String, dynamic> json) {
  return _Director.fromJson(json);
}

/// @nodoc
mixin _$Director {
  bool? get adult => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get gender => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get original_name => throw _privateConstructorUsedError;
  String? get credit_id => throw _privateConstructorUsedError;
  String? get known_for_department => throw _privateConstructorUsedError;
  String? get job => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity => throw _privateConstructorUsedError;
  String? get profile_path => throw _privateConstructorUsedError;

  /// Serializes this Director to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DirectorCopyWith<Director> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DirectorCopyWith<$Res> {
  factory $DirectorCopyWith(Director value, $Res Function(Director) then) =
      _$DirectorCopyWithImpl<$Res, Director>;
  @useResult
  $Res call({
    bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? original_name,
    String? credit_id,
    String? known_for_department,
    String? job,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    String? profile_path,
  });
}

/// @nodoc
class _$DirectorCopyWithImpl<$Res, $Val extends Director>
    implements $DirectorCopyWith<$Res> {
  _$DirectorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adult = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? credit_id = freezed,
    Object? known_for_department = freezed,
    Object? job = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _value.copyWith(
            adult: freezed == adult
                ? _value.adult
                : adult // ignore: cast_nullable_to_non_nullable
                      as bool?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            credit_id: freezed == credit_id
                ? _value.credit_id
                : credit_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            known_for_department: freezed == known_for_department
                ? _value.known_for_department
                : known_for_department // ignore: cast_nullable_to_non_nullable
                      as String?,
            job: freezed == job
                ? _value.job
                : job // ignore: cast_nullable_to_non_nullable
                      as String?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as double?,
            profile_path: freezed == profile_path
                ? _value.profile_path
                : profile_path // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DirectorImplCopyWith<$Res>
    implements $DirectorCopyWith<$Res> {
  factory _$$DirectorImplCopyWith(
    _$DirectorImpl value,
    $Res Function(_$DirectorImpl) then,
  ) = __$$DirectorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? original_name,
    String? credit_id,
    String? known_for_department,
    String? job,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    String? profile_path,
  });
}

/// @nodoc
class __$$DirectorImplCopyWithImpl<$Res>
    extends _$DirectorCopyWithImpl<$Res, _$DirectorImpl>
    implements _$$DirectorImplCopyWith<$Res> {
  __$$DirectorImplCopyWithImpl(
    _$DirectorImpl _value,
    $Res Function(_$DirectorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? adult = freezed,
    Object? gender = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? credit_id = freezed,
    Object? known_for_department = freezed,
    Object? job = freezed,
    Object? popularity = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _$DirectorImpl(
        adult: freezed == adult
            ? _value.adult
            : adult // ignore: cast_nullable_to_non_nullable
                  as bool?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        credit_id: freezed == credit_id
            ? _value.credit_id
            : credit_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        known_for_department: freezed == known_for_department
            ? _value.known_for_department
            : known_for_department // ignore: cast_nullable_to_non_nullable
                  as String?,
        job: freezed == job
            ? _value.job
            : job // ignore: cast_nullable_to_non_nullable
                  as String?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as double?,
        profile_path: freezed == profile_path
            ? _value.profile_path
            : profile_path // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DirectorImpl implements _Director {
  const _$DirectorImpl({
    this.adult,
    @JsonKey(fromJson: _intFromJson) this.gender,
    @JsonKey(fromJson: _intFromJson) this.id,
    this.name,
    this.original_name,
    this.credit_id,
    this.known_for_department,
    this.job,
    @JsonKey(fromJson: _doubleFromJson) this.popularity,
    this.profile_path,
  });

  factory _$DirectorImpl.fromJson(Map<String, dynamic> json) =>
      _$$DirectorImplFromJson(json);

  @override
  final bool? adult;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? name;
  @override
  final String? original_name;
  @override
  final String? credit_id;
  @override
  final String? known_for_department;
  @override
  final String? job;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? popularity;
  @override
  final String? profile_path;

  @override
  String toString() {
    return 'Director(adult: $adult, gender: $gender, id: $id, name: $name, original_name: $original_name, credit_id: $credit_id, known_for_department: $known_for_department, job: $job, popularity: $popularity, profile_path: $profile_path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DirectorImpl &&
            (identical(other.adult, adult) || other.adult == adult) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            (identical(other.credit_id, credit_id) ||
                other.credit_id == credit_id) &&
            (identical(other.known_for_department, known_for_department) ||
                other.known_for_department == known_for_department) &&
            (identical(other.job, job) || other.job == job) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.profile_path, profile_path) ||
                other.profile_path == profile_path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    adult,
    gender,
    id,
    name,
    original_name,
    credit_id,
    known_for_department,
    job,
    popularity,
    profile_path,
  );

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DirectorImplCopyWith<_$DirectorImpl> get copyWith =>
      __$$DirectorImplCopyWithImpl<_$DirectorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DirectorImplToJson(this);
  }
}

abstract class _Director implements Director {
  const factory _Director({
    final bool? adult,
    @JsonKey(fromJson: _intFromJson) final int? gender,
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? name,
    final String? original_name,
    final String? credit_id,
    final String? known_for_department,
    final String? job,
    @JsonKey(fromJson: _doubleFromJson) final double? popularity,
    final String? profile_path,
  }) = _$DirectorImpl;

  factory _Director.fromJson(Map<String, dynamic> json) =
      _$DirectorImpl.fromJson;

  @override
  bool? get adult;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get gender;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get name;
  @override
  String? get original_name;
  @override
  String? get credit_id;
  @override
  String? get known_for_department;
  @override
  String? get job;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get popularity;
  @override
  String? get profile_path;

  /// Create a copy of Director
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DirectorImplCopyWith<_$DirectorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatedBy _$CreatedByFromJson(Map<String, dynamic> json) {
  return _CreatedBy.fromJson(json);
}

/// @nodoc
mixin _$CreatedBy {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get credit_id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get original_name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get gender => throw _privateConstructorUsedError;
  String? get profile_path => throw _privateConstructorUsedError;

  /// Serializes this CreatedBy to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatedByCopyWith<CreatedBy> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatedByCopyWith<$Res> {
  factory $CreatedByCopyWith(CreatedBy value, $Res Function(CreatedBy) then) =
      _$CreatedByCopyWithImpl<$Res, CreatedBy>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? credit_id,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _intFromJson) int? gender,
    String? profile_path,
  });
}

/// @nodoc
class _$CreatedByCopyWithImpl<$Res, $Val extends CreatedBy>
    implements $CreatedByCopyWith<$Res> {
  _$CreatedByCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? credit_id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? gender = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            credit_id: freezed == credit_id
                ? _value.credit_id
                : credit_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            original_name: freezed == original_name
                ? _value.original_name
                : original_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as int?,
            profile_path: freezed == profile_path
                ? _value.profile_path
                : profile_path // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatedByImplCopyWith<$Res>
    implements $CreatedByCopyWith<$Res> {
  factory _$$CreatedByImplCopyWith(
    _$CreatedByImpl value,
    $Res Function(_$CreatedByImpl) then,
  ) = __$$CreatedByImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? credit_id,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _intFromJson) int? gender,
    String? profile_path,
  });
}

/// @nodoc
class __$$CreatedByImplCopyWithImpl<$Res>
    extends _$CreatedByCopyWithImpl<$Res, _$CreatedByImpl>
    implements _$$CreatedByImplCopyWith<$Res> {
  __$$CreatedByImplCopyWithImpl(
    _$CreatedByImpl _value,
    $Res Function(_$CreatedByImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? credit_id = freezed,
    Object? name = freezed,
    Object? original_name = freezed,
    Object? gender = freezed,
    Object? profile_path = freezed,
  }) {
    return _then(
      _$CreatedByImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        credit_id: freezed == credit_id
            ? _value.credit_id
            : credit_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        original_name: freezed == original_name
            ? _value.original_name
            : original_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as int?,
        profile_path: freezed == profile_path
            ? _value.profile_path
            : profile_path // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatedByImpl implements _CreatedBy {
  const _$CreatedByImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    this.credit_id,
    this.name,
    this.original_name,
    @JsonKey(fromJson: _intFromJson) this.gender,
    this.profile_path,
  });

  factory _$CreatedByImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatedByImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? credit_id;
  @override
  final String? name;
  @override
  final String? original_name;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? gender;
  @override
  final String? profile_path;

  @override
  String toString() {
    return 'CreatedBy(id: $id, credit_id: $credit_id, name: $name, original_name: $original_name, gender: $gender, profile_path: $profile_path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatedByImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.credit_id, credit_id) ||
                other.credit_id == credit_id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.original_name, original_name) ||
                other.original_name == original_name) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.profile_path, profile_path) ||
                other.profile_path == profile_path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    credit_id,
    name,
    original_name,
    gender,
    profile_path,
  );

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatedByImplCopyWith<_$CreatedByImpl> get copyWith =>
      __$$CreatedByImplCopyWithImpl<_$CreatedByImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatedByImplToJson(this);
  }
}

abstract class _CreatedBy implements CreatedBy {
  const factory _CreatedBy({
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? credit_id,
    final String? name,
    final String? original_name,
    @JsonKey(fromJson: _intFromJson) final int? gender,
    final String? profile_path,
  }) = _$CreatedByImpl;

  factory _CreatedBy.fromJson(Map<String, dynamic> json) =
      _$CreatedByImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get credit_id;
  @override
  String? get name;
  @override
  String? get original_name;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get gender;
  @override
  String? get profile_path;

  /// Create a copy of CreatedBy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatedByImplCopyWith<_$CreatedByImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Genre _$GenreFromJson(Map<String, dynamic> json) {
  return _Genre.fromJson(json);
}

/// @nodoc
mixin _$Genre {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this Genre to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenreCopyWith<Genre> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenreCopyWith<$Res> {
  factory $GenreCopyWith(Genre value, $Res Function(Genre) then) =
      _$GenreCopyWithImpl<$Res, Genre>;
  @useResult
  $Res call({@JsonKey(fromJson: _intFromJson) int? id, String? name});
}

/// @nodoc
class _$GenreCopyWithImpl<$Res, $Val extends Genre>
    implements $GenreCopyWith<$Res> {
  _$GenreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = freezed, Object? name = freezed}) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GenreImplCopyWith<$Res> implements $GenreCopyWith<$Res> {
  factory _$$GenreImplCopyWith(
    _$GenreImpl value,
    $Res Function(_$GenreImpl) then,
  ) = __$$GenreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(fromJson: _intFromJson) int? id, String? name});
}

/// @nodoc
class __$$GenreImplCopyWithImpl<$Res>
    extends _$GenreCopyWithImpl<$Res, _$GenreImpl>
    implements _$$GenreImplCopyWith<$Res> {
  __$$GenreImplCopyWithImpl(
    _$GenreImpl _value,
    $Res Function(_$GenreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = freezed, Object? name = freezed}) {
    return _then(
      _$GenreImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GenreImpl implements _Genre {
  const _$GenreImpl({@JsonKey(fromJson: _intFromJson) this.id, this.name});

  factory _$GenreImpl.fromJson(Map<String, dynamic> json) =>
      _$$GenreImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? name;

  @override
  String toString() {
    return 'Genre(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenreImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenreImplCopyWith<_$GenreImpl> get copyWith =>
      __$$GenreImplCopyWithImpl<_$GenreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GenreImplToJson(this);
  }
}

abstract class _Genre implements Genre {
  const factory _Genre({
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? name,
  }) = _$GenreImpl;

  factory _Genre.fromJson(Map<String, dynamic> json) = _$GenreImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get name;

  /// Create a copy of Genre
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenreImplCopyWith<_$GenreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Network _$NetworkFromJson(Map<String, dynamic> json) {
  return _Network.fromJson(json);
}

/// @nodoc
mixin _$Network {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get logo_path => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get origin_country => throw _privateConstructorUsedError;

  /// Serializes this Network to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkCopyWith<Network> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkCopyWith<$Res> {
  factory $NetworkCopyWith(Network value, $Res Function(Network) then) =
      _$NetworkCopyWithImpl<$Res, Network>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  });
}

/// @nodoc
class _$NetworkCopyWithImpl<$Res, $Val extends Network>
    implements $NetworkCopyWith<$Res> {
  _$NetworkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            logo_path: freezed == logo_path
                ? _value.logo_path
                : logo_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            origin_country: freezed == origin_country
                ? _value.origin_country
                : origin_country // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NetworkImplCopyWith<$Res> implements $NetworkCopyWith<$Res> {
  factory _$$NetworkImplCopyWith(
    _$NetworkImpl value,
    $Res Function(_$NetworkImpl) then,
  ) = __$$NetworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  });
}

/// @nodoc
class __$$NetworkImplCopyWithImpl<$Res>
    extends _$NetworkCopyWithImpl<$Res, _$NetworkImpl>
    implements _$$NetworkImplCopyWith<$Res> {
  __$$NetworkImplCopyWithImpl(
    _$NetworkImpl _value,
    $Res Function(_$NetworkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _$NetworkImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        logo_path: freezed == logo_path
            ? _value.logo_path
            : logo_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        origin_country: freezed == origin_country
            ? _value.origin_country
            : origin_country // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkImpl implements _Network {
  const _$NetworkImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    this.logo_path,
    this.name,
    this.origin_country,
  });

  factory _$NetworkImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? logo_path;
  @override
  final String? name;
  @override
  final String? origin_country;

  @override
  String toString() {
    return 'Network(id: $id, logo_path: $logo_path, name: $name, origin_country: $origin_country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.logo_path, logo_path) ||
                other.logo_path == logo_path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.origin_country, origin_country) ||
                other.origin_country == origin_country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, logo_path, name, origin_country);

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkImplCopyWith<_$NetworkImpl> get copyWith =>
      __$$NetworkImplCopyWithImpl<_$NetworkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkImplToJson(this);
  }
}

abstract class _Network implements Network {
  const factory _Network({
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? logo_path,
    final String? name,
    final String? origin_country,
  }) = _$NetworkImpl;

  factory _Network.fromJson(Map<String, dynamic> json) = _$NetworkImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get logo_path;
  @override
  String? get name;
  @override
  String? get origin_country;

  /// Create a copy of Network
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkImplCopyWith<_$NetworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionCompany _$ProductionCompanyFromJson(Map<String, dynamic> json) {
  return _ProductionCompany.fromJson(json);
}

/// @nodoc
mixin _$ProductionCompany {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get logo_path => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get origin_country => throw _privateConstructorUsedError;

  /// Serializes this ProductionCompany to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductionCompanyCopyWith<ProductionCompany> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionCompanyCopyWith<$Res> {
  factory $ProductionCompanyCopyWith(
    ProductionCompany value,
    $Res Function(ProductionCompany) then,
  ) = _$ProductionCompanyCopyWithImpl<$Res, ProductionCompany>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  });
}

/// @nodoc
class _$ProductionCompanyCopyWithImpl<$Res, $Val extends ProductionCompany>
    implements $ProductionCompanyCopyWith<$Res> {
  _$ProductionCompanyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            logo_path: freezed == logo_path
                ? _value.logo_path
                : logo_path // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            origin_country: freezed == origin_country
                ? _value.origin_country
                : origin_country // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductionCompanyImplCopyWith<$Res>
    implements $ProductionCompanyCopyWith<$Res> {
  factory _$$ProductionCompanyImplCopyWith(
    _$ProductionCompanyImpl value,
    $Res Function(_$ProductionCompanyImpl) then,
  ) = __$$ProductionCompanyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  });
}

/// @nodoc
class __$$ProductionCompanyImplCopyWithImpl<$Res>
    extends _$ProductionCompanyCopyWithImpl<$Res, _$ProductionCompanyImpl>
    implements _$$ProductionCompanyImplCopyWith<$Res> {
  __$$ProductionCompanyImplCopyWithImpl(
    _$ProductionCompanyImpl _value,
    $Res Function(_$ProductionCompanyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? logo_path = freezed,
    Object? name = freezed,
    Object? origin_country = freezed,
  }) {
    return _then(
      _$ProductionCompanyImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        logo_path: freezed == logo_path
            ? _value.logo_path
            : logo_path // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        origin_country: freezed == origin_country
            ? _value.origin_country
            : origin_country // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionCompanyImpl implements _ProductionCompany {
  const _$ProductionCompanyImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    this.logo_path,
    this.name,
    this.origin_country,
  });

  factory _$ProductionCompanyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionCompanyImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? logo_path;
  @override
  final String? name;
  @override
  final String? origin_country;

  @override
  String toString() {
    return 'ProductionCompany(id: $id, logo_path: $logo_path, name: $name, origin_country: $origin_country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionCompanyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.logo_path, logo_path) ||
                other.logo_path == logo_path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.origin_country, origin_country) ||
                other.origin_country == origin_country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, logo_path, name, origin_country);

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionCompanyImplCopyWith<_$ProductionCompanyImpl> get copyWith =>
      __$$ProductionCompanyImplCopyWithImpl<_$ProductionCompanyImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionCompanyImplToJson(this);
  }
}

abstract class _ProductionCompany implements ProductionCompany {
  const factory _ProductionCompany({
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? logo_path,
    final String? name,
    final String? origin_country,
  }) = _$ProductionCompanyImpl;

  factory _ProductionCompany.fromJson(Map<String, dynamic> json) =
      _$ProductionCompanyImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get logo_path;
  @override
  String? get name;
  @override
  String? get origin_country;

  /// Create a copy of ProductionCompany
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductionCompanyImplCopyWith<_$ProductionCompanyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductionCountry _$ProductionCountryFromJson(Map<String, dynamic> json) {
  return _ProductionCountry.fromJson(json);
}

/// @nodoc
mixin _$ProductionCountry {
  String? get iso_3166_1 => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this ProductionCountry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductionCountryCopyWith<ProductionCountry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionCountryCopyWith<$Res> {
  factory $ProductionCountryCopyWith(
    ProductionCountry value,
    $Res Function(ProductionCountry) then,
  ) = _$ProductionCountryCopyWithImpl<$Res, ProductionCountry>;
  @useResult
  $Res call({String? iso_3166_1, String? name});
}

/// @nodoc
class _$ProductionCountryCopyWithImpl<$Res, $Val extends ProductionCountry>
    implements $ProductionCountryCopyWith<$Res> {
  _$ProductionCountryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iso_3166_1 = freezed, Object? name = freezed}) {
    return _then(
      _value.copyWith(
            iso_3166_1: freezed == iso_3166_1
                ? _value.iso_3166_1
                : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductionCountryImplCopyWith<$Res>
    implements $ProductionCountryCopyWith<$Res> {
  factory _$$ProductionCountryImplCopyWith(
    _$ProductionCountryImpl value,
    $Res Function(_$ProductionCountryImpl) then,
  ) = __$$ProductionCountryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? iso_3166_1, String? name});
}

/// @nodoc
class __$$ProductionCountryImplCopyWithImpl<$Res>
    extends _$ProductionCountryCopyWithImpl<$Res, _$ProductionCountryImpl>
    implements _$$ProductionCountryImplCopyWith<$Res> {
  __$$ProductionCountryImplCopyWithImpl(
    _$ProductionCountryImpl _value,
    $Res Function(_$ProductionCountryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iso_3166_1 = freezed, Object? name = freezed}) {
    return _then(
      _$ProductionCountryImpl(
        iso_3166_1: freezed == iso_3166_1
            ? _value.iso_3166_1
            : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionCountryImpl implements _ProductionCountry {
  const _$ProductionCountryImpl({this.iso_3166_1, this.name});

  factory _$ProductionCountryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionCountryImplFromJson(json);

  @override
  final String? iso_3166_1;
  @override
  final String? name;

  @override
  String toString() {
    return 'ProductionCountry(iso_3166_1: $iso_3166_1, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionCountryImpl &&
            (identical(other.iso_3166_1, iso_3166_1) ||
                other.iso_3166_1 == iso_3166_1) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, iso_3166_1, name);

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionCountryImplCopyWith<_$ProductionCountryImpl> get copyWith =>
      __$$ProductionCountryImplCopyWithImpl<_$ProductionCountryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionCountryImplToJson(this);
  }
}

abstract class _ProductionCountry implements ProductionCountry {
  const factory _ProductionCountry({
    final String? iso_3166_1,
    final String? name,
  }) = _$ProductionCountryImpl;

  factory _ProductionCountry.fromJson(Map<String, dynamic> json) =
      _$ProductionCountryImpl.fromJson;

  @override
  String? get iso_3166_1;
  @override
  String? get name;

  /// Create a copy of ProductionCountry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductionCountryImplCopyWith<_$ProductionCountryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpokenLanguage _$SpokenLanguageFromJson(Map<String, dynamic> json) {
  return _SpokenLanguage.fromJson(json);
}

/// @nodoc
mixin _$SpokenLanguage {
  String? get english_name => throw _privateConstructorUsedError;
  String? get iso_639_1 => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this SpokenLanguage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpokenLanguageCopyWith<SpokenLanguage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpokenLanguageCopyWith<$Res> {
  factory $SpokenLanguageCopyWith(
    SpokenLanguage value,
    $Res Function(SpokenLanguage) then,
  ) = _$SpokenLanguageCopyWithImpl<$Res, SpokenLanguage>;
  @useResult
  $Res call({String? english_name, String? iso_639_1, String? name});
}

/// @nodoc
class _$SpokenLanguageCopyWithImpl<$Res, $Val extends SpokenLanguage>
    implements $SpokenLanguageCopyWith<$Res> {
  _$SpokenLanguageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? english_name = freezed,
    Object? iso_639_1 = freezed,
    Object? name = freezed,
  }) {
    return _then(
      _value.copyWith(
            english_name: freezed == english_name
                ? _value.english_name
                : english_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            iso_639_1: freezed == iso_639_1
                ? _value.iso_639_1
                : iso_639_1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpokenLanguageImplCopyWith<$Res>
    implements $SpokenLanguageCopyWith<$Res> {
  factory _$$SpokenLanguageImplCopyWith(
    _$SpokenLanguageImpl value,
    $Res Function(_$SpokenLanguageImpl) then,
  ) = __$$SpokenLanguageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? english_name, String? iso_639_1, String? name});
}

/// @nodoc
class __$$SpokenLanguageImplCopyWithImpl<$Res>
    extends _$SpokenLanguageCopyWithImpl<$Res, _$SpokenLanguageImpl>
    implements _$$SpokenLanguageImplCopyWith<$Res> {
  __$$SpokenLanguageImplCopyWithImpl(
    _$SpokenLanguageImpl _value,
    $Res Function(_$SpokenLanguageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? english_name = freezed,
    Object? iso_639_1 = freezed,
    Object? name = freezed,
  }) {
    return _then(
      _$SpokenLanguageImpl(
        english_name: freezed == english_name
            ? _value.english_name
            : english_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        iso_639_1: freezed == iso_639_1
            ? _value.iso_639_1
            : iso_639_1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpokenLanguageImpl implements _SpokenLanguage {
  const _$SpokenLanguageImpl({this.english_name, this.iso_639_1, this.name});

  factory _$SpokenLanguageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpokenLanguageImplFromJson(json);

  @override
  final String? english_name;
  @override
  final String? iso_639_1;
  @override
  final String? name;

  @override
  String toString() {
    return 'SpokenLanguage(english_name: $english_name, iso_639_1: $iso_639_1, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpokenLanguageImpl &&
            (identical(other.english_name, english_name) ||
                other.english_name == english_name) &&
            (identical(other.iso_639_1, iso_639_1) ||
                other.iso_639_1 == iso_639_1) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, english_name, iso_639_1, name);

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpokenLanguageImplCopyWith<_$SpokenLanguageImpl> get copyWith =>
      __$$SpokenLanguageImplCopyWithImpl<_$SpokenLanguageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpokenLanguageImplToJson(this);
  }
}

abstract class _SpokenLanguage implements SpokenLanguage {
  const factory _SpokenLanguage({
    final String? english_name,
    final String? iso_639_1,
    final String? name,
  }) = _$SpokenLanguageImpl;

  factory _SpokenLanguage.fromJson(Map<String, dynamic> json) =
      _$SpokenLanguageImpl.fromJson;

  @override
  String? get english_name;
  @override
  String? get iso_639_1;
  @override
  String? get name;

  /// Create a copy of SpokenLanguage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpokenLanguageImplCopyWith<_$SpokenLanguageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReleaseDate _$ReleaseDateFromJson(Map<String, dynamic> json) {
  return _ReleaseDate.fromJson(json);
}

/// @nodoc
mixin _$ReleaseDate {
  String? get iso_3166_1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get certification => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get release_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get type => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this ReleaseDate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReleaseDateCopyWith<ReleaseDate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReleaseDateCopyWith<$Res> {
  factory $ReleaseDateCopyWith(
    ReleaseDate value,
    $Res Function(ReleaseDate) then,
  ) = _$ReleaseDateCopyWithImpl<$Res, ReleaseDate>;
  @useResult
  $Res call({
    String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? certification,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _intFromJson) int? type,
    String? note,
  });
}

/// @nodoc
class _$ReleaseDateCopyWithImpl<$Res, $Val extends ReleaseDate>
    implements $ReleaseDateCopyWith<$Res> {
  _$ReleaseDateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? iso_3166_1 = freezed,
    Object? certification = freezed,
    Object? release_date = freezed,
    Object? type = freezed,
    Object? note = freezed,
  }) {
    return _then(
      _value.copyWith(
            iso_3166_1: freezed == iso_3166_1
                ? _value.iso_3166_1
                : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            certification: freezed == certification
                ? _value.certification
                : certification // ignore: cast_nullable_to_non_nullable
                      as String?,
            release_date: freezed == release_date
                ? _value.release_date
                : release_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReleaseDateImplCopyWith<$Res>
    implements $ReleaseDateCopyWith<$Res> {
  factory _$$ReleaseDateImplCopyWith(
    _$ReleaseDateImpl value,
    $Res Function(_$ReleaseDateImpl) then,
  ) = __$$ReleaseDateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? certification,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _intFromJson) int? type,
    String? note,
  });
}

/// @nodoc
class __$$ReleaseDateImplCopyWithImpl<$Res>
    extends _$ReleaseDateCopyWithImpl<$Res, _$ReleaseDateImpl>
    implements _$$ReleaseDateImplCopyWith<$Res> {
  __$$ReleaseDateImplCopyWithImpl(
    _$ReleaseDateImpl _value,
    $Res Function(_$ReleaseDateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? iso_3166_1 = freezed,
    Object? certification = freezed,
    Object? release_date = freezed,
    Object? type = freezed,
    Object? note = freezed,
  }) {
    return _then(
      _$ReleaseDateImpl(
        iso_3166_1: freezed == iso_3166_1
            ? _value.iso_3166_1
            : iso_3166_1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        certification: freezed == certification
            ? _value.certification
            : certification // ignore: cast_nullable_to_non_nullable
                  as String?,
        release_date: freezed == release_date
            ? _value.release_date
            : release_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReleaseDateImpl implements _ReleaseDate {
  const _$ReleaseDateImpl({
    this.iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) this.certification,
    @JsonKey(fromJson: _stringFromJson) this.release_date,
    @JsonKey(fromJson: _intFromJson) this.type,
    this.note,
  });

  factory _$ReleaseDateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReleaseDateImplFromJson(json);

  @override
  final String? iso_3166_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? certification;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? release_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? type;
  @override
  final String? note;

  @override
  String toString() {
    return 'ReleaseDate(iso_3166_1: $iso_3166_1, certification: $certification, release_date: $release_date, type: $type, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReleaseDateImpl &&
            (identical(other.iso_3166_1, iso_3166_1) ||
                other.iso_3166_1 == iso_3166_1) &&
            (identical(other.certification, certification) ||
                other.certification == certification) &&
            (identical(other.release_date, release_date) ||
                other.release_date == release_date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    iso_3166_1,
    certification,
    release_date,
    type,
    note,
  );

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReleaseDateImplCopyWith<_$ReleaseDateImpl> get copyWith =>
      __$$ReleaseDateImplCopyWithImpl<_$ReleaseDateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReleaseDateImplToJson(this);
  }
}

abstract class _ReleaseDate implements ReleaseDate {
  const factory _ReleaseDate({
    final String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) final String? certification,
    @JsonKey(fromJson: _stringFromJson) final String? release_date,
    @JsonKey(fromJson: _intFromJson) final int? type,
    final String? note,
  }) = _$ReleaseDateImpl;

  factory _ReleaseDate.fromJson(Map<String, dynamic> json) =
      _$ReleaseDateImpl.fromJson;

  @override
  String? get iso_3166_1;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get certification;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get release_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get type;
  @override
  String? get note;

  /// Create a copy of ReleaseDate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReleaseDateImplCopyWith<_$ReleaseDateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NextEpisodeToAir _$NextEpisodeToAirFromJson(Map<String, dynamic> json) {
  return _NextEpisodeToAir.fromJson(json);
}

/// @nodoc
mixin _$NextEpisodeToAir {
  @JsonKey(fromJson: _intFromJson)
  int? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get overview => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count => throw _privateConstructorUsedError;
  String? get air_date => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get episode_number => throw _privateConstructorUsedError;
  String? get episode_type => throw _privateConstructorUsedError;
  String? get production_code => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get runtime => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get season_number => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get show_id => throw _privateConstructorUsedError;
  String? get still_path => throw _privateConstructorUsedError;

  /// Serializes this NextEpisodeToAir to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NextEpisodeToAirCopyWith<NextEpisodeToAir> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NextEpisodeToAirCopyWith<$Res> {
  factory $NextEpisodeToAirCopyWith(
    NextEpisodeToAir value,
    $Res Function(NextEpisodeToAir) then,
  ) = _$NextEpisodeToAirCopyWithImpl<$Res, NextEpisodeToAir>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_number,
    String? episode_type,
    String? production_code,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _intFromJson) int? show_id,
    String? still_path,
  });
}

/// @nodoc
class _$NextEpisodeToAirCopyWithImpl<$Res, $Val extends NextEpisodeToAir>
    implements $NextEpisodeToAirCopyWith<$Res> {
  _$NextEpisodeToAirCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? vote_average = freezed,
    Object? vote_count = freezed,
    Object? air_date = freezed,
    Object? episode_number = freezed,
    Object? episode_type = freezed,
    Object? production_code = freezed,
    Object? runtime = freezed,
    Object? season_number = freezed,
    Object? show_id = freezed,
    Object? still_path = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            overview: freezed == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String?,
            vote_average: freezed == vote_average
                ? _value.vote_average
                : vote_average // ignore: cast_nullable_to_non_nullable
                      as double?,
            vote_count: freezed == vote_count
                ? _value.vote_count
                : vote_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            air_date: freezed == air_date
                ? _value.air_date
                : air_date // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_number: freezed == episode_number
                ? _value.episode_number
                : episode_number // ignore: cast_nullable_to_non_nullable
                      as int?,
            episode_type: freezed == episode_type
                ? _value.episode_type
                : episode_type // ignore: cast_nullable_to_non_nullable
                      as String?,
            production_code: freezed == production_code
                ? _value.production_code
                : production_code // ignore: cast_nullable_to_non_nullable
                      as String?,
            runtime: freezed == runtime
                ? _value.runtime
                : runtime // ignore: cast_nullable_to_non_nullable
                      as int?,
            season_number: freezed == season_number
                ? _value.season_number
                : season_number // ignore: cast_nullable_to_non_nullable
                      as int?,
            show_id: freezed == show_id
                ? _value.show_id
                : show_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            still_path: freezed == still_path
                ? _value.still_path
                : still_path // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NextEpisodeToAirImplCopyWith<$Res>
    implements $NextEpisodeToAirCopyWith<$Res> {
  factory _$$NextEpisodeToAirImplCopyWith(
    _$NextEpisodeToAirImpl value,
    $Res Function(_$NextEpisodeToAirImpl) then,
  ) = __$$NextEpisodeToAirImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_number,
    String? episode_type,
    String? production_code,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _intFromJson) int? show_id,
    String? still_path,
  });
}

/// @nodoc
class __$$NextEpisodeToAirImplCopyWithImpl<$Res>
    extends _$NextEpisodeToAirCopyWithImpl<$Res, _$NextEpisodeToAirImpl>
    implements _$$NextEpisodeToAirImplCopyWith<$Res> {
  __$$NextEpisodeToAirImplCopyWithImpl(
    _$NextEpisodeToAirImpl _value,
    $Res Function(_$NextEpisodeToAirImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? overview = freezed,
    Object? vote_average = freezed,
    Object? vote_count = freezed,
    Object? air_date = freezed,
    Object? episode_number = freezed,
    Object? episode_type = freezed,
    Object? production_code = freezed,
    Object? runtime = freezed,
    Object? season_number = freezed,
    Object? show_id = freezed,
    Object? still_path = freezed,
  }) {
    return _then(
      _$NextEpisodeToAirImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        overview: freezed == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String?,
        vote_average: freezed == vote_average
            ? _value.vote_average
            : vote_average // ignore: cast_nullable_to_non_nullable
                  as double?,
        vote_count: freezed == vote_count
            ? _value.vote_count
            : vote_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        air_date: freezed == air_date
            ? _value.air_date
            : air_date // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_number: freezed == episode_number
            ? _value.episode_number
            : episode_number // ignore: cast_nullable_to_non_nullable
                  as int?,
        episode_type: freezed == episode_type
            ? _value.episode_type
            : episode_type // ignore: cast_nullable_to_non_nullable
                  as String?,
        production_code: freezed == production_code
            ? _value.production_code
            : production_code // ignore: cast_nullable_to_non_nullable
                  as String?,
        runtime: freezed == runtime
            ? _value.runtime
            : runtime // ignore: cast_nullable_to_non_nullable
                  as int?,
        season_number: freezed == season_number
            ? _value.season_number
            : season_number // ignore: cast_nullable_to_non_nullable
                  as int?,
        show_id: freezed == show_id
            ? _value.show_id
            : show_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        still_path: freezed == still_path
            ? _value.still_path
            : still_path // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NextEpisodeToAirImpl implements _NextEpisodeToAir {
  const _$NextEpisodeToAirImpl({
    @JsonKey(fromJson: _intFromJson) this.id,
    this.name,
    this.overview,
    @JsonKey(fromJson: _doubleFromJson) this.vote_average,
    @JsonKey(fromJson: _intFromJson) this.vote_count,
    this.air_date,
    @JsonKey(fromJson: _intFromJson) this.episode_number,
    this.episode_type,
    this.production_code,
    @JsonKey(fromJson: _intFromJson) this.runtime,
    @JsonKey(fromJson: _intFromJson) this.season_number,
    @JsonKey(fromJson: _intFromJson) this.show_id,
    this.still_path,
  });

  factory _$NextEpisodeToAirImpl.fromJson(Map<String, dynamic> json) =>
      _$$NextEpisodeToAirImplFromJson(json);

  @override
  @JsonKey(fromJson: _intFromJson)
  final int? id;
  @override
  final String? name;
  @override
  final String? overview;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? vote_average;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? vote_count;
  @override
  final String? air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? episode_number;
  @override
  final String? episode_type;
  @override
  final String? production_code;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? runtime;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? season_number;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? show_id;
  @override
  final String? still_path;

  @override
  String toString() {
    return 'NextEpisodeToAir(id: $id, name: $name, overview: $overview, vote_average: $vote_average, vote_count: $vote_count, air_date: $air_date, episode_number: $episode_number, episode_type: $episode_type, production_code: $production_code, runtime: $runtime, season_number: $season_number, show_id: $show_id, still_path: $still_path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NextEpisodeToAirImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.vote_average, vote_average) ||
                other.vote_average == vote_average) &&
            (identical(other.vote_count, vote_count) ||
                other.vote_count == vote_count) &&
            (identical(other.air_date, air_date) ||
                other.air_date == air_date) &&
            (identical(other.episode_number, episode_number) ||
                other.episode_number == episode_number) &&
            (identical(other.episode_type, episode_type) ||
                other.episode_type == episode_type) &&
            (identical(other.production_code, production_code) ||
                other.production_code == production_code) &&
            (identical(other.runtime, runtime) || other.runtime == runtime) &&
            (identical(other.season_number, season_number) ||
                other.season_number == season_number) &&
            (identical(other.show_id, show_id) || other.show_id == show_id) &&
            (identical(other.still_path, still_path) ||
                other.still_path == still_path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    overview,
    vote_average,
    vote_count,
    air_date,
    episode_number,
    episode_type,
    production_code,
    runtime,
    season_number,
    show_id,
    still_path,
  );

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NextEpisodeToAirImplCopyWith<_$NextEpisodeToAirImpl> get copyWith =>
      __$$NextEpisodeToAirImplCopyWithImpl<_$NextEpisodeToAirImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NextEpisodeToAirImplToJson(this);
  }
}

abstract class _NextEpisodeToAir implements NextEpisodeToAir {
  const factory _NextEpisodeToAir({
    @JsonKey(fromJson: _intFromJson) final int? id,
    final String? name,
    final String? overview,
    @JsonKey(fromJson: _doubleFromJson) final double? vote_average,
    @JsonKey(fromJson: _intFromJson) final int? vote_count,
    final String? air_date,
    @JsonKey(fromJson: _intFromJson) final int? episode_number,
    final String? episode_type,
    final String? production_code,
    @JsonKey(fromJson: _intFromJson) final int? runtime,
    @JsonKey(fromJson: _intFromJson) final int? season_number,
    @JsonKey(fromJson: _intFromJson) final int? show_id,
    final String? still_path,
  }) = _$NextEpisodeToAirImpl;

  factory _NextEpisodeToAir.fromJson(Map<String, dynamic> json) =
      _$NextEpisodeToAirImpl.fromJson;

  @override
  @JsonKey(fromJson: _intFromJson)
  int? get id;
  @override
  String? get name;
  @override
  String? get overview;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get vote_average;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get vote_count;
  @override
  String? get air_date;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get episode_number;
  @override
  String? get episode_type;
  @override
  String? get production_code;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get runtime;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get season_number;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get show_id;
  @override
  String? get still_path;

  /// Create a copy of NextEpisodeToAir
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NextEpisodeToAirImplCopyWith<_$NextEpisodeToAirImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EpisodeGroup _$EpisodeGroupFromJson(Map<String, dynamic> json) {
  return _EpisodeGroup.fromJson(json);
}

/// @nodoc
mixin _$EpisodeGroup {
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get group_count => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringFromJson)
  String? get network => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromJson)
  int? get type => throw _privateConstructorUsedError;

  /// Serializes this EpisodeGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpisodeGroupCopyWith<EpisodeGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodeGroupCopyWith<$Res> {
  factory $EpisodeGroupCopyWith(
    EpisodeGroup value,
    $Res Function(EpisodeGroup) then,
  ) = _$EpisodeGroupCopyWithImpl<$Res, EpisodeGroup>;
  @useResult
  $Res call({
    String? description,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? group_count,
    String? id,
    String? name,
    @JsonKey(fromJson: _stringFromJson) String? network,
    @JsonKey(fromJson: _intFromJson) int? type,
  });
}

/// @nodoc
class _$EpisodeGroupCopyWithImpl<$Res, $Val extends EpisodeGroup>
    implements $EpisodeGroupCopyWith<$Res> {
  _$EpisodeGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = freezed,
    Object? episode_count = freezed,
    Object? group_count = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? network = freezed,
    Object? type = freezed,
  }) {
    return _then(
      _value.copyWith(
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            episode_count: freezed == episode_count
                ? _value.episode_count
                : episode_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            group_count: freezed == group_count
                ? _value.group_count
                : group_count // ignore: cast_nullable_to_non_nullable
                      as int?,
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            network: freezed == network
                ? _value.network
                : network // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EpisodeGroupImplCopyWith<$Res>
    implements $EpisodeGroupCopyWith<$Res> {
  factory _$$EpisodeGroupImplCopyWith(
    _$EpisodeGroupImpl value,
    $Res Function(_$EpisodeGroupImpl) then,
  ) = __$$EpisodeGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? description,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? group_count,
    String? id,
    String? name,
    @JsonKey(fromJson: _stringFromJson) String? network,
    @JsonKey(fromJson: _intFromJson) int? type,
  });
}

/// @nodoc
class __$$EpisodeGroupImplCopyWithImpl<$Res>
    extends _$EpisodeGroupCopyWithImpl<$Res, _$EpisodeGroupImpl>
    implements _$$EpisodeGroupImplCopyWith<$Res> {
  __$$EpisodeGroupImplCopyWithImpl(
    _$EpisodeGroupImpl _value,
    $Res Function(_$EpisodeGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = freezed,
    Object? episode_count = freezed,
    Object? group_count = freezed,
    Object? id = freezed,
    Object? name = freezed,
    Object? network = freezed,
    Object? type = freezed,
  }) {
    return _then(
      _$EpisodeGroupImpl(
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        episode_count: freezed == episode_count
            ? _value.episode_count
            : episode_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        group_count: freezed == group_count
            ? _value.group_count
            : group_count // ignore: cast_nullable_to_non_nullable
                  as int?,
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        network: freezed == network
            ? _value.network
            : network // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EpisodeGroupImpl implements _EpisodeGroup {
  const _$EpisodeGroupImpl({
    this.description,
    @JsonKey(fromJson: _intFromJson) this.episode_count,
    @JsonKey(fromJson: _intFromJson) this.group_count,
    this.id,
    this.name,
    @JsonKey(fromJson: _stringFromJson) this.network,
    @JsonKey(fromJson: _intFromJson) this.type,
  });

  factory _$EpisodeGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpisodeGroupImplFromJson(json);

  @override
  final String? description;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? group_count;
  @override
  final String? id;
  @override
  final String? name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  final String? network;
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? type;

  @override
  String toString() {
    return 'EpisodeGroup(description: $description, episode_count: $episode_count, group_count: $group_count, id: $id, name: $name, network: $network, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodeGroupImpl &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.episode_count, episode_count) ||
                other.episode_count == episode_count) &&
            (identical(other.group_count, group_count) ||
                other.group_count == group_count) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    description,
    episode_count,
    group_count,
    id,
    name,
    network,
    type,
  );

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodeGroupImplCopyWith<_$EpisodeGroupImpl> get copyWith =>
      __$$EpisodeGroupImplCopyWithImpl<_$EpisodeGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpisodeGroupImplToJson(this);
  }
}

abstract class _EpisodeGroup implements EpisodeGroup {
  const factory _EpisodeGroup({
    final String? description,
    @JsonKey(fromJson: _intFromJson) final int? episode_count,
    @JsonKey(fromJson: _intFromJson) final int? group_count,
    final String? id,
    final String? name,
    @JsonKey(fromJson: _stringFromJson) final String? network,
    @JsonKey(fromJson: _intFromJson) final int? type,
  }) = _$EpisodeGroupImpl;

  factory _EpisodeGroup.fromJson(Map<String, dynamic> json) =
      _$EpisodeGroupImpl.fromJson;

  @override
  String? get description;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get episode_count;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get group_count;
  @override
  String? get id;
  @override
  String? get name;
  @override
  @JsonKey(fromJson: _stringFromJson)
  String? get network;
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get type;

  /// Create a copy of EpisodeGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodeGroupImplCopyWith<_$EpisodeGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
