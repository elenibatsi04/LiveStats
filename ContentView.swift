import SwiftUI

@main
struct LiveStatsApp: App {
    @StateObject var favManager = FavoritesManager()
        
        init() {
            // Request Notification Permission on Launch
            NotificationManager.shared.requestPermission()
        }
        
        var body: some Scene {
            WindowGroup {
                TabView {
                    ScheduleView()
                        .tabItem { Label("Games", systemImage: "sportscourt") }
                    
                    FavoritesView()
                        .tabItem { Label("Prop Tracker", systemImage: "chart.bar.fill") }
                }
                .environmentObject(favManager)
            }
        }
    }
