//
//  TextModeListView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 1/3/25.
//

import SwiftUI

struct TextModeListView: View {
    @State private var textRecords: [TextRecord] = []
    @State private var isShowingTextInputView = false
    @State private var navigationPath = NavigationPath() // Navigation path
    @Binding var translatedWords: [TranslatedWord]
    var targetLanguage: Language

    var body: some View {
        NavigationStack(path: $navigationPath) { // Use NavigationStack
            List {
                ForEach($textRecords) { $record in
                    NavigationLink(value: record) { // Use NavigationLink(value:label:)
                        Text(record.name)
                    }
                }
                .onDelete(perform: deleteTextRecord)
            }
            .navigationTitle("Text Translations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingTextInputView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingTextInputView) {
                TextModeInputView { name, text in
                    let newRecord = TextRecord(name: name, text: text, translatedWords: [])
                    textRecords.append(newRecord)
                    
                    // Generate cache key based on the text
                    let cacheKey = CacheManager.shared.cacheKey(for: text)

                    // Check if cached data exists
                    if let cachedWords = CacheManager.shared.loadTranslatedWords(for: cacheKey) {
                        DispatchQueue.main.async {
                            self.translatedWords = cachedWords
                        }
                    } else {
                        // No cached data, call the API
                        let translationService = TranslationService()
                        translationService.translateText(
                            newRecord.text,
                            targetLanguage: targetLanguage,
                            translatedWords: $translatedWords,
                            extractedText: newRecord.text
                        )
                    }
                    navigationPath.append(newRecord) // Navigate to the new record
                }
            }
            .navigationDestination(for: TextRecord.self) { record in
                TextModeDetailView(record: $textRecords.first(where: { $0.id == record.id })!) // Pass the Binding
            }
        }
    }

    private func deleteTextRecord(at offsets: IndexSet) {
        textRecords.remove(atOffsets: offsets)
    }
}
