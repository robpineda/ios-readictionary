//
//  ReadictionaryApp.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

@main
struct ReadictionaryApp: App {
    
    // Initialize the DictionaryManager singleton at app launch
    init() {
        _ = JapaneseDictionaryManager.shared
        // Add other dictionaries here in the future
        // _ = KoreanDictionaryManager.shared
        // _ = SpanishDictionaryManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            DocumentListView()
        }
    }
}
