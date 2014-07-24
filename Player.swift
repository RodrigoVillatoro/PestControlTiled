//
//  Player.swift
//  PestControlNew
//
//  Created by Rodrigo Villatoro on 7/10/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit

class Player: AnimatedSprite {
    
    let PLAYER_MOVES_PER_SEC = 320.0 as CGFloat
    var playerVelocity = CGPoint()
    var trail = SKEmitterNode()
    
    init() {
    
        let atlas = SKTextureAtlas(named: "characters")
        let texture = atlas.textureNamed("player_ft1")
        texture.filteringMode = SKTextureFilteringMode.Nearest
        super.init(texture: texture, color: UIColor.whiteColor(), size: texture.size())
        self.name = "player"
        self.zPosition = -50.0
        
        var minDiam = returnMin(self.size.width, self.size.height)
        minDiam = returnMax(minDiam - 16, 4)
        self.physicsBody = SKPhysicsBody(circleOfRadius: minDiam/2)
        self.physicsBody.usesPreciseCollisionDetection = true
        self.physicsBody.allowsRotation = false
        self.physicsBody.restitution = 1
        self.physicsBody.friction = 0
        self.physicsBody.linearDamping = 0
        self.physicsBody.categoryBitMask = PhysicsCategory.Player
        self.physicsBody.contactTestBitMask = 0xFFFFFFFF
        self.physicsBody.collisionBitMask = PhysicsCategory.Boundary | PhysicsCategory.Tree | PhysicsCategory.KillingPoint | PhysicsCategory.FireBug | PhysicsCategory.Mushroom
        
        self.facingForwardAnim = createAnimWith("player", suffix: "ft")
        self.facingBackAnim = createAnimWith("player", suffix: "bk")
        self.facingSideAnim = createAnimWith("player", suffix: "lt")
        
    }
    
    func moveToward(targetPosition: CGPoint) {
        let offset = CGPointSubtract(targetPosition, self.position)
        let length = CGPointLength(offset)
        let direction = CGPointNormalize(offset)
        playerVelocity = CGPointMultiplyScalar(direction, PLAYER_MOVES_PER_SEC)
        self.physicsBody.velocity = CGVectorMake(playerVelocity.x, playerVelocity.y)
        
        faceCurrentDirection()
        defineFacingDirection(facingDirection)
        
        
    }
    
    func faceCurrentDirection() {
        
        var facingDir: FacingDirection = self.facingDirection
        
        let dir = self.physicsBody.velocity
        if abs(dir.dy) > abs(dir.dx) {
            if dir.dy < 0 {
                facingDir = .Forward
            } else {
                facingDir = .Back
            }
        } else {
            facingDir = dir.dx > 0 ? .Right : .Left
        }
        
        self.facingDirection = facingDir
        
    }
    
    func startTrail() {
        trail = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("PlayerTrail", ofType: "sks")) as SKEmitterNode
        trail.targetNode = self.parent
        trail.name = "Trail"
        self.addChild(trail)
    }
    
}











