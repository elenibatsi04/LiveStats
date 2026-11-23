//
//  ScheduleView.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//


import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()

    // the feed gives the date like 2026-11-23 so this makes it readable
    // falls back to the phones date if it cant read it
    var headerDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        if let d = parser.date(from: viewModel.dateString) {
            return d.formatted(date: .long, time: .omitted)
        }
        return Date().formatted(date: .long, time: .omitted)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // top header with the title and date
                HStack {
                    Text("Today's Schedule")
                        .font(.title2)
                        .bold()

                    Spacer()

                    Text(headerDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))

                Divider() // thin line under the header

                // three cases: loading, nothing to show, or the list
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
                        // shows the real error if there is one
                        Text(viewModel.errorMessage ?? "The season might be paused or finished.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    List(viewModel.games) { game in
                        // tap a game to open its box score
                        NavigationLink(destination: BoxScoreView(gameId: game.gameId)) {
                            GameSummaryRow(game: game)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        // pull down to reload
                        await viewModel.fetchSchedule()
                    }
                }
            }
            .navigationBarHidden(true) // dont need the default nav bar here
        }
        .task { await viewModel.fetchSchedule() }
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
    }
}

// one row in the games list
struct GameSummaryRow: View {
    let game: GameSummary

    var body: some View {
        HStack {
            // away team on the left
            VStack(alignment: .leading) {
                Text(game.awayTeam.teamCity).font(.caption).foregroundColor(.gray)
                Text(game.awayTeam.teamName).font(.headline)
                Text("\(game.awayTeam.wins)-\(game.awayTeam.losses)")
                    .font(.caption2).foregroundColor(.secondary)
            }

            Spacer()

            // middle: start time if it hasnt started, otherwise the score
            VStack {
                if game.gameStatusText.contains("ET") {
                    // upcoming games say something like "7:30 pm ET" so show local time instead
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
                    // grey for final, red for live
                    Text(game.gameStatusText)
                        .font(.caption)
                        .foregroundColor(game.gameStatusText.contains("Final") ? .secondary : .red)
                }
            }

            Spacer()

            // home team on the right
            VStack(alignment: .trailing) {
                Text(game.homeTeam.teamCity).font(.caption).foregroundColor(.gray)
                Text(game.homeTeam.teamName).font(.headline)
                Text("\(game.homeTeam.wins)-\(game.homeTeam.losses)")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // turns the utc time string into the users local time
    func convertTime(_ utcString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        if let date = isoFormatter.date(from: utcString) {
            let localFormatter = DateFormatter()
            localFormatter.dateFormat = "HH:mm" // 24h, like 14:30
            localFormatter.timeZone = TimeZone.current
            return localFormatter.string(from: date)
        }
        return "TBD"
    }
}
