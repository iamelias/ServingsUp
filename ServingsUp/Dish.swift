//
//  Dish.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation
import UIKit

class Dish {
    var dishContents: [Ingredient] = [] //collection of ingredients
    var editedServings: String = ""
    var dishName = ""
    var creationDate = Date()
    var lastAccessed: Bool = false
}
