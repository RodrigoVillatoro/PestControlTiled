//
//  FireBug.swift
//  PestControlNew
//
//  Created by Rodrigo Villatoro on 7/16/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit

class FireBug: Bugs {
   
    init() {
        super.init()
        self.physicsBody.categoryBitMask = PhysicsCategory.FireBug
        self.physicsBody.collisionBitMask = PhysicsCategory.Boundary | PhysicsCategory.Tree | PhysicsCategory.FireBug | PhysicsCategory.Player
        self.physicsBody.linearDamping = 1
        self.physicsBody.angularDamping = 1
        self.physicsBody.dynamic = true
        self.physicsBody.restitution = 1
        self.physicsBody.friction = 0
        self.color = SKColor.redColor()
        self.colorBlendFactor = 0.45
        self.name = "firebug"

    }
    
    
}
