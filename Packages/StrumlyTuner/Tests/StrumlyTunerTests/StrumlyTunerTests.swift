import Testing
@testable import StrumlyTuner

@Test func tunerVersionIsSet() {
    #expect(StrumlyTuner.version == "0.1.0")
}
