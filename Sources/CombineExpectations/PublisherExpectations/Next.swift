import XCTest

extension PublisherExpectations {
    public struct Next<Input, Failure: Error>: InvertablePublisherExpectation {
        let recorder: Recorder<Input, Failure>
        let count: Int
        
        init(recorder: Recorder<Input, Failure>, count: Int) {
            precondition(count >= 0, "Can't take a prefix of negative length")
            self.recorder = recorder
            self.count = count
        }
        
        public func _setup(_ expectation: XCTestExpectation) {
            if count == 0 {
                // Such an expectation is immediately fulfilled, by essence.
                expectation.expectedFulfillmentCount = 1
                expectation.fulfill()
            } else {
                expectation.expectedFulfillmentCount = count
                recorder.fulfillOnInput(expectation)
            }
        }
        
        public func _value() throws -> [Input] {
            try recorder.expectationValue { (_, completion, remaining, consume) in
                if remaining.count >= count {
                    consume(count)
                    return Array(remaining.prefix(count))
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
