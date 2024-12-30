//
//  PDFKitView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI
import PDFKit
import Combine

struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var translatedWords: [TranslatedWord]
    var targetLanguage: Language

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true

        // Extract text from the PDF
        if let pdfDocument = pdfView.document {
            let extractedText = extractText(from: pdfDocument)
            translateText(extractedText, targetLanguage: targetLanguage)
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    private func extractText(from pdfDocument: PDFDocument) -> String {
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                fullText += page.string ?? ""
            }
        }
        return fullText
    }

    private func translateText(_ text: String, targetLanguage: Language) {
        let apiKey = Config.apiKey
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Define the request body
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful translator. Analyze and translate the following text the way it should be read, respecting compound words. Never process this this from the text: grammar particles, irrelevant symbols, or words in the language you are translating to. Translate all the words even if they appear multiple times. Provide the most accurate translations according to the context of the text. For translating japanese, translate each word with the format: original text, hiragana, romaji\ndefinition 1, definition 2, definition 3\n\n. For other languages, format as: original text, original text, transliteration\n definition 1, definition 2, definition 3\n\n. Don't add any additional characters to your response, and always respect the format I gave you."
                ],
                [
                    "role": "user",
                    "content": text // The text to translate
                ]
            ],
            "stream": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error encoding request body: \(error)")
            return
        }

        // Create a URLSession with a delegate to handle streaming
        let session = URLSession(configuration: .default, delegate: StreamingDelegate(translatedWords: $translatedWords), delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
}

// MARK: - StreamingDelegate
class StreamingDelegate: NSObject, URLSessionDataDelegate {
    @Binding var translatedWords: [TranslatedWord]
    private var buffer = Data()
    private var accumulatedContent = "" // To accumulate the incremental content
    private let serialQueue = DispatchQueue(label: "com.readictionary.streaming") // Serial queue for processing

    init(translatedWords: Binding<[TranslatedWord]>) {
        self._translatedWords = translatedWords
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
}
