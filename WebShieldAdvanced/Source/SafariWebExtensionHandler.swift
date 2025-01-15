import OSLog
import SafariServices

@available(macOS 13.0, iOS 16.0, *)
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    // MARK: - Types

    private enum ExtensionError: Error {
        case missingInputItems
        case invalidMessageType
        case missingAction
        case unknownAction(String)
        case invalidURL(String?)
        case dataFetchFailed(String, Error)
    }

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "dev.arjuna.WebShield.Advanced", category: "SafariWebExtensionHandler")

    // MARK: - Initializer

    override init() {
        super.init()
        SafariWebExtensionHandler.logger.log("SafariWebExtensionHandler initialized")
    }

    // MARK: - NSExtensionRequestHandling

    func beginRequest(with context: NSExtensionContext) {
        SafariWebExtensionHandler.logger.log("beginRequest(with:) called *********************")

        // Copy necessary data from NSExtensionContext to local variables
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any]

        do {
            try self.handleRequest(message: message, context: context)  // Pass NSExtensionContext here
        } catch let error as ExtensionError {
            self.handleError(error, context: context)
        } catch {
            SafariWebExtensionHandler.logger.error("Unexpected error: \(error, privacy: .public)")
            self.sendErrorResponse(to: context, message: "An unexpected error occurred")
        }
    }

    // MARK: - Request Handling

    private func handleRequest(message: [String: Any]?, context: NSExtensionContext) throws {
        guard let message = message else {
            throw ExtensionError.invalidMessageType
        }

        guard let action = message["action"] as? String else {
            throw ExtensionError.missingAction
        }

        switch action {
        case "getAdvancedBlockingData":
            try handleGetAdvancedBlockingData(message: message, context: context)
        default:
            throw ExtensionError.unknownAction(action)
        }
    }

    // MARK: - Get Advanced Blocking Data

    private func handleGetAdvancedBlockingData(message: [String: Any], context: NSExtensionContext) throws {
        SafariWebExtensionHandler.logger.log("Handling getAdvancedBlockingData")

        guard let urlString = message["url"] as? String, let pageUrl = URL(string: urlString) else {
            throw ExtensionError.invalidURL(message["url"] as? String)
        }

        SafariWebExtensionHandler.logger.log("Fetching data for URL: \(urlString)")

        let result = ContentBlockerEngineWrapper.shared.getData(for: pageUrl)
        switch result {
        case .success(let blockingData):
            SafariWebExtensionHandler.logger.log("Got blocking data: \(blockingData, privacy: .public)")
            let response: [String: Any] = [
                "url": urlString,
                "data": blockingData,
                "verbose": true,
            ]
            sendResponse(to: context, data: response)

        case .failure(let error):
            throw ExtensionError.dataFetchFailed(urlString, error)
        }
    }

    // MARK: - Response Handling

    private func sendResponse(to context: NSExtensionContext, data: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: data]

        SafariWebExtensionHandler.logger.log(
            "Sending final response: \(String(describing: response.userInfo), privacy: .public)")

        context.completeRequest(returningItems: [response]) { success in
            if success {
                SafariWebExtensionHandler.logger.log("Request completed successfully")
            } else {
                SafariWebExtensionHandler.logger.error("Error completing request")
            }
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: ExtensionError, context: NSExtensionContext) {
        switch error {
        case .missingInputItems:
            SafariWebExtensionHandler.logger.error("Invalid request: No input items found")
            sendErrorResponse(to: context, message: "Invalid request")
        case .invalidMessageType:
            SafariWebExtensionHandler.logger.error("Invalid message type")
            sendErrorResponse(to: context, message: "Invalid message")
        case .missingAction:
            SafariWebExtensionHandler.logger.error("Invalid or missing action in message")
            sendErrorResponse(to: context, message: "Invalid action")
        case .unknownAction(let action):
            SafariWebExtensionHandler.logger.error("Unknown action: \(action, privacy: .public)")
            sendErrorResponse(to: context, message: "Unknown action: \(action)")
        case .invalidURL(let urlString):
            SafariWebExtensionHandler.logger.error("Invalid URL in message: \(urlString ?? "nil", privacy: .public)")
            sendErrorResponse(to: context, message: "Invalid URL")
        case .dataFetchFailed(let urlString, let underlyingError):
            SafariWebExtensionHandler.logger.error(
                "Failed to fetch blocking data for URL: \(urlString), Error: \(underlyingError, privacy: .public)")
            sendErrorResponse(to: context, message: "Failed to fetch blocking data")
        }
    }

    private func sendErrorResponse(to context: NSExtensionContext, message: String) {
        let errorResponse: [String: Any] = ["error": message]
        sendResponse(to: context, data: errorResponse)
    }
}
