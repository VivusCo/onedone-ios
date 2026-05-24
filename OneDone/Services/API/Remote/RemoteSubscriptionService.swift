import Foundation
import StoreKit

struct RemoteSubscriptionService: SubscriptionServiceProtocol {
    let environment: APIEnvironment
    let tokenProvider: any AuthTokenProvider
    let urlSession: URLSession

    init(
        environment: APIEnvironment = .current,
        tokenProvider: any AuthTokenProvider = NoAuthTokenProvider(),
        urlSession: URLSession = .shared
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.urlSession = urlSession
    }

    func startSubscriptionPurchase() async throws -> SubscriptionPurchaseResult {
        guard let _ = environment.baseURL else {
            throw SubscriptionServiceError.missingFunctionsBaseURL
        }

        guard let productID = environment.subscriptionProductID, !productID.isEmpty else {
            throw SubscriptionServiceError.missingProductConfiguration
        }

        guard tokenProvider.accessToken() != nil else {
            throw SubscriptionServiceError.authenticationRequired
        }

        let product = try await loadSubscriptionProduct(productID: productID)

        do {
            let purchaseResult = try await product.purchase()

            switch purchaseResult {
            case let .success(verificationResult):
                let transaction = try verifiedTransaction(from: verificationResult)
                let request = validateRequest(from: transaction)
                let response = try await validateSubscription(request)
                await transaction.finish()
                return .purchased(response)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                throw SubscriptionServiceError.retryable(message: "Subscription flow is temporarily unavailable. Please try again.")
            }
        } catch let error as SubscriptionServiceError {
            throw error
        } catch {
            throw SubscriptionServiceError.retryable(message: "Could not start App Store purchase right now. Please try again.")
        }
    }

    func restorePurchases() async throws -> SubscriptionRestoreResult {
        guard let _ = environment.baseURL else {
            throw SubscriptionServiceError.missingFunctionsBaseURL
        }

        guard tokenProvider.accessToken() != nil else {
            throw SubscriptionServiceError.authenticationRequired
        }

        do {
            try await AppStore.sync()
        } catch {
            throw SubscriptionServiceError.retryable(message: "Could not restore purchases right now. Please try again.")
        }

        let entitlements = await collectVerifiedEntitlements()
        let entitlementPayloads = entitlements.map(restoreEntitlementPayload(from:))
        let request = RestorePurchasesRequest(
            entitlements: entitlementPayloads.isEmpty ? nil : entitlementPayloads
        )

        let response = try await syncRestoredPurchases(request)
        return SubscriptionRestoreResult(
            response: response,
            restoredEntitlementCount: entitlements.count
        )
    }

    private func validateSubscription(_ request: ValidateSubscriptionRequest) async throws -> ValidateSubscriptionResponse {
        let data = try await postSubscriptionEndpoint(
            endpoint: "validate-subscription",
            body: request
        )

        if let decoded = decodeSingleWrapper(data, as: ValidateSubscriptionResponse.self) {
            return decoded
        }

        if let accessStateDTO = decodeSingleWrapper(data, as: GetAccessStateDTO.self) {
            return ValidateSubscriptionResponse(access: accessStateDTO.access)
        }

        throw SubscriptionServiceError.invalidResponse
    }

    private func syncRestoredPurchases(_ request: RestorePurchasesRequest) async throws -> RestorePurchasesResponse {
        let data = try await postSubscriptionEndpoint(
            endpoint: "restore-purchases",
            body: request
        )

        if let decoded = decodeSingleWrapper(data, as: RestorePurchasesResponse.self) {
            return decoded
        }

        if let accessStateDTO = decodeSingleWrapper(data, as: GetAccessStateDTO.self) {
            return RestorePurchasesResponse(access: accessStateDTO.access)
        }

        throw SubscriptionServiceError.invalidResponse
    }

    private func loadSubscriptionProduct(productID: String) async throws -> Product {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw SubscriptionServiceError.productUnavailable
        }
        return product
    }

    private func verifiedTransaction(
        from verificationResult: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch verificationResult {
        case let .verified(transaction):
            return transaction
        case .unverified:
            throw SubscriptionServiceError.unverifiedTransaction
        }
    }

    private func validateRequest(from transaction: Transaction) -> ValidateSubscriptionRequest {
        ValidateSubscriptionRequest(
            transactionID: String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            productID: transaction.productID,
            verificationMode: "ios_verified_mirror",
            purchasedAtISO8601: ISO8601DateFormatter().string(from: transaction.purchaseDate),
            expiresAtISO8601: transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) },
            ownershipType: transaction.ownershipType.rawValue,
            revocationDateISO8601: transaction.revocationDate.map { ISO8601DateFormatter().string(from: $0) },
            entitlementStatus: entitlementStatus(from: transaction),
            storeKitStatus: entitlementStatus(from: transaction),
            source: "app_store",
            platform: "ios",
            environment: environmentLabel(from: transaction),
            storefront: nil
        )
    }

    private func restoreEntitlementPayload(from transaction: Transaction) -> RestorePurchaseEntitlement {
        RestorePurchaseEntitlement(
            transactionID: String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            productID: transaction.productID,
            verificationMode: "ios_verified_mirror",
            purchasedAtISO8601: ISO8601DateFormatter().string(from: transaction.purchaseDate),
            expiresAtISO8601: transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) },
            ownershipType: transaction.ownershipType.rawValue,
            revocationDateISO8601: transaction.revocationDate.map { ISO8601DateFormatter().string(from: $0) },
            entitlementStatus: entitlementStatus(from: transaction),
            storeKitStatus: entitlementStatus(from: transaction),
            source: "app_store",
            platform: "ios",
            environment: environmentLabel(from: transaction),
            storefront: nil
        )
    }

    private func collectVerifiedEntitlements() async -> [Transaction] {
        var transactions: [Transaction] = []

        for await entitlement in Transaction.currentEntitlements {
            switch entitlement {
            case let .verified(transaction):
                transactions.append(transaction)
            case .unverified:
                continue
            }
        }

        return transactions
    }

    private func postSubscriptionEndpoint<T: Encodable>(
        endpoint: String,
        body: T
    ) async throws -> Data {
        guard let url = edgeFunctionURL(endpoint: endpoint) else {
            throw SubscriptionServiceError.missingFunctionsBaseURL
        }

        guard let accessToken = tokenProvider.accessToken(), !accessToken.isEmpty else {
            throw SubscriptionServiceError.authenticationRequired
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SubscriptionServiceError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw SubscriptionServiceError.authenticationRequired
            }

            if httpResponse.statusCode == 404 {
                throw SubscriptionServiceError.retryable(
                    message: "Subscription backend is unavailable. Please deploy '\(endpoint)' and try again."
                )
            }

            if httpResponse.statusCode == 408 || httpResponse.statusCode == 409 || httpResponse.statusCode == 425 ||
                httpResponse.statusCode == 429 || httpResponse.statusCode >= 500 {
                let backendError = decodeBackendError(data)
                logSubscriptionHTTPFailure(
                    endpoint: endpoint,
                    statusCode: httpResponse.statusCode,
                    backendError: backendError,
                    data: data
                )
                let message = sanitizeBackendMessage(backendError?.message) ?? "Subscription request failed. Please try again."
                throw SubscriptionServiceError.retryable(message: message)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let backendError = decodeBackendError(data)
                logSubscriptionHTTPFailure(
                    endpoint: endpoint,
                    statusCode: httpResponse.statusCode,
                    backendError: backendError,
                    data: data
                )
                let message = sanitizeBackendMessage(backendError?.message) ?? "Subscription request failed. Please try again."
                if endpoint == "validate-subscription" {
                    throw SubscriptionServiceError.backendValidationFailed(message: message)
                } else {
                    throw SubscriptionServiceError.backendRestoreFailed(message: message)
                }
            }

            return data
        } catch let error as SubscriptionServiceError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw SubscriptionServiceError.retryable(message: "You appear to be offline. Connect to the internet and retry.")
            case .timedOut:
                throw SubscriptionServiceError.retryable(message: "Subscription request timed out. Please try again.")
            default:
                throw SubscriptionServiceError.retryable(message: "Network issue while syncing subscription state.")
            }
        } catch {
            throw SubscriptionServiceError.retryable(message: "Subscription request failed. Please try again.")
        }
    }

    private func sanitizeBackendMessage(_ message: String?) -> String? {
        guard let message else { return nil }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.lowercased()
        if normalized.contains("unauthorized") || normalized.contains("session") || normalized.contains("token") {
            return "Your session expired. Please log in again."
        }

        if normalized.contains("rate limit") || normalized.contains("too many requests") {
            return "Too many requests right now. Please try again in a moment."
        }

        if normalized.contains("product") && normalized.contains("missing") {
            return "Subscription product details were incomplete. Please try again."
        }

        if normalized.contains("transaction") && normalized.contains("missing") {
            return "Subscription transaction details were incomplete. Please try again."
        }

        if normalized.contains("not found") {
            return "Subscription backend is unavailable. Please try again later."
        }

        if normalized.contains("validation") || normalized.contains("invalid") {
            return "Subscription details were not accepted. Please retry."
        }

        return "Subscription request failed. Please try again."
    }

    private func decodeSingleWrapper<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
        if let direct = try? JSONDecoder().decode(T.self, from: data) {
            return direct
        }

        if let wrapped = try? JSONDecoder().decode(RemoteSubscriptionResponseWrapper<T>.self, from: data) {
            return wrapped.data ?? wrapped.result ?? wrapped.response ?? wrapped.payload
        }

        return nil
    }

    private func environmentLabel(from transaction: Transaction) -> String {
        String(describing: transaction.environment).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func edgeFunctionURL(endpoint: String) -> URL? {
        guard let baseURL = environment.baseURL else { return nil }

        let basePath = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let functionBaseURL: URL
        if basePath.hasSuffix("functions/v1") {
            functionBaseURL = baseURL
        } else {
            functionBaseURL = baseURL
                .appendingPathComponent("functions")
                .appendingPathComponent("v1")
        }

        var cleanedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleanedEndpoint.hasPrefix("/") {
            cleanedEndpoint.removeFirst()
        }
        if cleanedEndpoint.lowercased().hasPrefix("functions/v1/") {
            cleanedEndpoint.removeFirst("functions/v1/".count)
        }

        return functionBaseURL.appendingPathComponent(cleanedEndpoint)
    }

    private func entitlementStatus(from transaction: Transaction) -> String {
        if transaction.revocationDate != nil {
            return "revoked"
        }

        if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            return "expired"
        }

        return "active"
    }

    private func logSubscriptionHTTPFailure(
        endpoint: String,
        statusCode: Int,
        backendError: ParsedBackendError?,
        data: Data
    ) {
#if DEBUG
        let keys = topLevelJSONKeys(from: data)
        let keysDescription = keys.isEmpty ? "none" : keys.joined(separator: ",")
        let codeValue = backendError?.code ?? "none"
        let messageValue = backendError?.message ?? "none"
        print("[OneDone][Subscription] endpoint=\(endpoint) status=\(statusCode) code=\(codeValue) message=\(messageValue) keys=\(keysDescription)")
#endif
    }

    private func topLevelJSONKeys(from data: Data) -> [String] {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return []
        }

        return dictionary.keys.sorted()
    }

    private func decodeBackendError(_ data: Data) -> ParsedBackendError? {
        if let payload = try? JSONDecoder().decode(StructuredBackendErrorPayload.self, from: data) {
            let code = payload.error?.code ?? payload.code ?? payload.status
            let message = payload.error?.message ?? payload.errorMessage ?? payload.message ?? payload.detail
            if code != nil || message != nil {
                return ParsedBackendError(code: code, message: message)
            }
        }

        if let object = try? JSONSerialization.jsonObject(with: data),
           let dictionary = object as? [String: Any] {
            let code = (dictionary["code"] as? String) ?? (dictionary["status"] as? String)
            let message =
                (dictionary["message"] as? String) ??
                (dictionary["error_message"] as? String) ??
                (dictionary["detail"] as? String)
            if code != nil || message != nil {
                return ParsedBackendError(code: code, message: message)
            }
        }

        return nil
    }
}

private struct RemoteSubscriptionResponseWrapper<T: Decodable>: Decodable {
    let data: T?
    let result: T?
    let response: T?
    let payload: T?
}

private struct ParsedBackendError {
    let code: String?
    let message: String?
}

private struct StructuredBackendErrorPayload: Decodable {
    struct NestedError: Decodable {
        let code: String?
        let message: String?
    }

    let ok: Bool?
    let error: NestedError?
    let code: String?
    let status: String?
    let message: String?
    let detail: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case error
        case code
        case status
        case message
        case detail
        case errorMessage = "error_message"
    }
}
