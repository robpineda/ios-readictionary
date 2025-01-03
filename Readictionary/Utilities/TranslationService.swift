//
//  TranslationService.swift
//  Readictionary
//
//  Created by Roberto Pineda on 1/4/25.
//

import Foundation
import SwiftUI

class TranslationService {
    func translateText(_ text: String, targetLanguage: Language, translatedWords: Binding<[TranslatedWord]>, extractedText: String) {
        let apiKey = Config.apiKey
        let url = URL(string: Config.apiUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": Config.apiMessageContent
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
        let session = URLSession(
            configuration: .default,
            delegate: StreamingDelegate(translatedWords: translatedWords, extractedText: extractedText),
            delegateQueue: nil
        )
        let task = session.dataTask(with: request)
        task.resume()
    }
}
