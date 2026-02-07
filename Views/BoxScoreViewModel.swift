//
//  BoxScoreViewModel.swift
//  LiveStats
//
//  Created by eleni on 2/1/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BoxScoreViewModel: ObservableObject {
    @Published var homeTeam: TeamBoxData?
    @Published var awayTeam: TeamBoxData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private let gameId: String
    
    init(gameId: String) {
        self.gameId = gameId
    }
    
    func startLiveUpdates() {
        fetchData() // Immediate fetch
        // Poll every 15 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            Task {
                await self.fetchData()
            }
        }
    }
    
    func stopLiveUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchData() {
        guard let url = URL(string: "https://cdn.nba.com/static/json/liveData/boxscore/boxscore_\(gameId).json") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(BoxScoreResponse.self, from: data)
                
                self.homeTeam = decoded.game.homeTeam
                self.awayTeam = decoded.game.awayTeam
                self.isLoading = false
            } catch {
                print("Error fetching box score: \(error)")
                if self.homeTeam == nil {
                    self.errorMessage = "Waiting for game to start..."
                }
            }
        }
    }
}
