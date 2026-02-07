//
//  ScheduleViewModel.swift
//  LiveStats
//
//  Created by eleni on 2/1/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var isLoading = false
    @Published var dateString: String = ""
    
    func fetchSchedule() {
        self.isLoading = true
        
        // This URL resets daily around 6am ET
        guard let url = URL(string: "https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json") else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(ScheduleResponse.self, from: data)
                
                self.games = decoded.scoreboard.games
                self.dateString = decoded.scoreboard.gameDate
                self.isLoading = false
            } catch {
                print("Error fetching schedule: \(error)")
                self.isLoading = false
            }
        }
    }
}
