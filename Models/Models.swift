import Foundation

// MARK: - SHARED MODELS

// --- Schedule Models ---
struct ScheduleResponse: Decodable {
    let scoreboard: Scoreboard
}

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
    
    var id: String { gameId }
}

struct TeamSummary: Decodable {
    let teamId: Int
    let teamName: String
    let teamCity: String
    let score: Int
    let wins: Int
    let losses: Int
}

// --- Box Score Models ---
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
    var fullName: String { "\(firstName) \(familyName)" }
    var headshotURL: URL? {
        URL(string: "https://ak-static.cms.nba.com/wp-content/uploads/headshots/nba/latest/260x190/\(personId).png")
    }
}

struct PlayerStats: Decodable {
    let points: Int
    let assists: Int
    let reboundsTotal: Int
    let minutes: String
}

// --- FAVORITES MODELS ---

// 1. The types of stats we can track
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
    
    // NEW: Store multiple targets!
    // Key = StatType (PTS), Value = Target Number (20.0)
    var targets: [StatType: Double] = [.points: 20.0]
    
    // NEW: Track notifications separately for each stat
    var notifiedStats: Set<StatType> = []
}
