import XCTest
import Combine
import CombineExpectations

/// Tests for sample code in documentation
class DocumentationTests: FailureTestCase {
    private struct MyError: Error { }
    
    // MARK: - Completion
    
    // SUCCESS: no error
    func testArrayPublisherSynchronouslyCompletesWithSuccess() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let completion = try recorder.completion.get()
        if case let .failure(error) = completion {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    // SUCCESS: no timeout, no error
    func testArrayPublisherCompletesWithSuccess() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let completion = try wait(for: recorder.completion, timeout: 0.1)
        if case let .failure(error) = completion {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notCompleted
    func testCompletionTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                _ = try wait(for: recorder.completion, timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notCompleted { }
        }
    }
    
    // MARK: - Elements
    
    func testArrayPublisherSynchronouslyPublishesArrayElements() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let elements = try recorder.elements.get()
        XCTAssertEqual(elements, ["foo", "bar", "baz"])
    }
    
    // SUCCESS: no timeout, no error
    func testArrayPublisherPublishesArrayElements() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let elements = try wait(for: recorder.elements, timeout: 0.1)
        XCTAssertEqual(elements, ["foo", "bar", "baz"])
    }

    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notCompleted
    func testElementsTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                _ = try wait(for: recorder.elements, timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notCompleted { }
        }
    }
    
    // FAIL: Caught error MyError
    func testElementsSynchronousError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send(completion: .failure(MyError()))
            _ = try recorder.elements.get()
            XCTFail("Expected error")
        } catch is MyError { }
    }

    // FAIL: Caught error MyError
    func testElementsError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send(completion: .failure(MyError()))
            _ = try wait(for: recorder.elements, timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // MARK: - Finished
    
    // SUCCESS: no error
    func testArrayPublisherSynchronouslyFinishesWithoutError() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        try recorder.finished.get()
    }
    
    // SUCCESS: no timeout, no error
    func testArrayPublisherFinishesWithoutError() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        try wait(for: recorder.finished, timeout: 0.1)
    }
    
    // FAIL: Asynchronous wait failed
    func testFinishedTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            try wait(for: recorder.finished, timeout: 0.1)
        }
    }
    
    // FAIL: Caught error MyError
    func testFinishedError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send(completion: .failure(MyError()))
            try wait(for: recorder.finished, timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // MARK: - Finished.inverted
    
    // SUCCESS: no timeout, no error
    func testPassthroughSubjectDoesNotFinish() throws {
        let publisher = PassthroughSubject<String, Never>()
        let recorder = publisher.record()
        try wait(for: recorder.finished.inverted, timeout: 0.1)
    }
    
    // FAIL: Fulfilled inverted expectation
    // FAIL: Caught error MyError
    func testInvertedFinishedError() throws {
        try assertFailure("Fulfilled inverted expectation") {
            do {
                let publisher = PassthroughSubject<String, MyError>()
                let recorder = publisher.record()
                publisher.send(completion: .failure(MyError()))
                try wait(for: recorder.finished.inverted, timeout: 0.1)
                XCTFail("Expected error")
            } catch is MyError { }
        }
    }
    
    // MARK: - Last
    
    // SUCCESS: no error
    func testArrayPublisherSynchronouslyPublishesLastElementLast() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        if let element = try recorder.last.get() {
            XCTAssertEqual(element, "baz")
        } else {
            XCTFail("Expected one element")
        }
    }
    
    // SUCCESS: no timeout, no error
    func testArrayPublisherPublishesLastElementLast() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        if let element = try wait(for: recorder.last, timeout: 0.1) {
            XCTAssertEqual(element, "baz")
        } else {
            XCTFail("Expected one element")
        }
    }
    
    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notCompleted
    func testLastTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                _ = try wait(for: recorder.last, timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notCompleted { }
        }
    }
    
    // FAIL: Caught error MyError
    func testLastError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send(completion: .failure(MyError()))
            _ = try wait(for: recorder.last, timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // MARK: - next()
    
    // SUCCESS: no error
    func testPassthroughSubjectSynchronouslyPublishesElements() throws {
        let publisher = PassthroughSubject<String, Never>()
        let recorder = publisher.record()
        
        publisher.send("foo")
        try XCTAssertEqual(recorder.next().get(), "foo")
        
        publisher.send("bar")
        try XCTAssertEqual(recorder.next().get(), "bar")
    }
    
    // SUCCESS: no error
    func testArrayOfTwoElementsSynchronouslyPublishesElementsInOrder() throws {
        let publisher = ["foo", "bar"].publisher
        let recorder = publisher.record()
    
        var element = try recorder.next().get()
        XCTAssertEqual(element, "foo")
    
        element = try recorder.next().get()
        XCTAssertEqual(element, "bar")
    }
    
    // SUCCESS: no timeout, no error
    func testArrayOfTwoElementsPublishesElementsInOrder() throws {
        let publisher = ["foo", "bar"].publisher
        let recorder = publisher.record()
        
        var element = try wait(for: recorder.next(), timeout: 0.1)
        XCTAssertEqual(element, "foo")
        
        element = try wait(for: recorder.next(), timeout: 0.1)
        XCTAssertEqual(element, "bar")
    }
    
    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notEnoughElements
    func testNextTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                _ = try wait(for: recorder.next(), timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notEnoughElements { }
        }
    }
    
    // FAIL: Caught error MyError
    func testNextError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send(completion: .failure(MyError()))
            _ = try wait(for: recorder.next(), timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // FAIL: Caught error RecordingError.notEnoughElements
    func testNextNotEnoughElementsError() throws {
        do {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send(completion: .finished)
            _ = try wait(for: recorder.next(), timeout: 0.1)
            XCTFail("Expected error")
        } catch RecordingError.notEnoughElements { }
    }
    
    // MARK: - next().inverted
    
    // SUCCESS: no timeout, no error
    func testPassthroughSubjectDoesNotPublishAnyElement() throws {
        let publisher = PassthroughSubject<String, Never>()
        let recorder = publisher.record()
        try wait(for: recorder.next().inverted, timeout: 0.1)
    }
    
    // FAIL: Fulfilled inverted expectation
    func testInvertedNextTooEarly() throws {
        try assertFailure("Fulfilled inverted expectation") {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send("foo")
            try wait(for: recorder.next().inverted, timeout: 0.1)
        }
    }
    
    // FAIL: Fulfilled inverted expectation
    // FAIL: Caught error MyError
    func testInvertedNextError() throws {
        try assertFailure("Fulfilled inverted expectation") {
            do {
                let publisher = PassthroughSubject<String, MyError>()
                let recorder = publisher.record()
                publisher.send(completion: .failure(MyError()))
                try wait(for: recorder.next().inverted, timeout: 0.1)
                XCTFail("Expected error")
            } catch is MyError { }
        }
    }
    
    // MARK: - next(count)
    
    // SUCCESS: no error
    func testArrayOfThreeElementsSynchronouslyPublishesTwoThenOneElement() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
    
        var elements = try recorder.next(2).get()
        XCTAssertEqual(elements, ["foo", "bar"])
    
        elements = try recorder.next(1).get()
        XCTAssertEqual(elements, ["baz"])
    }
    
    // SUCCESS: no timeout, no error
    func testArrayOfThreeElementsPublishesTwoThenOneElement() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        
        var elements = try wait(for: recorder.next(2), timeout: 0.1)
        XCTAssertEqual(elements, ["foo", "bar"])
        
        elements = try wait(for: recorder.next(1), timeout: 0.1)
        XCTAssertEqual(elements, ["baz"])
    }
    
    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notEnoughElements
    func testNextCountTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                publisher.send("foo")
                _ = try wait(for: recorder.next(2), timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notEnoughElements { }
        }
    }
    
    // FAIL: Caught error MyError
    func testNextCountError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send("foo")
            publisher.send(completion: .failure(MyError()))
            _ = try wait(for: recorder.next(2), timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // FAIL: Caught error RecordingError.notEnoughElements
    func testNextCountNotEnoughElementsError() throws {
        do {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send("foo")
            publisher.send(completion: .finished)
            _ = try wait(for: recorder.next(2), timeout: 0.1)
            XCTFail("Expected error")
        } catch RecordingError.notEnoughElements { }
    }
    
    // MARK: - Prefix
    
    // SUCCESS: no error
    func testArrayOfThreeElementsSynchronouslyPublishesTwoFirstElementsWithoutError() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let elements = try recorder.prefix(2).get()
        XCTAssertEqual(elements, ["foo", "bar"])
    }
    
    // SUCCESS: no timeout, no error
    func testArrayOfThreeElementsPublishesTwoFirstElementsWithoutError() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let elements = try wait(for: recorder.prefix(2), timeout: 0.1)
        XCTAssertEqual(elements, ["foo", "bar"])
    }
    
    // FAIL: Asynchronous wait failed
    func testPrefixTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send("foo")
            _ = try wait(for: recorder.prefix(2), timeout: 0.1)
        }
    }
    
    // FAIL: Caught error MyError
    func testPrefixError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send("foo")
            publisher.send(completion: .failure(MyError()))
            _ = try wait(for: recorder.prefix(2), timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // MARK: - Prefix.inverted
    
    // SUCCESS: no timeout, no error
    func testPassthroughSubjectPublishesNoMoreThanSentValues() throws {
        let publisher = PassthroughSubject<String, Never>()
        let recorder = publisher.record()
        publisher.send("foo")
        publisher.send("bar")
        let elements = try wait(for: recorder.prefix(3).inverted, timeout: 0.1)
        XCTAssertEqual(elements, ["foo", "bar"])
    }
    
    // FAIL: Fulfilled inverted expectation
    func testInvertedPrefixTooEarly() throws {
        try assertFailure("Fulfilled inverted expectation") {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send("foo")
            publisher.send("bar")
            publisher.send("baz")
            _ = try wait(for: recorder.prefix(3).inverted, timeout: 0.1)
        }
    }
    
    // FAIL: Fulfilled inverted expectation
    // FAIL: Caught error MyError
    func testInvertedPrefixError() throws {
        try assertFailure("Fulfilled inverted expectation") {
            do {
                let publisher = PassthroughSubject<String, MyError>()
                let recorder = publisher.record()
                publisher.send("foo")
                publisher.send(completion: .failure(MyError()))
                _ = try wait(for: recorder.prefix(3).inverted, timeout: 0.1)
                XCTFail("Expected error")
            } catch is MyError { }
        }
    }
    
    // MARK: - Recording
    
    // SUCCESS: no error
    func testArrayPublisherSynchronousRecording() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let recording = try recorder.recording.get()
        XCTAssertEqual(recording.output, ["foo", "bar", "baz"])
        if case let .failure(error) = recording.completion {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    // SUCCESS: no timeout, no error
    func testArrayPublisherRecording() throws {
        let publisher = ["foo", "bar", "baz"].publisher
        let recorder = publisher.record()
        let recording = try wait(for: recorder.recording, timeout: 0.1)
        XCTAssertEqual(recording.output, ["foo", "bar", "baz"])
        if case let .failure(error) = recording.completion {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notCompleted
    func testRecordingTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                _ = try wait(for: recorder.recording, timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notCompleted { }
        }
    }
    
    // MARK: - Single
    
    // SUCCESS: no error
    func testJustSynchronouslyPublishesExactlyOneElement() throws {
        let publisher = Just("foo")
        let recorder = publisher.record()
        let element = try recorder.single.get()
        XCTAssertEqual(element, "foo")
    }
    
    // SUCCESS: no timeout, no error
    func testJustPublishesExactlyOneElement() throws {
        let publisher = Just("foo")
        let recorder = publisher.record()
        let element = try wait(for: recorder.single, timeout: 0.1)
        XCTAssertEqual(element, "foo")
    }
    
    // FAIL: Asynchronous wait failed
    // FAIL: Caught error RecordingError.notCompleted
    func testSingleTimeout() throws {
        try assertFailure("Asynchronous wait failed") {
            do {
                let publisher = PassthroughSubject<String, Never>()
                let recorder = publisher.record()
                _ = try wait(for: recorder.single, timeout: 0.1)
                XCTFail("Expected error")
            } catch RecordingError.notCompleted { }
        }
    }
    
    // FAIL: Caught error MyError
    func testSingleError() throws {
        do {
            let publisher = PassthroughSubject<String, MyError>()
            let recorder = publisher.record()
            publisher.send(completion: .failure(MyError()))
            _ = try wait(for: recorder.single, timeout: 0.1)
            XCTFail("Expected error")
        } catch is MyError { }
    }
    
    // FAIL: Caught error RecordingError.tooManyElements
    func testSingleTooManyElementsError() throws {
        do {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send("foo")
            publisher.send("bar")
            publisher.send(completion: .finished)
            _ = try wait(for: recorder.single, timeout: 0.1)
            XCTFail("Expected error")
        } catch RecordingError.tooManyElements { }
    }
    
    // FAIL: Caught error RecordingError.notEnoughElements
    func testSingleNotEnoughElementsError() throws {
        do {
            let publisher = PassthroughSubject<String, Never>()
            let recorder = publisher.record()
            publisher.send(completion: .finished)
            _ = try wait(for: recorder.single, timeout: 0.1)
            XCTFail("Expected error")
        } catch RecordingError.notEnoughElements { }
    }
}
