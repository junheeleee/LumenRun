import SpriteKit

final class GameScene: SKScene {
    private enum RunPattern: CaseIterable {
        case flow
        case gate
        case switchback
        case harvest
        case pulseChase
        case voidTrap
        case overdrive
    }

    private enum NodeName {
        static let player = "player"
        static let star = "star"
        static let feverPulse = "feverPulse"
    }

    private let state: GameState
    private let playerRadius: CGFloat = 14
    private let orbitRadii: [CGFloat] = [76, 112, 148]
    private let collisionRadiusTolerance: CGFloat = 9
    private let powerUpBlockerNames = Set([
        LumenObjectKind.shard.nodeName,
        LumenObjectKind.pulse.nodeName,
        LumenObjectKind.void.nodeName,
        LumenObjectKind.shield.nodeName,
        LumenObjectKind.slow.nodeName,
        LumenObjectKind.magnet.nodeName,
        LumenObjectKind.bomb.nodeName,
        LumenObjectKind.surge.nodeName
    ])
    private let orbitTransitionDuration: TimeInterval = 0.16
    private var currentRadius: CGFloat = 76
    private var targetRadius: CGFloat = 76
    private var orbitStartRadius: CGFloat = 76
    private var orbitTransitionElapsed: TimeInterval = 0
    private var currentOrbitIndex = 0
    private var orbitStepDirection = 1
    private var angle: CGFloat = -.pi / 2
    private var previousAngle: CGFloat = -.pi / 2
    private var angularSpeed: CGFloat = 1.66
    private var lastUpdate: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0
    private var safeUntil: TimeInterval = 1.6
    private var invulnerableUntil: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var sparkTimer: TimeInterval = 0
    private var powerUpTimer: TimeInterval = 0
    private var comboTimer: TimeInterval = 0
    private var cleanupTimer: TimeInterval = 0
    private var patternTimer: TimeInterval = 0
    private var patternWaveTimer: TimeInterval = 0
    private var patternDuration: TimeInterval = 8.5
    private var patternIndex = 0
    private var patternStep = 0
    private var currentPattern: RunPattern = .flow
    private var lastScreenFlashTime: TimeInterval = -10
    private var lastFeverFlashTime: TimeInterval = -10
    private var lastSparkCollectFeedbackTime: TimeInterval = -10
    private var lastMagnetCollectFeedbackTime: TimeInterval = -10
    private var lastFeverConversionFeedbackTime: TimeInterval = -10
    private var objectVisualTimer: TimeInterval = 0
    private var pendingMagnetSparkCount = 0
    private var pendingMagnetSingleOrbitBonusCount = 0
    private var pendingMagnetFeedbackPoint: CGPoint?
    private var magnetScoreFlushTimer: TimeInterval = 0
    private var didWarnFeverEnding = false
    private var didSpawnOpeningRoute = false
    private var difficulty: CGFloat = 1
    private var renderedTheme: GameTheme?
    private var renderedCoreSkin: CoreSkin?
    private var renderedFeverActive = false
    private var renderedShieldCharges = -1
    private var renderedStageClearSerial = 0
    private var renderedStageResumeSerial = 0
    private var renderedOrbitShiftSerial = 0
    private var renderedSparkBurstSerial = 0
    private var renderedPulseRingSerial = 0
    private var renderedVoidPulseSerial = 0
    private var renderedStage = 1
    private var lockedSingleOrbitIndex: Int?
    private var wasSingleOrbitActive = false
    private var wasPhaseShiftActive = false
    private var wasGlitchModeActive = false
    private var glitchSwapTimer: TimeInterval = 0
    private var shownObjectHints = Set<LumenObjectKind>()
    private var hasShownSparkScoreLabel = false
    private var hasShownFeverRoleLabel = false

    private lazy var player = SKShapeNode(circleOfRadius: playerRadius)
    private lazy var shieldAura = SKShapeNode(path: shieldPath(radius: 30))
    private lazy var feverLabel: SKLabelNode = {
        let label = SKLabelNode(text: NSLocalizedString("hud.fever", comment: ""))
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 42
        label.zPosition = 30
        label.alpha = 0
        label.isHidden = true
        return label
    }()
    private lazy var stageClearLabel: SKLabelNode = {
        let label = SKLabelNode(text: "")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 30
        label.zPosition = 31
        label.alpha = 0
        label.isHidden = true
        return label
    }()
    private lazy var nextMoveCue: SKShapeNode = {
        let node = SKShapeNode(path: nextMoveChevronPath(size: 15))
        node.fillColor = .clear
        node.lineWidth = 2.4
        node.lineCap = .round
        node.lineJoin = .round
        node.zPosition = 4.6
        node.alpha = 0.48
        return node
    }()
    private let motePath = CGPath(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6), transform: nil)
    private lazy var cachedShardPath = hazardShardPath(radius: LumenObjectKind.shard.baseRadius)
    private lazy var cachedPulsePath = smallCirclePath(radius: LumenObjectKind.pulse.baseRadius)
    private lazy var cachedSparkPath = starPath(
        outerRadius: LumenObjectKind.spark.baseRadius,
        innerRadius: LumenObjectKind.spark.baseRadius * 0.42,
        points: 5
    )
    private lazy var cachedBombPath = burstPath(
        outerRadius: LumenObjectKind.bomb.baseRadius * 1.12,
        innerRadius: LumenObjectKind.bomb.baseRadius * 0.46,
        points: 8
    )
    private lazy var cachedSurgePath = hexPath(radius: LumenObjectKind.surge.baseRadius)
    private lazy var cachedMagnetPath = magnetBodyPath(radius: LumenObjectKind.magnet.baseRadius)
    private lazy var cachedShieldPath = shieldPath(radius: LumenObjectKind.shield.baseRadius)
    private lazy var cachedSlowPath = hourglassPath(radius: LumenObjectKind.slow.baseRadius)
    private let orbitLayer = SKNode()
    private let objectLayer = SKNode()
    private let effectLayer = SKNode()

    init(state: GameState) {
        self.state = state
        super.init(size: .zero)
        backgroundColor = state.selectedTheme.sceneBackgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isMultipleTouchEnabled = false
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        setupScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        drawOrbits()
        drawStars()
        updatePlayerPosition()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switchOrbitAndDirection()
    }

    private func switchOrbitAndDirection() {
        guard !state.isGameOver else { return }
        guard !state.isPaused else { return }
        if state.singleOrbitRemaining <= 0 {
            advanceOrbit()
        } else if let lockedSingleOrbitIndex {
            currentOrbitIndex = lockedSingleOrbitIndex
            currentRadius = orbitRadii[lockedSingleOrbitIndex]
            targetRadius = currentRadius
            orbitStartRadius = currentRadius
            orbitTransitionElapsed = orbitTransitionDuration
            pulseOrbit(at: currentRadius, color: state.selectedTheme.sparkColor, duration: 0.22)
        }
        angularSpeed *= -1
        SoundPlayer.tap(enabled: state.isSoundEnabled)
        Haptics.tap(enabled: state.isHapticsEnabled)
    }

    private func advanceOrbit() {
        currentOrbitIndex += orbitStepDirection
        if currentOrbitIndex >= orbitRadii.count - 1 {
            currentOrbitIndex = orbitRadii.count - 1
        } else if currentOrbitIndex <= 0 {
            currentOrbitIndex = 0
        }
        updateOrbitStepDirectionForEdge()
        orbitStartRadius = currentRadius
        orbitTransitionElapsed = 0
        targetRadius = orbitRadii[currentOrbitIndex]
    }

    private func updateOrbitStepDirectionForEdge() {
        if currentOrbitIndex >= orbitRadii.count - 1 {
            orbitStepDirection = -1
        } else if currentOrbitIndex <= 0 {
            orbitStepDirection = 1
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if renderedTheme != state.selectedTheme || renderedCoreSkin != state.selectedCoreSkin {
            applyTheme()
        }
        if renderedFeverActive != state.isFeverActive {
            renderedFeverActive = state.isFeverActive
            if state.isFeverActive {
                didWarnFeverEnding = false
                triggerFeverBurst()
                convertNearbyShardsForFever()
            } else {
                didWarnFeverEnding = false
                refreshNextMoveCueStyle()
                if !state.isGameOver {
                    triggerFeverEndBurst()
                }
            }
        }
        if renderedShieldCharges != state.shieldCharges {
            renderedShieldCharges = state.shieldCharges
            refreshShieldAura()
        }
        if renderedStage != state.stage {
            renderedStage = state.stage
            drawStars()
            drawOrbits()
        }
        if renderedStageClearSerial != state.stageClearSerial {
            renderedStageClearSerial = state.stageClearSerial
            presentStageClear()
        }
        if renderedStageResumeSerial != state.stageResumeSerial {
            renderedStageResumeSerial = state.stageResumeSerial
            startNextStage()
        }
        if renderedOrbitShiftSerial != state.orbitShiftSerial {
            renderedOrbitShiftSerial = state.orbitShiftSerial
            performOrbitShift()
        }
        if renderedSparkBurstSerial != state.sparkBurstSerial {
            renderedSparkBurstSerial = state.sparkBurstSerial
            performSparkBurst()
        }
        if renderedPulseRingSerial != state.pulseRingSerial {
            renderedPulseRingSerial = state.pulseRingSerial
            performPulseRing()
        }
        if renderedVoidPulseSerial != state.voidPulseSerial {
            renderedVoidPulseSerial = state.voidPulseSerial
            performVoidPulse()
        }

        guard !state.isPaused else { return }
        let delta = lastUpdate > 0 ? min(currentTime - lastUpdate, 1 / 20) : 0
        lastUpdate = currentTime
        elapsedTime += delta

        difficulty = 1 + CGFloat(difficultyProgress) * stageDifficultyPressure
        let timeScale: CGFloat = state.slowTimeRemaining > 0 ? 0.62 : 1
        let feverScale: CGFloat = state.isFeverActive ? 1.52 : 1
        previousAngle = angle
        angle += angularSpeed * difficulty * timeScale * feverScale * CGFloat(delta)
        updateOrbitRadius(delta: delta)
        spawnTimer += delta
        sparkTimer += delta
        powerUpTimer += delta
        comboTimer += delta
        cleanupTimer += delta
        patternTimer += delta
        patternWaveTimer += delta
        objectVisualTimer += delta
        let visualDelta = objectVisualTimer
        let shouldUpdateObjectVisuals = visualDelta >= objectVisualUpdateInterval
        if shouldUpdateObjectVisuals {
            objectVisualTimer = 0
        }
        state.tick(delta: delta)
        updateTimedUpgradeEffects(delta: delta)
        updateMovingHazards(delta: delta, visualDelta: visualDelta, updateVisuals: shouldUpdateObjectVisuals)
        updateFeverEndingCue()

        if comboTimer > comboBreakInterval {
            state.breakCombo()
        }

        updateRunPattern()
        updatePatternSpawns()

        if powerUpTimer > powerInterval(easy: 10.5, hard: 6.2) {
            spawnPowerUp()
            powerUpTimer = 0
        }

        updatePlayerPosition()
        updateMagnetPull(delta: delta)
        checkCollisions()
        cleanupTransientNodesIfNeeded()
    }

    private func setupScene() {
        removeAllChildren()
        resetRunState()
        addChild(orbitLayer)
        addChild(objectLayer)
        addChild(effectLayer)

        player.name = NodeName.player
        player.strokeColor = .white
        player.zPosition = 5
        addChild(nextMoveCue)
        addChild(player)
        addChild(feverLabel)
        addChild(stageClearLabel)
        setupShieldAura()
        player.alpha = 1
        targetRadius = currentRadius
        player.run(.sequence([.scale(to: 0.82, duration: 0.1), .scale(to: 1.0, duration: 0.28)]), withKey: "spawnPulse")

        applyTheme()
        drawStars()
        drawOrbits()
        updatePlayerPosition()
    }

    private func resetRunState() {
        currentRadius = orbitRadii[0]
        targetRadius = orbitRadii[0]
        orbitStartRadius = orbitRadii[0]
        orbitTransitionElapsed = orbitTransitionDuration
        currentOrbitIndex = 0
        orbitStepDirection = 1
        angle = -.pi / 2
        previousAngle = angle
        angularSpeed = abs(angularSpeed)
        lastUpdate = 0
        elapsedTime = 0
        safeUntil = 1.6
        invulnerableUntil = 0
        spawnTimer = 0
        sparkTimer = 0
        powerUpTimer = 0
        comboTimer = 0
        cleanupTimer = 0
        patternTimer = 0
        patternWaveTimer = 0
        objectVisualTimer = 0
        pendingMagnetSparkCount = 0
        pendingMagnetSingleOrbitBonusCount = 0
        pendingMagnetFeedbackPoint = nil
        magnetScoreFlushTimer = 0
        patternDuration = 8.5
        patternIndex = 0
        patternStep = 0
        currentPattern = stageOpeningPattern
        lastScreenFlashTime = -10
        lastFeverFlashTime = -10
        lastSparkCollectFeedbackTime = -10
        lastMagnetCollectFeedbackTime = -10
        lastFeverConversionFeedbackTime = -10
        didWarnFeverEnding = false
        didSpawnOpeningRoute = false
        difficulty = 1
        renderedShieldCharges = -1
        renderedFeverActive = state.isFeverActive
        renderedStageClearSerial = state.stageClearSerial
        renderedStageResumeSerial = state.stageResumeSerial
        renderedOrbitShiftSerial = state.orbitShiftSerial
        renderedSparkBurstSerial = state.sparkBurstSerial
        renderedPulseRingSerial = state.pulseRingSerial
        renderedVoidPulseSerial = state.voidPulseSerial
        renderedStage = state.stage
        lockedSingleOrbitIndex = nil
        wasSingleOrbitActive = state.singleOrbitRemaining > 0
        wasPhaseShiftActive = state.phaseShiftRemaining > 0
        wasGlitchModeActive = state.glitchModeRemaining > 0
        glitchSwapTimer = 0
        shownObjectHints.removeAll()
        hasShownSparkScoreLabel = false
        hasShownFeverRoleLabel = false

        resetPlayerVisuals()
        shieldAura.removeAllActions()
        shieldAura.setScale(1)
        shieldAura.alpha = 0
    }

    private func resetPlayerVisuals() {
        player.removeAllActions()
        player.setScale(1)
        player.alpha = 1
        player.isHidden = false
        feverLabel.removeAllActions()
        feverLabel.alpha = 0
        feverLabel.isHidden = true
        stageClearLabel.removeAllActions()
        stageClearLabel.alpha = 0
        stageClearLabel.isHidden = true
    }

    private func presentStageClear() {
        guard state.clearedStage > 0 else { return }
        flushPendingMagnetSparks(force: true)
        lastUpdate = 0
        spawnTimer = 0
        sparkTimer = 0
        powerUpTimer = 0
        patternTimer = 0
        patternWaveTimer = 0
        comboTimer = 0
        objectLayer.children.forEach { node in
            node.removeAllActions()
            node.run(.sequence([
                .group([
                    .fadeOut(withDuration: 0.16),
                    .scale(to: 0.2, duration: 0.16)
                ]),
                .removeFromParent()
            ]))
        }
        effectLayer.removeAllChildren()
        resetPlayerVisuals()
        safeUntil = max(safeUntil, elapsedTime + 1.2)
        invulnerableUntil = max(invulnerableUntil, elapsedTime + 1.2)
        SoundPlayer.stageClear(enabled: state.isSoundEnabled)
        Haptics.collect(enabled: state.isHapticsEnabled)
        pulseStageClearRings()
        showStageClearLabel()
    }

    private func startNextStage() {
        flushPendingMagnetSparks(force: true)
        lastUpdate = 0
        spawnTimer = 0
        sparkTimer = 0
        powerUpTimer = 0
        patternTimer = 0
        patternWaveTimer = 0
        patternStep = 0
        patternIndex += 1
        currentPattern = stageOpeningPattern
        didSpawnOpeningRoute = false
        objectLayer.removeAllChildren()
        drawStars()
        drawOrbits()
        safeUntil = max(safeUntil, elapsedTime + 1.8)
        invulnerableUntil = max(invulnerableUntil, elapsedTime + 1.0)
        lockedSingleOrbitIndex = state.singleOrbitRemaining > 0 ? currentOrbitIndex : nil
        glitchSwapTimer = 0
        resetPlayerVisuals()
        pulseOrbit(at: currentRadius, color: stageAccentColor, duration: 0.5)
        spawnOpeningRoute()
    }

    private func performOrbitShift() {
        let nextIndex: Int
        if currentOrbitIndex >= orbitRadii.count - 1 {
            nextIndex = max(0, currentOrbitIndex - 1)
        } else {
            nextIndex = min(orbitRadii.count - 1, currentOrbitIndex + 1)
        }

        currentOrbitIndex = nextIndex
        updateOrbitStepDirectionForEdge()
        orbitStartRadius = currentRadius
        orbitTransitionElapsed = 0
        targetRadius = orbitRadii[nextIndex]
        invulnerableUntil = max(invulnerableUntil, elapsedTime + 0.6)
        removeNearbyShards(clearance: 0.76)
        pulseOrbit(at: targetRadius, color: state.selectedTheme.timeCoreColor, duration: 0.36)
        signalRing(at: player.position, color: state.selectedTheme.timeCoreColor, radius: 62, duration: 0.24, lineWidth: 2)
    }

    private func performSparkBurst() {
        let baseAngle = normalizedAngle(angle + (angularSpeed >= 0 ? 0.16 : -0.16))
        for offset in [-0.12, -0.04, 0.05, 0.13] {
            spawnSpark(on: currentRadius, near: normalizedAngle(baseAngle + CGFloat(offset)))
        }
        emitCollectSignal(at: player.position, color: state.selectedTheme.sparkColor, count: 8)
    }

    private func performPulseRing() {
        let cleared = clearAllShards(color: state.selectedTheme.timeCoreColor)
        let radius = (orbitRadii.last ?? 148) + 24
        shockwave(at: center, color: state.selectedTheme.timeCoreColor, radius: radius)
        flash(color: state.selectedTheme.timeCoreColor.withAlphaComponent(cleared > 0 ? 0.16 : 0.08))
    }

    private func performVoidPulse() {
        objectLayer.children.forEach { node in
            emitGlitchClearSignal(at: node.position, color: state.selectedTheme.feverColor, count: 3, radius: 34)
            node.removeFromParent()
        }
        flash(color: state.selectedTheme.feverColor.withAlphaComponent(0.16))
        shockwave(at: center, color: state.selectedTheme.feverColor, radius: (orbitRadii.last ?? 148) + 38)
        spawnOpeningRoute()
    }

    private func updateTimedUpgradeEffects(delta: TimeInterval) {
        updateSingleOrbitEffect()
        updatePhaseShiftEffect()
        updateGlitchModeEffect(delta: delta)
    }

    private func updateSingleOrbitEffect() {
        let isActive = state.singleOrbitRemaining > 0
        if isActive, !wasSingleOrbitActive {
            lockedSingleOrbitIndex = currentOrbitIndex
            targetRadius = orbitRadii[currentOrbitIndex]
            orbitStartRadius = targetRadius
            currentRadius = targetRadius
            orbitTransitionElapsed = orbitTransitionDuration
            pulseOrbit(at: currentRadius, color: state.selectedTheme.sparkColor, duration: 0.46)
        } else if !isActive, wasSingleOrbitActive {
            lockedSingleOrbitIndex = nil
            pulseOrbit(at: currentRadius, color: stageAccentColor, duration: 0.3)
        }
        wasSingleOrbitActive = isActive
    }

    private func updatePhaseShiftEffect() {
        let isActive = state.phaseShiftRemaining > 0
        if isActive != wasPhaseShiftActive {
            player.removeAction(forKey: "phaseShiftPulse")
            if isActive {
                player.alpha = 0.46
                player.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.32, duration: 0.26),
                    .fadeAlpha(to: 0.58, duration: 0.26)
                ])), withKey: "phaseShiftPulse")
                pulseOrbit(at: currentRadius, color: state.selectedTheme.timeCoreColor, duration: 0.42)
            } else {
                player.alpha = 1
            }
        }
        wasPhaseShiftActive = isActive
    }

    private func updateGlitchModeEffect(delta: TimeInterval) {
        let isActive = state.glitchModeRemaining > 0
        if isActive, !wasGlitchModeActive {
            glitchSwapTimer = 1.2
            flash(color: objectColor(for: .surge).withAlphaComponent(0.14))
        } else if !isActive, wasGlitchModeActive {
            glitchSwapTimer = 0
        }

        guard isActive else {
            wasGlitchModeActive = false
            return
        }

        glitchSwapTimer += delta
        if glitchSwapTimer >= 1.2 {
            glitchSwapTimer = 0
            randomGlitchOrbitSwap()
        }
        wasGlitchModeActive = true
    }

    private func randomGlitchOrbitSwap() {
        guard state.singleOrbitRemaining <= 0 else { return }
        guard orbitRadii.count > 1 else { return }
        let options = orbitRadii.indices.filter { $0 != currentOrbitIndex }
        guard let nextIndex = options.randomElement() else { return }
        currentOrbitIndex = nextIndex
        updateOrbitStepDirectionForEdge()
        orbitStartRadius = currentRadius
        orbitTransitionElapsed = 0
        targetRadius = orbitRadii[nextIndex]
        angularSpeed *= Bool.random() ? 1 : -1
        invulnerableUntil = max(invulnerableUntil, elapsedTime + 0.32)
        pulseOrbit(at: targetRadius, color: objectColor(for: .surge), duration: 0.28)
        emitGlitchFragments(at: player.position, color: objectColor(for: .surge))
    }

    private func updateMovingHazards(delta: TimeInterval, visualDelta: TimeInterval, updateVisuals: Bool) {
        for node in objectLayer.children {
            guard let kind = node.lumenObjectKind else { continue }
            if kind == .pulse {
                updatePulseNode(node, delta: delta)
            } else if kind == .void {
                updateVoidNode(node)
            }
            if updateVisuals {
                updateObjectVisualMotion(node, kind: kind, delta: visualDelta)
            }
        }
    }

    private func updateObjectVisualMotion(_ node: SKNode, kind: LumenObjectKind, delta: TimeInterval) {
        let phase = storedCGFloat(for: node, key: "visualPhase") ?? 0
        let t = CGFloat(elapsedTime) + phase

        switch kind {
        case .spark:
            node.setScale(1.0 + sin(t * 4.2) * 0.08)
            node.zRotation += CGFloat(delta) * 0.9
        case .shard:
            node.setScale(1.0 + sin(t * 5.4) * 0.045)
            node.zRotation += CGFloat(delta) * 2.4
        case .pulse:
            node.setScale(1.0 + sin(t * 5.0) * 0.06)
        case .void:
            break
        case .shield, .slow, .magnet, .bomb, .surge:
            node.setScale(1.0 + sin(t * 3.4) * 0.055)
            node.zRotation += CGFloat(delta) * 0.42
        }
    }

    private func updatePulseNode(_ node: SKNode, delta: TimeInterval) {
        guard let radius = storedRadius(for: node) else { return }
        let currentAngle = storedAngle(for: node) ?? angle
        let angularVelocity = storedCGFloat(for: node, key: "angularVelocity") ?? -0.4
        let nextAngle = normalizedAngle(currentAngle + angularVelocity * CGFloat(delta))
        node.position = point(on: radius, angle: nextAngle)
        node.userData?["angle"] = nextAngle
    }

    private func updateVoidNode(_ node: SKNode) {
        let expiresAt = storedDouble(for: node, key: "expiresAt") ?? 0
        guard expiresAt > 0 else { return }
        let remaining = expiresAt - elapsedTime
        if remaining <= 0 {
            node.removeFromParent()
        } else if remaining < 0.55 {
            node.alpha = max(0.08, CGFloat(remaining / 0.55) * 0.75)
        }
    }

    private func pulseStageClearRings() {
        flash(color: stageAccentColor.withAlphaComponent(0.2))
        for (index, radius) in orbitRadii.enumerated() {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = stageAccentColor.withAlphaComponent(0.74)
            ring.fillColor = .clear
            ring.lineWidth = 3
            ring.glowWidth = 13
            ring.zPosition = 12
            effectLayer.addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: TimeInterval(index) * 0.05),
                .group([
                    .scale(to: 1.32, duration: 0.42),
                    .fadeOut(withDuration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
        emitBurst(at: center, color: stageAccentColor, count: 10)
        signalRing(at: center, color: .white.withAlphaComponent(0.82), radius: (orbitRadii.last ?? 148) + 34, duration: 0.36, lineWidth: 2)
    }

    private func showStageClearLabel() {
        stageClearLabel.removeAllActions()
        stageClearLabel.text = String(format: NSLocalizedString("stage.clear.label", comment: ""), state.clearedStage)
        stageClearLabel.fontColor = stageAccentColor
        stageClearLabel.position = CGPoint(x: center.x, y: center.y + 42)
        stageClearLabel.alpha = 0
        stageClearLabel.setScale(0.78)
        stageClearLabel.isHidden = false

        let appear = SKAction.group([
            .fadeIn(withDuration: 0.08),
            .scale(to: 1.08, duration: 0.14)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 0.45)
        let disappear = SKAction.group([
            .fadeOut(withDuration: 0.22),
            .moveBy(x: 0, y: 16, duration: 0.22)
        ])
        stageClearLabel.run(.sequence([
            appear,
            settle,
            hold,
            disappear,
            .run { [weak self] in
                self?.stageClearLabel.isHidden = true
            }
        ]), withKey: "stageClearLabel")
    }

    private func refreshPlayerIdentityMark() {
        player.removeAllChildren()

        let inner = SKShapeNode(circleOfRadius: playerRadius * 0.38)
        inner.fillColor = .white.withAlphaComponent(0.9)
        inner.strokeColor = state.selectedTheme.sparkColor.withAlphaComponent(0.95)
        inner.lineWidth = 1.5
        inner.glowWidth = 5
        inner.zPosition = 1
        player.addChild(inner)

        for rotation in [CGFloat(-0.45), CGFloat(0.45)] {
            let signal = SKShapeNode(path: arcPath(radius: playerRadius * 0.83, startAngle: -.pi * 0.18, endAngle: .pi * 0.52))
            signal.strokeColor = .white.withAlphaComponent(0.76)
            signal.lineWidth = 1.3
            signal.glowWidth = 2
            signal.lineCap = .round
            signal.zRotation = rotation
            signal.zPosition = 1
            player.addChild(signal)
        }
    }

    private func applyTheme() {
        renderedTheme = state.selectedTheme
        renderedCoreSkin = state.selectedCoreSkin
        backgroundColor = state.selectedTheme.sceneBackgroundColor
        player.path = playerPath(for: state.selectedCoreSkin)
        player.fillColor = state.selectedTheme.playerColor
        player.strokeColor = .white.withAlphaComponent(0.92)
        player.lineWidth = state.selectedCoreSkin.lineWidth
        player.glowWidth = state.selectedCoreSkin.glowWidth
        refreshPlayerIdentityMark()
        refreshShieldAura()
        refreshNextMoveCueStyle()
        drawOrbits()
        for node in objectLayer.children {
            guard let shape = node as? SKShapeNode else { continue }
            guard let kind = shape.lumenObjectKind else { continue }
            shape.fillColor = kind == .void ? .clear : objectColor(for: kind)
            shape.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        }
    }

    private func drawOrbits() {
        orbitLayer.removeAllChildren()

        for (index, radius) in orbitRadii.enumerated() {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = state.isFeverActive
                ? state.selectedTheme.feverColor.withAlphaComponent(0.35 + CGFloat(index) * 0.12)
                : stageAccentColor.withAlphaComponent(0.13 + CGFloat(index) * 0.08)
            ring.lineWidth = state.isFeverActive ? 3 : 2
            ring.glowWidth = state.isFeverActive ? 7 : 2
            orbitLayer.addChild(ring)

            addSignalSegments(to: orbitLayer, radius: radius, index: index)
            addRelayNodes(to: orbitLayer, radius: radius, index: index)
        }

        addStageSignature(to: orbitLayer)

        let core = SKShapeNode(circleOfRadius: 42)
        core.position = center
        core.fillColor = (state.isFeverActive ? state.selectedTheme.feverColor : stageSecondaryColor).withAlphaComponent(0.12)
        core.strokeColor = (state.isFeverActive ? state.selectedTheme.feverColor : stageAccentColor).withAlphaComponent(0.44)
        core.lineWidth = state.isFeverActive ? 3 : 2
        core.glowWidth = state.isFeverActive ? 16 : 8
        orbitLayer.addChild(core)

        if state.isFeverActive {
            let pulse = SKShapeNode(circleOfRadius: orbitRadii.last ?? 148)
            pulse.name = NodeName.feverPulse
            pulse.position = center
            pulse.strokeColor = state.selectedTheme.feverColor.withAlphaComponent(0.4)
            pulse.lineWidth = 1
            pulse.glowWidth = 16
            pulse.run(.repeatForever(.sequence([
                .group([.scale(to: 1.08, duration: 0.45), .fadeAlpha(to: 0.08, duration: 0.45)]),
                .group([.scale(to: 1.0, duration: 0.05), .fadeAlpha(to: 0.7, duration: 0.05)])
            ])))
            orbitLayer.addChild(pulse)
        }
    }

    private func drawStars() {
        children.filter { $0.name == NodeName.star }.forEach { $0.removeFromParent() }
        let colors = stageStarColors
        let starCount = 36 + min(state.stage, 5) * 3
        for _ in 0..<starCount {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.4))
            star.name = NodeName.star
            star.position = CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)), y: CGFloat.random(in: 0...max(size.height, 1)))
            star.fillColor = colors.randomElement()?.withAlphaComponent(CGFloat.random(in: 0.18...0.56)) ?? .white
            star.strokeColor = .clear
            star.zPosition = -2
            addChild(star)
        }
    }

    private var stageAccentColor: SKColor {
        switch state.stage % 4 {
        case 1:
            return state.selectedTheme.playerColor
        case 2:
            return state.selectedTheme.timeCoreColor
        case 3:
            return state.selectedTheme.shieldColor
        default:
            return state.selectedTheme.feverColor
        }
    }

    private var stageSecondaryColor: SKColor {
        switch state.stage % 4 {
        case 1:
            return state.selectedTheme.sparkColor
        case 2:
            return state.selectedTheme.shieldColor
        case 3:
            return state.selectedTheme.sparkColor
        default:
            return objectColor(for: .surge)
        }
    }

    private var stageStarColors: [SKColor] {
        switch state.stage % 4 {
        case 1:
            return [.white, state.selectedTheme.sparkColor, state.selectedTheme.playerColor]
        case 2:
            return [.white, state.selectedTheme.timeCoreColor, state.selectedTheme.shieldColor]
        case 3:
            return [.white, state.selectedTheme.shieldColor, state.selectedTheme.sparkColor]
        default:
            return [.white, state.selectedTheme.feverColor, objectColor(for: .surge)]
        }
    }

    private var stageOpeningPattern: RunPattern {
        switch state.stage {
        case 1:
            return .flow
        case 2:
            return .harvest
        case 3:
            return .pulseChase
        case 4:
            return .gate
        case 5:
            return .voidTrap
        default:
            switch state.stage % 4 {
            case 1:
                return .flow
            case 2:
                return .harvest
            case 3:
                return .gate
            default:
                return .switchback
            }
        }
    }

    private var stageDifficultyPressure: CGFloat {
        switch state.stage {
        case 1:
            return 0.46
        case 2:
            return 0.54
        case 3:
            return 0.68
        case 4:
            return 0.76
        case 5:
            return 0.82
        default:
            return min(0.9, 0.72 + CGFloat(state.stage - 5) * 0.025)
        }
    }

    private var stageThreatIntervalScale: Double {
        switch state.stage {
        case 1:
            return 1.22
        case 2:
            return 1.18
        case 3:
            return 0.98
        case 4:
            return 0.9
        case 5:
            return 0.92
        default:
            return max(0.86, 1.02 - Double(state.stage - 5) * 0.025)
        }
    }

    private var stageSparkIntervalScale: Double {
        switch state.stage {
        case 1:
            return 0.9
        case 2:
            return 0.78
        case 3:
            return 0.9
        case 4:
            return 0.96
        case 5:
            return 0.9
        default:
            return 0.88
        }
    }

    private var stagePowerIntervalScale: Double {
        switch state.stage {
        case 1:
            return 1.08
        case 2:
            return 0.78
        case 3:
            return 0.84
        case 4:
            return 0.86
        case 5:
            return 0.86
        default:
            return 0.9
        }
    }

    private var stagePatternIntervalScale: Double {
        switch state.stage {
        case 1:
            return 1.12
        case 2:
            return 1.0
        case 3:
            return 0.86
        case 4:
            return 0.86
        case 5:
            return 0.84
        default:
            return max(0.78, 0.92 - Double(state.stage - 5) * 0.02)
        }
    }

    private var stagePatternDurationScale: Double {
        switch state.stage {
        case 1:
            return 1.1
        case 2:
            return 0.94
        case 3:
            return 0.88
        case 4:
            return 0.86
        case 5:
            return 0.9
        default:
            return 0.86
        }
    }

    private var comboBreakInterval: Double {
        switch state.stage {
        case 1:
            return scaledInterval(easy: 4.1, hard: 2.6)
        case 2:
            return scaledInterval(easy: 3.75, hard: 2.32)
        default:
            return scaledInterval(easy: 3.45, hard: 2.05)
        }
    }

    private var voidSpawnChance: CGFloat {
        switch state.stage {
        case 5:
            return 0.24
        case 6...:
            return min(0.32, 0.18 + CGFloat(state.stage - 5) * 0.025)
        default:
            return 0
        }
    }

    private func addSignalSegments(to layer: SKNode, radius: CGFloat, index: Int) {
        let segmentCount = state.isFeverActive ? 5 : 4
        let arcLength: CGFloat = state.isFeverActive ? 0.34 : 0.24
        let baseOffset = CGFloat(index) * 0.42

        for segment in 0..<segmentCount {
            let angle = CGFloat(segment) / CGFloat(segmentCount) * 2 * .pi + baseOffset
            let path = arcPath(radius: radius, startAngle: angle, endAngle: angle + arcLength)
            let node = SKShapeNode(path: path)
            node.position = center
            node.strokeColor = (state.isFeverActive ? state.selectedTheme.feverColor : stageAccentColor)
                .withAlphaComponent(state.isFeverActive ? 0.72 : 0.34)
            node.lineWidth = state.isFeverActive ? 4 : 2.6
            node.glowWidth = state.isFeverActive ? 12 : 5
            node.lineCap = .round
            layer.addChild(node)
        }
    }

    private func addRelayNodes(to layer: SKNode, radius: CGFloat, index: Int) {
        let nodeAngles: [CGFloat] = [
            -.pi / 2 + CGFloat(index) * 0.32,
            .pi * 0.16 + CGFloat(index) * 0.26,
            .pi * 0.82 + CGFloat(index) * 0.2
        ]

        for nodeAngle in nodeAngles {
            let marker = SKShapeNode(circleOfRadius: state.isFeverActive ? 4.2 : 3.2)
            marker.position = point(on: radius, angle: nodeAngle)
            marker.fillColor = (state.isFeverActive ? state.selectedTheme.feverColor : stageSecondaryColor)
                .withAlphaComponent(state.isFeverActive ? 0.9 : 0.58)
            marker.strokeColor = .white.withAlphaComponent(0.34)
            marker.lineWidth = 0.8
            marker.glowWidth = state.isFeverActive ? 9 : 4
            layer.addChild(marker)
        }
    }

    private func addStageSignature(to layer: SKNode) {
        switch state.stage {
        case 2:
            addStageArcMotif(to: layer, color: state.selectedTheme.sparkColor, count: 8, span: 0.16, lineWidth: 2.8)
        case 3:
            addStageArcMotif(to: layer, color: objectColor(for: .pulse), count: 3, span: 0.38, lineWidth: 2.4)
        case 4:
            addGateLaneMotif(to: layer)
        case 5:
            addVoidLaneMotif(to: layer)
        default:
            if state.stage > 5 {
                addStageArcMotif(to: layer, color: stageSecondaryColor, count: 6, span: 0.28, lineWidth: 2.6)
            }
        }
    }

    private func addStageArcMotif(to layer: SKNode, color: SKColor, count: Int, span: CGFloat, lineWidth: CGFloat) {
        guard let radius = orbitRadii.last else { return }
        for index in 0..<count {
            let baseAngle = CGFloat(index) / CGFloat(count) * 2 * .pi + CGFloat(state.stage) * 0.08
            let node = SKShapeNode(path: arcPath(radius: radius + 18, startAngle: baseAngle, endAngle: baseAngle + span))
            node.position = center
            node.strokeColor = color.withAlphaComponent(0.18)
            node.fillColor = .clear
            node.lineWidth = lineWidth
            node.glowWidth = lineWidth
            node.lineCap = .round
            node.zPosition = -0.5
            layer.addChild(node)
        }
    }

    private func addGateLaneMotif(to layer: SKNode) {
        for (index, radius) in orbitRadii.enumerated() {
            for segment in 0..<4 {
                let angle = CGFloat(segment) * .pi / 2 + CGFloat(index) * 0.18
                let node = SKShapeNode(path: arcPath(radius: radius, startAngle: angle - 0.08, endAngle: angle + 0.08))
                node.position = center
                node.strokeColor = state.selectedTheme.shardColor.withAlphaComponent(0.26)
                node.fillColor = .clear
                node.lineWidth = 4.2
                node.glowWidth = 6
                node.lineCap = .round
                node.zPosition = 0
                layer.addChild(node)
            }
        }
    }

    private func addVoidLaneMotif(to layer: SKNode) {
        for (index, radius) in orbitRadii.enumerated() {
            let angle = -.pi / 3 + CGFloat(index) * 0.74
            let node = SKShapeNode(path: arcPath(radius: radius, startAngle: angle - 0.22, endAngle: angle + 0.22))
            node.position = center
            node.strokeColor = objectColor(for: .void).withAlphaComponent(0.24)
            node.fillColor = .clear
            node.lineWidth = 5.5
            node.glowWidth = 10
            node.lineCap = .round
            node.zPosition = 0
            layer.addChild(node)
        }
    }

    private func updateRunPattern() {
        guard elapsedTime > safeUntil + 2 else { return }
        guard patternTimer >= patternDuration else { return }

        patternIndex += 1
        let sequence = availablePatternSequence()
        currentPattern = sequence[patternIndex % sequence.count]
        patternTimer = 0
        patternWaveTimer = 0
        patternStep = 0
        patternDuration = patternDurationInterval(easy: 11.5, hard: 7.4)
        telegraphPatternStart(currentPattern)
    }

    private func availablePatternSequence() -> [RunPattern] {
        if state.stage <= 1 {
            return [.flow, .harvest]
        }
        if state.stage == 2 {
            return [.harvest, .harvest, .flow, .gate]
        }
        if state.stage == 3 {
            return [.pulseChase, .pulseChase, .switchback, .harvest]
        }
        if state.stage == 4 {
            return [.gate, .gate, .switchback, .overdrive]
        }
        return [.voidTrap, .voidTrap, .gate, .pulseChase, .overdrive]
    }

    private func updatePatternSpawns() {
        guard elapsedTime > safeUntil else { return }

        if !didSpawnOpeningRoute {
            didSpawnOpeningRoute = true
            presentRouteStartSignature()
            spawnOpeningRoute()
        }

        switch currentPattern {
        case .flow:
            if state.stage == 1 {
                updateIntroFlowPattern()
                return
            }
            if spawnTimer > threatInterval(easy: 1.95, hard: 0.92) {
                spawnShard()
                spawnTimer = 0
            }
            if elapsedTime > 0.45, sparkTimer > sparkInterval(easy: 1.14, hard: 0.7) {
                spawnSpark()
                if shouldSpawnRewardFork(step: patternStep) {
                    spawnChoiceFork()
                }
                patternStep += 1
                sparkTimer = 0
            }
        case .gate:
            let gateEasy = state.stage == 4 ? 1.92 : 2.24
            let gateHard = state.stage == 4 ? 1.04 : 1.22
            if spawnTimer > threatInterval(easy: gateEasy, hard: gateHard) {
                if state.stage >= 4, patternStep % 4 == 3 {
                    spawnGateCorridorStep()
                } else {
                    spawnGateWave()
                }
                spawnTimer = 0
            }
            if sparkTimer > sparkInterval(easy: 1.2, hard: 0.76) {
                spawnSpark()
                sparkTimer = 0
            }
        case .switchback:
            if patternWaveTimer > patternInterval(easy: 1.3, hard: 0.76) {
                spawnSwitchbackStep()
                patternWaveTimer = 0
            }
            if sparkTimer > sparkInterval(easy: 1.12, hard: 0.74) {
                spawnSpark(on: orbitRadii[patternStep % orbitRadii.count], near: nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.74))
                sparkTimer = 0
            }
        case .pulseChase:
            let pulseEasy = state.stage == 3 ? 1.36 : 1.55
            let pulseHard = state.stage == 3 ? 0.84 : 0.92
            if patternWaveTimer > patternInterval(easy: pulseEasy, hard: pulseHard) {
                if state.stage >= 3, patternStep % 3 == 2 {
                    spawnPulseSlalomStep()
                } else {
                    spawnPulseChaseStep()
                }
                patternWaveTimer = 0
            }
            if sparkTimer > sparkInterval(easy: 1.08, hard: 0.68) {
                spawnSpark(on: orbitRadii[rewardLaneIndex(awayFrom: currentOrbitIndex)], near: nextPlayableSpawnAngle(minLead: 0.84, maxLead: 1.7))
                sparkTimer = 0
            }
        case .voidTrap:
            let voidEasy = state.stage == 5 ? 2.16 : 2.55
            let voidHard = state.stage == 5 ? 1.34 : 1.62
            if patternWaveTimer > patternInterval(easy: voidEasy, hard: voidHard) {
                if state.stage >= 5, patternStep % 3 == 2 {
                    spawnVoidSplitTrapStep()
                } else {
                    spawnVoidTrapStep()
                }
                patternWaveTimer = 0
            }
            if sparkTimer > sparkInterval(easy: 1.0, hard: 0.64) {
                spawnSpark(on: orbitRadii[reachableSafeLaneIndex()], near: nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.68))
                sparkTimer = 0
            }
        case .harvest:
            if state.stage == 2 {
                updateHarvestRoutePattern()
                return
            }
            if sparkTimer > sparkInterval(easy: 0.82, hard: 0.46) {
                spawnSparkTrail()
                sparkTimer = 0
            }
            if state.stage >= 2, patternWaveTimer > powerInterval(easy: 3.6, hard: 2.45) {
                spawnPowerUp(kind: .magnet, on: randomOrbitRadius(), near: nextPlayableSpawnAngle(minLead: 0.9, maxLead: 2.1))
                patternWaveTimer = 0
            }
            if spawnTimer > threatInterval(easy: 2.65, hard: 1.45) {
                spawnShard()
                spawnTimer = 0
            }
        case .overdrive:
            if spawnTimer > threatInterval(easy: 1.28, hard: 0.68) {
                if patternStep.isMultiple(of: 4) {
                    spawnChoiceFork()
                } else {
                    spawnShard()
                }
                patternStep += 1
                spawnTimer = 0
            }
            if sparkTimer > sparkInterval(easy: 0.9, hard: 0.52) {
                spawnSpark()
                sparkTimer = 0
            }
            if patternWaveTimer > powerInterval(easy: 2.2, hard: 1.45) {
                spawnPowerUp(kind: .surge, on: randomOrbitRadius(), near: nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.9))
                patternWaveTimer = 0
            }
        }
    }

    private func updateIntroFlowPattern() {
        if spawnTimer > threatInterval(easy: 2.55, hard: 1.48) {
            spawnTeachingShard(near: nextThreatSpawnAngle(on: orbitRadii[min(2, orbitRadii.count - 1)], minLead: 1.02, maxLead: 1.58))
            spawnTimer = 0
        }

        if elapsedTime > 0.45, sparkTimer > sparkInterval(easy: 0.78, hard: 0.56) {
            spawnIntroRhythmStep()
            sparkTimer = 0
        }
    }

    private func updateHarvestRoutePattern() {
        if sparkTimer > sparkInterval(easy: 0.68, hard: 0.42) {
            spawnHarvestSweep()
            sparkTimer = 0
        }

        if patternWaveTimer > powerInterval(easy: 2.95, hard: 2.05) {
            let lane = patternStep % orbitRadii.count
            spawnPowerUp(kind: patternStep.isMultiple(of: 3) ? .surge : .magnet, on: orbitRadii[lane], near: nextPlayableSpawnAngle(minLead: 0.86, maxLead: 1.86))
            patternWaveTimer = 0
        }

        if spawnTimer > threatInterval(easy: 3.1, hard: 1.86) {
            if patternStep.isMultiple(of: 4) {
                spawnChoiceFork()
            } else {
                spawnShard()
            }
            spawnTimer = 0
        }
    }

    private func presentRouteStartSignature() {
        switch state.stage {
        case 1:
            signalRing(at: center, color: state.selectedTheme.sparkColor, radius: 70, duration: 0.28, lineWidth: 1.8)
            pulseOrbit(at: orbitRadii[0], color: state.selectedTheme.sparkColor, duration: 0.34)
        case 2:
            for radius in orbitRadii {
                pulseOrbit(at: radius, color: state.selectedTheme.sparkColor, duration: 0.44)
            }
            routeArcSignal(on: orbitRadii[1], at: nextPlayableSpawnAngle(minLead: 0.7, maxLead: 1.0), color: objectColor(for: .surge), span: 0.42, duration: 0.42, lineWidth: 3.8)
        case 3:
            pulseOrbit(at: currentRadius, color: objectColor(for: .pulse), duration: 0.5)
            routeArcSignal(on: currentRadius, at: nextThreatSpawnAngle(on: currentRadius, minLead: 0.92, maxLead: 1.18), color: objectColor(for: .pulse), span: 0.74, duration: 0.5, lineWidth: 4.4)
        case 4:
            let safeIndex = reachableSafeLaneIndex()
            routeArcSignal(on: orbitRadii[safeIndex], at: nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.1), color: state.selectedTheme.sparkColor, span: 0.54, duration: 0.44, lineWidth: 4.6)
            for index in orbitRadii.indices where index != safeIndex {
                pulseOrbit(at: orbitRadii[index], color: state.selectedTheme.shardColor, duration: 0.38)
            }
        case 5:
            let blockedIndex = rewardLaneIndex(awayFrom: reachableSafeLaneIndex())
            pulseOrbit(at: orbitRadii[blockedIndex], color: objectColor(for: .void), duration: 0.52)
            routeArcSignal(on: orbitRadii[blockedIndex], at: nextPlayableSpawnAngle(minLead: 0.86, maxLead: 1.16), color: objectColor(for: .void), span: 0.76, duration: 0.52, lineWidth: 5.0)
        default:
            pulseOrbit(at: currentRadius, color: stageAccentColor, duration: 0.42)
            if state.stage % 4 == 0 {
                flash(color: stageAccentColor.withAlphaComponent(0.12))
            }
        }
    }

    private func spawnOpeningRoute() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.16)
        for offset in 0..<(state.stage <= 1 ? 9 : 5) {
            let index = offset % orbitRadii.count
            spawnSpark(on: orbitRadii[index], near: baseAngle + CGFloat(offset) * 0.2)
        }

        switch state.stage {
        case 1:
            spawnPowerUp(kind: .shield, on: orbitRadii[1], near: baseAngle + 0.52)
            spawnTeachingShard(near: baseAngle + 1.02)
        case 2:
            spawnPowerUp(kind: .slow, on: orbitRadii[2], near: baseAngle + 0.52)
            spawnPowerUp(kind: .surge, on: orbitRadii[1], near: baseAngle + 0.82)
            spawnSparkTrail()
        case 3:
            spawnPowerUp(kind: .magnet, on: orbitRadii[0], near: baseAngle + 0.52)
            spawnTeachingPulse(near: baseAngle + 0.96)
            spawnSpark(on: orbitRadii[2], near: baseAngle + 1.22)
        case 4:
            spawnGateOpening(near: baseAngle + 0.9)
            spawnPowerUp(kind: .bomb, on: orbitRadii[reachableSafeLaneIndex()], near: baseAngle + 1.22)
        case 5:
            spawnPowerUp(kind: .shield, on: orbitRadii[1], near: baseAngle + 0.52)
            spawnTeachingVoid(near: baseAngle + 0.96)
            spawnSpark(on: orbitRadii[reachableSafeLaneIndex()], near: baseAngle + 1.28)
        default:
            switch state.stage % 4 {
            case 1:
                spawnPowerUp(kind: .shield, on: orbitRadii[1], near: baseAngle + 0.52)
                spawnPowerUp(kind: .surge, on: orbitRadii[2], near: baseAngle + 0.84)
            case 2:
                spawnPowerUp(kind: .slow, on: orbitRadii[2], near: baseAngle + 0.52)
                spawnSparkTrail()
            case 3:
                spawnPowerUp(kind: .magnet, on: orbitRadii[0], near: baseAngle + 0.52)
                spawnGateWave()
            default:
                spawnPowerUp(kind: .surge, on: orbitRadii[1], near: baseAngle + 0.52)
                spawnPowerUp(kind: .bomb, on: orbitRadii[2], near: baseAngle + 0.76)
            }
        }
        pulseOrbit(at: orbitRadii[0], color: stageSecondaryColor, duration: 0.48)
    }

    private func spawnGateOpening(near spawnAngle: CGFloat) {
        let safeIndex = reachableSafeLaneIndex()
        telegraphGateWave(safeIndex: safeIndex, at: spawnAngle)
        for index in orbitRadii.indices where index != safeIndex {
            spawnShard(on: orbitRadii[index], near: spawnAngle + CGFloat.random(in: -0.03...0.03), rewardChance: 0, allowParallel: true)
        }
        spawnSpark(on: orbitRadii[safeIndex], near: spawnAngle)
        spawnSpark(on: orbitRadii[safeIndex], near: spawnAngle + 0.18)
    }

    private func spawnTeachingPulse(near spawnAngle: CGFloat) {
        let radius = orbitRadii[min(1, orbitRadii.count - 1)]
        pulseOrbit(at: radius, color: objectColor(for: .pulse), duration: 0.5)
        spawnPulse(on: radius, near: spawnAngle, rewardChance: 0.35, allowParallel: false, showTelegraph: false)
        spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + 0.24)
    }

    private func spawnTeachingShard(near spawnAngle: CGFloat) {
        let radius = orbitRadii[min(2, orbitRadii.count - 1)]
        pulseOrbit(at: radius, color: objectColor(for: .shard), duration: 0.42)
        spawnShard(on: radius, near: spawnAngle, rewardChance: 0.75, allowParallel: false)
        spawnSpark(on: orbitRadii[0], near: spawnAngle + 0.24)
    }

    private func spawnTeachingVoid(near spawnAngle: CGFloat) {
        let radius = orbitRadii[min(1, orbitRadii.count - 1)]
        pulseOrbit(at: radius, color: objectColor(for: .void), duration: 0.56)
        spawnVoid(on: radius, near: spawnAngle)
        spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + 0.28)
    }

    private func spawnIntroRhythmStep() {
        let laneSequence = [0, 1, 2, 1]
        let laneIndex = laneSequence[patternStep % laneSequence.count]
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.72, maxLead: 1.58)
        pulseOrbit(at: orbitRadii[laneIndex], color: state.selectedTheme.sparkColor, duration: 0.26)
        spawnSpark(on: orbitRadii[laneIndex], near: baseAngle)

        if patternStep % 4 == 2 {
            spawnSpark(on: orbitRadii[reachableSafeLaneIndex()], near: baseAngle + 0.2)
        }
        patternStep += 1
    }

    private func spawnHarvestSweep() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.66, maxLead: 1.78)
        let laneSequence = patternStep.isMultiple(of: 2) ? [0, 1, 2, 1] : [2, 1, 0, 1]

        for offset in 0..<laneSequence.count {
            let laneIndex = laneSequence[offset]
            spawnSpark(on: orbitRadii[laneIndex], near: baseAngle + CGFloat(offset) * 0.16)
        }

        if patternStep % 3 == 1 {
            spawnPowerUp(kind: .surge, on: orbitRadii[laneSequence.last ?? 1], near: baseAngle + 0.72)
        }
        patternStep += 1
    }

    private func spawnGateWave() {
        let safeIndex = reachableSafeLaneIndex()
        let waveAngle = nextPlayableSpawnAngle(minLead: 1.06, maxLead: 1.62)
        telegraphGateWave(safeIndex: safeIndex, at: waveAngle)
        for index in orbitRadii.indices where index != safeIndex {
            spawnShard(on: orbitRadii[index], near: waveAngle + CGFloat.random(in: -0.04...0.04), rewardChance: 0, allowParallel: true)
        }
        spawnSpark(on: orbitRadii[safeIndex], near: waveAngle + CGFloat.random(in: -0.08...0.08))
        if state.stage >= 2 {
            let riskyIndex = (safeIndex + orbitStepDirection + orbitRadii.count) % orbitRadii.count
            spawnPowerUp(kind: .surge, on: orbitRadii[riskyIndex], near: waveAngle + 0.24)
        }
        if patternStep.isMultiple(of: 3) {
            spawnPowerUp(kind: .shield, on: orbitRadii[safeIndex], near: waveAngle - 0.2)
        }
        patternStep += 1
    }

    private func spawnGateCorridorStep() {
        let safeIndex = reachableSafeLaneIndex()
        let baseAngle = nextPlayableSpawnAngle(minLead: 1.08, maxLead: 1.52)

        for offset in 0..<2 {
            let waveAngle = baseAngle + CGFloat(offset) * 0.62
            telegraphGateWave(safeIndex: safeIndex, at: waveAngle)
            for index in orbitRadii.indices where index != safeIndex {
                spawnShard(on: orbitRadii[index], near: waveAngle + CGFloat.random(in: -0.03...0.03), rewardChance: 0, allowParallel: true)
            }
        }

        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle - 0.08)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle + 0.16)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle + 0.72)
        if patternStep.isMultiple(of: 2) {
            spawnPowerUp(kind: .bomb, on: orbitRadii[safeIndex], near: baseAngle + 0.92)
        }
        patternStep += 1
    }

    private func spawnSwitchbackStep() {
        let laneSequence = [0, 1, 2, 1]
        let laneIndex = laneSequence[patternStep % laneSequence.count]
        let radius = orbitRadii[laneIndex]
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.82, maxLead: 1.42)
        pulseOrbit(at: radius, color: state.selectedTheme.shardColor, duration: 0.32)
        spawnShard(on: radius, near: spawnAngle, rewardChance: patternStep.isMultiple(of: 2) ? 0.45 : 0.18, allowParallel: false)
        if state.stage >= 4, patternStep % 5 == 4 {
            spawnPowerUp(kind: .bomb, on: rewardRadius(awayFrom: radius), near: spawnAngle + 0.16)
        } else if patternStep.isMultiple(of: 3) {
            spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + 0.22)
        }
        patternStep += 1
    }

    private func spawnPulseChaseStep() {
        guard state.stage >= 3 else {
            spawnSwitchbackStep()
            return
        }

        let laneSequence = [currentOrbitIndex, reachableSafeLaneIndex(), rewardLaneIndex(awayFrom: currentOrbitIndex), reachableSafeLaneIndex()]
        let laneIndex = laneSequence[patternStep % laneSequence.count]
        let radius = orbitRadii[laneIndex]
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 1.02, maxLead: 1.72)
        telegraphPulseChase(on: radius, at: spawnAngle)
        spawnPulse(on: radius, near: spawnAngle, rewardChance: 0.28, allowParallel: false, showTelegraph: false)

        let rewardIndex = rewardLaneIndex(awayFrom: laneIndex)
        spawnSpark(on: orbitRadii[rewardIndex], near: spawnAngle + 0.24)
        if patternStep.isMultiple(of: 4) {
            spawnPowerUp(kind: .shield, on: orbitRadii[reachableSafeLaneIndex()], near: spawnAngle - 0.18)
        }
        patternStep += 1
    }

    private func spawnPulseSlalomStep() {
        guard state.stage >= 3 else {
            spawnSwitchbackStep()
            return
        }

        let chaseIndex = currentOrbitIndex
        let escapeIndex = reachableSafeLaneIndex()
        let rewardIndex = rewardLaneIndex(awayFrom: escapeIndex)
        let baseAngle = nextThreatSpawnAngle(on: orbitRadii[chaseIndex], minLead: 1.02, maxLead: 1.52)

        telegraphPulseChase(on: orbitRadii[chaseIndex], at: baseAngle)
        routeArcSignal(on: orbitRadii[escapeIndex], at: baseAngle + 0.22, color: state.selectedTheme.sparkColor, span: 0.46, duration: 0.42, lineWidth: 3.8)
        routeArcSignal(on: orbitRadii[rewardIndex], at: baseAngle + 0.52, color: objectColor(for: .pulse), span: 0.48, duration: 0.42, lineWidth: 3.8)

        spawnPulse(on: orbitRadii[chaseIndex], near: baseAngle, rewardChance: 0, allowParallel: false, showTelegraph: false)
        spawnSpark(on: orbitRadii[escapeIndex], near: baseAngle + 0.2)
        spawnSpark(on: orbitRadii[escapeIndex], near: baseAngle + 0.42)
        spawnPulse(on: orbitRadii[rewardIndex], near: baseAngle + 0.62, rewardChance: 0.2, allowParallel: true, showTelegraph: false)
        if patternStep % 5 == 2 {
            spawnPowerUp(kind: .slow, on: orbitRadii[escapeIndex], near: baseAngle - 0.16)
        }
        patternStep += 1
    }

    private func spawnVoidTrapStep() {
        guard state.stage >= 5 else {
            spawnGateWave()
            return
        }

        let safeIndex = reachableSafeLaneIndex()
        let blockedIndex = rewardLaneIndex(awayFrom: safeIndex)
        let baseAngle = nextPlayableSpawnAngle(minLead: 1.04, maxLead: 1.72)

        telegraphVoidTrap(safeIndex: safeIndex, blockedIndex: blockedIndex, at: baseAngle)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle - 0.1)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle + 0.12)
        spawnVoid(on: orbitRadii[blockedIndex], near: baseAngle)

        if patternStep.isMultiple(of: 3) {
            let riskIndex = rewardLaneIndex(awayFrom: blockedIndex)
            spawnPowerUp(kind: .surge, on: orbitRadii[riskIndex], near: baseAngle + 0.26)
        }
        patternStep += 1
    }

    private func spawnVoidSplitTrapStep() {
        guard state.stage >= 5 else {
            spawnGateWave()
            return
        }

        let safeIndex = reachableSafeLaneIndex()
        let blockedIndices = orbitRadii.indices.filter { $0 != safeIndex }
        guard blockedIndices.count >= 2 else {
            spawnVoidTrapStep()
            return
        }

        let firstBlockedIndex = blockedIndices[patternStep % blockedIndices.count]
        let secondBlockedIndex = blockedIndices[(patternStep + 1) % blockedIndices.count]
        let baseAngle = nextPlayableSpawnAngle(minLead: 1.08, maxLead: 1.54)

        telegraphVoidTrap(safeIndex: safeIndex, blockedIndex: firstBlockedIndex, at: baseAngle)
        telegraphVoidTrap(safeIndex: safeIndex, blockedIndex: secondBlockedIndex, at: baseAngle + 0.72)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle - 0.08)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle + 0.2)
        spawnSpark(on: orbitRadii[safeIndex], near: baseAngle + 0.5)
        spawnVoid(on: orbitRadii[firstBlockedIndex], near: baseAngle)
        spawnVoid(on: orbitRadii[secondBlockedIndex], near: baseAngle + 0.72)

        if patternStep.isMultiple(of: 2) {
            spawnPowerUp(kind: .surge, on: orbitRadii[secondBlockedIndex], near: baseAngle + 0.36)
        } else {
            spawnPowerUp(kind: .shield, on: orbitRadii[safeIndex], near: baseAngle + 0.68)
        }
        patternStep += 1
    }

    private func spawnSparkTrail() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.66, maxLead: 1.9)
        let startIndex = Int.random(in: orbitRadii.indices)
        let direction = Bool.random() ? 1 : -1
        for offset in 0..<3 {
            let rawIndex = startIndex + offset * direction + orbitRadii.count
            let index = rawIndex % orbitRadii.count
            spawnSpark(on: orbitRadii[index], near: baseAngle + CGFloat(offset) * 0.18)
        }
        if state.stage >= 2, patternStep.isMultiple(of: 4) {
            spawnPowerUp(kind: .magnet, on: orbitRadii[startIndex], near: baseAngle - 0.2)
        }
        patternStep += 1
    }

    private func spawnChoiceFork() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.92, maxLead: 1.64)
        let safeIndex = reachableSafeLaneIndex()
        let riskyIndex = rewardLaneIndex(awayFrom: safeIndex)
        let safeRadius = orbitRadii[safeIndex]
        let riskyRadius = orbitRadii[riskyIndex]

        pulseOrbit(at: safeRadius, color: state.selectedTheme.sparkColor, duration: 0.34)
        pulseOrbit(at: riskyRadius, color: objectColor(for: .surge), duration: 0.34)
        spawnSpark(on: safeRadius, near: baseAngle - 0.08)
        spawnSpark(on: safeRadius, near: baseAngle + 0.12)
        spawnPowerUp(kind: .surge, on: riskyRadius, near: baseAngle + 0.04)
        spawnShard(on: riskyRadius, near: baseAngle - 0.28, rewardChance: 0, allowParallel: true)
        spawnShard(on: riskyRadius, near: baseAngle + 0.34, rewardChance: 0, allowParallel: true)
    }

    private func shouldSpawnRewardFork(step: Int) -> Bool {
        if state.stage <= 1 {
            return false
        }
        return step.isMultiple(of: 6)
    }

    private func rewardLaneIndex(awayFrom index: Int) -> Int {
        if index == 0 {
            return 2
        }
        if index == orbitRadii.count - 1 {
            return 0
        }
        return Bool.random() ? 0 : 2
    }

    private func reachableSafeLaneIndex() -> Int {
        min(max(currentOrbitIndex + orbitStepDirection, orbitRadii.startIndex), orbitRadii.index(before: orbitRadii.endIndex))
    }

    private func telegraphPatternStart(_ pattern: RunPattern) {
        switch pattern {
        case .flow:
            break
        case .gate:
            let safeIndex = reachableSafeLaneIndex()
            let previewAngle = nextPlayableSpawnAngle(minLead: 0.9, maxLead: 1.18)
            telegraphGateWave(safeIndex: safeIndex, at: previewAngle)
        case .switchback:
            pulseOrbit(at: orbitRadii[1], color: state.selectedTheme.shardColor, duration: 0.5)
        case .pulseChase:
            telegraphPulseChase(on: currentRadius, at: nextThreatSpawnAngle(on: currentRadius, minLead: 0.9, maxLead: 1.2))
        case .voidTrap:
            let safeIndex = reachableSafeLaneIndex()
            telegraphVoidTrap(safeIndex: safeIndex, blockedIndex: rewardLaneIndex(awayFrom: safeIndex), at: nextPlayableSpawnAngle(minLead: 0.9, maxLead: 1.2))
        case .harvest:
            orbitRadii.forEach { pulseOrbit(at: $0, color: state.selectedTheme.sparkColor, duration: 0.46) }
        case .overdrive:
            orbitRadii.forEach { pulseOrbit(at: $0, color: state.selectedTheme.feverColor, duration: 0.62) }
            flash(color: state.selectedTheme.feverColor.withAlphaComponent(0.12))
        }
    }

    private func pulseOrbit(at radius: CGFloat, color: SKColor, duration: TimeInterval) {
        guard canAddEffects() else { return }

        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = center
        ring.strokeColor = color.withAlphaComponent(0.72)
        ring.lineWidth = 4
        ring.glowWidth = state.stage >= 3 ? 7 : 10
        ring.zPosition = 11
        effectLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 1.08, duration: duration),
                .fadeOut(withDuration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    private func telegraphGateWave(safeIndex: Int, at angle: CGFloat) {
        let safeRadius = orbitRadii[safeIndex]
        routeArcSignal(on: safeRadius, at: angle, color: state.selectedTheme.shieldColor, span: 0.62, duration: 0.52, lineWidth: 5)
        laneNodeSignal(on: safeRadius, at: angle, color: state.selectedTheme.sparkColor, count: 3)

        for index in orbitRadii.indices where index != safeIndex {
            routeArcSignal(on: orbitRadii[index], at: angle, color: state.selectedTheme.shardColor, span: 0.42, duration: 0.38, lineWidth: 3.4)
        }
    }

    private func telegraphPulseChase(on radius: CGFloat, at angle: CGFloat) {
        routeArcSignal(on: radius, at: angle, color: objectColor(for: .pulse), span: 0.72, duration: 0.44, lineWidth: 4.6)
        let rewardRadius = rewardRadius(awayFrom: radius)
        routeArcSignal(on: rewardRadius, at: angle + 0.24, color: state.selectedTheme.sparkColor, span: 0.36, duration: 0.38, lineWidth: 3)
    }

    private func telegraphVoidTrap(safeIndex: Int, blockedIndex: Int, at angle: CGFloat) {
        routeArcSignal(on: orbitRadii[safeIndex], at: angle, color: state.selectedTheme.sparkColor, span: 0.52, duration: 0.48, lineWidth: 4.2)
        laneNodeSignal(on: orbitRadii[safeIndex], at: angle, color: state.selectedTheme.sparkColor, count: 2)
        routeArcSignal(on: orbitRadii[blockedIndex], at: angle, color: objectColor(for: .void), span: 0.72, duration: 0.52, lineWidth: 5.4)
    }

    private func routeArcSignal(on radius: CGFloat, at angle: CGFloat, color: SKColor, span: CGFloat, duration: TimeInterval, lineWidth: CGFloat) {
        guard canAddEffects() else { return }

        let node = SKShapeNode(path: arcPath(radius: radius, startAngle: angle - span / 2, endAngle: angle + span / 2))
        node.position = center
        node.strokeColor = color.withAlphaComponent(0.72)
        node.fillColor = .clear
        node.lineWidth = lineWidth
        node.glowWidth = state.stage >= 3 ? lineWidth * 1.35 : lineWidth * 2.0
        node.lineCap = .round
        node.zPosition = 12
        effectLayer.addChild(node)
        node.run(.sequence([
            .group([
                .fadeOut(withDuration: duration),
                .scale(to: 1.015, duration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    private func laneNodeSignal(on radius: CGFloat, at angle: CGFloat, color: SKColor, count: Int) {
        guard canAddEffects(count) else { return }

        let offsets: [CGFloat]
        switch count {
        case 1:
            offsets = [0]
        case 2:
            offsets = [-0.13, 0.13]
        default:
            offsets = [-0.18, 0, 0.18]
        }

        for offset in offsets {
            let marker = SKShapeNode(circleOfRadius: 4.2)
            marker.position = point(on: radius, angle: angle + offset)
            marker.fillColor = color.withAlphaComponent(0.84)
            marker.strokeColor = .white.withAlphaComponent(0.48)
            marker.lineWidth = 0.8
            marker.glowWidth = 8
            marker.zPosition = 13
            effectLayer.addChild(marker)
            marker.run(.sequence([
                .group([
                    .scale(to: 1.45, duration: 0.34),
                    .fadeOut(withDuration: 0.34)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func shockwave(at point: CGPoint, color: SKColor, radius: CGFloat) {
        guard canAddEffects() else { return }

        let ring = SKShapeNode(circleOfRadius: 10)
        ring.position = point
        ring.strokeColor = color.withAlphaComponent(0.78)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.glowWidth = state.stage >= 3 ? 8 : 14
        ring.zPosition = 12
        effectLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: radius / 10, duration: 0.34),
                .fadeOut(withDuration: 0.34)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnShard() {
        let radius = chooseThreatRadius()
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.95, maxLead: 1.78)
        spawnThreat(on: radius, near: spawnAngle, rewardChance: 0.58, allowParallel: false)
    }

    private func spawnThreat(on radius: CGFloat, near spawnAngle: CGFloat, rewardChance: CGFloat, allowParallel: Bool) {
        if CGFloat.random(in: 0...1) < voidSpawnChance {
            spawnVoid(on: radius, near: spawnAngle)
        } else if canSpawnPulseThreat, CGFloat.random(in: 0...1) < pulseSpawnChance {
            spawnPulse(on: radius, near: spawnAngle, rewardChance: rewardChance, allowParallel: allowParallel)
        } else {
            spawnShard(on: radius, near: spawnAngle, rewardChance: rewardChance, allowParallel: allowParallel)
        }
    }

    private var canSpawnPulseThreat: Bool {
        state.stage >= 3 || state.isGlitchContractActive
    }

    private var effectNodeLimit: Int {
        state.isFeverActive ? 22 : 34
    }

    private var isDenseScoringMoment: Bool {
        state.isFeverActive && state.magnetTimeRemaining > 0
    }

    private var objectVisualUpdateInterval: TimeInterval {
        if isDenseScoringMoment || objectLayer.children.count > 30 {
            return 1.0 / 24.0
        }
        return 1.0 / 30.0
    }

    private var activeEffectNodeLimit: Int {
        if isDenseScoringMoment {
            return 12
        }
        if state.magnetTimeRemaining > 0, objectLayer.children.count > 26 {
            return 18
        }
        if state.stage >= 3 {
            return state.isFeverActive ? 18 : 28
        }
        return effectNodeLimit
    }

    private var objectNodeLimit: Int {
        state.isFeverActive ? 32 : 44
    }

    private var pulseSpawnChance: CGFloat {
        if state.stage <= 1, state.isGlitchContractActive {
            return 0.12
        }
        switch state.stage {
        case 3:
            return 0.34
        case 4:
            return 0.18
        case 5:
            return 0.24
        default:
            return 0.3
        }
    }

    private func spawnShard(on radius: CGFloat, near spawnAngle: CGFloat, rewardChance: CGFloat, allowParallel: Bool) {
        guard canSpawnThreat(at: spawnAngle, on: radius, allowParallel: allowParallel) else { return }

        let kind = LumenObjectKind.shard
        let node = SKShapeNode(path: cachedShardPath)
        node.name = kind.nodeName
        node.position = point(on: radius, angle: spawnAngle)
        node.zRotation = CGFloat.random(in: 0...(2 * .pi))
        node.fillColor = objectColor(for: kind)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle, "spawnTime": elapsedTime, "visualPhase": CGFloat.random(in: 0...(2 * .pi))]
        addSymbol(to: node, path: dangerMarkPath(size: kind.baseRadius * 1.07), color: .black.withAlphaComponent(0.66), lineWidth: 2.4)
        addDangerFrame(to: node, radius: kind.baseRadius * 1.28, color: objectColor(for: kind))
        objectLayer.addChild(node)

        node.run(.sequence([.wait(forDuration: 6.0), .fadeOut(withDuration: 0.25), .removeFromParent()]))
        presentObjectHintIfNeeded(.shard)

        if CGFloat.random(in: 0...1) < rewardChance {
            spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + CGFloat.random(in: -0.18...0.18))
        }
    }

    private func spawnPulse(on radius: CGFloat, near spawnAngle: CGFloat, rewardChance: CGFloat, allowParallel: Bool, showTelegraph: Bool = true) {
        guard canSpawnThreat(at: spawnAngle, on: radius, allowParallel: allowParallel) else { return }

        let kind = LumenObjectKind.pulse
        let node = SKShapeNode(path: cachedPulsePath)
        node.name = kind.nodeName
        node.position = point(on: radius, angle: spawnAngle)
        node.fillColor = objectColor(for: kind)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = state.stage >= 3 ? 7 : kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle, "spawnTime": elapsedTime, "angularVelocity": -0.4, "visualPhase": CGFloat.random(in: 0...(2 * .pi))]
        addDangerHalo(to: node, radius: kind.baseRadius * 1.18)
        addDangerFrame(to: node, radius: kind.baseRadius * 1.32, color: objectColor(for: kind))
        addSymbol(to: node, path: dangerMarkPath(size: kind.baseRadius * 1.02), color: .black.withAlphaComponent(0.68), lineWidth: 2.6)
        addSymbol(to: node, path: pulseMarkPath(radius: kind.baseRadius * 0.78), color: .black.withAlphaComponent(0.34), lineWidth: 1.7)
        objectLayer.addChild(node)
        if showTelegraph {
            telegraphThreat(at: node.position, on: radius, color: objectColor(for: kind))
        }
        presentObjectHintIfNeeded(.pulse)

        let pulseLifetime: TimeInterval = state.stage == 3 ? 4.7 : 5.6
        node.run(.sequence([.wait(forDuration: pulseLifetime), .fadeOut(withDuration: 0.25), .removeFromParent()]))

        if CGFloat.random(in: 0...1) < rewardChance {
            spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + CGFloat.random(in: -0.18...0.18))
        }
    }

    private func spawnVoid(on radius: CGFloat, near spawnAngle: CGFloat) {
        guard canSpawnThreat(at: spawnAngle, on: radius, allowParallel: false) else { return }

        let kind = LumenObjectKind.void
        let span: CGFloat = .pi / 6
        let startAngle = normalizedAngle(spawnAngle - span / 2)
        let endAngle = normalizedAngle(spawnAngle + span / 2)
        let node = SKShapeNode(path: arcPath(radius: radius, startAngle: spawnAngle - span / 2, endAngle: spawnAngle + span / 2))
        node.name = kind.nodeName
        node.position = center
        node.fillColor = .clear
        node.strokeColor = objectColor(for: kind)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.lineCap = .round
        node.zPosition = 3
        node.userData = [
            "radius": radius,
            "angle": spawnAngle,
            "startAngle": startAngle,
            "endAngle": endAngle,
            "orbitIndex": nearestOrbitIndex(to: radius),
            "spawnTime": elapsedTime,
            "expiresAt": elapsedTime + 3.5,
            "visualPhase": CGFloat.random(in: 0...(2 * .pi))
        ]
        addDisruptMark(to: node, radius: radius, angle: spawnAngle, color: objectColor(for: kind))
        objectLayer.addChild(node)
        telegraphDisruptor(on: radius, at: point(on: radius, angle: spawnAngle), color: objectColor(for: kind))
        presentObjectHintIfNeeded(.void)

        node.run(.sequence([.wait(forDuration: 3.1), .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }

    private func spawnSpark() {
        let spawnAngle = nextPlayableSpawnAngle(minLead: 0.72, maxLead: 2.35)
        let radius = randomOrbitRadius()
        spawnSpark(on: radius, near: spawnAngle)
    }

    private func spawnSpark(on radius: CGFloat, near spawnAngle: CGFloat) {
        spawnSpark(on: radius, near: spawnAngle, allowVoidDuplicate: true)
    }

    private func spawnSpark(on radius: CGFloat, near spawnAngle: CGFloat, allowVoidDuplicate: Bool) {
        let kind = LumenObjectKind.spark
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.24, names: [kind.nodeName]) else { return }

        let node = SKShapeNode(path: cachedSparkPath)
        node.name = kind.nodeName
        node.position = point(on: radius, angle: spawnAngle)
        node.fillColor = objectColor(for: kind)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle, "spawnTime": elapsedTime, "visualPhase": CGFloat.random(in: 0...(2 * .pi))]
        addCollectibleCore(to: node, radius: kind.baseRadius * 0.28)
        addGoodRoleBadge(to: node, radius: kind.baseRadius, color: objectColor(for: kind))
        objectLayer.addChild(node)
        node.run(.sequence([.wait(forDuration: 5.2), .fadeOut(withDuration: 0.2), .removeFromParent()]))

        if allowVoidDuplicate, state.voidPulseRemaining > 0 {
            let offset = angularSpeed >= 0 ? CGFloat(0.16) : CGFloat(-0.16)
            spawnSpark(on: radius, near: normalizedAngle(spawnAngle + offset), allowVoidDuplicate: false)
        }
        if allowVoidDuplicate, state.lumenRushRemaining > 0 {
            let offset = angularSpeed >= 0 ? CGFloat(-0.14) : CGFloat(0.14)
            spawnSpark(on: radius, near: normalizedAngle(spawnAngle + offset), allowVoidDuplicate: false)
        }
    }

    private func spawnPowerUp() {
        let radius = randomOrbitRadius()
        let spawnAngle = nextPlayableSpawnAngle(minLead: 1.05, maxLead: 2.4)
        let roll = CGFloat.random(in: 0...1)
        spawnPowerUp(kind: selectedPowerUpKind(for: roll), on: radius, near: spawnAngle)
    }

    private func selectedPowerUpKind(for roll: CGFloat) -> LumenObjectKind {
        if state.stage <= 1 {
            return .shield
        }

        switch state.stage {
        case 2:
            if roll < 0.38 {
                return .surge
            }
            if roll < 0.66 {
                return .magnet
            }
            if roll < 0.82 {
                return .slow
            }
        case 3:
            if roll < 0.28 {
                return .magnet
            }
            if roll < 0.56 {
                return .shield
            }
            if roll < 0.74 {
                return .slow
            }
        case 4:
            if roll < 0.34 {
                return .bomb
            }
            if roll < 0.58 {
                return .shield
            }
            if roll < 0.76 {
                return .surge
            }
        case 5:
            if roll < 0.3 {
                return .shield
            }
            if roll < 0.52 {
                return .bomb
            }
            if roll < 0.7 {
                return .slow
            }
        default:
            if state.stage >= 4 && roll < 0.18 {
                return .bomb
            }
            if roll < 0.32 {
                return .surge
            }
            if roll < 0.52 {
                return .magnet
            }
        }

        if state.shieldCharges == 0 || roll < 0.72 {
            return .shield
        }
        return .slow
    }

    private func spawnPowerUp(kind: LumenObjectKind, on radius: CGFloat, near spawnAngle: CGFloat) {
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.34, names: powerUpBlockerNames) else { return }

        let node: SKShapeNode

        if kind == .bomb {
            node = SKShapeNode(path: cachedBombPath)
            addSymbol(to: node, path: clearSlashPath(size: kind.baseRadius * 1.35), color: .white.withAlphaComponent(0.92), lineWidth: 2.6)
        } else if kind == .surge {
            node = SKShapeNode(path: cachedSurgePath)
            addSymbol(to: node, path: lightningPath(size: kind.baseRadius * 1.16), color: .white.withAlphaComponent(0.9), lineWidth: 2)
        } else if kind == .magnet {
            node = SKShapeNode(path: cachedMagnetPath)
            addSymbol(to: node, path: pullArrowPath(size: kind.baseRadius * 1.25), color: .white.withAlphaComponent(0.9), lineWidth: 2.4)
        } else if kind == .shield {
            node = SKShapeNode(path: cachedShieldPath)
            addSymbol(to: node, path: checkPath(size: kind.baseRadius * 1.25), color: .white.withAlphaComponent(0.92), lineWidth: 2.5)
        } else {
            node = SKShapeNode(path: cachedSlowPath)
            addHourglassSand(to: node, radius: kind.baseRadius)
        }

        node.name = kind.nodeName
        node.fillColor = objectColor(for: kind)
        node.position = point(on: radius, angle: spawnAngle)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle, "spawnTime": elapsedTime, "visualPhase": CGFloat.random(in: 0...(2 * .pi))]
        addCollectibleCore(to: node, radius: kind.baseRadius * 0.25)
        addGoodRoleBadge(to: node, radius: kind.baseRadius, color: objectColor(for: kind))
        objectLayer.addChild(node)
        presentObjectHintIfNeeded(kind)

        node.run(.sequence([.wait(forDuration: 5.8), .fadeOut(withDuration: 0.22), .removeFromParent()]))
    }

    private func checkCollisions() {
        for node in objectLayer.children {
            guard node.alpha > 0.08 else { continue }
            if let spawnTime = storedDouble(for: node, key: "spawnTime"),
               elapsedTime - spawnTime < 0.28 {
                continue
            }
            if node.lumenObjectKind == .void {
                handleVoidCollisionIfNeeded(node)
                continue
            }
            guard isOnCollidingRadius(with: node) else { continue }
            guard isTouchingPlayer(node) else { continue }
            guard let kind = node.lumenObjectKind else { continue }

            if kind == .spark {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.collectSpark(
                    singleOrbitBonus: isSingleOrbitBonus(for: node),
                    feverBonus: state.isFeverActive && state.phaseShiftRemaining <= 0
                )
                showSparkScoreLabelIfNeeded(at: hitPoint)
                emitSparkCollectFeedback(at: hitPoint)
            } else if kind == .shield {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.grantShield()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitPowerSignal(at: hitPoint, color: state.selectedTheme.shieldColor, count: 14, radius: 52)
                flash(color: state.selectedTheme.shieldColor.withAlphaComponent(0.18))
            } else if kind == .slow {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.triggerSlowTime(duration: 4.0)
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitPowerSignal(at: hitPoint, color: state.selectedTheme.timeCoreColor, count: 14, radius: 50)
                flash(color: state.selectedTheme.timeCoreColor.withAlphaComponent(0.18))
            } else if kind == .magnet {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                let wasMagnetActive = state.magnetTimeRemaining > 0.35
                state.triggerMagnet()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                if wasMagnetActive {
                    emitBurst(at: hitPoint, color: objectColor(for: .magnet), count: 1)
                } else {
                    emitPowerSignal(at: hitPoint, color: objectColor(for: .magnet), count: 14, radius: 58)
                    pulseOrbit(at: currentRadius, color: objectColor(for: .magnet), duration: 0.42)
                    flash(color: objectColor(for: .magnet).withAlphaComponent(0.16))
                }
            } else if kind == .bomb {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                let cleared = clearShards(near: hitPoint, clearance: 118)
                state.collectBombClear(count: cleared)
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitGlitchClearSignal(at: hitPoint, color: objectColor(for: .bomb), count: max(18, cleared * 8), radius: 118)
                flash(color: objectColor(for: .bomb).withAlphaComponent(0.18))
            } else if kind == .surge {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.collectSurge()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitPowerSignal(at: hitPoint, color: objectColor(for: .surge), count: state.isFeverActive ? 10 : 18, radius: 64)
                flash(color: objectColor(for: .surge).withAlphaComponent(0.2))
            } else if isCrashHazard(kind) {
                if state.phaseShiftRemaining > 0 {
                    signalRing(at: node.position, color: state.selectedTheme.timeCoreColor, radius: 28, duration: 0.18, lineWidth: 1.2)
                    continue
                }
                if state.isFeverActive {
                    let hitPoint = node.position
                    node.removeFromParent()
                    comboTimer = 0
                    state.collectFeverHit()
                    emitFeverConversionFeedback(at: hitPoint)
                    continue
                }
                guard elapsedTime > safeUntil else {
                    absorbShard(node, invulnerabilityDuration: 0.8)
                    continue
                }
                guard elapsedTime > invulnerableUntil else {
                    absorbShard(node, invulnerabilityDuration: 0.55)
                    continue
                }
                if state.consumeEchoCatchHit() {
                    let hitPoint = node.position
                    absorbShard(node, invulnerabilityDuration: 1.05)
                    Haptics.collect(enabled: state.isHapticsEnabled)
                    emitPowerSignal(at: hitPoint, color: state.selectedTheme.shieldColor, count: 14, radius: 62)
                    flash(color: state.selectedTheme.shieldColor.withAlphaComponent(0.18))
                    continue
                }
                if state.consumeShield() {
                    let hitPoint = node.position
                    absorbShard(node, invulnerabilityDuration: 1.15)
                    Haptics.fail(enabled: state.isHapticsEnabled)
                    emitPowerSignal(at: hitPoint, color: state.selectedTheme.shieldColor, count: 18, radius: 68)
                    flash(color: state.selectedTheme.shieldColor.withAlphaComponent(0.2))
                    continue
                }
                Haptics.fail(enabled: state.isHapticsEnabled)
                node.removeFromParent()
                removeNearbyShards(clearance: 0.9)
                flushPendingMagnetSparks(force: true)
                state.endGame()
                player.run(
                    .sequence([
                        .scale(to: 1.45, duration: 0.08),
                        .scale(to: 0.1, duration: 0.16),
                        .run { [weak self] in
                            self?.resetPlayerVisuals()
                        }
                    ]),
                    withKey: "deathPulse"
                )
                emitGlitchClearSignal(at: player.position, color: state.selectedTheme.shardColor, count: 12, radius: 86)
                flash(color: state.selectedTheme.shardColor.withAlphaComponent(0.24))
                return
            }
        }
    }

    private func handleVoidCollisionIfNeeded(_ node: SKNode) {
        guard let orbitIndex = storedInt(for: node, key: "orbitIndex") else { return }
        guard orbitIndex == currentOrbitIndex || abs((storedRadius(for: node) ?? 0) - currentRadius) <= collisionRadiusTolerance else { return }
        guard let startAngle = storedCGFloat(for: node, key: "startAngle") else { return }
        guard let endAngle = storedCGFloat(for: node, key: "endAngle") else { return }
        let angularReach = playerRadius / max(currentRadius, 1) + 0.04
        guard angleOverlapsVoid(startAngle: startAngle, endAngle: endAngle, reach: angularReach) else { return }

        comboTimer = 0
        state.breakCombo()
        Haptics.fail(enabled: state.isHapticsEnabled)
        signalRing(at: player.position, color: objectColor(for: .void), radius: 54, duration: 0.22, lineWidth: 2)
        flash(color: objectColor(for: .void).withAlphaComponent(0.12))
        node.removeFromParent()
    }

    private func updateMagnetPull(delta: TimeInterval) {
        magnetScoreFlushTimer += delta
        guard state.magnetTimeRemaining > 0 else {
            flushPendingMagnetSparks(force: true)
            return
        }

        var movedSparkCount = 0
        let captureRadiusSquared: CGFloat = 18 * 18
        let pullRadiusSquared: CGFloat = 108 * 108
        let pull = min(CGFloat(delta) * 8.4, 0.24)
        var capturedSparkCount = 0
        var capturedSingleOrbitBonusCount = 0
        var lastCapturePoint = player.position

        for node in objectLayer.children {
            guard node.lumenObjectKind == .spark else { continue }
            guard movedSparkCount < (isDenseScoringMoment ? 4 : 6) else { break }
            guard capturedSparkCount < (isDenseScoringMoment ? 3 : 4) else { break }

            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let distanceSquared = dx * dx + dy * dy
            guard distanceSquared < pullRadiusSquared else { continue }

            if distanceSquared <= captureRadiusSquared {
                lastCapturePoint = node.position
                if isSingleOrbitBonus(for: node) {
                    capturedSingleOrbitBonusCount += 1
                }
                node.removeFromParent()
                comboTimer = 0
                capturedSparkCount += 1
                continue
            }

            movedSparkCount += 1
            let nextX = node.position.x + dx * pull
            let nextY = node.position.y + dy * pull
            node.position = CGPoint(x: nextX, y: nextY)
            syncObjectTrackingData(for: node)
        }

        if capturedSparkCount > 0 {
            pendingMagnetSparkCount += capturedSparkCount
            pendingMagnetSingleOrbitBonusCount += capturedSingleOrbitBonusCount
            pendingMagnetFeedbackPoint = lastCapturePoint
        }
        flushPendingMagnetSparks(force: pendingMagnetSparkCount >= 8)
    }

    private func flushPendingMagnetSparks(force: Bool) {
        guard pendingMagnetSparkCount > 0 else { return }
        let flushInterval: TimeInterval = isDenseScoringMoment ? 0.08 : 0.05
        guard force || magnetScoreFlushTimer >= flushInterval else { return }

        let count = pendingMagnetSparkCount
        let singleOrbitBonusCount = pendingMagnetSingleOrbitBonusCount
        let feedbackPoint = pendingMagnetFeedbackPoint ?? player.position
        pendingMagnetSparkCount = 0
        pendingMagnetSingleOrbitBonusCount = 0
        pendingMagnetFeedbackPoint = nil
        magnetScoreFlushTimer = 0

        state.collectMagnetSparks(count: count, singleOrbitBonusCount: singleOrbitBonusCount)
        showSparkScoreLabelIfNeeded(at: feedbackPoint)
        let feedbackInterval: TimeInterval = isDenseScoringMoment ? 0.22 : 0.12
        guard elapsedTime - lastMagnetCollectFeedbackTime > feedbackInterval else { return }
        lastMagnetCollectFeedbackTime = elapsedTime
        Haptics.collect(enabled: state.isHapticsEnabled)
        if isDenseScoringMoment {
            emitBurst(at: feedbackPoint, color: state.selectedTheme.feverColor, count: 1)
        } else {
            emitCollectSignal(
                at: feedbackPoint,
                color: state.selectedTheme.sparkColor,
                count: min(state.isFeverActive ? 3 : 5, 2 + count)
            )
        }
    }

    private func showSparkScoreLabelIfNeeded(at position: CGPoint) {
        guard !hasShownSparkScoreLabel else { return }
        hasShownSparkScoreLabel = true

        let label = SKLabelNode(text: "+점수!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 13
        label.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.10, alpha: 1)
        label.position = position
        label.zPosition = 80
        objectLayer.addChild(label)

        let rise = SKAction.moveBy(x: 0, y: 30, duration: 1.1)
        let fade = SKAction.sequence([
            .wait(forDuration: 0.4),
            .fadeOut(withDuration: 0.7)
        ])
        label.run(.sequence([
            .group([rise, fade]),
            .removeFromParent()
        ]))
    }

    private func collapseOrbitPulse(at radius: CGFloat, color: SKColor, delay: TimeInterval) {
        guard canAddEffects() else { return }

        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = center
        ring.strokeColor = color.withAlphaComponent(0.7)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.glowWidth = state.stage >= 3 ? 3 : 5
        ring.zPosition = 12
        ring.setScale(1.08)
        effectLayer.addChild(ring)
        ring.run(.sequence([
            .wait(forDuration: delay),
            .group([
                .scale(to: 0.94, duration: 0.28),
                .fadeOut(withDuration: 0.28)
            ]),
            .removeFromParent()
        ]))
    }

    private func clearShards(near point: CGPoint, clearance: CGFloat) -> Int {
        var cleared = 0
        objectLayer.children.forEach { node in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) else { return }
            let distance = hypot(point.x - node.position.x, point.y - node.position.y)
            guard distance <= clearance else { return }
            cleared += 1
            emitGlitchClearSignal(at: node.position, color: objectColor(for: .bomb), count: 6, radius: 40)
            node.removeFromParent()
        }
        return cleared
    }

    private func clearAllShards(color: SKColor) -> Int {
        var cleared = 0
        objectLayer.children.forEach { node in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) else { return }
            cleared += 1
            emitGlitchClearSignal(at: node.position, color: color, count: 4, radius: 42)
            node.removeFromParent()
        }
        return cleared
    }

    private func isCrashHazard(_ kind: LumenObjectKind) -> Bool {
        kind == .shard || kind == .pulse
    }

    private func isSingleOrbitBonus(for node: SKNode) -> Bool {
        guard state.singleOrbitRemaining > 0 else { return false }
        guard let lockedSingleOrbitIndex else { return false }
        guard let objectRadius = storedRadius(for: node) else { return false }
        return abs(objectRadius - orbitRadii[lockedSingleOrbitIndex]) <= collisionRadiusTolerance
    }

    private func cleanupTransientNodesIfNeeded() {
        let interval: TimeInterval = isDenseScoringMoment ? 0.06 : 0.18
        guard cleanupTimer >= interval else { return }
        cleanupTimer = 0
        trimOldestChildren(in: effectLayer, keeping: activeEffectNodeLimit)
        trimOldestChildren(in: objectLayer, keeping: objectNodeLimit)
    }

    private func canAddEffects(_ count: Int = 1) -> Bool {
        effectLayer.children.count + count <= activeEffectNodeLimit
    }

    private func trimOldestChildren(in layer: SKNode, keeping limit: Int) {
        let overflow = layer.children.count - limit
        guard overflow > 0 else { return }
        layer.children.prefix(overflow).forEach { $0.removeFromParent() }
    }

    private func absorbShard(_ node: SKNode, invulnerabilityDuration: TimeInterval) {
        node.removeFromParent()
        invulnerableUntil = max(invulnerableUntil, elapsedTime + invulnerabilityDuration)
        recoverToSafePosition()
        pulseInvulnerability()
    }

    private func recoverToSafePosition() {
        angle = safestRecoveryAngle()
        currentRadius = saferRecoveryRadius(at: angle)
        currentOrbitIndex = nearestOrbitIndex(to: currentRadius)
        updateOrbitStepDirectionForEdge()
        orbitStartRadius = currentRadius
        orbitTransitionElapsed = orbitTransitionDuration
        targetRadius = currentRadius
        updatePlayerPosition()
        removeNearbyShards(clearance: 1.15)
        spawnTimer = 0
        sparkTimer = min(sparkTimer, 0.2)
    }

    private func safestRecoveryAngle() -> CGFloat {
        let candidates = (0..<16).map { normalizedAngle(CGFloat($0) * .pi / 8) }
        let shardAngles = objectLayer.children.compactMap { node -> CGFloat? in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) else { return nil }
            return storedAngle(for: node)
        }

        guard !shardAngles.isEmpty else {
            return normalizedAngle(angle + .pi)
        }

        return candidates.max { first, second in
            nearestDistance(from: first, to: shardAngles) < nearestDistance(from: second, to: shardAngles)
        } ?? normalizedAngle(angle + .pi)
    }

    private func saferRecoveryRadius(at recoveryAngle: CGFloat) -> CGFloat {
        orbitRadii.min { first, second in
            shardRisk(on: first, near: recoveryAngle) < shardRisk(on: second, near: recoveryAngle)
        } ?? orbitRadii[0]
    }

    private func shardRisk(on radius: CGFloat, near recoveryAngle: CGFloat) -> CGFloat {
        objectLayer.children.reduce(CGFloat.zero) { total, node in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) else { return total }
            guard let objectAngle = storedAngle(for: node) else { return total }
            guard let objectRadius = storedRadius(for: node) else { return total }
            let lanePenalty: CGFloat = objectRadius == radius ? 1 : 0.34
            return total + lanePenalty / max(angularDistance(objectAngle, recoveryAngle), 0.12)
        }
    }

    private func removeNearbyShards(clearance: CGFloat) {
        objectLayer.children.forEach { node in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) else { return }
            guard let objectAngle = storedAngle(for: node) else { return }
            if angularDistance(objectAngle, angle) < clearance {
                node.removeFromParent()
            }
        }
    }

    private func pulseInvulnerability() {
        player.removeAction(forKey: "invulnerablePulse")
        let pulse = SKAction.sequence([
            .scale(to: 0.86, duration: 0.07),
            .scale(to: 1.06, duration: 0.07)
        ])
        player.run(
            .sequence([
                .repeat(pulse, count: 6),
                .run { [weak self] in
                    guard let self, !self.state.isGameOver else { return }
                    self.player.setScale(1)
                    self.player.alpha = 1
                }
            ]),
            withKey: "invulnerablePulse"
        )
    }

    private func setupShieldAura() {
        shieldAura.strokeColor = state.selectedTheme.shieldColor.withAlphaComponent(0.78)
        shieldAura.fillColor = state.selectedTheme.shieldColor.withAlphaComponent(0.10)
        shieldAura.lineWidth = 2.5
        shieldAura.glowWidth = 12
        shieldAura.zPosition = 4
        shieldAura.alpha = 0
        addChild(shieldAura)
        refreshShieldAura()
    }

    private func refreshNextMoveCueStyle() {
        nextMoveCue.strokeColor = state.isFeverActive
            ? state.selectedTheme.feverColor.withAlphaComponent(0.9)
            : state.selectedTheme.sparkColor.withAlphaComponent(0.86)
        nextMoveCue.glowWidth = state.isFeverActive ? 4 : 2
    }

    private func updateNextMoveCue() {
        let shouldHide = state.isGameOver || state.isRunUpgradePresented || state.isPaused
        nextMoveCue.isHidden = shouldHide
        guard !shouldHide else { return }

        let nextIndex: Int
        if state.singleOrbitRemaining > 0, let lockedSingleOrbitIndex {
            nextIndex = lockedSingleOrbitIndex
        } else {
            nextIndex = min(max(currentOrbitIndex + orbitStepDirection, 0), orbitRadii.count - 1)
        }

        let nextDirection: CGFloat = angularSpeed >= 0 ? -1 : 1
        let previewAngle = normalizedAngle(angle + nextDirection * 0.28)
        nextMoveCue.position = point(on: orbitRadii[nextIndex], angle: previewAngle)
        nextMoveCue.zRotation = previewAngle + (nextDirection > 0 ? .pi / 2 : -.pi / 2)
        nextMoveCue.alpha = 0.34 + 0.12 * (sin(CGFloat(elapsedTime) * 4.0) + 1) / 2
    }

    private func refreshShieldAura() {
        shieldAura.strokeColor = state.selectedTheme.shieldColor.withAlphaComponent(0.78)
        shieldAura.fillColor = state.selectedTheme.shieldColor.withAlphaComponent(0.10)
        shieldAura.removeAction(forKey: "shieldPulse")

        guard state.shieldCharges > 0 else {
            shieldAura.run(.fadeOut(withDuration: 0.16))
            return
        }

        shieldAura.alpha = 1
        let scale = 1.0 + CGFloat(min(state.shieldCharges, 3) - 1) * 0.08
        shieldAura.setScale(scale)
        let pulse = SKAction.sequence([
            .group([.scale(to: scale * 1.08, duration: 0.34), .fadeAlpha(to: 0.62, duration: 0.34)]),
            .group([.scale(to: scale, duration: 0.34), .fadeAlpha(to: 1.0, duration: 0.34)])
        ])
        shieldAura.run(.repeatForever(pulse), withKey: "shieldPulse")
    }

    private func flash(color: SKColor, force: Bool = false) {
        guard force || elapsedTime - lastScreenFlashTime > 0.12 else { return }
        lastScreenFlashTime = elapsedTime
        let node = SKShapeNode(rectOf: size)
        node.position = center
        node.fillColor = color
        node.strokeColor = .clear
        node.zPosition = 20
        addChild(node)
        node.run(.sequence([.fadeOut(withDuration: 0.16), .removeFromParent()]))
    }

    private func throttledFeverFlash(color: SKColor) {
        guard elapsedTime - lastFeverFlashTime > 0.18 else { return }
        lastFeverFlashTime = elapsedTime
        flash(color: color)
    }

    private func emitSparkCollectFeedback(at position: CGPoint) {
        let minimumInterval: TimeInterval = isDenseScoringMoment ? 0.24 : (state.isFeverActive ? 0.16 : 0.085)
        guard elapsedTime - lastSparkCollectFeedbackTime >= minimumInterval else { return }
        lastSparkCollectFeedbackTime = elapsedTime

        Haptics.collect(enabled: state.isHapticsEnabled)
        if isDenseScoringMoment {
            emitBurst(at: position, color: state.selectedTheme.feverColor, count: 1)
            return
        }
        emitCollectSignal(
            at: position,
            color: state.isFeverActive ? state.selectedTheme.feverColor : state.selectedTheme.sparkColor,
            count: state.isFeverActive ? 2 : 4
        )
        if state.isFeverActive {
            throttledFeverFlash(color: state.selectedTheme.feverColor.withAlphaComponent(0.14))
        } else {
            flash(color: state.selectedTheme.sparkColor.withAlphaComponent(0.1))
        }
    }

    private func emitCollectSignal(at position: CGPoint, color: SKColor, count: Int) {
        emitBurst(at: position, color: color, count: count)
        signalRing(at: position, color: color, radius: state.isFeverActive ? 42 : 30, duration: 0.24, lineWidth: 1.5)
    }

    private func emitPowerSignal(at position: CGPoint, color: SKColor, count: Int, radius: CGFloat) {
        emitBurst(at: position, color: color, count: count)
        signalRing(at: position, color: color, radius: radius, duration: 0.32, lineWidth: 2.4)
        signalRing(at: position, color: .white.withAlphaComponent(0.75), radius: radius * 0.62, duration: 0.22, lineWidth: 1.2)
    }

    private func emitGlitchClearSignal(at position: CGPoint, color: SKColor, count: Int, radius: CGFloat) {
        emitBurst(at: position, color: color, count: count)
        emitGlitchFragments(at: position, color: color)
        shockwave(at: position, color: color, radius: radius)
    }

    private func emitFeverConversionSignal(at position: CGPoint, count: Int, radius: CGFloat) {
        emitGlitchFragments(at: position, color: state.selectedTheme.shardColor)
        signalRing(at: position, color: state.selectedTheme.shardColor, radius: radius * 0.72, duration: 0.18, lineWidth: 1.4)
        emitPowerSignal(at: position, color: state.selectedTheme.feverColor, count: count, radius: radius)
    }

    private func emitFeverConversionFeedback(at position: CGPoint) {
        guard elapsedTime - lastFeverConversionFeedbackTime >= 0.16 else { return }
        lastFeverConversionFeedbackTime = elapsedTime
        Haptics.collect(enabled: state.isHapticsEnabled)
        emitFeverConversionSignal(at: position, count: 4, radius: 46)
        throttledFeverFlash(color: state.selectedTheme.feverColor.withAlphaComponent(0.14))
    }

    private func signalRing(at position: CGPoint, color: SKColor, radius: CGFloat, duration: TimeInterval, lineWidth: CGFloat) {
        guard canAddEffects() else { return }

        let ring = SKShapeNode(circleOfRadius: 8)
        ring.position = position
        ring.strokeColor = color.withAlphaComponent(0.72)
        ring.fillColor = .clear
        ring.lineWidth = lineWidth
        ring.glowWidth = state.stage >= 3 ? 4 : 7
        ring.zPosition = 12
        effectLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: radius / 8, duration: duration),
                .fadeOut(withDuration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    private func telegraphThreat(at position: CGPoint, on radius: CGFloat, color: SKColor) {
        guard canAddEffects(2) else { return }
        signalRing(at: position, color: color, radius: 38, duration: 0.2, lineWidth: 1.8)
        pulseOrbit(at: radius, color: color.withAlphaComponent(0.54), duration: 0.22)
    }

    private func telegraphDisruptor(on radius: CGFloat, at position: CGPoint, color: SKColor) {
        guard canAddEffects(2) else { return }
        signalRing(at: position, color: color, radius: 46, duration: 0.28, lineWidth: 2.2)
        pulseOrbit(at: radius, color: color.withAlphaComponent(0.62), duration: 0.32)
    }

    private func presentObjectHintIfNeeded(_ kind: LumenObjectKind) {
        guard shouldTeachObject(kind) else { return }
        guard !shownObjectHints.contains(kind) else { return }
        guard state.objectHintKind == nil else { return }
        shownObjectHints.insert(kind)
        state.showObjectHint(for: kind)
    }

    private func shouldTeachObject(_ kind: LumenObjectKind) -> Bool {
        switch kind {
        case .surge, .slow, .magnet, .bomb, .pulse, .void:
            return true
        case .shard:
            return state.stage <= 1
        case .spark, .shield:
            return false
        }
    }

    private func emitGlitchFragments(at position: CGPoint, color: SKColor) {
        let fragmentLimit = state.isFeverActive ? 2 : 3
        guard canAddEffects(fragmentLimit) else { return }

        for index in 0..<fragmentLimit {
            let fragment = SKShapeNode(path: hazardShardPath(radius: CGFloat.random(in: 3.5...5.5)))
            fragment.position = position
            fragment.fillColor = color.withAlphaComponent(0.86)
            fragment.strokeColor = .black.withAlphaComponent(0.45)
            fragment.lineWidth = 0.8
            fragment.glowWidth = 3
            fragment.zRotation = CGFloat.random(in: 0...(2 * .pi))
            fragment.zPosition = 13
            effectLayer.addChild(fragment)

            let angle = CGFloat(index) / CGFloat(max(fragmentLimit, 1)) * 2 * .pi + CGFloat.random(in: -0.4...0.4)
            let distance = CGFloat.random(in: 24...54)
            let duration = TimeInterval(CGFloat.random(in: 0.22...0.36))
            fragment.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: duration),
                    .rotate(byAngle: CGFloat.random(in: -2.4...2.4), duration: duration),
                    .fadeOut(withDuration: duration),
                    .scale(to: 0.15, duration: duration)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func emitBurst(at position: CGPoint, color: SKColor, count: Int) {
        let effectLimit = activeEffectNodeLimit
        guard effectLayer.children.count < effectLimit else {
            return
        }

        let availableSlots = max(0, effectLimit - effectLayer.children.count)
        let cappedCount = min(count, state.isFeverActive ? 4 : 7, availableSlots)

        for index in 0..<cappedCount {
            let mote = SKShapeNode(path: motePath)
            mote.setScale(CGFloat.random(in: 0.7...1.4))
            mote.position = position
            mote.fillColor = color.withAlphaComponent(0.9)
            mote.strokeColor = .white.withAlphaComponent(0.35)
            mote.lineWidth = 1
            mote.glowWidth = state.isFeverActive ? 4 : 4
            mote.zPosition = 12
            effectLayer.addChild(mote)

            let angle = CGFloat(index) / CGFloat(max(count, 1)) * 2 * .pi + CGFloat.random(in: -0.22...0.22)
            let distance = CGFloat.random(in: state.isFeverActive ? 32...64 : 24...54)
            let duration = TimeInterval(CGFloat.random(in: state.isFeverActive ? 0.2...0.34 : 0.28...0.48))
            mote.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: duration),
                    .fadeOut(withDuration: duration),
                    .scale(to: 0.2, duration: duration)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func triggerFeverBurst() {
        flash(color: state.selectedTheme.feverColor.withAlphaComponent(0.12))
        refreshNextMoveCueStyle()
        signalRing(at: player.position, color: state.selectedTheme.feverColor, radius: 72, duration: 0.22, lineWidth: 2.2)
        if canAddEffects() {
            let ring = SKShapeNode(circleOfRadius: currentRadius)
            ring.position = center
            ring.strokeColor = state.selectedTheme.feverColor.withAlphaComponent(0.6)
            ring.lineWidth = 2
            ring.glowWidth = 4
            ring.zPosition = 10
            effectLayer.addChild(ring)
            ring.run(.sequence([
                .group([.scale(to: 1.18, duration: 0.26), .fadeOut(withDuration: 0.26)]),
                .removeFromParent()
            ]))
        }

        feverLabel.removeAllActions()
        feverLabel.text = NSLocalizedString("hud.fever", comment: "")
        feverLabel.fontColor = state.selectedTheme.feverColor
        feverLabel.position = center
        feverLabel.alpha = 0
        feverLabel.setScale(0.72)
        feverLabel.isHidden = false
        showFeverRoleLabelIfNeeded()

        let appear = SKAction.group([
            .fadeIn(withDuration: 0.08),
            .scale(to: 1.04, duration: 0.12)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 0.42)
        let disappear = SKAction.group([
            .fadeOut(withDuration: 0.22),
            .scale(to: 1.18, duration: 0.22),
            .moveBy(x: 0, y: 14, duration: 0.22)
        ])
        let seq = SKAction.sequence([
            appear,
            settle,
            hold,
            disappear,
            .run { [weak self] in
                self?.feverLabel.isHidden = true
            }
        ])
        feverLabel.run(seq, withKey: "feverLabel")
    }

    private func triggerFeverEndBurst() {
        let cooldownColor = SKColor(red: 0.42, green: 0.78, blue: 1.0, alpha: 1.0)
        flash(color: cooldownColor.withAlphaComponent(0.18), force: true)
        signalRing(at: player.position, color: cooldownColor, radius: 42, duration: 0.2, lineWidth: 2.0)
        signalRing(at: player.position, color: .white.withAlphaComponent(0.72), radius: 24, duration: 0.16, lineWidth: 1.2)
        emitBurst(at: player.position, color: cooldownColor, count: isDenseScoringMoment ? 1 : 4)

        for (index, radius) in orbitRadii.enumerated() {
            collapseOrbitPulse(at: radius, color: cooldownColor, delay: TimeInterval(index) * 0.035)
        }

        player.removeAction(forKey: "feverEndingPulse")
        player.run(.sequence([
            .scale(to: 1.12, duration: 0.06),
            .scale(to: 0.92, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]), withKey: "feverEndPulse")

        let label = SKLabelNode(text: "오버싱크 종료")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 16
        label.fontColor = cooldownColor.withAlphaComponent(0.92)
        label.position = CGPoint(x: center.x, y: center.y - 28)
        label.zPosition = 31
        label.alpha = 0
        effectLayer.addChild(label)
        label.run(.sequence([
            .fadeIn(withDuration: 0.08),
            .wait(forDuration: 0.34),
            .group([
                .moveBy(x: 0, y: -14, duration: 0.26),
                .fadeOut(withDuration: 0.26)
            ]),
            .removeFromParent()
        ]))
    }

    private func showFeverRoleLabelIfNeeded() {
        guard !hasShownFeverRoleLabel else { return }
        hasShownFeverRoleLabel = true

        let roleLabel = SKLabelNode(text: "무적 · 장애물 → 점수")
        roleLabel.fontName = "AvenirNext-Medium"
        roleLabel.fontSize = 12
        roleLabel.fontColor = SKColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 0.92)
        roleLabel.position = CGPoint(
            x: feverLabel.position.x,
            y: feverLabel.position.y - 22
        )
        roleLabel.zPosition = feverLabel.zPosition
        roleLabel.alpha = 0
        effectLayer.addChild(roleLabel)
        roleLabel.run(.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: 2.2),
            .fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
    }

    private func updateFeverEndingCue() {
        guard state.isFeverActive else { return }
        guard state.feverRemaining <= 1.15 else { return }
        guard !didWarnFeverEnding else { return }
        didWarnFeverEnding = true

        signalRing(at: player.position, color: state.selectedTheme.feverColor, radius: 86, duration: 0.34, lineWidth: 2.6)
        signalRing(at: player.position, color: state.selectedTheme.shardColor.withAlphaComponent(0.75), radius: 52, duration: 0.24, lineWidth: 1.4)
        for radius in orbitRadii {
            pulseOrbit(at: radius, color: state.selectedTheme.shardColor, duration: 0.26)
        }
        player.run(.sequence([
            .scale(to: 0.9, duration: 0.07),
            .scale(to: 1.08, duration: 0.07),
            .scale(to: 1.0, duration: 0.1)
        ]), withKey: "feverEndingPulse")
    }

    private func convertNearbyShardsForFever() {
        var converted = 0
        var lastConversionPoint = player.position
        objectLayer.children.forEach { node in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) else { return }
            guard converted < 3 else { return }
            guard let objectAngle = storedAngle(for: node) else { return }
            if angularDistance(objectAngle, angle) < 1.1 {
                converted += 1
                lastConversionPoint = node.position
                node.removeFromParent()
            }
        }

        guard converted > 0 else { return }
        state.collectFeverHits(count: converted)
        emitBurst(at: lastConversionPoint, color: state.selectedTheme.feverColor, count: min(4, converted + 1))
        signalRing(at: player.position, color: state.selectedTheme.feverColor, radius: 74, duration: 0.2, lineWidth: 1.6)
    }

    private func updatePlayerPosition() {
        player.position = point(on: currentRadius, angle: angle)
        shieldAura.position = player.position
        shieldAura.zRotation = -angle
        updateNextMoveCue()
    }

    private func updateOrbitRadius(delta: TimeInterval) {
        guard currentRadius != targetRadius else { return }

        orbitTransitionElapsed = min(orbitTransitionDuration, orbitTransitionElapsed + delta)
        let progress = CGFloat(orbitTransitionElapsed / orbitTransitionDuration)
        let eased = progress * progress * (3 - 2 * progress)
        currentRadius = orbitStartRadius + (targetRadius - orbitStartRadius) * eased

        if orbitTransitionElapsed >= orbitTransitionDuration {
            currentRadius = targetRadius
        }
    }

    private func point(on radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func chooseThreatRadius() -> CGFloat {
        let playerWillReachSoon = CGFloat.random(in: 0...1) < 0.64
        if playerWillReachSoon {
            return targetRadius
        }
        return randomOrbitRadius()
    }

    private func randomOrbitRadius() -> CGFloat {
        orbitRadii.randomElement() ?? orbitRadii[0]
    }

    private var difficultyProgress: Double {
        min(1, Double(max(state.score - 35, 0)) / 260)
    }

    private func scaledInterval(easy: Double, hard: Double) -> Double {
        easy - (easy - hard) * difficultyProgress
    }

    private func threatInterval(easy: Double, hard: Double) -> Double {
        scaledInterval(easy: easy, hard: hard) * stageThreatIntervalScale
    }

    private func sparkInterval(easy: Double, hard: Double) -> Double {
        scaledInterval(easy: easy, hard: hard) * stageSparkIntervalScale
    }

    private func powerInterval(easy: Double, hard: Double) -> Double {
        scaledInterval(easy: easy, hard: hard) * stagePowerIntervalScale
    }

    private func patternInterval(easy: Double, hard: Double) -> Double {
        scaledInterval(easy: easy, hard: hard) * stagePatternIntervalScale
    }

    private func patternDurationInterval(easy: Double, hard: Double) -> Double {
        scaledInterval(easy: easy, hard: hard) * stagePatternDurationScale
    }

    private func rewardRadius(awayFrom radius: CGFloat) -> CGFloat {
        let index = nearestOrbitIndex(to: radius)
        if index == 0 {
            return orbitRadii[1]
        }
        if index == orbitRadii.count - 1 {
            return orbitRadii[orbitRadii.count - 2]
        }
        return Bool.random() ? orbitRadii[index - 1] : orbitRadii[index + 1]
    }

    private func nearestOrbitIndex(to radius: CGFloat) -> Int {
        orbitRadii.indices.min { first, second in
            abs(orbitRadii[first] - radius) < abs(orbitRadii[second] - radius)
        } ?? 0
    }

    private func isOnCollidingRadius(with node: SKNode) -> Bool {
        if node.lumenObjectKind == .spark, isSpatiallyTouchingPlayer(node, extraTolerance: 8) {
            return true
        }

        guard let objectRadius = storedRadius(for: node) else { return true }
        let dynamicTolerance = max(collisionRadiusTolerance, playerRadius + collisionRadius(for: node))
        return abs(objectRadius - currentRadius) <= dynamicTolerance
    }

    private func isTouchingPlayer(_ node: SKNode) -> Bool {
        let combinedRadius = playerRadius + collisionRadius(for: node)
        if node.lumenObjectKind == .spark, isSpatiallyTouchingPlayer(node, extraTolerance: 8) {
            return true
        }

        guard let objectAngle = storedAngle(for: node) else { return false }
        guard let objectRadius = storedRadius(for: node) else { return false }
        let angularReach = combinedRadius / max(objectRadius, 1) + 0.035
        let didReachAngle = sweptAngleDidReach(objectAngle, angularReach: angularReach)
        guard didReachAngle else { return false }

        let radialGap = abs(objectRadius - currentRadius)
        guard radialGap <= combinedRadius else { return false }

        let dx = player.position.x - node.position.x
        let dy = player.position.y - node.position.y
        return dx * dx + dy * dy <= combinedRadius * combinedRadius || didReachAngle
    }

    private func isSpatiallyTouchingPlayer(_ node: SKNode, extraTolerance: CGFloat = 0) -> Bool {
        let combinedRadius = playerRadius + collisionRadius(for: node) + extraTolerance
        let dx = player.position.x - node.position.x
        let dy = player.position.y - node.position.y
        return dx * dx + dy * dy <= combinedRadius * combinedRadius
    }

    private func collisionRadius(for node: SKNode) -> CGFloat {
        node.lumenObjectKind?.collisionRadius ?? 12
    }

    private func sweptAngleDidReach(_ objectAngle: CGFloat, angularReach: CGFloat) -> Bool {
        let travel = angularTravelDistance(from: previousAngle, to: angle)
        guard travel > 0 else {
            return angularDistance(angle, objectAngle) <= angularReach
        }

        let distanceFromStart = angularTravelDistance(from: previousAngle, to: objectAngle)
        return distanceFromStart <= travel + angularReach || angularDistance(angle, objectAngle) <= angularReach
    }

    private func angularTravelDistance(from start: CGFloat, to end: CGFloat) -> CGFloat {
        let normalizedStart = normalizedAngle(start)
        let normalizedEnd = normalizedAngle(end)

        if angularSpeed >= 0 {
            let distance = normalizedEnd - normalizedStart
            return distance >= 0 ? distance : distance + 2 * .pi
        }

        let distance = normalizedStart - normalizedEnd
        return distance >= 0 ? distance : distance + 2 * .pi
    }

    private func nextThreatSpawnAngle(on radius: CGFloat, minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let radiusIndex = nearestOrbitIndex(to: radius)
        if radiusIndex == nearestOrbitIndex(to: currentRadius) || radiusIndex == currentOrbitIndex {
            return nextTrailingSpawnAngle(minLead: minLead, maxLead: maxLead)
        }
        return nextPlayableSpawnAngle(minLead: minLead, maxLead: maxLead)
    }

    private func nextPlayableSpawnAngle(minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let direction: CGFloat = angularSpeed >= 0 ? 1 : -1
        return normalizedAngle(angle + direction * CGFloat.random(in: minLead...maxLead))
    }

    private func nextTrailingSpawnAngle(minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let direction: CGFloat = angularSpeed >= 0 ? 1 : -1
        return normalizedAngle(angle - direction * CGFloat.random(in: minLead...maxLead))
    }

    private func canSpawnThreat(at spawnAngle: CGFloat, on radius: CGFloat, allowParallel: Bool) -> Bool {
        if angularDistance(angle, spawnAngle) < 0.82 {
            return false
        }

        let clearance: CGFloat
        switch state.stage {
        case 1:
            clearance = 0.76
        case 2:
            clearance = 0.66
        case 3:
            clearance = 0.56
        default:
            clearance = state.score < 120 ? 0.58 : 0.48
        }
        return !objectLayer.children.contains { node in
            guard let kind = node.lumenObjectKind, isCrashHazard(kind) || kind == .void else { return false }
            guard let objectAngle = storedAngle(for: node) else { return false }
            guard angularDistance(objectAngle, spawnAngle) < clearance else { return false }
            if allowParallel, let objectRadius = storedRadius(for: node), abs(objectRadius - radius) > collisionRadiusTolerance {
                return false
            }
            return true
        }
    }

    private func hasNearbyObject(at spawnAngle: CGFloat, clearance: CGFloat, names: Set<String>) -> Bool {
        objectLayer.children.contains { node in
            guard let name = node.name, names.contains(name) else { return false }
            guard let objectAngle = storedAngle(for: node) else { return false }
            return angularDistance(objectAngle, spawnAngle) < clearance
        }
    }

    private func storedAngle(for node: SKNode) -> CGFloat? {
        if let angle = node.userData?["angle"] as? CGFloat {
            return angle
        }

        if let angle = node.userData?["angle"] as? NSNumber {
            return CGFloat(truncating: angle)
        }

        return nil
    }

    private func storedRadius(for node: SKNode) -> CGFloat? {
        if let radius = node.userData?["radius"] as? CGFloat {
            return radius
        }

        if let radius = node.userData?["radius"] as? NSNumber {
            return CGFloat(truncating: radius)
        }

        return nil
    }

    private func storedCGFloat(for node: SKNode, key: String) -> CGFloat? {
        if let value = node.userData?[key] as? CGFloat {
            return value
        }

        if let value = node.userData?[key] as? NSNumber {
            return CGFloat(truncating: value)
        }

        return nil
    }

    private func storedDouble(for node: SKNode, key: String) -> Double? {
        if let value = node.userData?[key] as? Double {
            return value
        }

        if let value = node.userData?[key] as? NSNumber {
            return value.doubleValue
        }

        return nil
    }

    private func storedInt(for node: SKNode, key: String) -> Int? {
        if let value = node.userData?[key] as? Int {
            return value
        }

        if let value = node.userData?[key] as? NSNumber {
            return value.intValue
        }

        return nil
    }

    private func syncObjectTrackingData(for node: SKNode) {
        let dx = node.position.x - center.x
        let dy = node.position.y - center.y
        node.userData?["radius"] = hypot(dx, dy)
        node.userData?["angle"] = normalizedAngle(atan2(dy, dx))
    }

    private func nearestDistance(from angle: CGFloat, to angles: [CGFloat]) -> CGFloat {
        angles.map { angularDistance(angle, $0) }.min() ?? .pi
    }

    private func angularDistance(_ first: CGFloat, _ second: CGFloat) -> CGFloat {
        let difference = abs(normalizedAngle(first) - normalizedAngle(second))
        return min(difference, 2 * .pi - difference)
    }

    private func angleOverlapsVoid(startAngle: CGFloat, endAngle: CGFloat, reach: CGFloat) -> Bool {
        let currentAngle = normalizedAngle(angle)
        let expandedStart = normalizedAngle(startAngle - reach)
        let expandedEnd = normalizedAngle(endAngle + reach)

        if expandedStart <= expandedEnd {
            return currentAngle >= expandedStart && currentAngle <= expandedEnd
        }

        return currentAngle >= expandedStart || currentAngle <= expandedEnd
    }

    private func normalizedAngle(_ value: CGFloat) -> CGFloat {
        var angle = value.truncatingRemainder(dividingBy: 2 * .pi)
        if angle < 0 {
            angle += 2 * .pi
        }
        return angle
    }

    private func diamondPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addLine(to: CGPoint(x: radius * 0.75, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -radius))
        path.addLine(to: CGPoint(x: -radius * 0.75, y: 0))
        path.closeSubpath()
        return path
    }

    private func hazardShardPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 12
        for index in 0..<points {
            let isSpike = index.isMultiple(of: 2)
            let pointRadius = isSpike ? radius : radius * 0.58
            let angle = CGFloat(index) / CGFloat(points) * 2 * .pi - .pi / 2
            let point = CGPoint(x: cos(angle) * pointRadius, y: sin(angle) * pointRadius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func dangerMarkPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let half = size / 2
        path.move(to: CGPoint(x: -half, y: -half))
        path.addLine(to: CGPoint(x: half, y: half))
        path.move(to: CGPoint(x: half, y: -half))
        path.addLine(to: CGPoint(x: -half, y: half))
        return path
    }

    private func pulseMarkPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: -.pi * 0.62, endAngle: .pi * 0.62, clockwise: false)
        path.move(to: CGPoint(x: radius * 0.35, y: radius * 0.68))
        path.addLine(to: CGPoint(x: radius * 0.9, y: radius * 0.5))
        path.addLine(to: CGPoint(x: radius * 0.58, y: radius * 0.04))
        return path
    }

    private func polygonPath(radius: CGFloat, sides: Int) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<sides {
            let angle = CGFloat(index) / CGFloat(sides) * 2 * .pi + .pi / 6
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func starPath(outerRadius: CGFloat, innerRadius: CGFloat, points: Int) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = CGFloat(index) / CGFloat(points * 2) * 2 * .pi - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func arcPath(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }

    private func shieldPath(radius: CGFloat) -> CGPath {
        // 클래식 방패 모양: 위는 평평하고 아래로 갈수록 좁아지며 뾰족하게 끝남
        let path = CGMutablePath()
        let w = radius
        let top = radius * 0.75
        let shoulder = radius * 0.1
        let tip = -radius * 1.15

        path.move(to: CGPoint(x: -w, y: top))
        path.addLine(to: CGPoint(x: w, y: top))
        // 오른쪽 어깨 → 오른쪽 곡선 → 뾰족한 하단
        path.addLine(to: CGPoint(x: w, y: shoulder))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: tip),
            control: CGPoint(x: w * 0.72, y: tip * 0.55)
        )
        // 뾰족한 하단 → 왼쪽 곡선 → 왼쪽 어깨
        path.addQuadCurve(
            to: CGPoint(x: -w, y: shoulder),
            control: CGPoint(x: -w * 0.72, y: tip * 0.55)
        )
        path.closeSubpath()
        return path
    }

    private func corePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        path.move(to: CGPoint(x: -radius * 1.2, y: 0))
        path.addLine(to: CGPoint(x: radius * 1.2, y: 0))
        path.move(to: CGPoint(x: 0, y: -radius * 1.2))
        path.addLine(to: CGPoint(x: 0, y: radius * 1.2))
        return path
    }

    private func smallCirclePath(radius: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
    }

    private func burstPath(outerRadius: CGFloat, innerRadius: CGFloat, points: Int) -> CGPath {
        starPath(outerRadius: outerRadius, innerRadius: innerRadius, points: points)
    }

    private func hourglassPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let width = radius * 0.78
        let top = radius
        let waist = radius * 0.18
        let bottom = -radius

        path.move(to: CGPoint(x: -width, y: top))
        path.addLine(to: CGPoint(x: width, y: top))
        path.addLine(to: CGPoint(x: waist, y: 0))
        path.addLine(to: CGPoint(x: width, y: bottom))
        path.addLine(to: CGPoint(x: -width, y: bottom))
        path.addLine(to: CGPoint(x: -waist, y: 0))
        path.closeSubpath()
        return path
    }

    private func hexPath(radius: CGFloat) -> CGPath {
        polygonPath(radius: radius, sides: 6)
    }

    private func magnetBodyPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let width = radius * 0.82
        let arm = radius * 0.34
        let top = radius * 0.82
        let bottom = -radius * 0.36
        path.move(to: CGPoint(x: -width, y: top))
        path.addLine(to: CGPoint(x: -arm, y: top))
        path.addLine(to: CGPoint(x: -arm, y: bottom))
        path.addQuadCurve(to: CGPoint(x: arm, y: bottom), control: CGPoint(x: 0, y: -radius * 1.1))
        path.addLine(to: CGPoint(x: arm, y: top))
        path.addLine(to: CGPoint(x: width, y: top))
        path.addLine(to: CGPoint(x: width, y: bottom))
        path.addQuadCurve(to: CGPoint(x: -width, y: bottom), control: CGPoint(x: 0, y: -radius * 1.85))
        path.closeSubpath()
        return path
    }

    private func pullArrowPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.04))
        path.addLine(to: CGPoint(x: size * 0.22, y: -size * 0.04))
        path.move(to: CGPoint(x: size * 0.06, y: -size * 0.24))
        path.addLine(to: CGPoint(x: size * 0.28, y: -size * 0.04))
        path.addLine(to: CGPoint(x: size * 0.06, y: size * 0.16))
        return path
    }

    private func clearSlashPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.32))
        path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.32))
        return path
    }

    private func lightningPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size * 0.08, y: size * 0.5))
        path.addLine(to: CGPoint(x: -size * 0.36, y: -size * 0.05))
        path.addLine(to: CGPoint(x: -size * 0.04, y: -size * 0.05))
        path.addLine(to: CGPoint(x: -size * 0.18, y: -size * 0.5))
        path.addLine(to: CGPoint(x: size * 0.36, y: size * 0.08))
        path.addLine(to: CGPoint(x: size * 0.04, y: size * 0.08))
        path.closeSubpath()
        return path
    }

    private func checkPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.02))
        path.addLine(to: CGPoint(x: -size * 0.12, y: -size * 0.32))
        path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.28))
        return path
    }

    private func plusPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: 0))
        path.addLine(to: CGPoint(x: size * 0.42, y: 0))
        path.move(to: CGPoint(x: 0, y: -size * 0.42))
        path.addLine(to: CGPoint(x: 0, y: size * 0.42))
        return path
    }

    private func nextMoveChevronPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.34))
        path.addLine(to: CGPoint(x: size * 0.42, y: 0))
        path.addLine(to: CGPoint(x: -size * 0.42, y: size * 0.34))
        return path
    }

    private func dangerTrianglePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<3 {
            let angle = CGFloat(index) / 3 * 2 * .pi - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func disruptMarkPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.36, y: size * 0.46))
        path.addLine(to: CGPoint(x: -size * 0.06, y: size * 0.08))
        path.addLine(to: CGPoint(x: -size * 0.28, y: size * 0.08))
        path.move(to: CGPoint(x: size * 0.36, y: -size * 0.46))
        path.addLine(to: CGPoint(x: size * 0.06, y: -size * 0.08))
        path.addLine(to: CGPoint(x: size * 0.28, y: -size * 0.08))
        return path
    }

    private func addSymbol(to node: SKShapeNode, path: CGPath, color: SKColor, lineWidth: CGFloat) {
        let symbol = SKShapeNode(path: path)
        symbol.fillColor = color
        symbol.strokeColor = color
        symbol.lineWidth = lineWidth
        symbol.glowWidth = 0
        symbol.zPosition = 1
        node.addChild(symbol)
    }

    private func addGoodRoleBadge(to node: SKShapeNode, radius: CGFloat, color: SKColor) {
        let badgeRadius = max(4.4, radius * 0.36)
        let badge = SKShapeNode(path: smallCirclePath(radius: badgeRadius))
        badge.position = CGPoint(x: radius * 0.66, y: radius * 0.66)
        badge.fillColor = color.withAlphaComponent(0.96)
        badge.strokeColor = .white.withAlphaComponent(0.94)
        badge.lineWidth = 1.1
        badge.glowWidth = 4
        badge.zPosition = 1.5

        let plus = SKShapeNode(path: plusPath(size: badgeRadius * 1.05))
        plus.strokeColor = .white.withAlphaComponent(0.96)
        plus.fillColor = .clear
        plus.lineWidth = 1.7
        plus.lineCap = .round
        plus.zPosition = 1
        badge.addChild(plus)
        node.addChild(badge)
    }

    private func addCollectibleCore(to node: SKShapeNode, radius: CGFloat) {
        let core = SKShapeNode(path: smallCirclePath(radius: radius))
        core.fillColor = .white.withAlphaComponent(0.84)
        core.strokeColor = .white.withAlphaComponent(0.42)
        core.lineWidth = 0.8
        core.glowWidth = 5
        core.zPosition = 0.35
        node.addChild(core)
    }

    private func addDangerFrame(to node: SKShapeNode, radius: CGFloat, color: SKColor) {
        let frame = SKShapeNode(path: dangerTrianglePath(radius: radius))
        frame.fillColor = .clear
        frame.strokeColor = color.withAlphaComponent(0.84)
        frame.lineWidth = 1.4
        frame.glowWidth = 5
        frame.lineJoin = .round
        frame.zPosition = -0.18
        node.addChild(frame)
    }

    private func addDangerHalo(to node: SKShapeNode, radius: CGFloat) {
        let halo = SKShapeNode(path: smallCirclePath(radius: radius))
        halo.fillColor = .clear
        halo.strokeColor = .black.withAlphaComponent(0.42)
        halo.lineWidth = 1.4
        halo.glowWidth = 0
        halo.zPosition = -0.2
        node.addChild(halo)
    }

    private func addDisruptMark(to node: SKShapeNode, radius: CGFloat, angle: CGFloat, color: SKColor) {
        let marker = SKShapeNode(path: disruptMarkPath(size: 14))
        marker.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
        marker.zRotation = angle + .pi / 2
        marker.strokeColor = .white.withAlphaComponent(0.82)
        marker.fillColor = .clear
        marker.lineWidth = 2.2
        marker.lineCap = .round
        marker.lineJoin = .round
        marker.glowWidth = 4
        marker.zPosition = 1
        node.addChild(marker)

        let core = SKShapeNode(path: smallCirclePath(radius: 4.2))
        core.position = marker.position
        core.fillColor = color.withAlphaComponent(0.88)
        core.strokeColor = .white.withAlphaComponent(0.48)
        core.lineWidth = 0.9
        core.glowWidth = 5
        core.zPosition = 0.9
        node.addChild(core)
    }

    private func addHourglassSand(to node: SKShapeNode, radius: CGFloat) {
        let sandRadius = radius * 0.22
        let offset = radius * 0.4
        let top = SKShapeNode(path: smallCirclePath(radius: sandRadius))
        top.position = CGPoint(x: 0, y: offset)
        top.fillColor = .white.withAlphaComponent(0.86)
        top.strokeColor = .clear
        top.zPosition = 1
        node.addChild(top)

        let bottom = SKShapeNode(path: smallCirclePath(radius: sandRadius))
        bottom.position = CGPoint(x: 0, y: -offset)
        bottom.fillColor = .white.withAlphaComponent(0.86)
        bottom.strokeColor = .clear
        bottom.zPosition = 1
        node.addChild(bottom)
    }

    private func objectColor(for kind: LumenObjectKind) -> SKColor {
        kind.sceneColor(for: state.selectedTheme)
    }

    private func playerPath(for skin: CoreSkin) -> CGPath {
        switch skin {
        case .orb:
            return CGPath(
                ellipseIn: CGRect(x: -playerRadius, y: -playerRadius, width: playerRadius * 2, height: playerRadius * 2),
                transform: nil
            )
        case .prism:
            return diamondPath(radius: playerRadius * 1.2)
        case .pulse:
            return corePath(radius: playerRadius * 1.12)
        }
    }

    private var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }
}
