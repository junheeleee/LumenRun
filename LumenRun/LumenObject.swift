import SpriteKit
import SwiftUI

enum LumenObjectKind: String, CaseIterable, Identifiable {
    case spark
    case surge
    case shield
    case slow
    case magnet
    case bomb
    case shard
    case pulse
    case void

    var id: String { rawValue }
    var nodeName: String { rawValue }

    var titleKey: String {
        switch self {
        case .spark:
            return "objects.spark.title"
        case .surge:
            return "objects.surge.title"
        case .shield:
            return "objects.shield.title"
        case .slow:
            return "objects.slow.title"
        case .magnet:
            return "objects.magnet.title"
        case .bomb:
            return "objects.bomb.title"
        case .shard:
            return "objects.shard.title"
        case .pulse:
            return "objects.pulse.title"
        case .void:
            return "objects.void.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .spark:
            return "objects.spark.desc"
        case .surge:
            return "objects.surge.desc"
        case .shield:
            return "objects.shield.desc"
        case .slow:
            return "objects.slow.desc"
        case .magnet:
            return "objects.magnet.desc"
        case .bomb:
            return "objects.bomb.desc"
        case .shard:
            return "objects.shard.desc"
        case .pulse:
            return "objects.pulse.desc"
        case .void:
            return "objects.void.desc"
        }
    }

    var guideColor: Color {
        switch self {
        case .spark:
            return Color(red: 1.0, green: 0.78, blue: 0.12)
        case .surge:
            return Color(red: 1.0, green: 0.46, blue: 0.12)
        case .shield:
            return Color(red: 0.1, green: 0.68, blue: 1.0)
        case .slow:
            return Color(red: 0.68, green: 0.32, blue: 1.0)
        case .magnet:
            return Color(red: 0.08, green: 0.86, blue: 0.78)
        case .bomb:
            return Color(red: 0.34, green: 0.92, blue: 0.34)
        case .shard:
            return Color(red: 1.0, green: 0.18, blue: 0.48)
        case .pulse:
            return Color(red: 1.0, green: 0.28, blue: 0.10)
        case .void:
            return Color(red: 0.48, green: 0.12, blue: 0.72).opacity(0.75)
        }
    }

    var baseRadius: CGFloat {
        switch self {
        case .spark:
            return 10
        case .surge, .shield, .slow, .magnet, .bomb:
            return 12.5
        case .shard:
            return 14.5
        case .pulse:
            return 16.5
        case .void:
            return 15
        }
    }

    var collisionRadius: CGFloat {
        switch self {
        case .spark:
            return 8.5
        case .surge, .shield, .magnet, .bomb:
            return 11.5
        case .slow, .shard:
            return 11
        case .pulse:
            return 12.5
        case .void:
            return 10
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .spark:
            return 1.6
        case .surge, .shield, .slow, .magnet, .bomb:
            return 1.8
        case .shard:
            return 2
        case .pulse:
            return 2.2
        case .void:
            return 7
        }
    }

    var glowWidth: CGFloat {
        switch self {
        case .spark:
            return 8
        case .surge, .magnet, .bomb:
            return 9
        case .shield, .slow:
            return 7
        case .shard:
            return 9
        case .pulse:
            return 11
        case .void:
            return 14
        }
    }

    func sceneColor(for theme: GameTheme) -> SKColor {
        switch self {
        case .spark:
            return SKColor(red: 1.0, green: 0.84, blue: 0.10, alpha: 1)
        case .surge:
            return SKColor(red: 1.0, green: 0.46, blue: 0.12, alpha: 1)
        case .shield:
            return theme.shieldColor
        case .slow:
            return SKColor(red: 0.68, green: 0.32, blue: 1.0, alpha: 1)
        case .magnet:
            return SKColor(red: 0.08, green: 0.86, blue: 0.78, alpha: 1)
        case .bomb:
            return SKColor(red: 0.34, green: 0.92, blue: 0.34, alpha: 1)
        case .shard:
            return theme.shardColor
        case .pulse:
            return SKColor(red: 1.0, green: 0.28, blue: 0.10, alpha: 1)
        case .void:
            return SKColor(red: 0.48, green: 0.12, blue: 0.72, alpha: 0.75)
        }
    }

    func sceneStrokeColor(for theme: GameTheme) -> SKColor {
        switch self {
        case .spark:
            return SKColor(red: 1.0, green: 0.98, blue: 0.46, alpha: 0.95)
        case .void:
            return SKColor(red: 0.72, green: 0.34, blue: 1.0, alpha: 0.9)
        default:
            return sceneColor(for: theme).withAlphaComponent(0.98)
        }
    }
}

extension SKNode {
    var lumenObjectKind: LumenObjectKind? {
        guard let name else { return nil }
        return LumenObjectKind(rawValue: name)
    }
}
