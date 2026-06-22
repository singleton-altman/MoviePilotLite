import SwiftUI
import WidgetKit
import AppIntents
import os

private enum SharedSessionConfig {
  static let appGroup = "group.com.altman.moviepilot.shared"
  static let serverKey = "shared_server_url"
  static let tokenKey = "shared_access_token"
  static let siteWidgetPayloadKey = "shared_site_widget_payload"
}

private let widgetLog = Logger(subsystem: "com.altman.moviepilot", category: "widgets")
private let systemMessageWidgetURL = URL(string: "moviepilot://system-message")

private struct SharedSession {
  let server: String
  let accessToken: String
}

private struct SubscribeItemDTO: Decodable {
  let tmdbid: Int?
  let season: Int?
  let type: String?
  let name: String?
  let poster: String?

  private enum CodingKeys: String, CodingKey {
    case tmdbid
    case season
    case type
    case name
    case poster
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    tmdbid = Self.decodeInt(from: container, key: .tmdbid)
    season = Self.decodeInt(from: container, key: .season)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    poster = try container.decodeIfPresent(String.self, forKey: .poster)
  }

  private static func decodeInt(
    from container: KeyedDecodingContainer<CodingKeys>,
    key: CodingKeys
  ) -> Int? {
    if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
      return value
    }
    if let value = try? container.decodeIfPresent(String.self, forKey: key) {
      return Int(value)
    }
    return nil
  }
}

private struct TmdbEpisodeDTO: Decodable {
  let airDate: String?
  let episodeNumber: Int?
  let name: String?

  private enum CodingKeys: String, CodingKey {
    case airDate = "air_date"
    case episodeNumber = "episode_number"
    case name
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
    if let number = try? container.decodeIfPresent(Int.self, forKey: .episodeNumber) {
      episodeNumber = number
    } else if let number = try? container.decodeIfPresent(String.self, forKey: .episodeNumber) {
      episodeNumber = Int(number)
    } else {
      episodeNumber = nil
    }
    name = try container.decodeIfPresent(String.self, forKey: .name)
  }
}

struct EpisodeCard: Identifiable {
  let id: String
  let date: String
  let showName: String
  let seasonNumber: Int
  let episodeNumber: Int
  let episodeTitle: String
  let posterURL: URL?
  let posterData: Data?
}

struct SubscribeCalendarEntry: TimelineEntry {
  let date: Date
  let state: State

  enum State {
    case loaded([EpisodeCard])
    case empty(String)
    case failed(String)
  }
}

struct SubscribeCalendarProvider: TimelineProvider {
  func placeholder(in context: Context) -> SubscribeCalendarEntry {
    SubscribeCalendarEntry(
      date: Date(),
      state: .loaded([
        EpisodeCard(
          id: "placeholder-1",
          date: "2026-03-30",
          showName: "片名示例",
          seasonNumber: 1,
          episodeNumber: 3,
          episodeTitle: "新的线索出现",
          posterURL: URL(string: "https://image.tmdb.org/t/p/w300/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg"),
          posterData: nil
        ),
        EpisodeCard(
          id: "placeholder-2",
          date: "2026-03-31",
          showName: "片名示例 2",
          seasonNumber: 2,
          episodeNumber: 1,
          episodeTitle: "季首播",
          posterURL: URL(string: "https://image.tmdb.org/t/p/w300/qJxzjUjCpTPvDHldNnlbRC4OqEh.jpg"),
          posterData: nil
        ),
      ])
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SubscribeCalendarEntry) -> Void) {
    Task {
      completion(await Self.loadEntry())
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SubscribeCalendarEntry>) -> Void) {
    Task {
      let entry = await Self.loadEntry()
      let refreshDate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21600)
      completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
  }

  static func loadEntry() async -> SubscribeCalendarEntry {
    do {
      guard let session = SharedSessionStore.load() else {
        return SubscribeCalendarEntry(date: Date(), state: .empty("请先登录 MoviePilot"))
      }
      let items = try await SubscribeCalendarService(session: session).fetchUpcomingEpisodes()
      if items.isEmpty {
        return SubscribeCalendarEntry(date: Date(), state: .empty("今天之后暂无订阅更新"))
      }
      return SubscribeCalendarEntry(date: Date(), state: .loaded(items))
    } catch {
      return SubscribeCalendarEntry(date: Date(), state: .failed("订阅日历加载失败"))
    }
  }
}

private enum SharedSessionStore {
  static func load() -> SharedSession? {
    guard let defaults = UserDefaults(suiteName: SharedSessionConfig.appGroup) else {
      widgetLog.error("shared session load failed: missing app group defaults")
      return nil
    }
    guard
      let server = defaults.string(forKey: SharedSessionConfig.serverKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
      let accessToken = defaults.string(forKey: SharedSessionConfig.tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
      !server.isEmpty,
      !accessToken.isEmpty
    else {
      widgetLog.error("shared session load failed: server or token empty")
      return nil
    }
    widgetLog.info("shared session loaded, server=\(server, privacy: .public)")
    return SharedSession(server: server, accessToken: accessToken)
  }
}

private struct SubscribeCalendarService {
  let session: SharedSession

  func fetchUpcomingEpisodes() async throws -> [EpisodeCard] {
    let subscribes: [SubscribeItemDTO] = try await requestArray(path: "/api/v1/subscribe/")
    let tvSubscribes = subscribes.filter { subscribe in
      let value = (subscribe.type ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      return value == "tv" || value.contains("tv") || value.contains("电视剧")
    }

    var cards: [EpisodeCard] = []
    let today = utcToday()
    for subscribe in tvSubscribes {
      guard let tmdbId = subscribe.tmdbid, tmdbId > 0 else { continue }
      let season = max(subscribe.season ?? 1, 1)
      let episodes: [TmdbEpisodeDTO]
      do {
        episodes = try await requestArray(path: "/api/v1/tmdb/\(tmdbId)/\(season)")
      } catch {
        continue
      }
      let showName = (subscribe.name?.isEmpty == false) ? subscribe.name! : "剧集 \(tmdbId)"
      let posterURL = normalizedPosterURL(from: subscribe.poster)
      for episode in episodes {
        guard let airDate = episode.airDate, !airDate.isEmpty, airDate >= today else { continue }
        cards.append(
          EpisodeCard(
            id: "\(tmdbId)-\(season)-\(episode.episodeNumber ?? -1)-\(airDate)",
            date: airDate,
            showName: showName,
            seasonNumber: season,
            episodeNumber: episode.episodeNumber ?? 0,
            episodeTitle: episode.name?.isEmpty == false ? episode.name! : "待播出",
            posterURL: posterURL,
            posterData: nil
          )
        )
      }
    }

    cards.sort { lhs, rhs in
      if lhs.date == rhs.date {
        if lhs.showName == rhs.showName {
          return lhs.episodeNumber < rhs.episodeNumber
        }
        return lhs.showName < rhs.showName
      }
      return lhs.date < rhs.date
    }
    let limited = Array(cards.prefix(8))
    return await populatePosterData(for: limited)
  }

  private func requestArray<T: Decodable>(path: String) async throws -> [T] {
    let request = try buildRequest(path: path)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    guard (200...299).contains(httpResponse.statusCode) else {
      throw URLError(.userAuthenticationRequired)
    }
    let decoder = JSONDecoder()
    if let decoded = try? decoder.decode([T].self, from: data) {
      return decoded
    }
    if
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let nested = json["data"],
      JSONSerialization.isValidJSONObject(nested)
    {
      let nestedData = try JSONSerialization.data(withJSONObject: nested)
      return try decoder.decode([T].self, from: nestedData)
    }
    return []
  }

  private func buildRequest(path: String) throws -> URLRequest {
    let baseURL = try normalizedBaseURL()
    guard let url = URL(string: path, relativeTo: baseURL) else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 30
    request.setValue("application/json", forHTTPHeaderField: "accept")
    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "authorization")
    return request
  }

  private func populatePosterData(for cards: [EpisodeCard]) async -> [EpisodeCard] {
    await withTaskGroup(of: (String, Data?).self) { group in
      for card in cards {
        group.addTask {
          let data = await fetchPosterData(for: card.posterURL)
          return (card.id, data)
        }
      }

      var posterMap: [String: Data] = [:]
      for await (id, data) in group {
        if let data {
          posterMap[id] = data
        }
      }

      return cards.map { card in
        EpisodeCard(
          id: card.id,
          date: card.date,
          showName: card.showName,
          seasonNumber: card.seasonNumber,
          episodeNumber: card.episodeNumber,
          episodeTitle: card.episodeTitle,
          posterURL: card.posterURL,
          posterData: posterMap[card.id]
        )
      }
    }
  }

  private func fetchPosterData(for posterURL: URL?) async -> Data? {
    guard let posterURL else { return nil }
    let resolvedURL = proxiedImageURL(for: posterURL)
    var request = URLRequest(url: resolvedURL)
    request.timeoutInterval = 20
    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "authorization")
    request.setValue("image/*", forHTTPHeaderField: "accept")
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else { return nil }
      guard (200...299).contains(httpResponse.statusCode) else { return nil }
      return data
    } catch {
      return nil
    }
  }

  private func proxiedImageURL(for originalURL: URL) -> URL {
    let encoded = originalURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? originalURL.absoluteString
    let rawBase = session.server.hasSuffix("/") ? String(session.server.dropLast()) : session.server
    if let proxyURL = URL(string: "\(rawBase)/api/v1/system/cache/image?url=\(encoded)") {
      return proxyURL
    }
    return originalURL
  }

  private func normalizedBaseURL() throws -> URL {
    let raw = session.server.hasSuffix("/") ? String(session.server.dropLast()) : session.server
    guard let url = URL(string: raw) else {
      throw URLError(.badURL)
    }
    return url
  }

  private func utcToday() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: Date())
  }

  private func normalizedPosterURL(from raw: String?) -> URL? {
    guard let raw, !raw.isEmpty else { return nil }
    if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
      return URL(string: raw)
    }
    if raw.hasPrefix("/") {
      return URL(string: "https://image.tmdb.org/t/p/w300\(raw)")
    }
    return nil
  }
}

struct SubscribeCalendarWidget: Widget {
  let kind = "SubscribeCalendarWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SubscribeCalendarProvider()) { entry in
      SubscribeCalendarWidgetEntryView(entry: entry)
        .widgetURL(URL(string: "moviepilot://subscribe-calendar"))
    }
    .configurationDisplayName("订阅日历")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

private struct SubscribeCalendarWidgetEntryView: View {
  let entry: SubscribeCalendarEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .padding(16)
      .moviePilotWidgetBackground()
  }

  @ViewBuilder
  private var content: some View {
    switch entry.state {
    case .loaded(let items):
      loadedView(items: items)
    case .empty(let message):
      messageView(title: "订阅日历", message: message)
    case .failed(let message):
      messageView(title: "同步失败", message: message)
    }
  }

  private func loadedView(items: [EpisodeCard]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      switch family {
      case .systemSmall:
        SmallCalendarView(items: items)
      case .systemLarge:
        LargeCalendarView(items: items)
      default:
        MediumCalendarView(items: items)
      }
    }
  }

  private func messageView(title: String, message: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
      Spacer()
      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
      Spacer()
    }
  }
}

private struct SmallCalendarView: View {
  let items: [EpisodeCard]

  var body: some View {
    let todayItems = items.filter { $0.date == utcToday() }

    return VStack(alignment: .leading, spacing: 10) {
        VStack(alignment: .leading, spacing: 4) {
          Text("今天订阅")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
          Text("\(todayItems.count) 条更新")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.primary)
            .lineLimit(1)
          Text(todaySummary(from: todayItems))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
    }
    .padding(.vertical, 2)
  }

  private func todaySummary(from todayItems: [EpisodeCard]) -> String {
    guard !todayItems.isEmpty else {
      return "今天暂无订阅更新"
    }
    let names = todayItems.prefix(3).map(\.showName)
    if todayItems.count > 3 {
      return names.joined(separator: "、") + " 等"
    }
    return names.joined(separator: "、")
  }

  private func utcToday() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: Date())
  }
}

private struct MediumCalendarView: View {
  let items: [EpisodeCard]

  var body: some View {
    VStack(spacing: 6) {
      Spacer(minLength: 16)
      ForEach(Array(items.prefix(2))) { item in
        EpisodeRow(item: item, compact: false, showPoster: true)
      }
      Spacer(minLength: 16)
    }
  }
}

private struct LargeCalendarView: View {
  let items: [EpisodeCard]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(Array(items.prefix(4))) { item in
        EpisodeRow(item: item, compact: false, showPoster: true)
      }
      Spacer(minLength: 0)
    }
  }
}

private struct EpisodeRow: View {
  let item: EpisodeCard
  let compact: Bool
  let showPoster: Bool

  var body: some View {
    HStack(alignment: .top) {
      if showPoster {
        PosterThumbnail(data: item.posterData, compact: compact)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(scheduleLabel)
          .font(.system(size: compact ? 11 : 12, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Text(item.showName)
          .font(.system(size: compact ? 13 : 14, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
        Text("S\(item.seasonNumber)E\(max(item.episodeNumber, 0)) · \(item.episodeTitle)")
          .font(.system(size: compact ? 11 : 12, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(compact ? 1 : 2)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, compact ? 7 : 8)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private var scheduleLabel: String {
    if item.date == utcToday() {
      return "今天"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "zh_CN")
    let displayFormatter = DateFormatter()
    displayFormatter.locale = Locale(identifier: "zh_CN")
    displayFormatter.dateFormat = "M月d日 EEE"
    guard let date = formatter.date(from: item.date) else {
      return item.date
    }
    return displayFormatter.string(from: date)
  }

  private func utcToday() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: Date())
  }
}

private struct PosterThumbnail: View {
  let data: Data?
  let compact: Bool

  var body: some View {
    PosterBackground(data: data)
      .frame(width: compact ? 42 : 50, height: compact ? 56 : 66)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

private struct PosterBackground: View {
  let data: Data?

  var body: some View {
    ZStack {
      Color(.tertiarySystemFill)
      if let data, let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
      } else {
        placeholder
      }
    }
    .clipped()
  }

  private var placeholder: some View {
    ZStack {
      Color(.quaternarySystemFill)
      Image(systemName: "tv")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(.secondary)
    }
  }
}

private struct RecommendItemDTO: Decodable {
  let title: String?
  let year: String?
  let titleYear: String?
  let voteAverage: Double?
  let posterPath: String?
  let backdropPath: String?
  let overview: String?
  let tmdbId: String?
  let doubanId: String?
  let bangumiId: String?
  let mediaIdPrefix: String?
  let mediaId: String?
  let type: String?

  private enum CodingKeys: String, CodingKey {
    case title
    case year
    case titleYear = "title_year"
    case voteAverage = "vote_average"
    case posterPath = "poster_path"
    case backdropPath = "backdrop_path"
    case overview
    case tmdbId = "tmdb_id"
    case doubanId = "douban_id"
    case bangumiId = "bangumi_id"
    case mediaIdPrefix = "mediaid_prefix"
    case mediaId = "media_id"
    case type
    case typeName = "type_name"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    year = try container.decodeIfPresent(String.self, forKey: .year)
    titleYear = try container.decodeIfPresent(String.self, forKey: .titleYear)
    if let value = try? container.decodeIfPresent(Double.self, forKey: .voteAverage) {
      voteAverage = value
    } else if let value = try? container.decodeIfPresent(Int.self, forKey: .voteAverage) {
      voteAverage = Double(value)
    } else if let value = try? container.decodeIfPresent(String.self, forKey: .voteAverage) {
      voteAverage = Double(value)
    } else {
      voteAverage = nil
    }
    posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
    backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
    overview = try container.decodeIfPresent(String.self, forKey: .overview)
    if let value = try? container.decodeIfPresent(String.self, forKey: .tmdbId) {
      tmdbId = value
    } else if let value = try? container.decodeIfPresent(Int.self, forKey: .tmdbId) {
      tmdbId = String(value)
    } else {
      tmdbId = nil
    }
    if let value = try? container.decodeIfPresent(String.self, forKey: .doubanId) {
      doubanId = value
    } else if let value = try? container.decodeIfPresent(Int.self, forKey: .doubanId) {
      doubanId = String(value)
    } else {
      doubanId = nil
    }
    if let value = try? container.decodeIfPresent(String.self, forKey: .bangumiId) {
      bangumiId = value
    } else if let value = try? container.decodeIfPresent(Int.self, forKey: .bangumiId) {
      bangumiId = String(value)
    } else {
      bangumiId = nil
    }
    mediaIdPrefix = try container.decodeIfPresent(String.self, forKey: .mediaIdPrefix)
    if let value = try? container.decodeIfPresent(String.self, forKey: .mediaId) {
      mediaId = value
    } else if let value = try? container.decodeIfPresent(Int.self, forKey: .mediaId) {
      mediaId = String(value)
    } else {
      mediaId = nil
    }
    if let value = try? container.decodeIfPresent(String.self, forKey: .type) {
      type = value
    } else if let value = try? container.decodeIfPresent(String.self, forKey: .typeName) {
      type = value
    } else {
      type = nil
    }
  }
}

struct RecommendCard: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let scoreText: String
  let overview: String
  let posterURL: URL?
  let posterData: Data?
  let widgetURL: URL?
}

struct RecommendTrendingEntry: TimelineEntry {
  let date: Date
  let state: State

  enum State {
    case loaded([RecommendCard])
    case empty(String)
    case failed(String)
  }
}

struct RecommendTrendingProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecommendTrendingEntry {
    RecommendTrendingEntry(
      date: Date(),
      state: .loaded([
        RecommendCard(
          id: "recommend-placeholder-1",
          title: "流行影片示例",
          subtitle: "2026",
          scoreText: "8.4",
          overview: "这里显示流行趋势影视推荐简介，便于快速浏览近期热门内容。",
          posterURL: URL(string: "https://image.tmdb.org/t/p/w300/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg"),
          posterData: nil,
          widgetURL: nil
        ),
        RecommendCard(
          id: "recommend-placeholder-2",
          title: "热门剧集示例",
          subtitle: "2025",
          scoreText: "7.9",
          overview: "点击可进入 App 查看完整推荐列表和详情信息。",
          posterURL: URL(string: "https://image.tmdb.org/t/p/w300/qJxzjUjCpTPvDHldNnlbRC4OqEh.jpg"),
          posterData: nil,
          widgetURL: nil
        ),
      ])
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (RecommendTrendingEntry) -> Void) {
    Task {
      completion(await Self.loadEntry())
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RecommendTrendingEntry>) -> Void) {
    Task {
      let entry = await Self.loadEntry()
      let refreshDate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21600)
      completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
  }

  static func loadEntry() async -> RecommendTrendingEntry {
    widgetLog.info("recommend widget loadEntry started")
    do {
      guard let session = SharedSessionStore.load() else {
        widgetLog.error("recommend widget loadEntry aborted: no shared session")
        return RecommendTrendingEntry(date: Date(), state: .empty("请先登录 MoviePilot"))
      }
      let cards = try await RecommendTrendingService(session: session).fetchTrendingCards()
      if cards.isEmpty {
        widgetLog.error("recommend widget loadEntry completed with empty cards")
        return RecommendTrendingEntry(date: Date(), state: .empty("暂无影视推荐"))
      }
      widgetLog.info("recommend widget loadEntry success, count=\(cards.count)")
      return RecommendTrendingEntry(date: Date(), state: .loaded(cards))
    } catch {
      widgetLog.error("recommend widget loadEntry failed: \(error.localizedDescription, privacy: .public)")
      return RecommendTrendingEntry(date: Date(), state: .failed("推荐内容加载失败"))
    }
  }
}

private struct RecommendTrendingService {
  let session: SharedSession

  func fetchTrendingCards() async throws -> [RecommendCard] {
    widgetLog.info("recommend widget fetchTrendingCards request started")
    let items: [RecommendItemDTO] = try await requestArray()
    widgetLog.info("recommend widget fetchTrendingCards decoded items=\(items.count)")
    let mapped = items.prefix(8).enumerated().map { index, item in
      let rawTitle = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let title = rawTitle.isEmpty ? "未知影视" : rawTitle
      let subtitleRaw = (item.titleYear ?? item.year ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let subtitle = subtitleRaw.isEmpty ? "" : subtitleRaw
      let scoreText = formatScore(item.voteAverage)
      let summaryRaw = (item.overview ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let overview = summaryRaw.isEmpty ? "暂无简介" : summaryRaw
      let posterURL = normalizedPosterURL(from: item.posterPath) ?? normalizedPosterURL(from: item.backdropPath)
      let id = item.tmdbId ?? "recommend-\(index)-\(title)"
      let path = buildMediaPath(from: item)
      let widgetURL = buildMediaDetailURL(
        path: path,
        title: title,
        year: cleanedValue(item.year),
        typeName: cleanedValue(item.type)
      )
      return RecommendCard(
        id: id,
        title: title,
        subtitle: subtitle,
        scoreText: scoreText,
        overview: overview,
        posterURL: posterURL,
        posterData: nil,
        widgetURL: widgetURL
      )
    }
    widgetLog.info("recommend widget fetchTrendingCards mapped cards=\(mapped.count)")
    return await populatePosterData(for: Array(mapped))
  }

  private func requestArray<T: Decodable>() async throws -> [T] {
    let request = try buildRequest()
    widgetLog.info("recommend widget request url=\(request.url?.absoluteString ?? "", privacy: .public)")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      widgetLog.error("recommend widget request failed: non-http response")
      throw URLError(.badServerResponse)
    }
    widgetLog.info("recommend widget response status=\(httpResponse.statusCode)")
    guard (200...299).contains(httpResponse.statusCode) else {
      widgetLog.error("recommend widget response body=\(debugBodyPreview(from: data), privacy: .public)")
      throw URLError(.userAuthenticationRequired)
    }
    let decoder = JSONDecoder()
    if let decoded = try? decoder.decode([T].self, from: data) {
      widgetLog.info("recommend widget decoded root array count=\(decoded.count)")
      return decoded
    }
    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
      if
        let arrayObject = extractFirstArray(from: json),
        JSONSerialization.isValidJSONObject(arrayObject)
      {
        let nestedData = try JSONSerialization.data(withJSONObject: arrayObject)
        let nestedDecoded = try decoder.decode([T].self, from: nestedData)
        widgetLog.info("recommend widget decoded nested array count=\(nestedDecoded.count)")
        return nestedDecoded
      }
      if JSONSerialization.isValidJSONObject(json) {
        let wrappedData = try JSONSerialization.data(withJSONObject: [json])
        if let single = try? decoder.decode([T].self, from: wrappedData) {
          widgetLog.info("recommend widget decoded wrapped single object")
          return single
        }
      }
    }
    widgetLog.error("recommend widget decode produced empty array, body=\(debugBodyPreview(from: data), privacy: .public)")
    return []
  }

  private func buildRequest() throws -> URLRequest {
    let baseURL = try normalizedBaseURL()
    guard let pathURL = URL(string: "/api/v1/recommend/douban_tv_hot", relativeTo: baseURL) else {
      throw URLError(.badURL)
    }
    guard var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: true) else {
      throw URLError(.badURL)
    }
    components.queryItems = [
      URLQueryItem(name: "page", value: "1"),
//      URLQueryItem(name: "title", value: "流行趋势"),
    ]
    guard let finalURL = components.url else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: finalURL)
    request.timeoutInterval = 120
    request.setValue("application/json", forHTTPHeaderField: "accept")
    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "authorization")
    return request
  }

  private func populatePosterData(for cards: [RecommendCard]) async -> [RecommendCard] {
    await withTaskGroup(of: (String, Data?).self) { group in
      for card in cards {
        group.addTask {
          let data = await fetchPosterData(for: card.posterURL)
          return (card.id, data)
        }
      }

      var posterMap: [String: Data] = [:]
      for await (id, data) in group {
        if let data {
          posterMap[id] = data
        }
      }

      return cards.map { card in
        RecommendCard(
          id: card.id,
          title: card.title,
          subtitle: card.subtitle,
          scoreText: card.scoreText,
          overview: card.overview,
          posterURL: card.posterURL,
          posterData: posterMap[card.id],
          widgetURL: card.widgetURL
        )
      }
    }
  }

  private func fetchPosterData(for posterURL: URL?) async -> Data? {
    guard let posterURL else { return nil }
    let resolvedURL = proxiedImageURL(for: posterURL)
    var request = URLRequest(url: resolvedURL)
    request.timeoutInterval = 20
    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "authorization")
    request.setValue("image/*", forHTTPHeaderField: "accept")
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else { return nil }
      guard (200...299).contains(httpResponse.statusCode) else { return nil }
      return data
    } catch {
      return nil
    }
  }

  private func proxiedImageURL(for originalURL: URL) -> URL {
    let encoded = originalURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? originalURL.absoluteString
    let rawBase = session.server.hasSuffix("/") ? String(session.server.dropLast()) : session.server
    if let proxyURL = URL(string: "\(rawBase)/api/v1/system/cache/image?url=\(encoded)") {
      return proxyURL
    }
    return originalURL
  }

  private func normalizedBaseURL() throws -> URL {
    let raw = session.server.hasSuffix("/") ? String(session.server.dropLast()) : session.server
    guard let url = URL(string: raw) else {
      throw URLError(.badURL)
    }
    return url
  }

  private func normalizedPosterURL(from raw: String?) -> URL? {
    guard let raw, !raw.isEmpty else { return nil }
    if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
      return URL(string: raw)
    }
    if raw.hasPrefix("/") {
      return URL(string: "https://image.tmdb.org/t/p/w300\(raw)")
    }
    return nil
  }

  private func formatScore(_ score: Double?) -> String {
    guard let score else { return "暂无评分" }
    if score <= 0 { return "暂无评分" }
    return String(format: "%.1f", score)
  }

  private func debugBodyPreview(from data: Data) -> String {
    guard let text = String(data: data, encoding: .utf8) else {
      return "<non-utf8 \(data.count) bytes>"
    }
    if text.count > 240 {
      return String(text.prefix(240))
    }
    return text
  }

  private func cleanedValue(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func buildMediaPath(from item: RecommendItemDTO) -> String {
    let prefix = cleanedValue(item.mediaIdPrefix)
    let mediaId = cleanedValue(item.mediaId)
    if let prefix, let mediaId {
      return "\(prefix):\(mediaId)"
    }
    if let tmdbId = cleanedValue(item.tmdbId) {
      return "tmdb:\(tmdbId)"
    }
    if let doubanId = cleanedValue(item.doubanId) {
      return "douban:\(doubanId)"
    }
    if let bangumiId = cleanedValue(item.bangumiId) {
      return "bangumi:\(bangumiId)"
    }
    return ""
  }

  private func buildMediaDetailURL(
    path: String,
    title: String,
    year: String?,
    typeName: String?
  ) -> URL? {
    let cleanedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedPath.isEmpty else { return nil }
    var components = URLComponents()
    components.scheme = "moviepilot"
    components.host = "media-detail"
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "path", value: cleanedPath),
      URLQueryItem(name: "title", value: title),
    ]
    if let year {
      queryItems.append(URLQueryItem(name: "year", value: year))
    }
    if let typeName {
      queryItems.append(URLQueryItem(name: "type_name", value: typeName))
    }
    components.queryItems = queryItems
    return components.url
  }

  private func extractFirstArray(from payload: Any) -> [Any]? {
    if let list = payload as? [Any], !list.isEmpty {
      return list
    }
    guard let map = payload as? [String: Any] else {
      return nil
    }
    let prioritizedKeys = ["data", "results", "items", "list", "subjects", "subject", "rows"]
    for key in prioritizedKeys {
      if let nested = map[key], let extracted = extractFirstArray(from: nested), !extracted.isEmpty {
        return extracted
      }
    }
    for value in map.values {
      if let extracted = extractFirstArray(from: value), !extracted.isEmpty {
        return extracted
      }
    }
    return nil
  }
}

struct SiteWidgetPayloadDTO: Decodable {
  let updatedAt: String?
  let summary: SiteWidgetSummaryDTO
  let sites: [SiteWidgetSiteDTO]
}

struct SiteWidgetSummaryDTO: Decodable {
  let totalSites: Int
  let enabledSites: Int
  let sitesWithUserData: Int
  let warningSites: Int
  let unreadMessages: Int
  let totalUpload: Int
  let totalDownload: Int
  let totalSeeding: Int
  let totalSeedingSize: Int
  let totalBonus: Double
}

struct SiteWidgetSiteDTO: Decodable, Identifiable {
  let id: Int
  let name: String
  let domain: String
  let priority: Int
  let iconBase64: String?
  let isActive: Bool
  let hasIssue: Bool
  let errorMessage: String
  let messageUnread: Int
  let upload: Int
  let download: Int
  let ratio: Double
  let seeding: Int
  let seedingSize: Int
  let bonus: Double
  let updatedDay: String
  let updatedTime: String

  var iconData: Data? {
    guard let iconBase64, !iconBase64.isEmpty else { return nil }
    var normalized = iconBase64
    if let commaIndex = normalized.firstIndex(of: ",") {
      normalized = String(normalized[normalized.index(after: commaIndex)...])
    }
    return Data(base64Encoded: normalized)
  }

  var badgeText: String? {
    if hasIssue {
      return errorMessage.isEmpty ? "异常" : "告警"
    }
    if messageUnread > 0 {
      return "未读 \(messageUnread)"
    }
    return nil
  }

  var badgeColor: Color {
    if hasIssue {
      return .red
    }
    if messageUnread > 0 {
      return .orange
    }
    return .secondary
  }

}

struct SiteOverviewEntry: TimelineEntry {
  let date: Date
  let state: State

  enum State {
    case loaded(SiteWidgetPayloadDTO)
    case empty(String)
    case failed(String)
  }
}

struct SiteOverviewProvider: TimelineProvider {
  func placeholder(in context: Context) -> SiteOverviewEntry {
    SiteOverviewEntry(
      date: Date(),
      state: .loaded(
        SiteWidgetPayloadDTO(
          updatedAt: "2026-04-08T12:00:00Z",
          summary: SiteWidgetSummaryDTO(
            totalSites: 12,
            enabledSites: 11,
            sitesWithUserData: 10,
            warningSites: 2,
            unreadMessages: 6,
            totalUpload: 912_680_550_400,
            totalDownload: 274_877_906_944,
            totalSeeding: 86,
            totalSeedingSize: 549_755_813_888,
            totalBonus: 12345.6
          ),
          sites: [
            SiteWidgetSiteDTO(
              id: 1,
              name: "Audience",
              domain: "audiences.me",
              priority: 1,
              iconBase64: nil,
              isActive: true,
              hasIssue: false,
              errorMessage: "",
              messageUnread: 3,
              upload: 268_435_456_000,
              download: 64_424_509_440,
              ratio: 4.17,
              seeding: 12,
              seedingSize: 137_438_953_472,
              bonus: 2350,
              updatedDay: "2026-04-08",
              updatedTime: "08:00:00"
            ),
            SiteWidgetSiteDTO(
              id: 2,
              name: "OpenCD",
              domain: "open.cd",
              priority: 2,
              iconBase64: nil,
              isActive: true,
              hasIssue: true,
              errorMessage: "登录状态失效",
              messageUnread: 0,
              upload: 171_798_691_840,
              download: 42_949_672_960,
              ratio: 4.00,
              seeding: 8,
              seedingSize: 85_899_345_920,
              bonus: 1880,
              updatedDay: "2026-04-08",
              updatedTime: "08:10:00"
            ),
            SiteWidgetSiteDTO(
              id: 3,
              name: "HDHome",
              domain: "hdhome.org",
              priority: 3,
              iconBase64: nil,
              isActive: true,
              hasIssue: false,
              errorMessage: "",
              messageUnread: 1,
              upload: 128_849_018_880,
              download: 34_359_738_368,
              ratio: 3.75,
              seeding: 15,
              seedingSize: 103_079_215_104,
              bonus: 1520,
              updatedDay: "2026-04-08",
              updatedTime: "08:20:00"
            ),
          ]
        )
      )
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SiteOverviewEntry) -> Void) {
    completion(Self.loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SiteOverviewEntry>) -> Void) {
    let entry = Self.loadEntry()
    let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(refreshDate)))
  }

  static func loadEntry() -> SiteOverviewEntry {
    guard let defaults = UserDefaults(suiteName: SharedSessionConfig.appGroup) else {
      return SiteOverviewEntry(date: Date(), state: .failed("共享数据不可用"))
    }
    guard let raw = defaults.string(forKey: SharedSessionConfig.siteWidgetPayloadKey), !raw.isEmpty else {
      let message = SharedSessionStore.load() == nil ? "请先登录 MoviePilot" : "正在同步站点数据"
      return SiteOverviewEntry(date: Date(), state: .empty(message))
    }
    do {
      let payload = try JSONDecoder().decode(SiteWidgetPayloadDTO.self, from: Data(raw.utf8))
      if payload.sites.isEmpty {
        return SiteOverviewEntry(date: Date(), state: .empty("暂无站点数据"))
      }
      return SiteOverviewEntry(date: Date(), state: .loaded(payload))
    } catch {
      widgetLog.error("site overview widget decode failed: \(error.localizedDescription, privacy: .public)")
      return SiteOverviewEntry(date: Date(), state: .failed("站点数据暂时不可用"))
    }
  }
}

struct SiteOverviewWidget: Widget {
  let kind = "SiteOverviewWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SiteOverviewProvider()) { entry in
      SiteOverviewWidgetEntryView(entry: entry)
        .widgetURL(URL(string: "moviepilot://site-overview"))
    }
    .configurationDisplayName("站点概览")
    .description("展示站点总览与关键站点状态")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

private struct SiteOverviewWidgetEntryView: View {
  let entry: SiteOverviewEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .padding(contentPadding)
      .moviePilotWidgetBackground()
  }

  private var contentPadding: CGFloat {
    switch family {
    case .systemSmall:
      return 10
    case .systemMedium:
      return 11
    default:
      return 8
    }
  }

  @ViewBuilder
  private var content: some View {
    switch entry.state {
    case .loaded(let payload):
      loadedView(payload)
    case .empty(let message):
      siteMessageView(title: "站点概览", message: message)
    case .failed(let message):
      siteMessageView(title: "同步失败", message: message)
    }
  }

  @ViewBuilder
  private func loadedView(_ payload: SiteWidgetPayloadDTO) -> some View {
    switch family {
    case .systemSmall:
      SiteOverviewSmallView(payload: payload)
    case .systemLarge:
      SiteOverviewLargeView(payload: payload)
    default:
      SiteOverviewMediumView(payload: payload)
    }
  }

  private func siteMessageView(title: String, message: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
      Spacer()
      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
      Spacer()
    }
  }
}

private struct SiteOverviewSmallView: View {
  let payload: SiteWidgetPayloadDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      SiteOverviewHeaderView(payload: payload, compact: true)
      SiteSummaryGrid(
        items: [
          SiteSummaryItem(label: "站点", value: "\(payload.summary.totalSites)", tint: .blue),
          SiteSummaryItem(label: "在线", value: "\(payload.summary.enabledSites)", tint: .green),
          SiteSummaryItem(label: "告警", value: "\(payload.summary.warningSites)", tint: .red),
          SiteSummaryItem(
            label: "消息",
            value: "\(payload.summary.unreadMessages)",
            tint: .orange,
            destination: payload.summary.unreadMessages > 0 ? systemMessageWidgetURL : nil
          ),
        ]
      )
      Spacer(minLength: 0)
    }
  }
}

private struct SiteOverviewMediumView: View {
  let payload: SiteWidgetPayloadDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      SiteOverviewHeaderView(payload: payload)
      SiteSummaryGrid(
        items: [
          SiteSummaryItem(label: "站点", value: "\(payload.summary.totalSites)", tint: .blue),
          SiteSummaryItem(label: "在线", value: "\(payload.summary.enabledSites)", tint: .green),
          SiteSummaryItem(label: "告警", value: "\(payload.summary.warningSites)", tint: .red),
          SiteSummaryItem(
            label: "消息",
            value: "\(payload.summary.unreadMessages)",
            tint: .orange,
            destination: payload.summary.unreadMessages > 0 ? systemMessageWidgetURL : nil
          ),
        ]
      )
      SiteInsetGroup {
        SiteOverviewDetailRow(
          title: "总流量",
          content: {
            SiteTrafficText(
              upload: payload.summary.totalUpload,
              download: payload.summary.totalDownload,
              compact: true
            )
          }
        )
        SiteRowDivider(inset: 0)
        SiteOverviewDetailRow(
          title: "做种规模",
          trailingText: "\(payload.summary.totalSeeding) 项 · \(formatBytes(payload.summary.totalSeedingSize))"
        )
        SiteRowDivider(inset: 0)
        SiteOverviewDetailRow(
          title: "魔力值",
          trailingText: formatBonus(payload.summary.totalBonus)
        )
      }
    }
  }
}

private struct SiteOverviewLargeView: View {
  let payload: SiteWidgetPayloadDTO

  private var prioritizedSites: [SiteWidgetSiteDTO] {
    payload.sites.sorted { lhs, rhs in
      if lhs.priority != rhs.priority {
        return lhs.priority < rhs.priority
      }
      return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      SiteOverviewHeaderView(payload: payload)
      SiteSummaryRow(
        items: [
          SiteSummaryItem(label: "站点", value: "\(payload.summary.totalSites)", tint: .blue),
          SiteSummaryItem(label: "在线", value: "\(payload.summary.enabledSites)", tint: .green),
          SiteSummaryItem(
            label: "消息",
            value: "\(payload.summary.unreadMessages)",
            tint: .orange,
            destination: payload.summary.unreadMessages > 0 ? systemMessageWidgetURL : nil
          ),
          SiteSummaryItem(label: "做种", value: "\(payload.summary.totalSeeding)", tint: .purple),
        ],
        compact: true
      )
      SiteInsetGroup(horizontalPadding: 8, verticalPadding: 6, rowSpacing: 3) {
        ForEach(Array(prioritizedSites.prefix(5).enumerated()), id: \.element.id) { index, site in
          SiteOverviewRow(site: site, compact: true)
          if index < min(prioritizedSites.count, 5) - 1 {
            SiteRowDivider(inset: 36, verticalPadding: 1)
          }
        }
      }
    }
  }
}

private struct SiteOverviewHeaderView: View {
  let payload: SiteWidgetPayloadDTO
  let compact: Bool

  init(payload: SiteWidgetPayloadDTO, compact: Bool = false) {
    self.payload = payload
    self.compact = compact
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text("站点概览")
        .font(.system(size: compact ? 12 : 13, weight: .bold))
        .foregroundStyle(.primary)
        .lineLimit(1)
      Text("共 \(payload.summary.totalSites) 个")
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
      Spacer()
      if payload.summary.unreadMessages > 0 {
        Link(destination: systemMessageWidgetURL!) {
          SiteSummaryBadge(
            label: "消息",
            value: "\(payload.summary.unreadMessages)",
            tint: .orange
          )
        }
        .buttonStyle(.plain)
      }
    }
  }
}

private struct SiteSummaryItem {
  let label: String
  let value: String
  let tint: Color
  let destination: URL?

  init(label: String, value: String, tint: Color, destination: URL? = nil) {
    self.label = label
    self.value = value
    self.tint = tint
    self.destination = destination
  }
}

private struct SiteSummaryRow: View {
  let items: [SiteSummaryItem]
  let compact: Bool

  init(items: [SiteSummaryItem], compact: Bool = false) {
    self.items = items
    self.compact = compact
  }

  var body: some View {
    HStack(spacing: compact ? 6 : 8) {
      ForEach(Array(items.enumerated()), id: \.offset) { _, item in
        SiteSummaryBadge(
          label: item.label,
          value: item.value,
          tint: item.tint,
          destination: item.destination,
          compact: compact
        )
      }
    }
  }
}

private struct SiteSummaryGrid: View {
  let items: [SiteSummaryItem]

  private let columns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(Array(items.enumerated()), id: \.offset) { _, item in
        SiteSummaryBadge(
          label: item.label,
          value: item.value,
          tint: item.tint,
          destination: item.destination
        )
      }
    }
  }
}

private struct SiteOverviewDetailRow<Content: View>: View {
  let title: String
  let trailingText: String?
  let content: Content?

  init(title: String, trailingText: String) where Content == EmptyView {
    self.title = title
    self.trailingText = trailingText
    self.content = nil
  }

  init(
    title: String,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.trailingText = nil
    self.content = content()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Text(title)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
      Spacer(minLength: 8)
      if let content {
        content
      } else if let trailingText {
        Text(trailingText)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, 2)
    .padding(.vertical, 3)
  }
}

private struct SiteSummaryBadge: View {
  let label: String
  let value: String
  let tint: Color
  let destination: URL?
  let compact: Bool

  init(label: String, value: String, tint: Color, destination: URL? = nil, compact: Bool = false) {
    self.label = label
    self.value = value
    self.tint = tint
    self.destination = destination
    self.compact = compact
  }

  var body: some View {
    let content = HStack(spacing: 4) {
      Text(label)
        .font(.system(size: compact ? 8 : 9, weight: .medium))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.system(size: compact ? 8 : 9, weight: .semibold))
        .foregroundStyle(tint)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, compact ? 6 : 8)
    .padding(.vertical, compact ? 4 : 5)
    .background(
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )

    if let destination {
      Link(destination: destination) {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }
}

private struct SiteHeroCard: View {
  let site: SiteWidgetSiteDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        SiteIconView(site: site, size: 38)
        VStack(alignment: .leading, spacing: 2) {
          Text(site.name)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.primary)
            .lineLimit(1)
          Text(site.domain)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
        Spacer(minLength: 6)
        SiteBadge(site: site, destination: site.messageUnread > 0 ? systemMessageWidgetURL : nil)
      }
      SiteTrafficText(upload: site.upload, download: site.download, compact: false)
      if site.hasIssue, !site.errorMessage.isEmpty {
        Text(site.errorMessage)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.red)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }
}

private struct SiteOverviewRow: View {
  let site: SiteWidgetSiteDTO
  let compact: Bool

  var body: some View {
    HStack(alignment: .center, spacing: 9) {
      SiteIconView(site: site, size: compact ? 28 : 34)
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(site.name)
            .font(.system(size: compact ? 12 : 14, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
          SiteBadge(site: site, destination: site.messageUnread > 0 ? systemMessageWidgetURL : nil)
        }
        if site.hasIssue, !site.errorMessage.isEmpty {
          Text(site.errorMessage)
            .font(.system(size: compact ? 10 : 12, weight: .medium))
            .foregroundStyle(.red)
            .lineLimit(1)
        } else {
          SiteTrafficText(upload: site.upload, download: site.download, compact: compact)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, compact ? 7 : 8)
    .padding(.vertical, compact ? 6 : 7)
  }
}

private struct SiteBadge: View {
  let site: SiteWidgetSiteDTO
  let destination: URL?

  init(site: SiteWidgetSiteDTO, destination: URL? = nil) {
    self.site = site
    self.destination = destination
  }

  var body: some View {
    if let badgeText = site.badgeText {
      let content = Text(badgeText)
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(site.badgeColor)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(site.badgeColor.opacity(0.12), in: Capsule())

      if let destination {
        Link(destination: destination) {
          content
        }
        .buttonStyle(.plain)
      } else {
        content
      }
    }
  }
}

private struct SiteInsetGroup<Content: View>: View {
  @ViewBuilder let content: Content
  let horizontalPadding: CGFloat
  let verticalPadding: CGFloat
  let rowSpacing: CGFloat

  init(
    horizontalPadding: CGFloat = 12,
    verticalPadding: CGFloat = 10,
    rowSpacing: CGFloat = 0,
    @ViewBuilder content: () -> Content
  ) {
    self.horizontalPadding = horizontalPadding
    self.verticalPadding = verticalPadding
    self.rowSpacing = rowSpacing
    self.content = content()
  }

  var body: some View {
    VStack(spacing: rowSpacing) {
      content
    }
    .padding(.horizontal, horizontalPadding)
    .padding(.vertical, verticalPadding)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }
}

private struct SiteRowDivider: View {
  let inset: CGFloat
  let verticalPadding: CGFloat

  init(inset: CGFloat = 46, verticalPadding: CGFloat = 0) {
    self.inset = inset
    self.verticalPadding = verticalPadding
  }

  var body: some View {
    Divider()
      .overlay(Color(.separator).opacity(0.35))
      .padding(.leading, inset)
      .padding(.vertical, verticalPadding)
  }
}

private struct SiteIconView: View {
  let site: SiteWidgetSiteDTO
  let size: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        .fill(Color(.tertiarySystemFill))
      if let data = site.iconData, let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
      } else {
        Image(systemName: site.hasIssue ? "exclamationmark.triangle.fill" : "globe")
          .font(.system(size: size * 0.42, weight: .semibold))
          .foregroundStyle(site.badgeColor)
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
  }
}

private struct SiteTrafficText: View {
  let upload: Int
  let download: Int
  let compact: Bool

  var body: some View {
    HStack(spacing: compact ? 6 : 8) {
      Label {
        Text(formatBytes(upload))
          .font(.system(size: compact ? 9 : 11, weight: .semibold))
          .foregroundStyle(Color(red: 0.12, green: 0.60, blue: 0.33))
      } icon: {
        Image(systemName: "arrow.up.right")
          .font(.system(size: compact ? 9 : 10, weight: .bold))
          .foregroundStyle(Color(red: 0.12, green: 0.60, blue: 0.33))
      }
      Label {
        Text(formatBytes(download))
          .font(.system(size: compact ? 9 : 11, weight: .semibold))
          .foregroundStyle(Color(red: 0.12, green: 0.45, blue: 0.92))
      } icon: {
        Image(systemName: "arrow.down.right")
          .font(.system(size: compact ? 9 : 10, weight: .bold))
          .foregroundStyle(Color(red: 0.12, green: 0.45, blue: 0.92))
      }
    }
    .lineLimit(1)
  }
}

private func formatBytes(_ value: Int) -> String {
  guard value > 0 else { return "0 B" }
  let formatter = ByteCountFormatter()
  formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
  formatter.countStyle = .binary
  formatter.includesUnit = true
  formatter.isAdaptive = true
  return formatter.string(fromByteCount: Int64(value))
}

private func formatBonus(_ value: Double) -> String {
  if value >= 10000 {
    return String(format: "%.1fk", value / 1000)
  }
  if value >= 1000 {
    return String(format: "%.0f", value)
  }
  return String(format: "%.1f", value)
}

struct RecommendTrendingWidget: Widget {
  let kind = "RecommendTrendingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RecommendTrendingProvider()) { entry in
      RecommendTrendingWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("影视推荐")
    .description("展示豆瓣热门影视推荐")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

@available(iOSApplicationExtension 17.0, *)
struct SubscribeCalendarAppIntentWidget: Widget {
  let kind = "SubscribeCalendarWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SubscribeCalendarWidgetIntent.self,
      provider: SubscribeCalendarAppIntentProvider()
    ) { entry in
      SubscribeCalendarWidgetEntryView(entry: entry)
        .widgetURL(URL(string: "moviepilot://subscribe-calendar"))
    }
    .configurationDisplayName("订阅日历")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

@available(iOSApplicationExtension 17.0, *)
struct RecommendTrendingAppIntentWidget: Widget {
  let kind = "RecommendTrendingWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: RecommendTrendingWidgetIntent.self,
      provider: RecommendTrendingAppIntentProvider()
    ) { entry in
      RecommendTrendingWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("影视推荐")
    .description("展示豆瓣热门影视推荐")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

private struct RecommendTrendingWidgetEntryView: View {
  let entry: RecommendTrendingEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .padding(16)
      .moviePilotWidgetBackground()
  }

  @ViewBuilder
  private var content: some View {
    switch entry.state {
    case .loaded(let items):
      loadedView(items: items)
    case .empty(let message):
      messageView(title: "影视推荐", message: message)
    case .failed(let message):
      messageView(title: "同步失败", message: message)
    }
  }

  @ViewBuilder
  private func loadedView(items: [RecommendCard]) -> some View {
    switch family {
    case .systemSmall:
      RecommendSmallView(item: items.first)
    case .systemLarge:
      RecommendLargeView(items: items)
    default:
      RecommendMediumView(items: items)
    }
  }

  private func messageView(title: String, message: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
      Spacer()
      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
      Spacer()
    }
  }
}

private struct RecommendSmallView: View {
  let item: RecommendCard?

  @ViewBuilder
  var body: some View {
    if let item {
      if let url = item.widgetURL {
        Link(destination: url) {
          smallContent(item)
        }
        .buttonStyle(.plain)
      } else {
        smallContent(item)
      }
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Text("影视推荐")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(.primary)
        Spacer()
        Text("暂无推荐")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
      }
    }
  }

  private func smallContent(_ item: RecommendCard) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("豆瓣热门")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
      HStack(alignment: .top, spacing: 10) {
        RecommendPosterThumbnail(data: item.posterData, compact: true)
        VStack(alignment: .leading, spacing: 4) {
          Text(item.title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
          Text(item.subtitle)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text(item.scoreText == "暂无评分" ? item.scoreText : "评分 \(item.scoreText)")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
  }
}

private struct RecommendMediumView: View {
  let items: [RecommendCard]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("豆瓣热门")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.secondary)
      ForEach(Array(items.prefix(2))) { item in
        if let url = item.widgetURL {
          Link(destination: url) {
            RecommendRow(item: item)
          }
          .buttonStyle(.plain)
        } else {
          RecommendRow(item: item)
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct RecommendLargeView: View {
  let items: [RecommendCard]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("豆瓣热门")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.secondary)
      ForEach(Array(items.prefix(4))) { item in
        if let url = item.widgetURL {
          Link(destination: url) {
            RecommendRow(item: item)
          }
          .buttonStyle(.plain)
        } else {
          RecommendRow(item: item)
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct RecommendRow: View {
  let item: RecommendCard

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      RecommendPosterThumbnail(data: item.posterData, compact: false)
      VStack(alignment: .leading, spacing: 4) {
        Text(item.title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
        Text(item.subtitle)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Text(item.scoreText == "暂无评分" ? item.scoreText : "评分 \(item.scoreText)")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

private struct RecommendPosterThumbnail: View {
  let data: Data?
  let compact: Bool

  var body: some View {
    RecommendPosterBackground(data: data)
      .frame(width: compact ? 46 : 44, height: compact ? 62 : 58)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}

private struct RecommendPosterBackground: View {
  let data: Data?

  var body: some View {
    ZStack {
      Color(.tertiarySystemFill)
      if let data, let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
      } else {
        placeholder
      }
    }
    .clipped()
  }

  private var placeholder: some View {
    ZStack {
      Color(.quaternarySystemFill)
      Image(systemName: "film")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(.secondary)
    }
  }
}

private extension View {
  @ViewBuilder
  func moviePilotWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        Color(.systemBackground)
      }
    } else {
      background(Color(.systemBackground))
    }
  }
}
