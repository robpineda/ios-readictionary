//
//  TranslatedWordRow.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/28/24.
//

import SwiftUI

struct TranslatedWordRow: View {
    var word: TranslatedWord
    var isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Display the original word, hiragana, and romaji
            if let transliteration = word.transliteration, let romaji = word.romaji {
                Text("\(word.originalText), \(transliteration), \(romaji)")
                    .font(.headline)
            } else if let transliteration = word.transliteration {
                Text("\(word.originalText), \(transliteration)")
                    .font(.headline)
            } else {
                Text(word.originalText)
                    .font(.headline)
            }

            // Display definitions
            if !word.definitions.isEmpty {
                            Text(word.definitions.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .background(isHighlighted ? Color.yellow : Color.clear) // Highlight the selected word
    }
}
