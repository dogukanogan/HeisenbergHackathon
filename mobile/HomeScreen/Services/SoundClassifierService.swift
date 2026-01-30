import Foundation
import AVFoundation
import SoundAnalysis
import CoreML

@MainActor
final class SoundClassifierService: NSObject {
    struct Classification: Equatable {
        let identifier: String
        let confidence: Double
    }

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private var request: SNClassifySoundRequest?
    private let queue = DispatchQueue(label: "soundanalysis.queue")

    private var onResult: (([Classification]) -> Void)?

    func start(modelFileName: String,
               confidenceThreshold: Double = 0.75,
               onResult: @escaping ([Classification]) -> Void) async throws {

        self.onResult = onResult

        // Mikrofon izni
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            throw NSError(domain: "Mic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mikrofon izni verilmedi."])
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        analyzer = SNAudioStreamAnalyzer(format: format)

        let model = try loadCompiledModel(named: modelFileName)
        request = try SNClassifySoundRequest(mlModel: model)

        let observer = ResultsObserver(confidenceThreshold: confidenceThreshold) { [weak self] results in
            guard let self else { return }
            let mapped = results.map { Classification(identifier: $0.identifier, confidence: $0.confidence) }
            Task { @MainActor in
                self.onResult?(mapped)
            }
        }

        try analyzer?.add(request!, withObserver: observer)

        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { [weak self] buffer, time in
            guard let self, let analyzer = self.analyzer else { return }
            self.queue.async {
                analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        analyzer = nil
        request = nil
        onResult = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func loadCompiledModel(named name: String) throws -> MLModel {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            throw NSError(domain: "MLModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model bulunamadı: \(name).mlmodelc"])
        }
        return try MLModel(contentsOf: url)
    }
}

private final class ResultsObserver: NSObject, SNResultsObserving {
    private let threshold: Double
    private let handler: ([SNClassification]) -> Void

    init(confidenceThreshold: Double, handler: @escaping ([SNClassification]) -> Void) {
        self.threshold = confidenceThreshold
        self.handler = handler
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        let filtered = result.classifications
            .filter { $0.confidence >= threshold }
            .sorted { $0.confidence > $1.confidence }

        if !filtered.isEmpty {
            handler(filtered)
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) { }
    func requestDidComplete(_ request: SNRequest) { }
}
