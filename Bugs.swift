//
//  Bugs.swift
//  PestControlNew
//
//  Created by Rodrigo Villatoro on 7/10/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit

class Bugs: AnimatedSprite {

    var sharedFacingBackAnim: SKAction?
    var sharedFacingForwardAnim: SKAction?
    var sharedFacingSideAnim: SKAction?
    
    var randomX = CGFloat()
    var randomY = CGFloat()
    
    init() {
        
        let atlas = SKTextureAtlas(named: "characters")
        let texture = atlas.textureNamed("bug_ft1")
        texture.filteringMode = SKTextureFilteringMode.Nearest
        super.init(texture: texture, color: UIColor.whiteColor(), size: texture.size())
        self.name = "bug"
        self.zPosition = -50.0
        
        var minDiam = returnMin(self.size.width, self.size.height)
        minDiam = returnMax(minDiam - 8, 8)

        self.physicsBody = SKPhysicsBody(circleOfRadius: minDiam/2)
        self.physicsBody.categoryBitMask = PhysicsCategory.Bug
        self.physicsBody.collisionBitMask = 0
        
        self.physicsBody.usesPreciseCollisionDetection = true
        self.physicsBody.allowsRotation = false
        self.physicsBody.restitution = 1
        self.physicsBody.friction = 0
        self.physicsBody.linearDamping = 0
        self.physicsBody.collisionBitMask = PhysicsCategory.Boundary | PhysicsCategory.Tree | PhysicsCategory.KillingPoint | PhysicsCategory.Bug | PhysicsCategory.Breakable
        
        self.initializeAnimations()
        
    }
    
    func faceCurrentDirection() {
        
        var facingDir: FacingDirection = self.facingDirection
        
        if randomY != 0 && randomX != 0 {
            
            if abs(randomY) > abs(randomX) {
                if randomY < 0 {
                    facingDir = .Forward
                } else {
                    facingDir = .Back
                }
            } else {
                facingDir = randomX > 0 ? .Right : .Left
            }
            
            self.facingDirection = facingDir
            
        }
    }
    
    func initializeAnimations() {
        var token: dispatch_once_t = 0
        dispatch_once(&token, {
            
            self.sharedFacingForwardAnim = self.createAnimWith("bug", suffix: "ft")
            self.sharedFacingBackAnim = self.createAnimWith("bug", suffix: "bk")
            self.sharedFacingSideAnim = self.createAnimWith("bug", suffix: "lt")
            
            })
    }
  
    func walk() {
        
        let bugPosition = self.position
        randomX = randomNumberBetween(-20, 20)
        randomY = randomNumberBetween(-20, 20)
        
        let moveToPos = SKAction.moveByX(randomX, y: randomY, duration: NSTimeInterval(randomNumberBetween(0.2, 0.5)))
        let runBlock = SKAction.runBlock({self.walk()})
        let sequence = SKAction.sequence([moveToPos, runBlock])
        self.runAction(sequence)
        
        
        faceCurrentDirection()
        defineFacingDirection(facingDirection)
        
    }
    
    func facingBackAnim() -> SKAction {
        return sharedFacingBackAnim!
    }
    
    func facingForwardAnim() -> SKAction {
        return sharedFacingForwardAnim!
    }
    
    func facingSideAnim() -> SKAction {
        return sharedFacingSideAnim!
    }
    
}
