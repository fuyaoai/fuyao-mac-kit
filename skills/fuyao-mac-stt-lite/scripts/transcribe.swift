// fuyao-mac-stt-lite — macOS SpeechAnalyzer (SpeechTranscriber) local transcription
// Requires macOS 26+. Zero-install: on-device speech models ship with the OS.
// Usage: swift transcribe.swift <audio-file> [locale]   (locale default: zh-CN)

import Foundation
import AVFoundation
import Speech

func die(_ msg: String) -> Never { FileHandle.standardError.write(("error: " + msg + "\n").data(using: .utf8)!); exit(1) }

let args = CommandLine.arguments
guard args.count >= 2 else { die("usage: transcribe.swift <audio-file> [locale]") }
let url = URL(fileURLWithPath: args[1])
let localeID = args.count >= 3 ? args[2] : "zh-CN"

// Authorization (new framework shares the legacy speech-recognition permission)
if SFSpeechRecognizer.authorizationStatus() != .authorized {
    print("auth: requesting (approve the system prompt / enable in Settings → Privacy → Speech Recognition)...")
    SFSpeechRecognizer.requestAuthorization { _ in }
    for _ in 0..<120 where SFSpeechRecognizer.authorizationStatus() != .authorized { usleep(1_000_000) }
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else { die("speech recognition not authorized") }
}

let locale = Locale(identifier: localeID)
let supported = await SpeechTranscriber.supportedLocales.map { $0.identifier(.bcp47) }
guard supported.contains(localeID) else { die("locale \(localeID) not supported. Samples: \(supported.prefix(10))") }

let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
let analyzer = SpeechAnalyzer(modules: [transcriber])

// Ensure on-device assets (nil = already installed)
if let req = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
    print("downloading on-device speech assets...")
    req.progress.resume()
    while req.progress.fractionCompleted < 1.0 {
        print(String(format: "  %.0f%%", req.progress.fractionCompleted * 100)); usleep(2_000_000)
    }
}

let audioFile: AVAudioFile
do { audioFile = try AVAudioFile(forReading: url) } catch { die("cannot read audio: \(error.localizedDescription)") }
let dur = CMTimeGetSeconds(CMTime(value: CMTimeValue(audioFile.length), timescale: CMTimeScale(audioFile.processingFormat.sampleRate)))
print("file: \(url.lastPathComponent) (\(Int(dur))s, locale: \(localeID))")

let t0 = Date()
var full = ""
try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)
for try await result in transcriber.results {
    let text = String(result.text.characters)
    let start = Int(result.range.start.seconds)
    let end = Int(result.range.end.seconds)
    print("[\(start)-\(end)s] \(text)")
    full += text
}
let elapsed = Date().timeIntervalSince(t0)
print("=== FULL (\(full.count) chars, took \(String(format: "%.1f", elapsed))s for \(Int(dur))s audio) ===")
print(full)
