//
//  DocumentListView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

struct DocumentListView: View {
    @State private var documents: [URL] = [] // Store uploaded file URLs
    @State private var isShowingDocumentPicker = false

    var body: some View {
        NavigationView {
            List {
                ForEach(documents, id: \.self) { document in
                    NavigationLink {
                        ReadingView(fileURL: document) // Pass the selected file to the ReadingView
                    } label: {
                        Text(document.lastPathComponent)
                    }
                }
                .onDelete(perform: deleteDocument) // Allow deleting documents
            }
            .navigationTitle("My Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingDocumentPicker = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPicker(fileURL: .constant(nil)) { url in
                    documents.append(url)
                }
            }
        }
    }

    // Function to delete documents
    private func deleteDocument(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
    }
}
