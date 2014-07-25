//
//  AnimatedSprite.swift
//  PestControlNew
//
//  Created by Rodrigo Villatoro on 7/15/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit

enum FacingDirection {
    case Forward
    case Back
    case Right
    case Left
}

class AnimatedSprite: SKSpriteNode {
    
    var facingDirection = FacingDirection.Forward

    var facingForwardAnim = SKAction()
    var facingBackAnim = SKAction()
    var facingSideAnim = SKAction()
    
    func createAnimWith(prefix: NSString, suffix: NSString) -> SKAction {
        let atlas = SKTextureAtlas(named: "characters")
        var textures =  SKTexture[]()
        for i in 1...2 {
            let spriteString = "\(prefix)_\(suffix)\(i)"
            let sprite = atlas.textureNamed(spriteString)
            sprite.filteringMode = SKTextureFilteringMode.Nearest
            textures.append(sprite)
        }
        return SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.20))
    }
    
    func defineFacingDirection(direction: FacingDirection) {
        
        facingDirection = direction
        
        switch direction {
        case .Forward:
            self.runAction(facingForwardAnim)
        case .Back:
            self.runAction(facingBackAnim)
        case .Left:
            self.runAction(facingSideAnim)
        case .Right:
            self.runAction(facingSideAnim)
            if self.xScale > 0.0 {
                self.xScale = -self.xScale
            }
        }
        if direction != .Right && self.xScale < 0.0 {
            self.xScale = -self.xScale
        }
        
    }
    
}









