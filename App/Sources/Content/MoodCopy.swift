import DesignSystem
import Foundation

/// Product copy for each mood. Kept out of DesignSystem so the token layer stays wordless.
extension AtmosphereMood {
    var title: String {
        switch self {
        case .lamplight: "The Lamppost"
        case .expedition: "Expedition"
        case .teaTime: "Tea Time"
        }
    }

    func statusTitle(isRunning: Bool) -> String {
        switch self {
        case .lamplight: "Waiting at the lamppost"
        case .expedition: isRunning ? "On expedition" : "Expedition paused"
        case .teaTime: isRunning ? "Tea Time" : "Tea Time paused"
        }
    }

    var statusDetail: String? {
        switch self {
        case .lamplight: nil
        case .expedition: "25 MIN"
        case .teaTime: "5 MIN"
        }
    }

    var companionLine: String {
        switch self {
        case .lamplight: "Whenever you're ready, the wood will wait."
        case .expedition: "Eyes on the path. I'll keep the lantern lit."
        case .teaTime: "The kettle's on. Rest your feet a while."
        }
    }

    func primaryLabel(isRunning: Bool) -> String {
        switch self {
        case .lamplight: "Begin Expedition"
        case .expedition, .teaTime: isRunning ? "Pause" : "Resume"
        }
    }

    func primarySymbol(isRunning: Bool) -> String {
        switch self {
        case .lamplight: "figure.walk"
        case .expedition, .teaTime: isRunning ? "pause.fill" : "play.fill"
        }
    }
}

nonisolated enum PlaceData {
    static func lines(for date: Date) -> [String] {
        [
            Brand.appName.uppercased(),
            "\(Brand.place.uppercased())  51.7520° N  1.1920° W",
            date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()).uppercased(),
        ]
    }
}
