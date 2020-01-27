//
//  TabShareController.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation
import UIKit
import CoreData




import Foundation
import UIKit

class TabShareController: UITabBarController {
    var ingredArray: [Ingredient] = [] //contains all the ingredients to be displayed in dishController
    var foodName: String = "Empty" //contains food name that will be title of Dish Controller
    var servings: String = "" //DishController saved stepper value
    var saving: Bool = false
    var returning: Bool = false
    
    var testBookArray: [Dish] = [] //test transfering data to from DishtoBook controller
    var stringArray: [String] = [] //Array holding string name of all objects for search
    var arrayIndex: Int?
}
