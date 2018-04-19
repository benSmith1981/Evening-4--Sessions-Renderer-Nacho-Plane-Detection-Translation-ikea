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
    
    var cameraOrientation: SCNVector3?
    var cameraLocation: SCNVector3?
    var currentPositionOfCamera: SCNVector3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
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
    
    @objc func moveObject(sender: UIPanGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! ARSCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        
        let hittest = sceneViewTappedOn.hitTest(touchCoordinates)
        if !hittest.isEmpty, let results = hittest.first {
            let node = results.node
            let translation = sender.translation(in: sceneViewTappedOn)
            let position = SCNVector3.init(CGFloat(node.position.x) + CGFloat(translation.x),
                                           CGFloat(node.position.y),
                                           CGFloat(node.position.z) +  CGFloat(translation.y))
            node.enumerateChildNodes { (childNode, _) in
                childNode.position = position
            }
            if sender.state == .changed {

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
                print(name)
            }
            
        }
        
        //test for one type of hit
        let hitTestPlane = sceneViewTappedOn.hitTest(touchCoordinates, types: .existingPlaneUsingExtent)
        if !hitTestPlane.isEmpty, let results = hitTestPlane.first {
            addItem(anchorPlane: results.anchor!)
        }

        
    }
    
    func addItem(anchorPlane: ARAnchor) {
        let node = Furniture.init(itemName: "candle")
        let transform = anchorPlane.transform
        let location = transform.columns.3
        //we are adding the candle on the plane, whereever the camera is pointing, ignoring the cameras y position, but paying attention to the z and the x position
        if let cameraLocation = cameraLocation {
            node.position = SCNVector3.init(location.x + cameraLocation.x, location.y, location.z + cameraLocation.z)
        }

        
        self.sceneView.scene.rootNode.addChildNode(node)
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

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
