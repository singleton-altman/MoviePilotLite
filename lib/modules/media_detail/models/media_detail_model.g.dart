// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaDetailImpl _$$MediaDetailImplFromJson(Map<String, dynamic> json) =>
    _$MediaDetailImpl(
      source: json['source'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      en_title: json['en_title'] as String?,
      year: json['year'] as String?,
      title_year: json['title_year'] as String?,
      season: _intFromJson(json['season']),
      tmdb_id: _intFromJson(json['tmdb_id']),
      imdb_id: json['imdb_id'] as String?,
      tvdb_id: _intFromJson(json['tvdb_id']),
      douban_id: _intFromJson(json['douban_id']),
      bangumi_id: _intFromJson(json['bangumi_id']),
      collection_id: _intFromJson(json['collection_id']),
      mediaid_prefix: json['mediaid_prefix'] as String?,
      media_id: json['media_id'] as String?,
      original_language: json['original_language'] as String?,
      original_title: json['original_title'] as String?,
      release_date: json['release_date'] as String?,
      backdrop_path: json['backdrop_path'] as String?,
      poster_path: json['poster_path'] as String?,
      vote_average: _doubleFromJson(json['vote_average']),
      overview: json['overview'] as String?,
      category: json['category'] as String?,
      seasons: _seasonsFromJson(json['seasons']),
      season_info: (json['season_info'] as List<dynamic>?)
          ?.map((e) => SeasonInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      names: _stringListFromJson(json['names']),
      actors: (json['actors'] as List<dynamic>?)
          ?.map((e) => Actor.fromJson(e as Map<String, dynamic>))
          .toList(),
      directors: (json['directors'] as List<dynamic>?)
          ?.map((e) => Director.fromJson(e as Map<String, dynamic>))
          .toList(),
      detail_link: json['detail_link'] as String?,
      adult: json['adult'] as bool?,
      created_by: (json['created_by'] as List<dynamic>?)
          ?.map((e) => CreatedBy.fromJson(e as Map<String, dynamic>))
          .toList(),
      episode_run_time: _intListFromJson(json['episode_run_time']),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      first_air_date: json['first_air_date'] as String?,
      homepage: json['homepage'] as String?,
      languages: _stringListFromJson(json['languages']),
      last_air_date: json['last_air_date'] as String?,
      networks: (json['networks'] as List<dynamic>?)
          ?.map((e) => Network.fromJson(e as Map<String, dynamic>))
          .toList(),
      number_of_episodes: _intFromJson(json['number_of_episodes']),
      number_of_seasons: _intFromJson(json['number_of_seasons']),
      origin_country: _stringListFromJson(json['origin_country']),
      original_name: json['original_name'] as String?,
      production_companies: (json['production_companies'] as List<dynamic>?)
          ?.map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList(),
      production_countries: (json['production_countries'] as List<dynamic>?)
          ?.map((e) => ProductionCountry.fromJson(e as Map<String, dynamic>))
          .toList(),
      spoken_languages: (json['spoken_languages'] as List<dynamic>?)
          ?.map((e) => SpokenLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      release_dates: (json['release_dates'] as List<dynamic>?)
          ?.map((e) => ReleaseDate.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      tagline: json['tagline'] as String?,
      genre_ids: _intListFromJson(json['genre_ids']),
      vote_count: _intFromJson(json['vote_count']),
      popularity: _doubleFromJson(json['popularity']),
      runtime: _intFromJson(json['runtime']),
      next_episode_to_air: _nextEpisodeFromJson(json['next_episode_to_air']),
      episode_groups: (json['episode_groups'] as List<dynamic>?)
          ?.map((e) => EpisodeGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      episode_group: json['episode_group'] == null
          ? null
          : EpisodeGroup.fromJson(
              json['episode_group'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$$MediaDetailImplToJson(_$MediaDetailImpl instance) =>
    <String, dynamic>{
      'source': instance.source,
      'type': instance.type,
      'title': instance.title,
      'en_title': instance.en_title,
      'year': instance.year,
      'title_year': instance.title_year,
      'season': instance.season,
      'tmdb_id': instance.tmdb_id,
      'imdb_id': instance.imdb_id,
      'tvdb_id': instance.tvdb_id,
      'douban_id': instance.douban_id,
      'bangumi_id': instance.bangumi_id,
      'collection_id': instance.collection_id,
      'mediaid_prefix': instance.mediaid_prefix,
      'media_id': instance.media_id,
      'original_language': instance.original_language,
      'original_title': instance.original_title,
      'release_date': instance.release_date,
      'backdrop_path': instance.backdrop_path,
      'poster_path': instance.poster_path,
      'vote_average': instance.vote_average,
      'overview': instance.overview,
      'category': instance.category,
      'seasons': _seasonsToJson(instance.seasons),
      'season_info': instance.season_info,
      'names': _stringListToJson(instance.names),
      'actors': instance.actors,
      'directors': instance.directors,
      'detail_link': instance.detail_link,
      'adult': instance.adult,
      'created_by': instance.created_by,
      'episode_run_time': _intListToJson(instance.episode_run_time),
      'genres': instance.genres,
      'first_air_date': instance.first_air_date,
      'homepage': instance.homepage,
      'languages': _stringListToJson(instance.languages),
      'last_air_date': instance.last_air_date,
      'networks': instance.networks,
      'number_of_episodes': instance.number_of_episodes,
      'number_of_seasons': instance.number_of_seasons,
      'origin_country': _stringListToJson(instance.origin_country),
      'original_name': instance.original_name,
      'production_companies': instance.production_companies,
      'production_countries': instance.production_countries,
      'spoken_languages': instance.spoken_languages,
      'release_dates': instance.release_dates,
      'status': instance.status,
      'tagline': instance.tagline,
      'genre_ids': _intListToJson(instance.genre_ids),
      'vote_count': instance.vote_count,
      'popularity': instance.popularity,
      'runtime': instance.runtime,
      'next_episode_to_air': _nextEpisodeToJson(instance.next_episode_to_air),
      'episode_groups': instance.episode_groups,
      'episode_group': instance.episode_group,
    };

_$SeasonEpisodesImpl _$$SeasonEpisodesImplFromJson(Map<String, dynamic> json) =>
    _$SeasonEpisodesImpl(
      season: (json['season'] as num).toInt(),
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$SeasonEpisodesImplToJson(
  _$SeasonEpisodesImpl instance,
) => <String, dynamic>{
  'season': instance.season,
  'episodes': instance.episodes,
};

_$SeasonInfoImpl _$$SeasonInfoImplFromJson(Map<String, dynamic> json) =>
    _$SeasonInfoImpl(
      air_date: json['air_date'] as String?,
      episode_count: _intFromJson(json['episode_count']),
      id: _intFromJson(json['id']),
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      poster_path: json['poster_path'] as String?,
      season_number: _intFromJson(json['season_number']),
      vote_average: _doubleFromJson(json['vote_average']),
    );

Map<String, dynamic> _$$SeasonInfoImplToJson(_$SeasonInfoImpl instance) =>
    <String, dynamic>{
      'air_date': instance.air_date,
      'episode_count': instance.episode_count,
      'id': instance.id,
      'name': instance.name,
      'overview': instance.overview,
      'poster_path': instance.poster_path,
      'season_number': instance.season_number,
      'vote_average': instance.vote_average,
    };

_$ActorImpl _$$ActorImplFromJson(Map<String, dynamic> json) => _$ActorImpl(
  adult: json['adult'] as bool?,
  source: json['source'] as String?,
  gender: _intFromJson(json['gender']),
  id: _intFromJson(json['id']),
  known_for_department: json['known_for_department'] as String?,
  name: json['name'] as String?,
  original_name: json['original_name'] as String?,
  popularity: _doubleFromJson(json['popularity']),
  profile_path: json['profile_path'] as String?,
  character: json['character'] as String?,
  credit_id: json['credit_id'] as String?,
  order: _intFromJson(json['order']),
  avatar: _actorAvatarFromJson(json['avatar']),
  images: _actorImagesFromJson(json['images']),
  sharing_url: json['sharing_url'] as String?,
);

Map<String, dynamic> _$$ActorImplToJson(_$ActorImpl instance) =>
    <String, dynamic>{
      'adult': instance.adult,
      'source': instance.source,
      'gender': instance.gender,
      'id': instance.id,
      'known_for_department': instance.known_for_department,
      'name': instance.name,
      'original_name': instance.original_name,
      'popularity': instance.popularity,
      'profile_path': instance.profile_path,
      'character': instance.character,
      'credit_id': instance.credit_id,
      'order': instance.order,
      'avatar': _actorAvatarToJson(instance.avatar),
      'images': _actorImagesToJson(instance.images),
      'sharing_url': instance.sharing_url,
    };

_$ActorImagesImpl _$$ActorImagesImplFromJson(Map<String, dynamic> json) {
  final parsed = _actorImagesFromJson(json);
  return _$ActorImagesImpl(large: parsed?.large, normal: parsed?.normal);
}

Map<String, dynamic> _$$ActorImagesImplToJson(_$ActorImagesImpl instance) =>
    <String, dynamic>{'large': instance.large, 'normal': instance.normal};

_$ActorImageImpl _$$ActorImageImplFromJson(Map<String, dynamic> json) =>
    _$ActorImageImpl(url: json['url'] as String?);

Map<String, dynamic> _$$ActorImageImplToJson(_$ActorImageImpl instance) =>
    <String, dynamic>{'url': instance.url};

_$ActorAvatarImpl _$$ActorAvatarImplFromJson(Map<String, dynamic> json) =>
    _$ActorAvatarImpl(
      large: json['large'] as String?,
      normal: json['normal'] as String?,
    );

Map<String, dynamic> _$$ActorAvatarImplToJson(_$ActorAvatarImpl instance) =>
    <String, dynamic>{'large': instance.large, 'normal': instance.normal};

_$DirectorImpl _$$DirectorImplFromJson(Map<String, dynamic> json) =>
    _$DirectorImpl(
      adult: json['adult'] as bool?,
      gender: _intFromJson(json['gender']),
      id: _intFromJson(json['id']),
      name: json['name'] as String?,
      original_name: json['original_name'] as String?,
      credit_id: json['credit_id'] as String?,
      known_for_department: json['known_for_department'] as String?,
      job: json['job'] as String?,
      popularity: _doubleFromJson(json['popularity']),
      profile_path: json['profile_path'] as String?,
    );

Map<String, dynamic> _$$DirectorImplToJson(_$DirectorImpl instance) =>
    <String, dynamic>{
      'adult': instance.adult,
      'gender': instance.gender,
      'id': instance.id,
      'name': instance.name,
      'original_name': instance.original_name,
      'credit_id': instance.credit_id,
      'known_for_department': instance.known_for_department,
      'job': instance.job,
      'popularity': instance.popularity,
      'profile_path': instance.profile_path,
    };

_$CreatedByImpl _$$CreatedByImplFromJson(Map<String, dynamic> json) =>
    _$CreatedByImpl(
      id: _intFromJson(json['id']),
      credit_id: json['credit_id'] as String?,
      name: json['name'] as String?,
      original_name: json['original_name'] as String?,
      gender: _intFromJson(json['gender']),
      profile_path: json['profile_path'] as String?,
    );

Map<String, dynamic> _$$CreatedByImplToJson(_$CreatedByImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'credit_id': instance.credit_id,
      'name': instance.name,
      'original_name': instance.original_name,
      'gender': instance.gender,
      'profile_path': instance.profile_path,
    };

_$GenreImpl _$$GenreImplFromJson(Map<String, dynamic> json) =>
    _$GenreImpl(id: _intFromJson(json['id']), name: json['name'] as String?);

Map<String, dynamic> _$$GenreImplToJson(_$GenreImpl instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_$NetworkImpl _$$NetworkImplFromJson(Map<String, dynamic> json) =>
    _$NetworkImpl(
      id: _intFromJson(json['id']),
      logo_path: json['logo_path'] as String?,
      name: json['name'] as String?,
      origin_country: json['origin_country'] as String?,
    );

Map<String, dynamic> _$$NetworkImplToJson(_$NetworkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'logo_path': instance.logo_path,
      'name': instance.name,
      'origin_country': instance.origin_country,
    };

_$ProductionCompanyImpl _$$ProductionCompanyImplFromJson(
  Map<String, dynamic> json,
) => _$ProductionCompanyImpl(
  id: _intFromJson(json['id']),
  logo_path: json['logo_path'] as String?,
  name: json['name'] as String?,
  origin_country: json['origin_country'] as String?,
);

Map<String, dynamic> _$$ProductionCompanyImplToJson(
  _$ProductionCompanyImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'logo_path': instance.logo_path,
  'name': instance.name,
  'origin_country': instance.origin_country,
};

_$ProductionCountryImpl _$$ProductionCountryImplFromJson(
  Map<String, dynamic> json,
) => _$ProductionCountryImpl(
  iso_3166_1: json['iso_3166_1'] as String?,
  name: json['name'] as String?,
);

Map<String, dynamic> _$$ProductionCountryImplToJson(
  _$ProductionCountryImpl instance,
) => <String, dynamic>{
  'iso_3166_1': instance.iso_3166_1,
  'name': instance.name,
};

_$SpokenLanguageImpl _$$SpokenLanguageImplFromJson(Map<String, dynamic> json) =>
    _$SpokenLanguageImpl(
      english_name: json['english_name'] as String?,
      iso_639_1: json['iso_639_1'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$SpokenLanguageImplToJson(
  _$SpokenLanguageImpl instance,
) => <String, dynamic>{
  'english_name': instance.english_name,
  'iso_639_1': instance.iso_639_1,
  'name': instance.name,
};

_$ReleaseDateImpl _$$ReleaseDateImplFromJson(Map<String, dynamic> json) =>
    _$ReleaseDateImpl(
      iso_3166_1: json['iso_3166_1'] as String?,
      certification: _stringFromJson(json['certification']),
      release_date: _stringFromJson(json['release_date']),
      type: _intFromJson(json['type']),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ReleaseDateImplToJson(_$ReleaseDateImpl instance) =>
    <String, dynamic>{
      'iso_3166_1': instance.iso_3166_1,
      'certification': instance.certification,
      'release_date': instance.release_date,
      'type': instance.type,
      'note': instance.note,
    };

_$NextEpisodeToAirImpl _$$NextEpisodeToAirImplFromJson(
  Map<String, dynamic> json,
) => _$NextEpisodeToAirImpl(
  id: _intFromJson(json['id']),
  name: json['name'] as String?,
  overview: json['overview'] as String?,
  vote_average: _doubleFromJson(json['vote_average']),
  vote_count: _intFromJson(json['vote_count']),
  air_date: json['air_date'] as String?,
  episode_number: _intFromJson(json['episode_number']),
  episode_type: json['episode_type'] as String?,
  production_code: json['production_code'] as String?,
  runtime: _intFromJson(json['runtime']),
  season_number: _intFromJson(json['season_number']),
  show_id: _intFromJson(json['show_id']),
  still_path: json['still_path'] as String?,
);

Map<String, dynamic> _$$NextEpisodeToAirImplToJson(
  _$NextEpisodeToAirImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'overview': instance.overview,
  'vote_average': instance.vote_average,
  'vote_count': instance.vote_count,
  'air_date': instance.air_date,
  'episode_number': instance.episode_number,
  'episode_type': instance.episode_type,
  'production_code': instance.production_code,
  'runtime': instance.runtime,
  'season_number': instance.season_number,
  'show_id': instance.show_id,
  'still_path': instance.still_path,
};

_$EpisodeGroupImpl _$$EpisodeGroupImplFromJson(Map<String, dynamic> json) =>
    _$EpisodeGroupImpl(
      description: json['description'] as String?,
      episode_count: _intFromJson(json['episode_count']),
      group_count: _intFromJson(json['group_count']),
      id: json['id'] as String?,
      name: json['name'] as String?,
      network: _stringFromJson(json['network']),
      type: _intFromJson(json['type']),
    );

Map<String, dynamic> _$$EpisodeGroupImplToJson(_$EpisodeGroupImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'episode_count': instance.episode_count,
      'group_count': instance.group_count,
      'id': instance.id,
      'name': instance.name,
      'network': instance.network,
      'type': instance.type,
    };
