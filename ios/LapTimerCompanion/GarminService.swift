import Foundation
import Observation
import ConnectIQ
import OSLog

private let logger = Logger(subsystem: "com.jaisinha.laptimercompanion", category: "GarminService")

@Observable
final class GarminService {
    // This must match the value in `Info.plist`.
    private static let urlScheme = "com.jaisinha.laptimercompanion"
    private static let storedDeviceUUIDsKey = "GarminService.storedDeviceUUIDs"

    static let shared = GarminService()

    private let manager = Manager()

    let messageStream: AsyncStream<Data>
    private let messageContinuation: AsyncStream<Data>.Continuation

    var connectedDevices: [IQDevice] {
        Array(manager.apps.values.map { $0.device })
    }

    var hasSavedDevices: Bool {
        let uuids = UserDefaults.standard.stringArray(forKey: Self.storedDeviceUUIDsKey) ?? []
        return !uuids.isEmpty
    }

    private func saveDevice(_ device: IQDevice) {
        var uuids = UserDefaults.standard.stringArray(forKey: Self.storedDeviceUUIDsKey) ?? []
        let uuidString = device.uuid.uuidString
        if !uuids.contains(uuidString) {
            uuids.append(uuidString)
            UserDefaults.standard.set(uuids, forKey: Self.storedDeviceUUIDsKey)
        }
    }

    private func restoreSavedDevices() {
        let uuids = UserDefaults.standard.stringArray(forKey: Self.storedDeviceUUIDsKey) ?? []
        for uuidString in uuids {
            if let uuid = UUID(uuidString: uuidString) {
                if let device = IQDevice(id: uuid, modelName: nil, friendlyName: nil) {
                    ConnectIQ.shared?.register(forDeviceEvents: device, delegate: manager)
                    logger.info("Restored device with UUID: \(uuidString)")
                }
            }
        }
    }

    private func clearSavedDevices() {
        UserDefaults.standard.removeObject(forKey: Self.storedDeviceUUIDsKey)
    }

    private init() {
        var continuation: AsyncStream<Data>.Continuation!
        self.messageStream = AsyncStream { continuation = $0 }
        self.messageContinuation = continuation

        ConnectIQ.shared?.initialize(withUrlScheme: Self.urlScheme, uiOverrideDelegate: nil)
        manager.messageHandler = { messageData in
            continuation.yield(messageData)
        }

        restoreSavedDevices()
        logger.info("GarminService initialized")
    }

    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme == Self.urlScheme,
              let devices = ConnectIQ.shared?.parseDeviceSelectionResponse(from: url) as? [IQDevice]
        else { return false }

        for device in devices {
            ConnectIQ.shared?.register(forDeviceEvents: device, delegate: manager)
            saveDevice(device)
        }

        return true
    }

    func broadcast(dto: any Encodable) async {
        await manager.broadcast(dto: dto)
    }
}

private extension GarminService {
    @Observable
    final class Manager: NSObject, IQDeviceEventDelegate, IQAppMessageDelegate {
        private static let watchAppUuid = UUID(uuidString: "dc999a91-9c3d-4fb5-9ab7-1f13ff2ba94c")!

        var apps: [UUID: IQApp] = [:]

        var messageHandler: ((Data) -> Void)?

        func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
            switch status {
            case .connected:
                // The `store` is not necessary for sending messages, I suppose it's for when you want the user to download the app.
                // `IQApp` class needs to be instantiated for every IQDevice, you can't share them, it's the app on the specific device.
                let app = IQApp(uuid: Self.watchAppUuid, store: nil, device: device)
                apps[device.uuid] = app

                ConnectIQ.shared?.register(forAppMessages: app, delegate: self)

                // IMPORTANT: Sending a message right after connecting sends the messages to the void.
                // I have no idea why it doesn't work, but feel free to shrink the delay. I've found that 100ms works reliably.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    ConnectIQ.shared?.sendMessage("Hello there.", to: app, progress: nil, completion: { result in
                        logger.debug("Send message result: \(String(describing: result))")
                    })
                }

            case .bluetoothNotReady, .invalidDevice, .notConnected, .notFound:
                apps.removeValue(forKey: device.uuid)

            @unknown default:
                logger.warning("Unhandled case '\(status.rawValue)'.")
            }
        }

        func receivedMessage(_ message: Any!, from app: IQApp!) {
            logger.debug("Received message from ConnectIQ: \(String(describing: message))")

            guard let message else { return }

            // JSONSerialization.data(withJSONObject:) requires the top-level object to be an NSArray or NSDictionary.
            // If the watch sends a simple String or Number, this will crash.
            guard JSONSerialization.isValidJSONObject(message) else {
                logger.warning("Received message is not a valid JSON object (must be Array or Dictionary): \(String(describing: message))")
                return
            }

            do {
                messageHandler?(try JSONSerialization.data(withJSONObject: message))
            } catch {
                logger.error("Failed to parse payload: \(error)")
            }
        }

        func broadcast(dto: any Encodable) async {
            let message: Any
            if let string = dto as? String {
                message = string
            } else {
                do {
                    let data = try JSONEncoder().encode(dto)
                    message = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                } catch {
                    logger.error("Failed to encode dto: \(error)")
                    return
                }
            }

            for app in apps.values {
                await ConnectIQ.shared?.sendMessage(message, to: app, progress: nil)
                logger.debug("Sent \(String(describing: message)) to \(app)")
            }
        }

        deinit {
            ConnectIQ.shared?.unregister(forAllDeviceEvents: self)
            ConnectIQ.shared?.unregister(forAllAppMessages: self)
        }
    }
}

extension ConnectIQ {
    static var shared: ConnectIQ? {
        sharedInstance()
    }
}
