//
//  AddIngredientController.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation
import UIKit

protocol AddIngredientDelegate {
    
    func getIngredient(food: Ingredient)

}

class AddIngredientController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var servingsNumLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var unitPicker: UIPickerView!
    
    var chosenFood: AddIngredientDelegate!
    var weightUnitArray: [String] = ["mg", "g", "lb"] //tag 1
    var volumeUnitArray: [String] = ["oz","tsp","tbsp","cup","pt","ml","gallon"] //tag 2
    var selectedUnitArray:[String] = [] //for picker display
    var selectedUnit: String = "" //unit selected with pickerview
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitPicker.delegate = self
        unitPicker.dataSource = self
        textField.delegate = self
        amountTextField.delegate = self
        selectedUnitArray = weightUnitArray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    @IBAction func stepperUsed(_ sender: UIStepper) {
        var number = 0
        number = Int(sender.value)
        servingsNumLabel.text = String(number)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
       createIngredient()
        dismiss(animated: true)
    }
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        dismiss(animated: true) //closing viewController
    }
    
    @IBAction func unitButtonTapped(_ sender: UIButton) {
        
        switch sender.tag {
        case 1: selectedUnitArray = weightUnitArray
        case 2: selectedUnitArray = volumeUnitArray
        default: selectedUnitArray = weightUnitArray
        }
        
        unitPicker.reloadAllComponents()
    }
    
    
    func createIngredient() { //creating Ingredient object to be sent back to DishController
        let ingredient = Ingredient()
        ingredient.name = textField.text! //ingredient name
        let testServings = Int(servingsNumLabel!.text!)
        ingredient.servings = Int(testServings ?? 1)   //storing initial servingsNum as an int
        let testAmount = Double(amountTextField!.text!)
        ingredient.amount = Double(testAmount ?? 0.0) //storing initial amount of unit as double
        ingredient.unit = selectedUnit
        
        chosenFood.getIngredient(food: ingredient)
    }
}

extension AddIngredientController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        textField.resignFirstResponder()
        return true
}
}

extension AddIngredientController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectedUnitArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return selectedUnitArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedUnit = selectedUnitArray[row]
    }
    
}

