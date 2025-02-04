//
//  OfflinePauseHelper.swift
//  The Offline Game
//
//  Created by Daniel Crompton on 2/3/25.
//

import Foundation


struct OfflinePauseHelper {
    
    private init() { }
    
    
    static func pause(state: inout OfflineState) {
        
        print("⏸️ Paused offline at \(Date().formatted(date: .omitted, time: .complete))")
        // - Record the time we pause at and set state
        state.pauseDate = Date()
        state.state = .paused
        
        // Now cancel the success notification
        OfflineNotification.congratulatoryNotification(endDate: .now, formattedDuration: "").revoke()

    }
    
    
    static func resume(state: inout OfflineState) {
        
        // We can only resume if we have been paused
        guard state.isPaused,
              let pauseDate = state.pauseDate else {
            print("Only resume offline time when paused")
            return
        }
        
        print("▶️ Resuming offline time at \(Date().formatted(date: .omitted, time: .complete))")
        
        // - Calculate the duration we were paused for
        let pauseDuration = Date().timeIntervalSince(pauseDate)
        
        // - modify the end date. To do this we need to change the offline duration
        state.durationSeconds += .seconds(pauseDuration)
        
        // abbreviated because we're in a notification
        let formattedDuration = state.formattedDuration(width: .abbreviated)
        OfflineNotification.congratulatoryNotification(
            endDate: state.endDate!, // unwrapped- just set startDate and endDate depends on it
            formattedDuration: formattedDuration
        ).post()
        
    }
    
}
