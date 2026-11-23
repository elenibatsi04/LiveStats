//
//  BoxScoreViewModel.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
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
        fetchData() // get data right away
        // then again every 15 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            Task {
                await self.fetchData()
            }
        }
    }

    // stop the timer when leaving the screen so it doesnt keep running
    func stopLiveUpdates() {
        timer?.invalidate()
        timer = nil
    }

    func fetchData() {
        // each game has its own box score file based on the game id
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
                // the file usually doesnt exist until the game is about to start
                if self.homeTeam == nil {
                    self.errorMessage = "Waiting for game to start..."
                }
            }
        }
    }
}
