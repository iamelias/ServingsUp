//
//  AddDishController.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation
import UIKit

protocol DishDelegate {
    func getDish(passingDish: Dish)
}

class AddDishController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!
    
    var selectedDish:DishDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func addTapped(_ sender: Any) {
        
        let passingDish = Dish()
        passingDish.dishName = textField?.text ?? "empty" //saving copy of name for BookController
        
        selectedDish.getDish(passingDish: passingDish ) //passing name back
        dismiss(animated: true) //closing view controller
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
}

