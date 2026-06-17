import XCTest
import VoiceExtraction

@MainActor
final class StubTranscriberTests: XCTestCase {

    func testLifecycleMovesVolatileToFinalized() async {
        let stub = StubTranscriber(canned: "noisy street, lovely light")
        XCTAssertEqual(stub.modelState, .unknown)
        XCTAssertFalse(stub.isRecording)

        await stub.prepare()
        XCTAssertEqual(stub.modelState, .ready)

        await stub.startRecording()
        XCTAssertTrue(stub.isRecording)
        XCTAssertEqual(stub.transcript.volatile, "noisy street, lovely light")
        XCTAssertEqual(stub.transcript.finalized, "")

        await stub.stopRecording()
        XCTAssertFalse(stub.isRecording)
        XCTAssertEqual(stub.transcript.finalized, "noisy street, lovely light")
        XCTAssertEqual(stub.transcript.volatile, "")
        XCTAssertEqual(stub.transcript.combined, "noisy street, lovely light")
    }

    func testStartIsNoOpUntilReady() async {
        let stub = StubTranscriber()
        await stub.startRecording()   // not prepared yet
        XCTAssertFalse(stub.isRecording)
        XCTAssertTrue(stub.transcript.isEmpty)
    }

    /// The point of the protocol: the app can hold the capability abstractly.
    func testUsableThroughProtocol() async {
        let transcriber: any VoiceTranscribing = StubTranscriber()
        await transcriber.prepare()
        await transcriber.startRecording()
        XCTAssertTrue(transcriber.isRecording)
    }
}
