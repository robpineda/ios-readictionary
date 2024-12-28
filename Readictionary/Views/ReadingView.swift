//
//  ReadingView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

struct ReadingView: View {
    var fileURL: URL
    @State private var dictionaryViewHeight: CGFloat = UIScreen.main.bounds.height / 2
    @State private var isDragging = false
    @State private var highlightedWord: String?
    @State private var translatedWords: [TranslatedWord] = []
    @State private var sourceLanguage: Language = .japanese // Default to Japanese
    @State private var targetLanguage: Language = .english // Default to English

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Language Picker
                HStack {
                    Picker("Source Language", selection: $sourceLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Target Language", selection: $targetLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()

                // Reading View (Top)
                if fileURL.pathExtension == "pdf" {
                    PDFKitView(
                        url: fileURL,
                        translatedWords: $translatedWords,
                        sourceLanguage: sourceLanguage,
                        targetLanguage: targetLanguage
                    )
                    .frame(height: geometry.size.height - dictionaryViewHeight)
                } else {
                    Text("Unsupported file format")
                        .frame(height: geometry.size.height - dictionaryViewHeight)
                }

                // Dictionary View (Bottom)
                DictionaryView(
                    height: $dictionaryViewHeight,
                    isDragging: $isDragging,
                    translatedWords: translatedWords,
                    highlightedWord: $highlightedWord
                )
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
        .edgesIgnoringSafeArea(.bottom)
    }
}
