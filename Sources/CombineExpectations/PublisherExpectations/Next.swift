import XCTest

extension PublisherExpectations {
    /// A publisher expectation which waits for the recorded publisher to emit
    /// `count` elements, or to complete.
    ///
    /// When waiting for this expectation, a `RecordingError.notEnoughElements`
    /// is thrown if the publisher does not publish `count` elements after last
    /// waited expectation. The publisher error is thrown if the publisher fails
    /// before publishing the next `count` element.
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
    public struct Next<Input, Failure: Error>: PublisherExpectation {
        let recorder: Recorder<Input, Failure>
        let count: Int
        
        init(recorder: Recorder<Input, Failure>, count: Int) {
            precondition(count >= 0, "Can't take a prefix of negative length")
            self.recorder = recorder
            self.count = count
        }
        
        public func setup(_ expectation: XCTestExpectation) {
            if count == 0 {
                // Such an expectation is immediately fulfilled, by essence.
                expectation.expectedFulfillmentCount = 1
                expectation.fulfill()
            } else {
                expectation.expectedFulfillmentCount = count
                recorder.fulfillOnInput(expectation, includingConsumed: false)
            }
        }
        
        public func expectedValue() throws -> [Input] {
            try recorder.value { (_, completion, remainingElements, consume) in
                if remainingElements.count >= count {
                    consume(count)
                    return Array(remainingElements.prefix(count))
                }
                if case let .failure(error) = completion {
                    throw error
                } else {
                    throw RecordingError.notEnoughElements
                }
            }
        }
    }
}
