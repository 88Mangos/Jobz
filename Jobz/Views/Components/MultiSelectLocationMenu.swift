import SwiftUI

struct LocationParser {
    static func parseLocations(from rawString: String?, knownOptions: [String] = []) -> Set<String> {
        guard let raw = rawString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return []
        }
        
        // 1. Semicolon separated (e.g. "San Francisco, CA; New York, NY")
        if raw.contains(";") {
            let items = raw.components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Set(items)
        }
        
        // 2. Slash separated (e.g. "Mountain View, CA / Remote")
        if raw.contains(" / ") {
            let items = raw.components(separatedBy: " / ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Set(items)
        }
        
        // 3. Pipe separated (e.g. "San Francisco, CA|New York, NY")
        if raw.contains("|") {
            let items = raw.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Set(items)
        }
        
        // 4. Comma separated matching against known options
        var result = Set<String>()
        var workingString = raw
        let sortedKnown = knownOptions.filter { !$0.isEmpty }.sorted { $0.count > $1.count }
        
        for option in sortedKnown {
            if let range = workingString.range(of: option) {
                result.insert(option)
                workingString.removeSubrange(range)
            }
        }
        
        let leftovers = workingString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if result.isEmpty {
            return Set([raw])
        }
        
        for left in leftovers {
            result.insert(left)
        }
        
        return result
    }
    
    static func formatLocations(_ locations: Set<String>, sortedBy allOptions: [String]) -> String? {
        if locations.isEmpty {
            return nil
        }
        var sorted: [String] = []
        for option in allOptions {
            if locations.contains(option) {
                sorted.append(option)
            }
        }
        let customLeft = locations.subtracting(Set(allOptions)).sorted()
        sorted.append(contentsOf: customLeft)
        
        return sorted.joined(separator: "; ")
    }
}

struct MultiSelectLocationMenu: View {
    let defaultOptions = [
        "Remote",
        "San Francisco, CA",
        "New York, NY",
        "Seattle, WA",
        "Austin, TX",
        "Boston, MA",
        "Los Angeles, CA",
        "Chicago, IL"
    ]
    
    @Binding var selectedLocationsStr: String?
    @AppStorage("customLocations") private var customLocationsStr = ""
    @State private var showingAddAlert = false
    @State private var newLocation = ""
    
    var options: [String] {
        let custom = customLocationsStr.split(separator: "|").map(String.init)
        var all = defaultOptions
        for c in custom {
            if !all.contains(c) {
                all.append(c)
            }
        }
        return all
    }
    
    var selectedLocations: Set<String> {
        LocationParser.parseLocations(from: selectedLocationsStr, knownOptions: options)
    }
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    toggleLocation(option)
                }) {
                    HStack {
                        Text(option)
                        if selectedLocations.contains(option) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            if !selectedLocations.isEmpty {
                Divider()
                Button("Clear All", role: .destructive) {
                    selectedLocationsStr = nil
                }
            }
            
            Divider()
            Button("Add Custom...") {
                showingAddAlert = true
            }
        } label: {
            Text(displayText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .alert("Add Location", isPresented: $showingAddAlert) {
            TextField("City, State or Country", text: $newLocation)
            Button("Cancel", role: .cancel) {
                newLocation = ""
            }
            Button("Add") {
                addCustomLocation()
            }
        }
    }
    
    private var displayText: String {
        guard let str = selectedLocationsStr, !str.isEmpty else {
            return "Select Locations"
        }
        return str
    }
    
    private func toggleLocation(_ option: String) {
        var current = selectedLocations
        if current.contains(option) {
            current.remove(option)
        } else {
            current.insert(option)
        }
        selectedLocationsStr = LocationParser.formatLocations(current, sortedBy: options)
    }
    
    private func addCustomLocation() {
        let trimmed = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let currentCustom = customLocationsStr.split(separator: "|").map(String.init)
        if !currentCustom.contains(trimmed) && !defaultOptions.contains(trimmed) {
            let newCustom = currentCustom + [trimmed]
            customLocationsStr = newCustom.joined(separator: "|")
        }
        
        var current = selectedLocations
        current.insert(trimmed)
        
        var all = defaultOptions
        for c in customLocationsStr.split(separator: "|").map(String.init) {
            if !all.contains(c) {
                all.append(c)
            }
        }
        selectedLocationsStr = LocationParser.formatLocations(current, sortedBy: all)
        newLocation = ""
    }
}
