import SwiftUI
import Speech
import AVFoundation
import UserNotifications

class RecognitionViewModel: ObservableObject {
    @Published var isListening = false
    @Published var transcription = ""
    @Published var countdown = 10
    @Published var statusMessage = "音声認識中..."
    @Published var apiResult: Float?
    @Published var isAwake = false  // 画面遷移用のフラグ

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var timer: Timer?
    private var audioFile: AVAudioFile?
    private let audioFileName = "recording.caf"

    func startListening() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
            if let audioFile = self.audioFile {
                try? audioFile.write(from: buffer)
            }
        }

        // 音声ファイルの準備
        prepareAudioFile()

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.statusMessage = "音声認識中..."
                self.startCountdown()
            }
        } catch {
            print("Audio engine couldn't start because of an error: \(error)")
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let bestTranscription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcription = bestTranscription
                }
            } else if let error = error {
                print("There was an error: \(error)")
            }
        }
    }

    private func startCountdown() {
        countdown = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                timer.invalidate()
                self.stopListening()
            }
        }
    }

    func stopListening() {
        DispatchQueue.main.async {
            self.isListening = false
            self.timer?.invalidate()
            self.statusMessage = "録音停止"
        }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        completeAudioFile()
        handleAPIResponse(simulatedResult: 0.6)  // 基準値を上回る値を設定
        print("Stopped listening")
    }

    private func prepareAudioFile() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioFileURL = documentsPath.appendingPathComponent(audioFileName)
        do {
            audioFile = try AVAudioFile(forWriting: audioFileURL, settings: audioEngine.inputNode.outputFormat(forBus: 0).settings)
        } catch {
            print("Error creating audio file: \(error)")
        }
    }

    private func completeAudioFile() {
        audioFile = nil
        print("Audio file saved")
    }

    func handleAPIResponse(simulatedResult: Float) {
        DispatchQueue.main.async {
            print("API Response received: \(simulatedResult)")
            self.apiResult = simulatedResult
            if simulatedResult > 0.5 {
                self.isAwake = true
            }
        }
    }
}

