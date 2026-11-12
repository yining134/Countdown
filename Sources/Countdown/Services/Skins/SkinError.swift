import Foundation

struct SkinError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
