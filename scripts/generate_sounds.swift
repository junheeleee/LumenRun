import Foundation

let sampleRate = 44_100
let twoPi = Double.pi * 2
let outputDirectory = URL(fileURLWithPath: "LumenRun/Sounds", isDirectory: true)

func clamp(_ value: Double, min minimum: Double = -1, max maximum: Double = 1) -> Double {
    Swift.max(minimum, Swift.min(maximum, value))
}

func sine(_ frequency: Double, _ time: Double) -> Double {
    sin(twoPi * frequency * time)
}

func square(_ frequency: Double, _ time: Double) -> Double {
    sine(frequency, time) >= 0 ? 1 : -1
}

func saw(_ frequency: Double, _ time: Double) -> Double {
    let phase = (time * frequency).truncatingRemainder(dividingBy: 1)
    return phase * 2 - 1
}

func noise(_ time: Double) -> Double {
    let seed = sin(time * 12_989.8 + 78.233) * 43_758.5453
    return (seed - floor(seed)) * 2 - 1
}

func envelope(_ time: Double, attack: Double, decay: Double, sustain: Double = 0, release: Double, duration: Double) -> Double {
    if time < attack {
        return attack <= 0 ? 1 : time / attack
    }
    if time < attack + decay {
        let progress = (time - attack) / max(decay, 0.0001)
        return 1 + (sustain - 1) * progress
    }
    if time < duration - release {
        return sustain
    }
    let releaseProgress = (time - (duration - release)) / max(release, 0.0001)
    return sustain * max(0, 1 - releaseProgress)
}

func pulseEnvelope(_ localTime: Double, length: Double, sharpness: Double = 9) -> Double {
    guard localTime >= 0, localTime <= length else { return 0 }
    let attack = min(0.018, length * 0.18)
    if localTime < attack {
        return localTime / max(attack, 0.0001)
    }
    return exp(-(localTime - attack) * sharpness)
}

func softClip(_ value: Double) -> Double {
    value / (1 + abs(value))
}

func writeWav(name: String, duration: Double, stereo: Bool = true, render: (Double) -> (Double, Double)) throws {
    let sampleCount = Int(duration * Double(sampleRate))
    let channels = stereo ? 2 : 1
    let bytesPerSample = 2
    let dataByteCount = sampleCount * channels * bytesPerSample

    var data = Data()
    appendString("RIFF", to: &data)
    appendLE(UInt32(36 + dataByteCount), to: &data)
    appendString("WAVE", to: &data)
    appendString("fmt ", to: &data)
    appendLE(UInt32(16), to: &data)
    appendLE(UInt16(1), to: &data)
    appendLE(UInt16(channels), to: &data)
    appendLE(UInt32(sampleRate), to: &data)
    appendLE(UInt32(sampleRate * channels * bytesPerSample), to: &data)
    appendLE(UInt16(channels * bytesPerSample), to: &data)
    appendLE(UInt16(16), to: &data)
    appendString("data", to: &data)
    appendLE(UInt32(dataByteCount), to: &data)

    for index in 0..<sampleCount {
        let time = Double(index) / Double(sampleRate)
        let sample = render(time)
        appendSample(sample.0, to: &data)
        if stereo {
            appendSample(sample.1, to: &data)
        }
    }

    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    try data.write(to: outputDirectory.appendingPathComponent(name))
    print("Wrote LumenRun/Sounds/\(name)")
}

func appendString(_ string: String, to data: inout Data) {
    data.append(contentsOf: string.utf8)
}

func appendLE<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) { bytes in
        data.append(contentsOf: bytes)
    }
}

func appendSample(_ value: Double, to data: inout Data) {
    let clipped = Int16(clamp(softClip(value) * 0.92) * Double(Int16.max))
    appendLE(clipped, to: &data)
}

func pluck(_ time: Double, interval: Double, notes: [Double], root: Double, decay: Double, offset: Double = 0) -> Double {
    let shifted = time + offset
    let step = Int(floor(shifted / interval))
    let local = shifted - Double(step) * interval
    let note = notes[(step % notes.count + notes.count) % notes.count]
    let frequency = root * pow(2, note / 12)
    let tone = sine(frequency, time) * 0.78 + sine(frequency * 2.01, time) * 0.18 + saw(frequency * 0.5, time) * 0.04
    return tone * pulseEnvelope(local, length: interval * 0.95, sharpness: decay)
}

func beatPulse(_ time: Double, bpm: Double, subdivision: Double = 1) -> Double {
    let interval = 60 / bpm / subdivision
    let local = time.truncatingRemainder(dividingBy: interval)
    return pulseEnvelope(local, length: interval * 0.8, sharpness: 22)
}

try writeWav(name: "background.wav", duration: 12.8, stereo: true) { time in
    let bpm = 150.0
    let notes = [0.0, 7.0, 10.0, 12.0, 15.0, 12.0, 10.0, 7.0]
    let arpLeft = pluck(time, interval: 60 / bpm / 2, notes: notes, root: 196, decay: 10)
    let arpRight = pluck(time, interval: 60 / bpm / 2, notes: notes.reversed(), root: 247, decay: 9, offset: 60 / bpm / 4)
    let bassStep = Int(floor(time / (60 / bpm * 2)))
    let bassNote = [0.0, -2.0, -5.0, -2.0][bassStep % 4]
    let bassFrequency = 98 * pow(2, bassNote / 12)
    let bass = sine(bassFrequency, time) * beatPulse(time, bpm: bpm, subdivision: 0.5) * 0.28
    let tick = noise(time) * beatPulse(time + 0.02, bpm: bpm, subdivision: 4) * 0.045
    let pad = (sine(49, time) + sine(73.5, time + 0.08)) * 0.05
    let shimmer = sine(880, time + sine(0.18, time) * 0.002) * 0.018
    return (
        arpLeft * 0.28 + arpRight * 0.13 + bass + tick + pad + shimmer,
        arpRight * 0.28 + arpLeft * 0.13 + bass * 0.88 - tick * 0.7 + pad + shimmer * 0.8
    )
}

try writeWav(name: "feverloop.wav", duration: 4.8, stereo: true) { time in
    let bpm = 180.0
    let notes = [0.0, 3.0, 7.0, 10.0, 12.0, 15.0, 19.0, 22.0]
    let lead = pluck(time, interval: 60 / bpm / 2, notes: notes, root: 261.63, decay: 13)
    let counter = pluck(time, interval: 60 / bpm / 4, notes: notes.reversed(), root: 329.63, decay: 15, offset: 0.04)
    let drive = (square(65.41, time) * 0.14 + sine(130.82, time) * 0.18) * beatPulse(time, bpm: bpm, subdivision: 1)
    let hats = noise(time) * beatPulse(time + 0.012, bpm: bpm, subdivision: 4) * 0.075
    let sweep = sine(1_320 + sine(1.4, time) * 90, time) * 0.035
    return (
        lead * 0.32 + counter * 0.16 + drive + hats + sweep,
        counter * 0.28 + lead * 0.14 + drive * 0.92 - hats * 0.65 + sweep
    )
}

try writeWav(name: "tap.wav", duration: 0.09, stereo: false) { time in
    let env = envelope(time, attack: 0.001, decay: 0.035, sustain: 0.0, release: 0.02, duration: 0.09)
    let click = noise(time) * exp(-time * 80) * 0.18
    return (sine(840, time) * env * 0.52 + click, 0)
}

try writeWav(name: "lumen.wav", duration: 0.18, stereo: false) { time in
    let env = envelope(time, attack: 0.004, decay: 0.08, sustain: 0.18, release: 0.06, duration: 0.18)
    let glide = 980 + 420 * exp(-time * 18)
    let tone = sine(glide, time) * 0.58 + sine(glide * 1.5, time) * 0.22 + sine(glide * 2.01, time) * 0.08
    return (tone * env, 0)
}

try writeWav(name: "collect.wav", duration: 0.16, stereo: false) { time in
    let env = envelope(time, attack: 0.003, decay: 0.055, sustain: 0.12, release: 0.05, duration: 0.16)
    let tone = sine(740 + 320 * exp(-time * 20), time) + sine(1_480, time) * 0.22
    return (tone * env * 0.48, 0)
}

try writeWav(name: "shield.wav", duration: 0.38, stereo: false) { time in
    let env = envelope(time, attack: 0.01, decay: 0.1, sustain: 0.32, release: 0.14, duration: 0.38)
    let rise = 360 + 520 * (time / 0.38)
    let tone = sine(rise, time) * 0.36 + sine(rise * 1.5, time) * 0.18 + sine(1_760, time) * 0.04
    return (tone * env + noise(time) * env * 0.025, 0)
}

try writeWav(name: "timecore.wav", duration: 0.44, stereo: false) { time in
    let env = envelope(time, attack: 0.006, decay: 0.14, sustain: 0.24, release: 0.16, duration: 0.44)
    let wobble = 420 + sin(twoPi * 8 * time) * 65
    let tone = sine(wobble, time) * 0.38 + sine(wobble * 2.0, time) * 0.1
    let reversedChime = sine(1_280 - 520 * (time / 0.44), time) * 0.15
    return ((tone + reversedChime) * env, 0)
}

try writeWav(name: "stageclear.wav", duration: 0.86, stereo: true) { time in
    let env = envelope(time, attack: 0.01, decay: 0.18, sustain: 0.42, release: 0.32, duration: 0.86)
    let chime1 = sine(523.25, time) * pulseEnvelope(time, length: 0.26, sharpness: 5)
    let chime2 = sine(659.25, time - 0.12) * pulseEnvelope(time - 0.12, length: 0.26, sharpness: 5)
    let chime3 = sine(783.99, time - 0.24) * pulseEnvelope(time - 0.24, length: 0.32, sharpness: 5)
    let sweep = sine(220 + 520 * min(1, time / 0.68), time) * env * 0.25
    let sparkle = noise(time) * env * max(0, 0.035 - time * 0.02)
    return (
        chime1 * 0.34 + chime2 * 0.2 + chime3 * 0.28 + sweep + sparkle,
        chime1 * 0.2 + chime2 * 0.34 + chime3 * 0.3 + sweep * 0.85 - sparkle
    )
}

try writeWav(name: "module.wav", duration: 0.34, stereo: false) { time in
    let env = envelope(time, attack: 0.003, decay: 0.08, sustain: 0.24, release: 0.1, duration: 0.34)
    let connect = sine(420, time) * pulseEnvelope(time, length: 0.12, sharpness: 12)
    let lock = sine(840, time - 0.12) * pulseEnvelope(time - 0.12, length: 0.16, sharpness: 10)
    let shimmer = sine(1_680, time) * env * 0.08
    return (connect * 0.38 + lock * 0.42 + shimmer, 0)
}

try writeWav(name: "start.wav", duration: 0.56, stereo: true) { time in
    let env = envelope(time, attack: 0.02, decay: 0.12, sustain: 0.48, release: 0.2, duration: 0.56)
    let rise = 180 + 620 * pow(time / 0.56, 1.2)
    let core = sine(rise, time) * 0.32 + sine(rise * 2.0, time) * 0.12
    let pulse = sine(980, time) * pulseEnvelope(time - 0.34, length: 0.18, sharpness: 9)
    let noiseLift = noise(time) * env * 0.025
    return (
        core * env + pulse * 0.28 + noiseLift,
        core * env * 0.9 + pulse * 0.34 - noiseLift
    )
}

try writeWav(name: "fever.wav", duration: 0.74, stereo: false) { time in
    let env = envelope(time, attack: 0.02, decay: 0.08, sustain: 0.55, release: 0.22, duration: 0.74)
    let rise = 320 + 1_560 * pow(time / 0.74, 1.35)
    let blast = pulseEnvelope(time - 0.46, length: 0.24, sharpness: 7)
    let tone = sine(rise, time) * 0.38 + sine(rise * 1.5, time) * 0.16 + sine(220, time) * blast * 0.34
    return (tone * env + noise(time) * blast * 0.08, 0)
}

try writeWav(name: "shieldbreak.wav", duration: 0.38, stereo: false) { time in
    let env = envelope(time, attack: 0.001, decay: 0.12, sustain: 0.16, release: 0.16, duration: 0.38)
    let crack = noise(time) * exp(-time * 9) * 0.32
    let drop = sine(520 - 260 * time / 0.38, time) * env * 0.24
    return (crack + drop, 0)
}

try writeWav(name: "voidbreak.wav", duration: 0.42, stereo: false) { time in
    let env = envelope(time, attack: 0.002, decay: 0.1, sustain: 0.18, release: 0.18, duration: 0.42)
    let warp = sine(310 - 170 * min(1, time / 0.42), time) * env * 0.34
    let hollow = sine(92 + sin(twoPi * 5 * time) * 18, time) * env * 0.28
    let staticGate = noise(time) * pulseEnvelope(time, length: 0.2, sharpness: 8) * 0.16
    return (warp + hollow + staticGate, 0)
}

try writeWav(name: "crash.wav", duration: 0.5, stereo: false) { time in
    let env = envelope(time, attack: 0.001, decay: 0.16, sustain: 0.18, release: 0.2, duration: 0.5)
    let impact = noise(time) * exp(-time * 7) * 0.42
    let low = sine(95 - 38 * min(1, time / 0.5), time) * env * 0.52
    let grit = square(46, time) * env * 0.08
    return (impact + low + grit, 0)
}

try writeWav(name: "fail.wav", duration: 0.55, stereo: false) { time in
    let env = envelope(time, attack: 0.002, decay: 0.12, sustain: 0.2, release: 0.22, duration: 0.55)
    let fall = sine(420 - 280 * min(1, time / 0.55), time) * 0.38
    let staticTail = noise(time) * env * 0.08
    return ((fall + staticTail) * env, 0)
}
