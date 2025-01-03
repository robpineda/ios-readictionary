//
//  StreamingDelegate.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/31/24.
//

import SwiftUI
import PDFKit
import Combine

class StreamingDelegate: NSObject, URLSessionDataDelegate {
    @Binding var translatedWords: [TranslatedWord]
    private var buffer = Data()
    private var accumulatedContent = "" // To accumulate the incremental content
    private let serialQueue = DispatchQueue(label: "com.readictionary.streaming") // Serial queue for processing
    private let extractedText: String // Store the extracted text
    
    init(translatedWords: Binding<[TranslatedWord]>, extractedText: String) {
            self._translatedWords = translatedWords
            self.extractedText = extractedText
        }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append the new data to the buffer
        buffer.append(data)

        // Process the buffer on a serial queue to avoid race conditions
        serialQueue.async {
            if let string = String(data: self.buffer, encoding: .utf8) {
                let lines = string.components(separatedBy: "\n\n") // Split by double newlines
                for line in lines {
                    if line.isEmpty { continue }

                    // Remove the "data: " prefix
                    guard line.hasPrefix("data: ") else { continue }
                    let jsonString = String(line.dropFirst(6)) // Remove "data: "

                    // Parse the JSON string
                    if let jsonData = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String {
                        // Accumulate the content
                        self.accumulatedContent += content

                        // If the content ends with "\n\n", it indicates the end of a word entry
                        if self.accumulatedContent.hasSuffix("\n\n") {
                            // Process the accumulated content
                            let newWords = self.parseTranslatedContent(self.accumulatedContent)
                            print("New Words: \(newWords)") // Debugging

                            // Update the UI on the main thread
                            DispatchQueue.main.async {
                                self.translatedWords.append(contentsOf: newWords)
                            }

                            // Reset the accumulated content
                            self.accumulatedContent = ""
                        }
                    }
                }

                // Clear the buffer
                self.buffer = Data()
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Handle the end of the streaming response
        serialQueue.async {
            // Check if there's any remaining content in accumulatedContent
            if !self.accumulatedContent.isEmpty {
                // Process the remaining content
                let newWords = self.parseTranslatedContent(self.accumulatedContent)
                print("Final Words: \(newWords)") // Debugging

                // Update the UI on the main thread
                DispatchQueue.main.async {
                    self.translatedWords.append(contentsOf: newWords)
                }

                // Save the translated words to cache
                let cacheKey = CacheManager.shared.cacheKey(for: self.extractedText)
                CacheManager.shared.saveTranslatedWords(self.translatedWords, for: cacheKey)

                // Reset the accumulated content
                self.accumulatedContent = ""
            }
        }
    }

    private func parseTranslatedContent(_ content: String) -> [TranslatedWord] {
        var translatedWords: [TranslatedWord] = []

        print("Parsing Content: \(content)") // Debugging

        // Split the content into individual lines
        let lines = content.components(separatedBy: "\n")

        // Temporary variables to store the current word entry
        var currentWordInfo: String?
        var currentDefinitions: String?

        for line in lines {
            if line.isEmpty {
                // If the line is empty, it indicates the end of a word entry
                if let wordInfo = currentWordInfo, let definitions = currentDefinitions {
                    // Parse the word entry
                    if let word = parseWordEntry(wordInfo: wordInfo, definitions: definitions) {
                        translatedWords.append(word)
                    }
                }
                // Reset the temporary variables
                currentWordInfo = nil
                currentDefinitions = nil
            } else if currentWordInfo == nil {
                // If currentWordInfo is nil, this line is the word info line
                currentWordInfo = line
            } else {
                // If currentWordInfo is not nil, this line is the definitions line
                currentDefinitions = line
            }
        }

        // Handle the last word entry (if any)
        if let wordInfo = currentWordInfo, let definitions = currentDefinitions {
            if let word = parseWordEntry(wordInfo: wordInfo, definitions: definitions) {
                translatedWords.append(word)
            }
        }

        return translatedWords
    }

    private func parseWordEntry(wordInfo: String, definitions: String) -> TranslatedWord? {
        // Parse the word info line: [original text], [transliteration], [romaji (if applicable)]
        let wordInfoComponents = wordInfo.components(separatedBy: ", ")
        guard wordInfoComponents.count >= 3 else { return nil }

        let originalText = wordInfoComponents[0]
        var transliteration = wordInfoComponents[1]
        let romaji = wordInfoComponents[2]

        // Remove repeated "[original text], [original text]" for languages other than Japanese
        if originalText == transliteration {
            transliteration = ""
        }

        // Parse the definitions line: Definition 1, Definition 2, Definition 3
        let definitionsArray = definitions.components(separatedBy: ", ")
            .map { $0.replacingOccurrences(of: "^[0-9]+\\. ", with: "", options: .regularExpression) }

        // Create a TranslatedWord object
        return TranslatedWord(
            originalText: originalText,
            transliteration: transliteration,
            romaji: romaji,
            definitions: definitionsArray
        )
    }

    // Helper function to get the document URL (if available)
    private func getDocumentURL() -> URL? {
        // Implement logic to retrieve the document URL if needed
        // For example, you can store the document URL in the StreamingDelegate or pass it through the context
        return nil
    }
}
