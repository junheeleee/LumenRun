import SpriteKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: GameScene?
    @State private var didScheduleLoading = false
    @State private var isRecordsPresented = false
    @State private var isObjectGuidePresented = false
    @State private var isStageIntroVisible = false
    @State private var isObjectHintVisible = false

    var body: some View {
        ZStack {
            if let scene, !gameState.isLoading, !gameState.isStartScreenPresented {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            gameOverlay

            achievementToastOverlay
            stageIntroOverlay
            objectHintOverlay
            runUpgradeOverlay
            startCardOverlay

            if gameState.isLoading {
                LoadingView()
                    .transition(.opacity)
            } else if gameState.isStartScreenPresented {
                ZStack {
                    StartScreenBackdrop()
                        .ignoresSafeArea()

                    ScrollView(.vertical, showsIndicators: true) {
                        StartView {
                            gameState.startRun()
                        } showRewards: {
                            gameState.showRewards()
                        } showObjectGuide: {
                            isObjectGuidePresented = true
                        }
                        .padding(24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(
            LinearGradient(
                colors: gameState.selectedTheme.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $gameState.isSettingsPresented) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $gameState.isAchievementsPresented) {
            AchievementsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $gameState.isRewardsPresented) {
            RewardsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $gameCenter.isShowingLeaderboard) {
            GameCenterLeaderboardView()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isRecordsPresented) {
            RecordsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isObjectGuidePresented) {
            ObjectGuideView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if scene == nil {
                scene = makeScene()
            }
            gameState.refreshDailyMissionsIfNeeded()
            SoundPlayer.setMusicEnabled(gameState.isSoundEnabled)
            scheduleLoadingFinish()
        }
        .onChange(of: scenePhase) { _, newPhase in
            gameState.setSceneActive(newPhase == .active)
        }
        .onChange(of: gameState.achievementToast?.id) { _, _ in
            scheduleAchievementToastDismiss()
        }
        .onChange(of: gameState.stageResumeSerial) { _, _ in
            scheduleStageIntro()
        }
        .onChange(of: gameState.objectHintSerial) { _, _ in
            scheduleObjectHint()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.isGameOver)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.isUserPaused)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.achievementToast?.id)
    }

    private func makeScene() -> GameScene {
        let scene = GameScene(state: gameState)
        scene.scaleMode = .resizeFill
        return scene
    }

    private var gameOverlay: some View {
        VStack(spacing: 0) {
            if !gameState.isLoading, !gameState.isStartScreenPresented {
                HUDView(
                    openSettings: {
                        gameState.pauseForSettings()
                    },
                    openAchievements: {
                        gameState.showAchievements()
                    },
                    togglePause: {
                        gameState.togglePause()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }

            Spacer()

            if !gameState.hasSeenTutorial, !gameState.isStartScreenPresented, !gameState.isLoading {
                TutorialView {
                    gameState.completeTutorial()
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }

            if gameState.isGameOver {
                ScrollView(.vertical, showsIndicators: true) {
                    GameOverView {
                        gameState.reset()
                        gameState.startRun()
                        scene = makeScene()
                    } showRecords: {
                        isRecordsPresented = true
                    } showAchievements: {
                        gameState.showAchievements()
                    } showRewards: {
                        gameState.showRewards()
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
            }

            if gameState.isUserPaused, gameState.hasSeenTutorial, !gameState.isGameOver {
                PauseView {
                    gameState.resume()
                } showObjectGuide: {
                    isObjectGuidePresented = true
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var stageIntroOverlay: some View {
        if isStageIntroVisible, !gameState.isStartScreenPresented, !gameState.isLoading, !gameState.isGameOver {
            VStack {
                StageIntroToast()
                    .padding(.top, 120)

                Spacer()
            }
            .padding(.horizontal, 20)
            .transition(.scale.combined(with: .opacity))
            .zIndex(7)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var achievementToastOverlay: some View {
        if let achievement = gameState.achievementToast {
            VStack {
                AchievementToastView(achievement: achievement)
                    .padding(.horizontal, 20)
                    .padding(.top, 64)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(8)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var objectHintOverlay: some View {
        if isObjectHintVisible, let kind = gameState.objectHintKind, !gameState.isStartScreenPresented, !gameState.isLoading, !gameState.isGameOver {
            VStack {
                Spacer()

                ObjectHintToast(kind: kind, color: kind.guideColor)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 116)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(7)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var runUpgradeOverlay: some View {
        if gameState.isRunUpgradePresented {
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        Spacer(minLength: 28)

                        RunUpgradeView()
                            .padding(.horizontal, 20)

                        Spacer(minLength: 28)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black.opacity(0.48))
            .transition(.scale(scale: 0.96).combined(with: .opacity))
            .zIndex(10)
        }
    }

    @ViewBuilder
    private var startCardOverlay: some View {
        if gameState.isStartCardPresented {
            StartCardSelectionView()
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.42))
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
        }
    }

    private func scheduleLoadingFinish() {
        guard !didScheduleLoading else { return }
        didScheduleLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            gameState.finishLoading()
        }
    }

    private func scheduleAchievementToastDismiss() {
        guard let achievement = gameState.achievementToast else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            gameState.dismissAchievementToast(achievement)
        }
    }

    private func scheduleStageIntro() {
        guard gameState.stageResumeSerial > 0 else { return }
        isStageIntroVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.05) {
            isStageIntroVisible = false
        }
    }

    private func scheduleObjectHint() {
        let serial = gameState.objectHintSerial
        guard serial > 0 else { return }
        isObjectHintVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            guard gameState.objectHintSerial == serial else { return }
            isObjectHintVisible = false
            gameState.dismissObjectHint(serial: serial)
        }
    }
}

private struct ObjectHintToast: View {
    let kind: LumenObjectKind
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ObjectGuideIcon(kind: kind, color: color)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text("objectHint.new")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(color)
                    .textCase(.uppercase)

                Text(LocalizedStringKey(kind.titleKey))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(kind.descriptionKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 380)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.52), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 18, x: 0, y: 10)
    }
}

private struct StageIntroToast: View {
    @EnvironmentObject private var gameState: GameState
    @State private var isLinked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(gameState.selectedTheme.accentColor.opacity(isLinked ? 0.42 : 0.18), lineWidth: 1)
                        .frame(width: 48, height: 48)
                        .scaleEffect(isLinked ? 1.06 : 0.92)

                    Image(systemName: gameState.stageRouteIconName)
                        .font(.title2.weight(.black))
                        .foregroundStyle(gameState.selectedTheme.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: NSLocalizedString("stage.entering", comment: ""), gameState.stage))
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white.opacity(0.72))
                        .textCase(.uppercase)

                    Text(LocalizedStringKey(gameState.stageRouteTitleKey))
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(LocalizedStringKey(gameState.stageRouteDescriptionKey))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 0)
            }

            RouteSignalPreview(signals: routeSignals)
            RouteLinkMeter(isActive: isLinked, color: gameState.selectedTheme.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 390)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(gameState.selectedTheme.accentColor.opacity(0.48), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 10)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.72)) {
                isLinked = true
            }
        }
    }

    private var routeSignals: [LumenObjectKind] {
        switch gameState.stage {
        case 1:
            return [.spark, .shard]
        case 2:
            return [.spark, .surge, .slow]
        case 3:
            return [.pulse, .magnet, .spark]
        case 4:
            return [.shard, .bomb, .spark]
        case 5:
            return [.void, .shield, .spark]
        default:
            switch gameState.stage % 4 {
            case 1:
                return [.shield, .surge, .shard]
            case 2:
                return [.slow, .spark, .pulse]
            case 3:
                return [.shard, .bomb, .spark]
            default:
                return [.surge, .bomb, .void]
            }
        }
    }
}

private struct RouteSignalPreview: View {
    let signals: [LumenObjectKind]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("routeSignal.title")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.52))
                .textCase(.uppercase)

            HStack(spacing: 6) {
                ForEach(signals) { signal in
                    RouteSignalChip(kind: signal)
                }
            }
        }
    }
}

private struct RouteSignalChip: View {
    let kind: LumenObjectKind

    var body: some View {
        HStack(spacing: 6) {
            ObjectGuideIcon(kind: kind, color: kind.guideColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(kind.titleKey))
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                Text(LocalizedStringKey(roleKey))
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(roleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .background(kind.guideColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(kind.guideColor.opacity(0.3), lineWidth: 1)
        }
    }

    private var roleKey: String {
        switch kind {
        case .spark, .surge:
            return "routeSignal.role.collect"
        case .shield, .slow, .magnet, .bomb:
            return "routeSignal.role.power"
        case .shard, .pulse:
            return "routeSignal.role.avoid"
        case .void:
            return "routeSignal.role.disrupt"
        }
    }

    private var roleColor: Color {
        switch kind {
        case .spark, .surge:
            return LumenBrandColor.gold
        case .shield, .slow, .magnet, .bomb:
            return LumenBrandColor.teal
        case .shard, .pulse:
            return LumenBrandColor.magenta
        case .void:
            return LumenBrandColor.purple
        }
    }
}

private struct RouteLinkMeter: View {
    let isActive: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index == 2 ? LumenBrandColor.gold.opacity(0.82) : color.opacity(0.74))
                    .frame(height: 4)
                    .scaleEffect(x: isActive ? 1 : 0.2, anchor: .leading)
                    .opacity(isActive ? 1 : 0.35)
                    .animation(.easeOut(duration: 0.42).delay(Double(index) * 0.06), value: isActive)
            }
        }
    }
}

private struct RouteClearHeader: View {
    @EnvironmentObject private var gameState: GameState
    let isReady: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RelayBootHalo(isActive: isReady, color: gameState.selectedTheme.accentColor)
                        .frame(width: 58, height: 58)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3.weight(.black))
                        .foregroundStyle(LumenBrandColor.gold)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: NSLocalizedString("upgrade.stageCleared", comment: ""), gameState.clearedStage))
                        .font(.caption.weight(.black))
                        .foregroundStyle(gameState.selectedTheme.accentColor)
                        .textCase(.uppercase)

                    Text(LocalizedStringKey(gameState.clearedStageRouteTitleKey))
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("upgrade.subtitle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                RouteFlowStep(title: "routeFlow.clear", color: LumenBrandColor.gold, isActive: true)
                RouteFlowStep(title: "routeFlow.module", color: gameState.selectedTheme.accentColor, isActive: isReady)
                RouteFlowStep(title: "routeFlow.next", color: LumenBrandColor.teal, isActive: isReady)
            }

            if let dominantTag = gameState.dominantRunUpgradeTag {
                Text(String(format: NSLocalizedString("upgrade.buildFocus", comment: ""), NSLocalizedString(dominantTag.titleKey, comment: "")))
                    .font(.caption2.weight(.black))
                    .foregroundStyle(upgradeTagColor(dominantTag))
                    .textCase(.uppercase)
            }
        }
        .padding(.bottom, 2)
    }
}

private struct RouteFlowStep: View {
    let title: LocalizedStringKey
    let color: Color
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color.opacity(isActive ? 0.95 : 0.34))
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(isActive ? 0.7 : 0), radius: 5)

            Text(title)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .foregroundStyle(.white.opacity(isActive ? 0.88 : 0.46))
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 25)
        .background(color.opacity(isActive ? 0.14 : 0.06), in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(isActive ? 0.34 : 0.16), lineWidth: 1)
        }
    }
}

private struct RunUpgradeView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var isSelectionEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RouteClearHeader(isReady: isSelectionEnabled)

            VStack(spacing: 9) {
                ForEach(gameState.runUpgradeChoices) { choice in
                    VStack(alignment: .leading, spacing: 10) {
                        let rarityColor = rarityColor(choice.rarity)
                        let tagColor = upgradeTagColor(choice.tag)
                        let roleTag = choice.kind.primaryTag
                        let currentLevel = gameState.runUpgradeCounts[choice.kind, default: 0]

                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(roleTag.roleColor.opacity(0.15))
                                .frame(height: 48)

                            Image(systemName: roleTag.iconName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(roleTag.roleColor)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(rarityColor.opacity(0.18))

                                Image(systemName: choice.iconName)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(rarityColor)
                            }
                            .frame(width: 42, height: 42)

                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 7) {
                                    Text(LocalizedStringKey(choice.rarity.titleKey))
                                        .font(.caption2.weight(.black))
                                        .foregroundStyle(rarityColor)
                                        .textCase(.uppercase)
                                        .padding(.horizontal, 7)
                                        .frame(height: 20)
                                        .background(rarityColor.opacity(0.16), in: Capsule())
                                        .overlay {
                                            Capsule()
                                                .stroke(rarityColor.opacity(0.42), lineWidth: 1)
                                        }

                                    Text(LocalizedStringKey(choice.tag.titleKey))
                                        .font(.caption2.weight(.black))
                                        .foregroundStyle(tagColor)
                                        .textCase(.uppercase)
                                        .padding(.horizontal, 7)
                                        .frame(height: 20)
                                        .background(tagColor.opacity(0.14), in: Capsule())
                                        .overlay {
                                            Capsule()
                                                .stroke(tagColor.opacity(0.34), lineWidth: 1)
                                        }

                                    if currentLevel > 0 {
                                        Text(String(format: NSLocalizedString("upgrade.stackLevel", comment: ""), currentLevel, currentLevel + 1))
                                            .font(.caption2.weight(.black))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 7)
                                            .frame(height: 20)
                                            .background(.white.opacity(0.14), in: Capsule())
                                            .overlay {
                                                Capsule()
                                                    .stroke(.white.opacity(0.28), lineWidth: 1)
                                            }
                                    }

                                    Spacer(minLength: 0)
                                }

                                Text(LocalizedStringKey(choice.titleKey))
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)

                                Text(LocalizedStringKey(choice.descriptionKey))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)

                                if choice.rarity == .risk {
                                    RiskTradeoffView(kind: choice.kind)
                                }
                            }

                            Spacer(minLength: 0)

                            Button {
                                guard isSelectionEnabled else { return }
                                gameState.chooseRunUpgrade(choice)
                            } label: {
                                Text("upgrade.choose")
                                    .font(.caption.weight(.black))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(gameState.selectedTheme.accentColor.opacity(isSelectionEnabled ? 0.26 : 0.1), in: Capsule())
                                    .overlay {
                                        Capsule()
                                            .stroke(gameState.selectedTheme.accentColor.opacity(isSelectionEnabled ? 0.62 : 0.22), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(isSelectionEnabled ? .white : .white.opacity(0.42))
                            .disabled(!isSelectionEnabled)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
                    .background(rarityColor(choice.rarity).opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(rarityColor(choice.rarity).opacity(choice.rarity == .common ? 0.18 : 0.52), lineWidth: 1)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: 430)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(gameState.selectedTheme.accentColor.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 22, x: 0, y: 12)
        .onAppear {
            isSelectionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isSelectionEnabled = true
            }
        }
        .onChange(of: gameState.clearedStage) { _, _ in
            isSelectionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isSelectionEnabled = true
            }
        }
    }
}

private struct RiskTradeoffView: View {
    let kind: RunUpgradeKind

    var body: some View {
        HStack(spacing: 6) {
            TradeoffPill(
                iconName: "arrow.up.forward",
                titleKey: "upgrade.riskUpside",
                valueKey: riskUpsideKey(for: kind),
                color: Color(red: 1.0, green: 0.82, blue: 0.28)
            )

            TradeoffPill(
                iconName: "exclamationmark.triangle.fill",
                titleKey: "upgrade.riskCost",
                valueKey: riskCostKey(for: kind),
                color: Color(red: 1.0, green: 0.5, blue: 0.18)
            )
        }
    }
}

private struct TradeoffPill: View {
    let iconName: String
    let titleKey: String
    let valueKey: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2.weight(.black))

            Text(LocalizedStringKey(titleKey))
                .font(.caption2.weight(.black))
                .textCase(.uppercase)

            Text(LocalizedStringKey(valueKey))
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .frame(height: 21)
        .background(color.opacity(0.1), in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

private struct StartCardSelectionView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.stack.fill.badge.plus")
                    .font(.title3.weight(.black))
                    .foregroundStyle(gameState.selectedTheme.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text("startCard.eyebrow")
                        .font(.caption.weight(.black))
                        .foregroundStyle(gameState.selectedTheme.accentColor)
                        .textCase(.uppercase)

                    Text("startCard.title")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)

                    Text("startCard.subtitle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }

            VStack(spacing: 9) {
                ForEach(gameState.startCardChoices) { choice in
                    StartCardButton(choice: choice) {
                        gameState.chooseStartCard(choice)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: 430)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(gameState.selectedTheme.accentColor.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

private struct StartCardButton: View {
    let choice: StartCardChoice
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.18))

                    Image(systemName: choice.iconName)
                        .font(.headline.weight(.black))
                        .foregroundStyle(categoryColor)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(LocalizedStringKey(choice.category.titleKey))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(categoryColor)
                            .textCase(.uppercase)

                        Text(LocalizedStringKey(choice.titleKey))
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    Text(LocalizedStringKey(choice.descriptionKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Label {
                        Text(LocalizedStringKey(choice.synergyKey))
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)
                    } icon: {
                        Image(systemName: "arrow.triangle.branch")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(categoryColor.opacity(0.92))
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(categoryColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(categoryColor.opacity(choice.category == .risk ? 0.48 : 0.28), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var categoryColor: Color {
        switch choice.category {
        case .safe:
            return Color(red: 0.1, green: 0.68, blue: 1.0)
        case .growth:
            return Color(red: 1.0, green: 0.82, blue: 0.28)
        case .risk:
            return Color(red: 1.0, green: 0.24, blue: 0.48)
        }
    }
}

private func rarityColor(_ rarity: RunUpgradeRarity) -> Color {
    switch rarity {
    case .common:
        return Color(red: 0.0, green: 0.92, blue: 0.82)
    case .rare:
        return .cyan
    case .risk:
        return .orange
    case .legendary:
        return .yellow
    }
}

private func upgradeRoleKey(for kind: RunUpgradeKind) -> String {
    switch kind {
    case .shieldCache, .echoCatch, .pulseRing:
        return "upgrade.role.safety"
    case .magnetBoost, .timeBend, .orbitShift, .phaseShift, .resonanceField, .singleOrbit:
        return "upgrade.role.control"
    case .scoreSurge, .sparkBurst, .flowState, .overclock, .volatileSurge, .compressionGate, .voidPulse, .glitchMode, .meltdown, .stellarRun:
        return "upgrade.role.score"
    case .feverCharge, .comboEngine, .unstableFever, .hyperCombo, .absoluteCore:
        return "upgrade.role.fever"
    case .chainReactor:
        return "upgrade.role.risk"
    }
}

private func upgradeRoleColor(for kind: RunUpgradeKind) -> Color {
    switch kind {
    case .shieldCache, .echoCatch, .pulseRing:
        return Color(red: 0.2, green: 0.72, blue: 1.0)
    case .magnetBoost, .timeBend, .orbitShift, .phaseShift, .resonanceField, .singleOrbit:
        return Color(red: 0.56, green: 0.46, blue: 1.0)
    case .scoreSurge, .sparkBurst, .flowState, .overclock, .volatileSurge, .compressionGate, .voidPulse, .glitchMode, .meltdown, .stellarRun:
        return Color(red: 1.0, green: 0.82, blue: 0.28)
    case .feverCharge, .comboEngine, .unstableFever, .hyperCombo, .absoluteCore:
        return Color(red: 1.0, green: 0.32, blue: 0.52)
    case .chainReactor:
        return Color(red: 1.0, green: 0.5, blue: 0.18)
    }
}

private func upgradeTagColor(_ tag: RunUpgradeTag) -> Color {
    tag.roleColor
}

private struct AchievementToastView: View {
    let achievement: AchievementDefinition

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.28).opacity(0.22))

                Image(systemName: achievement.iconName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.34))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text("achievements.toast")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.34))
                    .textCase(.uppercase)

                Text(LocalizedStringKey(achievement.titleKey))
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.86, blue: 0.34).opacity(0.9),
                            Color(red: 0.0, green: 0.92, blue: 0.82).opacity(0.55)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.18).opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

private struct HUDView: View {
    @EnvironmentObject private var gameState: GameState
    let openSettings: () -> Void
    let openAchievements: () -> Void
    let togglePause: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                RelayScorePanel()
                    .layoutPriority(1)

                HUDActionCluster(
                    isPaused: gameState.isUserPaused,
                    isDisabled: !gameState.hasSeenTutorial || gameState.isGameOver,
                    openSettings: openSettings,
                    openAchievements: openAchievements,
                    togglePause: togglePause
                )
            }

            HStack(alignment: .center, spacing: 8) {
                RelayStatusStrip()

                Spacer(minLength: 4)

                PowerupTimersView()
                FeverMeter()
            }

            if !gameState.activeBuildSummaries.isEmpty {
                BuildSummaryView()
            }
        }
    }
}

private struct RelayScorePanel: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(gameState.selectedTheme.accentColor.opacity(0.16))
                RelayCoreMark(size: 27)
            }
            .frame(width: 42, height: 42)
            .overlay {
                Circle()
                    .stroke(gameState.selectedTheme.accentColor.opacity(0.36), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("hud.scoreLabel")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(gameState.selectedTheme.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("\(gameState.displayedScore)")
                    .font(.system(size: 33, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text("hud.best")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.48))

                Text("\(gameState.bestScore)")
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(LumenBrandColor.gold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .frame(width: 58, alignment: .trailing)
        }
        .padding(.horizontal, 11)
        .frame(height: 58)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            gameState.selectedTheme.accentColor.opacity(0.42),
                            .white.opacity(0.12),
                            LumenBrandColor.purple.opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: gameState.selectedTheme.accentColor.opacity(0.12), radius: 14, x: 0, y: 8)
    }
}

private struct HUDActionCluster: View {
    let isPaused: Bool
    let isDisabled: Bool
    let openSettings: () -> Void
    let openAchievements: () -> Void
    let togglePause: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HUDIconButton(
                systemName: isPaused ? "play.fill" : "pause.fill",
                foreground: .white,
                accessibilityKey: LocalizedStringKey(isPaused ? "pause.resume" : "pause.title"),
                action: togglePause
            )
            .disabled(isDisabled)

            HUDIconButton(
                systemName: "trophy.fill",
                foreground: LumenBrandColor.gold,
                accessibilityKey: "achievements.title",
                action: openAchievements
            )

            HUDIconButton(
                systemName: "gearshape.fill",
                foreground: .white,
                accessibilityKey: "settings.title",
                action: openSettings
            )
        }
        .padding(4)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct RelayStatusStrip: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                RelayStatusChip(
                    systemName: "point.3.connected.trianglepath.dotted",
                    text: String(format: NSLocalizedString("hud.route", comment: ""), gameState.stage),
                    color: gameState.selectedTheme.accentColor
                )

                RelayStatusChip(
                    systemName: "scope",
                    text: String(format: NSLocalizedString("hud.goal", comment: ""), gameState.stageTargetScore),
                    color: LumenBrandColor.gold
                )

                RelayStatusChip(
                    systemName: "waveform.path.ecg",
                    text: String(format: NSLocalizedString("hud.level", comment: ""), gameState.displayedLevel),
                    color: LumenBrandColor.teal
                )

                if gameState.displayedMultiplier > 1 {
                    RelayStatusChip(
                        systemName: "bolt.fill",
                        text: "x\(gameState.displayedMultiplier)",
                        color: LumenBrandColor.magenta
                    )
                }
            }
            .padding(.vertical, 1)
        }
        .frame(height: 30)
        .layoutPriority(1)
    }
}

private struct RelayStatusChip: View {
    let systemName: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2.weight(.black))
                .frame(width: 12)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(.caption2.weight(.black))
        .foregroundStyle(.white.opacity(0.9))
        .monospacedDigit()
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(color.opacity(0.14), in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(0.34), lineWidth: 1)
        }
    }
}

private struct BuildSummaryView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                if let startCard = gameState.selectedStartCard {
                    BuildPill(
                        iconName: startCard.iconName,
                        titleKey: startCard.titleKey,
                        suffix: nil,
                        color: startCardCategoryColor(startCard.category),
                        isProminent: startCard.category == .risk
                    )
                }

                ForEach(gameState.activeBuildSummaries) { summary in
                    BuildPill(
                        iconName: summary.iconName,
                        titleKey: summary.titleKey,
                        suffix: summary.count > 1 ? "Lv.\(summary.count)" : nil,
                        color: gameState.selectedTheme.accentColor,
                        isProminent: false
                    )
                }
            }
            .padding(.top, 1)
        }
    }
}

private struct BuildPill: View {
    let iconName: String
    let titleKey: String
    let suffix: String?
    let color: Color
    let isProminent: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.caption2.weight(.black))

            Text(LocalizedStringKey(titleKey))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if let suffix {
                Text(suffix)
                    .monospacedDigit()
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white.opacity(isProminent ? 0.95 : 0.86))
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(color.opacity(isProminent ? 0.2 : 0.13), in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(isProminent ? 0.56 : 0.28), lineWidth: 1)
        }
    }
}

private func riskUpsideKey(for kind: RunUpgradeKind) -> String {
    switch kind {
    case .volatileSurge:
        return "upgrade.riskUpside.volatileSurge"
    case .compressionGate:
        return "upgrade.riskUpside.compressionGate"
    case .unstableFever:
        return "upgrade.riskUpside.unstableFever"
    case .chainReactor:
        return "upgrade.riskUpside.chainReactor"
    case .singleOrbit:
        return "upgrade.riskUpside.singleOrbit"
    case .glitchMode:
        return "upgrade.riskUpside.glitchMode"
    case .meltdown:
        return "upgrade.riskUpside.meltdown"
    default:
        return "upgrade.riskUpside.default"
    }
}

private func riskCostKey(for kind: RunUpgradeKind) -> String {
    switch kind {
    case .volatileSurge:
        return "upgrade.riskCost.volatileSurge"
    case .compressionGate:
        return "upgrade.riskCost.compressionGate"
    case .unstableFever:
        return "upgrade.riskCost.unstableFever"
    case .chainReactor:
        return "upgrade.riskCost.chainReactor"
    case .singleOrbit:
        return "upgrade.riskCost.singleOrbit"
    case .glitchMode:
        return "upgrade.riskCost.glitchMode"
    case .meltdown:
        return "upgrade.riskCost.meltdown"
    default:
        return "upgrade.riskCost.default"
    }
}

private func startCardCategoryColor(_ category: StartCardCategory) -> Color {
    switch category {
    case .safe:
        return Color(red: 0.1, green: 0.68, blue: 1.0)
    case .growth:
        return Color(red: 1.0, green: 0.82, blue: 0.28)
    case .risk:
        return Color(red: 1.0, green: 0.24, blue: 0.48)
    }
}

private struct HUDIconButton: View {
    let systemName: String
    let foreground: Color
    let accessibilityKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(.white.opacity(0.12), in: Circle())
        .contentShape(Circle())
        .accessibilityLabel(Text(accessibilityKey))
    }
}

private struct PauseView: View {
    @EnvironmentObject private var gameState: GameState
    let resume: () -> Void
    let showObjectGuide: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("pause.title")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Button(action: resume) {
                Label("pause.resume", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)

            Button(action: showObjectGuide) {
                Label("objects.title", systemImage: "questionmark.circle.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct LoadingView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var isBooting = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: gameState.selectedTheme.backgroundColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            LumenSignalField()
                .opacity(0.54)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RelayBootHalo(isActive: isBooting, color: gameState.selectedTheme.accentColor)
                        .frame(width: 172, height: 172)

                    LumenSignalMark(size: 116, isCompact: false)
                        .scaleEffect(isBooting ? 1.04 : 0.98)
                }

                Text("loading.title")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                RelayBootSequence(isActive: isBooting, color: gameState.selectedTheme.accentColor)
                    .frame(maxWidth: 280)

                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                isBooting = true
            }
        }
    }
}

private struct StartView: View {
    @EnvironmentObject private var gameState: GameState
    let start: () -> Void
    let showRewards: () -> Void
    let showObjectGuide: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            StartHeroView()

            StartBriefingStrip()

            Button(action: start) {
                Label("start.play", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)

            HStack(spacing: 10) {
                StartActionButton(title: "rewards.title", systemImage: "gift.fill", action: showRewards)
                StartActionButton(title: "objects.title", systemImage: "scope", action: showObjectGuide)
            }
        }
        .padding(.vertical, 28)
    }
}

private struct StartScreenBackdrop: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gameState.selectedTheme.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )

            LumenSignalField()
                .opacity(0.16)

            RadialGradient(
                colors: [
                    gameState.selectedTheme.accentColor.opacity(0.18),
                    .clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 360
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .clear,
                    .black.opacity(0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct StartBriefingStrip: View {
    var body: some View {
        HStack(spacing: 8) {
            StartBriefingPill(icon: "hand.tap.fill", title: "start.brief.tap", color: LumenBrandColor.teal)
            StartBriefingPill(icon: "sparkles", title: "start.brief.spark", color: LumenBrandColor.gold)
            StartBriefingPill(icon: "flame.fill", title: "start.brief.sync", color: LumenBrandColor.magenta)
        }
        .frame(maxWidth: 380)
    }
}

private struct StartBriefingPill: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.black))

            Text(title)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .background(color.opacity(0.1), in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct StartHeroView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var isIgnited = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RelayBootHalo(isActive: isIgnited, color: gameState.selectedTheme.accentColor)
                    .frame(width: 214, height: 214)
                    .opacity(0.82)

                LumenSignalMark(size: 176, isCompact: false)
                    .padding(.bottom, 4)
                    .scaleEffect(isIgnited ? 1.02 : 0.98)

                RouteSignalSweep(isActive: isIgnited, color: gameState.selectedTheme.accentColor)
                    .frame(height: 230)
                    .opacity(0.78)
            }
            .frame(maxWidth: .infinity)

            Text("start.eyebrow")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))
                .tracking(1.8)

            Text("app.title")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gameState.selectedTheme.feverColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .shadow(color: gameState.selectedTheme.accentColor.opacity(0.35), radius: 18, x: 0, y: 10)

            Text("start.subtitle")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            StartStatusRail(isActive: isIgnited)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                isIgnited = true
            }
        }
    }
}

private struct RelayBootHalo: View {
    let isActive: Bool
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .trim(from: 0.08 + CGFloat(index) * 0.04, to: 0.72 + CGFloat(index) * 0.05)
                    .stroke(
                        index == 1 ? LumenBrandColor.gold.opacity(0.74) : color.opacity(0.64),
                        style: StrokeStyle(lineWidth: index == 1 ? 3.2 : 2.2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(isActive ? Double(index) * 42 + 34 : Double(index) * 42 - 18))
                    .scaleEffect(isActive ? 1.0 + CGFloat(index) * 0.055 : 0.94 + CGFloat(index) * 0.045)
                    .opacity(isActive ? 0.9 : 0.48)
                    .shadow(color: color.opacity(0.26), radius: 10)
                    .padding(CGFloat(index) * 16)
            }
        }
    }
}

private struct RelayBootSequence: View {
    let isActive: Bool
    let color: Color

    private let steps: [LocalizedStringKey] = [
        "loading.boot.core",
        "loading.boot.route",
        "loading.boot.signal"
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == 1 ? LumenBrandColor.gold.opacity(0.84) : color.opacity(0.78))
                        .frame(height: 4)
                        .scaleEffect(x: isActive ? 1 : 0.44, anchor: .leading)
                        .opacity(isActive ? 1 : 0.42)
                        .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.12), value: isActive)
                }
            }

            HStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { index in
                    Text(steps[index])
                        .font(.caption2.weight(.black))
                        .foregroundStyle(index == 1 ? LumenBrandColor.gold : color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .opacity(isActive ? 0.9 : 0.46)
                }
            }
        }
    }
}

private struct StartStatusRail: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            StartStatusPill(title: "start.status.core", color: LumenBrandColor.gold, isActive: isActive)
            StartStatusPill(title: "start.status.route", color: LumenBrandColor.teal, isActive: isActive)
            StartStatusPill(title: "start.status.signal", color: LumenBrandColor.magenta, isActive: isActive)
        }
        .frame(maxWidth: 360)
    }
}

private struct StartStatusPill: View {
    let title: LocalizedStringKey
    let color: Color
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.8), radius: isActive ? 6 : 2)

            Text(title)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .foregroundStyle(.white.opacity(0.86))
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background(color.opacity(isActive ? 0.15 : 0.08), in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(isActive ? 0.42 : 0.22), lineWidth: 1)
        }
    }
}

private struct RouteSignalSweep: View {
    let isActive: Bool
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            color.opacity(0.08),
                            .white.opacity(0.28),
                            color.opacity(0.08),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: proxy.size.width * 0.62, height: 2.5)
                .offset(x: isActive ? proxy.size.width * 0.72 : -proxy.size.width * 0.34, y: proxy.size.height * 0.48)
                .blur(radius: 0.2)
                .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: false), value: isActive)
        }
        .allowsHitTesting(false)
    }
}

private struct LumenSignalMark: View {
    let size: CGFloat
    let isCompact: Bool

    var body: some View {
        ZStack {
            routeArc(scale: 0.66, from: 0.08, to: 0.86, rotation: -34, color: LumenBrandColor.teal, lineWidth: size * 0.014)
            routeArc(scale: 0.86, from: 0.18, to: 0.93, rotation: 22, color: LumenBrandColor.gold, lineWidth: size * 0.012)
            routeArc(scale: 1.02, from: 0.28, to: 0.78, rotation: 78, color: LumenBrandColor.magenta, lineWidth: size * 0.01)

            RelayCoreMark(size: size * 0.32)

            RelaySparkMark(size: size * 0.13)
                .offset(relayNodeOffset(0))

            RelayNodeMark(size: size * 0.085, color: LumenBrandColor.teal)
                .offset(relayNodeOffset(1))

            RelayGlitchShardMark(size: size * 0.12)
                .offset(relayNodeOffset(2))

            RelayVoidGateMark(size: size * 0.12)
                .offset(relayNodeOffset(3))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func routeArc(scale: CGFloat, from: CGFloat, to: CGFloat, rotation: Double, color: Color, lineWidth: CGFloat) -> some View {
        Circle()
            .trim(from: from, to: to)
            .stroke(
                LinearGradient(
                    colors: [
                        color.opacity(0.04),
                        color.opacity(0.72),
                        LumenBrandColor.gold.opacity(0.58),
                        color.opacity(0.12)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: max(1.4, lineWidth), lineCap: .round)
            )
            .frame(width: size * scale, height: size * scale)
            .rotationEffect(.degrees(rotation))
            .shadow(color: color.opacity(0.24), radius: size * 0.055)
    }

    private func relayNodeOffset(_ index: Int) -> CGSize {
        let compactScale = isCompact ? 0.72 : 1
        switch index {
        case 0:
            return CGSize(width: size * 0.29 * compactScale, height: -size * 0.17 * compactScale)
        case 1:
            return CGSize(width: -size * 0.34 * compactScale, height: size * 0.02 * compactScale)
        case 2:
            return CGSize(width: size * 0.2 * compactScale, height: size * 0.31 * compactScale)
        default:
            return CGSize(width: -size * 0.18 * compactScale, height: -size * 0.31 * compactScale)
        }
    }
}

private struct RelayCoreMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            LumenBrandColor.gold,
                            LumenBrandColor.teal.opacity(0.78)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.58
                    )
                )

            Circle()
                .stroke(.white.opacity(0.68), lineWidth: max(1.4, size * 0.055))
                .padding(size * 0.12)

            PolygonGuideShape(sides: 4, rotation: .pi / 4)
                .fill(.white.opacity(0.88))
                .frame(width: size * 0.32, height: size * 0.32)

            PlusGuideShape()
                .stroke(LumenBrandColor.teal.opacity(0.9), style: StrokeStyle(lineWidth: max(1.4, size * 0.035), lineCap: .round))
                .frame(width: size * 0.38, height: size * 0.38)
        }
        .frame(width: size, height: size)
        .shadow(color: LumenBrandColor.gold.opacity(0.72), radius: size * 0.48)
    }
}

private struct RelayNodeMark: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.55), lineWidth: max(1, size * 0.12))
            }
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.54), radius: size * 0.8)
    }
}

private struct RelaySparkMark: View {
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            StarGuideShape(points: 5, innerRatio: 0.42)
                .fill(LumenBrandColor.gold)
                .overlay {
                    StarGuideShape(points: 5, innerRatio: 0.42)
                        .stroke(.white.opacity(0.76), lineWidth: max(1, size * 0.08))
                }
                .shadow(color: LumenBrandColor.gold.opacity(0.68), radius: size * 0.48)

            GoodRoleBadge(color: LumenBrandColor.gold)
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(x: size * 0.12, y: -size * 0.12)
        }
        .frame(width: size, height: size)
    }
}

private struct RelayGlitchShardMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            DangerTriangleGuideShape()
                .stroke(LumenBrandColor.magenta.opacity(0.86), style: StrokeStyle(lineWidth: max(1, size * 0.075), lineJoin: .round))
                .frame(width: size * 1.12, height: size * 1.12)

            StarGuideShape(points: 6, innerRatio: 0.58)
                .fill(LumenBrandColor.magenta)
                .overlay {
                    XGuideShape()
                        .stroke(.black.opacity(0.62), style: StrokeStyle(lineWidth: max(1, size * 0.12), lineCap: .round))
                        .padding(size * 0.18)
                }
        }
        .frame(width: size, height: size)
        .shadow(color: LumenBrandColor.magenta.opacity(0.56), radius: size * 0.42)
    }
}

private struct RelayVoidGateMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ArcGuideShape(startAngle: .degrees(-42), endAngle: .degrees(42))
                .stroke(LumenBrandColor.purple.opacity(0.86), style: StrokeStyle(lineWidth: max(3, size * 0.22), lineCap: .round))
                .frame(width: size * 1.2, height: size * 1.2)
                .rotationEffect(.degrees(42))

            DisruptGuideShape()
                .stroke(.white.opacity(0.86), style: StrokeStyle(lineWidth: max(1.3, size * 0.11), lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.64, height: size * 0.64)
        }
        .frame(width: size, height: size)
        .shadow(color: LumenBrandColor.purple.opacity(0.52), radius: size * 0.42)
    }
}

private struct LumenSignalField: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Path { path in
                        let y = height * (0.18 + CGFloat(index) * 0.15)
                        path.move(to: CGPoint(x: width * 0.08, y: y))
                        path.addCurve(
                            to: CGPoint(x: width * 0.92, y: y + CGFloat(index % 2 == 0 ? 18 : -18)),
                            control1: CGPoint(x: width * 0.32, y: y - 28),
                            control2: CGPoint(x: width * 0.68, y: y + 28)
                        )
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                LumenBrandColor.teal.opacity(0.0),
                                LumenBrandColor.teal.opacity(0.18),
                                LumenBrandColor.magenta.opacity(0.12),
                                LumenBrandColor.teal.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private enum LumenBrandColor {
    static let teal = Color(red: 0.0, green: 0.9, blue: 0.82)
    static let gold = Color(red: 1.0, green: 0.86, blue: 0.24)
    static let magenta = Color(red: 1.0, green: 0.22, blue: 0.55)
    static let purple = Color(red: 0.48, green: 0.12, blue: 0.72)
}

private struct StartActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct FeverBackdrop: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        LinearGradient(
            colors: gameState.selectedTheme.feverColors.map { $0.opacity(0.24) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct FeverMeter: View {
    @EnvironmentObject private var gameState: GameState
    private let activeFeverDuration: Double = 5.4

    private var feverBarProgress: Double {
        if gameState.displayedFeverProgress >= 1.0 {
            return min(1, max(0, gameState.displayedFeverSecondsLeft / activeFeverDuration))
        }
        return gameState.displayedFeverProgress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            feverLabel

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.14))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: gameState.selectedTheme.feverColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, proxy.size.width * feverBarProgress))
                        .shadow(color: gameState.selectedTheme.feverColors.first?.opacity(0.45) ?? .clear, radius: gameState.displayedIsFeverActive ? 8 : 3)
                }
            }
            .frame(width: 92, height: 7)
            .clipShape(Capsule())
            .animation(.snappy(duration: 0.18), value: gameState.displayedFeverProgress)
            .animation(.snappy(duration: 0.18), value: gameState.displayedIsFeverActive)
            .animation(.linear(duration: 0.08), value: gameState.displayedFeverSecondsLeft)
        }
        .padding(.horizontal, 7)
        .frame(width: 108, height: 34, alignment: .leading)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    (gameState.displayedIsFeverActive ? LumenBrandColor.gold : gameState.selectedTheme.accentColor)
                        .opacity(gameState.displayedCombo > 0 ? 0.36 : 0.18),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var feverLabel: some View {
        if gameState.displayedIsFeverActive {
            Text(String(format: "%.1f", gameState.displayedFeverSecondsLeft))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(gameState.isFeverEnding ? .red : .yellow)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.black.opacity(0.45), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke((gameState.isFeverEnding ? Color.red : Color.yellow).opacity(0.48), lineWidth: 1)
                }
                .animation(.none, value: gameState.displayedFeverSecondsLeft)
        } else {
            Text(String(format: NSLocalizedString("hud.feverMeter", comment: ""), gameState.displayedCombo, gameState.feverComboGoal))
                .font(.caption2.weight(.black))
                .foregroundStyle(gameState.displayedCombo > 0 ? Color(red: 1.0, green: 0.82, blue: 0.28) : .white.opacity(0.52))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct PowerupTimersView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        HStack(spacing: 5) {
            if gameState.displayedShieldTimeRemaining > 0 {
                PowerupTimerBadge(
                    systemName: "shield.fill",
                    value: gameState.displayedShieldTimeRemaining,
                    color: Color(red: 0.45, green: 0.82, blue: 1.0)
                )
            }
            if gameState.displayedSlowTimeRemaining > 0 {
                PowerupTimerBadge(
                    systemName: "timer",
                    value: gameState.displayedSlowTimeRemaining,
                    color: Color(red: 0.76, green: 0.58, blue: 1.0)
                )
            }
            if gameState.displayedMagnetTimeRemaining > 0 {
                PowerupTimerBadge(
                    systemName: "dot.radiowaves.left.and.right",
                    value: gameState.displayedMagnetTimeRemaining,
                    color: Color(red: 0.24, green: 0.92, blue: 0.84)
                )
            }
        }
        .frame(minWidth: 0, maxWidth: 116, alignment: .trailing)
    }
}

private struct PowerupTimerBadge: View {
    let systemName: String
    let value: TimeInterval
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemName)
                .font(.caption2.weight(.black))
                .frame(width: 12)
            Text("\(Int(ceil(value)))")
                .font(.caption2.weight(.black))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .frame(height: 26)
        .background(color.opacity(0.14), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.42), lineWidth: 1))
    }
}

private struct TutorialView: View {
    @EnvironmentObject private var gameState: GameState
    let start: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("tutorial.title")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("tutorial.body")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.74))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                TutorialRow(icon: "hand.tap.fill", text: "tutorial.step.tap")
                TutorialRow(icon: "sparkles", text: "tutorial.step.collect")
                TutorialRow(icon: "exclamationmark.triangle.fill", text: "tutorial.step.avoid")
                TutorialRow(icon: "bolt.shield.fill", text: "tutorial.step.powerups")
            }

            CoreObjectPrimer()

            Button(action: start) {
                Label("tutorial.start", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CoreObjectPrimer: View {
    private let items: [LumenObjectKind] = [.spark, .shield, .shard]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("tutorial.objects.title")
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.62))
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(items) { item in
                    CoreObjectPrimerItem(kind: item)
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

private struct CoreObjectPrimerItem: View {
    let kind: LumenObjectKind

    var body: some View {
        VStack(spacing: 7) {
            ObjectGuideIcon(kind: kind, color: kind.guideColor)
                .frame(width: 34, height: 34)

            Text(LocalizedStringKey(kind.titleKey))
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(primerKey))
                .font(.caption2.weight(.bold))
                .foregroundStyle(kind.guideColor.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var primerKey: String {
        switch kind {
        case .spark:
            return "tutorial.objects.spark"
        case .shield:
            return "tutorial.objects.shield"
        case .shard:
            return "tutorial.objects.shard"
        case .surge, .slow, .magnet, .bomb, .pulse, .void:
            return kind.descriptionKey
        }
    }
}

private struct TutorialRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 26)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GameOverView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager
    let restart: () -> Void
    let showRecords: () -> Void
    let showAchievements: () -> Void
    let showRewards: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                if gameState.didSetNewBestThisRun {
                    Label("gameover.newBest", systemImage: "crown.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.86, blue: 0.24), Color(red: 1.0, green: 0.52, blue: 0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }

                Text("gameover.title")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(gameState.score)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text(resultSubtitle)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(gameState.didSetNewBestThisRun ? Color(red: 1.0, green: 0.82, blue: 0.28) : .white.opacity(0.66))
                    .monospacedDigit()
            }

            RunFeedbackPanel(
                titleKey: runFeedbackTitleKey,
                detail: runFeedbackDetail,
                nextGoal: nextGoalText
            )

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ResultStatCard(title: "hud.best", value: "\(gameState.bestScore)", icon: "trophy.fill")
                    ResultStatCard(
                        title: "gameover.level.short",
                        value: "\(gameState.level)",
                        icon: "speedometer"
                    )
                }
                HStack(spacing: 8) {
                    ResultStatCard(
                        title: "gameover.missions.short",
                        value: "\(gameState.completedDailyMissionTotal)/\(gameState.dailyMissions.count)",
                        icon: "target"
                    )
                    ResultStatCard(
                        title: "rewards.completedMissions",
                        value: "\(gameState.completedMissionCount)",
                        icon: "checkmark.seal.fill"
                    )
                }
                HStack(spacing: 8) {
                    ResultStatCard(
                        title: "achievements.title",
                        value: "\(gameState.completedAchievementCount)/\(AchievementDefinition.all.count)",
                        icon: "medal.fill"
                    )
                }
            }

            if let unlockText {
                Label(unlockText, systemImage: "lock.open.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if gameCenter.lastSubmissionSucceeded {
                Label("gamecenter.submitted", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.52, green: 1.0, blue: 0.72))
            } else if gameCenter.lastSubmissionError != nil {
                Label("gamecenter.submitFailed", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.32))
            }

            DailyMissionsPanel(isCompact: true)

            Button(action: showRecords) {
                Label("records.title", systemImage: "chart.bar.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button(action: showAchievements) {
                Label("achievements.title", systemImage: "trophy.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button(action: showRewards) {
                Label("rewards.title", systemImage: "gift.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button {
                gameCenter.showLeaderboard()
            } label: {
                Label("gamecenter.leaderboard", systemImage: "list.number")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button(action: restart) {
                Label("gameover.restart", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var resultSubtitle: String {
        if gameState.didSetNewBestThisRun {
            return NSLocalizedString("gameover.newBest.subtitle", comment: "")
        }
        if gameState.bestScoreDelta >= 0 {
            return NSLocalizedString("gameover.tiedBest", comment: "")
        }
        return String(format: NSLocalizedString("gameover.bestDelta", comment: ""), abs(gameState.bestScoreDelta))
    }

    private var runFeedbackTitleKey: LocalizedStringKey {
        if gameState.didSetNewBestThisRun {
            return "gameover.feedback.newBest"
        }
        if gameState.clearedStage >= 4 {
            return "gameover.feedback.deepRun"
        }
        if !gameState.activeBuildSummaries.isEmpty {
            return "gameover.feedback.build"
        }
        return "gameover.feedback.close"
    }

    private var runFeedbackDetail: String {
        if let topBuild = gameState.activeBuildSummaries.first {
            return String(
                format: NSLocalizedString("gameover.feedback.buildDetail", comment: ""),
                NSLocalizedString(topBuild.titleKey, comment: ""),
                topBuild.count
            )
        }
        if let startCard = gameState.selectedStartCard {
            return String(
                format: NSLocalizedString("gameover.feedback.startDetail", comment: ""),
                NSLocalizedString(startCard.titleKey, comment: "")
            )
        }
        return String(
            format: NSLocalizedString("gameover.feedback.stageDetail", comment: ""),
            max(gameState.clearedStage, gameState.stage)
        )
    }

    private var nextGoalText: String {
        if gameState.bestScoreDelta < 0 {
            return String(format: NSLocalizedString("gameover.nextGoal.best", comment: ""), abs(gameState.bestScoreDelta))
        }
        if gameState.completedDailyMissionTotal < gameState.dailyMissions.count {
            return String(
                format: NSLocalizedString("gameover.nextGoal.mission", comment: ""),
                gameState.dailyMissions.count - gameState.completedDailyMissionTotal
            )
        }
        if let remaining = gameState.missionsUntilNextTheme, remaining > 0 {
            return String(format: NSLocalizedString("gameover.nextGoal.reward", comment: ""), remaining)
        }
        return NSLocalizedString("gameover.nextGoal.stage", comment: "")
    }

    private var unlockText: String? {
        guard let nextTheme = gameState.nextLockedTheme, let remaining = gameState.missionsUntilNextTheme else {
            return NSLocalizedString("gameover.allThemesUnlocked", comment: "")
        }
        return String(
            format: NSLocalizedString("gameover.nextTheme", comment: ""),
            remaining,
            NSLocalizedString(nextTheme.titleLocalizationKey, comment: "")
        )
    }
}

private struct RunFeedbackPanel: View {
    let titleKey: LocalizedStringKey
    let detail: String
    let nextGoal: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(titleKey, systemImage: "sparkles")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
                .textCase(.uppercase)

            Text(detail)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                Image(systemName: "scope")
                    .font(.caption.weight(.black))
                Text(nextGoal)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Color(red: 0.0, green: 0.92, blue: 0.82).opacity(0.1), in: Capsule())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct ResultStatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(value)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.play") {
                    Toggle("settings.sound", isOn: $gameState.isSoundEnabled)
                    Toggle("settings.haptics", isOn: $gameState.isHapticsEnabled)
                }

                Section("settings.theme") {
                    ForEach(GameTheme.allCases) { theme in
                        ThemeUnlockRow(theme: theme)
                    }
                    HStack {
                        Text("rewards.completedMissions")
                        Spacer()
                        Text("\(gameState.completedMissionCount)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }

                Section("settings.theme.quick") {
                    Picker("settings.theme", selection: $gameState.selectedTheme) {
                        ForEach(GameTheme.allCases) { theme in
                            Text(theme.titleKey)
                                .tag(theme)
                                .disabled(!gameState.isThemeUnlocked(theme))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings.skin") {
                    ForEach(CoreSkin.allCases) { skin in
                        CoreSkinUnlockRow(skin: skin)
                    }
                }

                Section("settings.record") {
                    HStack {
                        Text("hud.best")
                        Spacer()
                        Text("\(gameState.bestScore)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    Button("settings.resetBest", role: .destructive) {
                        gameState.resetBestScore()
                    }
                    Button("records.reset", role: .destructive) {
                        gameState.resetRunRecords()
                    }
                }

                Section("missions.title") {
                    ForEach(gameState.dailyMissions) { mission in
                        MissionRow(mission: mission)
                    }
                }

                Section("achievements.title") {
                    HStack {
                        Text("achievements.all")
                        Spacer()
                        Text("\(gameState.completedAchievementCount)/\(AchievementDefinition.all.count)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    ForEach(AchievementDefinition.all) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }

                Section("gamecenter.title") {
                    HStack {
                        Text("gamecenter.status")
                        Spacer()
                        Text(gameCenter.isAuthenticated ? gameCenter.playerAlias : NSLocalizedString("gamecenter.notConnected", comment: ""))
                            .fontWeight(.semibold)
                            .foregroundStyle(gameCenter.isAuthenticated ? .primary : .secondary)
                    }

                    Button {
                        gameState.closeSettings()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            gameCenter.showLeaderboard()
                        }
                    } label: {
                        Label("gamecenter.leaderboard", systemImage: "list.number")
                    }
                }

                Section("settings.help") {
                    Button("settings.showTutorial") {
                        gameState.showTutorialAgain()
                    }
                    NavigationLink {
                        ObjectGuideList()
                            .navigationTitle("objects.title")
                    } label: {
                        Label("objects.title", systemImage: "questionmark.circle.fill")
                    }
                }
            }
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        gameState.closeSettings()
                    }
                }
            }
        }
    }
}

private struct ObjectGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ObjectGuideList()
                .navigationTitle("objects.title")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("settings.done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct ObjectGuideList: View {
    private let items = LumenObjectKind.allCases

    var body: some View {
        List {
            Section {
                Text("objects.subtitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("objects.title") {
                ForEach(items) { item in
                    ObjectGuideRow(item: item)
                }
            }
        }
    }
}

private struct ObjectGuideRow: View {
    let item: LumenObjectKind

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.guideColor.opacity(0.16))
                ObjectGuideIcon(kind: item, color: item.guideColor)
                    .frame(width: 32, height: 32)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(item.titleKey))
                    .font(.headline.weight(.bold))
                Text(LocalizedStringKey(item.descriptionKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ObjectGuideIcon: View {
    let kind: LumenObjectKind
    let color: Color

    var body: some View {
        ZStack {
            if isLethalHazard {
                DangerTriangleGuideShape()
                    .stroke(color.opacity(0.82), style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                    .frame(width: 38, height: 38)
            }

            baseObject

            if isCollectible {
                GoodRoleBadge(color: color)
                    .frame(width: 16, height: 16)
                    .offset(x: 11, y: -11)
            }

            switch kind {
            case .spark:
                EmptyView()
            case .surge:
                LightningGuideShape()
                    .fill(.white.opacity(0.9))
                    .frame(width: 18, height: 22)
            case .shield:
                CheckGuideShape()
                    .stroke(.white.opacity(0.92), style: StrokeStyle(lineWidth: 3.1, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 20)
            case .slow:
                VStack(spacing: 6) {
                    Capsule().fill(.white.opacity(0.86)).frame(width: 9, height: 5)
                    Capsule().fill(.white.opacity(0.86)).frame(width: 9, height: 5)
                }
            case .magnet:
                PullArrowGuideShape()
                    .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 22)
            case .bomb:
                ClearSlashGuideShape()
                    .stroke(.white.opacity(0.92), style: StrokeStyle(lineWidth: 3.1, lineCap: .round))
                    .frame(width: 22, height: 22)
            case .shard:
                XGuideShape()
                    .stroke(.black.opacity(0.66), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                    .frame(width: 21, height: 21)
            case .pulse:
                Circle()
                    .stroke(.black.opacity(0.42), lineWidth: 2)
                    .frame(width: 29, height: 29)
                XGuideShape()
                    .stroke(.black.opacity(0.68), style: StrokeStyle(lineWidth: 3.1, lineCap: .round))
                    .frame(width: 21, height: 21)
            case .void:
                DisruptGuideShape()
                    .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
                    .frame(width: 21, height: 21)
                Circle()
                    .fill(color.opacity(0.9))
                    .overlay(Circle().stroke(.white.opacity(0.52), lineWidth: 1))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var isCollectible: Bool {
        switch kind {
        case .spark, .surge, .shield, .slow, .magnet, .bomb:
            return true
        case .shard, .pulse, .void:
            return false
        }
    }

    private var isLethalHazard: Bool {
        switch kind {
        case .shard, .pulse:
            return true
        case .spark, .surge, .shield, .slow, .magnet, .bomb, .void:
            return false
        }
    }

    @ViewBuilder
    private var baseObject: some View {
        switch kind {
        case .spark:
            StarGuideShape(points: 5, innerRatio: 0.42)
                .fill(color)
                .overlay(StarGuideShape(points: 5, innerRatio: 0.42).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .surge:
            PolygonGuideShape(sides: 6, rotation: .pi / 6)
                .fill(color)
                .overlay(PolygonGuideShape(sides: 6, rotation: .pi / 6).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .shield:
            ShieldGuideShape()
                .fill(color)
                .overlay(ShieldGuideShape().stroke(color.opacity(0.95), lineWidth: 1.4))
        case .slow:
            HourglassGuideShape()
                .fill(color)
                .overlay(HourglassGuideShape().stroke(color.opacity(0.95), lineWidth: 1.4))
        case .magnet:
            MagnetBodyGuideShape()
                .fill(color)
                .overlay(MagnetBodyGuideShape().stroke(color.opacity(0.95), lineWidth: 1.4))
        case .bomb:
            BurstGuideShape(points: 8, innerRatio: 0.46)
                .fill(color)
                .overlay(BurstGuideShape(points: 8, innerRatio: 0.46).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .shard:
            StarGuideShape(points: 6, innerRatio: 0.58)
                .fill(color)
                .overlay(StarGuideShape(points: 6, innerRatio: 0.58).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .pulse:
            Circle()
                .fill(color)
                .overlay(Circle().stroke(color.opacity(0.95), lineWidth: 1.6))
        case .void:
            ArcGuideShape(startAngle: .degrees(-15), endAngle: .degrees(15))
                .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
    }
}

private struct GoodRoleBadge: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.96))
            Circle()
                .stroke(.white.opacity(0.92), lineWidth: 1.3)
            PlusGuideShape()
                .stroke(.white.opacity(0.95), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .padding(4.2)
        }
    }
}

private struct ArcGuideShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) * 0.42
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

private struct PlusGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct DangerTriangleGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.46
        let rotation = -CGFloat.pi / 2

        for index in 0..<3 {
            let angle = CGFloat(index) / 3 * 2 * .pi + rotation
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct DisruptGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: rect.minX + width * 0.14, y: rect.minY + height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.44, y: rect.minY + height * 0.48))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.24, y: rect.minY + height * 0.48))
        path.move(to: CGPoint(x: rect.minX + width * 0.86, y: rect.minY + height * 0.82))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.56, y: rect.minY + height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.76, y: rect.minY + height * 0.52))
        return path
    }
}

private struct StarGuideShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) * 0.47
        let inner = outer * innerRatio

        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) / CGFloat(points * 2) * 2 * .pi - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct BurstGuideShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        StarGuideShape(points: points, innerRatio: innerRatio).path(in: rect)
    }
}

private struct MagnetBodyGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: rect.minX + width * 0.06, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.36, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.36, y: rect.minY + height * 0.58))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.64, y: rect.minY + height * 0.58),
            control: CGPoint(x: rect.midX, y: rect.minY + height * 0.88)
        )
        path.addLine(to: CGPoint(x: rect.minX + width * 0.64, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.94, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.94, y: rect.minY + height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.06, y: rect.minY + height * 0.6),
            control: CGPoint(x: rect.midX, y: rect.minY + height * 1.12)
        )
        path.closeSubpath()
        return path
    }
}

private struct PullArrowGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.midY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.7))
        return path
    }
}

private struct ClearSlashGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.22))
        return path
    }
}

private struct PolygonGuideShape: Shape {
    let sides: Int
    let rotation: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.45

        for index in 0..<sides {
            let angle = CGFloat(index) / CGFloat(sides) * 2 * .pi + rotation
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct ShieldGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.42
        let top = center.y - radius * 0.75
        let shoulder = center.y - radius * 0.1
        let tip = center.y + radius * 1.15

        path.move(to: CGPoint(x: center.x - radius, y: top))
        path.addLine(to: CGPoint(x: center.x + radius, y: top))
        path.addLine(to: CGPoint(x: center.x + radius, y: shoulder))
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: tip),
            control: CGPoint(x: center.x + radius * 0.72, y: center.y + radius * 0.64)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - radius, y: shoulder),
            control: CGPoint(x: center.x - radius * 0.72, y: center.y + radius * 0.64)
        )
        path.closeSubpath()
        return path
    }
}

private struct HourglassGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.43
        let width = radius * 0.78
        let waist = radius * 0.18

        path.move(to: CGPoint(x: center.x - width, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + width, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y))
        path.addLine(to: CGPoint(x: center.x + width, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - width, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y))
        path.closeSubpath()
        return path
    }
}

private struct LightningGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x + size * 0.08, y: center.y - size * 0.5))
        path.addLine(to: CGPoint(x: center.x - size * 0.36, y: center.y - size * 0.05))
        path.addLine(to: CGPoint(x: center.x - size * 0.04, y: center.y - size * 0.05))
        path.addLine(to: CGPoint(x: center.x - size * 0.18, y: center.y + size * 0.5))
        path.addLine(to: CGPoint(x: center.x + size * 0.36, y: center.y - size * 0.08))
        path.addLine(to: CGPoint(x: center.x + size * 0.04, y: center.y - size * 0.08))
        path.closeSubpath()
        return path
    }
}

private struct CheckGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.2))
        return path
    }
}

private struct XGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

private struct AchievementsView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("achievements.all")
                        Spacer()
                        Text("\(gameState.completedAchievementCount)/\(AchievementDefinition.all.count)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }

                Section("achievements.title") {
                    ForEach(AchievementDefinition.all) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
            .navigationTitle("achievements.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        gameState.closeAchievements()
                    }
                }
            }
        }
    }
}

private struct AchievementRow: View {
    @EnvironmentObject private var gameState: GameState
    let achievement: AchievementDefinition

    var body: some View {
        let progress = gameState.achievementProgress(for: achievement)
        let isUnlocked = gameState.isAchievementUnlocked(achievement)

        HStack(spacing: 12) {
            Image(systemName: isUnlocked ? "checkmark.seal.fill" : achievement.iconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(LocalizedStringKey(achievement.titleKey))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isUnlocked ? .primary : .secondary)
                    Spacer()
                    AchievementStatusBadge(isUnlocked: isUnlocked)
                }

                Text(LocalizedStringKey(achievement.descriptionKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(progress), total: Double(achievement.target))
                    .tint(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 0.0, green: 0.92, blue: 0.82))

                Text("\(progress)/\(achievement.target)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 3)
    }
}

private struct AchievementStatusBadge: View {
    let isUnlocked: Bool

    var body: some View {
        Label(
            isUnlocked ? "rewards.unlocked" : "achievements.locked",
            systemImage: isUnlocked ? "checkmark.seal.fill" : "lock.fill"
        )
        .font(.caption2.weight(.black))
        .labelStyle(.titleAndIcon)
        .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72).opacity(0.12) : Color.secondary.opacity(0.12))
        )
    }
}

private struct ThemeUnlockRow: View {
    @EnvironmentObject private var gameState: GameState
    let theme: GameTheme

    var body: some View {
        Button {
            guard gameState.isThemeUnlocked(theme) else { return }
            gameState.selectedTheme = theme
        } label: {
            HStack(spacing: 12) {
                LinearGradient(
                    colors: theme.feverColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.24), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.titleKey)
                        .font(.headline.weight(.bold))
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: trailingIcon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(gameState.selectedTheme == theme ? gameState.selectedTheme.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!gameState.isThemeUnlocked(theme))
    }

    private var subtitle: String {
        if gameState.isThemeUnlocked(theme) {
            return NSLocalizedString("rewards.unlocked", comment: "")
        }
        return String(format: NSLocalizedString("rewards.unlockAt", comment: ""), theme.unlockRequirement)
    }

    private var trailingIcon: String {
        if gameState.selectedTheme == theme {
            return "checkmark.circle.fill"
        }
        return gameState.isThemeUnlocked(theme) ? "circle" : "lock.fill"
    }
}

private struct CoreSkinUnlockRow: View {
    @EnvironmentObject private var gameState: GameState
    let skin: CoreSkin

    var body: some View {
        Button {
            guard gameState.isCoreSkinUnlocked(skin) else { return }
            gameState.selectedCoreSkin = skin
        } label: {
            HStack(spacing: 12) {
                Image(systemName: skin.iconName)
                    .font(.title3.weight(.black))
                    .foregroundStyle(gameState.selectedTheme.accentColor)
                    .frame(width: 34, height: 34)
                    .background(.secondary.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(skin.titleKey)
                        .font(.headline.weight(.bold))
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: trailingIcon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(gameState.selectedCoreSkin == skin ? gameState.selectedTheme.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!gameState.isCoreSkinUnlocked(skin))
    }

    private var subtitle: String {
        if gameState.isCoreSkinUnlocked(skin) {
            return NSLocalizedString("rewards.unlocked", comment: "")
        }
        return String(format: NSLocalizedString("rewards.unlockAt", comment: ""), skin.unlockRequirement)
    }

    private var trailingIcon: String {
        if gameState.selectedCoreSkin == skin {
            return "checkmark.circle.fill"
        }
        return gameState.isCoreSkinUnlocked(skin) ? "circle" : "lock.fill"
    }
}

private struct RewardsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    DailyMissionsPanel()
                    RewardShowcasePanel()
                }
                    .padding(20)
            }
            .navigationTitle(Text("rewards.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct RewardShowcasePanel: View {
    @EnvironmentObject private var gameState: GameState
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("rewards.previewTitle", systemImage: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
                Spacer()
                Text("\(gameState.completedMissionCount)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.72))
                    .monospacedDigit()
            }

            Text("rewards.previewSubtitle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))

            RewardCategoryRow(title: "settings.theme", icon: "paintpalette.fill") {
                ForEach(GameTheme.allCases) { theme in
                    let isUnlocked = gameState.isThemeUnlocked(theme)
                    let isSelected = gameState.selectedTheme == theme
                    RewardPreviewCard(
                        title: theme.titleKey,
                        subtitle: rewardSubtitle(required: theme.unlockRequirement, isUnlocked: isUnlocked, isSelected: isSelected),
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onSelect: {
                            if isUnlocked {
                                gameState.selectedTheme = theme
                            }
                        }
                    ) {
                        LinearGradient(
                            colors: theme.feverColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            }

            RewardCategoryRow(title: "settings.skin", icon: "circle.hexagongrid.fill") {
                ForEach(CoreSkin.allCases) { skin in
                    let isUnlocked = gameState.isCoreSkinUnlocked(skin)
                    let isSelected = gameState.selectedCoreSkin == skin
                    RewardPreviewCard(
                        title: skin.titleKey,
                        subtitle: rewardSubtitle(required: skin.unlockRequirement, isUnlocked: isUnlocked, isSelected: isSelected),
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onSelect: {
                            if isUnlocked {
                                gameState.selectedCoreSkin = skin
                            }
                        }
                    ) {
                        ZStack {
                            Circle()
                                .fill(gameState.selectedTheme.accentColor.opacity(0.22))
                            Image(systemName: skin.iconName)
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(gameState.selectedTheme.accentColor)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func rewardSubtitle(required: Int, isUnlocked: Bool, isSelected: Bool) -> String {
        if isSelected {
            return NSLocalizedString("rewards.equipped", comment: "")
        }
        if isUnlocked {
            return NSLocalizedString("rewards.tapToEquip", comment: "")
        }
        let remaining = max(0, required - gameState.completedMissionCount)
        return String(format: NSLocalizedString("rewards.remaining", comment: ""), remaining)
    }
}

private struct RewardCategoryRow<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.76))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    content()
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct RewardPreviewCard<Preview: View>: View {
    let title: LocalizedStringKey
    let subtitle: String
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    preview()
                        .frame(width: 94, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .opacity(isUnlocked ? 1 : 0.52)

                    Image(systemName: isUnlocked ? (isSelected ? "checkmark.circle.fill" : "hand.tap.fill") : "lock.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : .white.opacity(0.78))
                        .padding(5)
                }

                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(subtitle)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 1.0, green: 0.82, blue: 0.28))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .padding(9)
        .frame(width: 112, height: 118, alignment: .topLeading)
        .background(.white.opacity(isSelected ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color(red: 0.52, green: 1.0, blue: 0.72).opacity(0.7) : .white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct DailyMissionsPanel: View {
    @EnvironmentObject private var gameState: GameState
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("missions.title", systemImage: "target")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))

            VStack(spacing: isCompact ? 7 : 9) {
                ForEach(gameState.dailyMissions) { mission in
                    MissionRow(mission: mission)
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MissionRow: View {
    let mission: DailyMission

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: mission.isCompleted ? "checkmark.seal.fill" : iconName)
                    .foregroundStyle(mission.isCompleted ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 1.0, green: 0.82, blue: 0.28))
                    .frame(width: 18)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 8)

                Text("\(mission.clampedProgress)/\(mission.target)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.7))
                    .monospacedDigit()
            }

            ProgressView(value: Double(mission.clampedProgress), total: Double(mission.target))
                .tint(mission.isCompleted ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 0.0, green: 0.92, blue: 0.82))
                .scaleEffect(x: 1, y: 0.7, anchor: .center)
        }
    }

    private var title: String {
        switch mission.kind {
        case .score:
            return String(format: NSLocalizedString("missions.score", comment: ""), mission.target)
        case .sparks:
            return String(format: NSLocalizedString("missions.sparks", comment: ""), mission.target)
        case .fever:
            return String(format: NSLocalizedString("missions.fever", comment: ""), mission.target)
        case .shields:
            return String(format: NSLocalizedString("missions.shields", comment: ""), mission.target)
        case .combo:
            return String(format: NSLocalizedString("missions.combo", comment: ""), mission.target)
        case .stages:
            return String(format: NSLocalizedString("missions.stages", comment: ""), mission.target)
        case .surges:
            return String(format: NSLocalizedString("missions.surges", comment: ""), mission.target)
        case .bombs:
            return String(format: NSLocalizedString("missions.bombs", comment: ""), mission.target)
        }
    }

    private var iconName: String {
        switch mission.kind {
        case .score:
            return "flag.checkered"
        case .sparks:
            return "sparkles"
        case .fever:
            return "flame.fill"
        case .shields:
            return "shield.fill"
        case .combo:
            return "link.circle.fill"
        case .stages:
            return "flag.checkered.circle.fill"
        case .surges:
            return "bolt.fill"
        case .bombs:
            return "burst.fill"
        }
    }
}

private struct RecordsView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("records.top") {
                    if gameState.topRunRecords.isEmpty {
                        Text("records.empty")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(gameState.topRunRecords.enumerated()), id: \.element.id) { index, record in
                            RunRecordRow(rank: index + 1, record: record)
                        }
                    }
                }

                Section("records.recent") {
                    if gameState.recentRunRecords.isEmpty {
                        Text("records.empty")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(gameState.recentRunRecords.enumerated()), id: \.element.id) { index, record in
                            RunRecordRow(rank: index + 1, record: record)
                        }
                    }
                }
            }
            .navigationTitle("records.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct RunRecordRow: View {
    let rank: Int
    let record: RunRecord

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.headline.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: NSLocalizedString("records.score", comment: ""), record.score))
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                Text(String(format: NSLocalizedString("gameover.level", comment: ""), record.level))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.date, style: .date)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
