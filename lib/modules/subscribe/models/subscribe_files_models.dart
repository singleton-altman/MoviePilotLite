import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';

class SubscribeFilesResult {
  const SubscribeFilesResult({
    required this.subscribe,
    required this.episodes,
  });

  final SubscribeItem? subscribe;
  final List<SubscribeEpisodeFiles> episodes;

  factory SubscribeFilesResult.fromJson(Map<String, dynamic> json) {
    final subscribeRaw = json['subscribe'];
    SubscribeItem? subscribe;
    if (subscribeRaw is Map) {
      subscribe = SubscribeItem.fromJson(
        normalizeSubscribeJson(Map<String, dynamic>.from(subscribeRaw)),
      );
    }

    final episodesRaw = json['episodes'];
    final episodes = <SubscribeEpisodeFiles>[];
    if (episodesRaw is Map) {
      final entries = episodesRaw.entries.toList()
        ..sort((a, b) {
          final ai = int.tryParse(a.key.toString()) ?? 0;
          final bi = int.tryParse(b.key.toString()) ?? 0;
          return ai.compareTo(bi);
        });
      for (final entry in entries) {
        final value = entry.value;
        if (value is! Map) continue;
        episodes.add(
          SubscribeEpisodeFiles.fromJson(
            episodeKey: entry.key.toString(),
            json: Map<String, dynamic>.from(value),
          ),
        );
      }
    }
    return SubscribeFilesResult(subscribe: subscribe, episodes: episodes);
  }
}

class SubscribeEpisodeFiles {
  const SubscribeEpisodeFiles({
    required this.episodeKey,
    this.title,
    this.description,
    this.backdrop,
    this.downloads = const [],
    this.libraries = const [],
  });

  final String episodeKey;
  final String? title;
  final String? description;
  final String? backdrop;
  final List<SubscribeDownloadFile> downloads;
  final List<SubscribeLibraryFile> libraries;

  factory SubscribeEpisodeFiles.fromJson({
    required String episodeKey,
    required Map<String, dynamic> json,
  }) {
    final downloads = <SubscribeDownloadFile>[];
    final downloadRaw = json['download'];
    if (downloadRaw is List) {
      for (final item in downloadRaw) {
        if (item is Map) {
          downloads.add(
            SubscribeDownloadFile.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final libraries = <SubscribeLibraryFile>[];
    final libraryRaw = json['library'];
    if (libraryRaw is List) {
      for (final item in libraryRaw) {
        if (item is Map) {
          libraries.add(
            SubscribeLibraryFile.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return SubscribeEpisodeFiles(
      episodeKey: episodeKey,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      backdrop: json['backdrop']?.toString(),
      downloads: downloads,
      libraries: libraries,
    );
  }

  int get fileCount => downloads.length + libraries.length;
}

class SubscribeDownloadFile {
  const SubscribeDownloadFile({
    this.torrentTitle,
    this.siteName,
    this.downloader,
    this.hash,
    this.filePath,
  });

  final String? torrentTitle;
  final String? siteName;
  final String? downloader;
  final String? hash;
  final String? filePath;

  factory SubscribeDownloadFile.fromJson(Map<String, dynamic> json) {
    return SubscribeDownloadFile(
      torrentTitle: json['torrent_title']?.toString(),
      siteName: json['site_name']?.toString(),
      downloader: json['downloader']?.toString(),
      hash: json['hash']?.toString(),
      filePath: json['file_path']?.toString(),
    );
  }
}

class SubscribeLibraryFile {
  const SubscribeLibraryFile({
    this.storage,
    this.filePath,
    this.server,
    this.serverType,
    this.itemid,
  });

  final String? storage;
  final String? filePath;
  final String? server;
  final String? serverType;
  final String? itemid;

  factory SubscribeLibraryFile.fromJson(Map<String, dynamic> json) {
    return SubscribeLibraryFile(
      storage: json['storage']?.toString(),
      filePath: json['file_path']?.toString(),
      server: json['server']?.toString(),
      serverType: json['server_type']?.toString(),
      itemid: json['itemid']?.toString(),
    );
  }
}
