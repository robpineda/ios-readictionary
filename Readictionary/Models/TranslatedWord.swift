//
//  TranslatedWord.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/28/24.
//

import Foundation

struct TranslatedWord: Identifiable, Codable {
    var id = UUID()
    let originalText: String // The original word in the source language
    let transliteration: String? // Transliteration (e.g., hiragana for Japanese)
    let romaji: String? // Romaji (for Japanese)
    let definitions: [String] // List of translations in the target language
}

enum Language: String, CaseIterable {
    case japanese = "Japanese"
    case korean = "Korean"
    case spanish = "Spanish"
    case english = "English"
    // Add more languages as needed
}
