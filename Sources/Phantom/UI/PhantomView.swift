import SwiftUI

public struct PhantomView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        phantomRow("Logs", icon: "doc.text", destination: PhantomLogsView())
                        phantomRow("Network", icon: "network", destination: PhantomNetworkView())
                        phantomRow("Mock Services", icon: "antenna.radiowaves.left.and.right", destination: PhantomMockListView())
                        phantomRow("Configuration", icon: "gearshape", destination: PhantomConfigView())
                    }
                }
            }
            .navigationTitle("Phantom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.onBackgroundVariant)
                            .padding(8)
                            .background(Circle().fill(theme.surface))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .environment(\.phantomTheme, Phantom.theme)
        .onAppear { configureNavigationBarAppearance() }
    }

    private func configureNavigationBarAppearance() {
        let titleColor = UIColor(theme.onBackground)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        let backImage = UIImage(systemName: "chevron.left")?
            .withTintColor(titleColor, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.buttonAppearance = buttonAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = titleColor
        let selectedAttrs = [NSAttributedString.Key.foregroundColor: UIColor(theme.background)]
        let normalAttrs = [NSAttributedString.Key.foregroundColor: titleColor]
        UISegmentedControl.appearance().selectedSegmentTintColor = titleColor
        UISegmentedControl.appearance().setTitleTextAttributes(selectedAttrs, for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes(normalAttrs, for: .normal)
        UISegmentedControl.appearance().backgroundColor = UIColor(theme.inputBackground)
    }

    @ViewBuilder
    private func phantomRow<Destination: View>(_ title: String, icon: String, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(theme.primary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        Divider().overlay(theme.outlineVariant)
    }
}
