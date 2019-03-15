//
//  Enemy.swift
//  AR Tower Defense
//
//  Created by Jordan Blackett on 08/01/2018.
//  Copyright © 2018 BLACKETT, JORDAN. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class Enemy {
    var health = 100
    var moveSpeed = Float()
    var enemyID = 0
    
    var enemyNode = SCNNode()
    var colourNode = SCNNode()
    
    var wayPointIndex = 0
    var mapWayPointsX: [Float] = [] // TODO: POINTERS
    var mapWayPointsY: [Float] = []
    
    var startPositionX = Float()
    var startPositionZ = Float()
    
    var firstPos = false
    
    var atEnd = false
    var isDead = false
    
    //let cube =
    
    init(id: Int, mapCoords: SCNVector3, pointsX: [Float], pointsY: [Float])
    {
        enemyID = id
        moveSpeed = 0.0006
        
        // Way Points
        mapWayPointsX = pointsX
        mapWayPointsY = pointsY
        
        //Create enemy cube
        let cube = SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0)
        cube.firstMaterial?.diffuse.contents = UIColor.red
        
        let cubeNode = SCNNode(geometry: cube)
        cubeNode.position = SCNVector3(mapCoords.x, mapCoords.y, mapCoords.z)
        
        colourNode = cubeNode.copy() as! SCNNode // Work around - can't change colour of enemyNode when enemy is damaged
        
        // start pos - mapcoord is center so -rednode coord
        enemyNode.addChildNode(cubeNode)
        
        // Top Conor of the map
        startPositionX = mapCoords.x - 0.14
        startPositionZ = mapCoords.z - 0.14
        
        // Set to first waypoint
        enemyNode.position = SCNVector3(mapCoords.x - 0.15, mapCoords.y, mapCoords.z - 0.1)
        
    }
    
    func move()
    {
        var newX = enemyNode.position.x
        var newZ = enemyNode.position.z
        
        let tempWaypointCoordsX = startPositionX + mapWayPointsX[wayPointIndex]
        let tempWaypointCoordsZ = startPositionZ + mapWayPointsY[wayPointIndex]
        
        if(enemyNode.position.x < tempWaypointCoordsX) {
            newX += moveSpeed
        } else{
            newX -= moveSpeed
        }
        
        if(enemyNode.position.z < tempWaypointCoordsZ) {
            newZ += moveSpeed
        } else{
            newZ -= moveSpeed
        }
        
        let distance = hypot((newX - tempWaypointCoordsX), (newZ - tempWaypointCoordsZ))
        if(distance < 0.005)
        {
            if(mapWayPointsX.count != wayPointIndex+1)
            {
                wayPointIndex += 1
            }
            //else delete
            else {
                atEnd = true
            }
        }
        
        enemyNode.position = SCNVector3(newX, enemyNode.position.y, newZ)
    }
    
    func damage(dmg: Int)
    {
        health -= dmg
        
        // Update Colour
        let colour = Double(health)
        colourNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: (CGFloat(colour / 100)), green: 0, blue: 0, alpha: 1)
        //enemyNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        
        // dead
        if(health <= 0)
        {
            isDead = true
        }
    }

    func atEndOfMap() -> Bool
    {
        return atEnd
    }
    
    func getIsDead() -> Bool
    {
        return isDead
    }
    
}
