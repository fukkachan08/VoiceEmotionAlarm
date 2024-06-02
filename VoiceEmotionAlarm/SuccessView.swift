import SwiftUI

struct SuccessView: View {
    @Environment(\.presentationMode) var presentationMode
    var onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text("ハキハキ度合いが基準値を上回りました。")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
            Text("あなたは起きています")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
                onDismiss()
            }) {
                Text("最初の画面に戻る")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

