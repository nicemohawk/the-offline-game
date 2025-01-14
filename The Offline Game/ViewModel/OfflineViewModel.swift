//
//  OfflineViewModel.swift
//  The Offline Game
//
//  Created by Daniel Crompton on 12/2/24.
//

import SwiftUI


@Observable
class OfflineViewModel {
    
    
    //MARK: - Initialization
        
    init() {
        // Restore the things from user defaults
        
        // The `UserDefaults.standard.double` defaults to 0.0 if the value doesn't exist but we want it to default to 20 minutes.
        let durationSeconds = UserDefaults.standard.double(forKey: K.userDefaultsDurationSecondsKey)
        self.durationSeconds = durationSeconds == 0.0 ? 20*60 : durationSeconds
        
        let stateRawValue = UserDefaults.standard.integer(forKey: K.userDefaultsOfflineStateKey)
        state = State(rawValue: stateRawValue) ?? .none
        
        startDate = UserDefaults.standard.object(forKey: K.userDefaultsStartDateKey) as? Date // default to nil
        
        if isOffline {
            scheduleOfflineTimer()
        }
    }
    
    
    
    //MARK: - Offline duration
    
    // store the number of offline minutes selected by the user
    var durationSeconds: TimeInterval = 20 * 60 { // 20 minutes
        didSet {
            // When set, persist it in user defaults
            UserDefaults.standard.set(durationSeconds, forKey: K.userDefaultsDurationSecondsKey)
#warning("The durationSeconds is set extrenuousely each time the slider changes")
        }
    }
    var durationMinutes: TimeInterval {
        get { durationSeconds / 60 }
        set { durationSeconds = newValue * 60 }
    }
    
    
    
    //MARK: - Offline state
    
    enum State: Int {
        case none, offline, paused
    }
    
    var state = State.none {
        // When we set the state value, store in user defaults
        didSet { UserDefaults.standard.set(state.rawValue, forKey: K.userDefaultsOfflineStateKey) }
    }
    
    // Is the user offline?
    // Used to trigger presentation of the offline view
    var isOffline: Bool {
        get { state != .none } // We are offline if the state is either paused or actually offline
        set { state = newValue ? .offline : .none }
    }
    var isPaused: Bool { state == .paused }
    
    // When did the user go offline?
    var startDate: Date? {
        didSet {
            UserDefaults.standard.set(startDate, forKey: K.userDefaultsStartDateKey)
            if oldValue != nil { oldStartDate = oldValue }
        }
    }
    
    // Used to access the previous start date even when it's reset
    var oldStartDate: Date?
    
    // When can they do online?
    // Diaplayed in the UI with Text(Date, style: .timer)
    var endDate: Date? {
        guard let startDate else { return nil }
        return startDate.addingTimeInterval(durationSeconds)
    }
    
    // Used in the offline progress bar gauges
    var offlineProgress: CGFloat? {
        // The start date's distance to the current date
        guard let endDate else { return nil }
        return startDate?.completionTo(endDate)
    }
    
    // Elapsed time used in ther live activity and the offline progress calculation
    var elapsedTime: TimeInterval? {
        guard let startDate else { return nil }
        return Date().timeIntervalSince(startDate)
    }
    
    // Used to call the function to end the offline period (e.g. bringing up the congrats view and dismissing the OfflineView)
    var endOfflineTimer: Timer? // ONLY TRIGGERS at the `endDate`
    
    // The notification posted when offline time completes
    var congratulatoryNotification: OfflineNotification?
    
    func goOffline() {
        isPickingDuration = false
        isOffline = true
        startDate = Date()
        
        // Add one to the offline count
        offlineCountViewModel?.increase()
        
        // Now add the live activity
        liveActivityViewModel?.startActivity()
        
        scheduleOfflineTimer()
        
        // Now schedule a notification to be posted to the user when their offline time ends
        let formattedDuration = DurationDisplayHelper.formatDuration(durationSeconds)
        
        congratulatoryNotification = OfflineNotification.congratulatoryNotification(
            endDate: endDate!, // unwrapped- just set startDate and endDate depends on it
            formattedDuration: formattedDuration
        )
        
        congratulatoryNotification?.post()
    }
    
    
    private func scheduleOfflineTimer() {
        guard let endDate else {
            print("Don't call scheduleOfflineTimer is endDate is nil")
            return
        }
        
        // Schedule the `offlineTimeFinished` function to be called at the `endDate`
        endOfflineTimer = Timer.scheduledTimer(
            withTimeInterval: endDate.timeIntervalSinceNow,
            repeats: false
        ) { [weak self] _ in
            // may execute on a background thread
            DispatchQueue.main.async {
                self?.offlineTimeFinished(successfully: true)
            }
        }
    }
    
    
    func offlineTimeFinished(successfully: Bool) {
        print("offline time finished")
        
        endOfflineTimer?.invalidate()
        endOfflineTimer = nil
        startDate = nil
        
        // Now subtract 1 from the offline count
        offlineCountViewModel?.decrease()
        
        // Manage presentation of sheets
        isOffline = false
        userShouldBeCongratulated = successfully
        userDidFail = !successfully
        
        // stop the live activity
        liveActivityViewModel?.stopActivity()
        
        // Now revoke any success notifications if we need to
        congratulatoryNotification?.revoke()
    }
    
    var pauseDate: Date?
    func pauseOfflineTime() {
        // - Record the time we pause at and set state
        pauseDate = Date()
        state = .paused
        
        // - Cancel notifications and timers
        endOfflineTimer?.invalidate()
        endOfflineTimer = nil
        congratulatoryNotification?.revoke()
        congratulatoryNotification = nil
    }
    
    
    func resumeOfflineTime() {
        // We can only resume if we have been paused
        guard isPaused,
              let pauseDate else {
            print("Only resume offline time when paused")
            return
        }
        
        // - Calculate the duration we were paused for
        let pauseDuration = Date().timeIntervalSince(pauseDate)
        
        // - modify the end date. To do this we need to change the offline duration
        durationSeconds += pauseDuration
        
        // - reschedule the notification and end timer
        scheduleOfflineTimer()
        
        let formattedDuration = DurationDisplayHelper.formatDuration(durationSeconds)
        congratulatoryNotification = OfflineNotification.congratulatoryNotification(
            endDate: endDate!, // unwrapped- just set startDate and endDate depends on it
            formattedDuration: formattedDuration
        )
        congratulatoryNotification?.post()
    }
    
    
    //MARK: - Other
    
    var isPickingDuration = false // Makes the OfflinetimeView appear to pick duration
    var userShouldBeCongratulated = false // Makes the congratulatory view appear in the main view
    var userDidFail = false // Presents the failure view
    
    var liveActivityViewModel: LiveActivityViewModel?
    var offlineCountViewModel: OfflineCountViewModel?
}
