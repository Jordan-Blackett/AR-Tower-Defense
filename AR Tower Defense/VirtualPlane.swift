//
//  VirtualPlane.swift
//  AR Tower Defense
//
//  Created by BLACKETT, JORDAN on 11/12/2017.
//  Copyright © 2017 BLACKETT, JORDAN. All rights reserved.
//

import Foundation

import SceneKit
import ARKit

class VirtualPlane: SCNNode {
    // store the anchor and a plane SceneKit node containing the visual representation of the plane. REWRITE:
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    init(anchor: ARPlaneAnchor) {
        super.init()
        
        // initialize anchor and geometry, set color for plane
        self.anchor = anchor
        //self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        //Match Map Size - Plane touch detection
        self.planeGeometry = SCNPlane(width: CGFloat(1), height: CGFloat(1))
        
        //let material = initializePlaneMaterial()
        //self.planeGeometry!.materials = [material]
        
        // Set Image/Material
        let planeImage = UIImage() //named: "tron_grid"
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = planeImage
        //lavaMaterial.isDoubleSided = true
        self.planeGeometry!.materials = [planeMaterial]
        
        // create the SceneKit plane node.
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
 
        // Game Map
        let mapNode = SCNNode()
        mapNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
            
        guard let virtualObjectScene = SCNScene(named: "art.scnassets/Map_1.scn") else { return }
            
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
            
        mapNode.addChildNode(wrapperNode)
            
        let objectScale = SCNVector3Make(0.02, 0.02, 0.02)
        mapNode.scale = objectScale
            
        self.addChildNode(mapNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    struct planeRect {
        var left = CGFloat()
        var top = CGFloat()
        var width = CGFloat()
        var height = CGFloat()
    }
    
    func getSize() -> planeRect
    {
        var rect = planeRect()
        rect.left = 0
        rect.top = 0
        rect.width = self.planeGeometry!.width
        rect.height = self.planeGeometry!.height
        
        return rect
    }
    
    
}


