//
//  DictionaryView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

struct DictionaryView: View {
    @Binding var height: CGFloat
    @Binding var isDragging: Bool
    var dictionaryEntries: [JapaneseDictionaryEntry]
    @Binding var highlightedWord: String?

    var body: some View {
        VStack {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 40, height: 6)
                .foregroundColor(.gray)
                .padding(.top, 8)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Update the height of the dictionary view based on drag
                            let newHeight = max(100, min(UIScreen.main.bounds.height / 2, height - value.translation.height))
                            height = newHeight
                            isDragging = true
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )

            // Dictionary List View
            List {
                ForEach(dictionaryEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        // Display kanji and hiragana
                        if let kanji = entry.kanji {
                            Text("\(kanji), \(entry.hiragana)")
                                .font(.headline)
                        } else {
                            Text(entry.hiragana)
                                .font(.headline)
                        }

                        // Display English meanings
                        ForEach(entry.englishMeanings.indices, id: \.self) { index in
                            Text("\(index + 1). \(entry.englishMeanings[index])")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
