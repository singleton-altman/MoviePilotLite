import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_detail_model.freezed.dart';
part 'media_detail_model.g.dart';

@freezed
class MediaDetail with _$MediaDetail {
  const factory MediaDetail({
    String? source,
    String? type,
    String? title,
    String? en_title,
    String? year,
    String? title_year,
    @JsonKey(fromJson: _intFromJson) int? season,
    @JsonKey(fromJson: _intFromJson) int? tmdb_id,
    String? imdb_id,
    @JsonKey(fromJson: _intFromJson) int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) int? douban_id,
    @JsonKey(fromJson: _intFromJson) int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) int? collection_id,
    String? mediaid_prefix,
    String? media_id,
    String? original_language,
    String? original_title,
    String? release_date,
    String? backdrop_path,
    String? poster_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    String? overview,
    String? category,
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
  }) = _MediaDetail;

  factory MediaDetail.fromJson(Map<String, dynamic> json) =>
      _$MediaDetailFromJson(json);
}

@freezed
class SeasonEpisodes with _$SeasonEpisodes {
  const factory SeasonEpisodes({
    required int season,
    required List<int> episodes,
  }) = _SeasonEpisodes;

  factory SeasonEpisodes.fromJson(Map<String, dynamic> json) =>
      _$SeasonEpisodesFromJson(json);
}

@freezed
class SeasonInfo with _$SeasonInfo {
  const factory SeasonInfo({
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    String? poster_path,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
  }) = _SeasonInfo;

  factory SeasonInfo.fromJson(Map<String, dynamic> json) =>
      _$SeasonInfoFromJson(json);
}

@freezed
class Actor with _$Actor {
  const factory Actor({
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
  }) = _Actor;

  factory Actor.fromJson(Map<String, dynamic> json) =>
      _$ActorFromJson(_normalizeActorJson(json));
}

@freezed
class ActorImages with _$ActorImages {
  const factory ActorImages({ActorImage? large, ActorImage? normal}) =
      _ActorImages;

  factory ActorImages.fromJson(Map<String, dynamic> json) =>
      _actorImagesFromJson(json) ?? const ActorImages();
}

@freezed
class ActorImage with _$ActorImage {
  const factory ActorImage({String? url}) = _ActorImage;

  factory ActorImage.fromJson(Map<String, dynamic> json) =>
      _$ActorImageFromJson(json);
}

@freezed
class ActorAvatar with _$ActorAvatar {
  const factory ActorAvatar({String? large, String? normal}) = _ActorAvatar;

  factory ActorAvatar.fromJson(Map<String, dynamic> json) =>
      _$ActorAvatarFromJson(json);
}

@freezed
class Director with _$Director {
  const factory Director({
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
  }) = _Director;

  factory Director.fromJson(Map<String, dynamic> json) =>
      _$DirectorFromJson(json);
}

@freezed
class CreatedBy with _$CreatedBy {
  const factory CreatedBy({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? credit_id,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _intFromJson) int? gender,
    String? profile_path,
  }) = _CreatedBy;

  factory CreatedBy.fromJson(Map<String, dynamic> json) =>
      _$CreatedByFromJson(json);
}

@freezed
class Genre with _$Genre {
  const factory Genre({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}

@freezed
class Network with _$Network {
  const factory Network({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  }) = _Network;

  factory Network.fromJson(Map<String, dynamic> json) =>
      _$NetworkFromJson(json);
}

@freezed
class ProductionCompany with _$ProductionCompany {
  const factory ProductionCompany({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  }) = _ProductionCompany;

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      _$ProductionCompanyFromJson(json);
}

@freezed
class ProductionCountry with _$ProductionCountry {
  const factory ProductionCountry({String? iso_3166_1, String? name}) =
      _ProductionCountry;

  factory ProductionCountry.fromJson(Map<String, dynamic> json) =>
      _$ProductionCountryFromJson(json);
}

@freezed
class SpokenLanguage with _$SpokenLanguage {
  const factory SpokenLanguage({
    String? english_name,
    String? iso_639_1,
    String? name,
  }) = _SpokenLanguage;

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) =>
      _$SpokenLanguageFromJson(json);
}

@freezed
class ReleaseDate with _$ReleaseDate {
  const factory ReleaseDate({
    String? iso_3166_1,
    @JsonKey(fromJson: _stringFromJson) String? certification,
    @JsonKey(fromJson: _stringFromJson) String? release_date,
    @JsonKey(fromJson: _intFromJson) int? type,
    String? note,
  }) = _ReleaseDate;

  factory ReleaseDate.fromJson(Map<String, dynamic> json) =>
      _$ReleaseDateFromJson(json);
}

@freezed
class NextEpisodeToAir with _$NextEpisodeToAir {
  const factory NextEpisodeToAir({
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
  }) = _NextEpisodeToAir;

  factory NextEpisodeToAir.fromJson(Map<String, dynamic> json) =>
      _$NextEpisodeToAirFromJson(json);
}

@freezed
class EpisodeGroup with _$EpisodeGroup {
  const factory EpisodeGroup({
    String? description,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? group_count,
    String? id,
    String? name,
    @JsonKey(fromJson: _stringFromJson) String? network,
    @JsonKey(fromJson: _intFromJson) int? type,
  }) = _EpisodeGroup;

  factory EpisodeGroup.fromJson(Map<String, dynamic> json) =>
      _$EpisodeGroupFromJson(json);
}

int? _intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _stringFromJson(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

double? _doubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<int> _intListFromJson(Object? value) {
  if (value is List) {
    return value.map((item) => _intFromJson(item)).whereType<int>().toList();
  }
  return const [];
}

List<int>? _intListToJson(List<int>? value) => value;

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value
        .map((item) => _stringFromJson(item))
        .whereType<String>()
        .toList();
  }
  return const [];
}

List<String>? _stringListToJson(List<String>? value) => value;

List<SeasonEpisodes> _seasonsFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    final items = <SeasonEpisodes>[];
    value.forEach((key, rawEpisodes) {
      final season = _intFromJson(key) ?? int.tryParse(key) ?? 0;
      final episodes = _intListFromJson(rawEpisodes);
      items.add(SeasonEpisodes(season: season, episodes: episodes));
    });
    items.sort((a, b) => a.season.compareTo(b.season));
    return items;
  }
  return const [];
}

Map<String, dynamic> _seasonsToJson(List<SeasonEpisodes>? seasons) {
  final result = <String, dynamic>{};
  if (seasons == null) return result;
  for (final item in seasons) {
    result[item.season.toString()] = item.episodes;
  }
  return result;
}

NextEpisodeToAir? _nextEpisodeFromJson(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) return null;
    return NextEpisodeToAir.fromJson(value);
  }
  return null;
}

Map<String, dynamic>? _nextEpisodeToJson(NextEpisodeToAir? value) =>
    value?.toJson();

ActorAvatar? _actorAvatarFromJson(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) {
    return ActorAvatar.fromJson(value);
  }
  if (value is Map) {
    return ActorAvatar.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

Map<String, dynamic>? _actorAvatarToJson(ActorAvatar? value) => value?.toJson();

ActorImages? _actorImagesFromJson(Object? value) {
  if (value == null) return null;
  if (value is! Map) return null;
  final map = value is Map<String, dynamic>
      ? value
      : Map<String, dynamic>.from(value);

  ActorImage? parseImage(Object? raw) {
    if (raw == null) return null;
    if (raw is String) {
      final url = raw.trim();
      return url.isEmpty ? null : ActorImage(url: url);
    }
    if (raw is Map) {
      final nested = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
      final url = nested['url']?.toString().trim();
      if (url == null || url.isEmpty) return null;
      return ActorImage(url: url);
    }
    return null;
  }

  return ActorImages(
    large: parseImage(map['large']),
    normal: parseImage(
      map['normal'] ?? map['medium'] ?? map['small'] ?? map['grid'],
    ),
  );
}

Map<String, dynamic>? _actorImagesToJson(ActorImages? value) {
  if (value == null) return null;
  return {
    'large': value.large?.toJson(),
    'normal': value.normal?.toJson(),
  };
}

Map<String, dynamic> _normalizeActorJson(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  if ((map['character'] == null || map['character'].toString().isEmpty) &&
      map['career'] is List) {
    final career = (map['career'] as List)
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    if (career.isNotEmpty) {
      map['character'] = career.first;
    }
  }
  if ((map['profile_path'] == null ||
          map['profile_path'].toString().trim().isEmpty) &&
      map['images'] is Map) {
    final images = Map<String, dynamic>.from(map['images'] as Map);
    final raw =
        images['large'] ?? images['medium'] ?? images['small'] ?? images['grid'];
    if (raw is String && raw.trim().isNotEmpty) {
      map['profile_path'] = raw.trim();
    } else if (raw is Map) {
      final url = raw['url']?.toString().trim();
      if (url != null && url.isNotEmpty) {
        map['profile_path'] = url;
      }
    }
  }
  return map;
}
