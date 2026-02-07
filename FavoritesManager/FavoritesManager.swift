//
//  FavoritesManager.swift
//  LiveStats
//
//  Created by eleni on 2/1/26.
//

import Combine
import Foundation
import SwiftUI

class FavoritesManager: ObservableObject {
    @Published var savedPlayers: [FavoritePlayer] = []
    
    // Changed key to v4 to reset data for the new structure
    private let key = "saved_players_v4"
    
    init() { load() }
    
    // MARK: - ADD / REMOVE PLAYER
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
    
    func removeFavorite(withId id: Int) {
        savedPlayers.removeAll { $0.id == id }
        save()
    }
    
    // MARK: - MISSING FUNCTION FIXED HERE
    func isFavorite(playerId: Int) -> Bool {
        return savedPlayers.contains(where: { $0.id == playerId })
    }
    
    // MARK: - MANAGE TARGETS (PTS, REB, AST)
    
    // 1. Update the number (e.g., change PTS from 20 to 25)
    func updateTarget(playerId: Int, type: StatType, value: Double) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        
        savedPlayers[idx].targets[type] = value
        // Reset notification for this specific stat since the target changed
        savedPlayers[idx].notifiedStats.remove(type)
        save()
    }
    
    // 2. Add a new stat line (e.g., User adds "Rebounds")
    func addStatType(playerId: Int, type: StatType) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        
        if savedPlayers[idx].targets[type] == nil {
            // Set default values
            let def: Double = (type == .points) ? 20.0 : 6.0
            savedPlayers[idx].targets[type] = def
            save()
        }
    }
    
    // 3. Remove a stat line (e.g., User deletes "Assists")
    func removeStatType(playerId: Int, type: StatType) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        
        savedPlayers[idx].targets.removeValue(forKey: type)
        savedPlayers[idx].notifiedStats.remove(type)
        save()
    }
    
    // MARK: - NOTIFICATIONS
    func markAsNotified(playerId: Int, type: StatType) {
        guard let idx = savedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        savedPlayers[idx].notifiedStats.insert(type)
        save()
    }
    
    func cleanupOldFavorites(validTeamIds: Set<Int>) {
        guard !validTeamIds.isEmpty else { return }
        let initialCount = savedPlayers.count
        savedPlayers.removeAll { !validTeamIds.contains($0.teamId) }
        if savedPlayers.count != initialCount { save() }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(savedPlayers) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FavoritePlayer].self, from: data) {
            savedPlayers = decoded
        }
    }
}
