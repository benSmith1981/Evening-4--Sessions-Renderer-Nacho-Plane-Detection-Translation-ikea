//
//  Zombie.swift
//  HelloARWorld
//
//  Created by ben on 28/10/2017.
//  Copyright © 2017 ben. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class Zombie: SCNNode {
    
    //this holds all the differnet types of animations
    var animations = [String: CAAnimation]()
    //Is the animation idle or not
    var idle:Bool = true
    var transition:Bool = false
    var walking:Bool = true
    var zombieIsTurning = false
    var currentRotation: CGFloat = CGFloat.pi

    private var idleAnimation: SCNAnimation?
    private var walkingAnimation: SCNAnimation?
    private var turnRightAnimation: SCNAnimation?
    private var turnLeftAnimation: SCNAnimation?
    private var transitionAnimation: SCNAnimation?
    private var attackAnimation: SCNAnimation?
    private var agonizingAnimation: SCNAnimation?
    private var runningAnimation: SCNAnimation?
    
    private var head: SCNNode!
    private var geometryRoot: SCNNode!
    private var focusOfTheHead = SCNNode()
    private let focusNodeBasePosition = simd_float3(0, 0.1, 0.25)
    private var headIsMoving: Bool = false
    private var lastRelativePosition: RelativeCameraPositionToHead = .tooHighOrLow
    private var lastDistance: Float = Float.greatestFiniteMagnitude
    // Enums to describe the current state
    private enum RelativeCameraPositionToHead {
        case withinFieldOfView(Distance)
        case needsToTurnLeft
        case needsToTurnRight
        case tooHighOrLow
        
        var rawValue: Int {
            switch self {
            case .withinFieldOfView(_) : return 0
            case .needsToTurnLeft : return 1
            case .needsToTurnRight: return 2
            case .tooHighOrLow : return 3
            }
        }
    }
    private enum Distance {
        case outsideTargetLockDistance
        case withinTargetLockDistance
    }
    
    let contentRootNode = SCNNode()
    var id: String = ""

    init(itemName: String) {
        super.init()
        id = "\(itemName)\(UUID.init())"

        /*
        guard let virtualObjectScene = SCNScene(named: "ZombieIdle", inDirectory: "art.scnassets/ZombieIdle/") else {
            return
        }
 */
        if let scene = SCNScene.init(named: "Art.scnassets/\(itemName)/\(itemName).dae") {
//            self.setName(itemName: id)
//            self.contentRootNode.setName(itemName: id)
            let wrapperNode = SCNNode()
//            wrapperNode.setName(itemName: id)
            
            for child in scene.rootNode.childNodes {
//                child.setName(itemName: id)
                wrapperNode.addChildNode(child)
            }
            contentRootNode.addChildNode(wrapperNode)
            self.addChildNode(contentRootNode)

            self.scale = SCNVector3(0.005, 0.005, 0.005)
            self.position = SCNVector3(0,-0.5,-0.5)
//            contentRootNode.position = SCNVector3(0,0,-1)
//
            setupSpecialNodes()
            setupConstraints()
            preloadAnimations()
        }
    }
    
    private func setupSpecialNodes() {
        geometryRoot = contentRootNode.childNode(withName: "Zombie_Geo", recursively: true)
        head = contentRootNode.childNode(withName: "Zombie_Head", recursively: true)
        focusOfTheHead.simdPosition = focusNodeBasePosition
        geometryRoot.addChildNode(focusOfTheHead)

    }
    
    private func setupConstraints() {
        // Set up constraints for head movement
        let headConstraint = SCNLookAtConstraint(target: focusOfTheHead)
        headConstraint.isGimbalLockEnabled = true
        head?.constraints = [headConstraint]
    }
    
    func reactToRendering(in sceneView: ARSCNView) {
        // Update environment map to match ambient light level
//        lightingEnvironment.intensity = (sceneView.session.currentFrame?.lightEstimate?.ambientIntensity ?? 1000) / 100
        
        guard !zombieIsTurning, let pointOfView = sceneView.pointOfView else {
            return
        }
        
        let localTarget = focusOfTheHead.parent!.simdConvertPosition(pointOfView.simdWorldPosition, from: nil)
//        followUserWithEyes(to: localTarget)
        
        // Obtain relative position of the head to the camera and act accordingly.
        let relativePos = self.relativePositionToHead(pointOfViewPosition: pointOfView.simdPosition)
        switch relativePos {
        case .withinFieldOfView(let distance):
            handleWithinFieldOfView(localTarget: localTarget, distance: distance)
        case .needsToTurnLeft:
            followUserWithHead(to: simd_float3(0.4, focusNodeBasePosition.y, focusNodeBasePosition.z))
//            triggerTurnLeftCounter += 1
//            if triggerTurnLeftCounter > 150 {
//                triggerTurnLeftCounter = 0
//                if let anim = turnLeftAnimation {
//                    playTurnAnimation(anim)
//                }
//            }
        case .needsToTurnRight:
            followUserWithHead(to: simd_float3(-0.4, focusNodeBasePosition.y, focusNodeBasePosition.z))
//            triggerTurnRightCounter += 1
//            if triggerTurnRightCounter > 150 {
//                triggerTurnRightCounter = 0
//                if let anim = turnRightAnimation {
//                    playTurnAnimation(anim)
//                }
//            }
        case .tooHighOrLow:
            followUserWithHead(to: focusNodeBasePosition)
        }
    }
    
    private func handleWithinFieldOfView(localTarget: simd_float3, distance: Distance) {
//        triggerTurnLeftCounter = 0
//        triggerTurnRightCounter = 0
        switch distance {
        case .outsideTargetLockDistance:
            followUserWithHead(to: localTarget)
        case .withinTargetLockDistance:
            followUserWithHead(to: localTarget, instantly: true)
//        case .withinShootTongueDistance:
//            followUserWithHead(to: localTarget, instantly: true)
//            if mouthAnimationState == .mouthClosed {
//                readyToShootCounter += 1
//                if readyToShootCounter > 30 {
//                    openCloseMouthAndShootTongue()
//                }
//            } else {
//                readyToShootCounter = 0
//            }
        }
    }
    
    private func followUserWithHead(to target: simd_float3, instantly: Bool = false) {
        guard !headIsMoving else { return }
        headIsMoving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            let moveToTarget = SCNAction.move(to: SCNVector3(target.x, target.y, target.z), duration: 0.5)
            self.focusOfTheHead.runAction(moveToTarget, completionHandler: {
                self.headIsMoving = false
            })
        })
    }
    
    private func relativePositionToHead(pointOfViewPosition: simd_float3) -> RelativeCameraPositionToHead {
        // Compute angles between camera position and chameleon
        let cameraPosLocal = head.simdConvertPosition(pointOfViewPosition, from: nil)
        let cameraPosLocalComponentX = simd_float3(cameraPosLocal.x, head.position.y, cameraPosLocal.z)
        let dist = simd_length(cameraPosLocal - head.simdPosition)
        
        let xAngle = acos(simd_dot(simd_normalize(head!.simdPosition), simd_normalize(cameraPosLocalComponentX))) * 180 / Float.pi
        let yAngle = asin(cameraPosLocal.y / dist) * 180 / Float.pi
        
        let selfToUserDistance = simd_length(pointOfViewPosition - head.simdWorldPosition)
        
        var relativePosition: RelativeCameraPositionToHead
        
        if yAngle > 60 {
            relativePosition = .tooHighOrLow
        } else if xAngle > 60 {
            relativePosition = cameraPosLocal.x < 0 ? .needsToTurnLeft : .needsToTurnRight
        } else {
            var distanceCategory: Distance = .outsideTargetLockDistance
            
            switch selfToUserDistance {
//            case 0..<0.3:
//                break
//                distanceCategory = .withinShootTongueDistance
            case 0.3..<0.45:
                break
                distanceCategory = .withinTargetLockDistance
//                if lastDistance > 0.45 || lastRelativePosition.rawValue > 0 {
//                    didEnterTargetLockDistance = true
//                }
            default:
                distanceCategory = .outsideTargetLockDistance
            }
            relativePosition = .withinFieldOfView(distanceCategory)
        }
        
        lastDistance = selfToUserDistance
        lastRelativePosition = relativePosition
        return relativePosition
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addToNode(rootNode: SCNNode) {

    }
    
    func setTransform(_ transform: simd_float4x4) {
        contentRootNode.simdTransform = transform
    }
    
    func preloadAnimations() {
        idleAnimation = SCNAnimation.fromFile(named: "ZombieIdle", inDirectory: "Art.scnassets/ZombieIdle/")
        idleAnimation?.repeatCount = -1
        
        turnRightAnimation = SCNAnimation.fromFile(named: "ZombieRightTurn", inDirectory: "Art.scnassets/ZombieRightTurn/")
        turnRightAnimation?.repeatCount = 1
        turnRightAnimation?.blendInDuration = 0.3
        turnRightAnimation?.blendOutDuration = 0.3
        
        turnLeftAnimation = SCNAnimation.fromFile(named: "ZombieLeftTurn", inDirectory: "Art.scnassets/ZombieLeftTurn/")
        turnLeftAnimation?.repeatCount = 1
        turnLeftAnimation?.blendInDuration = 0.3
        turnLeftAnimation?.blendOutDuration = 0.3
        
        walkingAnimation = SCNAnimation.fromFile(named: "ZombieWalking", inDirectory: "Art.scnassets/ZombieWalking/")
        walkingAnimation?.repeatCount = 1
        walkingAnimation?.blendInDuration = 0.3
        walkingAnimation?.blendOutDuration = 0.3
        
        transitionAnimation = SCNAnimation.fromFile(named: "ZombieTransition", inDirectory: "Art.scnassets/ZombieTransition/")
        transitionAnimation?.repeatCount = 1
        transitionAnimation?.blendInDuration = 0.3
        transitionAnimation?.blendOutDuration = 0.3
        
        attackAnimation = SCNAnimation.fromFile(named: "ZombieAttack", inDirectory: "Art.scnassets/ZombieAttack/")
        attackAnimation?.repeatCount = 1
        attackAnimation?.blendInDuration = 0.3
        attackAnimation?.blendOutDuration = 0.3
        
        agonizingAnimation = SCNAnimation.fromFile(named: "ZombieAgonizing", inDirectory: "Art.scnassets/ZombieAgonizing/")
        agonizingAnimation?.repeatCount = 1
        agonizingAnimation?.blendInDuration = 0.3
        agonizingAnimation?.blendOutDuration = 0.3
        
        runningAnimation = SCNAnimation.fromFile(named: "ZombieRunning", inDirectory: "Art.scnassets/ZombieRunning/")
        runningAnimation?.repeatCount = 1
        runningAnimation?.blendInDuration = 0.3
        runningAnimation?.blendOutDuration = 0.3
        
        // Start playing idle animation.
        if let anim = idleAnimation {
            contentRootNode.childNodes[0].addAnimation(anim, forKey: anim.keyPath)
        }
    }
    
    func playTransitionAnimation() {
        let modelBaseNode = contentRootNode.childNodes[0]
        self.transition = true

        if let transitionAnimation = transitionAnimation {
            modelBaseNode.addAnimation(transitionAnimation, forKey: transitionAnimation.keyPath)
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            SCNTransaction.animationDuration = transitionAnimation.duration
            SCNTransaction.completionBlock = {
                self.transition = false
                if !self.zombieIsTurning  {
//                    self.playTurnAnimation()

                } else {
                    self.idle = true

                }
            }
            SCNTransaction.commit()
        }
        

        /*
         if animation == turnRightAnimation {
         rotationAngle = Float.pi / 4
         } else if animation == turnRightAnimation {
         rotationAngle = -Float.pi / 4
         }
         */
        
    }
    func playTurnAnimation() {
        var rotationAngle = -Float.pi / 6
        zombieIsTurning = true

        if let turnRightAnimation = turnRightAnimation {
            let modelBaseNode = contentRootNode.childNodes[0]
            modelBaseNode.addAnimation(turnRightAnimation, forKey: turnRightAnimation.keyPath)
            
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            SCNTransaction.animationDuration = turnRightAnimation.duration
            modelBaseNode.transform = SCNMatrix4Mult(modelBaseNode.presentation.transform, SCNMatrix4MakeRotation(rotationAngle, 0, 1, 0))
            SCNTransaction.completionBlock = {
//                self.playTransitionAnimation()
                self.zombieIsTurning = false
                self.transition = true

            }
            SCNTransaction.commit()
        }
/*
        if animation == turnRightAnimation {
            rotationAngle = Float.pi / 4
        } else if animation == turnRightAnimation {
            rotationAngle = -Float.pi / 4
        }
        */

    }
    
    func playWalkingAnimation() {
        var distance: Float = 1.0
        if let walkingAnimation = walkingAnimation{
            let modelBaseNode = contentRootNode.childNodes[0]
            modelBaseNode.addAnimation(walkingAnimation, forKey: walkingAnimation.keyPath)
            
            walking = true
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            SCNTransaction.animationDuration = walkingAnimation.duration
            modelBaseNode.transform = SCNMatrix4Mult(modelBaseNode.presentation.transform, SCNMatrix4MakeTranslation(0, 0, distance))
            SCNTransaction.completionBlock = {
                self.walking = false
            }
            SCNTransaction.commit()
        }

    }
    
    func loadAnimations () {
        // Load the character in the idle animation
//        let idleScene = SCNScene(named: "art.scnassets/ZombieIdle/ZombieIdle.dae")!
//        let idleScene = SCNScene(named: "art.scnassets/Pirate/Pirate.scn")!
//        let idleScene = SCNScene(named: "art.scnassets/PirateAnimation/PirateAnimation.dae")!

        //        let idleScene = SCNScene(named: "art.scnassets/ZombieTransition/ZombieTransition.dae")!
        
        // This node will be parent of all the animation models
        
        // Add all the child nodes to the parent node
/*        for child in idleScene.rootNode.childNodes {
            worldSceneNode.addChildNode(child)
        }
 */
        // Set up some properties
//        worldSceneNode.position = SCNVector3(0, -1, -1)
//        worldSceneNode.scale = SCNVector3(0.6,0.6,0.6)

        // Add the node to the scene
        //        sceneView.scene.rootNode.addChildNode(node)
        
        // Load all the DAE animations
//        loadAnimation(withKey: "transition", sceneName: "art.scnassets/PirateAnimation/PirateAnimation", animationIdentifier: "pirate_animation_v003-anim")
//        loadAnimation(withKey: "transition", sceneName: "art.scnassets/SharkAnimation/SharkAnimation", animationIdentifier: "Shark_resized_animation_v003-anim")
//        loadAnimation(withKey: "idle", sceneName: "art.scnassets/SharkAnimation/SharkAnimation", animationIdentifier: "Shark_resized_animation_v003-anim")
//        loadAnimation(withKey: "walking", sceneName: "art.scnassets/SharkAnimation/SharkAnimation", animationIdentifier: "Shark_resized_animation_v003-anim")
//        
        
        
        //PIRATE
//        loadAnimation(withKey: "transition", sceneName: "art.scnassets/PirateAnimation/PirateAnimation", animationIdentifier: "pirate_animation_v003-anim")
//        loadAnimation(withKey: "walking", sceneName: "art.scnassets/PirateAnimation/PirateAnimation", animationIdentifier: "pirate_animation_v003-anim")
        
        
        
        ///ZOMBIE
        loadAnimation(withKey: "idle", sceneName: "art.scnassets/ZombieIdle/ZombieIdle", animationIdentifier: "Zombie_Hips-anim")

        loadAnimation(withKey: "transition", sceneName: "art.scnassets/ZombieTransition/ZombieTransition", animationIdentifier: "Zombie_Hips-anim")

        loadAnimation(withKey: "walking", sceneName: "art.scnassets/Walking/Walking-1", animationIdentifier: "Walking-1-1")

    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) {
        
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will only play once
            animationObject.repeatCount = 1
            animationObject.autoreverses = true
            // To create smooth transitions between animations
//            animationObject.fadeInDuration = CGFloat(1)
//            animationObject.fadeOutDuration = CGFloat(1)
            
            // Store the animation for later use
            animations[withKey] = animationObject
        }
    }
    
    func addStaticZombie(_ sender: Any) {
        guard let virtualObjectScene = SCNScene(named: "zombie.dae", inDirectory: "art.scnassets/zombie") else {
            return
        }

        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        wrapperNode.scale = SCNVector3(0.01, 0.01, 0.01)
        
    }
}
