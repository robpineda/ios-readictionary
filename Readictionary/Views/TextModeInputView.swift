//
//  TextModeInputView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 1/3/25.
//

import SwiftUI

struct TextModeInputView: View {
    @State private var name: String = ""
    @State private var text: String = ""
    var onSave: (String, String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Record Name")) {
                    TextField("Enter a name", text: $name)
                }

                Section(header: Text("Text to Translate")) {
                    TextEditor(text: $text)
                        .frame(height: 200)
                }
            }
            .navigationTitle("New Translation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Translate") {
                        onSave(name, text)
                        dismiss() // Dismiss the sheet
                    }
                    .disabled(name.isEmpty || text.isEmpty)
                }
            }
        }
    }
}
