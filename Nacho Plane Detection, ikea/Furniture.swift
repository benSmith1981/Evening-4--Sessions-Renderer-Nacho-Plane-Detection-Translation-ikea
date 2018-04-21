//
//  Furniture.swift
//  Nacho Plane Detection, ikea
//
//  Created by Ben Smith on 19/04/2018.
//  Copyright © 2018 Ben Smith. All rights reserved.
//

import Foundation
import ARKit

extension SCNNode {
    
    
    func setName(itemName: String) {
        self.name = itemName
    }
    
    
    func parentOfType<T: SCNNode>() -> T? {
        var node: SCNNode! = self
        repeat {
            if let node = node as? T { return node }
            node = node?.parent
        } while node != nil
        return nil
    }
}

class Furniture: SCNNode {
    var itemName: String?
    let contentRootNode = SCNNode()
    var id: String = ""
    init(itemName: String) {
        super.init()
        id = "\(itemName)\(UUID.init())"

        self.setName(itemName: id)
        self.contentRootNode.setName(itemName: id)
        print(self.contentRootNode.name)
//        print(self.rootNode.name)

        self.itemName = itemName
        if let scene = SCNScene.init(named: "Art.scnassets/\(itemName)/\(itemName).scn") {
//            let node = scene.rootNode.childNode(withName: itemName, recursively: true) {
            
            let wrapperNode = SCNNode()
            wrapperNode.setName(itemName: id)

            for child in scene.rootNode.childNodes {
                child.setName(itemName: id)

                wrapperNode.addChildNode(child)
            }
            self.addChildNode(contentRootNode)
            contentRootNode.addChildNode(wrapperNode)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTransform(_ transform: simd_float4x4) {
        contentRootNode.simdTransform = transform
    }
}
