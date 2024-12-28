//
//  JapaneseDictionaryLoader.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import Foundation

func loadJapaneseDictionary() -> [JapaneseDictionaryEntry] {
    guard let url = Bundle.main.url(forResource: "JMdict_e", withExtension: ""),
          let data = try? Data(contentsOf: url) else {
        return []
    }

    var entries: [JapaneseDictionaryEntry] = []
    let parser = JapaneseDictionaryParser()
    parser.parseDictionary(from: data) { parsedEntries in
        entries = parsedEntries
    }
    return entries
}
