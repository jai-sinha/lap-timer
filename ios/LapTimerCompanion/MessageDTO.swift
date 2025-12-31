struct ResultsDTO: Codable {
    let lapTimes: [String]
    let bestLap: String
    let totalTime: String
}

struct MessageDTO: Codable {
    let results: ResultsDTO
}
