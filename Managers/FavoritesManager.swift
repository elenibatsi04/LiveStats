//
//  FavoritesManager.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//


import Combine
import Foundation
import SwiftUI

class FavoritesManager: ObservableObject {
    // the list of starred players, views update when this changes
    @Published var savedPlayers: [FavoritePlayer] = []

    // bumped the version when i changed the structure so old saved data doesnt crash it
    private let key = "saved_players_v4"

    init() { load() }

    // MARK: - add / remove player
    // tapping the star: if already saved remove it, otherwise add it
    func toggleFavorite(player: Player, teamId: Int, teamName: String) {
        if let index = savedPlayers.firstIndex(where: { $0.id == player.id }) {
            savedPlayers.remove(at: index)
        } else {
            let newFav = FavoritePlayer(
                id: player.id,
                name: player.fullName,
                teamName: teamName,
                jersey: player.jerseyNum,
                headshotURL: player.headshotURL,
                teamId: teamId
            )
            savedPlayers.append(newFav)
        }
        save()
    }

    // the x button on the card
    func removeFavorite(withId id: Int) {
        savedPlayers.removeAll { $0.id == id }
        save()
    }

    // used to decide if the star is filled in or not
    func isFavorite(playerId: Int) -> Bool {
        return savedPlayers.contains(where: { $0.id == playerId })
    }

    // MARK: - targets (pts, reb, ast)

    // change the target number with the stepper
    func updateTarget(playerId: Int, type: StatType, value: Double) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }

        savedPlayers[idx].targets[type] = value
        // target changed so it can notify again
        savedPlayers[idx].notifiedStats.remove(type)
        save()
    }

    // add a new stat row, like rebounds
    func addStatType(playerId: Int, type: StatType) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }

        if savedPlayers[idx].targets[type] == nil {
            // 20 for points, 6 for the others
            let def: Double = (type == .points) ? 20.0 : 6.0
            savedPlayers[idx].targets[type] = def
            save()
        }
    }

    // remove a stat row (the minus button)
    func removeStatType(playerId: Int, type: StatType) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }

        savedPlayers[idx].targets.removeValue(forKey: type)
        savedPlayers[idx].notifiedStats.remove(type)
        save()
    }

    // MARK: - notifications
    // remember we already sent the alert for this stat
    func markAsNotified(playerId: Int, type: StatType) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        savedPlayers[idx].notifiedStats.insert(type)
        save()
    }

    // removes players whose team isnt playing today
    // NOTE: this wipes favorites on off days, might remove this later
    func cleanupOldFavorites(validTeamIds: Set<Int>) {
        guard !validTeamIds.isEmpty else { return }
        let initialCount = savedPlayers.count
        savedPlayers.removeAll { !validTeamIds.contains($0.teamId) }
        if savedPlayers.count != initialCount { save() }
    }

    // saves to UserDefaults as json
    private func save() {
        if let encoded = try? JSONEncoder().encode(savedPlayers) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    // loads whatever was saved last time
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FavoritePlayer].self, from: data) {
            savedPlayers = decoded
        }
    }
}
