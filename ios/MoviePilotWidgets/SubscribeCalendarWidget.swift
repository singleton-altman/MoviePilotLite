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

private enum MoviePilotWidgetTheme {
  static let backgroundTop = Color(red: 0.02, green: 0.04, blue: 0.09)
  static let backgroundBottom = Color(red: 0.00, green: 0.02, blue: 0.06)
  static let surface = Color.white.opacity(0.08)
  static let elevatedSurface = Color.white.opacity(0.12)
  static let border = Color.white.opacity(0.13)
  static let primaryText = Color(red: 0.97, green: 0.98, blue: 1.00)
  static let secondaryText = Color(red: 0.70, green: 0.77, blue: 0.86)
  static let mutedText = Color(red: 0.49, green: 0.56, blue: 0.67)
  static let green = Color(red: 0.13, green: 0.77, blue: 0.37)
  static let cyan = Color(red: 0.19, green: 0.73, blue: 0.93)
  static let amber = Color(red: 0.98, green: 0.68, blue: 0.20)
  static let red = Color(red: 0.96, green: 0.31, blue: 0.35)
  static let violet = Color(red: 0.63, green: 0.47, blue: 0.98)

  static var backgroundGradient: LinearGradient {
    LinearGradient(
      colors: [backgroundTop, backgroundBottom],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}

private struct WidgetSectionHeader: View {
  let title: String
  let subtitle: String?
  let systemImage: String
  let tint: Color
  let compact: Bool

  init(
    title: String,
    subtitle: String? = nil,
    systemImage: String,
    tint: Color = MoviePilotWidgetTheme.green,
    compact: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.tint = tint
    self.compact = compact
  }

  var body: some View {
    HStack(alignment: .center, spacing: compact ? 6 : 8) {
      Image(systemName: systemImage)
        .font(.system(size: compact ? 10 : 12, weight: .bold))
        .foregroundStyle(tint)
        .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)
        .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: compact ? 6 : 7, style: .continuous))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.system(size: compact ? 12 : 13, weight: .bold))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
          .lineLimit(1)
        if let subtitle, !subtitle.isEmpty {
          Text(subtitle)
            .font(.system(size: compact ? 8 : 9, weight: .medium))
            .foregroundStyle(MoviePilotWidgetTheme.mutedText)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct WidgetStatusView: View {
  let title: String
  let message: String
  let systemImage: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      WidgetSectionHeader(
        title: title,
        subtitle: "MoviePilot",
        systemImage: systemImage,
        tint: tint
      )
      Spacer(minLength: 0)
      Text(message)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
        .lineLimit(3)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

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
      .padding(contentPadding)
      .moviePilotWidgetBackground()
  }

  private var contentPadding: CGFloat {
    switch family {
    case .systemSmall:
      return 13
    case .systemMedium:
      return 14
    default:
      return 15
    }
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
    WidgetStatusView(
      title: title,
      message: message,
      systemImage: title == "同步失败" ? "exclamationmark.triangle.fill" : "calendar.badge.clock",
      tint: title == "同步失败" ? MoviePilotWidgetTheme.red : MoviePilotWidgetTheme.green
    )
  }
}

private struct SmallCalendarView: View {
  let items: [EpisodeCard]

  var body: some View {
    let todayItems = items.filter { $0.date == utcToday() }
    let nextItem = items.first

    return VStack(alignment: .leading, spacing: 9) {
      WidgetSectionHeader(
        title: "订阅日历",
        subtitle: nextItem.map { scheduleLabel(for: $0.date) },
        systemImage: "calendar.badge.clock",
        tint: MoviePilotWidgetTheme.green,
        compact: true
      )
      Spacer(minLength: 0)
      Text("\(todayItems.count)")
        .font(.system(size: 36, weight: .black, design: .rounded))
        .foregroundStyle(MoviePilotWidgetTheme.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      Text(todayItems.isEmpty ? "今天暂无更新" : "今日待播更新")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(todayItems.isEmpty ? MoviePilotWidgetTheme.mutedText : MoviePilotWidgetTheme.green)
        .lineLimit(1)
      Text(todaySummary(from: todayItems, fallback: nextItem))
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
        .lineLimit(2)
        .minimumScaleFactor(0.82)
    }
    .accessibilityElement(children: .combine)
  }

  private func todaySummary(from todayItems: [EpisodeCard], fallback: EpisodeCard?) -> String {
    guard !todayItems.isEmpty else {
      guard let fallback else { return "今天之后暂无订阅更新" }
      return "下一集：\(fallback.showName)"
    }
    let names = todayItems.prefix(3).map(\.showName)
    if todayItems.count > 3 {
      return names.joined(separator: "、") + " 等"
    }
    return names.joined(separator: "、")
  }

  private func scheduleLabel(for rawDate: String) -> String {
    if rawDate == utcToday() {
      return "今天"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let displayFormatter = DateFormatter()
    displayFormatter.locale = Locale(identifier: "zh_CN")
    displayFormatter.dateFormat = "M月d日"
    guard let date = formatter.date(from: rawDate) else { return rawDate }
    return displayFormatter.string(from: date)
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
    VStack(alignment: .leading, spacing: 9) {
      WidgetSectionHeader(
        title: "订阅日历",
        subtitle: "\(items.count) 条待播",
        systemImage: "calendar.badge.clock",
        tint: MoviePilotWidgetTheme.green
      )
      if let first = items.first {
        EpisodeHeroCard(item: first, compact: true)
      }
      HStack(spacing: 8) {
        ForEach(Array(items.dropFirst().prefix(2))) { item in
          EpisodeCompactChip(item: item)
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct LargeCalendarView: View {
  let items: [EpisodeCard]

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      WidgetSectionHeader(
        title: "订阅日历",
        subtitle: "\(items.count) 条待播更新",
        systemImage: "calendar.badge.clock",
        tint: MoviePilotWidgetTheme.green
      )
      if let first = items.first {
        EpisodeHeroCard(item: first, compact: false)
      }
      VStack(spacing: 6) {
        ForEach(Array(items.dropFirst().prefix(3))) { item in
          EpisodeRow(item: item, compact: true, showPoster: true)
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct EpisodeHeroCard: View {
  let item: EpisodeCard
  let compact: Bool

  var body: some View {
    HStack(alignment: .center, spacing: compact ? 10 : 12) {
      PosterThumbnail(data: item.posterData, compact: compact)
      VStack(alignment: .leading, spacing: compact ? 4 : 6) {
        Text(scheduleLabel)
          .font(.system(size: compact ? 10 : 11, weight: .bold))
          .foregroundStyle(MoviePilotWidgetTheme.green)
          .lineLimit(1)
        Text(item.showName)
          .font(.system(size: compact ? 15 : 17, weight: .bold))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
          .lineLimit(compact ? 1 : 2)
          .minimumScaleFactor(0.82)
        Text("S\(item.seasonNumber)E\(max(item.episodeNumber, 0)) · \(item.episodeTitle)")
          .font(.system(size: compact ? 11 : 12, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
          .lineLimit(compact ? 1 : 2)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, compact ? 10 : 12)
    .padding(.vertical, compact ? 9 : 11)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(MoviePilotWidgetTheme.elevatedSurface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(MoviePilotWidgetTheme.green.opacity(0.26), lineWidth: 0.8)
    )
    .accessibilityElement(children: .combine)
  }

  private var scheduleLabel: String {
    formattedCalendarDate(item.date)
  }
}

private struct EpisodeCompactChip: View {
  let item: EpisodeCard

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(formattedCalendarDate(item.date))
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(MoviePilotWidgetTheme.green)
        .lineLimit(1)
      Text(item.showName)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(MoviePilotWidgetTheme.primaryText)
        .lineLimit(1)
      Text("E\(max(item.episodeNumber, 0))")
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(MoviePilotWidgetTheme.mutedText)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 8)
    .padding(.vertical, 7)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(MoviePilotWidgetTheme.surface)
    )
    .accessibilityElement(children: .combine)
  }
}

private struct EpisodeRow: View {
  let item: EpisodeCard
  let compact: Bool
  let showPoster: Bool

  var body: some View {
    HStack(alignment: .center, spacing: 9) {
      if showPoster {
        PosterThumbnail(data: item.posterData, compact: compact)
      }
      VStack(alignment: .leading, spacing: 3) {
        Text(scheduleLabel)
          .font(.system(size: compact ? 11 : 12, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.green)
          .lineLimit(1)
        Text(item.showName)
          .font(.system(size: compact ? 13 : 14, weight: .semibold))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
          .lineLimit(1)
        Text("S\(item.seasonNumber)E\(max(item.episodeNumber, 0)) · \(item.episodeTitle)")
          .font(.system(size: compact ? 11 : 12, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
          .lineLimit(compact ? 1 : 2)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, compact ? 9 : 12)
    .padding(.vertical, compact ? 7 : 8)
    .background(MoviePilotWidgetTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  private var scheduleLabel: String {
    formattedCalendarDate(item.date)
  }
}

private struct PosterThumbnail: View {
  let data: Data?
  let compact: Bool

  var body: some View {
    PosterBackground(data: data)
      .frame(width: compact ? 46 : 58, height: compact ? 62 : 78)
      .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous)
          .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
      )
  }
}

private struct PosterBackground: View {
  let data: Data?

  var body: some View {
    ZStack {
      MoviePilotWidgetTheme.surface
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
      MoviePilotWidgetTheme.elevatedSurface
      Image(systemName: "tv")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(MoviePilotWidgetTheme.green)
    }
  }
}

private func formattedCalendarDate(_ rawDate: String) -> String {
  let todayFormatter = ISO8601DateFormatter()
  todayFormatter.formatOptions = [.withFullDate]
  todayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
  if rawDate == todayFormatter.string(from: Date()) {
    return "今天"
  }
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  formatter.locale = Locale(identifier: "zh_CN")
  let displayFormatter = DateFormatter()
  displayFormatter.locale = Locale(identifier: "zh_CN")
  displayFormatter.dateFormat = "M月d日 EEE"
  guard let date = formatter.date(from: rawDate) else {
    return rawDate
  }
  return displayFormatter.string(from: date)
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
    .supportedFamilies([.systemExtraLarge])
  }
}

private struct SiteOverviewWidgetEntryView: View {
  let entry: SiteOverviewEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .padding(contentPadding)
      .siteInfoWidgetBackground()
  }

  private var contentPadding: CGFloat {
    24
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
    case .systemLarge, .systemExtraLarge:
      SiteOverviewLargeView(payload: payload)
    default:
      SiteOverviewMediumView(payload: payload)
    }
  }

  private func siteMessageView(title: String, message: String) -> some View {
    SiteReminderStyleStatusView(
      count: "0",
      title: title == "同步失败" ? "同步失败" : "站点数据",
      message: message,
      systemImage: title == "同步失败" ? "exclamationmark.triangle.fill" : "chart.bar.fill",
      tint: title == "同步失败" ? SiteReminderStyleTheme.danger : SiteReminderStyleTheme.blue
    )
  }
}

private struct SiteOverviewSmallView: View {
  let payload: SiteWidgetPayloadDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SiteOverviewHeaderView(payload: payload, compact: true)
      HStack(alignment: .center, spacing: 10) {
        SiteHealthRing(
          progress: siteHealthProgress(payload),
          tint: siteHealthTint(payload),
          size: 54,
          lineWidth: 6
        )
        VStack(alignment: .leading, spacing: 3) {
          Text("\(payload.summary.enabledSites)/\(max(payload.summary.totalSites, 1))")
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(MoviePilotWidgetTheme.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
          Text(siteHealthLabel(payload))
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(siteHealthTint(payload))
            .lineLimit(1)
          Text("告警 \(payload.summary.warningSites) · 未读 \(payload.summary.unreadMessages)")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
      }
      SiteTrafficBalanceBar(
        upload: payload.summary.totalUpload,
        download: payload.summary.totalDownload,
        compact: true
      )
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .contain)
  }
}

private struct SiteOverviewMediumView: View {
  let payload: SiteWidgetPayloadDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SiteOverviewHeaderView(payload: payload)
      SiteOperationsHero(payload: payload, compact: true)
      HStack(spacing: 7) {
        SiteMetricTile(
          label: "告警",
          value: "\(payload.summary.warningSites)",
          systemImage: "exclamationmark.triangle.fill",
          tint: MoviePilotWidgetTheme.red,
          compact: true
        )
        SiteMetricTile(
          label: "消息",
          value: "\(payload.summary.unreadMessages)",
          systemImage: "bell.badge.fill",
          tint: MoviePilotWidgetTheme.amber,
          destination: payload.summary.unreadMessages > 0 ? systemMessageWidgetURL : nil,
          compact: true
        )
        SiteMetricTile(
          label: "做种",
          value: "\(payload.summary.totalSeeding)",
          systemImage: "arrow.up.circle.fill",
          tint: MoviePilotWidgetTheme.violet,
          compact: true
        )
      }
      Spacer(minLength: 0)
    }
  }
}

private struct SiteOverviewLargeView: View {
  let payload: SiteWidgetPayloadDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SiteReminderStyleHeader(
        count: "\(payload.summary.totalSites)",
        title: "站点数据",
        systemImage: "chart.bar.fill",
        tint: SiteReminderStyleTheme.blue
      )
      SiteReminderStyleDivider()
      VStack(spacing: 14) {
        HStack(alignment: .top, spacing: 18) {
          SiteReminderStyleHeroMetric(
            label: "在线站点",
            value: "\(payload.summary.enabledSites)/\(max(payload.summary.totalSites, 1))",
            detail: "已启用站点",
            tint: SiteReminderStyleTheme.blue
          )
          SiteReminderStyleHeroMetric(
            label: "已同步数据",
            value: "\(payload.summary.sitesWithUserData)",
            detail: "有用户数据的站点",
            tint: SiteReminderStyleTheme.black
          )
        }
        SiteReminderStyleTrafficPanel(
          upload: formatBytes(payload.summary.totalUpload),
          download: formatBytes(payload.summary.totalDownload)
        )
        HStack(spacing: 18) {
          SiteReminderStyleDataMetric(
            label: "做种数量",
            value: "\(payload.summary.totalSeeding) 项",
            tint: SiteReminderStyleTheme.black
          )
          SiteReminderStyleDataMetric(
            label: "做种体积",
            value: formatBytes(payload.summary.totalSeedingSize),
            tint: SiteReminderStyleTheme.black
          )
          SiteReminderStyleDataMetric(
            label: "魔力值",
            value: formatBonus(payload.summary.totalBonus),
            tint: SiteReminderStyleTheme.black
          )
        }
      }
      .padding(.top, 18)
      Spacer(minLength: 0)
      SiteReminderStyleDivider()
      HStack(spacing: 18) {
        SiteReminderStyleFooterItem(label: "站点总数", value: "\(payload.summary.totalSites)")
        SiteReminderStyleFooterItem(label: "告警", value: "\(payload.summary.warningSites)")
        if payload.summary.unreadMessages > 0, let url = systemMessageWidgetURL {
          Link(destination: url) {
            SiteReminderStyleFooterItem(label: "未读", value: "\(payload.summary.unreadMessages)")
          }
          .buttonStyle(.plain)
        } else {
          SiteReminderStyleFooterItem(label: "未读", value: "\(payload.summary.unreadMessages)")
        }
      }
    }
    .accessibilityElement(children: .contain)
  }
}

private enum SiteReminderStyleTheme {
  static let blue = Color(red: 0.00, green: 0.47, blue: 1.00)
  static let danger = Color(red: 1.00, green: 0.23, blue: 0.19)
  static let black = Color.black
  static let divider = Color(red: 0.88, green: 0.88, blue: 0.90)
  static let placeholder = Color(red: 0.42, green: 0.42, blue: 0.44)
  static let secondary = Color(red: 0.30, green: 0.30, blue: 0.32)
}

private struct SiteReminderStyleHeader: View {
  let count: String
  let title: String
  let systemImage: String
  let tint: Color

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading, spacing: 1) {
        Text(count)
          .font(.system(size: 38, weight: .black, design: .rounded))
          .foregroundStyle(SiteReminderStyleTheme.black)
          .frame(height: 44, alignment: .center)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        Text(title)
          .font(.system(size: 19, weight: .bold))
          .foregroundStyle(tint)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
      ZStack {
        Circle()
          .fill(tint)
        Image(systemName: systemImage)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(.white)
      }
      .frame(width: 44, height: 44)
      .padding(.top, 5)
      .accessibilityHidden(true)
    }
    .padding(.top, 4)
    .padding(.bottom, 16)
    .accessibilityElement(children: .combine)
  }
}

private struct SiteReminderStyleStatusView: View {
  let count: String
  let title: String
  let message: String
  let systemImage: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SiteReminderStyleHeader(
        count: count,
        title: title,
        systemImage: systemImage,
        tint: tint
      )
      SiteReminderStyleDivider()
      Spacer(minLength: 0)
      Text(message)
        .font(.system(size: 21, weight: .semibold))
        .foregroundStyle(SiteReminderStyleTheme.placeholder)
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct SiteReminderStyleIssueRow: View {
  let site: SiteWidgetSiteDTO

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      ZStack {
        Circle()
          .fill(SiteReminderStyleTheme.danger.opacity(0.14))
        Image(systemName: "exclamationmark")
          .font(.system(size: 14, weight: .black))
          .foregroundStyle(SiteReminderStyleTheme.danger)
      }
      .frame(width: 28, height: 28)
      VStack(alignment: .leading, spacing: 3) {
        Text(site.name)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(SiteReminderStyleTheme.black)
          .lineLimit(1)
        Text(site.errorMessage.isEmpty ? site.domain : site.errorMessage)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(SiteReminderStyleTheme.secondary)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 9)
    .accessibilityElement(children: .combine)
  }
}

private struct SiteReminderStyleDataMetric: View {
  let label: String
  let value: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(value)
        .font(.system(size: 24, weight: .heavy, design: .rounded))
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.58)
      Text(label)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(SiteReminderStyleTheme.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

private struct SiteReminderStyleHeroMetric: View {
  let label: String
  let value: String
  let detail: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(value)
        .font(.system(size: 34, weight: .black, design: .rounded))
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.62)
      Text(label)
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(SiteReminderStyleTheme.black)
        .lineLimit(1)
      Text(detail)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(SiteReminderStyleTheme.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

private struct SiteReminderStyleTrafficPanel: View {
  let upload: String
  let download: String

  var body: some View {
    VStack(spacing: 8) {
      SiteReminderStyleTrafficRow(label: "上传总量", value: upload, tint: SiteReminderStyleTheme.blue)
      SiteReminderStyleDivider()
      SiteReminderStyleTrafficRow(label: "下载总量", value: download, tint: SiteReminderStyleTheme.black)
    }
    .padding(.vertical, 8)
  }
}

private struct SiteReminderStyleTrafficRow: View {
  let label: String
  let value: String
  let tint: Color

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(label)
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(SiteReminderStyleTheme.secondary)
      Spacer(minLength: 10)
      Text(value)
        .font(.system(size: 27, weight: .black, design: .rounded))
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct SiteReminderStyleFooterItem: View {
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 4) {
      Text(value)
        .font(.system(size: 13, weight: .heavy))
        .foregroundStyle(SiteReminderStyleTheme.black)
      Text(label)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(SiteReminderStyleTheme.secondary)
    }
    .lineLimit(1)
  }
}

private struct SiteReminderStyleDivider: View {
  var body: some View {
    Rectangle()
      .fill(SiteReminderStyleTheme.divider)
      .frame(height: 1)
  }
}

private struct SiteOperationsHero: View {
  let payload: SiteWidgetPayloadDTO
  let compact: Bool

  var body: some View {
    HStack(alignment: .center, spacing: compact ? 10 : 12) {
      SiteHealthRing(
        progress: siteHealthProgress(payload),
        tint: siteHealthTint(payload),
        size: compact ? 52 : 62,
        lineWidth: compact ? 6 : 7
      )
      VStack(alignment: .leading, spacing: compact ? 5 : 6) {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(payload.summary.enabledSites)")
            .font(.system(size: compact ? 24 : 28, weight: .black, design: .rounded))
            .foregroundStyle(MoviePilotWidgetTheme.primaryText)
            .lineLimit(1)
          Text("/ \(max(payload.summary.totalSites, 1)) 在线")
            .font(.system(size: compact ? 10 : 11, weight: .bold))
            .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
            .lineLimit(1)
        }
        Text(siteHealthLabel(payload))
          .font(.system(size: compact ? 10 : 11, weight: .bold))
          .foregroundStyle(siteHealthTint(payload))
          .lineLimit(1)
        SiteTrafficBalanceBar(
          upload: payload.summary.totalUpload,
          download: payload.summary.totalDownload,
          compact: compact
        )
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, compact ? 10 : 12)
    .padding(.vertical, compact ? 9 : 11)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(MoviePilotWidgetTheme.elevatedSurface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(siteHealthTint(payload).opacity(0.24), lineWidth: 0.9)
    )
    .accessibilityElement(children: .combine)
  }
}

private struct SiteHealthRing: View {
  let progress: Double
  let tint: Color
  let size: CGFloat
  let lineWidth: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .stroke(MoviePilotWidgetTheme.surface, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: min(max(progress, 0), 1))
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(Int((min(max(progress, 0), 1) * 100).rounded()))%")
        .font(.system(size: size > 58 ? 13 : 11, weight: .black, design: .rounded))
        .foregroundStyle(MoviePilotWidgetTheme.primaryText)
        .minimumScaleFactor(0.7)
    }
    .frame(width: size, height: size)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("站点健康度 \(Int((min(max(progress, 0), 1) * 100).rounded()))%")
  }
}

private struct SiteTrafficBalanceBar: View {
  let upload: Int
  let download: Int
  let compact: Bool

  private var total: Double {
    Double(max(upload + download, 1))
  }

  private var uploadRatio: Double {
    min(max(Double(upload) / total, 0), 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 4 : 5) {
      HStack(spacing: 6) {
        Label {
          Text(formatBytes(upload))
        } icon: {
          Image(systemName: "arrow.up.right")
            .accessibilityHidden(true)
        }
        .foregroundStyle(MoviePilotWidgetTheme.green)
        Label {
          Text(formatBytes(download))
        } icon: {
          Image(systemName: "arrow.down.right")
            .accessibilityHidden(true)
        }
        .foregroundStyle(MoviePilotWidgetTheme.cyan)
      }
      .font(.system(size: compact ? 8 : 9, weight: .semibold))
      .lineLimit(1)
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(MoviePilotWidgetTheme.surface)
          Capsule()
            .fill(MoviePilotWidgetTheme.cyan.opacity(0.62))
          Capsule()
            .fill(MoviePilotWidgetTheme.green)
            .frame(width: max(proxy.size.width * CGFloat(uploadRatio), 4))
        }
      }
      .frame(height: compact ? 5 : 6)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct SiteMetricTile: View {
  let label: String
  let value: String
  let systemImage: String
  let tint: Color
  let destination: URL?
  let compact: Bool

  init(
    label: String,
    value: String,
    systemImage: String,
    tint: Color,
    destination: URL? = nil,
    compact: Bool = false
  ) {
    self.label = label
    self.value = value
    self.systemImage = systemImage
    self.tint = tint
    self.destination = destination
    self.compact = compact
  }

  var body: some View {
    if let destination {
      Link(destination: destination) {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }

  private var content: some View {
    HStack(spacing: compact ? 5 : 7) {
      Image(systemName: systemImage)
        .font(.system(size: compact ? 10 : 12, weight: .bold))
        .foregroundStyle(tint)
        .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: compact ? 6 : 7, style: .continuous))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 1) {
        Text(value)
          .font(.system(size: compact ? 12 : 14, weight: .black, design: .rounded))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        Text(label)
          .font(.system(size: compact ? 8 : 9, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.mutedText)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, compact ? 6 : 8)
    .padding(.vertical, compact ? 6 : 8)
    .background(
      RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous)
        .fill(MoviePilotWidgetTheme.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous)
        .stroke(tint.opacity(0.18), lineWidth: 0.8)
    )
    .accessibilityElement(children: .combine)
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
    HStack(alignment: .center, spacing: 6) {
      WidgetSectionHeader(
        title: "站点概览",
        subtitle: "共 \(payload.summary.totalSites) 个",
        systemImage: "server.rack",
        tint: MoviePilotWidgetTheme.cyan,
        compact: compact
      )
      if payload.summary.unreadMessages > 0 {
        Link(destination: systemMessageWidgetURL!) {
          SiteSummaryBadge(
            label: "消息",
            value: "\(payload.summary.unreadMessages)",
            tint: MoviePilotWidgetTheme.amber,
            compact: true
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
        .foregroundStyle(MoviePilotWidgetTheme.mutedText)
      Spacer(minLength: 8)
      if let content {
        content
      } else if let trailingText {
        Text(trailingText)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
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
        .foregroundStyle(MoviePilotWidgetTheme.mutedText)
      Text(value)
        .font(.system(size: compact ? 9 : 11, weight: .bold))
        .foregroundStyle(tint)
        .minimumScaleFactor(0.72)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, compact ? 6 : 8)
    .padding(.vertical, compact ? 5 : 7)
    .background(
      RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
        .fill(MoviePilotWidgetTheme.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
        .stroke(tint.opacity(0.18), lineWidth: 0.8)
    )
    .accessibilityElement(children: .combine)

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
            .foregroundStyle(MoviePilotWidgetTheme.primaryText)
            .lineLimit(1)
          Text(site.domain)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MoviePilotWidgetTheme.mutedText)
            .lineLimit(1)
        }
        Spacer(minLength: 6)
        SiteBadge(site: site, destination: site.messageUnread > 0 ? systemMessageWidgetURL : nil)
      }
      SiteTrafficText(upload: site.upload, download: site.download, compact: false)
      if site.hasIssue, !site.errorMessage.isEmpty {
        Text(site.errorMessage)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.red)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(MoviePilotWidgetTheme.elevatedSurface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(site.badgeColor.opacity(0.24), lineWidth: 0.8)
    )
    .accessibilityElement(children: .combine)
  }
}

private struct SiteOverviewRow: View {
  let site: SiteWidgetSiteDTO
  let compact: Bool
  let ranked: Bool

  init(site: SiteWidgetSiteDTO, compact: Bool, ranked: Bool = false) {
    self.site = site
    self.compact = compact
    self.ranked = ranked
  }

  var body: some View {
    HStack(alignment: .center, spacing: 9) {
      SiteIconView(site: site, size: compact ? 28 : 34)
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(site.name)
            .font(.system(size: compact ? 12 : 14, weight: .semibold))
            .foregroundStyle(MoviePilotWidgetTheme.primaryText)
            .lineLimit(1)
          if ranked {
            Text("优先")
              .font(.system(size: 8, weight: .bold))
              .foregroundStyle(MoviePilotWidgetTheme.cyan)
              .padding(.horizontal, 5)
              .padding(.vertical, 2)
              .background(MoviePilotWidgetTheme.cyan.opacity(0.14), in: Capsule())
          }
          SiteBadge(site: site, destination: site.messageUnread > 0 ? systemMessageWidgetURL : nil)
        }
        if site.hasIssue, !site.errorMessage.isEmpty {
          Text(site.errorMessage)
            .font(.system(size: compact ? 10 : 12, weight: .medium))
            .foregroundStyle(MoviePilotWidgetTheme.red)
            .lineLimit(1)
        } else {
          SiteTrafficText(upload: site.upload, download: site.download, compact: compact)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, compact ? 7 : 8)
    .padding(.vertical, compact ? 6 : 7)
    .accessibilityElement(children: .combine)
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
        .background(site.badgeColor.opacity(0.16), in: Capsule())

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
        .fill(MoviePilotWidgetTheme.surface)
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
      .overlay(MoviePilotWidgetTheme.border)
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
        .fill(MoviePilotWidgetTheme.elevatedSurface)
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
          .foregroundStyle(MoviePilotWidgetTheme.green)
      } icon: {
        Image(systemName: "arrow.up.right")
          .font(.system(size: compact ? 9 : 10, weight: .bold))
          .foregroundStyle(MoviePilotWidgetTheme.green)
      }
      Label {
        Text(formatBytes(download))
          .font(.system(size: compact ? 9 : 11, weight: .semibold))
          .foregroundStyle(MoviePilotWidgetTheme.cyan)
      } icon: {
        Image(systemName: "arrow.down.right")
          .font(.system(size: compact ? 9 : 10, weight: .bold))
          .foregroundStyle(MoviePilotWidgetTheme.cyan)
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

private func siteHealthProgress(_ payload: SiteWidgetPayloadDTO) -> Double {
  let total = max(payload.summary.totalSites, 1)
  let onlineRatio = Double(payload.summary.enabledSites) / Double(total)
  let warningPenalty = Double(payload.summary.warningSites) / Double(total) * 0.45
  return min(max(onlineRatio - warningPenalty, 0), 1)
}

private func siteHealthTint(_ payload: SiteWidgetPayloadDTO) -> Color {
  if payload.summary.warningSites > 0 {
    return MoviePilotWidgetTheme.red
  }
  if siteHealthProgress(payload) < 0.75 {
    return MoviePilotWidgetTheme.amber
  }
  return MoviePilotWidgetTheme.green
}

private func siteHealthLabel(_ payload: SiteWidgetPayloadDTO) -> String {
  if payload.summary.warningSites > 0 {
    return "\(payload.summary.warningSites) 个站点需要处理"
  }
  if payload.summary.enabledSites < payload.summary.totalSites {
    return "部分站点离线"
  }
  return "全部站点运行正常"
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
      .padding(contentPadding)
      .moviePilotWidgetBackground()
  }

  private var contentPadding: CGFloat {
    switch family {
    case .systemSmall:
      return 13
    case .systemMedium:
      return 14
    default:
      return 15
    }
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
    WidgetStatusView(
      title: title,
      message: message,
      systemImage: title == "同步失败" ? "exclamationmark.triangle.fill" : "popcorn.fill",
      tint: title == "同步失败" ? MoviePilotWidgetTheme.red : MoviePilotWidgetTheme.amber
    )
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
        WidgetSectionHeader(
          title: "影视推荐",
          systemImage: "popcorn.fill",
          tint: MoviePilotWidgetTheme.amber,
          compact: true
        )
        Spacer()
        Text("暂无推荐")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
      }
    }
  }

  private func smallContent(_ item: RecommendCard) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      WidgetSectionHeader(
        title: "豆瓣热门",
        subtitle: scoreLabel(for: item),
        systemImage: "popcorn.fill",
        tint: MoviePilotWidgetTheme.amber,
        compact: true
      )
      Spacer(minLength: 0)
      HStack(alignment: .bottom, spacing: 9) {
        RecommendPosterThumbnail(data: item.posterData, compact: true)
        VStack(alignment: .leading, spacing: 4) {
          Text(item.title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(MoviePilotWidgetTheme.primaryText)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
          Text(item.subtitle.isEmpty ? "热门影视" : item.subtitle)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func scoreLabel(for item: RecommendCard) -> String {
    item.scoreText == "暂无评分" ? item.scoreText : "评分 \(item.scoreText)"
  }
}

private struct RecommendMediumView: View {
  let items: [RecommendCard]

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      WidgetSectionHeader(
        title: "豆瓣热门",
        subtitle: "\(items.count) 个推荐",
        systemImage: "popcorn.fill",
        tint: MoviePilotWidgetTheme.amber
      )
      HStack(spacing: 8) {
        ForEach(Array(items.prefix(2))) { item in
          RecommendFeatureCard(item: item, compact: true)
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct RecommendLargeView: View {
  let items: [RecommendCard]

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      WidgetSectionHeader(
        title: "豆瓣热门",
        subtitle: "\(items.count) 个推荐",
        systemImage: "popcorn.fill",
        tint: MoviePilotWidgetTheme.amber
      )
      if let first = items.first {
        if let url = first.widgetURL {
          Link(destination: url) {
            RecommendFeatureCard(item: first, compact: false)
          }
          .buttonStyle(.plain)
        } else {
          RecommendFeatureCard(item: first, compact: false)
        }
      }
      VStack(spacing: 6) {
        ForEach(Array(items.dropFirst().prefix(3))) { item in
          if let url = item.widgetURL {
            Link(destination: url) {
              RecommendRow(item: item)
            }
            .buttonStyle(.plain)
          } else {
            RecommendRow(item: item)
          }
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct RecommendFeatureCard: View {
  let item: RecommendCard
  let compact: Bool

  var body: some View {
    let content = HStack(alignment: .center, spacing: compact ? 8 : 11) {
      RecommendPosterThumbnail(data: item.posterData, compact: compact)
      VStack(alignment: .leading, spacing: compact ? 4 : 5) {
        Text(item.title)
          .font(.system(size: compact ? 13 : 16, weight: .bold))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
          .lineLimit(compact ? 2 : 1)
          .minimumScaleFactor(0.78)
        Text(item.subtitle.isEmpty ? "热门影视" : item.subtitle)
          .font(.system(size: compact ? 10 : 11, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
          .lineLimit(1)
        HStack(spacing: 5) {
          Image(systemName: "star.fill")
            .font(.system(size: compact ? 8 : 9, weight: .bold))
            .foregroundStyle(MoviePilotWidgetTheme.amber)
            .accessibilityHidden(true)
          Text(scoreLabel)
            .font(.system(size: compact ? 10 : 11, weight: .semibold))
            .foregroundStyle(MoviePilotWidgetTheme.amber)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, compact ? 8 : 10)
    .padding(.vertical, compact ? 8 : 10)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(MoviePilotWidgetTheme.elevatedSurface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(MoviePilotWidgetTheme.amber.opacity(0.24), lineWidth: 0.8)
    )
    .accessibilityElement(children: .combine)

    if compact, let url = item.widgetURL {
      Link(destination: url) {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }

  private var scoreLabel: String {
    item.scoreText == "暂无评分" ? item.scoreText : "评分 \(item.scoreText)"
  }
}

private struct RecommendRow: View {
  let item: RecommendCard

  var body: some View {
    HStack(alignment: .center, spacing: 9) {
      RecommendPosterThumbnail(data: item.posterData, compact: true)
      VStack(alignment: .leading, spacing: 3) {
        Text(item.title)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(MoviePilotWidgetTheme.primaryText)
          .lineLimit(1)
        Text(item.subtitle.isEmpty ? "热门影视" : item.subtitle)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(MoviePilotWidgetTheme.secondaryText)
          .lineLimit(1)
        Text(item.scoreText == "暂无评分" ? item.scoreText : "评分 \(item.scoreText)")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(MoviePilotWidgetTheme.amber)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 9)
    .padding(.vertical, 7)
    .background(MoviePilotWidgetTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}

private struct RecommendPosterThumbnail: View {
  let data: Data?
  let compact: Bool

  var body: some View {
    RecommendPosterBackground(data: data)
      .frame(width: compact ? 44 : 56, height: compact ? 60 : 76)
      .clipShape(RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous)
          .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
      )
  }
}

private struct RecommendPosterBackground: View {
  let data: Data?

  var body: some View {
    ZStack {
      MoviePilotWidgetTheme.surface
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
      MoviePilotWidgetTheme.elevatedSurface
      Image(systemName: "film")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(MoviePilotWidgetTheme.amber)
    }
  }
}

private extension View {
  @ViewBuilder
  func moviePilotWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        MoviePilotWidgetTheme.backgroundGradient
      }
    } else {
      background(MoviePilotWidgetTheme.backgroundGradient)
    }
  }

  @ViewBuilder
  func siteInfoWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        Color.white
      }
    } else {
      background(Color.white)
    }
  }
}
