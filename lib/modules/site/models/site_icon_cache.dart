/// Site icon base64 cache keyed by site URL.
class SiteIconCache {
  final String url;
  final String iconBase64;

  const SiteIconCache({
    required this.url,
    required this.iconBase64,
  });
}
