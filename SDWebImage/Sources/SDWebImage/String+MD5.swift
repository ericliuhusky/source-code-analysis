import CryptoKit
import CommonCrypto

extension String {
    var md5: String {
        if #available(macOS 10.15, iOS 13.0, *) {
            guard let data = data(using: .utf8) else { return "" }
            let digest = Insecure.MD5.hash(data: data)
            return digest.reduce("") { $0 + String(format: "%02x", $1) }
        } else {
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(self, CC_LONG(strlen(self)), &digest)
            return digest.reduce("") { $0 + String(format: "%02x", $1) }
        }
    }
}
