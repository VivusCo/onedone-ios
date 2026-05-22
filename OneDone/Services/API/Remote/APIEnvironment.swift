import Foundation

struct APIEnvironment {
    static let baseURLKey = "ONEDONE_API_BASE_URL"
    static let useRemoteAccessStateKey = "ONEDONE_USE_REMOTE_ACCESS_STATE"
    static let placeholderBaseURL = "https://your-backend.example.com"

    let baseURL: URL?
    let useRemoteAccessState: Bool

    static let current = APIEnvironment(
        baseURLString: environmentValue(for: baseURLKey) ?? bundleValue(for: baseURLKey),
        useRemoteAccessStateValue: environmentValue(for: useRemoteAccessStateKey) ?? bundleValue(for: useRemoteAccessStateKey)
    )

    init(baseURLString: String?, useRemoteAccessStateValue: String?) {
        if let baseURLString, !baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseURL = URL(string: baseURLString)
        } else {
            baseURL = nil
        }

        useRemoteAccessState = APIEnvironment.parseBool(useRemoteAccessStateValue) ?? false
    }

    private static func parseBool(_ value: String?) -> Bool? {
        guard let value else { return nil }

        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "y", "on":
            return true
        case "0", "false", "no", "n", "off":
            return false
        default:
            return nil
        }
    }

    private static func environmentValue(for key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

    private static func bundleValue(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
