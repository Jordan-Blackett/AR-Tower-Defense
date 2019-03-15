//
//  ViewController.swift
//  AR Tower Defense
//
//  Created by BLACKETT, JORDAN on 11/12/2017.
//  Copyright © 2017 BLACKETT, JORDAN. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import GameplayKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    //Plane Details
    var planeExists = false
    var mapExists = false
    
    // Map Settings
    var mapNode = SCNNode()
    var spawnPosition = SCNVector3()

    // Game Settings
    var gameStart = false
    var gameTimer = Timer()
    
    // Enemies and tower containers
    var enemies: [Enemy] = []
    var towers: [Tower] = []
    
    // Map enemies waypoints = [0.1, 0.05] -> [0.1, 0.25]
    var mapWayPointsX: [Float] = [0.1, 0.1, 0.2, 0.2, 0.15, 0.15, 0.25, 0.25, 0.3] // = Array<Array<Int>>()
    var mapWayPointsY: [Float] = [0.05, 0.25, 0.25, 0.15, 0.15, 0.05, 0.05, 0.25, 0.25]
    
    // UI - Labeles + Variables
    var wave = 0
    var numOfEnemiesWave: [Int] = [10, 15, 20, 30, 40]
    var EnemiesKilledThisWave = 0
    @IBOutlet weak var Wave: UILabel!
    var health = 100
    @IBOutlet weak var Health: UILabel!
    var gold = 120
    @IBOutlet weak var Gold: UILabel!
    @IBOutlet weak var Enemies: UILabel!
    @IBOutlet weak var searchLbl: UILabel!
    @IBOutlet weak var selectTowerView: UIView!
    @IBOutlet weak var CurrentSelectedTowerLbl: UILabel!
    @IBOutlet weak var TowerSelectBtn: UIButton!
    
    var currentTower = towerSelected()
    struct towerSelected
    {
        // Selected Tower
        var towerID = 0
        
        // Tower Stats
        var damageStats: [Int] = [10, 5, 20, 15, 25, 25]
        var fireRateStats: [Float] = [0.50, 0.25, 1.25, 0.75, 1.25, 0.25]
        var rangeStats: [Float] = [0.75, 0.50, 1, 1.25, 0.50, 1.25]
        var costStats: [Int] = [10, 25, 50, 75, 100, 125]
        
        var colourStats: [UIColor] = [UIColor.blue, UIColor.cyan, UIColor.magenta, UIColor.purple, UIColor.orange, UIColor.green]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Debug
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.debugOptions  = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Shows fps rate
        self.sceneView.showsStatistics = true
        self.sceneView.automaticallyUpdatesLighting = true
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Spawn timers
        gameTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        gameTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(self.spawn), userInfo: nil, repeats: true)
        
        // Hide select tower view
        selectTowerView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Plane Detecion
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func unloadGame()
    {
        // Stop timers
        gameTimer.invalidate()

        // Clear containers
        towers.removeAll()
        enemies.removeAll()
        EnemyStore.sharedInstance.activeEnemies.removeAll()
        
        // Reset Settings
        health = 100
        wave = 0
        gold = 120
        
        planeExists = false
        mapExists = false
    }
    
    // Game Update Tick
    @objc func tick()
    {
        moveEnemies()
        towerRange()
        
        // Start new wave
        if(numOfEnemiesWave[wave] == EnemiesKilledThisWave && wave < numOfEnemiesWave.count-1)
        {
            //
            wave += 1
            Wave.text = "Wave: " + String(wave+1)
            gold += 5
            Gold.text = "Gold: " +  String(gold)
            Enemies.text = "Enemies: " + String(numOfEnemiesWave[wave])
            EnemiesKilledThisWave = 0
            
            // New Wave
            NextWave()
        }
        
        // Game Over
        if(health <= 0)
        {
            // End Game
            self.performSegue(withIdentifier: "GameOverSeque", sender: nil)
            unloadGame()
        }
        
        // End Game - No more waves
        if(wave == numOfEnemiesWave.count-1 && numOfEnemiesWave[wave] == EnemiesKilledThisWave)
        {
            // End Game
            self.performSegue(withIdentifier: "WinScreenSeque", sender: nil)
            unloadGame()
        }
        
        // Trigger Text - Change change text in plane thread
        if(!gameStart && mapExists)
        {
            searchLbl.text = "> Place a tower to begin <"
            
            // Show UI
            Wave.isHidden = false
            Health.isHidden = false
            Enemies.isHidden = false
            Gold.isHidden = false
            TowerSelectBtn.isHidden = false
            CurrentSelectedTowerLbl.isHidden = false
        }
    }
    
    @objc func spawn()
    {
        // Spawn next enemy
        spawnEnemy()
    }
    
    func moveEnemies()
    {
        var temp = 0 // Array doesn't include a removeobject function
        for a in EnemyStore.sharedInstance.activeEnemies
        {
            searchLbl.text = ""
            a.move()
            
            // Enemy reached the end
            if(a.atEndOfMap())
            {
                // Damage Player
                health -= 10
                Health.text = "Health: " +  String(health)
                
                // Delete Enemy
                RemoveEnemy(enemy: a, id: temp, gold1: 0)
            }
            
            // Enemy Died
            if(a.getIsDead())
            {
                // Delete Enemy
                RemoveEnemy(enemy: a, id: temp, gold1: 2)
            }
            
            temp += 1
        }
    }
    
    func RemoveEnemy(enemy: Enemy, id: Int, gold1: Int)
    {
        EnemyStore.sharedInstance.activeEnemies.remove(at: id)
        enemy.enemyNode.removeFromParentNode()
        EnemiesKilledThisWave += 1
        
        gold += gold1
        Gold.text = "Gold: " +  String(gold)
        
        Enemies.text = "Enemies: " + String(numOfEnemiesWave[wave] - EnemiesKilledThisWave)
    }
    
    // New Wave
    func NextWave()
    {
        initEnemies(position: spawnPosition)
    }
    
    // Check if an enemies is in within range
    func towerRange()
    {
        for t in towers
        {
            for a in EnemyStore.sharedInstance.activeEnemies
            {
                t.findTartget(target: a)
            }
        }
    }
    
    // Spawn
    func spawnEnemy()
    {
        if(enemies.isEmpty)
        {
            return
        }
        
        let enemy = enemies[0]
        mapNode.addChildNode(enemy.enemyNode)
        EnemyStore.sharedInstance.activeEnemies.append(enemy)
        enemies.remove(at: 0)
    }
    
    // Init wave enemies
    func initEnemies(position: SCNVector3)
    {
        for i in 0..<numOfEnemiesWave[wave]
        {
            let enemy = Enemy(id: i,mapCoords: position, pointsX: mapWayPointsX, pointsY: mapWayPointsY)
            enemies.append(enemy)
        }
        
    }
    
    // Removed - Not used
    func placeWaypointNodes(position: SCNVector3)
    {
        for i in 0..<mapWayPointsX.count
        {
            //Create Cube
            let cube = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents = UIColor.green
            
            let cubeNode = SCNNode(geometry: cube)
            
            //cubeNode.position = SCNVector3((position.x - 14) + mapWayPointsX[i], 0, (position.z - 14) + mapWayPointsY[i])
            cubeNode.position = SCNVector3(position.x, position.y, position.z)
            
            let node = SCNNode()
            node.addChildNode(cubeNode)
            node.position = SCNVector3((position.x - 14) + mapWayPointsX[i], 0, (position.z - 14) + mapWayPointsY[i])
            
            mapNode.addChildNode(node)
        }
    }
    
    func initWaypoints()
    {
        for _ in 0..<mapWayPointsX.count
        {
            //Create Cube
            let cube = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents = UIColor.green
            
            let cubeNode = SCNNode(geometry: cube)
            
            let node = SCNNode()
            node.addChildNode(cubeNode)
            
            mapNode.addChildNode(node)
        }
    }
    
    // ARKit detects new plane
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if(!mapExists){
            // Check if anchor is plane
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
            let planeNode = VirtualPlane(anchor: planeAnchor)
            
            let mapPosition = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
            spawnPosition = mapPosition
            
            // ARKit owns the node corresponding to the anchor, so make the plane a child node.
            node.addChildNode(planeNode)
            
            mapNode = node
            
            // Start Game
            mapExists = true
        }
    }
    
    /*  - Required for AR testing however not used for the game -
     
    // Called when a node has been updated with data from the given anchor.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //let planeNode = VirtualPlane(anchor: planeAnchor)
       // Plane *plane = [self.planes objectForKey:anchor.identifier];
       // if (plane == nil) {
        //    return;
        //}
        
        // When an anchor is updated we need to also update our 3D geometry too. For example
        // the width and height of the plane detection may have changed so we need to update
        // our SceneKit geometry to match that
       // [plane update:(ARPlaneAnchor *)anchor];
        
       // guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Remove existing plane nodes
       // node.enumerateChildNodes {
       //     (childNode, _) in
       //     childNode.removeFromParentNode()
       // }
        
        
       // let planeNode = VirtualPlane(anchor: planeAnchor)
        
       // node.addChildNode(planeNode)
    }
 
    // When a detected plane is removed, remove the planeNode
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        //guard anchor is ARPlaneAnchor else { return }
        
        // Remove existing plane nodes
        //node.enumerateChildNodes {
        //    (childNode, _) in
        //    childNode.removeFromParentNode()
        //}
    }
    */
    
    struct myCameraCoordinates {
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func getCameraCoordinates(sceneView: ARSCNView) -> myCameraCoordinates
    {
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        let cameraCoordinates = MDLTransform(matrix: cameraTransform!)
        
        var cc = myCameraCoordinates()
        cc.x = cameraCoordinates.translation.x
        cc.y = cameraCoordinates.translation.y
        cc.z = cameraCoordinates.translation.z
        
        return cc
    }
    
    // Select Tower View
    @IBAction func addTower(_ sender: Any) {
        selectTowerView.isHidden = !selectTowerView.isHidden
    }
    
    //
    @IBAction func SelectTowerClose(_ sender: Any) {
        selectTowerView.isHidden = true
    }

    // Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(gold >= currentTower.costStats[currentTower.towerID])
        {
            gold -= currentTower.costStats[currentTower.towerID]
            Gold.text = "Gold: " +  String(gold)

            //ViewController.worldPositionFromScreenPosition(_:objectPos:infinitePlane:)
            guard let touch = touches.first else { return }
            let location = touch.location(in: sceneView)
            
            // Place tower where player touched - only on detected planes
            let hitResults = sceneView.hitTest(location, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
            if(hitResults.count > 0)
            {
                let result: ARHitTestResult = hitResults.first!
                // if var planeAnchor = result.anchor as? ARPlaneAnchor
                if (result.anchor as? ARPlaneAnchor) != nil
                {
                    //planeAnchor.center.x
                    // Hit Plane
                    let pointTransform = SCNMatrix4(result.worldTransform)
                    let pointVector = SCNVector3Make(pointTransform.m41, pointTransform.m42, pointTransform.m43)
                    
                    createTower(position: pointVector)
                }
            }
        }
        
        if(!gameStart)
        {
            // Start Game
            initEnemies(position: spawnPosition)
            gameStart = true
        }
    }
    
    func createTower(position: SCNVector3)
    {
        //Create Cube
        let tower = Tower(mapCoords: position, towerDamage: currentTower.damageStats[currentTower.towerID],
                          towerFireSpeed: currentTower.fireRateStats[currentTower.towerID],
                          towerRange: currentTower.rangeStats[currentTower.towerID],
                          towerColour: currentTower.colourStats[currentTower.towerID])
        
        towers.append(tower)
        sceneView.scene.rootNode.addChildNode(tower.projectileNode)
        sceneView.scene.rootNode.addChildNode(tower.towerNode)
    }
    
    // Select Tower Btns + Lbls
    @IBOutlet weak var BasicTowerNameLbl: UILabel!
    @IBAction func BasicTowerBtn(_ sender: Any) {
        currentTower.towerID = 0
        CurrentSelectedTowerLbl.text = BasicTowerNameLbl.text
        selectTowerView.isHidden = true
    }
    
    @IBOutlet weak var RapidTowerLbl: UILabel!
    @IBAction func RapidTowerBtn(_ sender: Any) {
        currentTower.towerID = 1
        CurrentSelectedTowerLbl.text = RapidTowerLbl.text
        selectTowerView.isHidden = true
    }
    
    @IBOutlet weak var CannonTowerLbl: UILabel!
    @IBAction func CannonTowerBtn(_ sender: Any) {
        currentTower.towerID = 2
        CurrentSelectedTowerLbl.text = CannonTowerLbl.text
        selectTowerView.isHidden = true
    }
    
    @IBOutlet weak var LightingTowerLbl: UILabel!
    @IBAction func LightingTowerBtn(_ sender: Any) {
        currentTower.towerID = 3
        CurrentSelectedTowerLbl.text = LightingTowerLbl.text
        selectTowerView.isHidden = true
    }
    
    @IBOutlet weak var BigTowerLbl: UILabel!
    @IBAction func BigTowerBtn(_ sender: Any) {
        currentTower.towerID = 4
        CurrentSelectedTowerLbl.text = BigTowerLbl.text
        selectTowerView.isHidden = true
    }
    
    @IBOutlet weak var MegaTowerLbl: UILabel!
    @IBAction func MegaTowerBtn(_ sender: Any) {
        currentTower.towerID = 5
        CurrentSelectedTowerLbl.text = MegaTowerLbl.text
        selectTowerView.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
