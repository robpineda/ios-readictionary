//
//  CacheManager.swift
//  Readictionary
//
//  Created by Roberto Pineda on 1/3/25.
//

import Foundation
import CryptoKit

class CacheManager {
    static let shared = CacheManager()
    private let cacheDirectory: URL

    private init() {
        // Create a cache directory if it doesn't exist
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDir.appendingPathComponent("ReadictionaryCache")
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    // Generate a cache key from the document's content (extracted text)
    func cacheKey(for text: String) -> String {
        // Generate a SHA256 hash of the content
        let hash = SHA256.hash(data: text.data(using: .utf8)!)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Save translated words to cache
    func saveTranslatedWords(_ words: [TranslatedWord], for cacheKey: String) {
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")

        do {
            let data = try JSONEncoder().encode(words)
            try data.write(to: cacheFile)
            print("Saved cache for \(cacheKey) at \(cacheFile.path)") // Debugging
        } catch {
            print("Failed to save cache: \(error)")
        }
    }

    // Load translated words from cache
    func loadTranslatedWords(for cacheKey: String) -> [TranslatedWord]? {
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")

        // Check if the file exists
        if !FileManager.default.fileExists(atPath: cacheFile.path) {
            print("Cache file does not exist at \(cacheFile.path)") // Debugging
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheFile)
            let words = try JSONDecoder().decode([TranslatedWord].self, from: data)
            print("Loaded cache for \(cacheKey) from \(cacheFile.path)") // Debugging
            return words
        } catch {
            print("Failed to load cache: \(error)")
            return nil
        }
    }

    // Invalidate cache for a document
    func invalidateCache(for cacheKey: String) {
        let cacheFile = cacheDirectory.appendingPathComponent("\(cacheKey).json")

        do {
            try FileManager.default.removeItem(at: cacheFile)
            print("Invalidated cache for \(cacheKey)")
        } catch {
            print("Failed to invalidate cache: \(error)")
        }
    }
    
    // Save text records to cache
        func saveTextRecords(_ records: [TextRecord], for cacheKey: String) {
            let cacheFile = cacheDirectory.appendingPathComponent("text_\(cacheKey).json")

            do {
                let data = try JSONEncoder().encode(records)
                try data.write(to: cacheFile)
                print("Saved text records for \(cacheKey) at \(cacheFile.path)")
            } catch {
                print("Failed to save text records: \(error)")
            }
        }

        // Load text records from cache
        func loadTextRecords(for cacheKey: String) -> [TextRecord]? {
            let cacheFile = cacheDirectory.appendingPathComponent("text_\(cacheKey).json")

            if !FileManager.default.fileExists(atPath: cacheFile.path) {
                print("Text records cache file does not exist at \(cacheFile.path)")
                return nil
            }

            do {
                let data = try Data(contentsOf: cacheFile)
                let records = try JSONDecoder().decode([TextRecord].self, from: data)
                print("Loaded text records for \(cacheKey) from \(cacheFile.path)")
                return records
            } catch {
                print("Failed to load text records: \(error)")
                return nil
            }
        }
}
