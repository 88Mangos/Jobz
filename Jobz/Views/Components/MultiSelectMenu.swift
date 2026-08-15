import SwiftUI

struct MultiSelectMenu: View {
    var title: String
    var options: [String]
    @Binding var selectedOptions: Set<String>
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    toggleOption(option)
                }) {
                    HStack {
                        Text(option.isEmpty ? "(Empty)" : option)
                        if selectedOptions.contains(option) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            if !selectedOptions.isEmpty {
                Divider()
                Button("Clear All", role: .destructive) {
                    selectedOptions.removeAll()
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                if !selectedOptions.isEmpty {
                    Text("(\(selectedOptions.count))")
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .frame(minWidth: 100)
    }
    
    private func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
    }
}
