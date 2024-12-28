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
    var sourceLanguage: Language
    var targetLanguage: Language

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true

        // Extract text from the PDF
        if let pdfDocument = pdfView.document {
            let extractedText = extractText(from: pdfDocument)
            translateText(extractedText, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
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

    private func translateText(_ text: String, sourceLanguage: Language, targetLanguage: Language) {
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
                    "content": "You are a helpful translator. Analyze and translate the following text the way it should be read, respecting compound words. Omit particles and other symbols. For japanese, translate each word with the format as: [original text], [hiragana], [romaji]\ndefinition 1, definition 2, definition 3. In other languages, format as: [original text], [transliteration (if applicable)]\n definition 1, definition 2, definition 3. For each word, provide the best possible translations according to the context of the text, with the most accurate at the top of the definitions list."
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
                    let translatedWords = parseTranslatedContent(content, sourceLanguage: sourceLanguage)
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

    private func parseTranslatedContent(_ content: String, sourceLanguage: Language) -> [TranslatedWord] {
        var translatedWords: [TranslatedWord] = []
        let entries = content.components(separatedBy: "\n\n") // Split into individual word entries

        for entry in entries {
            if entry.isEmpty { continue }

            // Split the entry into lines
            let lines = entry.components(separatedBy: "\n")
            guard lines.count >= 2 else { continue }

            // Parse the first line: [original text], [hiragana], [romaji]
            let wordInfo = lines[0].components(separatedBy: ", ")
            guard wordInfo.count >= 3 else { continue }

            let originalText = wordInfo[0]
            let transliteration = wordInfo[1] // Hiragana
            let romaji = wordInfo[2] // Romaji

            // Parse the second line: Definition 1, Definition 2, Definition 3
            let definitions = lines[1].components(separatedBy: ", ")
                .map { $0.replacingOccurrences(of: "^[0-9]+\\. ", with: "", options: .regularExpression) }

            // Create a TranslatedWord object
            let word = TranslatedWord(
                originalText: originalText,
                transliteration: transliteration,
                romaji: romaji,
                definitions: definitions,
                language: sourceLanguage
            )
            translatedWords.append(word)
        }

        return translatedWords
    }
}
