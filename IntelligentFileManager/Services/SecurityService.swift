import Foundation
import CryptoKit

class SecurityService {
    // MARK: - Key Generation

    func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    // MARK: - Encryption

    func encrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        return combined
    }

    // MARK: - Decryption

    func decrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// MARK: - Errors

enum SecurityError: LocalizedError {
    case encryptionFailed
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Encryption failed: could not produce combined data."
        case .decryptionFailed:
            return "Decryption failed: invalid or corrupted data."
        }
    }
}
