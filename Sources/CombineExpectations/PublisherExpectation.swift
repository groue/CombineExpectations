import XCTest

/// A name space for publisher expectations
public enum PublisherExpectations { }

/// The protocol for publisher expectations.
///
/// You can build publisher expectations from Recorder returned by the
/// `Publisher.record()` method. For example:
///
///     // SUCCESS: no timeout, no error
///     func testArrayPublisherPublishesArrayElements() throws {
///         let publisher = ["foo", "bar", "baz"].publisher
///         let recorder = publisher.record()
///         let expectation = recorder.elements
///         let elements = try wait(for: expectation, timeout: 1)
///         XCTAssertEqual(elements, ["foo", "bar", "baz"])
///     }
public protocol PublisherExpectation {
    associatedtype Output
    
    /// :nodoc:
    func setup(_ expectation: XCTestExpectation)
    
    /// :nodoc:
    func expectedValue() throws -> Output
}

extension XCTestCase {
    /// Waits for the publisher expectation to fulfill, and returns the
    /// expected value.
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
    ///
    /// - parameter publisherExpectation: The publisher expectation.
    /// - parameter timeout: The number of seconds within which the expectation
    ///   must be fulfilled.
    /// - parameter description: A string to display in the test log for the
    ///   expectation, to help diagnose failures.
    /// - throws: An error if the expectation fails.
    public func wait<R: PublisherExpectation>(
        for publisherExpectation: R,
        timeout: TimeInterval = 1.0,
        description: String = "")
        throws -> R.Output
    {
        let expectation = self.expectation(description: description)
        publisherExpectation.setup(expectation)
        wait(for: [expectation], timeout: timeout)
        return try publisherExpectation.expectedValue()
    }
}
