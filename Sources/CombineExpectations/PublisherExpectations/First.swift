import XCTest

extension PublisherExpectations {
    /// A publisher expectation which waits for the recorded publisher to emit
    /// one element, or to complete.
    ///
    /// When waiting for this expectation, the publisher error is thrown if the
    /// publisher fails before publishing any element.
    ///
    /// Otherwise, the first published element is returned, or nil if the publisher
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
    ///         try wait(for: recorder.first.inverted, timeout: 1)
    ///     }
    public struct First<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func _setup(_ expectation: XCTestExpectation) {
            recorder.fulfillOnInput(expectation)
        }
        
        public func _value() throws -> Input? {
            try recorder.expectationValue { (elements, completion, remaining, consume) in
                if let first = elements.first {
                    let extraCount = max(1 + remaining.count - elements.count, 0)
                    consume(extraCount)
                    return first
                }
                if case let .failure(error) = completion {
                    throw error
                }
                return nil
            }
        }
        
        /// Returns an inverted publisher expectation which waits for a
        /// publisher to emit `maxLength` elements, or to complete.
        ///
        /// When waiting for this expectation, the publisher error is thrown
        /// if the publisher fails before `maxLength` elements are published.
        ///
        /// Otherwise, an array of received elements is returned, containing at
        /// most `maxLength` elements, or less if the publisher completes early.
        ///
        /// For example:
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
        public var inverted: Inverted<Self> {
            return Inverted(base: self)
        }
    }
    
    /// An inverted publisher expectation which waits for the recorded publisher
    /// to emit one element, or to complete.
    ///
    /// When waiting for this expectation, the publisher error is thrown if the
    /// publisher fails before publishing any element.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testPassthroughSubjectDoesNotPublishAnyElement() throws {
    ///         let publisher = PassthroughSubject<String, Never>()
    ///         let recorder = publisher.record()
    ///         try wait(for: recorder.first.inverted, timeout: 1)
    ///     }
    public struct FirstInverted<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func _setup(_ expectation: XCTestExpectation) {
            expectation.isInverted = true
            recorder.fulfillOnInput(expectation)
        }
        
        public func _value() throws {
            try recorder.expectationValue { (elements, completion, _, _) in
                if elements.first == nil, case let .failure(error) = completion {
                    throw error
                }
            }
        }
        
        /// :nodoc:
        public var inverted: First<Input, Failure> {
            return First(recorder: recorder)
        }
    }
}
