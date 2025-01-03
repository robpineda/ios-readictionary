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

            // Generate cache key based on the document's content
            let cacheKey = CacheManager.shared.cacheKey(for: extractedText)

            // Check if cached data exists
                if let cachedWords = CacheManager.shared.loadTranslatedWords(for: cacheKey) {
                    DispatchQueue.main.async {
                        self.translatedWords = cachedWords
                    }
                } else {
                    // No cached data, call the API
                    translateText(extractedText, targetLanguage: targetLanguage)
                }
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
           let session = URLSession(configuration: .default, delegate: StreamingDelegate(translatedWords: $translatedWords, extractedText: text), delegateQueue: nil)
           let task = session.dataTask(with: request)
           task.resume()
    }
}
