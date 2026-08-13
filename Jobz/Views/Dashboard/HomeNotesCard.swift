import SwiftUI
import AppKit

struct HomeNotesCard: View {
    @AppStorage("homePageNotesDump") private var notes: String = ""
    @State private var isEditing: Bool = false
    @State private var showCopiedAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notes Dump")
                            .font(.headline)
                        Text("Quick unattached notes, code snippets, and scratch pad")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if showCopiedAlert {
                        Text("Copied!")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                            .transition(.opacity)
                    }
                    
                    Button(action: copyToClipboard) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(notes.isEmpty)
                    
                    if !notes.isEmpty && isEditing {
                        Button(role: .destructive, action: { notes = "" }) {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if isEditing {
                        Button(action: { isEditing.toggle() }) {
                            Label("Done", systemImage: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        Button(action: { isEditing.toggle() }) {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            Divider()
            
            // Body Content
            if isEditing {
                TextEditor(text: $notes)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 180)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 8) {
                        Spacer(minLength: 24)
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("No notes dumped yet")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("Click 'Edit' above to dump raw text, code snippets (Python triple-quoted docstrings supported), or Markdown.")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Spacer(minLength: 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ScrollView(.vertical) {
                        Text(markdownText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(8)
                    }
                    .frame(minHeight: 120, maxHeight: 300)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }
    
    private var markdownText: AttributedString {
        if let attrStr = try? AttributedString(markdown: notes, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)) {
            return attrStr
        }
        return AttributedString(notes)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(notes, forType: .string)
        
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
    HomeNotesCard()
        .padding()
}
