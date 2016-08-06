//
//  GameScene.swift
//  ZombieConga
//
//  Created by unknown-macbook on 6/25/16.
//  Copyright (c) 2016 indietarhouni.com. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    let scene = 
      MainMenuScene(size:CGSize(width: 2048, height: 1536))
    let skView = self.view as! SKView
    skView.showsFPS = true
    skView.showsNodeCount = true
    skView.ignoresSiblingOrder = true
    scene.scaleMode = .AspectFill
    skView.presentScene(scene)
  } 
  override func prefersStatusBarHidden() -> Bool  {
    return true
  }
}
