//
//  MyUtils.swift
//  ZombieConga
//
//  Created by Глеб Капустин on 26.02.2024.
//

import Foundation
import CoreGraphics
import AVFoundation

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}

func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

func *= (left: inout CGPoint, right: CGPoint) {
    left = left * right
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func *= (point: inout CGPoint, scalar: CGFloat) {
    point = point * scalar
}

func / (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
}

func /= ( left: inout CGPoint, right: CGPoint) {
    left = left / right
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

func /= (point: inout CGPoint, scalar: CGFloat) {
    point = point / scalar
}

#if !(arch(x86_64) || arch(arm64))
func atan2(y: CGFloat, x: CGFloat) -> CGFloat {
    CGFloat(atan2f(Float(y), Float(x)))
}
func sqrt(a: CGFloat) -> CGFloat {
    CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func length() -> CGFloat {
        sqrt(Double(x*x + y*y))
    }
    
    func normalized() -> CGPoint {
        self / length()
    }
    
    var angle: CGFloat {
        atan2(y, x)
    }
}


let pi = CGFloat.pi
func shortestAngleBetween(angle1: CGFloat,
                          angle2: CGFloat) -> CGFloat {
    let twoPi = pi * 2.0
    var angle = (angle2 - angle1).truncatingRemainder(dividingBy: twoPi)
    if angle >= pi {
        angle = angle - twoPi
    }
    if angle <= -pi {
        angle = angle + twoPi
    }
    return angle
}

extension CGFloat {
    func sign() -> CGFloat {
        self >= 0.0 ? 1.0 : -1.0
    }

    static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }
    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return CGFloat.random() * (max - min) + min
    }
}

var backgroundMusicPlayer: AVAudioPlayer!
func playBackgroundMusic(filename: String) {
    let resourceUrl = Bundle.main.url(forResource:
                                        filename, withExtension: nil)
    guard let url = resourceUrl else {
        print("Could not find file: \(filename)")
        return
    }
    do {
        try backgroundMusicPlayer = AVAudioPlayer(contentsOf: url)
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    } catch {
        print("Could not create audio player!")
        return
    }
}
