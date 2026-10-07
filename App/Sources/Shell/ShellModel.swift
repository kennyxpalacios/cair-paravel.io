import DesignSystem
import Foundation
import Observation

nonisolated enum Panel: String, CaseIterable, Identifiable {
    case chronicles
    case mediaHub

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chronicles: "The Chronicles"
        case .mediaHub: "Media Hub"
        }
    }

    var symbol: String {
        switch self {
        case .chronicles: "book.closed"
        case .mediaHub: "music.note"
        }
    }
}

/// Shell state for Phase 2. The mood and running flag are preview stand-ins so every
/// visual state can be reviewed; the real timer engine replaces them in Phase 3.
@Observable
final class ShellModel {
    var mood: AtmosphereMood = .lamplight
    var isRunning = false
    var panel: Panel?
    var showsGrid = true
    var showsWorkshop = false

    init() {
        #if DEBUG
        // Launch arguments for screenshots and review, e.g.
        // `-CairPreviewMood expedition -CairPreviewPanel chronicles`.
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "CairPreviewMood"), let mood = AtmosphereMood(rawValue: raw) {
            self.mood = mood
            isRunning = mood != .lamplight
        }
        if let raw = defaults.string(forKey: "CairPreviewPanel"), let panel = Panel(rawValue: raw) {
            self.panel = panel
        }
        #endif
    }

    /// Static countdown values per mood, for layout review only.
    var previewSeconds: Int {
        switch mood {
        case .lamplight: 25 * 60
        case .expedition: 18 * 60 + 42
        case .teaTime: 4 * 60 + 12
        }
    }

    func primaryAction() {
        switch mood {
        case .lamplight:
            mood = .expedition
            isRunning = true
        case .expedition, .teaTime:
            isRunning.toggle()
        }
    }

    func skipToTeaTime() {
        mood = .teaTime
        isRunning = true
    }

    func end() {
        mood = .lamplight
        isRunning = false
    }

    func toggle(_ panel: Panel) {
        self.panel = self.panel == panel ? nil : panel
    }
}
