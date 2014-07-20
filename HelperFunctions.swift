//
//  HelperFunctions.swift
//  HelperFunctions
//
//  Created by Rodrigo Villatoro on 7/10/14.
//  Copyright (c) 2014 RVD. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

func CGPointMultiplyScalar(a: CGPoint, b: CGFloat) -> CGPoint {
    return CGPointMake(a.x * b, a.y * b)
}

func CGPointAdd(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPointMake(a.x + b.x, a.y + b.y)
}

func CGPointSubtract(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPointMake(a.x - b.x, a.y - b.y)
}

func Clamp(value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return value < min ? min : value > max ? max : value
}

func returnMax(a: CGFloat, b: CGFloat) -> CGFloat {
    return a > b ? a : b
}

func returnMin(a: CGFloat, b: CGFloat) -> CGFloat {
    return a < b ? a : b
}

func scalarSign(a: CGFloat) -> CGFloat {
    return a > 0 ? 1 : -1
}

//func scalarShortestAngleBetween(a: CGFloat, b: CGFloat) -> CGFloat {
//    var difference = a - b
//    var angle = fmodf(difference, CGFloat(M_PI)* 2.0)
//    if angle >= CGFloat(M_PI) {
//        angle -= CGFloat(M_PI) * 2.0
//    } else if angle <= -CGFloat(M_PI) {
//        angle += CGFloat(M_PI) * 2.0
//    }
//    return angle
//}

func CGPointLength(a: CGPoint) -> CGFloat {
    return CGFloat(sqrtf(CFloat(a.x * a.x + a.y * a.y)))
}

func CGPointNormalize(a: CGPoint) -> CGPoint {
    let length = CGPointLength(a)
    return CGPointMake(a.x / length, a.y / length)
}

func CGPointToAngle(a: CGPoint) -> CGFloat {
    return CGFloat(atan2(CDouble(a.y), CDouble(a.x)))
}

func randomNumberBetween(minNum: CGFloat, maxNum: CGFloat) -> CGFloat {
    let randomNumber = CGFloat(arc4random())
    return randomNumber % (maxNum - minNum + 1) + minNum
}
