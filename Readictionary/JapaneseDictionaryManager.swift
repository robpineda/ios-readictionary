//
//  JapaneseDictionaryManager.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import Foundation

class JapaneseDictionaryManager {
    static let shared = JapaneseDictionaryManager() // Singleton instance
    private var dictionaryEntries: [JapaneseDictionaryEntry] = []

    private init() {
        // Load the dictionary when the singleton is initialized
        loadDictionary()
    }

    func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "JMdict_e", withExtension: ""),
              let data = try? Data(contentsOf: url) else {
            return
        }

        let parser = JapaneseDictionaryParser()
        parser.parseDictionary(from: data) { entries in
            self.dictionaryEntries = entries
        }
    }

    func getDictionaryEntries() -> [JapaneseDictionaryEntry] {
        return dictionaryEntries
    }

    func filterEntries(for words: [String]) -> [JapaneseDictionaryEntry] {
        let wordSet = Set(words) // Convert to a Set for faster lookups
        return dictionaryEntries.filter { entry in
            wordSet.contains(entry.kanji ?? "") || wordSet.contains(entry.hiragana)
        }
    }
}
