//
//  TextRecord.swift
//  Readictionary
//
//  Created by Roberto Pineda on 1/3/25.
//

import Foundation

struct TextRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let text: String
    var translatedWords: [TranslatedWord]

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Use the unique ID for hashing
    }

    // Implement Equatable (required by Hashable)
    static func == (lhs: TextRecord, rhs: TextRecord) -> Bool {
        return lhs.id == rhs.id // Compare records by their unique ID
    }
}
