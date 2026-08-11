import Observation

@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .scan
}
