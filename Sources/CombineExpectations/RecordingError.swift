import Foundation

/// An error that may be thrown when waiting for publisher expectations.
public enum RecordingError: Error {
    /// The publisher did not complete.
    case notCompleted
    
    /// The publisher did not publish enough elements.
    /// For example, see `recorder.single`.
    case notEnoughElements(minimumExpected: Int)
    
    /// The publisher did publish too many elements.
    /// For example, see `recorder.single`.
    case tooManyElements(maximumExpected: Int)
}

extension RecordingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notCompleted:
            return "RecordingError.notCompleted"
        case let .notEnoughElements(minimumExpected):
            return "RecordingError.notEnoughElements(minimumExpected:\(minimumExpected))"
        case let .tooManyElements(maximumExpected):
            return "RecordingError.tooManyElements(maximumExpected:\(maximumExpected))"
        }
    }
}
