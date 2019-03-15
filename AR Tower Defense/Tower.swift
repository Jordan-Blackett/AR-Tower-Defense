//
//  Tower.swift
//  AR Tower Defense
//
//  Created by Jordan Blackett on 09/01/2018.
//  Copyright © 2018 BLACKETT, JORDAN. All rights reserved.
//

import ARKit

import Foundation

class Tower {
    var damage = Int()
    var fireSpeed = Double()
    var projectileSpeed = Float()
    var range = Float()
    
    var towerNode = SCNNode()
    var projectileNode = SCNNode()
    var fireTimer = Timer()
    
    var enemyID = Int()
    var gotTarget = false
    var fireInProgress = false
    
    init(mapCoords: SCNVector3, towerDamage: Int, towerFireSpeed: Float, towerRange: Float, towerColour: UIColor)
    {
        damage = towerDamage
        fireSpeed = Double(towerFireSpeed)
        range = towerRange
        projectileSpeed = 0.01
        
        // Create Tower Node
        let cube = SCNBox(width: 0.02, height: 0.07, length: 0.02, chamferRadius: 0)
        cube.firstMaterial?.diffuse.contents = towerColour
        
        let cubeNode = SCNNode(geometry: cube)
        
        towerNode.addChildNode(cubeNode)
        towerNode.position = SCNVector3(mapCoords.x, mapCoords.y, mapCoords.z)
        
        // Create Projectile
        let cubeProjectile = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
        cubeProjectile.firstMaterial?.diffuse.contents = towerColour //UIColor.green
        
        let projectileCubeNode = SCNNode(geometry: cubeProjectile)
        
        projectileNode.addChildNode(projectileCubeNode)
        projectileNode.position = SCNVector3(mapCoords.x, mapCoords.y, mapCoords.z)
    }
    
    func startFire()
    {
        fireTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.Tick), userInfo: nil, repeats: true)
    }
    
    @objc func Tick()
    {
        fire()
    }
    
    func fire()
    {
        if(!fireInProgress)
        {
            projectileNode.worldPosition = towerNode.worldPosition
            // Fire Rate Delay
            DispatchQueue.main.asyncAfter(deadline: .now() + fireSpeed)
            {
                self.fireInProgress = true
            }
        }
        else {
            if(EnemyStore.sharedInstance.activeEnemies.count > enemyID && !EnemyStore.sharedInstance.activeEnemies.isEmpty)
            {
                let dx = EnemyStore.sharedInstance.activeEnemies[enemyID].enemyNode.worldPosition.x - projectileNode.worldPosition.x
                let dz = EnemyStore.sharedInstance.activeEnemies[enemyID].enemyNode.worldPosition.z - projectileNode.worldPosition.z
                
                let angle = atan2(dz, dx)
                
                let vx = cos(angle) * projectileSpeed
                let vz = sin(angle) * projectileSpeed
                
                projectileNode.position.x += vx
                projectileNode.position.z += vz
                
                // Check if hit
                let distance = hypot(dx, dz)
                if(distance < 0.04)
                {
                    fireInProgress = false
                    
                    //check if target is dead
                    EnemyStore.sharedInstance.activeEnemies[enemyID].damage(dmg: damage)
                }
            } else{
                // Reset Bullet
                fireInProgress = false
            }
        }
    }
    
    func findTartget(target: Enemy)
    {
        if(!gotTarget)
        {
            let distance = hypot((towerNode.worldPosition.x - target.enemyNode.worldPosition.x), (towerNode.worldPosition.z - target.enemyNode.worldPosition.z))
            if(distance < range)
            {
                enemyID = target.enemyID
                startFire()
                gotTarget = true
            }
        }
        else if(enemyID < EnemyStore.sharedInstance.activeEnemies.count)
        {
            // Check enemy still in range
            let distance = hypot((towerNode.worldPosition.x - EnemyStore.sharedInstance.activeEnemies[enemyID].enemyNode.worldPosition.x), (towerNode.position.z - EnemyStore.sharedInstance.activeEnemies[enemyID].enemyNode.worldPosition.z))
            if(distance > range)
            {
                gotTarget = false
                fireTimer.invalidate()
            }
        }
    }
}
