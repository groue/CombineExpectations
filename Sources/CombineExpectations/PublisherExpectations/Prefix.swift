import XCTest

extension PublisherExpectations {
    /// A publisher expectation which waits for a publisher to emit a certain
    /// number of elements, or to complete.
    ///
    /// The awaited array may contain less than `maxLength` elements, if the
    /// publisher completes early.
    ///
    /// When waiting for this expectation, an error is thrown if the publisher
    /// fails before `maxLength` elements are published.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoFirstElementsWithoutError() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try wait(for: recorder.prefix(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///     }
    public struct Prefix<Input, Failure: Error>: InvertablePublisherExpectation {
        let recorder: Recorder<Input, Failure>
        let maxLength: Int
        
        init(recorder: Recorder<Input, Failure>, maxLength: Int) {
            precondition(maxLength >= 0, "Can't take a prefix of negative length")
            self.recorder = recorder
            self.maxLength = maxLength
        }
        
        public func _setup(_ expectation: XCTestExpectation) {
            if maxLength == 0 {
                // Such an expectation is immediately fulfilled, by essence.
                expectation.expectedFulfillmentCount = 1
                expectation.fulfill()
            } else {
                expectation.expectedFulfillmentCount = maxLength
                recorder.fulfillOnInput(expectation)
            }
        }
        
        public func _value() throws -> [Input] {
            let (elements, completion) = recorder.elementsAndCompletion
            if elements.count >= maxLength {
                return Array(elements.prefix(maxLength))
            }
            if case let .failure(error) = completion {
                throw error
            }
            return elements
        }
    }
    
    public typealias First<Input, Failure: Error> = Map<Prefix<Input, Failure>, Input?>
}

extension Recorder {
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit a certain number of elements, or to complete.
    ///
    /// When waiting for this expectation, an error is thrown if the publisher
    /// fails before `maxLength` elements are published.
    ///
    /// Otherwise, an array of received elements is returned, containing at
    /// most `maxLength` elements, or less if the publisher completes early.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoFirstElementsWithoutError() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         let elements = try wait(for: recorder.prefix(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///     }
    ///
    /// This publisher expectation can be inverted:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectPublishesNoMoreThanSentValues() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         publisher.send("foo")
    ///         publisher.send("bar")
    ///         let elements = try wait(for: recorder.prefix(3).inverted, timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///     }
    ///
    /// - parameter maxLength: The maximum number of elements.
    public func prefix(_ maxLength: Int) -> PublisherExpectations.Prefix<Input, Failure> {
        PublisherExpectations.Prefix(recorder: self, maxLength: maxLength)
    }
    
    /// Returns a publisher expectation which waits for the recorded publisher
    /// to emit one element, or to complete.
    ///
    /// When waiting for this expectation, an error is thrown if the publisher
    /// fails before any element is published.
    ///
    /// Otherwise, the first published element is returned, unless the publisher
    /// completes before it publishes any element.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesItsFirstElementWithoutError() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///         if let element = try wait(for: recorder.first, timeout: 1) {
    ///             XCTAssertEqual(element, "foo")
    ///         } else {
    ///             XCTFail("Expected one element")
    ///         }
    ///     }
    ///
    /// This publisher expectation can be inverted:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotPublishAnyElement() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         _ = try wait(for: recorder.first.inverted, timeout: 1)
    ///     }
    public var first: PublisherExpectations.First<Input, Failure> {
        prefix(1).map { $0.first }
    }
}
