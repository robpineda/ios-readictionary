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
            // Display the original word and transliteration (if applicable)
            if !word.transliteration!.isEmpty {
                // If transliteration is not empty, display it
                Text("\(word.originalText), \(word.transliteration!), \(word.romaji ?? "")")
                    .font(.headline)
            } else {
                // If transliteration is empty, skip it
                Text("\(word.originalText), \(word.romaji ?? "")")
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
