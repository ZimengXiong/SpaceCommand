import Foundation

/// Manages persistence of space names for native mode
class PersistenceManager {
    private let fileURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SpaceCommand", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        self.fileURL = appDir.appendingPathComponent("space_names.json")
    }
    
    /// Load space names from disk
    func loadSpaceNames() -> [String: String] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let names = try JSONDecoder().decode([String: String].self, from: data)
            return names
        } catch {
            print("Failed to load space names: \(error)")
            return [:]
        }
    }
    
    /// Save a space name to disk
    func saveSpaceName(index: Int, name: String) {
        var names = loadSpaceNames()
        names["\(index)"] = name
        
        do {
            let data = try JSONEncoder().encode(names)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save space name: \(error)")
        }
    }
    
    /// Remove a space name
    func removeSpaceName(index: Int) {
        var names = loadSpaceNames()
        names.removeValue(forKey: "\(index)")
        
        do {
            let data = try JSONEncoder().encode(names)
            try data.write(to: fileURL)
        } catch {
            print("Failed to remove space name: \(error)")
        }
    }
}
