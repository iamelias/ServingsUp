//
//  Messages.swift
//  ServingsUp
//
//  Created by Elias Hall on 5/2/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation

enum Messages: String { //used for longer strings
    case neitherEmpty = "Neither name nor amount can be empty"
    case decimalFormat = "Please enter Initial Amount in decimal format "
    case smallerNumber = "Please enter a smaller number for Initial Amount"
    case shorterName = "Please enter a shorter name"
    case alreadyExists = "Dish already exists"
    case enterName = "Please enter a name"
    case existsError = "This dish already exists"
    case unableToFetch = "unable to fetch"
    case differentName = "Please use a different name"
    case enterNameDish = "Enter the name of your dish."
    case dishNameQuestion = "What will your new dish be called?"
    case permDeleteDish = "Are you sure you want to permanently delete this dish?"
    case newDishName = "Please enter a new name for this dish "
}
