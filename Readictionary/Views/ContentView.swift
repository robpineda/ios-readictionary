//
//  ContentView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

struct ContentView: View {
    @State private var translatedWords: [TranslatedWord] = [] // State for translated words
    @State private var targetLanguage: Language = .english // Default target language
    
    var body: some View {
        TabView {
            // Tab 1: PDF Functionality
            DocumentListView()
                .tabItem {
                    Image(systemName: "doc")
                    Text("PDF")
                }

            // Tab 2: Text Translation Functionality
            TextModeListView(translatedWords: $translatedWords, targetLanguage: targetLanguage)
                .tabItem {
                    Image(systemName: "text.bubble")
                    Text("Text")
                }
        }
    }
}
