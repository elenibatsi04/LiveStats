//
//  FavoritesView.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//


import Combine
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favManager: FavoritesManager
    @StateObject private var trackerModel = PropTrackerViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if favManager.savedPlayers.isEmpty {
                    // nothing starred yet
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No active props")
                            .font(.headline)
                        Text("Go to Schedule > Game > Star a player")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // one card per starred player
                            ForEach(favManager.savedPlayers) { player in
                                PropCard(
                                    player: player,
                                    stats: trackerModel.liveStats[player.id]
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Props")
            // refresh the stats every time you open the tab
            .onAppear {
                trackerModel.refreshAll(favoritesManager: favManager)
            }
        }
    }
}

// the card for each player
struct PropCard: View {
    let player: FavoritePlayer
    let stats: PlayerStats? // nil if the game hasnt started
    @EnvironmentObject var favManager: FavoritesManager

    var body: some View {
        VStack(spacing: 0) {
            // top part with the player info
            HStack {
                AsyncImage(url: player.headshotURL) { img in img.resizable() } placeholder: { Color.gray }
                    .frame(width: 45, height: 35)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))

                VStack(alignment: .leading) {
                    Text(player.name).font(.headline)
                    Text(player.teamName).font(.caption).foregroundColor(.secondary)
                }

                Spacer()

                // x button removes the player
                Button(action: {
                    withAnimation { favManager.removeFavorite(withId: player.id) }
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            Divider()

            // the list of stats (pts, reb, ast)
            VStack(spacing: 0) {
                // sorted so the rows dont jump around
                let sortedTargets = player.targets.sorted(by: { $0.key.rawValue < $1.key.rawValue })

                ForEach(sortedTargets, id: \.key) { (statType, targetVal) in
                    PropRow(
                        player: player,
                        statType: statType,
                        targetVal: targetVal,
                        currentVal: getCurrentValue(type: statType)
                    )
                    Divider()
                }

                // add stat button at the bottom
                HStack {
                    Menu {
                        // only list the ones you havent added yet
                        ForEach(StatType.allCases, id: \.self) { type in
                            if player.targets[type] == nil {
                                ButtonLabel(type: type) {
                                    favManager.addStatType(playerId: player.id, type: type)
                                }
                            }
                        }
                    } label: {
                        Label("Add Stat", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // gets the current number for a stat, 0 if we have no stats yet
    func getCurrentValue(type: StatType) -> Int {
        guard let s = stats else { return 0 }
        switch type {
        case .points: return s.points
        case .rebounds: return s.reboundsTotal
        case .assists: return s.assists
        }
    }

    // little helper so the menu code isnt so messy
    func ButtonLabel(type: StatType, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Add \(type.rawValue)", systemImage: "chart.bar")
        }
    }
}

// one stat row, like PTS 12 / 20
struct PropRow: View {
    let player: FavoritePlayer
    let statType: StatType
    let targetVal: Double
    let currentVal: Int
    @EnvironmentObject var favManager: FavoritesManager

    var body: some View {
        HStack {
            // stat name and current number
            VStack(alignment: .leading) {
                Text(statType.rawValue)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(currentVal)")
                        .font(.title3)
                        .bold()
                        // goes green once the target is hit
                        .foregroundColor(currentVal >= Int(targetVal) ? .green : .primary)
                    Text("/ \(Int(targetVal))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            // progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                    // max(..., 1) so we never divide by zero
                    let pct = min(CGFloat(currentVal) / CGFloat(max(targetVal, 1)), 1.0)
                    Capsule().fill(currentVal >= Int(targetVal) ? Color.green : Color.blue)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 8)

            Spacer()

            // +/- to change the target
            Stepper("", value: Binding(
                get: { targetVal },
                set: { newVal in
                    favManager.updateTarget(playerId: player.id, type: statType, value: newVal)
                }
            ), in: 0...100, step: 1)
            .labelsHidden() // hides the text, only the buttons show

            // minus button removes this stat row
            Button(action: {
                favManager.removeStatType(playerId: player.id, type: statType)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.leading, 4)
        }
        .padding(12)
        .background(Color(.systemBackground))
    }
}

// gets the live stats for the starred players
@MainActor
class PropTrackerViewModel: ObservableObject {
    // player id -> their stats right now
    @Published var liveStats: [Int: PlayerStats] = [:]

    func refreshAll(favoritesManager: FavoritesManager) {
        Task {
            // first get todays games so we know which game each player is in
            guard let url = URL(string: "https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json") else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ScheduleResponse.self, from: data)

                // collect the teams that play today
                var validTeamIds = Set<Int>()
                for game in response.scoreboard.games {
                    validTeamIds.insert(game.homeTeam.teamId)
                    validTeamIds.insert(game.awayTeam.teamId)
                }
                // drops players whose team isnt playing (see note in FavoritesManager)
                favoritesManager.cleanupOldFavorites(validTeamIds: validTeamIds)

                // then get the box score for each starred players game
                for fav in favoritesManager.savedPlayers {
                    if let game = response.scoreboard.games.first(where: { $0.homeTeam.teamId == fav.teamId || $0.awayTeam.teamId == fav.teamId }) {
                        await self.fetchBoxScore(gameId: game.gameId, player: fav, manager: favoritesManager)
                    }
                }
            } catch { print("Error: \(error)") }
        }
    }

    func fetchBoxScore(gameId: String, player: FavoritePlayer, manager: FavoritesManager) async {
        guard let url = URL(string: "https://cdn.nba.com/static/json/liveData/boxscore/boxscore_\(gameId).json") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            // ignore it if the server didnt give a normal response
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return }

            let box = try JSONDecoder().decode(BoxScoreResponse.self, from: data)
            let allPlayers = box.game.homeTeam.players + box.game.awayTeam.players

            // find our player in the box score
            if let stats = allPlayers.first(where: { $0.personId == player.id }) {
                self.liveStats[player.id] = stats.statistics

                // check every target the user set
                for (type, targetVal) in player.targets {
                    let currentVal: Int
                    switch type {
                    case .points: currentVal = stats.statistics.points
                    case .rebounds: currentVal = stats.statistics.reboundsTotal
                    case .assists: currentVal = stats.statistics.assists
                    }

                    // hit the target and no alert sent yet -> send one
                    if Double(currentVal) >= targetVal && !player.notifiedStats.contains(type) {
                        NotificationManager.shared.sendNotification(
                            title: "Hit! \(player.name) ✅",
                            body: "Reached \(currentVal) \(type.rawValue)"
                        )
                        manager.markAsNotified(playerId: player.id, type: type)
                    }
                }
            }
        } catch { print("Error: \(error)") }
    }
}
