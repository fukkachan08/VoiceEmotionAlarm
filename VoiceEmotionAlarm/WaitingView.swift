import SwiftUI

struct WaitingView: View {
    var achievementPercentage: Int

    var body: some View {
        VStack {
            Spacer()
            Text("APIの結果を待っています...")
                .font(.title)
                .padding()
            Text("達成率: \(achievementPercentage)%")
                .font(.title2)
                .padding()
            ProgressView()
                .padding()
            Spacer()
        }
    }
}

