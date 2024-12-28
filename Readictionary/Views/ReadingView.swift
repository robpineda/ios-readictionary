//
//  ReadingView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

struct ReadingView: View {
    var fileURL: URL
    @State private var dictionaryViewHeight: CGFloat = UIScreen.main.bounds.height / 2 // Start at 50% of the screen height
    @State private var isDragging = false // Track if the user is dragging the dictionary view
    @State private var highlightedWord: String?
    @State private var currentPageText: String = "" // Text from the current page

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Reading View (Top)
                if fileURL.pathExtension == "pdf" {
                    PDFKitView(url: fileURL, currentPageText: $currentPageText)
                        .frame(height: geometry.size.height - dictionaryViewHeight)
                } else {
                    Text("Unsupported file format")
                        .frame(height: geometry.size.height - dictionaryViewHeight)
                }

                // Dictionary View (Bottom)
                DictionaryView(
                    height: $dictionaryViewHeight,
                    isDragging: $isDragging,
                    dictionaryEntries: filterDictionaryEntries(for: currentPageText),
                    highlightedWord: $highlightedWord
                )
                .frame(height: dictionaryViewHeight)
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
        .edgesIgnoringSafeArea(.bottom)
    }

    private func filterDictionaryEntries(for text: String) -> [JapaneseDictionaryEntry] {
        let words = tokenizeJapanese(text: text)

        // Filter entries and preserve the order of words in the PDF
        var filteredEntries: [JapaneseDictionaryEntry] = []
        for word in words {
            if let entry = JapaneseDictionaryManager.shared.getDictionaryEntries().first(where: { $0.kanji == word || $0.hiragana == word }) {
                filteredEntries.append(entry)
            }
        }

        return filteredEntries
    }

    private func tokenizeJapanese(text: String) -> [String] {
        let tagger = NSLinguisticTagger(
            tagSchemes: [.tokenType, .lexicalClass],
            options: 0
        )
        tagger.string = text
        var words: [String] = []
        let range = NSRange(location: 0, length: text.utf16.count)

        // Use .lexicalClass to tokenize Japanese text
        tagger.enumerateTags(
            in: range,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range, _, _ in
            if let tag = tag, tag != .whitespace, tag != .punctuation {
                let word = (text as NSString).substring(with: range)
                words.append(word)
            }
        }

        return words
    }
}
