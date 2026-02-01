import Foundation
import AVFoundation
import SoundAnalysis
import CoreML

final class SoundClassifierService: NSObject {
    struct Classification: Equatable {
        let identifier: String
        let confidence: Double
    }

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private var request: SNClassifySoundRequest?
    private let queue = DispatchQueue(label: "soundanalysis.queue")
    private var converter: AVAudioConverter?
    private var currentSampleTime: Int64 = 0
    private var observer: ResultsObserver? // Retain için

    private var onResult: (([Classification]) -> Void)?

    func start(modelFileName: String,
               confidenceThreshold: Double = 0.75,
               onResult: @escaping ([Classification]) -> Void) async throws {

        print("🎤 Ses dinleme başlatılıyor...")
        self.onResult = onResult
        self.currentSampleTime = 0

        // Mikrofon izni kontrolü
        let status = AVAudioApplication.shared.recordPermission
        print("🎤 Mikrofon izni durumu: \(status.rawValue)")
        guard status == .granted else {
            throw NSError(domain: "Mic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mikrofon izni verilmedi. Lütfen Ayarlar'dan izin verin."])
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true)
        print("✅ Audio session aktif")

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("🎵 Input format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) channel")
        
        // Model 16000 Hz bekliyor
        let targetSampleRate: Double = 16000.0
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetSampleRate, channels: 1, interleaved: false) else {
            throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Target format oluşturulamadı"])
        }
        print("🎵 Target format: \(targetFormat.sampleRate) Hz, 1 channel")
        
        // Format converter
        guard let formatConverter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Format converter oluşturulamadı"])
        }
        self.converter = formatConverter
        print("✅ Format converter oluşturuldu")

        // Analyzer - target format ile
        analyzer = SNAudioStreamAnalyzer(format: targetFormat)
        print("✅ Audio analyzer oluşturuldu")

        // Model yükle
        let model = try loadCompiledModel(named: modelFileName)
        print("✅ Model yüklendi")
        
        // Request oluştur
        request = try SNClassifySoundRequest(mlModel: model)
        print("✅ Classification request oluşturuldu, threshold: \(confidenceThreshold)")

        // Observer - retain etmek için property olarak sakla
        let observer = ResultsObserver(confidenceThreshold: confidenceThreshold) { [weak self] results in
            guard let self else { 
                print("⚠️ Observer callback: self is nil")
                return 
            }
            print("📞 Observer callback: \(results.count) sonuç")
            let mapped = results.map { Classification(identifier: $0.identifier, confidence: $0.confidence) }
            Task { @MainActor in
                self.onResult?(mapped)
            }
        }
        
        // Observer'ı retain et (deallocate olmasın)
        self.observer = observer

        try analyzer?.add(request!, withObserver: observer)
        print("✅ Observer eklendi")

        // Audio tap
        var bufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            guard let self, let analyzer = self.analyzer, let converter = self.converter else {
                return
            }
            
            bufferCount += 1
            
            self.queue.async {
                // Format dönüşümü
                let ratio = targetFormat.sampleRate / buffer.format.sampleRate
                let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 100)
                
                guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
                    if bufferCount <= 5 {
                        print("❌ Output buffer oluşturulamadı")
                    }
                    return
                }
                
                outputBuffer.frameLength = 0
                
                var error: NSError?
                let inputProvidedLock = NSLock()
                var inputProvided = false
                
                let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                    inputProvidedLock.lock()
                    defer { inputProvidedLock.unlock() }
                    
                    if inputProvided {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    outStatus.pointee = .haveData
                    inputProvided = true
                    return buffer
                }
                
                let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
                
                if let error = error {
                    if bufferCount <= 5 {
                        print("❌ Conversion error: \(error.localizedDescription)")
                    }
                    return
                }
                
                if outputBuffer.frameLength == 0 {
                    if bufferCount <= 5 {
                        print("⚠️ Output buffer frameLength is 0, status: \(status.rawValue)")
                    }
                    return
                }
                
                // Sample time - sequential (her buffer bir öncekinin devamı)
                let sampleTime = self.currentSampleTime
                self.currentSampleTime += Int64(outputBuffer.frameLength)
                
                if bufferCount <= 10 {
                    print("📊 Buffer \(bufferCount): \(outputBuffer.frameLength) frames @ sampleTime: \(sampleTime) (next: \(self.currentSampleTime))")
                } else if bufferCount % 100 == 0 {
                    print("📊 Buffer \(bufferCount): \(outputBuffer.frameLength) frames @ sampleTime: \(sampleTime)")
                }
                
                // Analyze - SoundAnalysis window'ları otomatik oluşturur
                analyzer.analyze(outputBuffer, atAudioFramePosition: sampleTime)
                
                if bufferCount <= 10 {
                    print("   ✅ analyze() çağrıldı")
                }
            }
        }
        print("✅ Audio tap kuruldu")

        audioEngine.prepare()
        try audioEngine.start()
        print("✅ Audio engine başlatıldı - DİNLENİYOR...")
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        analyzer = nil
        request = nil
        observer = nil
        onResult = nil
        converter = nil
        currentSampleTime = 0
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func loadCompiledModel(named name: String) throws -> MLModel {
        if let compiledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            return try MLModel(contentsOf: compiledURL)
        }
        if let sourceURL = Bundle.main.url(forResource: name, withExtension: "mlmodel") {
            return try MLModel(contentsOf: sourceURL)
        }
        throw NSError(
            domain: "MLModel",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Model bulunamadı: \(name)"]
        )
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
        print("🔔🔔🔔 request(_:didProduce:) ÇAĞRILDI! 🔔🔔🔔")
        
        guard let classificationResult = result as? SNClassificationResult else {
            print("⚠️ Result is not SNClassificationResult")
            return
        }
        
        print("✅ SNClassificationResult: \(classificationResult.classifications.count) classifications")
        
        if !classificationResult.classifications.isEmpty {
            let sorted = classificationResult.classifications.sorted { $0.confidence > $1.confidence }
            let top = sorted.first!
            print("🎤 Top result: \(top.identifier) - \(String(format: "%.3f", top.confidence))")
            
            if sorted.count > 1 {
                print("   Top 3:")
                for (i, c) in sorted.prefix(3).enumerated() {
                    print("   \(i+1). \(c.identifier): \(String(format: "%.3f", c.confidence))")
                }
            }
        }
        
        let filtered = classificationResult.classifications
            .filter { $0.confidence >= threshold }
            .sorted { $0.confidence > $1.confidence }

        if !filtered.isEmpty {
            print("✅ Passing \(filtered.count) results to handler")
            handler(filtered)
        } else if let top = classificationResult.classifications.max(by: { $0.confidence < $1.confidence }) {
            print("⚠️ No results above threshold. Top: \(top.identifier) (\(String(format: "%.3f", top.confidence)))")
            handler([top])
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("❌ SNRequest failed: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("✅ SNRequest completed")
    }
}
