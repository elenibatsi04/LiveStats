//
//  Models.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//

import Foundation

// MARK: - SHARED MODELS
// all the structs that match the nba json live in here

// MARK: - Schedule Models

struct ScheduleResponse: Decodable { let scoreboard: Scoreboard }

struct Scoreboard: Decodable {
    let gameDate: String
    let games: [GameSummary]
}

struct GameSummary: Decodable, Identifiable {
    let gameId: String
    let gameStatusText: String
    let gameTimeUTC: String
    let homeTeam: TeamSummary
    let awayTeam: TeamSummary

    var id: String { gameId } // List needs an id
}

struct TeamSummary: Decodable {
    let teamId: Int
    let teamName: String
    let teamCity: String
    let score: Int
    let wins: Int
    let losses: Int

    enum CodingKeys: String, CodingKey {
        case teamId, teamName, teamCity, score, wins, losses
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        teamId   = try c.decode(Int.self, forKey: .teamId) // this one we really need
        teamName = (try? c.decode(String.self, forKey: .teamName)) ?? ""
        teamCity = (try? c.decode(String.self, forKey: .teamCity)) ?? ""
        score    = (try? c.decode(Int.self, forKey: .score)) ?? 0 // 0 before tipoff
        wins     = (try? c.decode(Int.self, forKey: .wins)) ?? 0
        losses   = (try? c.decode(Int.self, forKey: .losses)) ?? 0
    }
}

// MARK: - Box Score Models

struct BoxScoreResponse: Decodable {
    let game: GameCore
}

struct GameCore: Decodable {
    let gameId: String
    let homeTeam: TeamBoxData
    let awayTeam: TeamBoxData
}

struct TeamBoxData: Decodable {
    let teamId: Int
    let teamName: String
    let teamCity: String
    let score: Int
    let players: [Player]
}

struct Player: Decodable, Identifiable {
    let personId: Int
    let firstName: String
    let familyName: String
    let jerseyNum: String
    let position: String?
    let statistics: PlayerStats

    var id: Int { personId }
    var fullName: String { "\(firstName) \(familyName)" } // first + last
    // headshot pic is built from the player id
    var headshotURL: URL? {
        URL(string: "https://ak-static.cms.nba.com/wp-content/uploads/headshots/nba/latest/260x190/\(personId).png")
    }

    enum CodingKeys: String, CodingKey {
        case personId, firstName, familyName, jerseyNum, position, statistics
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        personId   = try c.decode(Int.self, forKey: .personId)
        firstName  = (try? c.decode(String.self, forKey: .firstName)) ?? ""
        familyName = (try? c.decode(String.self, forKey: .familyName)) ?? ""
        jerseyNum  = (try? c.decode(String.self, forKey: .jerseyNum)) ?? "-"
        position   = try? c.decode(String.self, forKey: .position)
        statistics = (try? c.decode(PlayerStats.self, forKey: .statistics)) ?? .empty // bench guys can have no stats yet
    }
}

struct PlayerStats: Decodable {
    let points: Int
    let assists: Int
    let reboundsTotal: Int
    let minutes: String

    // all zeros, used when a player has no stats
    static let empty = PlayerStats(points: 0, assists: 0, reboundsTotal: 0, minutes: "")
}

// MARK: - Favorites Models

// the stats you can set a target for
enum StatType: String, Codable, CaseIterable {
    case points = "PTS"
    case rebounds = "REB"
    case assists = "AST"
}

struct FavoritePlayer: Identifiable, Codable {
    let id: Int
    let name: String
    let teamName: String
    let jersey: String
    let headshotURL: URL?
    let teamId: Int

    // key is the stat (PTS) and value is the target number (20.0)
    var targets: [StatType: Double] = [.points: 20.0]

    // remembers which stats already sent a notification so it doesnt spam
    var notifiedStats: Set<StatType> = []
}
