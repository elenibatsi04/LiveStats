import SwiftUI

@main
struct LiveStatsApp: App {
    // one favorites manager for the whole app, gets passed down below
    @StateObject var favManager = FavoritesManager()

    init() {
        // ask for notification permission when the app opens
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                // first tab = todays games
                ScheduleView()
                    .tabItem { Label("Games", systemImage: "sportscourt") }

                // second tab = the stars / targets thing
                FavoritesView()
                    .tabItem { Label("Prop Tracker", systemImage: "chart.bar.fill") }
            }
            // so every view can use favManager without passing it around
            .environmentObject(favManager)
        }
    }
}
