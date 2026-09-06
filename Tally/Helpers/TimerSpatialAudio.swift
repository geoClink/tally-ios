//
//  TimerSpatialAudio.swift
//  Tally
//

#if os(visionOS)
import AVFoundation

// Plays a subtle ambient hum spatially positioned where the volume floats.
// Audio is intentionally very quiet — meant to be felt more than heard.
final class TimerSpatialAudio {
    private let engine = AVAudioEngine()
    private let humNode = AVAudioPlayerNode()
    private let environment = AVAudioEnvironmentNode()

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        engine.attach(humNode)
        engine.attach(environment)

        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(humNode, to: environment, format: monoFormat)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)

        // Position sound ~1.5 m in front of the user — where the volume typically sits
        humNode.position = AVAudio3DPoint(x: 0, y: 0, z: -1.5)
        humNode.renderingAlgorithm = .HRTFHQ
        humNode.reverbBlend = 0.12
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)

        try? engine.start()
    }

    func startHum() {
        guard !humNode.isPlaying, let buffer = makeHumBuffer() else { return }
        humNode.scheduleBuffer(buffer, at: nil, options: .loops)
        humNode.play()
    }

    func stopHum() {
        humNode.stop()
    }

    func tearDown() {
        humNode.stop()
        engine.stop()
    }

    // 3-second looping buffer: 220 Hz fundamental + harmonics, crossfade at loop points
    private func makeHumBuffer() -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frequency: Double = 220
        let duration: Double = 3.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        let amplitude: Float = 0.03
        let fadeFrames = Int(sampleRate * 0.06)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // Envelope to avoid clicks at the loop boundary
            var env: Float = 1.0
            if i < fadeFrames { env = Float(i) / Float(fadeFrames) }
            if i > Int(frameCount) - fadeFrames { env = Float(Int(frameCount) - i) / Float(fadeFrames) }
            data[i] = env * amplitude * (
                0.6  * Float(sin(2 * .pi * frequency * t)) +
                0.25 * Float(sin(2 * .pi * frequency * 2 * t)) +
                0.1  * Float(sin(2 * .pi * frequency * 3 * t)) +
                0.05 * Float(sin(2 * .pi * frequency * 4 * t))
            )
        }
        return buffer
    }
}
#endif
