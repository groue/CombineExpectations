# CombineExpectations

### Utilities for tests that wait for Combine publishers.

---

**Latest release**: [version 0.1.0](https://github.com/groue/CombineExpectations/tree/v0.1.0) (November 23, 2019) • [Release Notes]

**Requirements**: iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ &bull; Swift 5.1+ / Xcode 11.0+

**Contact**: Report bugs and ask questions in [Github issues](https://github.com/groue/CombineExpectations/issues).

:bug: CombineExpectations tests crash or fail until Xcode 11.3. They rely on fixes to Combine that were only introduced in the SDK shipped with Xcode 11.3. However, the library itself works fine right from Xcode 11.0.

---

Testing Combine publishers with [XCTestExpectation](*https://developer.apple.com/documentation/xctest/xctestexpectation*) often requires setting up a lot of boilerplate code.

CombineExpectations aims at streamlining those tests. It defines an XCTestCase method which waits for *publisher expectations*.

- [Usage]
- [Installation]
- [Publisher Expectations]: [completion], [elements], [finished], [first], [last], [prefix], [recording], [single]

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
        let elements = try wait(for: recorder.elements, timeout: 1, description: "Elements")
        
        // 4. Test the result of the expectation
        XCTAssertEqual(elements, ["Hello", "World!"])
    }
}
```

When you wait for a publisher expectation,

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
        _ = try wait(for: recorder.first, timeout: ...)
        
        // Wait for second element
        _ = try wait(for: recorder.prefix(2), timeout: ...)
        
        // Wait for successful completion
        try wait(for: recorder.finished, timeout: ...)
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

- [completion]: the publisher completion
- [elements]: all published elements
- [finished]: the publisher successful completion
- [first]: the first published element
- [last]: the last published element
- [prefix]: the first N published elements
- [recording]: the full recording of publisher events
- [single]: the one and only published element
- [Inverted Expectations]

### completion

`recorder.completion` is a publisher expectation which waits for the recorded publisher to complete.

When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time.

Otherwise, a [`Subscribers.Completion`](https://developer.apple.com/documentation/subscribers/completion) is returned.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherCompletesWithSuccess() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let completion = try wait(for: recorder.completion, timeout: 1)
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
    let completion = try wait(for: recorder.completion, timeout: 1)
}
```

</details>


### elements

`recorder.elements` is a publisher expectation which waits for the recorded publisher to complete.

When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time, and the publisher error is thrown if the publisher fails.

Otherwise, an array of published elements is returned.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherPublishesArrayElements() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let elements = try wait(for: recorder.elements, timeout: 1)
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
    let elements = try wait(for: recorder.elements, timeout: 1)
}
    
// FAIL: Caught error MyError
func testElementsError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.elements, timeout: 1)
}
```

</details>


### finished

`recorder.finished` is a publisher expectation which waits for the recorded publisher to complete successfully.

When waiting for this expectation, an error is thrown if the publisher fails with an error.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherFinishesWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    try wait(for: recorder.finished, timeout: 1)
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
func testFinishedTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    try wait(for: recorder.finished, timeout: 1)
}
    
// FAIL: Caught error MyError
func testFinishedError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    try wait(for: recorder.finished, timeout: 1)
}
```

</details>

This publisher expectation can be [inverted]:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectDoesNotFinish() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    try wait(for: recorder.finished.inverted, timeout: 1)
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
    try wait(for: recorder.finished.inverted, timeout: 1)
}
```

</details>


### first

`recorder.first` is a publisher expectation which waits for the recorded publisher to emit one element, or to complete.

When waiting for this expectation, an error is thrown if the publisher fails before any element is published.

Otherwise, the first published element is returned, unless the publisher completes before it publishes any element.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayOfThreeElementsPublishesItsFirstElementWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    if let element = try wait(for: recorder.first, timeout: 1) {
        XCTAssertEqual(element, "foo")
    } else {
        XCTFail("Expected one element")
    }
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift
// FAIL: Asynchronous wait failed
func testFirstTimeout() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    let element = try wait(for: recorder.first, timeout: 1)
}
    
// FAIL: Caught error MyError
func testFirstError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let element = try wait(for: recorder.first, timeout: 1)
}
```

</details>

This publisher expectation can be [inverted]:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectDoesNotPublishAnyElement() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    _ = try wait(for: recorder.first.inverted, timeout: 1)
}
```

<details>
    <summary>Examples of failing tests</summary>

```swift    
// FAIL: Fulfilled inverted expectation
func testInvertedFirstTooEarly() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    _ = try wait(for: recorder.first.inverted, timeout: 1)
}
    
// FAIL: Fulfilled inverted expectation
// FAIL: Caught error MyError
func testInvertedFirstError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    _ = try wait(for: recorder.first.inverted, timeout: 1)
}
```

</details>


### last

`recorder.last` is a publisher expectation which waits for the recorded publisher to publish its last element and complete.

When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time, and the publisher error is thrown if the publisher fails.

Otherwise, the last published element is returned, unless the publisher completes before it publishes any element.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherPublishesLastElementLast() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    if let element = try wait(for: recorder.last, timeout: 1) {
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
    let element = try wait(for: recorder.last, timeout: 1)
}
    
// FAIL: Caught error MyError
func testLastError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let element = try wait(for: recorder.last, timeout: 1)
}
```

</details>


### prefix

`recorder.prefix(maxLength)` is a publisher expectation which waits for the recorded publisher to emit a certain number of elements, or to complete.

When waiting for this expectation, an error is thrown if the publisher fails before `maxLength` elements are published.

Otherwise, an array of received elements is returned, containing at most `maxLength` elements, or less if the publisher completes early.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayOfThreeElementsPublishesTwoFirstElementsWithoutError() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let elements = try wait(for: recorder.prefix(2), timeout: 1)
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
    let elements = try wait(for: recorder.prefix(2), timeout: 1)
}
    
// FAIL: Caught error MyError
func testPrefixError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.prefix(2), timeout: 1)
}
```

</details>

This publisher expectation can be [inverted]:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectPublishesNoMoreThanSentValues() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send("bar")
    let elements = try wait(for: recorder.prefix(3).inverted, timeout: 1)
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
    let elements = try wait(for: recorder.prefix(3).inverted, timeout: 1)
}
    
// FAIL: Fulfilled inverted expectation
// FAIL: Caught error MyError
func testInvertedPrefixError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send(completion: .failure(MyError()))
    let elements = try wait(for: recorder.prefix(3).inverted, timeout: 1)
}
```

</details>


### recording

`recorder.recording` is a publisher expectation which waits for the recorded publisher to complete.

When waiting for this expectation, a `RecordingError.notCompleted` is thrown if the publisher does not complete on time.

Otherwise, a [`Record.Recording`](https://developer.apple.com/documentation/combine/ecording) is returned.

For example:

```swift
// SUCCESS: no timeout, no error
func testArrayPublisherRecording() throws {
    let publisher = ["foo", "bar", "baz"].publisher
    let recorder = publisher.record()
    let recording = try wait(for: recorder.recording, timeout: 1)
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
    let recording = try wait(for: recorder.recording, timeout: 1)
}
```

</details>


### single

`recorder.single` is a publisher expectation which waits for the recorded publisher to publish exactly one element and complete.

When waiting for this expectation, a `RecordingError` is thrown if the publisher does not complete on time, or does not publish exactly one element before it completes. The publisher error is thrown if the publisher fails.

Otherwise, the single published element is returned.

For example:

```swift
// SUCCESS: no timeout, no error
func testJustPublishesExactlyOneElement() throws {
    let publisher = Just("foo")
    let recorder = publisher.record()
    let element = try wait(for: recorder.single, timeout: 1)
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
    let element = try wait(for: recorder.single, timeout: 1)
}
    
// FAIL: Caught error MyError
func testSingleError() throws {
    let publisher = PassthroughSubject<String, MyError>()
    let recorder = publisher.record()
    publisher.send(completion: .failure(MyError()))
    let element = try wait(for: recorder.single, timeout: 1)
}
    
// FAIL: Caught error RecordingError.moreThanOneElement
func testSingleMoreThanOneElementError() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send("foo")
    publisher.send("bar")
    publisher.send(completion: .finished)
    let element = try wait(for: recorder.single, timeout: 1)
}
    
// FAIL: Caught error RecordingError.noElements
func testSingleNoElementsError() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    publisher.send(completion: .finished)
    let element = try wait(for: recorder.single, timeout: 1)
}
```

</details>


### Inverted Expectations

Some expectations can be inverted ([finished], [first], [prefix]). An inverted expectation fails if the base expectation fulfills within the specified timeout.

When waiting for an inverted expectation, you receive the same result and eventual error as the base expectation.

For example:

```swift
// SUCCESS: no timeout, no error
func testPassthroughSubjectDoesNotFinish() throws {
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record()
    try wait(for: recorder.finished.inverted, timeout: 1)
}
```

[Release Notes]: CHANGELOG.md
[Usage]: #usage
[Installation]: #installation
[Publisher Expectations]: #publisher-expectations
[finished]: #finished
[prefix]: #prefix
[first]: #first
[recording]: #recording
[completion]: #completion
[elements]: #elements
[last]: #last
[single]: #single
[Inverted Expectations]: #inverted-expectations
[inverted]: #inverted-expectations
