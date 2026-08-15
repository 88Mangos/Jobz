import SwiftUI
import AppKit
import Textual

struct MusingsView: View {
    @AppStorage("musingsNotesTab") private var musings: String = ""
    @State private var isEditing: Bool = false
    @State private var showCopiedAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Musings")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                if showCopiedAlert {
                    Text("Copied!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                        .transition(.opacity)
                }
                
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(musings.isEmpty)
                
                if !musings.isEmpty && isEditing {
                    Button(role: .destructive, action: { musings = "" }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                
                if isEditing {
                    Button(action: { isEditing.toggle() }) {
                        Label("Done Editing", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { isEditing.toggle() }) {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            Divider()
            
            // Content
            if isEditing {
                TextEditor(text: $musings)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            } else {
                if musings.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "lightbulb")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Musings Yet")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("Click 'Edit' to dump unstructured thoughts, notes, and ideas here before they become formal job applications. Your musings are automatically saved to this device.")
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        StructuredText(markdown: musings)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textual.textSelection(.enabled)
                            .padding()
                    }
                }
            }
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(musings, forType: .string)
        
        withAnimation {
            showCopiedAlert = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
}

#Preview {
    MusingsView()
}
