import SwiftUI

struct RecognitionView: View {
    @StateObject private var viewModel = RecognitionViewModel()

    var body: some View {
        VStack {
            if viewModel.isAwake {
                SuccessView()
            } else {
                Text(viewModel.statusMessage)
                    .font(.headline)
                    .padding()

                if viewModel.isListening {
                    Text("録音終了まで: \(viewModel.countdown)秒")
                        .padding()
                    Text(viewModel.transcription)
                        .padding()
                }

                Spacer()

                if let apiResult = viewModel.apiResult {
                    if apiResult > 0.5 {
                        Text("ハキハキ度合いが基準を上回りました")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } else {
                        Button(action: viewModel.startListening) {
                            Text("再度録音を開始")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else if viewModel.isListening {
                    Button(action: viewModel.stopListening) {
                        Text("停止")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.startListening()
        }
    }
}

