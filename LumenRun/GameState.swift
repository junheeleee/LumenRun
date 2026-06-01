import Foundation
import SwiftUI

struct RunRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let score: Int
    let level: Int
    let date: Date
}

enum MissionKind: String, Codable, CaseIterable {
    case score
    case sparks
    case fever
    case shields
    case combo
    case stages
    case surges
    case bombs
}

struct DailyMission: Codable, Identifiable, Equatable {
    let id: String
    let kind: MissionKind
    let target: Int
    var progress: Int

    var isCompleted: Bool {
        progress >= target
    }

    var clampedProgress: Int {
        min(progress, target)
    }
}

enum RunUpgradeKind: CaseIterable, Hashable {
    case shieldCache
    case magnetBoost
    case timeBend
    case feverCharge
    case scoreSurge
    case comboEngine
    case overclock
    case volatileSurge
    case compressionGate
    case unstableFever
    case orbitShift
    case sparkBurst
    case pulseRing
    case flowState
    case echoCatch
    case phaseShift
    case resonanceField
    case hyperCombo
    case voidPulse
    case chainReactor
    case singleOrbit
    case glitchMode
    case meltdown
    case absoluteCore
    case stellarRun
}

enum RunUpgradeRarity {
    case common
    case rare
    case risk
    case legendary

    var titleKey: String {
        switch self {
        case .common:
            return "upgrade.rarity.common"
        case .rare:
            return "upgrade.rarity.rare"
        case .risk:
            return "upgrade.rarity.risk"
        case .legendary:
            return "upgrade.rarity.legendary"
        }
    }
}

enum RunUpgradeTag: CaseIterable, Hashable {
    case shield
    case orbit
    case fever
    case harvest
    case risk

    var titleKey: String {
        switch self {
        case .shield:
            return "upgrade.tag.shield"
        case .orbit:
            return "upgrade.tag.orbit"
        case .fever:
            return "upgrade.tag.fever"
        case .harvest:
            return "upgrade.tag.harvest"
        case .risk:
            return "upgrade.tag.risk"
        }
    }
}

extension RunUpgradeTag {
    var iconName: String {
        switch self {
        case .shield:
            return "shield.fill"
        case .orbit:
            return "circle.dotted.and.circle"
        case .fever:
            return "bolt.fill"
        case .harvest:
            return "sparkle"
        case .risk:
            return "exclamationmark.triangle.fill"
        }
    }

    var roleColor: Color {
        switch self {
        case .shield:
            return Color(red: 0.1, green: 0.68, blue: 1.0)
        case .orbit:
            return Color(red: 0.2, green: 0.9, blue: 0.7)
        case .fever:
            return Color(red: 1.0, green: 0.46, blue: 0.12)
        case .harvest:
            return Color(red: 1.0, green: 0.78, blue: 0.12)
        case .risk:
            return Color(red: 1.0, green: 0.18, blue: 0.48)
        }
    }
}

extension RunUpgradeKind {
    var rarity: RunUpgradeRarity {
        switch self {
        case .shieldCache, .magnetBoost, .timeBend, .scoreSurge, .comboEngine, .orbitShift, .sparkBurst, .pulseRing, .flowState, .echoCatch:
            return .common
        case .feverCharge, .phaseShift, .resonanceField, .hyperCombo, .voidPulse:
            return .rare
        case .overclock:
            return .rare
        case .volatileSurge, .compressionGate, .unstableFever, .chainReactor, .singleOrbit, .glitchMode, .meltdown:
            return .risk
        case .absoluteCore, .stellarRun:
            return .legendary
        }
    }

    var tags: [RunUpgradeTag] {
        switch self {
        case .shieldCache, .echoCatch, .pulseRing:
            return [.shield]
        case .magnetBoost, .timeBend, .orbitShift, .phaseShift, .resonanceField, .singleOrbit:
            return [.orbit]
        case .feverCharge, .comboEngine, .unstableFever, .hyperCombo, .absoluteCore:
            return [.fever]
        case .scoreSurge, .sparkBurst, .flowState, .overclock, .compressionGate, .voidPulse, .stellarRun:
            return [.harvest]
        case .volatileSurge, .chainReactor, .glitchMode, .meltdown:
            return [.risk]
        }
    }

    var primaryTag: RunUpgradeTag {
        tags.first ?? .orbit
    }
}

enum StartCardKind: CaseIterable, Hashable {
    case shieldStart
    case magnetWarmup
    case comboWarmup
    case lumenRush
    case overchargedCore
    case glitchContract
    case glassCore
}

enum StartCardCategory {
    case safe
    case growth
    case risk

    var titleKey: String {
        switch self {
        case .safe:
            return "startCard.category.safe"
        case .growth:
            return "startCard.category.growth"
        case .risk:
            return "startCard.category.risk"
        }
    }
}

struct StartCardChoice: Identifiable, Equatable {
    let kind: StartCardKind
    let titleKey: String
    let descriptionKey: String
    let synergyKey: String
    let iconName: String
    let category: StartCardCategory

    var id: StartCardKind { kind }
}

struct RunUpgradeChoice: Identifiable, Equatable {
    let kind: RunUpgradeKind
    let titleKey: String
    let descriptionKey: String
    let iconName: String
    let rarity: RunUpgradeRarity
    let tag: RunUpgradeTag

    var id: RunUpgradeKind { kind }
}

struct RunBuildSummary: Identifiable, Equatable {
    let kind: RunUpgradeKind
    let titleKey: String
    let iconName: String
    let count: Int

    var id: RunUpgradeKind { kind }
}

enum AchievementID: String, CaseIterable, Codable {
    case firstRun
    case firstFever
    case score50
    case score100
    case score200
    case shields5
    case runs10
    case newBest5
    case dailySweep
    case combo20
    case feverChain3
    case surviveStage5
    case surviveStage10
    case bombClear
    case magnetCollect50
    case shieldSave10
    case runs50
    case dailyStreak3
    case allMissions
    case unlockAllThemes
}

struct AchievementDefinition: Identifiable, Equatable {
    let id: AchievementID
    let titleKey: String
    let descriptionKey: String
    let iconName: String
    let target: Int

    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: .firstRun, titleKey: "achievements.firstRun.title", descriptionKey: "achievements.firstRun.desc", iconName: "play.fill", target: 1),
        AchievementDefinition(id: .firstFever, titleKey: "achievements.firstFever.title", descriptionKey: "achievements.firstFever.desc", iconName: "flame.fill", target: 1),
        AchievementDefinition(id: .score50, titleKey: "achievements.score50.title", descriptionKey: "achievements.score50.desc", iconName: "50.circle.fill", target: 50),
        AchievementDefinition(id: .score100, titleKey: "achievements.score100.title", descriptionKey: "achievements.score100.desc", iconName: "100.circle.fill", target: 100),
        AchievementDefinition(id: .score200, titleKey: "achievements.score200.title", descriptionKey: "achievements.score200.desc", iconName: "bolt.circle.fill", target: 200),
        AchievementDefinition(id: .shields5, titleKey: "achievements.shields5.title", descriptionKey: "achievements.shields5.desc", iconName: "shield.fill", target: 5),
        AchievementDefinition(id: .runs10, titleKey: "achievements.runs10.title", descriptionKey: "achievements.runs10.desc", iconName: "repeat.circle.fill", target: 10),
        AchievementDefinition(id: .newBest5, titleKey: "achievements.newBest5.title", descriptionKey: "achievements.newBest5.desc", iconName: "crown.fill", target: 5),
        AchievementDefinition(id: .dailySweep, titleKey: "achievements.dailySweep.title", descriptionKey: "achievements.dailySweep.desc", iconName: "checkmark.seal.fill", target: 1),
        AchievementDefinition(id: .combo20, titleKey: "achievements.combo20.title", descriptionKey: "achievements.combo20.desc", iconName: "20.circle.fill", target: 20),
        AchievementDefinition(id: .feverChain3, titleKey: "achievements.feverChain3.title", descriptionKey: "achievements.feverChain3.desc", iconName: "flame.circle.fill", target: 3),
        AchievementDefinition(id: .surviveStage5, titleKey: "achievements.surviveStage5.title", descriptionKey: "achievements.surviveStage5.desc", iconName: "5.circle.fill", target: 5),
        AchievementDefinition(id: .surviveStage10, titleKey: "achievements.surviveStage10.title", descriptionKey: "achievements.surviveStage10.desc", iconName: "10.circle.fill", target: 10),
        AchievementDefinition(id: .bombClear, titleKey: "achievements.bombClear.title", descriptionKey: "achievements.bombClear.desc", iconName: "burst.fill", target: 1),
        AchievementDefinition(id: .magnetCollect50, titleKey: "achievements.magnetCollect50.title", descriptionKey: "achievements.magnetCollect50.desc", iconName: "dot.radiowaves.left.and.right", target: 50),
        AchievementDefinition(id: .shieldSave10, titleKey: "achievements.shieldSave10.title", descriptionKey: "achievements.shieldSave10.desc", iconName: "shield.lefthalf.filled", target: 10),
        AchievementDefinition(id: .runs50, titleKey: "achievements.runs50.title", descriptionKey: "achievements.runs50.desc", iconName: "repeat.circle", target: 50),
        AchievementDefinition(id: .dailyStreak3, titleKey: "achievements.dailyStreak3.title", descriptionKey: "achievements.dailyStreak3.desc", iconName: "calendar.badge.checkmark", target: 3),
        AchievementDefinition(id: .allMissions, titleKey: "achievements.allMissions.title", descriptionKey: "achievements.allMissions.desc", iconName: "checklist.checked", target: 15),
        AchievementDefinition(id: .unlockAllThemes, titleKey: "achievements.unlockAllThemes.title", descriptionKey: "achievements.unlockAllThemes.desc", iconName: "paintpalette.fill", target: 9)
    ]
}

final class GameState: ObservableObject {
    var score = 0
    @Published var bestScore: Int
    @Published private(set) var previousBestScore: Int
    @Published private(set) var runRecords: [RunRecord]
    @Published private(set) var dailyMissions: [DailyMission]
    @Published private(set) var achievementProgress: [String: Int]
    @Published var achievementToast: AchievementDefinition?
    var combo = 0
    var multiplier = 1
    var level = 1
    @Published private(set) var displayedScore = 0
    @Published private(set) var displayedCombo = 0
    @Published private(set) var displayedMultiplier = 1
    @Published private(set) var displayedLevel = 1
    @Published private(set) var displayedShieldTimeRemaining: TimeInterval = 0
    @Published private(set) var displayedSlowTimeRemaining: TimeInterval = 0
    @Published private(set) var displayedMagnetTimeRemaining: TimeInterval = 0
    @Published private(set) var displayedFeverProgress: Double = 0
    @Published private(set) var displayedFeverSecondsLeft: Double = 0
    @Published private(set) var isFeverEnding = false
    @Published private(set) var displayedIsFeverActive = false
    @Published private(set) var stage = 1
    @Published private(set) var stageTargetScore = 60
    @Published private(set) var clearedStage = 0
    @Published private(set) var stageClearSerial = 0
    @Published private(set) var stageResumeSerial = 0
    @Published private(set) var objectHintKind: LumenObjectKind?
    @Published private(set) var objectHintSerial = 0
    @Published private(set) var orbitShiftSerial = 0
    @Published private(set) var sparkBurstSerial = 0
    @Published private(set) var pulseRingSerial = 0
    @Published private(set) var voidPulseSerial = 0
    @Published private(set) var runUpgradeCounts: [RunUpgradeKind: Int] = [:]
    @Published var shieldCharges = 0
    var shieldTimeRemaining: TimeInterval = 0
    var slowTimeRemaining: TimeInterval = 0
    var magnetTimeRemaining: TimeInterval = 0
    var feverRemaining: TimeInterval = 0
    var orbitShiftInvulnerabilityRemaining: TimeInterval = 0
    var flowStateRemaining: TimeInterval = 0
    var phaseShiftRemaining: TimeInterval = 0
    var voidPulseRemaining: TimeInterval = 0
    var singleOrbitRemaining: TimeInterval = 0
    var glitchModeRemaining: TimeInterval = 0
    @Published private(set) var echoCatchCharges = 0
    @Published private(set) var isChainReactorActive = false
    @Published private(set) var isAbsoluteCoreUnlocked = false
    @Published private(set) var isGlassCoreActive = false
    @Published private(set) var isGlitchContractActive = false
    var lumenRushRemaining: TimeInterval = 0
    @Published private(set) var stellarMultiplierBonus = 0
    @Published private(set) var runMultiplierBonus = 0
    @Published private(set) var selectedStartCard: StartCardChoice?
    @Published private(set) var startCardChoices: [StartCardChoice] = []
    @Published var isStartCardPresented = false {
        didSet { updatePauseState() }
    }
    @Published private(set) var runUpgradeChoices: [RunUpgradeChoice] = []
    @Published var isRunUpgradePresented = false {
        didSet { updatePauseState() }
    }
    @Published var isLoading = true {
        didSet { updatePauseState() }
    }
    @Published var isStartScreenPresented = true {
        didSet { updatePauseState() }
    }
    @Published var isGameOver = false
    @Published var isPaused: Bool
    @Published var isUserPaused = false
    @Published var isSceneActive = true
    @Published var isSettingsPresented = false {
        didSet { updatePauseState() }
    }
    @Published var isAchievementsPresented = false {
        didSet { updatePauseState() }
    }
    @Published var isRewardsPresented = false {
        didSet { updatePauseState() }
    }
    @Published var hasSeenTutorial: Bool
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey)
            SoundPlayer.setMusicEnabled(isSoundEnabled)
            SoundPlayer.setFeverActive(isFeverActive, enabled: isSoundEnabled)
        }
    }
    @Published var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: hapticsEnabledKey) }
    }
    @Published private(set) var completedMissionCount: Int
    @Published var selectedTheme: GameTheme {
        didSet {
            if !isThemeUnlocked(selectedTheme) {
                selectedTheme = .aurora
                return
            }
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: selectedThemeKey)
        }
    }
    @Published var selectedCoreSkin: CoreSkin {
        didSet {
            if !isCoreSkinUnlocked(selectedCoreSkin) {
                selectedCoreSkin = .orb
                return
            }
            UserDefaults.standard.set(selectedCoreSkin.rawValue, forKey: selectedCoreSkinKey)
        }
    }

    private let bestScoreKey = "bestScore"
    private let runRecordsKey = "runRecords"
    private let dailyMissionsKey = "dailyMissions"
    private let dailyMissionsDateKey = "dailyMissionsDate"
    private let completedMissionCountKey = "completedMissionCount"
    private let rewardedMissionIDsKey = "rewardedMissionIDs"
    private let achievementProgressKey = "achievementProgress"
    private let dailyStreakLastCompletedDateKey = "dailyStreakLastCompletedDate"
    private let dailyStreakCountKey = "dailyStreakCount"
    private let tutorialKey = "hasSeenTutorial"
    private let soundEnabledKey = "soundEnabled"
    private let hapticsEnabledKey = "hapticsEnabled"
    private let selectedThemeKey = "selectedTheme"
    private let selectedCoreSkinKey = "selectedCoreSkin"
    private let feverComboThreshold = 13
    private let feverDuration: TimeInterval = 5.4
    private let shieldDuration: TimeInterval = 8.5
    private let shieldExtensionDuration: TimeInterval = 6
    private let magnetDuration: TimeInterval = 5.5
    private let firstStageTargetScore = 60
    private var nextStageScore = 60
    private var recentRunUpgradeKinds: [RunUpgradeKind] = []
    private var recentOfferedRunUpgradeKinds: [RunUpgradeKind] = []
    private var feverActivationCount = 0
    private var currentComboStreak = 0
    private var peakCombo = 0
    private var displayStatsTimer: TimeInterval = 0
    private var canShowAchievementToast = false
    private var pendingAchievementToasts: [AchievementDefinition] = []

    var isFeverActive: Bool {
        feverRemaining > 0
    }

    var feverComboGoal: Int {
        feverComboThreshold
    }

    var feverProgress: Double {
        guard !isFeverActive else { return 1 }
        return min(1, Double(combo) / Double(feverComboThreshold))
    }

    var comboUntilFever: Int {
        guard !isFeverActive else { return 0 }
        return max(0, feverComboThreshold - combo)
    }

    var stageRouteTitleKey: String {
        switch stage {
        case 1:
            return "stage.route.flow"
        case 2:
            return "stage.route.harvest"
        case 3:
            return "stage.route.pulse"
        case 4:
            return "stage.route.gate"
        case 5:
            return "stage.route.void"
        default:
            switch stage % 4 {
            case 1:
                return "stage.route.flow"
            case 2:
                return "stage.route.harvest"
            case 3:
                return "stage.route.gate"
            default:
                return "stage.route.overdrive"
            }
        }
    }

    var stageRouteDescriptionKey: String {
        switch stage {
        case 1:
            return "stage.route.flow.desc"
        case 2:
            return "stage.route.harvest.desc"
        case 3:
            return "stage.route.pulse.desc"
        case 4:
            return "stage.route.gate.desc"
        case 5:
            return "stage.route.void.desc"
        default:
            switch stage % 4 {
            case 1:
                return "stage.route.flow.desc"
            case 2:
                return "stage.route.harvest.desc"
            case 3:
                return "stage.route.gate.desc"
            default:
                return "stage.route.overdrive.desc"
            }
        }
    }

    var stageRouteIconName: String {
        switch stage {
        case 1:
            return "sparkles"
        case 2:
            return "bolt.fill"
        case 3:
            return "arrow.clockwise.circle.fill"
        case 4:
            return "rectangle.split.3x1.fill"
        case 5:
            return "circle.dotted"
        default:
            switch stage % 4 {
            case 1:
                return "sparkles"
            case 2:
                return "bolt.fill"
            case 3:
                return "shield.lefthalf.filled"
            default:
                return "flame.fill"
            }
        }
    }

    var clearedStageRouteTitleKey: String {
        switch clearedStage {
        case 1:
            return "stage.route.flow"
        case 2:
            return "stage.route.harvest"
        case 3:
            return "stage.route.pulse"
        case 4:
            return "stage.route.gate"
        case 5:
            return "stage.route.void"
        default:
            switch clearedStage % 4 {
            case 1:
                return "stage.route.flow"
            case 2:
                return "stage.route.harvest"
            case 3:
                return "stage.route.gate"
            default:
                return "stage.route.overdrive"
            }
        }
    }

    var activeBuildSummaries: [RunBuildSummary] {
        runUpgradeCounts
            .sorted {
                if $0.value == $1.value {
                    return upgradeSortIndex($0.key) < upgradeSortIndex($1.key)
                }
                return $0.value > $1.value
            }
            .prefix(4)
            .map { kind, count in
                RunBuildSummary(
                    kind: kind,
                    titleKey: upgradeTitleKey(for: kind),
                    iconName: upgradeIconName(for: kind),
                    count: count
                )
            }
    }

    var dominantRunUpgradeTag: RunUpgradeTag? {
        var tagCounts: [RunUpgradeTag: Int] = [:]
        for (kind, count) in runUpgradeCounts {
            tagCounts[upgradeTag(for: kind), default: 0] += count
        }
        return tagCounts.max {
            if $0.value == $1.value {
                let firstIndex = RunUpgradeTag.allCases.firstIndex(of: $0.key) ?? 0
                let secondIndex = RunUpgradeTag.allCases.firstIndex(of: $1.key) ?? 0
                return firstIndex > secondIndex
            }
            return $0.value < $1.value
        }?.key
    }

    var topRunRecords: [RunRecord] {
        Array(runRecords.sorted { $0.score > $1.score }.prefix(5))
    }

    var recentRunRecords: [RunRecord] {
        Array(runRecords.sorted { $0.date > $1.date }.prefix(5))
    }

    var didSetNewBestThisRun: Bool {
        isGameOver && score > previousBestScore
    }

    var bestScoreDelta: Int {
        score - previousBestScore
    }

    var completedDailyMissionTotal: Int {
        dailyMissions.filter(\.isCompleted).count
    }

    var completedAchievementCount: Int {
        AchievementDefinition.all.filter { isAchievementUnlocked($0) }.count
    }

    var nextLockedTheme: GameTheme? {
        GameTheme.allCases.first { !isThemeUnlocked($0) }
    }

    var missionsUntilNextTheme: Int? {
        guard let nextLockedTheme else { return nil }
        return max(0, nextLockedTheme.unlockRequirement - completedMissionCount)
    }

    init() {
        let defaults = UserDefaults.standard
        let loadedBestScore = defaults.integer(forKey: bestScoreKey)
        bestScore = loadedBestScore
        previousBestScore = loadedBestScore
        runRecords = Self.loadRunRecords(from: defaults, key: runRecordsKey)
        dailyMissions = Self.loadDailyMissions(from: defaults, missionsKey: dailyMissionsKey, dateKey: dailyMissionsDateKey)
        achievementProgress = Self.loadAchievementProgress(from: defaults, key: achievementProgressKey)
        hasSeenTutorial = defaults.bool(forKey: tutorialKey)
        isPaused = true
        isSoundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
        isHapticsEnabled = defaults.object(forKey: hapticsEnabledKey) as? Bool ?? true
        completedMissionCount = defaults.integer(forKey: completedMissionCountKey)
        selectedTheme = GameTheme(rawValue: defaults.string(forKey: selectedThemeKey) ?? "") ?? .aurora
        selectedCoreSkin = CoreSkin(rawValue: defaults.string(forKey: selectedCoreSkinKey) ?? "") ?? .orb
        if selectedTheme.unlockRequirement > completedMissionCount {
            selectedTheme = .aurora
        }
        if selectedCoreSkin.unlockRequirement > completedMissionCount {
            selectedCoreSkin = .orb
        }
        updateMissionRewards()
        updateMetaAchievementProgress()
        canShowAchievementToast = true
    }

    func reset() {
        previousBestScore = bestScore
        score = 0
        combo = 0
        multiplier = 1
        level = 1
        stage = 1
        stageTargetScore = firstStageTargetScore
        clearedStage = 0
        stageClearSerial = 0
        stageResumeSerial = 0
        objectHintKind = nil
        objectHintSerial = 0
        orbitShiftSerial = 0
        sparkBurstSerial = 0
        pulseRingSerial = 0
        voidPulseSerial = 0
        runUpgradeCounts = [:]
        shieldCharges = 0
        shieldTimeRemaining = 0
        slowTimeRemaining = 0
        magnetTimeRemaining = 0
        feverRemaining = 0
        orbitShiftInvulnerabilityRemaining = 0
        flowStateRemaining = 0
        phaseShiftRemaining = 0
        voidPulseRemaining = 0
        singleOrbitRemaining = 0
        glitchModeRemaining = 0
        echoCatchCharges = 0
        isChainReactorActive = false
        isAbsoluteCoreUnlocked = false
        isGlassCoreActive = false
        isGlitchContractActive = false
        lumenRushRemaining = 0
        stellarMultiplierBonus = 0
        runMultiplierBonus = 0
        selectedStartCard = nil
        startCardChoices = []
        isStartCardPresented = false
        runUpgradeChoices = []
        isRunUpgradePresented = false
        nextStageScore = firstStageTargetScore
        recentRunUpgradeKinds = []
        recentOfferedRunUpgradeKinds = []
        feverActivationCount = 0
        currentComboStreak = 0
        peakCombo = 0
        displayStatsTimer = 0
        syncDisplayedStats()
        SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
        isGameOver = false
        isUserPaused = false
        isStartScreenPresented = false
        updatePauseState()
    }

    func finishLoading() {
        isLoading = false
    }

    func startRun() {
        SoundPlayer.startRun(enabled: isSoundEnabled)
        presentStartCards()
    }

    func chooseStartCard(_ choice: StartCardChoice) {
        SoundPlayer.moduleSelect(enabled: isSoundEnabled)
        let shouldShowTutorial = !hasSeenTutorial
        selectedStartCard = choice
        applyStartCard(choice.kind)
        syncDisplayedStats()
        startCardChoices = []
        isStartCardPresented = false
        isStartScreenPresented = false
        isUserPaused = false
        isGameOver = false
        if !shouldShowTutorial {
            hasSeenTutorial = true
            UserDefaults.standard.set(true, forKey: tutorialKey)
        }
        updatePauseState()
    }

    func cancelStartCards() {
        startCardChoices = []
        isStartCardPresented = false
    }

    func showObjectHint(for kind: LumenObjectKind) {
        objectHintKind = kind
        objectHintSerial += 1
    }

    func dismissObjectHint(serial: Int) {
        guard objectHintSerial == serial else { return }
        objectHintKind = nil
    }

    func collectSpark(singleOrbitBonus: Bool = false, feverBonus: Bool = false) {
        collectSparkBatch(
            count: 1,
            singleOrbitBonusCount: singleOrbitBonus ? 1 : 0,
            magnetAchievementCount: magnetTimeRemaining > 0 ? 1 : 0,
            feverBonusCount: feverBonus ? 1 : 0
        )
    }

    func collectMagnetSparks(count: Int, singleOrbitBonusCount: Int = 0) {
        collectSparkBatch(
            count: count,
            singleOrbitBonusCount: singleOrbitBonusCount,
            magnetAchievementCount: count,
            feverBonusCount: 0
        )
    }

    private func collectSparkBatch(count: Int, singleOrbitBonusCount: Int, magnetAchievementCount: Int, feverBonusCount: Int) {
        guard count > 0 else { return }

        if phaseShiftRemaining > 0 {
            SoundPlayer.lumen(enabled: isSoundEnabled)
            advanceMission(.sparks, by: count)
            if magnetAchievementCount > 0 {
                incrementAchievement(.magnetCollect50, by: magnetAchievementCount)
            }
            return
        }

        for index in 0..<count {
            let hasSingleOrbitBonus = index < singleOrbitBonusCount

            if isAbsoluteCoreUnlocked, !isFeverActive {
                activateFever()
                SoundPlayer.feverStart(enabled: isSoundEnabled)
                SoundPlayer.setFeverActive(true, enabled: isSoundEnabled)
            } else if !isFeverActive {
                let comboGain = flowStateRemaining > 0 ? 2 : 1
                combo += comboGain
                currentComboStreak += comboGain
                if combo >= feverComboThreshold {
                    combo = 0
                    activateFever()
                    SoundPlayer.feverStart(enabled: isSoundEnabled)
                    SoundPlayer.setFeverActive(true, enabled: isSoundEnabled)
                }
            } else if isAbsoluteCoreUnlocked {
                feverRemaining = max(feverRemaining, activeFeverDuration())
            }

            multiplier = calculatedMultiplier()
            score += (multiplier + (isFeverActive ? 1 : 0)) * activeScoreMultiplier(singleOrbitBonus: hasSingleOrbitBonus)
        }

        if feverBonusCount > 0, isFeverActive {
            score += max(3, multiplier + 2) * activeScoreMultiplier() * feverBonusCount
        }

        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        advanceMission(.sparks, by: count)
        if magnetAchievementCount > 0 {
            incrementAchievement(.magnetCollect50, by: magnetAchievementCount)
        }
        updateComboMissionIfNeeded()
        setAchievementProgress(.combo20, to: peakCombo)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func collectFeverHit() {
        collectFeverHits(count: 1)
    }

    func collectFeverHits(count: Int) {
        guard isFeverActive else { return }
        guard count > 0 else { return }
        score += max(3, multiplier + 2) * activeScoreMultiplier() * count
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func collectSurge() {
        if !isFeverActive {
            combo += 2
        }
        advanceMission(.surges, by: 1)
        multiplier = calculatedMultiplier()
        score += max(8, multiplier * 3) * activeScoreMultiplier()
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func collectBombClear(count: Int) {
        guard count > 0 else { return }
        combo += min(count, 3)
        advanceMission(.bombs, by: 1)
        multiplier = calculatedMultiplier()
        score += max(4, count * 4) * multiplier * activeScoreMultiplier()
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        setAchievementProgress(.bombClear, to: 1)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func chooseRunUpgrade(_ choice: RunUpgradeChoice) {
        guard isRunUpgradePresented else { return }
        SoundPlayer.moduleSelect(enabled: isSoundEnabled)
        applyRunUpgrade(choice.kind)
        runUpgradeChoices = []
        isRunUpgradePresented = false
        stageResumeSerial += 1
    }

    func breakCombo() {
        combo = 0
        currentComboStreak = 0
        multiplier = max(0, 1 + runMultiplierBonus)
        if isFeverActive {
            feverRemaining = 0
            SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
            syncDisplayedStats()
        }
    }

    func grantShield() {
        guard !isGlassCoreActive else {
            SoundPlayer.timeCore(enabled: isSoundEnabled)
            return
        }
        if shieldTimeRemaining > 0 {
            // 실드 발동 중 - 시간 연장
            shieldTimeRemaining = min(shieldTimeRemaining + shieldExtensionDuration, shieldDuration * 2)
        } else {
            // 새 실드 발동
            shieldCharges = 1
            shieldTimeRemaining = shieldDuration
        }
        SoundPlayer.shield(enabled: isSoundEnabled)
        advanceMission(.shields, by: 1)
        incrementAchievement(.shields5, by: 1)
    }

    func consumeShield() -> Bool {
        guard !isGlassCoreActive else { return false }
        guard shieldTimeRemaining > 0 else { return false }
        shieldTimeRemaining = 0
        shieldCharges = 0
        breakCombo()
        SoundPlayer.shieldBreak(enabled: isSoundEnabled)
        incrementAchievement(.shieldSave10, by: 1)
        return true
    }

    func consumeEchoCatchHit() -> Bool {
        guard echoCatchCharges > 0 else { return false }
        echoCatchCharges -= 1
        if isChainReactorActive {
            combo = 0
            multiplier = calculatedMultiplier()
        }
        grantShield()
        return true
    }

    func triggerSlowTime(duration: TimeInterval) {
        slowTimeRemaining = max(slowTimeRemaining, duration)
        SoundPlayer.timeCore(enabled: isSoundEnabled)
    }

    func triggerMagnet() {
        let wasActive = magnetTimeRemaining > 0.35
        magnetTimeRemaining = max(magnetTimeRemaining, magnetDuration)
        if !wasActive {
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        }
    }

    func tick(delta: TimeInterval) {
        if shieldTimeRemaining > 0 {
            shieldTimeRemaining = max(0, shieldTimeRemaining - delta)
            if shieldTimeRemaining == 0 {
                shieldCharges = 0
            }
        }

        if slowTimeRemaining > 0 {
            slowTimeRemaining = max(0, slowTimeRemaining - delta)
        }

        if magnetTimeRemaining > 0 {
            magnetTimeRemaining = max(0, magnetTimeRemaining - delta)
        }

        if feverRemaining > 0 {
            feverRemaining = max(0, feverRemaining - delta)
            if feverRemaining == 0 {
                SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
                syncDisplayedStats()
            }
        }

        if orbitShiftInvulnerabilityRemaining > 0 {
            orbitShiftInvulnerabilityRemaining = max(0, orbitShiftInvulnerabilityRemaining - delta)
        }

        if flowStateRemaining > 0 {
            flowStateRemaining = max(0, flowStateRemaining - delta)
        }

        if phaseShiftRemaining > 0 {
            phaseShiftRemaining = max(0, phaseShiftRemaining - delta)
        }

        if voidPulseRemaining > 0 {
            voidPulseRemaining = max(0, voidPulseRemaining - delta)
        }

        if singleOrbitRemaining > 0 {
            singleOrbitRemaining = max(0, singleOrbitRemaining - delta)
        }

        if glitchModeRemaining > 0 {
            glitchModeRemaining = max(0, glitchModeRemaining - delta)
        }

        if lumenRushRemaining > 0 {
            lumenRushRemaining = max(0, lumenRushRemaining - delta)
        }

        displayStatsTimer += delta
        if displayStatsTimer >= (isFeverActive ? 0.12 : 0.08) {
            displayStatsTimer = 0
            syncDisplayedStats()
        }
    }

    private func syncDisplayedStats() {
        if displayedScore != score {
            displayedScore = score
        }
        if displayedCombo != combo {
            displayedCombo = combo
        }
        if displayedMultiplier != multiplier {
            displayedMultiplier = multiplier
        }
        if displayedLevel != level {
            displayedLevel = level
        }
        let shieldDisplay = displayTimerValue(shieldTimeRemaining)
        if displayedShieldTimeRemaining != shieldDisplay {
            displayedShieldTimeRemaining = shieldDisplay
        }
        let slowDisplay = displayTimerValue(slowTimeRemaining)
        if displayedSlowTimeRemaining != slowDisplay {
            displayedSlowTimeRemaining = slowDisplay
        }
        let magnetDisplay = displayTimerValue(magnetTimeRemaining)
        if displayedMagnetTimeRemaining != magnetDisplay {
            displayedMagnetTimeRemaining = magnetDisplay
        }
        let currentFeverProgress = feverProgress
        if displayedFeverProgress != currentFeverProgress {
            displayedFeverProgress = currentFeverProgress
        }
        let isFeverCurrentlyActive = isFeverActive
        let feverSecondsLeft = isFeverCurrentlyActive ? feverRemaining : 0
        if displayedFeverSecondsLeft != feverSecondsLeft {
            displayedFeverSecondsLeft = feverSecondsLeft
        }
        let shouldShowFeverEnding = isFeverCurrentlyActive && feverRemaining <= 1.5
        if isFeverEnding != shouldShowFeverEnding {
            isFeverEnding = shouldShowFeverEnding
        }
        if displayedIsFeverActive != isFeverCurrentlyActive {
            displayedIsFeverActive = isFeverCurrentlyActive
        }
    }

    private func displayTimerValue(_ value: TimeInterval) -> TimeInterval {
        value > 0 ? ceil(value) : 0
    }

    func endGame() {
        guard !isGameOver else { return }
        isGameOver = true
        let finalScore = score
        let didBeatPreviousBest = finalScore > previousBestScore
        feverRemaining = 0
        syncDisplayedStats()
        updateScoreMission()
        recordRun(score: finalScore, level: level)
        incrementAchievement(.firstRun, by: 1)
        incrementAchievement(.runs10, by: 1)
        incrementAchievement(.runs50, by: 1)
        if didBeatPreviousBest {
            incrementAchievement(.newBest5, by: 1)
        }
        updatePauseState()
        SoundPlayer.crash(enabled: isSoundEnabled)
        SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
        Task { @MainActor in
            GameCenterManager.shared.submit(score: finalScore)
        }
    }

    func completeTutorial() {
        hasSeenTutorial = true
        UserDefaults.standard.set(true, forKey: tutorialKey)
        updatePauseState()
    }

    func pauseForSettings() {
        isSettingsPresented = true
    }

    func closeSettings() {
        isSettingsPresented = false
    }

    func showAchievements() {
        isAchievementsPresented = true
    }

    func closeAchievements() {
        isAchievementsPresented = false
    }

    func showRewards() {
        isRewardsPresented = true
    }

    func closeRewards() {
        isRewardsPresented = false
    }

    func togglePause() {
        guard hasSeenTutorial, !isGameOver else { return }
        isUserPaused.toggle()
        updatePauseState()
    }

    func resume() {
        isUserPaused = false
        updatePauseState()
    }

    func setSceneActive(_ active: Bool) {
        isSceneActive = active
        updatePauseState()
    }

    func showTutorialAgain() {
        isSettingsPresented = false
        isStartScreenPresented = true
        hasSeenTutorial = false
        isUserPaused = false
        UserDefaults.standard.set(false, forKey: tutorialKey)
        updatePauseState()
    }

    func resetBestScore() {
        bestScore = 0
        UserDefaults.standard.set(0, forKey: bestScoreKey)
    }

    func resetRunRecords() {
        runRecords = []
        UserDefaults.standard.removeObject(forKey: runRecordsKey)
    }

    func isThemeUnlocked(_ theme: GameTheme) -> Bool {
        completedMissionCount >= theme.unlockRequirement
    }

    func isCoreSkinUnlocked(_ skin: CoreSkin) -> Bool {
        completedMissionCount >= skin.unlockRequirement
    }

    func achievementProgress(for achievement: AchievementDefinition) -> Int {
        min(achievementProgress[achievement.id.rawValue] ?? 0, achievement.target)
    }

    func isAchievementUnlocked(_ achievement: AchievementDefinition) -> Bool {
        achievementProgress(for: achievement) >= achievement.target
    }

    func dismissAchievementToast(_ achievement: AchievementDefinition? = nil) {
        guard achievement == nil || achievementToast?.id == achievement?.id else { return }
        achievementToast = nil
        if !pendingAchievementToasts.isEmpty {
            achievementToast = pendingAchievementToasts.removeFirst()
        }
    }

    func refreshDailyMissionsIfNeeded() {
        let defaults = UserDefaults.standard
        let today = Self.todayKey()
        if defaults.string(forKey: dailyMissionsDateKey) != today {
            dailyMissions = Self.generateDailyMissions(for: today)
            saveDailyMissions()
        }
    }

    private func recordRun(score: Int, level: Int) {
        guard score > 0 else { return }
        let record = RunRecord(id: UUID(), score: score, level: level, date: Date())
        runRecords.insert(record, at: 0)
        runRecords = Array(runRecords.prefix(30))
        saveRunRecords()
    }

    private func updateBestScore() {
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }
    }

    private func saveRunRecords() {
        guard let data = try? JSONEncoder().encode(runRecords) else { return }
        UserDefaults.standard.set(data, forKey: runRecordsKey)
    }

    private func advanceMission(_ kind: MissionKind, by amount: Int) {
        refreshDailyMissionsIfNeeded()
        var didChange = false
        for index in dailyMissions.indices where dailyMissions[index].kind == kind {
            let nextProgress = min(dailyMissions[index].target, dailyMissions[index].progress + amount)
            if nextProgress != dailyMissions[index].progress {
                dailyMissions[index].progress = nextProgress
                didChange = true
            }
        }
        if didChange {
            saveDailyMissions()
            updateMissionRewards()
        }
    }

    private func updateMissionProgress(_ kind: MissionKind, to value: Int) {
        refreshDailyMissionsIfNeeded()
        var didChange = false
        for index in dailyMissions.indices where dailyMissions[index].kind == kind {
            let nextProgress = min(dailyMissions[index].target, max(dailyMissions[index].progress, value))
            if nextProgress != dailyMissions[index].progress {
                dailyMissions[index].progress = nextProgress
                didChange = true
            }
        }
        if didChange {
            saveDailyMissions()
            updateMissionRewards()
        }
    }

    private func updateScoreMission() {
        refreshDailyMissionsIfNeeded()
        var didChange = false
        for index in dailyMissions.indices where dailyMissions[index].kind == .score {
            let nextProgress = min(dailyMissions[index].target, max(dailyMissions[index].progress, score))
            if nextProgress != dailyMissions[index].progress {
                dailyMissions[index].progress = nextProgress
                didChange = true
            }
        }
        if didChange {
            saveDailyMissions()
            updateMissionRewards()
        }
    }

    private func updateMissionRewards() {
        let defaults = UserDefaults.standard
        var rewardedIDs = Set(defaults.stringArray(forKey: rewardedMissionIDsKey) ?? [])
        var newlyCompletedCount = 0

        for mission in dailyMissions where mission.isCompleted && !rewardedIDs.contains(mission.id) {
            rewardedIDs.insert(mission.id)
            newlyCompletedCount += 1
        }

        guard newlyCompletedCount > 0 else { return }
        completedMissionCount += newlyCompletedCount
        defaults.set(completedMissionCount, forKey: completedMissionCountKey)
        defaults.set(Array(rewardedIDs), forKey: rewardedMissionIDsKey)
        if completedDailyMissionTotal >= dailyMissions.count {
            setAchievementProgress(.dailySweep, to: 1)
            updateDailyStreakAchievement(defaults: defaults)
        }
        updateMetaAchievementProgress()
    }

    private func updateScoreAchievements() {
        setAchievementProgress(.score50, to: score)
        setAchievementProgress(.score100, to: score)
        setAchievementProgress(.score200, to: score)
    }

    private func updateComboMissionIfNeeded() {
        guard currentComboStreak > peakCombo else { return }
        peakCombo = currentComboStreak
        updateMissionProgress(.combo, to: peakCombo)
    }

    private func updateMetaAchievementProgress() {
        setAchievementProgress(.allMissions, to: completedMissionCount)
        setAchievementProgress(.unlockAllThemes, to: completedMissionCount)
    }

    private func activateFever() {
        feverRemaining = activeFeverDuration()
        feverActivationCount += 1
        advanceMission(.fever, by: 1)
        setAchievementProgress(.firstFever, to: 1)
        setAchievementProgress(.feverChain3, to: feverActivationCount)
        syncDisplayedStats()
    }

    private func updateDailyStreakAchievement(defaults: UserDefaults) {
        let today = Self.todayKey()
        let lastCompletedDate = defaults.string(forKey: dailyStreakLastCompletedDateKey)
        guard lastCompletedDate != today else {
            setAchievementProgress(.dailyStreak3, to: defaults.integer(forKey: dailyStreakCountKey))
            return
        }

        let nextStreak: Int
        if let lastCompletedDate, Self.isYesterday(lastCompletedDate, before: today) {
            nextStreak = defaults.integer(forKey: dailyStreakCountKey) + 1
        } else {
            nextStreak = 1
        }

        defaults.set(today, forKey: dailyStreakLastCompletedDateKey)
        defaults.set(nextStreak, forKey: dailyStreakCountKey)
        setAchievementProgress(.dailyStreak3, to: nextStreak)
    }

    private func incrementAchievement(_ id: AchievementID, by amount: Int) {
        let nextValue = (achievementProgress[id.rawValue] ?? 0) + amount
        setAchievementProgress(id, to: nextValue)
    }

    private func setAchievementProgress(_ id: AchievementID, to value: Int) {
        guard let definition = AchievementDefinition.all.first(where: { $0.id == id }) else { return }
        let currentValue = achievementProgress[id.rawValue] ?? 0
        let wasUnlocked = currentValue >= definition.target
        let nextValue = min(value, definition.target)
        guard nextValue > currentValue else { return }
        achievementProgress[id.rawValue] = nextValue
        saveAchievementProgress()

        if !wasUnlocked, nextValue >= definition.target, canShowAchievementToast {
            showAchievementToast(definition)
        }
    }

    private func showAchievementToast(_ achievement: AchievementDefinition) {
        if achievementToast == nil {
            achievementToast = achievement
        } else if achievementToast?.id != achievement.id, !pendingAchievementToasts.contains(where: { $0.id == achievement.id }) {
            pendingAchievementToasts.append(achievement)
        }
    }

    private func saveAchievementProgress() {
        guard let data = try? JSONEncoder().encode(achievementProgress) else { return }
        UserDefaults.standard.set(data, forKey: achievementProgressKey)
    }

    private func saveDailyMissions() {
        guard let data = try? JSONEncoder().encode(dailyMissions) else { return }
        UserDefaults.standard.set(data, forKey: dailyMissionsKey)
        UserDefaults.standard.set(Self.todayKey(), forKey: dailyMissionsDateKey)
    }

    private static func loadRunRecords(from defaults: UserDefaults, key: String) -> [RunRecord] {
        guard
            let data = defaults.data(forKey: key),
            let records = try? JSONDecoder().decode([RunRecord].self, from: data)
        else {
            return []
        }

        return Array(records.prefix(30))
    }

    private static func loadAchievementProgress(from defaults: UserDefaults, key: String) -> [String: Int] {
        guard
            let data = defaults.data(forKey: key),
            let progress = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            return [:]
        }

        return progress
    }

    private static func loadDailyMissions(from defaults: UserDefaults, missionsKey: String, dateKey: String) -> [DailyMission] {
        let today = todayKey()
        guard
            defaults.string(forKey: dateKey) == today,
            let data = defaults.data(forKey: missionsKey),
            let missions = try? JSONDecoder().decode([DailyMission].self, from: data),
            !missions.isEmpty
        else {
            let generated = generateDailyMissions(for: today)
            if let data = try? JSONEncoder().encode(generated) {
                defaults.set(data, forKey: missionsKey)
                defaults.set(today, forKey: dateKey)
            }
            return generated
        }

        return missions
    }

    private static func generateDailyMissions(for dayKey: String) -> [DailyMission] {
        let seed = abs(dayKey.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 10_000 })
        let scoreTarget = [40, 60, 80, 100][seed % 4]
        let sparkTarget = [18, 24, 30, 36][seed % 4]
        let feverTarget = [1, 2, 2, 3][seed % 4]
        let shieldTarget = [1, 2, 3, 3][seed % 4]
        let comboTarget = [10, 15, 18, 20][seed % 4]
        let stageTarget = [2, 3, 4, 5][(seed / 3) % 4]
        let surgeTarget = [2, 3, 4, 5][(seed / 5) % 4]
        let bombTarget = [1, 2, 2, 3][(seed / 7) % 4]
        let pool: [(MissionKind, Int)] = [
            (.score, scoreTarget),
            (.sparks, sparkTarget),
            (.fever, feverTarget),
            (.shields, shieldTarget),
            (.combo, comboTarget),
            (.stages, stageTarget),
            (.surges, surgeTarget),
            (.bombs, bombTarget)
        ]

        let startIndex = seed % pool.count
        return (0..<3).map { offset in
            let item = pool[(startIndex + offset) % pool.count]
            return DailyMission(
                id: "\(dayKey)-\(item.0.rawValue)",
                kind: item.0,
                target: item.1,
                progress: 0
            )
        }
    }

    private static func todayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private static func isYesterday(_ dayKey: String, before todayKey: String) -> Bool {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-M-d"

        guard
            let day = formatter.date(from: dayKey),
            let today = formatter.date(from: todayKey),
            let yesterday = formatter.calendar.date(byAdding: .day, value: -1, to: today)
        else {
            return false
        }

        return formatter.calendar.isDate(day, inSameDayAs: yesterday)
    }

    private func updatePauseState() {
        isPaused = isLoading || isStartScreenPresented || isStartCardPresented || !hasSeenTutorial || isGameOver || isSettingsPresented || isAchievementsPresented || isRewardsPresented || isRunUpgradePresented || isUserPaused || !isSceneActive
    }

    private func offerRunUpgradeIfNeeded() {
        guard !isRunUpgradePresented, !isGameOver, score >= nextStageScore else { return }
        clearedStage = stage
        runUpgradeChoices = makeRunUpgradeChoices()
        stageClearSerial += 1
        let nextStage = stage + 1
        stage = nextStage
        updateMissionProgress(.stages, to: stage)
        setAchievementProgress(.surviveStage5, to: stage)
        setAchievementProgress(.surviveStage10, to: stage)
        nextStageScore += stageScoreRequirement(for: nextStage)
        stageTargetScore = nextStageScore
        isRunUpgradePresented = true
    }

    private func presentStartCards() {
        startCardChoices = makeStartCardChoices()
        isStartCardPresented = true
        updatePauseState()
    }

    private func makeStartCardChoices() -> [StartCardChoice] {
        let seed = max(0, bestScore + completedMissionCount * 7 + runRecords.count * 11)
        let safePool = [
            startCardChoice(.shieldStart),
            startCardChoice(.magnetWarmup)
        ]
        let growthPool = [
            startCardChoice(.comboWarmup),
            startCardChoice(.lumenRush),
            startCardChoice(.magnetWarmup)
        ]
        let riskPool = [
            startCardChoice(.overchargedCore),
            startCardChoice(.glitchContract),
            startCardChoice(.glassCore)
        ]

        var choices = [
            pickStartCard(from: safePool, seed: seed),
            pickStartCard(from: growthPool, seed: seed + 5),
            pickStartCard(from: riskPool, seed: seed + 11)
        ]

        var unique: [StartCardChoice] = []
        for choice in choices {
            if unique.contains(where: { $0.kind == choice.kind }) {
                let fallbackPool = (safePool + growthPool + riskPool).filter { candidate in
                    !unique.contains(where: { $0.kind == candidate.kind })
                }
                if let replacement = fallbackPool.first {
                    unique.append(replacement)
                }
            } else {
                unique.append(choice)
            }
        }

        choices = Array(unique.prefix(3))
        return choices
    }

    private func pickStartCard(from pool: [StartCardChoice], seed: Int) -> StartCardChoice {
        pool[abs(seed) % pool.count]
    }

    private func makeRunUpgradeChoices() -> [RunUpgradeChoice] {
        if clearedStage <= 1 {
            return makeFirstClearChoices()
        }

        let seed = max(0, score / 11 + stage * 5 + combo * 2 + clearedStage)
        let commonPool = [
            runUpgradeChoice(.shieldCache),
            runUpgradeChoice(.magnetBoost),
            runUpgradeChoice(.timeBend),
            runUpgradeChoice(.scoreSurge),
            runUpgradeChoice(.comboEngine),
            runUpgradeChoice(.orbitShift),
            runUpgradeChoice(.sparkBurst),
            runUpgradeChoice(.pulseRing),
            runUpgradeChoice(.flowState),
            runUpgradeChoice(.echoCatch)
        ]
        let rarePool = [
            runUpgradeChoice(.feverCharge),
            runUpgradeChoice(.overclock),
            runUpgradeChoice(.phaseShift),
            runUpgradeChoice(.resonanceField),
            runUpgradeChoice(.hyperCombo),
            runUpgradeChoice(.voidPulse)
        ]
        let riskPool = [
            runUpgradeChoice(.volatileSurge),
            runUpgradeChoice(.compressionGate),
            runUpgradeChoice(.unstableFever),
            runUpgradeChoice(.chainReactor),
            runUpgradeChoice(.singleOrbit),
            runUpgradeChoice(.glitchMode),
            runUpgradeChoice(.meltdown)
        ]
        let legendaryPool = [
            runUpgradeChoice(.unstableFever),
            runUpgradeChoice(.overclock),
            runUpgradeChoice(.absoluteCore),
            runUpgradeChoice(.stellarRun)
        ]
        let fullPool = commonPool + rarePool + riskPool + legendaryPool
        let routePool = routeRecommendedUpgradeKinds(for: max(clearedStage, stage)).map(runUpgradeChoice)

        var choices: [RunUpgradeChoice] = []
        appendRunUpgradeChoice(
            from: routePool + commonPool,
            to: &choices,
            seed: seed,
            allowDuplicateTag: false
        )

        if let dominantTag = dominantRunUpgradeTag, stage >= 2 {
            let synergyPool = fullPool.filter { $0.tag == dominantTag && $0.rarity != .legendary }
            appendRunUpgradeChoice(
                from: synergyPool.isEmpty ? routePool + rarePool + commonPool : synergyPool,
                to: &choices,
                seed: seed + 7,
                allowDuplicateTag: true
            )
        } else if stage >= 3, seed % 5 == 0 {
            appendRunUpgradeChoice(
                from: legendaryPool,
                to: &choices,
                seed: seed + 7,
                allowDuplicateTag: false
            )
        } else {
            appendRunUpgradeChoice(
                from: routePool + rarePool + commonPool,
                to: &choices,
                seed: seed + 7,
                allowDuplicateTag: false
            )
        }

        if stage >= 4, seed % 7 == 0 {
            appendRunUpgradeChoice(
                from: legendaryPool + riskPool,
                to: &choices,
                seed: seed + 13,
                allowDuplicateTag: false
            )
        } else if stage >= 2, seed % 3 != 1 {
            appendRunUpgradeChoice(
                from: riskPool,
                to: &choices,
                seed: seed + 13,
                allowDuplicateTag: false
            )
        } else {
            appendRunUpgradeChoice(
                from: commonPool + rarePool,
                to: &choices,
                seed: seed + 13,
                allowDuplicateTag: false
            )
        }

        while choices.count < 3 {
            let didAppend = appendRunUpgradeChoice(
                from: routePool + commonPool + rarePool + riskPool + legendaryPool,
                to: &choices,
                seed: seed + choices.count * 19,
                allowDuplicateTag: choices.count >= 2
            )
            if !didAppend {
                break
            }
        }

        let finalChoices = Array(choices.prefix(3))
        recentOfferedRunUpgradeKinds = Array((recentOfferedRunUpgradeKinds + finalChoices.map(\.kind)).suffix(6))
        return finalChoices
    }

    private func makeFirstClearChoices() -> [RunUpgradeChoice] {
        let seed = score / 11 + 1
        let commonKinds = RunUpgradeKind.allCases
            .filter { kind in
                kind.rarity == .common
            }

        let safePool = commonKinds
            .filter { kind in
                kind.tags.contains(.shield) || kind.tags.contains(.harvest)
            }
            .map(runUpgradeChoice)

        let preferredTags = selectedStartCard.map { startCardPreferredTags(for: $0.kind) } ?? []
        let preferredPool = commonKinds
            .filter { kind in
                preferredTags.contains { preferredTag in
                    kind.tags.contains(preferredTag)
                }
            }
            .map(runUpgradeChoice)

        var choices: [RunUpgradeChoice] = []
        if !preferredPool.isEmpty {
            appendRunUpgradeChoice(
                from: preferredPool,
                to: &choices,
                seed: seed,
                allowDuplicateTag: false
            )
        }

        var seedOffset = 0
        let fallbackPool = preferredPool + safePool
        while choices.count < 2, seedOffset < fallbackPool.count * 3 {
            let didAppend = appendRunUpgradeChoice(
                from: fallbackPool,
                to: &choices,
                seed: seed + seedOffset * 7,
                allowDuplicateTag: choices.count >= 1
            )
            if didAppend {
                seedOffset += 1
            } else {
                break
            }
        }

        if choices.count < 2 {
            for choice in safePool where !choices.contains(where: { $0.kind == choice.kind }) {
                choices.append(choice)
                if choices.count == 2 {
                    break
                }
            }
        }

        let finalChoices = Array(choices.prefix(2))
        recentOfferedRunUpgradeKinds = Array((recentOfferedRunUpgradeKinds + finalChoices.map(\.kind)).suffix(6))
        return finalChoices
    }

    @discardableResult
    private func appendRunUpgradeChoice(
        from pool: [RunUpgradeChoice],
        to choices: inout [RunUpgradeChoice],
        seed: Int,
        allowDuplicateTag: Bool
    ) -> Bool {
        guard let candidate = pickRunUpgradeCandidate(
            from: pool,
            seed: seed,
            existing: choices,
            allowDuplicateTag: allowDuplicateTag
        ) else {
            return false
        }

        choices.append(candidate)
        return true
    }

    private func pickRunUpgradeCandidate(
        from pool: [RunUpgradeChoice],
        seed: Int,
        existing: [RunUpgradeChoice],
        allowDuplicateTag: Bool
    ) -> RunUpgradeChoice? {
        var seenKinds = Set<RunUpgradeKind>()
        var candidates: [RunUpgradeChoice] = []

        for choice in pool where !seenKinds.contains(choice.kind) {
            seenKinds.insert(choice.kind)
            guard !existing.contains(where: { $0.kind == choice.kind }) else { continue }
            candidates.append(choice)
        }

        guard !candidates.isEmpty else { return nil }

        let recentKinds = Set(recentRunUpgradeKinds + recentOfferedRunUpgradeKinds)
        let freshCandidates = candidates.filter { !recentKinds.contains($0.kind) }
        if !freshCandidates.isEmpty {
            candidates = freshCandidates
        }

        if !allowDuplicateTag {
            let existingTags = Set(existing.map(\.tag))
            let diverseCandidates = candidates.filter { !existingTags.contains($0.tag) }
            if !diverseCandidates.isEmpty {
                candidates = diverseCandidates
            }
        }

        return pickChoice(from: candidates, seed: seed)
    }

    private func routeRecommendedUpgradeKinds(for route: Int) -> [RunUpgradeKind] {
        switch route {
        case 1:
            return [.shieldCache, .orbitShift, .timeBend, .comboEngine, .sparkBurst]
        case 2:
            return [.magnetBoost, .sparkBurst, .flowState, .scoreSurge, .comboEngine, .overclock]
        case 3:
            return [.shieldCache, .timeBend, .phaseShift, .resonanceField, .orbitShift, .echoCatch]
        case 4:
            return [.pulseRing, .orbitShift, .timeBend, .shieldCache, .voidPulse, .phaseShift]
        case 5:
            return [.echoCatch, .comboEngine, .hyperCombo, .pulseRing, .phaseShift, .voidPulse]
        default:
            switch route % 5 {
            case 1:
                return [.shieldCache, .orbitShift, .flowState, .scoreSurge]
            case 2:
                return [.magnetBoost, .sparkBurst, .flowState, .overclock]
            case 3:
                return [.phaseShift, .resonanceField, .echoCatch, .timeBend]
            case 4:
                return [.pulseRing, .orbitShift, .voidPulse, .shieldCache]
            default:
                return [.hyperCombo, .echoCatch, .comboEngine, .stellarRun]
            }
        }
    }

    private func applyRunUpgrade(_ kind: RunUpgradeKind) {
        recentRunUpgradeKinds.append(kind)
        recentRunUpgradeKinds = Array(recentRunUpgradeKinds.suffix(3))
        runUpgradeCounts[kind, default: 0] += 1
        let upgradeLevel = runUpgradeCounts[kind, default: 1]

        switch kind {
        case .shieldCache:
            grantShield()
            if upgradeLevel > 1 {
                shieldTimeRemaining = min(shieldTimeRemaining + TimeInterval(min(upgradeLevel - 1, 3)) * 1.5, shieldDuration * 2.4)
            }
        case .magnetBoost:
            magnetTimeRemaining = max(magnetTimeRemaining, magnetDuration + 2 + TimeInterval(min(upgradeLevel - 1, 3)) * 1.5)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .timeBend:
            triggerSlowTime(duration: 5.5 + TimeInterval(min(upgradeLevel - 1, 3)) * 1.2)
        case .feverCharge:
            if isFeverActive {
                feverRemaining = min(feverRemaining + 2.5, activeFeverDuration() + 3)
            } else {
                combo = min(feverComboThreshold - 1, combo + 5)
                multiplier = calculatedMultiplier(isFever: false)
            }
            SoundPlayer.feverStart(enabled: isSoundEnabled)
        case .scoreSurge:
            score += max(10, multiplier * (8 + min(upgradeLevel - 1, 4) * 3))
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .comboEngine:
            combo += 5 + min(upgradeLevel - 1, 4)
            multiplier = calculatedMultiplier()
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .overclock:
            score += max(16, multiplier * 9)
            combo += 3
            multiplier = calculatedMultiplier()
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .volatileSurge:
            score += max(32, multiplier * 15)
            combo += 5
            multiplier = calculatedMultiplier()
            shieldCharges = 0
            shieldTimeRemaining = 0
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .compressionGate:
            score += max(42, multiplier * 18)
            nextStageScore = max(score + 85, nextStageScore - 80)
            stageTargetScore = nextStageScore
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .unstableFever:
            if isFeverActive {
                feverRemaining = min(feverRemaining + 3.5, activeFeverDuration() + 4)
            } else {
                combo = min(feverComboThreshold - 1, combo + 8)
                multiplier = calculatedMultiplier(isFever: false)
            }
            magnetTimeRemaining = min(magnetTimeRemaining, 1.2)
            slowTimeRemaining = 0
            SoundPlayer.feverStart(enabled: isSoundEnabled)
        case .orbitShift:
            orbitShiftSerial += 1
            orbitShiftInvulnerabilityRemaining = max(orbitShiftInvulnerabilityRemaining, 0.6)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .sparkBurst:
            sparkBurstSerial += 1
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .pulseRing:
            pulseRingSerial += 1
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .flowState:
            flowStateRemaining = max(flowStateRemaining, 6 + TimeInterval(min(upgradeLevel - 1, 3)) * 1.5)
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .echoCatch:
            echoCatchCharges += 3 + min(upgradeLevel - 1, 3)
            SoundPlayer.shield(enabled: isSoundEnabled)
        case .phaseShift:
            phaseShiftRemaining = max(phaseShiftRemaining, 4 + TimeInterval(min(upgradeLevel - 1, 3)) * 1.0)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .resonanceField:
            magnetTimeRemaining = max(magnetTimeRemaining, 4)
            slowTimeRemaining = max(slowTimeRemaining, 4)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .hyperCombo:
            combo = max(combo, feverComboThreshold - 1)
            multiplier = calculatedMultiplier(isFever: false)
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .voidPulse:
            voidPulseSerial += 1
            voidPulseRemaining = max(voidPulseRemaining, 5)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .chainReactor:
            isChainReactorActive = true
            runMultiplierBonus += 1
            multiplier = calculatedMultiplier()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .singleOrbit:
            singleOrbitRemaining = max(singleOrbitRemaining, 9)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .glitchMode:
            glitchModeRemaining = max(glitchModeRemaining, 8)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .meltdown:
            score += max(0, multiplier * 25)
            combo = 0
            multiplier = 0
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .absoluteCore:
            isAbsoluteCoreUnlocked = true
            activateFever()
            combo = 0
            SoundPlayer.feverStart(enabled: isSoundEnabled)
            SoundPlayer.setFeverActive(true, enabled: isSoundEnabled)
        case .stellarRun:
            stellarMultiplierBonus += 2
            score += 60
            multiplier = calculatedMultiplier()
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.lumen(enabled: isSoundEnabled)
        }
    }

    private func applyStartCard(_ kind: StartCardKind) {
        switch kind {
        case .shieldStart:
            grantShield()
        case .magnetWarmup:
            magnetTimeRemaining = max(magnetTimeRemaining, 5.0)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .comboWarmup:
            combo = max(combo, 4)
            currentComboStreak = max(currentComboStreak, combo)
            updateComboMissionIfNeeded()
            multiplier = calculatedMultiplier()
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .lumenRush:
            lumenRushRemaining = 10
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .overchargedCore:
            runMultiplierBonus += 1
            multiplier = calculatedMultiplier()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .glitchContract:
            isGlitchContractActive = true
            combo = max(combo, 6)
            currentComboStreak = max(currentComboStreak, combo)
            updateComboMissionIfNeeded()
            multiplier = calculatedMultiplier()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .glassCore:
            isGlassCoreActive = true
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        }
    }

    private func stageScoreRequirement(for stage: Int) -> Int {
        130 + min(stage - 2, 6) * 45
    }

    private func activeFeverDuration() -> TimeInterval {
        isAbsoluteCoreUnlocked ? feverDuration * 2 : feverDuration
    }

    private func multiplierCap(isFever: Bool) -> Int {
        (isFever ? 8 : 5) + stellarMultiplierBonus
    }

    private func calculatedMultiplier(isFever: Bool? = nil) -> Int {
        min(multiplierCap(isFever: isFever ?? isFeverActive), 1 + runMultiplierBonus + combo / 5)
    }

    private func activeScoreMultiplier(singleOrbitBonus: Bool = false) -> Int {
        var scoreMultiplier = 1
        if isGlassCoreActive {
            scoreMultiplier *= 2
        }
        if singleOrbitRemaining > 0, singleOrbitBonus {
            scoreMultiplier *= 3
        }
        if glitchModeRemaining > 0 {
            scoreMultiplier *= 2
        }
        return scoreMultiplier
    }

    private func upgradeTitleKey(for kind: RunUpgradeKind) -> String {
        switch kind {
        case .shieldCache:
            return "upgrade.shield.title"
        case .magnetBoost:
            return "upgrade.magnet.title"
        case .timeBend:
            return "upgrade.slow.title"
        case .feverCharge:
            return "upgrade.fever.title"
        case .scoreSurge:
            return "upgrade.score.title"
        case .comboEngine:
            return "upgrade.combo.title"
        case .overclock:
            return "upgrade.overclock.title"
        case .volatileSurge:
            return "upgrade.volatile.title"
        case .compressionGate:
            return "upgrade.compression.title"
        case .unstableFever:
            return "upgrade.unstableFever.title"
        case .orbitShift:
            return "upgrade.orbitShift.title"
        case .sparkBurst:
            return "upgrade.sparkBurst.title"
        case .pulseRing:
            return "upgrade.pulseRing.title"
        case .flowState:
            return "upgrade.flowState.title"
        case .echoCatch:
            return "upgrade.echoCatch.title"
        case .phaseShift:
            return "upgrade.phaseShift.title"
        case .resonanceField:
            return "upgrade.resonanceField.title"
        case .hyperCombo:
            return "upgrade.hyperCombo.title"
        case .voidPulse:
            return "upgrade.voidPulse.title"
        case .chainReactor:
            return "upgrade.chainReactor.title"
        case .singleOrbit:
            return "upgrade.singleOrbit.title"
        case .glitchMode:
            return "upgrade.glitchMode.title"
        case .meltdown:
            return "upgrade.meltdown.title"
        case .absoluteCore:
            return "upgrade.absoluteCore.title"
        case .stellarRun:
            return "upgrade.stellarRun.title"
        }
    }

    private func startCardTitleKey(for kind: StartCardKind) -> String {
        switch kind {
        case .shieldStart:
            return "startCard.shield.title"
        case .magnetWarmup:
            return "startCard.magnet.title"
        case .comboWarmup:
            return "startCard.combo.title"
        case .lumenRush:
            return "startCard.rush.title"
        case .overchargedCore:
            return "startCard.overcharge.title"
        case .glitchContract:
            return "startCard.glitch.title"
        case .glassCore:
            return "startCard.glass.title"
        }
    }

    private func startCardDescriptionKey(for kind: StartCardKind) -> String {
        switch kind {
        case .shieldStart:
            return "startCard.shield.desc"
        case .magnetWarmup:
            return "startCard.magnet.desc"
        case .comboWarmup:
            return "startCard.combo.desc"
        case .lumenRush:
            return "startCard.rush.desc"
        case .overchargedCore:
            return "startCard.overcharge.desc"
        case .glitchContract:
            return "startCard.glitch.desc"
        case .glassCore:
            return "startCard.glass.desc"
        }
    }

    private func startCardSynergyKey(for kind: StartCardKind) -> String {
        switch kind {
        case .shieldStart:
            return "startCard.shield.synergy"
        case .magnetWarmup:
            return "startCard.magnet.synergy"
        case .comboWarmup:
            return "startCard.combo.synergy"
        case .lumenRush:
            return "startCard.rush.synergy"
        case .overchargedCore:
            return "startCard.overcharge.synergy"
        case .glitchContract:
            return "startCard.glitch.synergy"
        case .glassCore:
            return "startCard.glass.synergy"
        }
    }

    private func startCardPreferredTags(for kind: StartCardKind) -> [RunUpgradeTag] {
        switch kind {
        case .shieldStart:
            return [.shield]
        case .magnetWarmup:
            return [.orbit, .harvest]
        case .comboWarmup:
            return [.fever, .harvest]
        case .lumenRush:
            return [.harvest]
        case .overchargedCore:
            return [.harvest, .risk]
        case .glitchContract:
            return [.orbit, .risk]
        case .glassCore:
            return [.harvest, .risk]
        }
    }

    private func startCardIconName(for kind: StartCardKind) -> String {
        switch kind {
        case .shieldStart:
            return "shield.fill"
        case .magnetWarmup:
            return "scope"
        case .comboWarmup:
            return "link.circle.fill"
        case .lumenRush:
            return "sparkles"
        case .overchargedCore:
            return "bolt.circle.fill"
        case .glitchContract:
            return "waveform.path.ecg"
        case .glassCore:
            return "diamond.fill"
        }
    }

    private func startCardCategory(for kind: StartCardKind) -> StartCardCategory {
        switch kind {
        case .shieldStart:
            return .safe
        case .magnetWarmup, .comboWarmup, .lumenRush:
            return .growth
        case .overchargedCore, .glitchContract, .glassCore:
            return .risk
        }
    }

    private func upgradeIconName(for kind: RunUpgradeKind) -> String {
        switch kind {
        case .shieldCache:
            return "shield.fill"
        case .magnetBoost:
            return "dot.radiowaves.left.and.right"
        case .timeBend:
            return "hourglass"
        case .feverCharge:
            return "flame.fill"
        case .scoreSurge:
            return "bolt.fill"
        case .comboEngine:
            return "link.circle.fill"
        case .overclock:
            return "speedometer"
        case .volatileSurge:
            return "bolt.trianglebadge.exclamationmark.fill"
        case .compressionGate:
            return "arrow.down.forward.and.arrow.up.backward.circle.fill"
        case .unstableFever:
            return "flame.circle.fill"
        case .orbitShift:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .sparkBurst:
            return "sparkles"
        case .pulseRing:
            return "wave.3.right.circle.fill"
        case .flowState:
            return "wind"
        case .echoCatch:
            return "shield.lefthalf.filled.badge.checkmark"
        case .phaseShift:
            return "eye.slash.circle.fill"
        case .resonanceField:
            return "dot.radiowaves.forward"
        case .hyperCombo:
            return "flame.circle.fill"
        case .voidPulse:
            return "circle.dashed.inset.filled"
        case .chainReactor:
            return "link.badge.plus"
        case .singleOrbit:
            return "smallcircle.circle.fill"
        case .glitchMode:
            return "shuffle.circle.fill"
        case .meltdown:
            return "exclamationmark.triangle.fill"
        case .absoluteCore:
            return "sun.max.circle.fill"
        case .stellarRun:
            return "star.circle.fill"
        }
    }

    private func upgradeTag(for kind: RunUpgradeKind) -> RunUpgradeTag {
        switch kind {
        case .shieldCache, .echoCatch, .pulseRing:
            return .shield
        case .magnetBoost, .timeBend, .orbitShift, .phaseShift, .resonanceField, .singleOrbit:
            return .orbit
        case .feverCharge, .comboEngine, .unstableFever, .hyperCombo, .absoluteCore:
            return .fever
        case .scoreSurge, .sparkBurst, .flowState, .overclock, .compressionGate, .voidPulse, .stellarRun:
            return .harvest
        case .volatileSurge, .chainReactor, .glitchMode, .meltdown:
            return .risk
        }
    }

    private func upgradeSortIndex(_ kind: RunUpgradeKind) -> Int {
        RunUpgradeKind.allCases.firstIndex(of: kind) ?? 0
    }

    private func runUpgradeChoice(_ kind: RunUpgradeKind) -> RunUpgradeChoice {
        RunUpgradeChoice(
            kind: kind,
            titleKey: upgradeTitleKey(for: kind),
            descriptionKey: upgradeDescriptionKey(for: kind),
            iconName: upgradeIconName(for: kind),
            rarity: upgradeRarity(for: kind),
            tag: upgradeTag(for: kind)
        )
    }

    private func startCardChoice(_ kind: StartCardKind) -> StartCardChoice {
        StartCardChoice(
            kind: kind,
            titleKey: startCardTitleKey(for: kind),
            descriptionKey: startCardDescriptionKey(for: kind),
            synergyKey: startCardSynergyKey(for: kind),
            iconName: startCardIconName(for: kind),
            category: startCardCategory(for: kind)
        )
    }

    private func pickChoice(from pool: [RunUpgradeChoice], seed: Int) -> RunUpgradeChoice {
        pool[abs(seed) % pool.count]
    }

    private func upgradeDescriptionKey(for kind: RunUpgradeKind) -> String {
        switch kind {
        case .shieldCache:
            return "upgrade.shield.desc"
        case .magnetBoost:
            return "upgrade.magnet.desc"
        case .timeBend:
            return "upgrade.slow.desc"
        case .feverCharge:
            return "upgrade.fever.desc"
        case .scoreSurge:
            return "upgrade.score.desc"
        case .comboEngine:
            return "upgrade.combo.desc"
        case .overclock:
            return "upgrade.overclock.desc"
        case .volatileSurge:
            return "upgrade.volatile.desc"
        case .compressionGate:
            return "upgrade.compression.desc"
        case .unstableFever:
            return "upgrade.unstableFever.desc"
        case .orbitShift:
            return "upgrade.orbitShift.desc"
        case .sparkBurst:
            return "upgrade.sparkBurst.desc"
        case .pulseRing:
            return "upgrade.pulseRing.desc"
        case .flowState:
            return "upgrade.flowState.desc"
        case .echoCatch:
            return "upgrade.echoCatch.desc"
        case .phaseShift:
            return "upgrade.phaseShift.desc"
        case .resonanceField:
            return "upgrade.resonanceField.desc"
        case .hyperCombo:
            return "upgrade.hyperCombo.desc"
        case .voidPulse:
            return "upgrade.voidPulse.desc"
        case .chainReactor:
            return "upgrade.chainReactor.desc"
        case .singleOrbit:
            return "upgrade.singleOrbit.desc"
        case .glitchMode:
            return "upgrade.glitchMode.desc"
        case .meltdown:
            return "upgrade.meltdown.desc"
        case .absoluteCore:
            return "upgrade.absoluteCore.desc"
        case .stellarRun:
            return "upgrade.stellarRun.desc"
        }
    }

    private func upgradeRarity(for kind: RunUpgradeKind) -> RunUpgradeRarity {
        switch kind {
        case .shieldCache, .magnetBoost, .timeBend, .scoreSurge, .comboEngine, .orbitShift, .sparkBurst, .pulseRing, .flowState, .echoCatch:
            return .common
        case .feverCharge, .phaseShift, .resonanceField, .hyperCombo, .voidPulse:
            return .rare
        case .overclock:
            return stage >= 3 ? .legendary : .rare
        case .volatileSurge, .compressionGate, .unstableFever, .chainReactor, .singleOrbit, .glitchMode, .meltdown:
            return .risk
        case .absoluteCore, .stellarRun:
            return .legendary
        }
    }
}
