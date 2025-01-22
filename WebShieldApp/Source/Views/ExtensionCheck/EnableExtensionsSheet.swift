import SwiftUI

struct EnableExtensionsSheet: View {
    let missingExtensions: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    extensionsListSection
                    instructionsSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Enable Extensions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .frame(
            minWidth: platformSpecificWidth,
            idealWidth: platformSpecificWidth,
            maxWidth: .infinity,
            minHeight: 400,
            idealHeight: 500
        )
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 48))
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Enable WebShield Extensions")
                    .font(.title2.weight(.semibold))

                Text("WebShield requires Safari extensions to be enabled for full functionality.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var extensionsListSection: some View {
        GroupBox("Required Extensions") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(missingExtensions, id: \.self) { ext in
                    Label(ext, systemImage: "square.stack.3d.down.forward")
                        .symbolRenderingMode(.multicolor)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }

    private var instructionsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 20) {
                InstructionStep(
                    number: 1,
                    title: "Open Safari Settings",
                    icon: "safari",
                    description: platformSpecificSettingsPath
                )

                InstructionStep(
                    number: 2,
                    title: "Enable Extensions",
                    icon: "powerplug",
                    description: "Toggle on WebShield extensions and enable 'Allow in Private Browsing'"
                )

                InstructionStep(
                    number: 3,
                    title: "Set Permissions",
                    icon: "lock.open",
                    description: "Set website permissions to 'Allow on Every Website' for WebShield Advanced"
                )
            }
            .padding(.vertical, 8)
        } label: {
            Text("Setup Instructions")
                .font(.headline)
                .padding(.bottom, 8)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            #if os(iOS) || os(visionOS)
                Button(action: openSettings) {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            #endif
            //            #if os(macOS)
            //                Button("Quit Safari") {
            //                    NSApplication.shared.terminate(nil)
            //                }
            //                .foregroundStyle(.secondary)
            //            #endif
        }
    }

    // MARK: - Platform Specific Properties

    private var platformSpecificSettingsPath: LocalizedStringKey {
        #if os(macOS)
            return "Go to **Safari** → **Settings** → **Extensions**"
        #else
            return "Go to **Settings** → **Safari** → **Extensions**"
        #endif
    }

    private var platformSpecificWidth: CGFloat? {
        #if os(macOS)
            return 560
        #else
            return nil
        #endif
    }

    // MARK: - Actions

    private func openSettings() {
        #if os(macOS)
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Safari-Settings.extension")!)
        #elseif os(iOS)
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        #endif
    }
}

// MARK: - Reusable Components

struct InstructionStep: View {
    let number: Int
    let title: LocalizedStringKey
    let icon: String
    let description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            NumberBadge(number: number)

            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.medium))

                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

struct NumberBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(.blue))
    }
}
