//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Глеб Капустин on 05.03.2024.
//

import Foundation
import SpriteKit

final class MainMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(background)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let nextScene = GameScene(size: size)
        nextScene.scaleMode = self.scaleMode
        let reveal = SKTransition.doorsOpenVertical(withDuration: 1.5)
        view?.presentScene(nextScene, transition: reveal)
    }
}
