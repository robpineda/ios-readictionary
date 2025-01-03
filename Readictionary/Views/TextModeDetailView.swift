//
//  TextModeDetailView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 1/3/25.
//

import SwiftUI

struct TextModeDetailView: View {
    @Binding var record: TextRecord

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Display the original text at the top
                ScrollView {
                    Text(record.text)
                        .padding()
                }
                .frame(height: geometry.size.height / 2)

                // Dictionary View at the bottom
                DictionaryView(
                    height: .constant(geometry.size.height / 2),
                    isDragging: .constant(false),
                    translatedWords: record.translatedWords,
                    highlightedWord: .constant(nil)
                )
            }
        }
        .navigationTitle(record.name)
    }
}
