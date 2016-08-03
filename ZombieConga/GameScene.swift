


//
//  GameScene.swift
//  ZombieConga
//
//  Created by unknown-macbook on 6/25/16.
//  Copyright (c) 2016 indietarhouni.com. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect : CGRect
    var lastTouchLocation: CGPoint?
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction =
    SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction =
    SKAction.playSoundFileNamed( "hitCatLady.wav", waitForCompletion:false)
    var invincible = false
    let catMovePointsPerSec:CGFloat = 480.0

    override init(size : CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0 // 1
        let playableHeight = size.width / maxAspectRatio // 2
        let playableMargin = (size.height-playableHeight)/2.0 // 3
        playableRect = CGRect(x: 0, y: playableMargin,
            width: size.width,
            height: playableHeight) // 4
        var textures:[SKTexture] = []
        for i in 1...4{
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.1)

        super.init(size: size) // 5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // 6
    }

    override func didMoveToView(view: SKView) {

        backgroundColor = SKColor.blackColor()

        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1
        addChild(background)
        //background.anchorPoint = CGPoint.zero //START changing the default anchor point (0.5, 0.5) to (0, 0)
        //background.position = CGPoint.zero//END
        //background.zRotation = CGFloat(M_PI) / 8 //START rotate by PI/8
        let mySize = background.size
        print("Size: \(mySize)")

        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        //zombie.setScale(2)
        addChild(zombie)
        //zombie.runAction(SKAction.repeatActionForever(zombieAnimation))
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnEnemy),
                SKAction.waitForDuration(2.0)])))
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnCat),
                SKAction.waitForDuration(1.0)])))
        debugDrawPlayableArea()

    }

    override func update(currentTime: NSTimeInterval) {
        //zombie.position = CGPoint(x: zombie.position.x + 8 , y: zombie.position.y)
        //moveSprite(zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
        //moveSprite(zombie, velocity: velocity)
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        print("\(dt*1000) milliseconds since last update")

        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - zombie.position
            if(diff.length() <= zombieMovePointsPerSec * CGFloat(dt)){
                zombie.position = lastTouchLocation
                velocity = CGPointZero
                stopZombieAnimation()
            } else {
                moveSprite(zombie, velocity: velocity)
                rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            }
        }

        boundsCheckZombie()
        checkCollisions()
        moveTrain()
    }

    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint){
        // 1
        //let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        let amountToMove = velocity * CGFloat(dt)
        print("Amount to move: \(amountToMove)")
        // 2
        //sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
        sprite.position += amountToMove

    }

    func moveZombieToward(location: CGPoint){
        //let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        startZombieAnimation()
        let offset = location - zombie.position
        //let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        //let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        let direction = offset.normalized()
        //velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        velocity = direction * zombieMovePointsPerSec

    }

    func sceneTouched(touchLocation:CGPoint){
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)

    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch  = touches.first else {
            return
        }
        let touchLocation  = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }

    func boundsCheckZombie(){
        /*let bottomLeft = CGPointZero
        let topRight = CGPoint(x: size.width, y: size.height)*/

        let bottomLeft = CGPoint(x: 0,
            y: CGRectGetMinY(playableRect))

        let topRight = CGPoint(x: size.width,
            y: CGRectGetMaxY(playableRect))

        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }

    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }

    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint,
        rotateRadiansPerSec: CGFloat){
            let shortest = shortestAngleBetween(sprite.zRotation, angle2: velocity.angle)
            let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
            sprite.zRotation += shortest.sign() * amountToRotate

    }
    func spawnEnemy(){
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        addChild(enemy)

        let actionMove =
        SKAction.moveToX(-enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }

    func startZombieAnimation(){
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(
                SKAction.repeatActionForever(zombieAnimation),
                withKey: "animation")
        }
    }

    func stopZombieAnimation(){
        zombie.removeActionForKey("animation")
    }

    func spawnCat(){
        // 1
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"

        cat.position = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect),
                max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect),
                max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
        addChild(cat)
        // 2
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        //let wait = SKAction.waitForDuration(2.0)
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        /*[let wiggleWait = SKAction.repeatAction(fullWiggle, count: 10)*/
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }

    func zombieHitCat(cat: SKSpriteNode) {

        //cat.removeFromParent()
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        let turnGreen = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        cat.runAction(turnGreen)
        runAction(catCollisionSound)

    }

    func zombieHitEnemy(enemy: SKSpriteNode) {

        enemy.removeFromParent()
        runAction(enemyCollisionSound)
        
        invincible = true
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration){
            node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        let setHidden = SKAction.runBlock(){
            self.zombie.hidden = false
            self.invincible = false
        }
        zombie.runAction(SKAction.sequence([blinkAction, setHidden]))
        
    }

    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {

                hitCats.append(cat)

            }
        }
        for cat in hitCats {

            zombieHitCat(cat)
        }

        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodesWithName("enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if CGRectIntersectsRect( CGRectInset(node.frame, 20, 20), self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies {

            zombieHitEnemy(enemy) }

    }
    
    func moveTrain(){
        var targetPosition = zombie.position
        
        enumerateChildNodesWithName("train"){
            node, _ in
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
        }
    }


    /*
    func spawnEnemy(){
    let enemy = SKSpriteNode(imageNamed: "enemy")
    enemy.position = CGPoint(x: size.width + enemy.size.width/2,
    y: size.height/2)
    addChild(enemy)
    // 1
    let actionMidMove = SKAction.moveByX(
    -size.width/2-enemy.size.width/2,
    y: -CGRectGetHeight(playableRect)/2 + enemy.size.height/2,
    duration: 1.0)
    // 2
    let actionMove = SKAction.moveByX(
    -size.width/2 - enemy.size.width/2,
    y: CGRectGetHeight(playableRect)/2 - enemy.size.height/2,
    duration:  1.0)


    // 3
    let wait = SKAction.waitForDuration(0.25)
    let logMessage = SKAction.runBlock(){
    print("Reached Bottom!")
    }
    let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
    let sequence = SKAction.sequence([halfSequence, halfSequence.reversedAction()])

    let repeatAction = SKAction.repeatActionForever(sequence)
    // 4

    /*
    let reverseMid = actionMidMove.reversedAction()
    let reverseMove = actionMove.reversedAction()
    let sequence = SKAction.sequence([ actionMidMove, logMessage, wait, actionMove, reverseMove, logMessage, wait, reverseMid ])
    */
    enemy.runAction(sequence)
    }
    */
    /*
    backgroundColor = SKColor.blackColor()

    let background = SKSpriteNode(imageNamed: "background1")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
    // background.zRotation = CGFloat(M_PI) / 8
    background.zPosition = -1
    addChild(background)

    let mySize = background.size
    print("Size: \(mySize)")

    zombie.position = CGPoint(x: 400, y: 400)
    addChild(zombie)

    */
}
