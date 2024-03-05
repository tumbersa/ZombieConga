//
//  GameScene.swift
//  ZombieConga
//
//  Created by Глеб Капустин on 25.02.2024.
//

import SpriteKit

class GameScene: SKScene {
    let livesLabel = SKLabelNode(fontNamed: "Catbrother")
    let catsLabel = SKLabelNode(fontNamed: "Catbrother")
    let cameraNode = SKCameraNode()
    
    var lives = 5
    var catsTrainCount = 0
    var gameOver = false
    var isInvincible: Bool = false
    
    ///reuse and pre-production of sound
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
      "hitCat.wav", waitForCompletion: true)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
      "hitCatLady.wav", waitForCompletion: true)
    let zombieAnimation: SKAction
    
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * pi
    var lastTouchLocation: CGPoint?
    let playableRect: CGRect
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let trainMovePointsPerSec: CGFloat = 1000.0
    let zombieMovePointsPerSec: CGFloat = 480.0
    let cameraMovePointsPerSec: CGFloat = 200.0
    var velocity = CGPoint.zero
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var cameraRect : CGRect {
      let x = cameraNode.position.x - size.width/2
          + (size.width - playableRect.width)/2
      let y = cameraNode.position.y - size.height/2
          + (size.height - playableRect.height)/2
      return CGRect(x: x, y: y, width: playableRect.width, height: playableRect.height)
    }
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 19.5 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
        
    override func didMove(to view: SKView) {
        playBackgroundMusic(filename: "backgroundMusic2.mp3")
        backgroundColor = SKColor.black
        
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position =
            CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.zPosition = -1
            addChild(background)
        }
        
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        addChild(zombie)
        
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run() { [weak self] in
                self?.spawnEnemy()
            },
            SKAction.wait(forDuration: 2.0)
        ])))
        
        run(SKAction.repeatForever( SKAction.sequence([
            SKAction.run() { [weak self] in
                self?.spawnCat()
            },
            SKAction.wait(forDuration: 1.0)])))
        
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(
          x: -playableRect.size.width/2 + CGFloat(20),
          y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(livesLabel)
        
        catsLabel.text = "Cats: \(catsTrainCount)"
        catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 100
        catsLabel.zPosition = 150
        catsLabel.horizontalAlignmentMode = .right
        catsLabel.verticalAlignmentMode = .bottom
        catsLabel.position = CGPoint(
          x: playableRect.size.width/2 - CGFloat(20),
          y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(catsLabel)
        //debugDrawPlayableArea()
    }
    
    //MARK: - SpriteKit cycle
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
          dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime

        defer {
            boundsCheckZombie()
            moveTrain()
            moveCamera()
            livesLabel.text = "Lives: \(lives)"
            catsLabel.text = "Cats: \(catsTrainCount)"
            if lives <= 0 && !gameOver {
                gameOver = true
                print("You lose!")
                backgroundMusicPlayer.stop()
                
                let gameOverScene = GameOverScene(size: size, won: false)
                gameOverScene.scaleMode = scaleMode
                
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                view?.presentScene(gameOverScene, transition: reveal)
            }
            
            //cameraNode.position = zombie.position
            //checkCollisions()
        }
        guard let lastTouchLocation else {
            return
        }
        if (lastTouchLocation - zombie.position).length() > zombieMovePointsPerSec * dt {
            startZombieAnimation()
            move(sprite: zombie, velocity: velocity)
            rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        } else {
            stopZombieAnimation()
            zombie.position = lastTouchLocation
            velocity = .zero
        }
        
    }
    
    override func didEvaluateActions() {
      ///checking for collisions after spritekit has calculated the new sprite coordinates
        checkCollisions()
    }
    
    //MARK: - touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        if isTouchLocationInSprite(touchLocation: touchLocation, sprite: zombie) {
            sceneTouched(touchLocation: touchLocation)
            lastTouchLocation = touchLocation
        } else {
            sceneTouched(touchLocation: touchLocation)
            lastTouchLocation = .zero
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        if isTouchLocationInSprite(touchLocation: touchLocation, sprite: zombie) {
            sceneTouched(touchLocation: touchLocation)
            lastTouchLocation = touchLocation
        } else {
            sceneTouched(touchLocation: touchLocation)
            lastTouchLocation = .zero
        }
    }
    
    private func move(sprite: SKSpriteNode, velocity: CGPoint) {
         let amountToMove = velocity * CGFloat(dt)
         sprite.position += amountToMove
    }
    
    private func moveZombieToward(location: CGPoint) {
        let offset = location - zombie.position
        //normalizing a vector
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    private func sceneTouched(touchLocation: CGPoint) {
        moveZombieToward(location: touchLocation)
    }
    
    private func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        if zombie.position.x <= bottomLeft.x {
          zombie.position.x = bottomLeft.x
          velocity.x = abs(velocity.x)
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
    
    private func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
      }
    
    private func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        var amountToRotate = rotateRadiansPerSec * CGFloat(dt)
        
        if abs(shortest) < amountToRotate {
            amountToRotate = abs(shortest)
        }
        amountToRotate *= shortest.sign()
        sprite.zRotation += amountToRotate
    }
    
    private func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2 + cameraRect.maxX,
            y: CGFloat.random(
                min: playableRect.minY + enemy.size.height/2,
                max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2 + cameraRect.minX, duration: 2.5)
        //print(cameraRect.minX, cameraRect.maxX)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    private func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
          x: CGFloat.random(min: cameraRect.minX,
                            max: cameraRect.maxX),
          y: CGFloat.random(min: cameraRect.minY,
                            max: cameraRect.maxY))
        cat.zPosition = 50
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        cat.zRotation = -pi / 16.0
        let leftWiggle = SKAction.rotate(byAngle: pi/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence(
          [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
      }
    
    private func isTouchLocationInSprite(touchLocation: CGPoint, sprite: SKSpriteNode) -> Bool {
        touchLocation.x >= (sprite.position.x - sprite.size.width / 2)
        && touchLocation.x <= (sprite.position.x + sprite.size.width / 2)
        && touchLocation.y >= (sprite.position.y - sprite.size.height / 2)
        && touchLocation.y <= (sprite.position.y + sprite.size.height / 2)
    }
    
    private func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    
    private func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    private func zombieHit(cat: SKSpriteNode) {
        if !isInvincible {
            cat.name = "train"
            cat.removeAllActions()
            cat.setScale(1)
            cat.zRotation = 0
            cat.run(SKAction.colorize(with: .green, colorBlendFactor: 1, duration: 0.1))
            run(catCollisionSound)
        }
    }
    
    private func zombieHit(enemy: SKSpriteNode) {
        if !isInvincible {
            run(enemyCollisionSound)
            let blinkTimes = 10.0
            let duration = 3.0
            let blinkAction = SKAction.customAction(
                withDuration: duration) {[weak self] node, elapsedTime in
                    guard let self else { return }
                    let slice = duration / blinkTimes
                    let remainder = Double(elapsedTime).truncatingRemainder(
                        dividingBy: slice)
                    zombie.isHidden = remainder > slice / 2
                }
            let isInvicibleToFalse = SKAction.customAction(withDuration: 0) { [weak self] _, _ in
                self?.zombie.isHidden = false
                self?.isInvincible = false
            }
            isInvincible = true
            zombie.run(SKAction.sequence([blinkAction,isInvicibleToFalse]))
            loseCats()
            lives -= 1
        }
    }
    
    ///Don’t remove the nodes from within the enumeration.
    ///It’s unsafe to remove a node while enumerating over a list of them, and doing so can crash my app.
    private func checkCollisions() {
      var hitCats: [SKSpriteNode] = []
      enumerateChildNodes(withName: "cat") { node, _ in
        let cat = node as! SKSpriteNode
        if cat.frame.intersects(self.zombie.frame) {
          hitCats.append(cat)
        }
      }
      for cat in hitCats {
        zombieHit(cat: cat)
      }
      var hitEnemies: [SKSpriteNode] = []
      enumerateChildNodes(withName: "enemy") { node, _ in
        let enemy = node as! SKSpriteNode
        if node.frame.insetBy(dx: 20, dy: 20).intersects(
          self.zombie.frame) {
          hitEnemies.append(enemy)
        }
      }
      for enemy in hitEnemies {
        zombieHit(enemy: enemy)
      }
    }
    
    private func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        enumerateChildNodes(withName: "train") {[weak self] node, stop in
            guard let self else { return }
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * trainMovePointsPerSec * CGFloat(dt)
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.customAction(withDuration: actionDuration) { node, _ in
                    node.position += amountToMove
                }
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        catsTrainCount = trainCount
        if trainCount >= 15 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    private func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { node, stop in
            
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(byAngle: pi*4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                ]))
            loseCount += 1
            if loseCount >= 2 {
                stop[0] = true
            }
        }
    }
    
    private func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position =
        CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }
    
    private func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") {[weak self] node, _ in
            guard let self else { return }
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < cameraRect.origin.x {
            background.position = CGPoint(
              x: background.position.x + background.size.width*2,
              y: background.position.y)
          }
        }
      }
}
