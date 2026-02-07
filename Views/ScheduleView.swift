import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - 1. NEW CLEAN HEADER (No Selection)
                HStack {
                    Text("Today's Schedule")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    // Displays the current date nicely (e.g., "Jan 2, 2026")
                    Text(Date().formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider() // A subtle line to separate header from list
                
                // MARK: - 2. CONTENT
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Games...")
                    Spacer()
                } else if viewModel.games.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No games scheduled")
                            .font(.headline)
                        Text("The season might be paused or finished.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(viewModel.games) { game in
                        NavigationLink(destination: BoxScoreView(gameId: game.gameId)) {
                            GameSummaryRow(game: game)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        // Useful feature: Pull down to reload scores
                        viewModel.fetchSchedule()
                    }
                }
            }
            .navigationBarHidden(true) // Hides the default "Back" bar
        }
        .onAppear {
            viewModel.fetchSchedule()
        }
    }
}

// Subview: The List Row (Unchanged)
struct GameSummaryRow: View {
    let game: GameSummary
    
    var body: some View {
        HStack {
            // Away Team
            VStack(alignment: .leading) {
                Text(game.awayTeam.teamCity).font(.caption).foregroundColor(.gray)
                Text(game.awayTeam.teamName).font(.headline)
                Text("\(game.awayTeam.wins)-\(game.awayTeam.losses)")
                    .font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score / Time
            VStack {
                if game.gameStatusText.contains("ET") {
                    // Convert ET time to Local Time
                    Text(convertTime(game.gameTimeUTC))
                        .font(.system(size: 14, weight: .bold))
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    HStack(spacing: 15) {
                        Text("\(game.awayTeam.score)").font(.title2).bold()
                        Text("\(game.homeTeam.score)").font(.title2).bold()
                    }
                    Text(game.gameStatusText)
                        .font(.caption)
                        .foregroundColor(game.gameStatusText.contains("Final") ? .secondary : .red)
                }
            }
            
            Spacer()
            
            // Home Team
            VStack(alignment: .trailing) {
                Text(game.homeTeam.teamCity).font(.caption).foregroundColor(.gray)
                Text(game.homeTeam.teamName).font(.headline)
                Text("\(game.homeTeam.wins)-\(game.homeTeam.losses)")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Time Converter Helper
    func convertTime(_ utcString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: utcString) {
            let localFormatter = DateFormatter()
            localFormatter.dateFormat = "HH:mm" // e.g. 14:30
            localFormatter.timeZone = TimeZone.current
            return localFormatter.string(from: date)
        }
        return "TBD"
    }
}
