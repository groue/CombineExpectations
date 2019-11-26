import Combine
import XCTest

extension PublisherExpectations {
    /// A publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time.
    ///
    /// Otherwise, a [Record.Recording](https://developer.apple.com/documentation/combine/record/recording)
    /// is returned.
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
            try recorder.expectationValue { (elements, completion, remaining, consume) in
                if let completion = completion {
                    consume(remaining.count)
                    return Record<Input, Failure>.Recording(output: elements, completion: completion)
                } else {
                    throw RecordingError.notCompleted
                }
            }
        }
    }
}
