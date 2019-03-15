//
//  EnemyStore.swift
//  AR Tower Defense
//
//  Created by Jordan Blackett on 08/01/2018.
//  Copyright © 2018 BLACKETT, JORDAN. All rights reserved.
//

import Foundation

class EnemyStore {
    // Singleton
    static let sharedInstance = EnemyStore()
    
    var activeEnemies: [Enemy] = []
}
