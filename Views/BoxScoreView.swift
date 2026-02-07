//
//  BoxScoreView.swift
//  LiveStats
//
//  Created by eleni on 2/1/26.
//


import SwiftUI

struct BoxScoreView: View {
    @StateObject var viewModel: BoxScoreViewModel
    @State private var selectedTeamIndex = 0 // 0 = Home, 1 = Away
    
    init(gameId: String) {
        _viewModel = StateObject(wrappedValue: BoxScoreViewModel(gameId: gameId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. Score Header
            if let home = viewModel.homeTeam, let away = viewModel.awayTeam {
                ScoreHeaderView(home: home, away: away)
                    .padding(.bottom)
            }
            
            // 2. Team Picker
            Picker("Team", selection: $selectedTeamIndex) {
                Text(viewModel.homeTeam?.teamName ?? "Home").tag(0)
                Text(viewModel.awayTeam?.teamName ?? "Away").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)
            
            // 3. Stats Column Headers
            HStack {
                Text("PLAYER").font(.caption).bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("MIN").font(.caption).bold().frame(width: 40)
                Text("PTS").font(.caption).bold().frame(width: 40)
                Text("REB").font(.caption).bold().frame(width: 40)
                Text("AST").font(.caption).bold().frame(width: 40)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // 4. Player List
            if viewModel.isLoading && viewModel.homeTeam == nil {
                ProgressView().padding(.top, 50)
                Spacer()
            } else if let activeTeam = (selectedTeamIndex == 0 ? viewModel.homeTeam : viewModel.awayTeam) {
                List(activeTeam.players) { player in
                    PlayerRow(
                        player: player,
                        teamId: activeTeam.teamId,
                        teamName: activeTeam.teamName
                    )
                }
                .listStyle(.plain)
            } else {
                Text(viewModel.errorMessage ?? "Loading...")
                    .padding(.top, 50)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .navigationTitle("Live Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startLiveUpdates()
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
    }
}

// Helper Subviews
struct ScoreHeaderView: View {
    let home: TeamBoxData
    let away: TeamBoxData
    
    var body: some View {
        HStack {
            // Home (Left)
            VStack {
                Text(home.teamCity).font(.caption).foregroundColor(.gray)
                Text(home.teamName).font(.headline)
                Text("\(home.score)").font(.system(size: 34, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            
            Text("VS").font(.caption).bold().foregroundColor(.gray)
            
            // Away (Right)
            VStack {
                Text(away.teamCity).font(.caption).foregroundColor(.gray)
                Text(away.teamName).font(.headline)
                Text("\(away.score)").font(.system(size: 34, weight: .bold))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}

// In BoxScoreView.swift

struct PlayerRow: View {
    let player: Player
    let teamId: Int
    let teamName: String
    
    // Inject the FavoritesManager
    @EnvironmentObject var favManager: FavoritesManager
    
    var body: some View {
        HStack {
            // 1. Favorite Button (Star)
            Button(action: {
                favManager.toggleFavorite(player: player, teamId: teamId, teamName: teamName)
            }) {
                Image(systemName: favManager.isFavorite(playerId: player.id) ? "star.fill" : "star")
                    .foregroundColor(favManager.isFavorite(playerId: player.id) ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // Prevents clicking the row when clicking star
            .padding(.trailing, 4)
            
            // 2. Headshot
            AsyncImage(url: player.headshotURL) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 40, height: 29)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            // 3. Name
            VStack(alignment: .leading) {
                Text(player.fullName)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                Text("#\(player.jerseyNum) • \(player.position ?? "-")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 4. Stats
            let mins = player.statistics.minutes.prefix(5).replacingOccurrences(of: "PT", with: "")
            Text(mins).font(.system(size: 13, design: .monospaced)).frame(width: 40)
            Text("\(player.statistics.points)").bold().frame(width: 40)
            Text("\(player.statistics.reboundsTotal)").frame(width: 40)
            Text("\(player.statistics.assists)").frame(width: 40)
        }
        .padding(.vertical, 4)
    }
}
