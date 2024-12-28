//
//  JapaneseDictionaryEntry.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import Foundation

struct JapaneseDictionaryEntry: Identifiable {
    let id = UUID()
    let kanji: String? // Kanji representation (optional)
    let hiragana: String // Hiragana representation
    let englishMeanings: [String] // List of English meanings
}
