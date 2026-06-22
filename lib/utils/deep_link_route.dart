class DeepLinkTarget {
  const DeepLinkTarget({required this.route, this.parameters = const {}});

  final String route;
  final Map<String, String> parameters;
}

DeepLinkTarget? parseDeepLinkTarget(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.host == 'subscribe-calendar') {
    return const DeepLinkTarget(route: '/subscribe-calendar');
  }
  if (uri.path == '/subscribe-calendar') {
    return const DeepLinkTarget(route: '/subscribe-calendar');
  }
  if (uri.host == 'media-detail' || uri.path == '/media-detail') {
    final path = (uri.queryParameters['path'] ?? '').trim();
    if (path.isEmpty) return null;
    final title = (uri.queryParameters['title'] ?? '').trim();
    final year = (uri.queryParameters['year'] ?? '').trim();
    final typeName = (uri.queryParameters['type_name'] ?? '').trim();
    final params = <String, String>{'path': path};
    if (title.isNotEmpty) params['title'] = title;
    if (year.isNotEmpty) params['year'] = year;
    if (typeName.isNotEmpty) params['type_name'] = typeName;
    return DeepLinkTarget(route: '/media-detail', parameters: params);
  }
  if (uri.host == 'recommend-widget' || uri.path == '/recommend-widget') {
    final key = (uri.queryParameters['key'] ?? 'tmdb_trending').trim();
    final title = (uri.queryParameters['title'] ?? '流行趋势').trim();
    return DeepLinkTarget(
      route: '/recommend-category-list',
      parameters: {
        'key': key.isEmpty ? 'tmdb_trending' : key,
        'title': title.isEmpty ? '流行趋势' : title,
      },
    );
  }
  if (uri.host == 'site-overview' || uri.path == '/site-overview') {
    return const DeepLinkTarget(route: '/site');
  }
  if (uri.host == 'system-message' || uri.path == '/system-message') {
    return const DeepLinkTarget(route: '/system-message');
  }
  return null;
}
