import Foundation
import CoreMotion
import Combine

@MainActor
final class FocusSessionEngine: ObservableObject {
    enum SessionState: Equatable {
        case idle
        case running
        case paused(reason: String)
    }

    @Published private(set) var state: SessionState = .idle
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var creditedMinutes: Int = 0
    @Published private(set) var isDeviceStill: Bool = true

    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var sessionStartUptime: TimeInterval = 0
    private var accumulatedActiveSeconds: TimeInterval = 0
    private var lastTickUptime: TimeInterval = 0
    private var lastCreditedMinuteMark: Int = 0

    var onMinuteEarned: ((Int) -> Void)?

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    func start() {
        guard !isRunning else { return }
        elapsedSeconds = 0
        creditedMinutes = 0
        accumulatedActiveSeconds = 0
        lastCreditedMinuteMark = 0
        sessionStartUptime = ProcessInfo.processInfo.systemUptime
        lastTickUptime = sessionStartUptime
        state = .running
        startMotionUpdatesIfAvailable()
        startTimer()
    }

    func stop() {
        state = .idle
        timer?.invalidate()
        timer = nil
        motionManager.stopAccelerometerUpdates()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isRunning || isPaused else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let delta = now - lastTickUptime
        lastTickUptime = now

        if isDeviceStill {
            accumulatedActiveSeconds += delta
            state = .running
        } else {
            state = .paused(reason: "Phone picked up — set it down to keep earning")
        }

        elapsedSeconds = Int(now - sessionStartUptime)

        let earnedMinutes = Int(accumulatedActiveSeconds) / 60
        if earnedMinutes > lastCreditedMinuteMark {
            let newMinutes = earnedMinutes - lastCreditedMinuteMark
            lastCreditedMinuteMark = earnedMinutes
            creditedMinutes = earnedMinutes
            onMinuteEarned?(newMinutes)
        }
    }

    private var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    private func startMotionUpdatesIfAvailable() {
        guard motionManager.isAccelerometerAvailable else {
            isDeviceStill = true
            return
        }
        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data = data else { return }
            let magnitude = sqrt(data.acceleration.x * data.acceleration.x +
                                  data.acceleration.y * data.acceleration.y +
                                  data.acceleration.z * data.acceleration.z)
            let deviation = abs(magnitude - 1.0)
            self.isDeviceStill = deviation < 0.06
        }
    }
}
