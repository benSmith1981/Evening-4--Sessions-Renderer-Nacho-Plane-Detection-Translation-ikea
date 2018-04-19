//
//  Furniture.swift
//  Nacho Plane Detection, ikea
//
//  Created by Ben Smith on 19/04/2018.
//  Copyright © 2018 Ben Smith. All rights reserved.
//

import Foundation
import ARKit

class Furniture: SCNNode {
    var itemName: String?
    
    init(itemName: String) {
        super.init()
        self.itemName = itemName
        if let scene = SCNScene.init(named: "Art.scnassets/\(itemName)/\(itemName).scn"),
            let node = scene.rootNode.childNode(withName: itemName, recursively: true) {
            self.addChildNode(node)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
