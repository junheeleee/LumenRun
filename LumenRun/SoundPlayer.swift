import AVFoundation

enum SoundPlayer {
    private static var players: [String: AVAudioPlayer] = [:]
    private static var musicPlayer: AVAudioPlayer?
    private static var feverMusicPlayer: AVAudioPlayer?
    private static var isFeverActive = false
    private static var lastPlayTimes: [String: TimeInterval] = [:]

    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        preload("start")
        preload("tap")
        preload("lumen")
        preload("shield")
        preload("timecore")
        preload("crash")
        preload("shieldbreak")
        preload("fever")
        preload("stageclear")
        preload("module")
        preloadMusic()
    }

    static func startRun(enabled: Bool) {
        play("start", enabled: enabled)
    }

    static func tap(enabled: Bool) {
        play("tap", enabled: enabled)
    }

    static func lumen(enabled: Bool) {
        play("lumen", enabled: enabled)
    }

    static func shield(enabled: Bool) {
        play("shield", enabled: enabled)
    }

    static func timeCore(enabled: Bool) {
        play("timecore", enabled: enabled)
    }

    static func shieldBreak(enabled: Bool) {
        play("shieldbreak", enabled: enabled)
    }

    static func crash(enabled: Bool) {
        play("crash", enabled: enabled)
    }

    static func feverStart(enabled: Bool) {
        play("fever", enabled: enabled)
    }

    static func stageClear(enabled: Bool) {
        play("stageclear", enabled: enabled)
    }

    static func moduleSelect(enabled: Bool) {
        play("module", enabled: enabled)
    }

    static func setMusicEnabled(_ enabled: Bool) {
        guard enabled else {
            musicPlayer?.pause()
            feverMusicPlayer?.pause()
            return
        }

        if isFeverActive {
            musicPlayer?.pause()
            if feverMusicPlayer?.isPlaying == false {
                feverMusicPlayer?.play()
            }
        } else if let musicPlayer, !musicPlayer.isPlaying {
            feverMusicPlayer?.pause()
            musicPlayer.play()
        }
    }

    static func setFeverActive(_ active: Bool, enabled: Bool) {
        isFeverActive = active
        guard enabled else { return }

        if active {
            musicPlayer?.pause()
            if feverMusicPlayer?.isPlaying == false {
                feverMusicPlayer?.currentTime = 0
                feverMusicPlayer?.play()
            }
        } else {
            feverMusicPlayer?.pause()
            if musicPlayer?.isPlaying == false {
                musicPlayer?.play()
            }
        }
    }

    private static func preload(_ name: String) {
        guard players[name] == nil else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume(for: name)
        player.prepareToPlay()
        players[name] = player
    }

    private static func preloadMusic() {
        guard musicPlayer == nil else { return }
        guard let url = Bundle.main.url(forResource: "background", withExtension: "wav") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = 0.27
        player.prepareToPlay()
        musicPlayer = player

        if let feverURL = Bundle.main.url(forResource: "feverloop", withExtension: "wav"),
           let feverPlayer = try? AVAudioPlayer(contentsOf: feverURL) {
            feverPlayer.numberOfLoops = -1
            feverPlayer.volume = 0.34
            feverPlayer.prepareToPlay()
            feverMusicPlayer = feverPlayer
        }
    }

    private static func play(_ name: String, enabled: Bool) {
        guard enabled else { return }
        guard let player = players[name] else { return }
        guard canPlay(name) else { return }
        lastPlayTimes[name] = ProcessInfo.processInfo.systemUptime
        player.currentTime = 0
        player.play()
    }

    private static func canPlay(_ name: String) -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let minimumInterval: TimeInterval
        switch name {
        case "lumen":
            minimumInterval = isFeverActive ? 0.1 : 0.075
        case "tap":
            minimumInterval = 0.035
        case "module":
            minimumInterval = 0.18
        case "stageclear":
            minimumInterval = 0.7
        case "start":
            minimumInterval = 0.45
        case "timecore":
            minimumInterval = 0.25
        default:
            minimumInterval = 0
        }

        guard minimumInterval > 0 else { return true }
        return now - (lastPlayTimes[name] ?? -10) >= minimumInterval
    }

    private static func volume(for name: String) -> Float {
        switch name {
        case "tap":
            return 0.46
        case "lumen", "collect":
            return 0.58
        case "start", "stageclear", "fever":
            return 0.74
        case "module", "shield", "timecore":
            return 0.64
        case "crash", "shieldbreak":
            return 0.7
        default:
            return 0.62
        }
    }
}
