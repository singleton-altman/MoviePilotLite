// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognize_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecognizeResponseImpl _$$RecognizeResponseImplFromJson(
  Map<String, dynamic> json,
) => _$RecognizeResponseImpl(
  meta_info: json['meta_info'] == null
      ? null
      : MetaInfo.fromJson(json['meta_info'] as Map<String, dynamic>),
  media_info: json['media_info'] == null
      ? null
      : MediaInfo.fromJson(json['media_info'] as Map<String, dynamic>),
  torrent_info: json['torrent_info'] == null
      ? null
      : TorrentInfo.fromJson(json['torrent_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$RecognizeResponseImplToJson(
  _$RecognizeResponseImpl instance,
) => <String, dynamic>{
  'meta_info': instance.meta_info,
  'media_info': instance.media_info,
  'torrent_info': instance.torrent_info,
};

_$MetaInfoImpl _$$MetaInfoImplFromJson(Map<String, dynamic> json) =>
    _$MetaInfoImpl(
      isfile: _boolFromJson(json['isfile']),
      org_string: _stringFromJson(json['org_string']),
      title: _stringFromJson(json['title']),
      subtitle: _stringFromJson(json['subtitle']),
      type: _stringFromJson(json['type']),
      name: _stringFromJson(json['name']),
      cn_name: _stringFromJson(json['cn_name']),
      en_name: _stringFromJson(json['en_name']),
      year: _stringFromJson(json['year']),
      total_season: _intFromJson(json['total_season']),
      begin_season: _intFromJson(json['begin_season']),
      end_season: _intFromJson(json['end_season']),
      total_episode: _intFromJson(json['total_episode']),
      begin_episode: _intFromJson(json['begin_episode']),
      end_episode: _intFromJson(json['end_episode']),
      season_episode: _stringFromJson(json['season_episode']),
      episode_list: _intListFromJson(json['episode_list']),
      part: _stringFromJson(json['part']),
      resource_type: _stringFromJson(json['resource_type']),
      resource_effect: _stringFromJson(json['resource_effect']),
      resource_pix: _stringFromJson(json['resource_pix']),
      resource_team: _stringFromJson(json['resource_team']),
      video_encode: _stringFromJson(json['video_encode']),
      audio_encode: _stringFromJson(json['audio_encode']),
      edition: _stringFromJson(json['edition']),
      web_source: _stringFromJson(json['web_source']),
      apply_words: _stringListFromJson(json['apply_words']),
    );

Map<String, dynamic> _$$MetaInfoImplToJson(_$MetaInfoImpl instance) =>
    <String, dynamic>{
      'isfile': instance.isfile,
      'org_string': instance.org_string,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'type': instance.type,
      'name': instance.name,
      'cn_name': instance.cn_name,
      'en_name': instance.en_name,
      'year': instance.year,
      'total_season': instance.total_season,
      'begin_season': instance.begin_season,
      'end_season': instance.end_season,
      'total_episode': instance.total_episode,
      'begin_episode': instance.begin_episode,
      'end_episode': instance.end_episode,
      'season_episode': instance.season_episode,
      'episode_list': _intListToJson(instance.episode_list),
      'part': instance.part,
      'resource_type': instance.resource_type,
      'resource_effect': instance.resource_effect,
      'resource_pix': instance.resource_pix,
      'resource_team': instance.resource_team,
      'video_encode': instance.video_encode,
      'audio_encode': instance.audio_encode,
      'edition': instance.edition,
      'web_source': instance.web_source,
      'apply_words': _stringListToJson(instance.apply_words),
    };

_$MediaInfoImpl _$$MediaInfoImplFromJson(Map<String, dynamic> json) =>
    _$MediaInfoImpl(
      source: _stringFromJson(json['source']),
      type: _stringFromJson(json['type']),
      title: _stringFromJson(json['title']),
      en_title: _stringFromJson(json['en_title']),
      year: _stringFromJson(json['year']),
      title_year: _stringFromJson(json['title_year']),
      season: _intFromJson(json['season']),
      tmdb_id: _intFromJson(json['tmdb_id']),
      imdb_id: _stringFromJson(json['imdb_id']),
      tvdb_id: _intFromJson(json['tvdb_id']),
      douban_id: _intFromJson(json['douban_id']),
      bangumi_id: _intFromJson(json['bangumi_id']),
      collection_id: _intFromJson(json['collection_id']),
      mediaid_prefix: _stringFromJson(json['mediaid_prefix']),
      media_id: _stringFromJson(json['media_id']),
      original_language: _stringFromJson(json['original_language']),
      original_title: _stringFromJson(json['original_title']),
      release_date: _stringFromJson(json['release_date']),
      backdrop_path: _stringFromJson(json['backdrop_path']),
      poster_path: _stringFromJson(json['poster_path']),
      vote_average: _doubleFromJson(json['vote_average']),
      overview: _stringFromJson(json['overview']),
      category: _stringFromJson(json['category']),
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
      detail_link: _stringFromJson(json['detail_link']),
      adult: _boolFromJson(json['adult']),
      created_by: (json['created_by'] as List<dynamic>?)
          ?.map((e) => CreatedBy.fromJson(e as Map<String, dynamic>))
          .toList(),
      episode_run_time: _intListFromJson(json['episode_run_time']),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      first_air_date: _stringFromJson(json['first_air_date']),
      homepage: _stringFromJson(json['homepage']),
      languages: _stringListFromJson(json['languages']),
      last_air_date: _stringFromJson(json['last_air_date']),
      networks: (json['networks'] as List<dynamic>?)
          ?.map((e) => Network.fromJson(e as Map<String, dynamic>))
          .toList(),
      number_of_episodes: _intFromJson(json['number_of_episodes']),
      number_of_seasons: _intFromJson(json['number_of_seasons']),
      origin_country: _stringListFromJson(json['origin_country']),
      original_name: _stringFromJson(json['original_name']),
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
      status: _stringFromJson(json['status']),
      tagline: _stringFromJson(json['tagline']),
      genre_ids: _intListFromJson(json['genre_ids']),
      vote_count: _intFromJson(json['vote_count']),
      popularity: _doubleFromJson(json['popularity']),
      runtime: _intFromJson(json['runtime']),
      next_episode_to_air: _nextEpisodeFromJson(json['next_episode_to_air']),
      episode_groups: _episodeGroupsFromJson(json['episode_groups']),
      episode_group: _episodeGroupFromJson(json['episode_group']),
    );

Map<String, dynamic> _$$MediaInfoImplToJson(_$MediaInfoImpl instance) =>
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
      'episode_groups': _episodeGroupsToJson(instance.episode_groups),
      'episode_group': _episodeGroupToJson(instance.episode_group),
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
      air_date: _stringFromJson(json['air_date']),
      episode_count: _intFromJson(json['episode_count']),
      id: _intFromJson(json['id']),
      name: _stringFromJson(json['name']),
      overview: _stringFromJson(json['overview']),
      poster_path: _stringFromJson(json['poster_path']),
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
  source: _stringFromJson(json['source']),
  adult: _boolFromJson(json['adult']),
  gender: _intFromJson(json['gender']),
  id: _intFromJson(json['id']),
  known_for_department: _stringFromJson(json['known_for_department']),
  name: _stringFromJson(json['name']),
  original_name: _stringFromJson(json['original_name']),
  popularity: _doubleFromJson(json['popularity']),
  profile_path: _stringFromJson(json['profile_path']),
  character: _stringFromJson(json['character']),
  credit_id: _stringFromJson(json['credit_id']),
  order: _intFromJson(json['order']),
);

Map<String, dynamic> _$$ActorImplToJson(_$ActorImpl instance) =>
    <String, dynamic>{
      'source': instance.source,
      'adult': instance.adult,
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
    };

_$DirectorImpl _$$DirectorImplFromJson(Map<String, dynamic> json) =>
    _$DirectorImpl(
      adult: _boolFromJson(json['adult']),
      gender: _intFromJson(json['gender']),
      id: _intFromJson(json['id']),
      name: _stringFromJson(json['name']),
      original_name: _stringFromJson(json['original_name']),
      credit_id: _stringFromJson(json['credit_id']),
      known_for_department: _stringFromJson(json['known_for_department']),
      job: _stringFromJson(json['job']),
      popularity: _doubleFromJson(json['popularity']),
      profile_path: _stringFromJson(json['profile_path']),
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
      credit_id: _stringFromJson(json['credit_id']),
      name: _stringFromJson(json['name']),
      original_name: _stringFromJson(json['original_name']),
      gender: _intFromJson(json['gender']),
      profile_path: _stringFromJson(json['profile_path']),
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

_$GenreImpl _$$GenreImplFromJson(Map<String, dynamic> json) => _$GenreImpl(
  id: _intFromJson(json['id']),
  name: _stringFromJson(json['name']),
);

Map<String, dynamic> _$$GenreImplToJson(_$GenreImpl instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_$NetworkImpl _$$NetworkImplFromJson(Map<String, dynamic> json) =>
    _$NetworkImpl(
      id: _intFromJson(json['id']),
      logo_path: _stringFromJson(json['logo_path']),
      name: _stringFromJson(json['name']),
      origin_country: _stringFromJson(json['origin_country']),
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
  logo_path: _stringFromJson(json['logo_path']),
  name: _stringFromJson(json['name']),
  origin_country: _stringFromJson(json['origin_country']),
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
  iso_3166_1: _stringFromJson(json['iso_3166_1']),
  name: _stringFromJson(json['name']),
);

Map<String, dynamic> _$$ProductionCountryImplToJson(
  _$ProductionCountryImpl instance,
) => <String, dynamic>{
  'iso_3166_1': instance.iso_3166_1,
  'name': instance.name,
};

_$SpokenLanguageImpl _$$SpokenLanguageImplFromJson(Map<String, dynamic> json) =>
    _$SpokenLanguageImpl(
      english_name: _stringFromJson(json['english_name']),
      iso_639_1: _stringFromJson(json['iso_639_1']),
      name: _stringFromJson(json['name']),
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
      certification: _stringFromJson(json['certification']),
      iso_3166_1: _stringFromJson(json['iso_3166_1']),
      release_date: _stringFromJson(json['release_date']),
      note: _stringFromJson(json['note']),
      type: _intFromJson(json['type']),
    );

Map<String, dynamic> _$$ReleaseDateImplToJson(_$ReleaseDateImpl instance) =>
    <String, dynamic>{
      'certification': instance.certification,
      'iso_3166_1': instance.iso_3166_1,
      'release_date': instance.release_date,
      'note': instance.note,
      'type': instance.type,
    };

_$EpisodeGroupImpl _$$EpisodeGroupImplFromJson(Map<String, dynamic> json) =>
    _$EpisodeGroupImpl(
      id: _stringFromJson(json['id']),
      name: _stringFromJson(json['name']),
      description: _stringFromJson(json['description']),
      episode_count: _intFromJson(json['episode_count']),
      group_count: _intFromJson(json['group_count']),
      type: _stringFromJson(json['type']),
      network: _networkFromJson(json['network']),
    );

Map<String, dynamic> _$$EpisodeGroupImplToJson(_$EpisodeGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'episode_count': instance.episode_count,
      'group_count': instance.group_count,
      'type': instance.type,
      'network': _networkToJson(instance.network),
    };

_$NextEpisodeToAirImpl _$$NextEpisodeToAirImplFromJson(
  Map<String, dynamic> json,
) => _$NextEpisodeToAirImpl(
  air_date: _stringFromJson(json['air_date']),
  episode_number: _intFromJson(json['episode_number']),
  id: _intFromJson(json['id']),
  name: _stringFromJson(json['name']),
  overview: _stringFromJson(json['overview']),
  production_code: _stringFromJson(json['production_code']),
  season_number: _intFromJson(json['season_number']),
  still_path: _stringFromJson(json['still_path']),
  vote_average: _doubleFromJson(json['vote_average']),
  vote_count: _intFromJson(json['vote_count']),
  runtime: _intFromJson(json['runtime']),
);

Map<String, dynamic> _$$NextEpisodeToAirImplToJson(
  _$NextEpisodeToAirImpl instance,
) => <String, dynamic>{
  'air_date': instance.air_date,
  'episode_number': instance.episode_number,
  'id': instance.id,
  'name': instance.name,
  'overview': instance.overview,
  'production_code': instance.production_code,
  'season_number': instance.season_number,
  'still_path': instance.still_path,
  'vote_average': instance.vote_average,
  'vote_count': instance.vote_count,
  'runtime': instance.runtime,
};

_$TorrentInfoImpl _$$TorrentInfoImplFromJson(Map<String, dynamic> json) =>
    _$TorrentInfoImpl();

Map<String, dynamic> _$$TorrentInfoImplToJson(_$TorrentInfoImpl instance) =>
    <String, dynamic>{};
