//
//  PDFKitView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI
import PDFKit

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
            "model": "deepseek-chat", // Specify the model
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful translator. Analyze and translate the following text the way it should be read, respecting compound words. Never read this from the text: grammar particles, irrelevant symbols, or words in the language you are translating to, since we don't need to translate that. Provide the most accurate translations according to the context of the text. For translating japanese, translate each word with the format: original text, hiragana, romaji\ndefinition 1, definition 2, definition 3\n\n. For other languages, format as: original text, original text, transliteration\n definition 1, definition 2, definition 3\n\n. Don't add any additional characters to your response, only provide the content as I specified."
                ],
                [
                    "role": "user",
                    "content": text // The text to translate
                ]
            ],
            "stream": false // Set to true if you want a stream response
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error encoding request body: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                // Parse the response
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // Process the translated content
                    let translatedWords = parseTranslatedContent(content)
                    DispatchQueue.main.async {
                        self.translatedWords = translatedWords
                    }
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }
        task.resume()
    }

    private func parseTranslatedContent(_ content: String) -> [TranslatedWord] {
        var translatedWords: [TranslatedWord] = []
        
        print(content)
        
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
        
        // Remove repeated [original text] for languages other than Japanese
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
