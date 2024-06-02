import SwiftUI
import Speech
import AVFoundation
import UserNotifications

class RecognitionViewModel: ObservableObject {
    @Published var isListening = false
    @Published var transcription = ""
    @Published var countdown = 10
    @Published var statusMessage = "録音を開始してください"
    @Published var apiResult: Float?
    @Published var isAwake = false  // 画面遷移用のフラグ
    @Published var isWaitingForAPI = false  // API待機用のフラグ
    @Published var achievementPercentage: Int?  // 達成率

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var timer: Timer?
    private var audioFile: AVAudioFile?
    private let audioFileName = "recording.wav"  // 音声ファイルをwav形式で保存
    private var selectedDate: Date
    private var isTomorrow: Bool
    private var immediate: Bool
    private var startTime: Date?

    // APIエンドポイント
    private let apiEndpoint = "https://ai-api.userlocal.jp/voice-emotion/basic-emotions"

    init(selectedDate: Date, isTomorrow: Bool, immediate: Bool = false) {
        self.selectedDate = selectedDate
        self.isTomorrow = isTomorrow
        self.immediate = immediate
        requestPermissions()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    self.statusMessage = "音声認識の権限がありません"
                }
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.statusMessage = "マイクの権限がありません"
                }
            }
        }
    }

    func startListening() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            if let audioFile = self.audioFile {
                try? audioFile.write(from: buffer)
            }
        }

        prepareAudioFile()

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.statusMessage = "音声録音中"
                self.startCountdown()
                self.checkRecordingStartTimeout()
            }
        } catch {
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                }
            } else if let error = error {
                print("Recognition error: \(error)")
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
            self.statusMessage = "録音を開始してください"
            self.isWaitingForAPI = true
        }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        completeAudioFile()
        sendAudioToAPI()
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
    }

    func sendAudioToAPI() {
        guard let audioFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(audioFileName) else { return }

        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let fileData = try? Data(contentsOf: audioFileURL) else { return }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"voice_data\"; filename=\"\(audioFileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }

            self.handleAPIResponse(responseData: data)
        }

        task.resume()
    }

    func handleAPIResponse(responseData: Data) {
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
              let status = jsonResponse["status"] as? String, status == "ok",
              let emotionDetail = jsonResponse["emotion_detail"] as? [String: Any] else {
            sendRetryNotification()
            return
        }

        // 必要なデバッグ情報を出力
        print("API response: \(jsonResponse)")
        print("happy: \(emotionDetail["happy"] ?? "nil")")
        print("angry: \(emotionDetail["angry"] ?? "nil")")
        print("surprise: \(emotionDetail["surprise"] ?? "nil")")

        DispatchQueue.main.async {
            self.isWaitingForAPI = false

            let happyValueString = "\(emotionDetail["happy"] ?? "nil")"
            let happyValue = Float(happyValueString) ?? -1

            let angryValueString = "\(emotionDetail["angry"] ?? "nil")"
            let angryValue = Float(angryValueString) ?? -1

            let surpriseValueString = "\(emotionDetail["surprise"] ?? "nil")"
            let surpriseValue = Float(surpriseValueString) ?? -1

            if happyValue >= 0 && angryValue >= 0 && surpriseValue >= 0 {
                self.apiResult = happyValue + 2 * angryValue + 3 * surpriseValue
                self.achievementPercentage = Int((self.apiResult! / 0.6) * 100)
                print("API Result: \(self.apiResult ?? 0)")

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self.apiResult! >= 0.6 {
                        self.isAwake = true
                    } else {
                        self.isAwake = false
                    }
                }
            } else {
                self.sendRetryNotification()
            }
        }
    }

    func checkRecordingStartTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if !self.isListening {
                self.sendRetryNotification()
            }
        }
    }

    func sendRetryNotification() {
        let content = UNMutableNotificationContent()
        content.title = "再試行通知"
        content.body = "音声録音が開始されませんでした。再度お試しください。"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "RetryNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func sendImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = "これは即時通知のテストです"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "ImmediateNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func resetState() {
        isListening = false
        transcription = ""
        countdown = 10
        statusMessage = "録音を開始してください"
        apiResult = nil
        isAwake = false
        isWaitingForAPI = false
        achievementPercentage = nil
    }
}

