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
    
    public typealias Completion<Input, Failure: Error> = Map<Recording<Input, Failure>, Subscribers.Completion<Failure>>
    public typealias Elements<Input, Failure: Error> = Map<Recording<Input, Failure>, [Input]>
    public typealias Last<Input, Failure: Error> = Map<Elements<Input, Failure>, Input?>
    public typealias Single<Input, Failure: Error> = Map<Elements<Input, Failure>, Input>
}

extension Recorder {
    /// Returns a publisher expectation which waits for the recorded publisher
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
    public var recording: PublisherExpectations.Recording<Input, Failure> {
        PublisherExpectations.Recording(recorder: self)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time.
    ///
    /// Otherwise, a [Subscribers.Completion](https://developer.apple.com/documentation/combine/subscribers/completion)
    /// is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherCompletesWithSuccess() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let completion = try wait(for: recorder.completion, timeout: 1)
    ///         if case let .failure(error) = completion {
    ///             XCTFail("Unexpected error \(error)")
    ///         }
    ///     }
    public var completion: PublisherExpectations.Completion<Input, Failure> {
        recording.map { $0.completion }
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time, and the publisher
    /// error is thrown if the publisher fails.
    ///
    /// Otherwise, an array of published elements is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherPublishesArrayElements() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try wait(for: recorder.elements, timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
    ///     }
    public var elements: PublisherExpectations.Elements<Input, Failure> {
        recording.map { recording in
            if case let .failure(error) = recording.completion {
                throw error
            }
            return recording.output
        }
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to publish its last element and complete.
    ///
    /// When waiting for this expectation, a RecordingError.notCompleted is
    /// thrown if the publisher does not complete on time, and the publisher
    /// error is thrown if the publisher fails.
    ///
    /// Otherwise, the last published element is returned, unless the publisher
    /// completes before it publishes any element.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayPublisherPublishesLastElementLast() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         if let element = try wait(for: recorder.last, timeout: 1) {
    ///             XCTAssertEqual(element, "baz")
    ///         } else {
    ///             XCTFail("Expected one element")
    ///         }
    ///     }
    public var last: PublisherExpectations.Last<Input, Failure> {
        elements.map { $0.last }
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to publish exactly one element and complete.
    ///
    /// When waiting for this expectation, a RecordingError is thrown if the
    /// publisher does not complete on time, or does not publish exactly one
    /// element before it completes. The publisher error is thrown if the
    /// publisher fails.
    ///
    /// Otherwise, the single published element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testJustPublishesExactlyOneElement() throws {
    ///         let publisher = Just("foo")
    ///         let recorder = publisher.record()
    ///         let element = try wait(for: recorder.single, timeout: 1)
    ///         XCTAssertEqual(element, "foo")
    ///     }
    public var single: PublisherExpectations.Single<Input, Failure> {
        elements.map { elements in
            guard let element = elements.first else {
                throw RecordingError.noElements
            }
            if elements.count > 1 {
                throw RecordingError.moreThanOneElement
            }
            return element
        }
    }
}
