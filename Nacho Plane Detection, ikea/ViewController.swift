//
//  ViewController.swift
//  Nacho Plane Detection, ikea
//
//  Created by Ben Smith on 19/04/2018.
//  Copyright © 2018 Ben Smith. All rights reserved.
//

import UIKit
import ARKit
import Foundation
class ViewController: UIViewController {

    @IBOutlet weak var detectedLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    @IBOutlet weak var sessionInfoLabel: UILabel!
    var furnitureNodes: [Furniture] = []
    var zombies: [Zombie] = []

    var selectedModel: String = "ZombieIdle"
//    var candle: Furniture = Furniture.init(itemName: "candle")

    var cameraOrientation: SCNVector3?
    var cameraLocation: SCNVector3?
    var currentPositionOfCamera: SCNVector3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        config.planeDetection = .horizontal
        self.sceneView.autoenablesDefaultLighting = true
//        config.planeDetection = .vertical
        self.sceneView.session.run(config)
        
        let tapGest = UITapGestureRecognizer.init(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGest)
        
        let panGest = UIPanGestureRecognizer.init(target: self, action: #selector(moveObject))
        self.sceneView.addGestureRecognizer(panGest)

        
        let pinchGest = UIPinchGestureRecognizer.init(target: self, action: #selector(pinched(sender:)))
        self.sceneView.addGestureRecognizer(pinchGest)

        let rotate = UIRotationGestureRecognizer.init(target: self, action: #selector(rotate(sender:)))
        self.sceneView.addGestureRecognizer(rotate)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//    @objc func moveObject(_ recognizer: UIPanGestureRecognizer) {
//        let sceneViewTappedOn = recognizer.view as! ARSCNView
//        let location = recognizer.location(in: sceneViewTappedOn)
//
//        // Drag the object on an infinite plane
//        let arHitTestResult = sceneView.hitTest(location, types: .existingPlane)
//        let hittest = sceneViewTappedOn.hitTest(location)
//
//        if !arHitTestResult.isEmpty {
//            let hit = arHitTestResult.first!
//            chameleon.setTransform(hit.worldTransform)
//
//            if recognizer.state == .ended {
//                chameleon.reactToPositionChange(in: sceneView)
//            }
//        }
//    }
//
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            let pinchACtion = SCNAction.scale(by: sender.scale, duration: 0)
            node.parent?.enumerateChildNodes { (childnode, _) in
                childnode.runAction(pinchACtion)
            }
            sender.scale = 1.0
        }
    }
    
    @objc func moveObject(sender: UIPanGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! ARSCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        
        let hittest = sceneViewTappedOn.hitTest(touchCoordinates)
        let arHitTestResult = sceneView.hitTest(touchCoordinates, types: .existingPlane)
        let hitTestPlane = sceneViewTappedOn.hitTest(touchCoordinates, types: .existingPlaneUsingExtent)

        let xTranslation = sender.translation(in: sceneView).x
        var angle = (xTranslation * CGFloat.pi) / 200.0
        
//        for result in hittest {
//            let node = result.node
//            if let name = node.name {
//                print("******************************"+name)
//            }
//        }
        if !hittest.isEmpty , let results = hittest.first {
//        if !arHitTestResult.isEmpty , let results = hittest.first {

//            let hit = arHitTestResult.first!

            let node = results.node

            if sender.state == .changed || sender.state == .began {
                if let name = node.name {
                    print("******************************"+name)
                    let tappedNode = zombies.filter { (node) -> Bool in
                        print("******************************"+node.name!)
                        return node.name == name
                    }
                    if tappedNode.count > 0 {
                        tappedNode[0].currentRotation = angle
                        //                            tappedNode[0].setTransform(hit.worldTransform)
                    }
                    
                }
//                if let parent = node.parent {
//                    if let parentNAme = parent.name {
//                        print("******************************"+parentNAme)
//                        let tappedNode = zombies.filter { (node) -> Bool in
//                            print("******************************"+node.name!)
//                            return node.name == parentNAme
//                        }
//                        if tappedNode.count > 0 {
//                            angle += tappedNode[0].currentRotation
//                            tappedNode[0].rotation = SCNVector4.init(0, 1, 0, angle)
//
////                            tappedNode[0].setTransform(hit.worldTransform)
//                        }
//
//                    }
//                } else {
//                    if let name = node.name {
//                        print("******************************"+name)
//                        let tappedNode = zombies.filter { (node) -> Bool in
//                            print("******************************"+node.name!)
//                            return node.name == name
//                        }
//                        if tappedNode.count > 0 {
//                            tappedNode[0].currentRotation = angle
////                            tappedNode[0].setTransform(hit.worldTransform)
//                        }
//
//                    }
//                }
                
            }

        }
    }
    @objc func rotate(sender: UIRotationGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        

        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            
            
            if sender.state == .changed {
                
                let rotateAction = SCNAction.rotateBy(x: 0, y: sender.rotation, z: 0, duration: 1)
                rotateAction.speed = 0.9 * .pi
                node.parent?.enumerateChildNodes { (childnode, _) in
                    childnode.runAction(rotateAction)
                }
                sender.rotation = 0
                
                print("rotate gesture")
            } else if sender.state == .ended {
                node.removeAllActions()
            } else if sender.state == .cancelled {
                node.removeAllActions()
            }
            
        }
        
    }
    
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! ARSCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        
        let hittest = sceneViewTappedOn.hitTest(touchCoordinates)
        if !hittest.isEmpty, let results = hittest.first {
            let node = results.node
            if let name = node.name {
                print("******************************"+name)
                if let parent = node.parent {
                    if let parentNAme = parent.name {
                        print("******************************"+parentNAme)
//                        let tappedNode = furnitureNodes.filter { (node) -> Bool in
//                            print("******************************"+node.name!)
//                            return node.name == parentNAme
//                        }
//                        tappedNode[0].playAnimation()

                        let tappedNode = zombies.filter { (node) -> Bool in
//                            print("******************************"+node.name!)
                            return node.name == name
                        }
                        if tappedNode[0].idle {
                            tappedNode[0].playTransitionAnimation()

                        }
                        if tappedNode[0].transition {
                            tappedNode[0].playTurnAnimation()

                        }

                        return
                    }
                }
            }

        }
        
        //test for one type of hit
        let hitTestPlane = sceneViewTappedOn.hitTest(touchCoordinates, types: .existingPlaneUsingExtent)
        if !hitTestPlane.isEmpty, let results = hitTestPlane.first {
            addItem(anchorPlane: results.anchor!, touchCoordinates: (hittest.first?.worldCoordinates)!)
        }
        
    }
    
    func addItem(anchorPlane: ARAnchor, touchCoordinates: SCNVector3) {
//        let node = Furniture.init(itemName: self.selectedModel)
        let node = Zombie.init(itemName: self.selectedModel)

        print(node.contentRootNode.name)
        
        let transform = anchorPlane.transform
        let location = transform.columns.3

        node.setTransform(anchorPlane.transform)
//        furnitureNodes.append(node)
        zombies.append(node)

        self.sceneView.scene.rootNode.addChildNode(node)
        //we are adding the candle on the plane, whereever the camera is pointing, ignoring the cameras y position, but paying attention to the z and the x position


        //we are adding the candle on the plane, whereever the camera is pointing, ignoring the cameras y position, but paying attention to the z and the x position
        if let cameraLocation = cameraLocation {
//            node.setTransform(anchorPlane.transform)
//            node.position = SCNVector3.init(location.x + Float(touchCoordinates.x),
//                                            location.y,
//                                            location.z + Float(touchCoordinates.z))
        }
        
//        furnitureNodes.append(node)
//        
//        self.sceneView.scene.rootNode.addChildNode(node.contentRootNode)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func Shark(_ sender: Any) {
        self.selectedModel = "candle"
    }
    @IBAction func Pirate(_ sender: Any) {
        self.selectedModel = "chair"

    }
    @IBAction func PirateShip(_ sender: Any) {
        self.selectedModel = "cup"

    }
    @IBAction func pirateShipFlying(_ sender: Any) {
        self.selectedModel = "lamp"

    }
    
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        node.addChildNode(createLava(planeAnchor: planeAnchor))
        
        DispatchQueue.main.async {
            self.detectedLabel.text = "Plane detected"

            self.detectedLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.detectedLabel.isHidden = true
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        node.addChildNode(createLava(planeAnchor: planeAnchor))

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.detectedLabel.isHidden = false
            self.detectedLabel.text = "Did Remove Anchor"
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.detectedLabel.isHidden = true
            }
        }
    }
    
    //keep the camera position updated
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        //get the cameras current point of view
        guard let pointOfView = sceneView.pointOfView else { return }
        
        //get its transform matric
        let transform = pointOfView.transform
        
        //transform across Column 3 row 1, m31   , column 3 row 2, m32,     column 3 row 3, m33
        //Where ur phoen is facing, when you rotate phone around itselg
        cameraOrientation = SCNVector3.init(-transform.m31, -transform.m32, -transform.m33)
        
        //Moves translationally, when phone moves
        cameraLocation = SCNVector3.init(transform.m41, transform.m42, transform.m43)
        
        //combine orientation and location, get full location and direction
        currentPositionOfCamera = cameraOrientation! + cameraLocation!
    }
    
    func createLava(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let lava = SCNNode.init(geometry: SCNPlane.init(width: CGFloat(planeAnchor.extent.x),
                                                        height: CGFloat(planeAnchor.extent.z)))
        lava.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        lava.position = SCNVector3.init(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        lava.eulerAngles = SCNVector3.init(Double.pi / 2 , 0, 0)
        lava.geometry?.firstMaterial?.isDoubleSided = true
        return lava
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if zombies.count > 0 {
            zombies[0].reactToRendering(in: sceneView)
        }
    }
    
}


extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.sessionInfoLabel.text = error.localizedDescription
            self.sessionInfoLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.sessionInfoLabel.isHidden = true
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        DispatchQueue.main.async {
            self.sessionInfoLabel.isHidden = false
            switch camera.trackingState {
            case .normal:
                self.sessionInfoLabel.text = "Normal"
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    self.sessionInfoLabel.text = "excessiveMotion KEEP STILL"
//                    self.resetArWorld()
                case .initializing:
                    self.sessionInfoLabel.text = "initializing"
                case .insufficientFeatures:
                    self.sessionInfoLabel.text = "insufficientFeatures, Need more light"
                case .relocalizing:
                    self.sessionInfoLabel.text = "Resetting"
                }
            case .notAvailable:
                self.sessionInfoLabel.text = "Not Available"
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.sessionInfoLabel.isHidden = true
            }
        }

    }
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.sessionInfoLabel.isHidden = false
            self.sessionInfoLabel.text = "sessionWasInterrupted"

            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.sessionInfoLabel.isHidden = true
            }
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.sessionInfoLabel.isHidden = false
            self.sessionInfoLabel.text = "sessionInterruption   Ended"
            
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.sessionInfoLabel.isHidden = true
            }
        }
        resetArWorld()
    }
    
    func resetArWorld() {
        config.planeDetection = .horizontal
        self.sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: Gesture Recognized
extension ViewController {

}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
