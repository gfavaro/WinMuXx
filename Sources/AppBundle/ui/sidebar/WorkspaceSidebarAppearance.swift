import AppKit
import SwiftUI

private struct WorkspaceSidebarAppearanceKey: EnvironmentKey {
    static let defaultValue: WorkspaceSidebarAppearance = .custom
}

private struct WorkspaceSidebarTransparentContrastKey: EnvironmentKey {
    static let defaultValue = false
}

private struct WorkspaceSidebarWallpaperSampleKey: EnvironmentKey {
    static let defaultValue: WorkspaceSidebarWallpaperSample? = nil
}

/// Only deterministic developer previews set these; production uses system preferences.
struct WorkspaceSidebarPreviewAccessibility: Sendable {
    var reduceTransparency = false
    var increasedContrast = false
}

private struct WorkspaceSidebarPreviewAccessibilityKey: EnvironmentKey {
    static let defaultValue = WorkspaceSidebarPreviewAccessibility()
}

extension EnvironmentValues {
    var workspaceSidebarWallpaperSample: WorkspaceSidebarWallpaperSample? {
        get { self[WorkspaceSidebarWallpaperSampleKey.self] }
        set { self[WorkspaceSidebarWallpaperSampleKey.self] = newValue }
    }
    var workspaceSidebarTransparentContrast: Bool {
        get { self[WorkspaceSidebarTransparentContrastKey.self] }
        set { self[WorkspaceSidebarTransparentContrastKey.self] = newValue }
    }
    var workspaceSidebarPreviewAccessibility: WorkspaceSidebarPreviewAccessibility {
        get { self[WorkspaceSidebarPreviewAccessibilityKey.self] }
        set { self[WorkspaceSidebarPreviewAccessibilityKey.self] = newValue }
    }

    var workspaceSidebarAppearance: WorkspaceSidebarAppearance {
        get { self[WorkspaceSidebarAppearanceKey.self] }
        set { self[WorkspaceSidebarAppearanceKey.self] = newValue }
    }
}

/// Kept local to sidebar descendants; shared tab/switcher chrome is not affected.
@propertyWrapper
struct SidebarColors: DynamicProperty {
    @Environment(\.workspaceSidebarAppearance) var appearance
    @Environment(\.colorSchemeContrast) var contrast
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.workspaceSidebarPreviewAccessibility) var previewAccessibility
    @Environment(\.workspaceSidebarTransparentContrast) var transparentContrast

    var wrappedValue: WorkspaceSidebarPalette {
        // Also redraw AppKit-generated menu swatches when the system theme changes.
        _ = colorScheme
        return WorkspaceSidebarPalette(appearance: appearance, increasedContrast: contrast == .increased || previewAccessibility.increasedContrast, transparentContrast: transparentContrast, colorScheme: colorScheme)
    }
}

struct WorkspaceSidebarPalette {
    let appearance: WorkspaceSidebarAppearance
    var increasedContrast = false
    var transparentContrast = false
    var colorScheme: ColorScheme = .dark

    var foreground: Color {
        if appearance == .custom { return .white }
        if transparentContrast { return colorScheme == .light ? .black : .white }
        return .primary
    }
    var separator: Color {
        appearance == .system
            ? Color(nsColor: .separatorColor).opacity(increasedContrast ? 1 : 0.7)
            : .white.opacity(GlassToken.separatorOpacity)
    }

    func text(opacity: Double) -> Color {
        guard opacity > 0 else { return .clear }
        if appearance == .custom { return .white.opacity(opacity) }
        if transparentContrast { return foreground.opacity(increasedContrast ? 1 : max(opacity, 0.85)) }
        return opacity < 0.8 && !increasedContrast ? .secondary : .primary
    }
}

struct WorkspaceSidebarSystemSurface: View {
    var background: WorkspaceSidebarBackground = .sidebar
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.workspaceSidebarPreviewAccessibility) var previewAccessibility

    var body: some View {
        if reduceTransparency || previewAccessibility.reduceTransparency {
            Color(nsColor: .windowBackgroundColor)
        } else if background == .transparent {
            Color.clear
        } else {
            WorkspaceSidebarVisualEffect(background: background)
        }
    }
}

struct WorkspaceSidebarVisualEffect: NSViewRepresentable {
    var background: WorkspaceSidebarBackground = .sidebar
    var frosted = false
    @Environment(\.colorScheme) var colorScheme
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        configure(view)
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        configure(view)
    }

    func configure(_ view: NSVisualEffectView) {
        // AppKit has no public material for the actual system menu bar.
        // Header material provides a native approximation without capturing wallpaper.
        view.material = frosted ? .hudWindow : (background == .menuBar ? .headerView : .sidebar)
        // Keep the expanded transparent sidebar visibly translucent rather than the
        // near-opaque header material, while retaining the native behind-window blur.
        view.alphaValue = frosted ? 0.93 : 1
        view.blendingMode = .behindWindow
        // The sidebar stays visible when another application's window has focus.
        view.state = .active
        view.isEmphasized = false
        view.appearance = frosted ? NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua) : nil
    }
}

struct WorkspaceSidebarFrostedSurface: View {
    var tint: WorkspaceSidebarFrostedTint = .automatic
    @Environment(\.workspaceSidebarWallpaperSample) var wallpaperSample
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.workspaceSidebarPreviewAccessibility) var previewAccessibility

    var body: some View {
        if reduceTransparency || previewAccessibility.reduceTransparency {
            Color(nsColor: .windowBackgroundColor)
        } else {
            ZStack {
                WorkspaceSidebarVisualEffect(frosted: true)
                // A stronger veil keeps expanded labels readable while preserving blur and wallpaper color.
                LinearGradient(colors: resolvedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(workspaceSidebarFrostedVeilOpacity(tint: tint, hasWallpaperSample: wallpaperSample != nil))
            }
        }
    }

    var resolvedColors: [Color] {
        tint.colors(colorScheme: colorScheme, wallpaperSample: wallpaperSample)
    }
}

func workspaceSidebarFrostedVeilOpacity(tint: WorkspaceSidebarFrostedTint, hasWallpaperSample: Bool) -> Double {
    tint == .automatic && !hasWallpaperSample ? 0.14 : 0.36
}

extension WorkspaceSidebarFrostedTint {
    var preferredColorScheme: ColorScheme? {
        switch self {
            case .automatic: nil
            case .white, .cyan, .pink, .ice: .light
            case .black, .indigo, .purple, .aurora: .dark
        }
    }

    func colors(colorScheme: ColorScheme, wallpaperSample: WorkspaceSidebarWallpaperSample? = nil) -> [Color] {
        if self == .automatic, let wallpaperSample { return [wallpaperSample.color] }
        return switch self {
            case .automatic: [colorScheme == .dark ? .black : .white]
            case .white: [.white]
            case .black: [.black]
            case .cyan: [.cyan]
            case .pink: [.pink]
            case .indigo: [.indigo]
            case .purple: [.purple]
            case .ice: [.white, .cyan, .pink]
            case .aurora: [.black, .indigo, .purple]
        }
    }
}

struct WorkspaceSidebarColorScheme: ViewModifier {
    let appearance: WorkspaceSidebarAppearance
    @Environment(\.colorScheme) var systemColorScheme

    func body(content: Content) -> some View {
        content.environment(\.colorScheme, appearance == .custom ? .dark : systemColorScheme)
    }
}
