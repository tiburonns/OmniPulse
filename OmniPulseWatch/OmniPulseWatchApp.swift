import SwiftUI

@main
struct OmniPulseWatchApp: App {
    @State private var connectivity = WatchConnectivityClient()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(connectivity)
        }
    }
}
