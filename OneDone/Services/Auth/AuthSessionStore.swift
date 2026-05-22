import Foundation

protocol AuthSessionStoreProtocol: AnyObject {
    var currentSession: StoredAuthSession? { get }
    var currentUserEmail: String? { get }
    func restoreSession() throws -> StoredAuthSession?
    func persistSession(_ session: StoredAuthSession) throws
    func clearSession() throws
}

final class AuthSessionStore: AuthSessionStoreProtocol {
    private static let account = "current-auth-session"
    private let keychain: KeychainStore
    private let lock = NSLock()
    private var inMemorySession: StoredAuthSession?

    init(keychain: KeychainStore = KeychainStore(service: "com.vivusco.onedone.auth")) {
        self.keychain = keychain
    }

    var currentSession: StoredAuthSession? {
        lock.lock()
        defer { lock.unlock() }
        return inMemorySession
    }

    var currentUserEmail: String? {
        currentSession?.userEmail
    }

    func restoreSession() throws -> StoredAuthSession? {
        guard let data = try keychain.get(account: Self.account) else {
            lock.lock()
            inMemorySession = nil
            lock.unlock()
            return nil
        }

        let decoded = try JSONDecoder().decode(StoredAuthSession.self, from: data)
        lock.lock()
        inMemorySession = decoded
        lock.unlock()
        return decoded
    }

    func persistSession(_ session: StoredAuthSession) throws {
        let encoded = try JSONEncoder().encode(session)
        try keychain.set(encoded, account: Self.account)
        lock.lock()
        inMemorySession = session
        lock.unlock()
    }

    func clearSession() throws {
        try keychain.delete(account: Self.account)
        lock.lock()
        inMemorySession = nil
        lock.unlock()
    }
}

final class InMemoryAuthSessionStore: AuthSessionStoreProtocol {
    private var session: StoredAuthSession?

    var currentSession: StoredAuthSession? {
        session
    }

    var currentUserEmail: String? {
        session?.userEmail
    }

    func restoreSession() throws -> StoredAuthSession? {
        session
    }

    func persistSession(_ session: StoredAuthSession) throws {
        self.session = session
    }

    func clearSession() throws {
        session = nil
    }
}

final class SessionAuthTokenProvider: AuthTokenProvider {
    private weak var sessionStore: AuthSessionStoreProtocol?

    init(sessionStore: AuthSessionStoreProtocol) {
        self.sessionStore = sessionStore
    }

    func accessToken() -> String? {
        sessionStore?.currentSession?.accessToken
    }
}
