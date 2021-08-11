# Combine Expectations

### Utilities for tests that wait for Combine publishers.

---

**Latest release**: [version 0.10.0](https://github.com/groue/CombineExpectations/tree/v0.10.0) (August 11, 2021) • [Release Notes]

**Requirements**: iOS 13+, macOS 10.15+, and tvOS 13+ require Swift 5.1+ or Xcode 11+. watchOS 7.4+ requires Swift 5.4+ or Xcode 12.5+.

**Contact**: Report bugs and ask questions in [Github issues](https://github.com/groue/CombineExpectations/issues).

---

Testing Combine publishers with [XCTestExpectation](*https://developer.apple.com/documentation/xctest/xctestexpectation*) often requires setting up a lot of boilerplate code.

CombineExpectations aims at streamlining those tests. It defines an XCTestCase method which waits for *publisher expectations*.

- [Usage]
- [Installation]
- [Publisher Expectations]: [availableElements], [completion], [elements], [finished], [last], [next()], [next(count)], [prefix(maxLength)], [recording], [single]

---

## Usage

Waiting for [Publisher Expectations] allows your tests to look like this:

```swift
import XCTest
import CombineExpectations

class PublisherTests: XCTestCase {
    func testElements() throws {
        // 1. Create a publisher
        let publisher = ...
        
        // 2. Start recording the publisher
        let recorder = publisher.record()
        
        // 3. Wait for a publisher expectation
        let elements = try wait(for: recorder.elements, timeout: ..., description: "Elements")
        
        // 4. Test the result of the expectation
        XCTAssertEqual(elements, ["Hello", "World!"])
    }
}
```

**When you wait for a publisher expectation:**

- The test fails if the expectation is not fulfilled within the specified timeout.
- An error is thrown if the expected value can not be returned. For example, waiting for `recorder.elements` throws the publisher error if the publisher completes with a failure.
- The `wait` method returns immediately if the expectation has already reached the waited state.

You can wait multiple times for a publisher:

```swift
class PublisherTests: XCTestCase {
    func testPublisher() throws {
        let publisher = ...
        let recorder = publisher.record()
        
        // Wait for first element
        _ = try wait(for: recorder.next(), timeout: ...)
        
        // Wait for second element
        _ = try wait(for: recorder.next(), timeout: ...)
        
        // Wait for successful completion
        try wait(for: recorder.finished, timeout: ...)
    }
}
```

**Not all tests have to wait**, because some publishers expectations are fulfilled right away. In this case, prefer the synchronous `get()` method over `wait(for:timeout:)`, as below:

```swift
class PublisherTests: XCTestCase {
    func testSynchronousPublisher() throws {
        // 1. Create a publisher
        let publisher = ...
        
        // 2. Start recording the publisher
        let recorder = publisher.record()
        
        // 3. Grab the expected result
        let elements = try recorder.elements.get()
        
        // 4. Test the result of the expectation
        XCTAssertEqual(elements, ["Hello", "World!"])
    }
}
```

Just like `wait(for:timeout:)`, the `get()` method can be called multiple times:

```swift
class PublisherTests: XCTestCase {
    // SUCCESS: no error
    func testPassthroughSubjectSynchronouslyPublishesElements() throws {
        let publisher = PassthroughSubject<String, Never>()
        let recorder = publisher.record()
        
        publisher.send("foo")
        try XCTAssertEqual(recorder.next().get(), "foo")
        
        publisher.send("bar")
        try XCTAssertEqual(recorder.next().get(), "bar")
    }
}
```


## Installation

Add a dependency for CombineExpectations to your [Swift Package](https://swift.org/package-manager/) test targets:

```diff
 import PackageDescription
 
 let package = Package(
     dependencies: [
+        .package(url: "https://github.com/groue/CombineExpectations.git", ...)
     ],
     targets: [
         .testTarget(
             dependencies: [
+                "CombineExpectations"
             ])
     ]
 )
```


## Publisher Expectations

There are various publisher expectations. Each one waits for a specific publisher aspect:

- [availableElements]: all published elements until timeout expiration
- [completion]: the publisher completion
- [elements]: all published elements until successful completion
- [finished]: the publisher successful completion
- [last]: the last published element
- [next()]: the next published element
- [next(count)]: the next N published elements
- [prefix(maxLength)]: the first N published elements
- [recording]: the full recording of publisher events
- [single]: the one and only published element

---

### availableElements

:clock230: `recorder.availableElements` waits for the expectation to expire, or the recorded publisher to complete.

:x: When waiting for this expectation, the publisher error is thrown if the publisher fails before the expectation has expired.

:white_check_mark: Otherwise, an array of all elements published before the expectation has expired is returned.

:arrow_right: Related expectations: [elements], [prefix(maxLength)].

Unlike other expectations, `availableElements` does not make a test fail on timeout expiration. It just returns the elements published so far.

Example:

```swift
// SUCCESS: no timeout, no error
func testTimerPublishesIncreasingDates() throws {
    let publisher = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    let recorder = publisher.record()
    let dates = try wait(for: recorder.availableElements, timeout: ...)
    XCTAssertEqual(dates.sorted(), dates)
}
```

### completion

:clock230: `recorder.completion` waits for the recorded publisher to complete.

:x: When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time.

:white_check_mark: Otherwise, a [`Subscribers.Completion`](https://developer.apple.com/documentation/combine/subscribers/completion) is returned.

:arrow_right: Related expectations: [finished], [recording].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherCompletesWithSuccess() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let completion = try wait(for: recorder.completion, timeout: ...)
    if case let .failure(error) = completion {
        XCTFail("Unexpected error \(error)")
    }
}

// SUCCESS: no error
func testArrayPublisherSynchronouslyCompletesWithSuccess() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let completion = try recorder.completion.get()
    if case let .failure(error) = completion {
        XCTFail("Unexpected error \(error)")
    }
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notCompleted
func testCompletionTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let completion = try wait(for: recorder.completion, timeout: ...)
}
```

</details>


---

### elements

:clock230: `recorder.elements` waits for the recorded publisher to complete.

:x: When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time, and the publisher error is thrown if the publisher fails.

:white_check_mark: Otherwise, an array of published elements is returned.

:arrow_right: Related expectations: [availableElements], [last], [prefix(maxLength)], [recording], [single].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherPublishesArrayElements() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let elements = try wait(for: recorder.elements, timeout: ...)
    XCTAssertEqual(elements, ["foo", "bar", "baz"])
}

// SUCCESS: no error
func testArrayPublisherSynchronouslyPublishesArrayElements() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let elements = try recorder.elements.get()
    XCTAssertEqual(elements, ["foo", "bar", "baz"])
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notCompleted
func testElementsTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let elements = try wait(for: recorder.elements, timeout: ...)
}

// FAIL: Caught error MyError
func testElementsError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.elements, timeout: ...)
}
```

</details>


---

### finished

:clock230: `recorder.finished` waits for the recorded publisher to complete.

:x: When waiting for this expectation, the publisher error is thrown if the publisher fails.

:arrow_right: Related expectations: [completion], [recording].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherFinishesWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    try wait(for: recorder.finished, timeout: ...)
}

// SUCCESS: no error
func testArrayPublisherSynchronouslyFinishesWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    try recorder.finished.get()
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
func testFinishedTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    try wait(for: recorder.finished, timeout: ...)
}

// FAIL: Caught error MyError
func testFinishedError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    try wait(for: recorder.finished, timeout: ...)
}
```

</details>

`recorder.finished` can be inverted:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectDoesNotFinish() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    try wait(for: recorder.finished.inverted, timeout: ...)
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Fulfilled inverted expectation
// FAIL: Caught error MyError
func testInvertedFinishedError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    try wait(for: recorder.finished.inverted, timeout: ...)
}
```

</details>


---

### last

:clock230: `recorder.last` waits for the recorded publisher to complete.

:x: When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time, and the publisher error is thrown if the publisher fails.

:white_check_mark: Otherwise, the last published element is returned, or nil if the publisher completes before it publishes any element.

:arrow_right: Related expectations: [elements], [single].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherPublishesLastElementLast() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    if let element = try wait(for: recorder.last, timeout: ...) {
        XCTAssertEqual(element, "baz")
    } else {
        XCTFail("Expected one element")
    }
}

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
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notCompleted
func testLastTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let element = try wait(for: recorder.last, timeout: ...)
}

// FAIL: Caught error MyError
func testLastError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let element = try wait(for: recorder.last, timeout: ...)
}
```

</details>


---

### next()

:clock230: `recorder.next()` waits for the recorded publisher to emit one element, or to complete.

:x: When waiting for this expectation, a `RecordingError.notEnoughElements` is thrown if the publisher does not publish one element after last waited expectation. The publisher error is thrown if the publisher fails before publishing the next element.

:white_check_mark: Otherwise, the next published element is returned.

:arrow_right: Related expectations: [next(count)], [single].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayOfTwoElementsPublishesElementsInOrder() throws {
    let publisher = ["foo", "bar"].publisher
    let recorder = publisher.record()
    
    var element = try wait(for: recorder.next(), timeout: ...)
    XCTAssertEqual(element, "foo")
    
    element = try wait(for: recorder.next(), timeout: ...)
    XCTAssertEqual(element, "bar")
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
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notEnoughElements
func testNextTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let element = try wait(for: recorder.next(), timeout: ...)
}

// FAIL: Caught error MyError
func testNextError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let element = try wait(for: recorder.next(), timeout: ...)
}

// FAIL: Caught error RecordingError.notEnoughElements
func testNextNotEnoughElementsError() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send(completion: .finished)
    let element = try wait(for: recorder.next(), timeout: ...)
}
```

</details>

`recorder.next()` can be inverted:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectDoesNotPublishAnyElement() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    try wait(for: recorder.next().inverted, timeout: ...)
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Fulfilled inverted expectation
func testInvertedNextTooEarly() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    try wait(for: recorder.next().inverted, timeout: ...)
}

// FAIL: Fulfilled inverted expectation
// FAIL: Caught error MyError
func testInvertedNextError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    try wait(for: recorder.next().inverted, timeout: ...)
}
```

</details>


---

### next(count)

:clock230: `recorder.next(count)` waits for the recorded publisher to emit `count` elements, or to complete.

:x: When waiting for this expectation, a `RecordingError.notEnoughElements` is thrown if the publisher does not publish `count` elements after last waited expectation. The publisher error is thrown if the publisher fails before publishing the next `count` elements.

:white_check_mark: Otherwise, an array of exactly `count` elements is returned.

:arrow_right: Related expectations: [next()], [prefix(maxLength)].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayOfThreeElementsPublishesTwoThenOneElement() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    
    var elements = try wait(for: recorder.next(2), timeout: ...)
    XCTAssertEqual(elements, ["foo", "bar"])
    
    elements = try wait(for: recorder.next(1), timeout: ...)
    XCTAssertEqual(elements, ["baz"])
}

// SUCCESS: no error
func testArrayOfThreeElementsSynchronouslyPublishesTwoThenOneElement() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    
    var elements = try recorder.next(2).get()
    XCTAssertEqual(elements, ["foo", "bar"])
    
    elements = try recorder.next(1).get()
    XCTAssertEqual(elements, ["baz"])
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notEnoughElements
func testNextCountTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    let elements = try wait(for: recorder.next(2), timeout: ...)
}

// FAIL: Caught error MyError
func testNextCountError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.next(2), timeout: ...)
}

// FAIL: Caught error RecordingError.notEnoughElements
func testNextCountNotEnoughElementsError() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send(completion: .finished)
    let elements = try wait(for: recorder.next(2), timeout: ...)
}
```

</details>


---

### prefix(maxLength)

:clock230: `recorder.prefix(maxLength)` waits for the recorded publisher to emit `maxLength` elements, or to complete.

:x: When waiting for this expectation, the publisher error is thrown if the publisher fails before `maxLength` elements are published.

:white_check_mark: Otherwise, an array of received elements is returned, containing at most `maxLength` elements, or less if the publisher completes early.

:arrow_right: Related expectations: [availableElements], [elements], [next(count)].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayOfThreeElementsPublishesTwoFirstElementsWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let elements = try wait(for: recorder.prefix(2), timeout: ...)
    XCTAssertEqual(elements, ["foo", "bar"])
}

// SUCCESS: no error
func testArrayOfThreeElementsSynchronouslyPublishesTwoFirstElementsWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let elements = try recorder.prefix(2).get()
    XCTAssertEqual(elements, ["foo", "bar"])
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
func testPrefixTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    let elements = try wait(for: recorder.prefix(2), timeout: ...)
}

// FAIL: Caught error MyError
func testPrefixError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.prefix(2), timeout: ...)
}
```

</details>

`recorder.prefix(maxLength)` can be inverted:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectPublishesNoMoreThanSentValues() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send("bar")
    let elements = try wait(for: recorder.prefix(3).inverted, timeout: ...)
    XCTAssertEqual(elements, ["foo", "bar"])
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Fulfilled inverted expectation
func testInvertedPrefixTooEarly() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send("bar")
    publisher.send("baz")
    let elements = try wait(for: recorder.prefix(3).inverted, timeout: ...)
}

// FAIL: Fulfilled inverted expectation
// FAIL: Caught error MyError
func testInvertedPrefixError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.prefix(3).inverted, timeout: ...)
}
```

</details>


---

### recording

:clock230: `recorder.recording` waits for the recorded publisher to complete.

:x: When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time.

:white_check_mark: Otherwise, a [`Record.Recording`](https://developer.apple.com/documentation/combine/record/recording) is returned.

:arrow_right: Related expectations: [completion], [elements], [finished].

Example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherRecording() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let recording = try wait(for: recorder.recording, timeout: ...)
    XCTAssertEqual(recording.output, ["foo", "bar", "baz"])
    if case let .failure(error) = recording.completion {
        XCTFail("Unexpected error \(error)")
    }
}

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
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notCompleted
func testRecordingTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let recording = try wait(for: recorder.recording, timeout: ...)
}
```

</details>


---

### single

:clock230: `recorder.single` waits for the recorded publisher to complete.

:x: When waiting for this expectation, a `RecordingError` is thrown if the publisher does not complete on time, or does not publish exactly one element before it completes. The publisher error is thrown if the publisher fails.

:white_check_mark: Otherwise, the single published element is returned.

:arrow_right: Related expectations: [elements], [last], [next()].

Example:

```swift
// SUCCESS: no timeout, no error
func testJustPublishesExactlyOneElement() throws {
    let publisher = Just("foo")
    let recorder = publisher.record()
    let element = try wait(for: recorder.single, timeout: ...)
    XCTAssertEqual(element, "foo")
}

// SUCCESS: no error
func testJustSynchronouslyPublishesExactlyOneElement() throws {
    let publisher = Just("foo")
    let recorder = publisher.record()
    let element = try recorder.single.get()
    XCTAssertEqual(element, "foo")
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
// FAIL: Caught error RecordingError.notCompleted
func testSingleTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let element = try wait(for: recorder.single, timeout: ...)
}

// FAIL: Caught error MyError
func testSingleError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let element = try wait(for: recorder.single, timeout: ...)
}

// FAIL: Caught error RecordingError.tooManyElements
func testSingleTooManyElementsError() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send("bar")
    publisher.send(completion: .finished)
    let element = try wait(for: recorder.single, timeout: ...)
}

// FAIL: Caught error RecordingError.notEnoughElements
func testSingleNotEnoughElementsError() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send(completion: .finished)
    let element = try wait(for: recorder.single, timeout: ...)
}
```

</details>


[Release Notes]: CHANGELOG.md
[Usage]: #usage
[Installation]: #installation
[Publisher Expectations]: #publisher-expectations
[finished]: #finished
[prefix(maxLength)]: #prefixmaxlength
[next()]: #next
[next(count)]: #nextcount
[recording]: #recording
[completion]: #completion
[elements]: #elements
[last]: #last
[single]: #single
[availableElements]: #availableElements
