// Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

func randomPositiveOrNegative() -> Int {
    let number = Int(arc4random() % 2)
    return number == 0 ? -1 : 1
}
