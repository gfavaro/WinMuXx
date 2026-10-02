import Sparkle

/// Coordinates application updates from the release appcast.
@MainActor
public enum AutomaticUpdates {

    /// Starts Sparkle's periodic update checks for the main application bundle.
    public static func start() {
        // Disabled for the personal fork. Never initialize an upstream updater.
    }

    /// Displays Sparkle's standard update-checking interface.
    public static func checkForUpdates() {
        // A fork-owned signed update feed must be configured before enabling this.
    }
}
