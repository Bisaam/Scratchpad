import SwiftUI

struct AppearanceSettingsTab: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        Form {
            Section {
                Slider(value: $settingsStore.settings.backgroundDimOpacity, in: 0...0.5, step: 0.01) {
                    Text("Background Dim")
                }
                HStack {
                    ForEach(AppSettings.dimOpacityPresets, id: \.self) { preset in
                        Button("\(Int(preset * 100))%") {
                            settingsStore.settings.backgroundDimOpacity = preset
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section {
                Slider(value: $settingsStore.settings.animationDuration, in: 0.1...1.0, step: 0.05) {
                    Text("Animation Duration: \(settingsStore.settings.animationDuration, specifier: "%.2f")s")
                }
            }

            Section {
                ColorPicker(
                    "Pencil Color",
                    selection: Binding(
                        get: { settingsStore.settings.strokeColor.swiftUIColor },
                        set: { settingsStore.settings.strokeColor = StrokeColor(swiftUIColor: $0) }
                    ),
                    supportsOpacity: false
                )
                Slider(
                    value: $settingsStore.settings.strokeWidth,
                    in: AppSettings.strokeWidthRange,
                    step: 0.5
                ) {
                    Text("Pencil Thickness: \(settingsStore.settings.strokeWidth, specifier: "%.1f")pt")
                }
            }
        }
        .padding()
    }
}
