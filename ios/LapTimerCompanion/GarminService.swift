import Foundation
import Combine
import ConnectIQ
import OSLog

private let logger = Logger(subsystem: "com.jaisinha.laptimercompanion", category: "GarminService")

final class GarminService {
    // This must match the value in `Info.plist`.
    private static let urlScheme = "com.jaisinha.laptimercompanion"
    private static let storedDeviceUUIDsKey = "GarminService.storedDeviceUUIDs"

    static let shared = GarminService()

    private let manager = Manager()

    private let messageSubject = PassthroughSubject<Data, Never>()

    var hasSavedDevices: Bool {
        let uuids = UserDefaults.standard.stringArray(forKey: Self.storedDeviceUUIDsKey) ?? []
        return !uuids.isEmpty
    }

    func observeMessages() -> AnyPublisher<Data, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    var messageStream: AsyncPublisher<PassthroughSubject<Data, Never>> {
        messageSubject.values
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
        ConnectIQ.shared?.initialize(withUrlScheme: Self.urlScheme, uiOverrideDelegate: nil)
        manager.messageHandler = { [weak self] messageData in
            self?.messageSubject.send(messageData)
        }
        restoreSavedDevices()
        logger.info("GarminService initialized")
    }

    func start() {
        // Service is initialized in init()
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
    final class Manager: NSObject, IQDeviceEventDelegate, IQAppMessageDelegate {
        private static let watchAppUuid = UUID(uuidString: "dc999a91-9c3d-4fb5-9ab7-1f13ff2ba94c")!

        @Published
        private(set) var apps: [UUID: IQApp] = [:]

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
                // You may send any ObjC type (e.g. NSNumber, NSString, NSArray, NSDictionary).
                // Unless you're experiencing difficulties, there's no need to use the `NS*` types directly,
                // you can use their Swift equivalents.
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
