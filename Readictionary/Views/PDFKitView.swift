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
                let translationService = TranslationService()
                translationService.translateText(
                    extractedText,
                    targetLanguage: targetLanguage,
                    translatedWords: $translatedWords,
                    extractedText: extractedText
                )
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
}
