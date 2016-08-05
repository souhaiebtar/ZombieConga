


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
    var lives = 5
    var gameOver = false
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0

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
        playBackgroundMusic("backgroundMusic.mp3")
        backgroundColor = SKColor.blackColor()

        // let background = SKSpriteNode(imageNamed: "background1")
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPointZero
            background.position =
            CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            addChild(background)
        }
        //background.anchorPoint = CGPoint.zero //START changing the default anchor point (0.5, 0.5) to (0, 0)
        //background.position = CGPoint.zero//END
        //background.zRotation = CGFloat(M_PI) / 8 //START rotate by PI/8
        //let mySize = background.size
        //print("Size: \(mySize)")

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
        //debugDrawPlayableArea()
        addChild(cameraNode)
        camera = cameraNode
        //cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        setCameraPosition(CGPoint(x: size.width/2, y: size.height/2))
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
        //print("\(dt*1000) milliseconds since last update")
        /*
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - zombie.position
            if(diff.length() <= zombieMovePointsPerSec * CGFloat(dt)){
                zombie.position = lastTouchLocation
                velocity = CGPointZero
                stopZombieAnimation()
            } else {*/
                moveSprite(zombie, velocity: velocity)
                rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)/*
            }
        }*/

        boundsCheckZombie()
        checkCollisions()
        moveTrain()
        moveCamera()
        if lives <= 0 && !gameOver {
            gameOver  = true
            //print("You lose!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: false)
            
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)

            view?.presentScene(gameOverScene, transition: reveal)


        }
        // cameraNode.position = zombie.position
    }

    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint){
        // 1
        //let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        let amountToMove = velocity * CGFloat(dt)
        //print("Amount to move: \(amountToMove)")
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

        let bottomLeft = CGPoint(x: CGRectGetMinX(cameraRect),
            y: CGRectGetMinY(cameraRect))

        let topRight = CGPoint(x: CGRectGetMaxX(cameraRect),
            y: CGRectGetMaxY(cameraRect))

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
        enemy.position = CGPoint(x: CGRectGetMaxX(cameraRect) + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(cameraRect) + enemy.size.height/2,
                max: CGRectGetMaxY(cameraRect) - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)

        /*let actionMove =
        SKAction.moveToX(-enemy.size.width/2, duration: 2.0)*/
        let actionMove = SKAction.moveByX(-size.width-enemy.size.width*2, y: 0, duration: 2.0)
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
            x: CGFloat.random(min: CGRectGetMinX(cameraRect),
                max: CGRectGetMaxX(cameraRect)),
            y: CGFloat.random(min: CGRectGetMinY(cameraRect),
                max: CGRectGetMaxY(cameraRect)))
        cat.zPosition = 50
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
        loseCats()
        lives--
        
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
        var trainCount = 0
        var targetPosition = zombie.position
        
        enumerateChildNodesWithName("train"){
            node, _ in
            trainCount++
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
        if trainCount >= 15 && !gameOver {
            gameOver = true
            //print("You win!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipVerticalWithDuration(0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats(){
        // 1
        var loseCount = 0
        enumerateChildNodesWithName("train"){
            node, stop in
            // 2
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            // 3
            node.name = ""
            node.runAction(
                SKAction.sequence([
                SKAction.group([
                    SKAction.rotateByAngle(π*4, duration: 1.0),
                    SKAction.moveTo(randomSpot, duration: 1.0),
                    SKAction.scaleTo(0, duration: 1.0)
                    ]),
                SKAction.removeFromParent()
                ]))
            // 4
            loseCount++
            if loseCount >= 2 {
                stop.memory = true
            }
        }
    }
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {
            return 0
        }
        let scale = view.bounds.size.width / self.size.width
        let scaledHeight  = self.size.height * scale
        let scaledOverlap = scaledHeight - view.bounds.size.height
        return scaledOverlap / scale
    }
    
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: cameraNode.position.x, y: cameraNode.position.y + overlapAmount()/2)
    }
    
    func setCameraPosition(position: CGPoint) {
        cameraNode.position = CGPoint(x: position.x, y: position.y - overlapAmount()/2)
    }
    
    func backgroundNode() -> SKSpriteNode {
        // 1 
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        // 3
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        // 4
        backgroundNode.size = CGSize( width: background1.size.width + background2.size.width, height: background1.size.height)
        return backgroundNode
        
    }
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        enumerateChildNodesWithName("background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width <
                self.cameraRect.origin.x {
                    background.position = CGPoint(
                        x: background.position.x + background.size.width*2,
                        y: background.position.y)
            }
        }
    }
    
    var cameraRect : CGRect {
        return CGRect(
            x: getCameraPosition().x - size.width/2
                + (size.width - playableRect.width)/2,
            y: getCameraPosition().y - size.height/2
                + (size.height - playableRect.height)/2,
            width: playableRect.width,
            height: playableRect.height)
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

