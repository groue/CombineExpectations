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
            try recorder.expectationValue { (elements, completion, remaining, consume) in
                if elements.count >= maxLength {
                    let result = Array(elements.prefix(maxLength))
                    let extraCount = max(maxLength + remaining.count - elements.count, 0)
                    consume(extraCount)
                    return result
                }
                if case let .failure(error) = completion {
                    throw error
                }
                consume(remaining.count)
                return elements
            }
        }
    }
}
