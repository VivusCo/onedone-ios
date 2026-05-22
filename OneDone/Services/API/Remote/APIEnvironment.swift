import Foundation

struct APIEnvironment {
    static let functionsBaseURLKey = "ONEDONE_FUNCTIONS_BASE_URL"
    static let legacyBaseURLKey = "ONEDONE_API_BASE_URL"
    static let supabaseURLKey = "ONEDONE_SUPABASE_URL"
    // Supabase anon key is public by design and allowed in client apps.
    // Never place Supabase service_role keys in iOS code or client config.
    static let supabaseAnonKeyKey = "ONEDONE_SUPABASE_ANON_KEY"
    static let useMockRuntimeKey = "ONEDONE_USE_MOCK_RUNTIME"
    static let useRemoteAccessStateKey = "ONEDONE_USE_REMOTE_ACCESS_STATE"
    static let useRemoteTaskAnalysisKey = "ONEDONE_USE_REMOTE_TASK_ANALYSIS"
    static let useRemoteTaskActionsKey = "ONEDONE_USE_REMOTE_TASK_ACTIONS"
    static let useRemoteReminderSyncKey = "ONEDONE_USE_REMOTE_REMINDER_SYNC"
    static let placeholderBaseURL = "https://your-backend.example.com"

    let baseURL: URL?
    let supabaseURL: URL?
    let supabaseAnonKey: String?
    let forceMockRuntime: Bool
    let useRemoteAccessState: Bool
    let useRemoteTaskAnalysis: Bool
    let useRemoteTaskActions: Bool
    let useRemoteReminderSync: Bool

    static let current = APIEnvironment(
        functionsBaseURLString:
            environmentValue(for: functionsBaseURLKey) ??
            bundleValue(for: functionsBaseURLKey) ??
            environmentValue(for: legacyBaseURLKey) ??
            bundleValue(for: legacyBaseURLKey),
        supabaseURLString: environmentValue(for: supabaseURLKey) ?? bundleValue(for: supabaseURLKey),
        supabaseAnonKeyValue: environmentValue(for: supabaseAnonKeyKey) ?? bundleValue(for: supabaseAnonKeyKey),
        forceMockRuntimeValue: environmentValue(for: useMockRuntimeKey) ?? bundleValue(for: useMockRuntimeKey),
        useRemoteAccessStateValue: environmentValue(for: useRemoteAccessStateKey) ?? bundleValue(for: useRemoteAccessStateKey),
        useRemoteTaskAnalysisValue: environmentValue(for: useRemoteTaskAnalysisKey) ?? bundleValue(for: useRemoteTaskAnalysisKey),
        useRemoteTaskActionsValue: environmentValue(for: useRemoteTaskActionsKey) ?? bundleValue(for: useRemoteTaskActionsKey),
        useRemoteReminderSyncValue: environmentValue(for: useRemoteReminderSyncKey) ?? bundleValue(for: useRemoteReminderSyncKey)
    )

    init(
        functionsBaseURLString: String?,
        supabaseURLString: String?,
        supabaseAnonKeyValue: String?,
        forceMockRuntimeValue: String?,
        useRemoteAccessStateValue: String?,
        useRemoteTaskAnalysisValue: String?,
        useRemoteTaskActionsValue: String?,
        useRemoteReminderSyncValue: String?
    ) {
        if let functionsBaseURLString, !functionsBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseURL = URL(string: functionsBaseURLString)
        } else {
            baseURL = nil
        }

        if let supabaseURLString, !supabaseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            supabaseURL = URL(string: supabaseURLString)
        } else {
            supabaseURL = nil
        }

        if let supabaseAnonKeyValue {
            let trimmed = supabaseAnonKeyValue.trimmingCharacters(in: .whitespacesAndNewlines)
            supabaseAnonKey = trimmed.isEmpty ? nil : trimmed
        } else {
            supabaseAnonKey = nil
        }

        forceMockRuntime = APIEnvironment.parseBool(forceMockRuntimeValue) ?? false
        let defaultRemoteEnabled = !forceMockRuntime
        useRemoteAccessState = APIEnvironment.parseBool(useRemoteAccessStateValue) ?? defaultRemoteEnabled
        useRemoteTaskAnalysis = APIEnvironment.parseBool(useRemoteTaskAnalysisValue) ?? useRemoteAccessState
        useRemoteTaskActions = APIEnvironment.parseBool(useRemoteTaskActionsValue) ?? useRemoteTaskAnalysis
        useRemoteReminderSync = APIEnvironment.parseBool(useRemoteReminderSyncValue) ?? useRemoteTaskActions
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
