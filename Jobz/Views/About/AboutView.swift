import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    @State private var isLicenseExpanded: Bool = false
    @State private var isTextualLicenseExpanded: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Jobz")
                            .font(.system(size: 24, weight: .bold))
                        Text("Version 1.0.0 (Build 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Modern macOS Job Application & Search Metrics Tracker")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Open Source Licenses & Attributions Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("Third-Party Open Source Software & Attributions")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Jobz incorporates open-source software libraries. We acknowledge and express our gratitude to the authors and maintainers of these projects for their contributions.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // GRDB.swift Attribution Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("GRDB.swift")
                                        .font(.headline)
                                    Text("v7.11.1")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                    Text("MIT License")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                                Text("A toolkit for SQLite database management in Swift.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Copyright © 2015-2025 Gwendal Roué")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if let url = URL(string: "https://github.com/groue/GRDB.swift") {
                                    openURL(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("GitHub")
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        DisclosureGroup(
                            isExpanded: $isLicenseExpanded,
                            content: {
                                Text(ResourceLoader.loadLicense("GRDB_LICENSE.txt"))
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .padding(.top, 8)
                            },
                            label: {
                                Text(isLicenseExpanded ? "Hide Full License Text" : "View Full MIT License Text")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                            }
                        )
                    }
                    .padding(16)
                    .background(Color(NSColor.secondarySystemFill))
                    .cornerRadius(12)
                    
                    // Textual Attribution Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Textual")
                                        .font(.headline)
                                    Text("v0.5.0")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                    Text("MIT License")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                                Text("A Markdown viewer for SwiftUI.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Copyright © 2025 Guillermo González")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if let url = URL(string: "https://github.com/gonzalezreal/textual") {
                                    openURL(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("GitHub")
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        DisclosureGroup(
                            isExpanded: $isTextualLicenseExpanded,
                            content: {
                                Text(ResourceLoader.loadLicense("TEXTUAL_LICENSE.txt"))
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .padding(.top, 8)
                            },
                            label: {
                                Text(isTextualLicenseExpanded ? "Hide Full License Text" : "View Full MIT License Text")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                            }
                        )
                    }
                    .padding(16)
                    .background(Color(NSColor.secondarySystemFill))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("About & Licenses")
    }
}

#Preview {
    AboutView()
}
