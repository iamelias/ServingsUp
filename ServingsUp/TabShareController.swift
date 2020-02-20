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
    
    var allDishes: [CoreDish] = []
    var selectedDish: CoreDish! //assigned value when user selects cell in BookController, used in rearrange method in DishController
    var returning = false
    var deleting = false
    var tapped = false

}
