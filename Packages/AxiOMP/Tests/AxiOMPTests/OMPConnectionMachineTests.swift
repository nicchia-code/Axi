import Foundation
import Testing
@testable import AxiOMP

struct OMPConnectionMachineTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test func becomesReadyAfterLaunch() {
        var machine = OMPConnectionMachine()
        let launch = machine.handle(.started, at: start)
        let ready = machine.handle(.ready, at: start)
        #expect(launch == [.launch])
        #expect(ready == [.publish(.ready)])
        #expect(machine.state == .ready)
    }

    @Test func missingExecutableIsUnavailable() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        let effects = machine.handle(.failed(.notFound), at: start)
        #expect(effects == [.publish(.unavailable(.notFound)), .stop])
        #expect(machine.state == .unavailable(.notFound))
    }

    @Test func exitDuringStartupIsFailedToStart() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        let effects = machine.handle(.exited, at: start)
        #expect(effects == [.publish(.unavailable(.failedToStart)), .stop])
    }

    @Test func firstExitRestartsAndSecondExitWithinWindowStops() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        _ = machine.handle(.ready, at: start)
        let restart = machine.handle(.exited, at: start)
        #expect(restart == [.publish(.terminated), .publish(.starting), .stop, .launch])
        #expect(machine.state == .starting)
        _ = machine.handle(.ready, at: start)
        let stop = machine.handle(.exited, at: start.addingTimeInterval(10))
        #expect(stop == [.publish(.terminated), .publish(.unavailable(.stoppedAgain)), .stop])
        #expect(machine.state == .unavailable(.stoppedAgain))
    }

    @Test func exitAfterTheWindowRestartsAgain() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        _ = machine.handle(.ready, at: start)
        _ = machine.handle(.exited, at: start)
        _ = machine.handle(.ready, at: start)
        let restart = machine.handle(.exited, at: start.addingTimeInterval(31))
        #expect(restart == [.publish(.terminated), .publish(.starting), .stop, .launch])
        #expect(machine.state == .starting)
    }

    @Test func exitWhileRestartingFollowsTheRestartRule() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        _ = machine.handle(.ready, at: start)
        _ = machine.handle(.exited, at: start)
        let restart = machine.handle(.exited, at: start.addingTimeInterval(10))
        #expect(restart == [.publish(.unavailable(.stoppedAgain)), .stop])
        #expect(machine.state == .unavailable(.stoppedAgain))
    }

    @Test func exitWhileRestartingAfterTheWindowRestartsWithoutANewTerminatedEvent() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        _ = machine.handle(.ready, at: start)
        _ = machine.handle(.exited, at: start)
        let restart = machine.handle(.exited, at: start.addingTimeInterval(31))
        #expect(restart == [.publish(.starting), .stop, .launch])
        #expect(machine.state == .starting)
    }

    @Test func newPathRetriesFromUnavailable() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        _ = machine.handle(.failed(.notFound), at: start)
        let effects = machine.handle(.userChangedPath, at: start)
        #expect(effects == [.publish(.starting), .stop, .launch])
        #expect(machine.state == .starting)
    }

    @Test func newPathWhileReadyOrStartingDoesNotRestart() {
        var machine = OMPConnectionMachine()
        _ = machine.handle(.started, at: start)
        #expect(machine.handle(.userChangedPath, at: start) == [])
        #expect(machine.state == .starting)
        _ = machine.handle(.ready, at: start)
        #expect(machine.handle(.userChangedPath, at: start) == [])
        #expect(machine.state == .ready)
    }
}
