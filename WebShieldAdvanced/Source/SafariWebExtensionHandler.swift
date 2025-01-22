import OSLog
import SafariServices

// MARK: - SafariWebExtensionHandler
final class SafariWebExtensionHandler: NSObject, @preconcurrency NSExtensionRequestHandling {
    private var currentReader: ChunkFileReader?

    override init() {
        super.init()
    }

    @MainActor
    func beginRequest(with context: NSExtensionContext) {
        do {
            guard let message = context.inputItems.first as? NSExtensionItem,
                let userInfo = message.userInfo?[SFExtensionMessageKey] as? [String: Any],
                let action = userInfo["action"] as? String
            else {
                return sendErrorResponse(context, message: "Invalid request")
            }

            switch action {
            case "getAdvancedBlockingData":
                try handleBlockingDataRequest(context, userInfo: userInfo)
            default:
                sendErrorResponse(context, message: "Unknown action")
            }
        } catch {
            sendErrorResponse(context, message: error.localizedDescription)
        }
    }

    @MainActor
    private func handleBlockingDataRequest(_ context: NSExtensionContext, userInfo: [String: Any]) throws {
        guard let urlString = userInfo["url"] as? String,
            let url = URL(string: urlString)
        else {
            throw BlockingError.invalidURL
        }

        Task {
            let data = try await ContentBlockerEngineWrapper.shared?.getBlockingData(for: url)

            if data?.utf8.count ?? 0 > 32_768 {
                try await sendChunkedResponse(context, url: urlString)
            } else {
                sendSingleResponse(context, data: data ?? "", url: urlString)
            }
        }
    }

    private func sendChunkedResponse(_ context: NSExtensionContext, url: String) async throws {
        let reader = try await ContentBlockerEngineWrapper.shared?.makeChunkedReader()
        currentReader = reader

        let response = NSExtensionItem()
        var message: [String: Any] = [
            "url": url,
            "chunked": true,
            "more": true,
        ]

        // Use async actor calls
        if let chunk = await reader?.nextChunk() {
            message["data"] = chunk
            message["more"] = await reader?.progress ?? 0 < 1.0
        }

        response.userInfo = [SFExtensionMessageKey: message]
        context.completeRequest(returningItems: [response])
    }

    private func sendSingleResponse(_ context: NSExtensionContext, data: String, url: String) {
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "url": url,
                "data": data,
                "chunked": false,
            ]
        ]
        context.completeRequest(returningItems: [response])
    }

    private func sendErrorResponse(_ context: NSExtensionContext, message: String) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["error": message]]
        context.completeRequest(returningItems: [response])
    }

    enum BlockingError: Error {
        case invalidURL
    }
}
