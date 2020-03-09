//
//  Ingredient.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation
import UIKit

   class Ingredient { //definition of an ingredient
    var name: String = ""
    var servings: Int = 1
    var amount: Double = 0.0
    var editedAmount: Double = 0.0
    var unit: String = ""
    var modifiedIngredient: String = ""
    var creationDate: Date = Date()
}
