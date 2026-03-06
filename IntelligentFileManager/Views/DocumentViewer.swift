import SwiftUI

struct DocumentViewer: View {
    @Binding var file: ManagedFile?
    @State private var isEditingTags = false
    @State private var newTag = ""

    private var managedFile: ManagedFile? { file }

    var body: some View {
        Group {
            if let file = managedFile {
                List {
                    // MARK: - Identity
                    Section("File Info") {
                        LabeledContent("Name", value: file.name)
                        LabeledContent("Extension", value: file.fileExtension.isEmpty ? "—" : file.fileExtension.uppercased())
                        LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        LabeledContent("Path") {
                            Text(file.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }

                    // MARK: - Dates
                    Section("Dates") {
                        LabeledContent("Created") {
                            Text(file.createdAt, style: .date)
                        }
                        LabeledContent("Modified") {
                            Text(file.modifiedAt, style: .date)
                        }
                    }

                    // MARK: - Classification
                    Section("Classification") {
                        if let label = file.classificationLabel {
                            LabeledContent("Label", value: label)
                            LabeledContent("Confidence") {
                                Text(String(format: "%.0f%%", file.classificationConfidence * 100))
                                    .foregroundStyle(
                                        file.classificationConfidence > 0.8 ? .green :
                                        file.classificationConfidence > 0.5 ? .orange : .red
                                    )
                            }
                        } else {
                            Text("Not classified")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: - Security
                    Section("Security") {
                        HStack {
                            Label("Encrypted", systemImage: file.isEncrypted ? "lock.fill" : "lock.open")
                                .foregroundStyle(file.isEncrypted ? .green : .secondary)
                            Spacer()
                            Text(file.isEncrypted ? "Yes" : "No")
                                .foregroundStyle(.secondary)
                        }
                        if let checksum = file.checksum {
                            LabeledContent("Checksum") {
                                Text(checksum)
                                    .font(.caption)
                                    .monospaced()
                                    .lineLimit(1)
                            }
                        }
                    }

                    // MARK: - Duplicates
                    if file.isDuplicate {
                        Section("Duplicates") {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(.orange)
                                Text("This file is a duplicate")
                                    .foregroundStyle(.orange)
                            }
                            if let dupId = file.duplicateOfId {
                                LabeledContent("Original ID", value: dupId.uuidString)
                            }
                        }
                    }

                    // MARK: - Tags
                    Section {
                        if file.tags.isEmpty && !isEditingTags {
                            Text("No tags")
                                .foregroundStyle(.secondary)
                        } else {
                            FlowLayout(spacing: 6) {
                                ForEach(file.tags, id: \.self) { tag in
                                    TagChip(tag: tag) {
                                        file.tags.removeAll { $0 == tag }
                                    }
                                }
                            }
                        }

                        if isEditingTags {
                            HStack {
                                TextField("New tag", text: $newTag)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty && !file.tags.contains(trimmed) {
                                        file.tags.append(trimmed)
                                        newTag = ""
                                    }
                                }
                                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Tags")
                            Spacer()
                            Button(isEditingTags ? "Done" : "Edit") {
                                isEditingTags.toggle()
                                newTag = ""
                            }
                            .font(.caption)
                        }
                    }
                }
                .navigationTitle(file.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("No File Selected", systemImage: "doc.questionmark")
            }
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.small)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.12))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}

// MARK: - Simple Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    let file = ManagedFile(
        name: "Report.pdf",
        path: "/Documents/Report.pdf",
        fileExtension: "pdf",
        size: 204800,
        isEncrypted: false,
        classificationLabel: "Document",
        classificationConfidence: 0.92,
        tags: ["finance", "2024"]
    )
    NavigationStack {
        DocumentViewer(file: .constant(file))
    }
}
