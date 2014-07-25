//
//  GameScene.swift
//  PestControlTiled
//
//  Created by Rodrigo Villatoro on 7/17/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import SpriteKit
import AVFoundation
import QuartzCore

enum PhysicsCategory {
    static let Boundary = 1 << 0 as UInt32      // 1
    static let Player = 1 << 1 as UInt32        // 2
    static let Bug = 1 << 2 as UInt32           // 4
    static let Tree = 1 << 3 as UInt32          // 8
    static let KillingPoint = 1 << 4 as UInt32  // 16
    static let Breakable = 1 << 5 as UInt32     // 32
    static let FireBug = 1 << 6 as UInt32       // 64
    static let Mushroom = 1 << 7 as UInt32      // 128
}

enum GameState {
    case StartingLevel
    case Playing
    case InLevelMenu
}

enum Side: Int {
    case Right
    case Top
    case Left
    case Bottom
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var screenNode = SKNode()
    var worldNode = SKNode()
    var bounds = SKNode()
    var map: JSTileMap!
    var player = Player()
    var mapSizeInPixels = CGSize()
    var gameState: GameState!
    var level = Int()
    var levelTimeLimit = Double()
    var timerLabel = SKLabelNode()
    var currentTime = Double()
    var startTime = Double()
    var elapsedTime = Double()
    var won = Bool()
    var lastComboTime = CFTimeInterval()
    var comboCounter = Int()
    var bugCount = Int()
    
    // Sounds
    var hitMushroomSound = SKAction()
    var hitTreeSound = SKAction()
    var hitFireBugSound = SKAction()
    var playerMoveSound = SKAction()
    var clockSound = SKAction()
    var winSound = SKAction()
    var loseSound = SKAction()
    var drownFireBugSound = SKAction()
    var killBugsSound = SKAction[]()
    var backgroundMusicPlayer = AVAudioPlayer()
    
    /*
    ==========================
    
    Init and didMoveToView
    
    ==========================
    */
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder);
    }
    
    init(size: CGSize, level: Int) {
        
        super.init(size: size)
        
        self.level = level
        
        if level == 0 {
            levelTimeLimit = 25.0
        } else if level == 1 {
            levelTimeLimit = 100.0
        } else if level > 1 {
            self.level = 0
            levelTimeLimit = 15.0
        }
        
    }
    
    override func didMoveToView(view: SKView) {
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
        
        map = JSTileMap(named: "level-\(level).tmx")
        
        addChild(screenNode)
        
        screenNode.addChild(worldNode)
        worldNode.addChild(map)
        
        setupWorld()
        createCollisionAreas()
        createFireBugsKillingPoints()
        spawnPlayer()
        spawnBugs()
        spawnFireBugs()
        createMushrooms()
        countBugsAndMakeThemWalk()
        loadSounds()
        
        createUserInterface()
        gameState = GameState.StartingLevel
        
    }
    
    /*
    ==========================
    
    Sounds
    
    ==========================
    */
    
    func loadSounds() {
        hitMushroomSound = SKAction.playSoundFileNamed("HitWall.mp3", waitForCompletion: false)
        hitTreeSound = SKAction.playSoundFileNamed("HitTree.mp3", waitForCompletion: false)
        hitFireBugSound = SKAction.playSoundFileNamed("HitFireBug.mp3", waitForCompletion: false)
        playerMoveSound = SKAction.playSoundFileNamed("PlayerMove.mp3", waitForCompletion: false)
        clockSound = SKAction.playSoundFileNamed("TickTock.mp3", waitForCompletion: true)
        winSound = SKAction.playSoundFileNamed("Win.mp3", waitForCompletion: false)
        loseSound = SKAction.playSoundFileNamed("Lose.mp3", waitForCompletion: false)
        drownFireBugSound = SKAction.playSoundFileNamed("DrownFireBug.mp3", waitForCompletion: false)
        
        for var t = 0; t < 12; ++t {
            let someKillBugsSound = SKAction.playSoundFileNamed("KillBug-\(t+1).mp3", waitForCompletion: false)
            killBugsSound.append(someKillBugsSound)
        }
        
    }
    
    func playBackgroundMusic() -> () {
        var error: NSError?
        let backgroundMusicURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Music", ofType: "mp3"))
        backgroundMusicPlayer = AVAudioPlayer(contentsOfURL: backgroundMusicURL, error: &error)
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    }
    
    /*
    ==========================
    
    Emitter Nodes
    
    ==========================
    */
    
    func dropLeaves() -> SKEmitterNode {
        let leaves = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("TreeSmash", ofType: "sks")) as SKEmitterNode
        leaves.position = CGPointMake(0, 0)
        leaves.name = "Leaves"
        return leaves
    }
    
    func burnFireBug() -> SKEmitterNode {
        let smoke = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("Smoke", ofType: "sks")) as SKEmitterNode
        smoke.position = CGPointMake(0, 0)
        smoke.name = "Smoke"
        return smoke
    }
    
    func sparkFireBug() -> SKEmitterNode {
        let spark = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("FirebugSparks", ofType: "sks")) as SKEmitterNode
        spark.position = CGPointMake(0, 0)
        spark.name = "Smoke"
        return spark
    }
    
    func waitThenRemove(emitterNode: SKEmitterNode, duration: NSTimeInterval) {
        let actionWait = SKAction.waitForDuration(duration)
        let actionRemove = SKAction.removeFromParent()
        emitterNode.runAction(SKAction.sequence([actionWait, actionRemove]))
    }
    
    /*
    ==========================
    
    Setup
    
    ==========================
    */
    
    func setupWorld() {
        mapSizeInPixels = CGSizeMake(map.mapSize.width * map.tileSize.width, map.mapSize.height * map.tileSize.height)
        
        bounds.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectMake(0, 0, mapSizeInPixels.width, mapSizeInPixels.height))
        bounds.physicsBody.categoryBitMask = PhysicsCategory.Boundary
        bounds.physicsBody.friction = 0
        map.addChild(bounds)
    }
    
    func countBugsAndMakeThemWalk() {
        worldNode.enumerateChildNodesWithName("bug", usingBlock: {
            node, stop in
            (node as Bugs).walk()
            ++self.bugCount
            })
        
        worldNode.enumerateChildNodesWithName("firebug", usingBlock: {
            node, stop in
            (node as FireBug).walk()
            ++self.bugCount
            })
    }
    
    func worldTargetPosition() -> CGPoint {
        
        var somePosition = CGPoint()
        
        // Center camera on X
        if player.position.x < self.size.width/2 {
            somePosition.x = 0.0
        } else if player.position.x >= self.size.width/2 {
            somePosition.x = -player.position.x + self.size.width/2
            if player.position.x > mapSizeInPixels.width - self.size.width/2 {
                somePosition.x = -mapSizeInPixels.width + self.size.width
            }
        }
        
        // Center camera on Y
        if player.position.y < self.size.height/2 {
            somePosition.y = 0.0
        } else if player.position.y >= self.size.height/2 {
            somePosition.y = -player.position.y + self.size.height/2
            if player.position.y > mapSizeInPixels.height - self.size.height/2 {
                somePosition.y = -mapSizeInPixels.height + self.size.height
            }
        }
        
        return somePosition
        
    }
    
    func createUserInterface() {
        
        let startMsg = SKLabelNode(fontNamed: "HelveticaNeue")
        startMsg.name = "msgLabel"
        startMsg.text = "Tap screen to run!!"
        startMsg.fontSize = 32
        startMsg.position = CGPointMake(self.size.width/2, self.size.height/2)
        addChild(startMsg)
        
        timerLabel = SKLabelNode(fontNamed: "HelveticaNeue")
        timerLabel.name = "timerLabel"
        timerLabel.text = "Time remaining \(levelTimeLimit)"
        timerLabel.fontSize = 18
        timerLabel.position = CGPointMake(self.size.width - 90, self.size.height - 20)
        addChild(timerLabel)
        
        timerLabel.hidden = true
        
    }
    
    /*
    ==========================
    
    Tile Map Related
    
    ==========================
    */
    
    func tileRectFromTileCoords(tileCoords: CGPoint) -> CGRect {
        let levelHeightInPixels = map.mapSize.height * map.tileSize.height
        let origin = CGPointMake(tileCoords.x * map.tileSize.width, levelHeightInPixels - ((tileCoords.y + 1) * map.tileSize.height))
        return CGRectMake(origin.x, origin.y, map.tileSize.width, map.tileSize.height)
    }
    
    func tileGIDAtTileCoord(coord: CGPoint, layer:TMXLayer) -> NSInteger {
        let layerInfo = layer.layerInfo
        return NSInteger(layerInfo.tileGidAtCoord(coord))
    }
    
    // For collision areas with width and height
    func createFireBugsKillingPoints() {
        
        let collisionsGroup = map.groupNamed("KillingPoints")
        
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            
            let width = collisionObject.objectForKey("width") as String
            let height = collisionObject.objectForKey("height") as String
            let someObstacleSize = CGSize(width: CGFloat(width.toInt()!) * 0.50, height: CGFloat(height.toInt()!) * 0.75)
            
            let someObstacle = SKSpriteNode(color: UIColor.clearColor(), size: someObstacleSize)
            
            let y = collisionObject.objectForKey("y") as Int
            let x = collisionObject.objectForKey("x") as Int
            
            someObstacle.position = CGPoint(x: x + width.toInt()!/2, y: y + height.toInt()!/2)
            someObstacle.physicsBody = SKPhysicsBody(rectangleOfSize: someObstacleSize)
            someObstacle.physicsBody.affectedByGravity = false
            someObstacle.physicsBody.categoryBitMask = PhysicsCategory.KillingPoint
            someObstacle.physicsBody.dynamic = false
            someObstacle.physicsBody.friction = 0
            someObstacle.physicsBody.restitution = 1
            someObstacle.name = "someObstacle"
            
            worldNode.addChild(someObstacle)
        }
        
    }
    
    // For collision areas with width and height
    func createCollisionAreas() {
        
        let collisionsGroup = map.groupNamed("CollisionAreas")
        
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            
            let width = collisionObject.objectForKey("width") as String
            let height = collisionObject.objectForKey("height") as String
            let someObstacleSize = CGSize(width: width.toInt()!, height: height.toInt()!)
            
            let someObstacle = SKSpriteNode(color: UIColor.clearColor(), size: someObstacleSize)
            
            let y = collisionObject.objectForKey("y") as Int
            let x = collisionObject.objectForKey("x") as Int
            
            someObstacle.position = CGPoint(x: x + width.toInt()!/2, y: y + height.toInt()!/2)
            someObstacle.physicsBody = SKPhysicsBody(rectangleOfSize: someObstacleSize)
            someObstacle.physicsBody.affectedByGravity = false
            someObstacle.physicsBody.categoryBitMask = PhysicsCategory.Tree
            someObstacle.physicsBody.dynamic = false
            someObstacle.physicsBody.friction = 0
            someObstacle.physicsBody.restitution = 1
            
            map.addChild(someObstacle)
            
        }
    }
    
    // For spawn points (without width and height)
    func createMushrooms() {
        if map.groupNamed("Mushrooms") != nil {
            let collisionsGroup = map.groupNamed("Mushrooms")
            for (var i = 0; i < collisionsGroup.objects.count; ++i) {
                let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
                let y = collisionObject.objectForKey("y") as Int
                let x = collisionObject.objectForKey("x") as Int
                let shrooms = Mushroom()
                let width = shrooms.size.width
                let height = shrooms.size.height
                shrooms.position = CGPointMake(CGFloat(x) + width/2, CGFloat(y) + height/2)
                worldNode.addChild(shrooms)
            }
        }
    }
    
    
    // For spawn points (without width and height)
    func spawnPlayer() {
        let collisionsGroup = map.groupNamed("Player")
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            player.position = CGPoint(x: x, y: y);
            worldNode.addChild(player)
        }
    }
    
    // For spawn points (without width and height)
    func spawnBugs() {
        let collisionsGroup = map.groupNamed("Bugs")
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            let bugNode = Bugs()
            bugNode.position = CGPoint(x: x, y: y);
            worldNode.addChild(bugNode)
        }
    }
    
    
    // For spawn points (without width and height)
    func spawnFireBugs() {
        let collisionsGroup = map.groupNamed("FireBugs")
        for (var i = 0; i < collisionsGroup.objects.count; ++i) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as NSDictionary
            let y = collisionObject.objectForKey("y") as Int;
            let x = collisionObject.objectForKey("x") as Int;
            let bugNode = FireBug()
            bugNode.position = CGPoint(x: x, y: y);
            worldNode.addChild(bugNode)
        }
    }
    
    /*
    ==========================
    
    Handle Collissions
    
    ==========================
    */
    
    func sideForCollisionsWithNode(node: SKNode) -> Side {
        let diff = CGPointSubtract(node.position, player.position)
        let angle = CGPointToAngle(diff)
        if angle > -CGFloat(M_PI_4) && angle <= CGFloat(M_PI_4) {
            return Side.Right
        } else if angle > CGFloat(M_PI_4) && angle <= 3.0 * CGFloat(M_PI_4) {
            return Side.Top
        } else if angle <= -CGFloat(M_PI_4) && angle > -3.0 * CGFloat(M_PI_4) {
            return Side.Bottom
        } else {
            return Side.Left
        }
    }
    
    func moveMushrooms(node: SKNode, side: Side) {
        if node.actionForKey("moving") == nil {
            
            // first four numbers represent Xs, last four numbers represent Ys
            let offsets = [4.0, 0.0, -4.0, 0.0, 0.0, 4.0, 0.0, -4.0]
            
            let x = side.toRaw()
            let y = side.toRaw() + 4
            
            let oldPositon = node.position
            var offset = CGPoint(x: CGFloat(offsets[x]), y: CGFloat(offsets[y]))
            let newPosition = CGPointAdd(node.position, offset)
            let moveEffect = SKAction.moveTo(newPosition, duration: 0.3)
            let moveBack = SKAction.moveTo(oldPositon, duration: 0.3)
            node.runAction(SKAction.sequence([moveEffect, moveBack]), withKey: "moving")
        }
    }
    
    func scaleMushroom(node: SKNode) {
        node.xScale = 1.2
        node.yScale = node.xScale
        let action = SKAction.scaleTo(1.0, duration: 1.2)
        action.timingMode = SKActionTimingMode.EaseOut
        node.runAction(action, withKey: "scaling")
        
        let side = sideForCollisionsWithNode(node)
        self.moveMushrooms(node, side: side)
    }
    
    func shakeScreenCollisions() {
        
        let moveSome = SKAction.moveByX(3, y: 1, duration: 0.05)
        let returnMove = SKAction.reversedAction(moveSome)
        let sequence = SKAction.sequence([moveSome, returnMove()])
        
        screenNode.runAction(SKAction.repeatAction(sequence, count: 2))
        
    }
    
    func hitBugEffect(someNode: SKNode) {
        
        var now = CACurrentMediaTime()
        if now - lastComboTime < 0.5 {
            ++comboCounter
        } else {
            comboCounter = 0
        }
        lastComboTime = now
        
        if someNode.physicsBody != nil {
            --bugCount
        }
        
        someNode.physicsBody.contactTestBitMask = 0
        someNode.physicsBody = nil
        println(bugCount)
        
        let upAction = SKAction.moveByX(0.0, y: 30.0, duration: 0.2)
        upAction.timingMode = SKActionTimingMode.EaseOut
        let downAction = SKAction.moveByX(0.0, y: -300.0, duration: 0.8)
        downAction.timingMode = SKActionTimingMode.EaseIn
        someNode.runAction(SKAction.sequence([upAction, downAction, SKAction.removeFromParent()]))
        
        let direction = randomPositiveOrNegative()
        let horizontalAction = SKAction.moveByX(100.0 * CGFloat(direction), y: 0.0, duration: 1.0)
        someNode.runAction(horizontalAction)
        
        let rotateAction = SKAction.rotateByAngle(-CGFloat(M_PI_4) * 2.0, duration: 1.0)
        someNode.runAction(rotateAction)
        
        someNode.xScale = 1.5 + (CGFloat(comboCounter) * 0.05)
        someNode.yScale = 1.5 + (CGFloat(comboCounter) * 0.05)
        let scaleAction = SKAction.scaleTo(0.4, duration: 1.0)
        scaleAction.timingMode = SKActionTimingMode.EaseOut
        someNode.runAction(scaleAction)
        
        someNode.runAction(SKAction.sequence([SKAction.waitForDuration(0.6), SKAction.fadeOutWithDuration(0.4)]))
        
        (someNode as SKSpriteNode).color = SKColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
        (someNode as SKSpriteNode).colorBlendFactor = 1.0
        
        shakeScreenCollisions()
        
        let soundNumber = Int(returnMin(CGFloat(11), CGFloat(comboCounter)))
        someNode.runAction(killBugsSound[soundNumber])
        println(soundNumber)
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == PhysicsCategory.Player || contact.bodyB.categoryBitMask == PhysicsCategory.Player {
            let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
            
            if other.categoryBitMask == PhysicsCategory.Bug {
                
                self.hitBugEffect(other.node)
                
            } else if other.categoryBitMask == PhysicsCategory.FireBug {
                
                self.runAction(hitFireBugSound)
                
                let scaleUp = SKAction.scaleTo(1.2, duration: 0.1)
                let scaleDown = SKAction.scaleTo(1.0, duration: 0.1)
                other.node.runAction(SKAction.repeatAction(SKAction.sequence([scaleUp, scaleDown]), count: 5))
                
                let burnEmitterNode = burnFireBug()
                other.node.addChild(burnEmitterNode)
                waitThenRemove(burnEmitterNode, duration: 1.5)
                
                // EmitterNode on Firebug
                let sparkEmitterNode = sparkFireBug()
                other.node.addChild(sparkEmitterNode)
                waitThenRemove(sparkEmitterNode, duration: 1.0)
                
            } else if other.categoryBitMask == PhysicsCategory.Mushroom {
                self.runAction(hitMushroomSound)
                self.scaleMushroom(other.node)
            }
            
            
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.KillingPoint || contact.bodyB.categoryBitMask == PhysicsCategory.KillingPoint {
            let other = contact.bodyA.categoryBitMask == PhysicsCategory.KillingPoint ? contact.bodyB : contact.bodyA
            if other.categoryBitMask == PhysicsCategory.FireBug {
                other.node.removeFromParent()
            }
        }
        
        
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        // other category bitmask is 1, 8, 16, etc., player collision bitmask is 25
        if other.categoryBitMask & player.physicsBody.collisionBitMask != 0 {
            player.faceCurrentDirection()
            player.defineFacingDirection(player.facingDirection)
            shakeScreenCollisions()
            
            if other.categoryBitMask != PhysicsCategory.Mushroom && other.categoryBitMask != PhysicsCategory.FireBug && other.categoryBitMask != PhysicsCategory.Boundary {
                
                let leavesEmmiterNode = dropLeaves()
                other.node.addChild(leavesEmmiterNode)
                waitThenRemove(leavesEmmiterNode, duration: 0.5)
                
                self.runAction(hitTreeSound)
            }
            
            
        }
    }
    
    /*
    ==========================
    
    Other Functions
    
    ==========================
    */
   
    func endLevelWithSuccess(won: Bool) {
        
        self.won = won
        
        let label = self.childNodeWithName("msgLabel") as SKLabelNode
        
        label.text = won ? "You win!!!" : "Too slow!!!"
        label.hidden = false
        
        if won {
            let nextLevel = SKLabelNode(fontNamed: "HelveticaNeue")
            nextLevel.name = "nextLevelLabel"
            nextLevel.text = "Next level?"
            nextLevel.fontSize = 24
            nextLevel.position = CGPointMake(self.size.width/2, self.size.height/2 - 40)
            addChild(nextLevel)
        } else {
            let tryAgain = SKLabelNode(fontNamed: "HelveticaNeue")
            tryAgain.name = "playAgain"
            tryAgain.text = "Try again?"
            tryAgain.fontSize = 24
            tryAgain.position = CGPointMake(self.size.width/2, self.size.height/2 - 40)
            addChild(tryAgain)
        }

        player.physicsBody.linearDamping = 1
        gameState = GameState.InLevelMenu
        
        backgroundMusicPlayer.pause()
        self.runAction(won ? winSound : loseSound)
        
    }
  
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent!) {
        
        for touch : AnyObject in touches {
            
            switch gameState! {
            case .StartingLevel:
                childNodeWithName("msgLabel").hidden = true
                gameState = GameState.Playing
                self.paused = false
                timerLabel.hidden = false
                startTime = currentTime
                player.startTrail()
                playBackgroundMusic()
                fallthrough
            case .Playing:
                let location = touch.locationInNode(worldNode)
                player.moveToward(location)
                player.runAction(playerMoveSound)
            case .InLevelMenu:
                if won {
                    ++level
                    let newScene = GameScene(size: self.size, level: level)
                    self.view.presentScene(newScene, transition: SKTransition.flipVerticalWithDuration(0.5))
                } else {
                    let newScene = GameScene(size: self.size, level: level)
                    self.view.presentScene(newScene, transition: SKTransition.flipVerticalWithDuration(0.5))
                }
            }
        }
    }
    
    override func didSimulatePhysics() {
        var target = worldTargetPosition()
        
        var newPosition = worldNode.position
        newPosition.x += (target.x - worldNode.position.x) * 0.1
        newPosition.y += (target.y - worldNode.position.y) * 0.1
        
        worldNode.position = newPosition
    }
   
    override func update(currentTime: CFTimeInterval) {
        
        self.currentTime = currentTime
        elapsedTime = currentTime - startTime
        
        if gameState == GameState.StartingLevel && !self.paused {
            self.paused = true
        }
        
        if gameState != GameState.Playing {
            return
        }
        
        // Check if FireBug is in Killing Point, if so, rotate and remove from Parent
        worldNode.enumerateChildNodesWithName("someObstacle", usingBlock: {
            node, stop in
            self.worldNode.enumerateChildNodesWithName("firebug", usingBlock: {
                anotherNode, stop in
                if anotherNode.intersectsNode(node) {
                    
                    self.runAction(self.drownFireBugSound)
                    
                    anotherNode.runAction(SKAction.sequence([SKAction.group([SKAction.rotateByAngle(4 * CGFloat(M_PI_4), duration: 1.0), SKAction.scaleTo(0.0, duration: 1.0)]),SKAction.removeFromParent()]))
                    
                    if anotherNode.physicsBody != nil {
                        --self.bugCount
                        anotherNode.physicsBody.contactTestBitMask = 0
                        anotherNode.physicsBody = nil
                    }
                    
                    
                }
                })
            })
        
        if elapsedTime >= levelTimeLimit {
            endLevelWithSuccess(false)
            timerLabel.text = "Time remaining 0.0"
        } else if bugCount <= 0 {
            endLevelWithSuccess(true)
        } else {
            timerLabel.text = NSString(format: "Time remaining %2.1f", levelTimeLimit - elapsedTime)
        }
        
        
    }
}
