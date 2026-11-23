//
//  ScheduleViewModel.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//


import Foundation
import SwiftUI
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?   // shows on screen if something breaks
    @Published var dateString: String = ""

    private var timer: Timer?

    func fetchSchedule() async {
        // only show the big spinner the first time, not on every refresh
        if games.isEmpty { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        // this link switches to the next day around 6am ET
        guard let url = URL(string: "https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json") else { return }

        var request = URLRequest(url: url)
        // dont use the cached copy, we want fresh scores
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // the nba server sometimes rejects plain app requests, so look like a browser
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://www.nba.com/", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // if the server answered with an error page, say so instead of failing to decode
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("Schedule HTTP \(http.statusCode):", String(data: data.prefix(300), encoding: .utf8) ?? "")
                errorMessage = "Server returned \(http.statusCode)"
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ScheduleResponse.self, from: data)
                games = decoded.scoreboard.games
                dateString = decoded.scoreboard.gameDate
            } catch {
                // shows in the xcode console so we can see what the server really sent
                print("Decode error:", error)
                print("Body starts with:", String(data: data.prefix(300), encoding: .utf8) ?? "")
                errorMessage = "Couldn't read game data"
            }
        } catch {
            print("Network error:", error)
            errorMessage = "Couldn't load games: \(error.localizedDescription)"
        }
    }

    // refresh the scores every 30 sec while the screen is open
    func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.fetchSchedule() }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
}
