import Combine
import XCTest

extension PublisherExpectations {
    /// A publisher expectation which waits for a publisher to
    /// complete successfully.
    ///
    /// When waiting for this expectation, an error is thrown if the publisher
    /// does not complete on time.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherRecording() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let recording = try wait(for: recorder.recording, timeout: 1)
    ///         XCTAssertEqual(recording.output, ["foo", "bar", "baz"])
    ///         if case let .failure(error) = recording.completion {
    ///             XCTFail("Unexpected error \(error)")
    ///         }
    ///     }
    public struct Recording<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func _setup(_ expectation: XCTestExpectation) {
            recorder.fulfillOnCompletion(expectation)
        }
        
        public func _value() throws -> Record<Input, Failure>.Recording {
            let (elements, completion) = recorder.elementsAndCompletion
            if let completion = completion {
                return Record<Input, Failure>.Recording(output: elements, completion: completion)
            } else {
                throw RecordingError.notCompleted
            }
        }
    }
}
