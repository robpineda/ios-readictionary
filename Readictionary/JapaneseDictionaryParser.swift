//
//  JapaneseDictionaryParser.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import Foundation

class JapaneseDictionaryParser: NSObject, XMLParserDelegate {
    private var entries: [JapaneseDictionaryEntry] = []
    private var currentElement: String = ""
    private var currentKanji: String? = nil
    private var currentHiragana: String = ""
    private var currentEnglishMeanings: [String] = []
    private var parserCompletionHandler: (([JapaneseDictionaryEntry]) -> Void)?

    func parseDictionary(from data: Data, completion: @escaping ([JapaneseDictionaryEntry]) -> Void) {
        self.parserCompletionHandler = completion
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    // XMLParserDelegate methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "entry" {
            currentKanji = nil
            currentHiragana = ""
            currentEnglishMeanings = []
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedString.isEmpty else { return }

        switch currentElement {
        case "keb": // Kanji element
            currentKanji = cleanedString
        case "reb": // Hiragana element
            currentHiragana = cleanedString
        case "gloss": // English meaning
            if currentEnglishMeanings.count < 3 { // Limit to 3 meanings
                currentEnglishMeanings.append(cleanedString)
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "entry" && (!currentHiragana.isEmpty || currentKanji != nil) {
            let entry = JapaneseDictionaryEntry(
                kanji: currentKanji,
                hiragana: currentHiragana,
                englishMeanings: currentEnglishMeanings
            )
            entries.append(entry)
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        parserCompletionHandler?(entries)
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML Parsing Error: \(parseError.localizedDescription)")
    }
}
