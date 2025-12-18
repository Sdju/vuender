import Foundation
enum AppVersion {
    static let version = "0.1.0"
    static let build = "1"
    static var fullVersion: String {
        return "\(version) (build \(build))"
    }
}

