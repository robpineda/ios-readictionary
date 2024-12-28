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
    var translatedWords: [TranslatedWord] // Use TranslatedWord
    @Binding var highlightedWord: String?

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            DragHandle(height: $height, isDragging: $isDragging)

            // Dictionary List View
            List {
                ForEach(translatedWords) { word in
                    TranslatedWordRow(
                        word: word,
                        isHighlighted: word.originalText == highlightedWord
                    )
                }
            }
            .listStyle(PlainListStyle())
            .onChange(of: highlightedWord) { newWord in
                // Scroll to the highlighted word
                if let word = newWord,
                   let index = translatedWords.firstIndex(where: { $0.originalText == word }) {
                    ScrollViewReader { proxy in
                        Color.clear
                            .onAppear {
                                proxy.scrollTo(index, anchor: .center)
                            }
                    }
                }
            }
        }
        .frame(height: height) // Constrain the entire DictionaryView to the specified height
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// MARK: - Drag Handle
// DragHandle.swift

struct DragHandle: View {
    @Binding var height: CGFloat
    @Binding var isDragging: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .frame(width: 40, height: 6)
            .foregroundColor(.gray)
            .padding(.top, 8)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = max(100, min(UIScreen.main.bounds.height - 100, height - value.translation.height))
                        height = newHeight
                        isDragging = true
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}
