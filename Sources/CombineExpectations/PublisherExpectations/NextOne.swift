import XCTest

extension PublisherExpectations {
    /// A publisher expectation which waits for the recorded publisher to emit
    /// `count` elements, or to complete.
    ///
    /// When waiting for this expectation, a RecordingError is thrown if the
    /// publisher does not publish `count` elements after last waited
    /// expectation. The publisher error is thrown if the publisher fails before
    /// publishing `count` elements.
    ///
    /// Otherwise, an array of exactly `count` element is returned.
    ///
    /// For example:
    ///
    ///     // SUCCESS: no timeout, no error
    ///     func testArrayOfThreeElementsPublishesTwoThenOneElement() throws {
    ///         let publisher = ["foo", "bar", "baz"].publisher
    ///         let recorder = publisher.record()
    ///
    ///         var elements = try wait(for: recorder.next(2), timeout: 1)
    ///         XCTAssertEqual(elements, ["foo", "bar"])
    ///
    ///         elements = try wait(for: recorder.next(1), timeout: 1)
    ///         XCTAssertEqual(elements, ["baz"])
    ///     }
    public struct NextOne<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func setup(_ expectation: XCTestExpectation) {
            recorder.fulfillOnInput(expectation, includingConsumed: false)
        }
        
        public func expectedValue() throws -> Input? {
            try recorder.expectationValue { (_, completion, remaining, consume) in
                if let next = remaining.first {
                    consume(1)
                    return next
                }
                if case let .failure(error) = completion {
                    throw error
                } else {
                    throw RecordingError.notEnoughElements
                }
            }
        }
        
        /// TODO
        public var inverted: NextOneInverted<Input, Failure> {
            return NextOneInverted(recorder: recorder)
        }
    }
    
    public struct NextOneInverted<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        
        public func setup(_ expectation: XCTestExpectation) {
            expectation.isInverted = true
            recorder.fulfillOnInput(expectation, includingConsumed: false)
        }
        
        public func expectedValue() throws {
            try recorder.expectationValue { (_, completion, remaining, consume) in
                if remaining.isEmpty == false {
                    return
                }
                if case let .failure(error) = completion {
                    throw error
                }
            }
        }
        
        /// :nodoc:
        public var inverted: NextOne<Input, Failure> {
            return NextOne(recorder: recorder)
        }
    }
}
