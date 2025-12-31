import SwiftUI
import Combine
import ConnectIQ

struct MessageView: View {
    @State
    var message = ""

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 7
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            Text(message.isEmpty ? "No message from the spirits." : "The spirits say:\n\(message)")
                .multilineTextAlignment(.center)

            Button("Connect Device") {
                ConnectIQ.shared?.showDeviceSelection()
            }
        }
        .task {
            // This will let the user pick ConnectIQ devices to connect to the app (or automatically pick the only one if there aren't more).
            // Your app may be suspended during this, act accordingly.
            if !GarminService.shared.hasSavedDevices {
                try? await Task.sleep(nanoseconds: 500_000_000)
                ConnectIQ.shared?.showDeviceSelection()
            }

            for await data in GarminService.shared.messageStream {
                do {
                    let dto = try JSONDecoder().decode(MessageDTO.self, from: data)
                    let results = dto.results
                    message = """
                    Lap Times: \(results.lapTimes)
                    Best Lap: \(results.bestLap)
                    Total Time: \(results.totalTime)
                    """
                } catch {
                    message = ""
                }
            }
        }
        .onTapGesture {
            Task {
                await GarminService.shared.broadcast(dto: "General Kenobi.")
            }
        }
    }
}
