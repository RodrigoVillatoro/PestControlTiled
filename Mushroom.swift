//
//  Mushroom.swift
//  PestControlTiled
//
//  Created by Rodrigo Villatoro on 7/23/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit

class Mushroom: SKSpriteNode {
   
    init() {

        let texture = SKTexture(imageNamed: "littleshrooms_0")
        
        super.init(texture: texture, color: UIColor.whiteColor(), size: texture.size())
        
        self.physicsBody = SKPhysicsBody(rectangleOfSize: self.texture.size())
        self.physicsBody.categoryBitMask = PhysicsCategory.Mushroom
        self.physicsBody.collisionBitMask = 0
        self.physicsBody.dynamic = false
        self.physicsBody.usesPreciseCollisionDetection = true
        self.physicsBody.allowsRotation = false
        self.physicsBody.restitution = 1
        self.physicsBody.friction = 0
        self.physicsBody.linearDamping = 0
        self.physicsBody.collisionBitMask = PhysicsCategory.Bug | PhysicsCategory.Player

        
    }
    
}
