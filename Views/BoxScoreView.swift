//
//  BoxScoreView.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//


import SwiftUI

struct BoxScoreView: View {
    @StateObject var viewModel: BoxScoreViewModel
    @State private var selectedTeamIndex = 0 // 0 = home, 1 = away

    init(gameId: String) {
        _viewModel = StateObject(wrappedValue: BoxScoreViewModel(gameId: gameId))
    }

    var body: some View {
        VStack(spacing: 0) {

            // 1. score at the top
            if let home = viewModel.homeTeam, let away = viewModel.awayTeam {
                ScoreHeaderView(home: home, away: away)
                    .padding(.bottom)
            }

            // 2. switch between the two teams
            Picker("Team", selection: $selectedTeamIndex) {
                Text(viewModel.homeTeam?.teamName ?? "Home").tag(0)
                Text(viewModel.awayTeam?.teamName ?? "Away").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)

            // 3. column titles
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

            // 4. the actual player list
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
                // nothing yet, usually the game hasnt started
                Text(viewModel.errorMessage ?? "Loading...")
                    .padding(.top, 50)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .navigationTitle("Live Stats")
        .navigationBarTitleDisplayMode(.inline)
        // start polling when the screen opens, stop when it closes
        .onAppear {
            viewModel.startLiveUpdates()
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
    }
}

// score header with both teams
struct ScoreHeaderView: View {
    let home: TeamBoxData
    let away: TeamBoxData

    var body: some View {
        HStack {
            // home on the left here
            VStack {
                Text(home.teamCity).font(.caption).foregroundColor(.gray)
                Text(home.teamName).font(.headline)
                Text("\(home.score)").font(.system(size: 34, weight: .bold))
            }
            .frame(maxWidth: .infinity)

            Text("VS").font(.caption).bold().foregroundColor(.gray)

            // away on the right
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

// one player in the list
struct PlayerRow: View {
    let player: Player
    let teamId: Int
    let teamName: String

    // gets the favorites manager from ContentView
    @EnvironmentObject var favManager: FavoritesManager

    var body: some View {
        HStack {
            // star button to add to favorites
            Button(action: {
                favManager.toggleFavorite(player: player, teamId: teamId, teamName: teamName)
            }) {
                Image(systemName: favManager.isFavorite(playerId: player.id) ? "star.fill" : "star")
                    .foregroundColor(favManager.isFavorite(playerId: player.id) ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // without this the whole row gets tapped
            .padding(.trailing, 4)

            // headshot, grey circle while its loading
            AsyncImage(url: player.headshotURL) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 40, height: 29)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))

            // name + number and position
            VStack(alignment: .leading) {
                Text(player.fullName)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                Text("#\(player.jerseyNum) • \(player.position ?? "-")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // the numbers
            // minutes come as something like "PT24M30.00S" so cut it down
            let mins = player.statistics.minutes.prefix(5).replacingOccurrences(of: "PT", with: "")
            Text(mins).font(.system(size: 13, design: .monospaced)).frame(width: 40)
            Text("\(player.statistics.points)").bold().frame(width: 40)
            Text("\(player.statistics.reboundsTotal)").frame(width: 40)
            Text("\(player.statistics.assists)").frame(width: 40)
        }
        .padding(.vertical, 4)
    }
}
