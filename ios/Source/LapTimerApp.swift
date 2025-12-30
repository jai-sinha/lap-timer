import SwiftUI
import ConnectIQ

@main
struct LapTimerApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .center) {
                Text("Lap Timer Companion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                Divider()
                MessageView()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
