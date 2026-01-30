import Foundation
import AVFoundation

final class AudioLevelMonitor {
    private var recorder: AVAudioRecorder?
    private(set) var isRunning = false

    /// 0...1 arası yaklaşık seviye
    private(set) var level: Float = 0

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    func start() throws {
        guard !isRunning else { return }
        isRunning = true

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setActive(true)

        // Kaydı dosyaya yazmak şart değil; temp bir dosyaya yazıyoruz
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("temp.caf")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleIMA4),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 12800,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        let rec = try AVAudioRecorder(url: url, settings: settings)
        rec.isMeteringEnabled = true
        rec.prepareToRecord()
        rec.record()

        recorder = rec
        level = 0
    }

    func updateMeters() {
        guard let recorder else { return }
        recorder.updateMeters()
        // dB: -160 ... 0
        let db = recorder.averagePower(forChannel: 0)
        level = Self.normalizedPower(db)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        recorder?.stop()
        recorder = nil
        level = 0

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private static func normalizedPower(_ db: Float) -> Float {
        // -60 dB altını 0 say, 0 dB = 1
        if db < -60 { return 0 }
        let normalized = (db + 60) / 60
        return min(max(normalized, 0), 1)
    }
}
