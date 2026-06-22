import SwiftUI
import WidgetKit

@main
struct MoviePilotWidgetsBundle: WidgetBundle {
  var body: some Widget {
    SubscribeCalendarWidget()
    SiteOverviewWidget()
    RecommendTrendingWidget()
  }
}
