//
//  GameScene.swift
//  ZombieConga
//
//  Created by Глеб Капустин on 25.02.2024.
//

import SpriteKit

class GameScene: SKScene {
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * pi
    var lastTouchLocation: CGPoint?
    let playableRect: CGRect
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    
    let background = SKSpriteNode(imageNamed: "background1")
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    
    override init(size: CGSize) {
      let maxAspectRatio: CGFloat = 19.5 / 9.0
      let playableHeight = size.width / maxAspectRatio
      let playableMargin = (size.height - playableHeight) / 2.0
      playableRect = CGRect(x: 0, y: playableMargin,
                            width: size.width,
                            height: playableHeight)
      super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
        
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        spawnEnemy()
        
        debugDrawPlayableArea()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
          dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime

        defer {
            boundsCheckZombie()
        }
        guard let lastTouchLocation else {
            return
        }
        if (lastTouchLocation - zombie.position).length() > zombieMovePointsPerSec * dt {
            move(sprite: zombie, velocity: velocity)
            rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        } else {
            zombie.position = lastTouchLocation
            velocity = .zero
        }
        
    }
    
    
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
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
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
        enemy.position = CGPoint(x: size.width + enemy.size.width/2,
                                 y: size.height/2)
        addChild(enemy)
        
        let actionMidMove = SKAction.moveBy(
          x: -size.width/2-enemy.size.width/2,
          y: -playableRect.height/2 + enemy.size.height/2,
          duration: 1.0)
        let actionMove = SKAction.moveBy(
          x: -size.width/2-enemy.size.width/2,
          y: playableRect.height/2 - enemy.size.height/2,
          duration: 1.0)
        
        let wait = SKAction.wait(forDuration: 0.25)
        let logMessage = SKAction.run() {
            print("Reached bottom!")
          }
        let halfSequence = SKAction.sequence(
          [actionMidMove, logMessage, wait, actionMove])
        let sequence = SKAction.sequence(
          [halfSequence, halfSequence.reversed()])
        
        let repeatAction = SKAction.repeatForever(sequence)
        enemy.run(repeatAction)
    }
    
    private func isTouchLocationInSprite(touchLocation: CGPoint, sprite: SKSpriteNode) -> Bool {
        touchLocation.x >= (sprite.position.x - sprite.size.width / 2)
        && touchLocation.x <= (sprite.position.x + sprite.size.width / 2)
        && touchLocation.y >= (sprite.position.y - sprite.size.height / 2)
        && touchLocation.y <= (sprite.position.y + sprite.size.height / 2)
    }
}
