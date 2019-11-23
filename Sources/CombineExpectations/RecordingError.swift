import Foundation

/// An error that may be thrown when waiting for publisher expectations.
public enum RecordingError: Error {
    /// Can be thrown when the publisher does not complete in time.
    case notCompleted
    
    /// Can be thrown when waiting for `recorder.single`, when the publisher
    /// does not publish any element.
    case noElements
    
    /// Can be thrown when waiting for `recorder.single`, when the publisher
    /// publishes more than one element.
    case moreThanOneElement
}

extension RecordingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notCompleted:
            return "RecordingError.notCompleted"
        case .noElements:
            return "RecordingError.noElements"
        case .moreThanOneElement:
            return "RecordingError.moreThanOneElement"
        }
    }
}
