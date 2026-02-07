//
//  FavoritesView.swift
//  LiveStats
//
//  Created by eleni on 2/1/26.
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
                            ForEach(favManager.savedPlayers) { player in
                                // We pass the full Stats object to the card now
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
            .onAppear {
                trackerModel.refreshAll(favoritesManager: favManager)
            }
        }
    }
}

// MARK: - THE PROP CARD
struct PropCard: View {
    let player: FavoritePlayer
    let stats: PlayerStats? // Can be nil if game hasn't started
    @EnvironmentObject var favManager: FavoritesManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. HEADER (Player Info)
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
                
                // Trash Button (Remove Player)
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
            
            // 2. STAT LIST (The "Sheet")
            VStack(spacing: 0) {
                // Loop through every stat the user added (PTS, AST, etc.)
                // sort them so they don't jump around
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
                
                // 3. ADD BUTTON (Footer)
                HStack {
                    Menu {
                        // Only show options not already added
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
    
    // Helper to extract safely
    func getCurrentValue(type: StatType) -> Int {
        guard let s = stats else { return 0 }
        switch type {
        case .points: return s.points
        case .rebounds: return s.reboundsTotal
        case .assists: return s.assists
        }
    }
    
    // Helper view for Menu
    func ButtonLabel(type: StatType, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Add \(type.rawValue)", systemImage: "chart.bar")
        }
    }
}

// MARK: - INDIVIDUAL ROW (The "Slider" replacement)
struct PropRow: View {
    let player: FavoritePlayer
    let statType: StatType
    let targetVal: Double
    let currentVal: Int
    @EnvironmentObject var favManager: FavoritesManager
    
    var body: some View {
        HStack {
            // A. Stat Name & Current Value
            VStack(alignment: .leading) {
                Text(statType.rawValue)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(currentVal)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(currentVal >= Int(targetVal) ? .green : .primary)
                    Text("/ \(Int(targetVal))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // B. Simple Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                    let pct = min(CGFloat(currentVal) / CGFloat(max(targetVal, 1)), 1.0)
                    Capsule().fill(currentVal >= Int(targetVal) ? Color.green : Color.blue)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 8)
            
            Spacer()
            
            // C. Target Stepper (Inputs)
            Stepper("", value: Binding(
                get: { targetVal },
                set: { newVal in
                    favManager.updateTarget(playerId: player.id, type: statType, value: newVal)
                }
            ), in: 0...100, step: 1)
            .labelsHidden() // Hide the text, just show +/- buttons
            
            // D. Remove Stat Button (X)
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

// MARK: - VIEW MODEL
@MainActor
class PropTrackerViewModel: ObservableObject {
    @Published var liveStats: [Int: PlayerStats] = [:]
    
    func refreshAll(favoritesManager: FavoritesManager) {
        Task {
            guard let url = URL(string: "https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json") else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ScheduleResponse.self, from: data)
                
                // Cleanup old players
                var validTeamIds = Set<Int>()
                for game in response.scoreboard.games {
                    validTeamIds.insert(game.homeTeam.teamId)
                    validTeamIds.insert(game.awayTeam.teamId)
                }
                favoritesManager.cleanupOldFavorites(validTeamIds: validTeamIds)
                
                // Fetch Stats
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
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return }
            
            let box = try JSONDecoder().decode(BoxScoreResponse.self, from: data)
            let allPlayers = box.game.homeTeam.players + box.game.awayTeam.players
            
            if let stats = allPlayers.first(where: { $0.personId == player.id }) {
                self.liveStats[player.id] = stats.statistics
                
                // NEW: Loop through ALL targets to check notifications
                for (type, targetVal) in player.targets {
                    let currentVal: Int
                    switch type {
                    case .points: currentVal = stats.statistics.points
                    case .rebounds: currentVal = stats.statistics.reboundsTotal
                    case .assists: currentVal = stats.statistics.assists
                    }
                    
                    // Check if hit AND not notified for this specific stat
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
