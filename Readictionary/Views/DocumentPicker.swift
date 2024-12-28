//
//  DocumentPicker.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL? // Binding to pass the selected file URL back to SwiftUI
    var onFilePicked: (URL) -> Void // Callback for when a file is picked

    // Create the UIKit UIDocumentPickerViewController
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.epub, UTType.pdf], asCopy: true)
        picker.delegate = context.coordinator // Set the delegate to handle file selection
        return picker
    }

    // Update the view controller (not needed here, but required by the protocol)
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    // Create a Coordinator to handle delegate methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator class to act as the delegate for UIDocumentPickerViewController
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        // Handle file selection
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.fileURL = url // Update the Binding
                parent.onFilePicked(url) // Call the callback
            }
        }
    }
}
