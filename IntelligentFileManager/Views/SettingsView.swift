import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var viewModel: SettingsViewModel
    @State private var isDirectoryPickerPresented = false

    init(appEnvironment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            settingsService: appEnvironment.settingsService,
            fileRepository: appEnvironment.fileRepository
        ))
    }

    var body: some View {
        Form {
            // MARK: - Security
            Section("Security") {
                Toggle("Enable Encryption", isOn: $viewModel.encryptionEnabled)
            }

            // MARK: - File Management
            Section("File Management") {
                Toggle("Auto-Classify Files", isOn: $viewModel.autoClassifyEnabled)

                HStack {
                    Text("Max File Size")
                    Spacer()
                    Stepper("\(viewModel.maxFileSizeMB) MB", value: $viewModel.maxFileSizeMB, in: 1...10000, step: 50)
                }

                HStack {
                    Label("Default Directory", systemImage: "folder")
                    Spacer()
                    Button(action: { isDirectoryPickerPresented = true }) {
                        Text(URL(fileURLWithPath: viewModel.defaultDirectoryPath).lastPathComponent)
                            .lineLimit(1)
                            .foregroundStyle(.blue)
                    }
                }
            }

            // MARK: - Actions
            Section {
                Button {
                    viewModel.applyChanges()
                } label: {
                    Label("Apply Changes", systemImage: "checkmark.circle")
                }

                Button(role: .destructive) {
                    viewModel.resetToDefaults()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $isDirectoryPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                viewModel.defaultDirectoryPath = url.path
            }
        }
    }
}

#Preview {
    let env = AppEnvironment(modelContainer: try! ModelContainerProvider.preview())
    NavigationStack {
        SettingsView(appEnvironment: env)
            .environmentObject(env)
    }
}
