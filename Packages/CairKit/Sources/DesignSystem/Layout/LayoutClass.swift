import SwiftUI

/// Layout is chosen from available width, never from device idiom: an iPad window in
/// Stage Manager can be phone-narrow, and it gets the compact layout too.
public enum LayoutClass: Sendable, Equatable {
    /// iPhone, and iPad windows narrower than `regularMinWidth`.
    case compact
    /// iPad full screen and wide windows. The design lead.
    case regular

    public static let regularMinWidth: CGFloat = 700
    /// At or above this width the folio panel docks beside the canvas instead of floating over it.
    public static let dockedPanelMinWidth: CGFloat = 1100

    public init(width: CGFloat) {
        self = width >= Self.regularMinWidth ? .regular : .compact
    }
}

public extension EnvironmentValues {
    @Entry var cairLayout: LayoutClass = .regular
    @Entry var cairMood: AtmosphereMood = .lamplight
}
