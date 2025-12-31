import SwiftUI

@main
struct LapTimerCompanionApp: App {
    init() {
        // Initialize ConnectIQ.
        GarminService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            MessageView()
                .onOpenURL { url in
                    GarminService.shared.handle(url: url)
                }
        }
    }
}
