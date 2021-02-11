import XCTest
@testable import SynthesisFramework

final class SynthesisFrameworkTests: XCTestCase {
    
    let format = SynthesisFormat(sr: kSamplesRate, cc: 1, l: kSamplesPerBuffer)
    let que = DispatchQueue(label: "SS")
    var synthesis: AudioSynthesis?
    var exp: XCTestExpectation?
    
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let s = SignalSynth(sampleRate: OscillationType(kSamplesRate))
        print(s.buffer(length: 100))
        XCTAssertEqual(SynthesisFramework().text, "Hello, World!")
    }
    
    func testSynthesis() {
        synthesis = AudioSynthesis(ƒ: format)
        guard
            let synthesis = synthesis
        else { return }
        
        exp = expectation(description: "mainvolume.timeout")
        synthesis.synthesize()
        while let buffer = synthesis.player.acquireBuffer() {
            print("[CoreSynthesis TEST] Synthesis Generated : \(buffer.capacity > 0)")
            exp?.fulfill()
            break
        }
        waitForExpectations(timeout: 5)
    }

    static var allTests = [
        ("testExample", testExample, testSynthesis),
    ]
}
