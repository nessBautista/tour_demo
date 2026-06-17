import XCTest
import VoiceExtraction

@MainActor
final class VoiceTranscriberFactoryTests: XCTestCase {

    /// Whatever implementation the environment selects, it comes back fresh and
    /// ready to drive through the standard lifecycle.
    func testDefaultIsFreshAndUsable() {
        let transcriber = VoiceTranscriberFactory.makeDefault()
        XCTAssertEqual(transcriber.modelState, .unknown)
        XCTAssertFalse(transcriber.isRecording)
        XCTAssertTrue(transcriber.transcript.isEmpty)
    }

    /// On any non-device build (macOS test host, Simulator), the default is the
    /// stub — so the lifecycle works end to end with no hardware.
    func testDefaultDrivesThroughLifecycleOffDevice() async {
        let transcriber = VoiceTranscriberFactory.makeDefault()
        await transcriber.prepare()
        await transcriber.startRecording()
        await transcriber.stopRecording()
        XCTAssertFalse(transcriber.isRecording)
    }
}
