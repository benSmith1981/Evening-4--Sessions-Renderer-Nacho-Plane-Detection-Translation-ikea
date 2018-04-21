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
//    var candle: Furniture = Furniture.init(itemName: "candle")

    var cameraOrientation: SCNVector3?
    var cameraLocation: SCNVector3?
    var currentPositionOfCamera: SCNVector3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        config.planeDetection = .horizontal
//        config.planeDetection = .vertical
        self.sceneView.session.run(config)
        
        let tapGest = UITapGestureRecognizer.init(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGest)
        
        let panGest = UIPanGestureRecognizer.init(target: self, action: #selector(moveObject))
        self.sceneView.addGestureRecognizer(panGest)

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
    @objc func moveObject(sender: UIPanGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! ARSCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        
        let hittest = sceneViewTappedOn.hitTest(touchCoordinates)
        let arHitTestResult = sceneView.hitTest(touchCoordinates, types: .existingPlane)
        let hitTestPlane = sceneViewTappedOn.hitTest(touchCoordinates, types: .existingPlaneUsingExtent)

//        for result in hittest {
//            let node = result.node
//            if let name = node.name {
//                print("******************************"+name)
//            }
//        }
//        if !hittest.isEmpty && !arHitTestResult.isEmpty , let results = hittest.first {
        if !arHitTestResult.isEmpty , let results = hittest.first {

            let hit = arHitTestResult.first!

            let node = results.node
//            if let parent = node.parent {
//
//                parent.simdTransform = hit.worldTransform
//            }
            
            if sender.state == .changed || sender.state == .began {
                
                if let myNode = node.parentOfType() as? Furniture {
                    // do something
                    print("******************************parentOfType"+myNode.name!)

                }
                if let node = node.parent as? Furniture {
                    print("******************************Got furnitue node"+node.name!)

                }
                if let node = node as? Furniture {
                    print("******************************Got furnitue node"+node.name!)
                    
                }
                if let name = node.name {
                    print("******************************"+name)
                }
                if let parent = node.parent {
                    if let parentNAme = parent.name {
                        print("******************************"+parentNAme)
                        let tappedNode = furnitureNodes.filter { (node) -> Bool in
                            print("******************************"+node.name!)
                            return node.name == parentNAme
                        }
                        tappedNode[0].setTransform(hit.worldTransform)

                    }

//                    let translation = sender.translation(in: sceneViewTappedOn)
//                    let vector = self.sceneView.unprojectPoint(SCNVector3Make(Float(translation.x),
//                                                                              0,
//                                                                              Float(-translation.y)))
//                    let matrix = results.worldCoordinates
////                    let vector = SCNVector3Make(matrix.m41, parent.position.y, matrix.m43)
//
//                    let position = SCNVector3.init(vector.x,
//                                                   Float(parent.position.y),
//                                                   vector.z)
//
//                    parent.position = vector
//                    let moveBy = SCNAction.move(by: vector, duration: 1)
//                    parent.runAction(moveBy)
//                    parent.position = position
//                    parent.enumerateChildNodes { (childNode, _) in
//                        childNode.position = position
//                    }
                }
                
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
            }
            
        }
        
        //test for one type of hit
        let hitTestPlane = sceneViewTappedOn.hitTest(touchCoordinates, types: .existingPlaneUsingExtent)
        if !hitTestPlane.isEmpty, let results = hitTestPlane.first {
            
            addItem(anchorPlane: results.anchor!, touchCoordinates: (hittest.first?.worldCoordinates)!)
        }

        
    }
    
    func addItem(anchorPlane: ARAnchor, touchCoordinates: SCNVector3) {
        let node = Furniture.init(itemName: "candle")
        print(node.contentRootNode.name)

        node.setTransform(anchorPlane.transform)
        furnitureNodes.append(node)
        self.sceneView.scene.rootNode.addChildNode(node)
        //we are adding the candle on the plane, whereever the camera is pointing, ignoring the cameras y position, but paying attention to the z and the x position

        
        let transform = anchorPlane.transform
        let location = transform.columns.3
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
