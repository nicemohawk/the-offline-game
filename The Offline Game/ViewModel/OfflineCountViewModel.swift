//
//  OfflineCountViewModel.swift
//  The Offline Game
//
//  Created by Daniel Crompton on 1/4/25.
//

import Foundation
import FirebaseDatabase

@Observable
class OfflineCountViewModel {
    
    var count = 0
    
    private var realtimeDB: DatabaseReference!
    
    func loadDatabase() {
        realtimeDB = Database.database().reference()
    }
    
    
    
    func setupDatabaseObserver() {
        let countRef = realtimeDB.child(K.firebaseOfflineCountKey)
        
        countRef.observe(.value) { [weak self] snapshot in
            if let c = snapshot.value as? Int {                
                DispatchQueue.main.async {
                    self?.count = c
//                    print("Offline count changed to \(self?.count ?? -1)")
                }
            } else {
                print("Cannot get Int value from snapshot")
            }
        }
    }
    
    
    
    func increase() async throws {
        let countRef = realtimeDB.child("offlineCount")
        
        // The transactions are good for concurrency
        try await countRef.runTransactionBlock { data in
            data.value = max((data.value as? Int ?? 0) + 1, 0)
            
            return .success(withValue: data)
        }
        
    }
    
    
    
    func decrease() async throws {
        // Concurrency handled properly?
        
        let countRef = realtimeDB.child("offlineCount")
        
        // The transactions are good for concurrency
        try await countRef.runTransactionBlock { data in
            data.value = max((data.value as? Int ?? 0) - 1, 0)
            
            return .success(withValue: data)
        }
    }
}
