//
//  TranslatedWord.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/28/24.
//

import Foundation

struct TranslatedWord: Identifiable, Codable, Hashable { // Add Hashable
    var id = UUID()
    let originalText: String
    let transliteration: String?
    let romaji: String?
    let definitions: [String]

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Use the unique ID for hashing
    }

    // Implement Equatable (required by Hashable)
    static func == (lhs: TranslatedWord, rhs: TranslatedWord) -> Bool {
        return lhs.id == rhs.id // Compare words by their unique ID
    }
}

enum Language: String, CaseIterable {
    case japanese = "Japanese"
    case korean = "Korean"
    case spanish = "Spanish"
    case english = "English"
    // Add more languages as needed
}
