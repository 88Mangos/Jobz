import Foundation

/// Centralized utility for loading bundled text and SQL resources.
enum ResourceLoader {
    private static var cache: [String: String] = [:]
    private static let lock = NSLock()
    
    /// Loads the string contents of a bundled resource file.
    ///
    /// - Parameters:
    ///   - name: The base filename without extension.
    ///   - ext: The file extension (e.g. "sql", "txt").
    ///   - subdirectory: An optional subdirectory inside the bundle resources.
    /// - Returns: The contents of the file, or an empty string if not found.
    static func load(name: String, ext: String, subdirectory: String? = nil) -> String {
        let cacheKey = "\(subdirectory ?? "")/\(name).\(ext)"
        
        lock.lock()
        if let cached = cache[cacheKey] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        var fileURL: URL?
        
        // 1. Try Bundle.main with optional subdirectory
        if let subdirectory = subdirectory {
            fileURL = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
        }
        
        // 2. Try Bundle.main at root
        if fileURL == nil {
            fileURL = Bundle.main.url(forResource: name, withExtension: ext)
        }
        
        // 3. Fallback to searching all bundles (useful in test runner or preview environments)
        if fileURL == nil {
            for bundle in Bundle.allBundles {
                if let url = (subdirectory != nil ? bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) : nil)
                    ?? bundle.url(forResource: name, withExtension: ext) {
                    fileURL = url
                    break
                }
            }
        }
        
        guard let url = fileURL,
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            #if DEBUG
            print("[ResourceLoader] Warning: Resource '\(name).\(ext)' not found in bundle.")
            #endif
            return ""
        }
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        lock.lock()
        cache[cacheKey] = trimmed
        lock.unlock()
        
        return trimmed
    }
    
    /// Loads a SQL query resource by filename (with or without `.sql` extension).
    static func loadQuery(_ filename: String) -> String {
        let cleanName = filename.replacingOccurrences(of: ".sql", with: "")
        return load(name: cleanName, ext: "sql", subdirectory: "Queries")
    }
    
    /// Loads a license text resource by filename (with or without `.txt` extension).
    static func loadLicense(_ filename: String) -> String {
        let cleanName = filename.replacingOccurrences(of: ".txt", with: "")
        return load(name: cleanName, ext: "txt", subdirectory: "Licenses")
    }
}
