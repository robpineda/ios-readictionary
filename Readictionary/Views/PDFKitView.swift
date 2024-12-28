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
    @Binding var currentPageText: String // Text from the current page

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.delegate = context.coordinator

        // Extract text from the first page as soon as the document is loaded
        if let firstPage = pdfView.document?.page(at: 0) {
            let text = getText(from: firstPage)
            DispatchQueue.main.async {
                self.currentPageText = text
            }
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitView

        init(_ parent: PDFKitView) {
            self.parent = parent
        }

        func pdfViewPageChanged(_ notification: Notification) {
            // Extract text from the current page when the page changes
            if let pdfView = notification.object as? PDFView {
                let currentPageText = parent.getText(from: pdfView.currentPage)
                DispatchQueue.main.async {
                    self.parent.currentPageText = currentPageText
                }
            }
        }
    }

    // Move the getText method here
    private func getText(from page: PDFPage?) -> String {
        guard let page = page else { return "" }
        return page.string ?? ""
    }
}
