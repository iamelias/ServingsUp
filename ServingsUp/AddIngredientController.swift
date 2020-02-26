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
    var selectedUnit: String = "g" //unit selected with pickerview
    var checker = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitPicker.delegate = self
        unitPicker.dataSource = self
        textField.delegate = self
        amountTextField.delegate = self
        
        
        selectedUnitArray = weightUnitArray
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddIngredientController.action)) //when view is tapped picker/keyboard is dismissed
        
        view.addGestureRecognizer(tapGesture)
        // unitPicker.resignFirstResponder()
        
        let swipeGesture: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(AddIngredientController.action))
        view.addGestureRecognizer(swipeGesture)
        
        unitPicker.selectRow(1, inComponent: 0, animated: true)
        if unitPicker.isUserInteractionEnabled {
            view.endEditing(true)
        }
    }
    
    @objc func action() {
        view.endEditing(true)
    }
    
    
    @IBAction func stepperUsed(_ sender: UIStepper) {
        var number = 0
        number = Int(sender.value)
        servingsNumLabel.text = String(number)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
       let firstCheck = stringCountCheck(textField.text)
        if firstCheck == false {
        textField.shake()
        }
        guard firstCheck == true else { return}
      
       let secondCheck = stringCountCheck(amountTextField.text)
        if secondCheck == false {
        amountTextField.shake()
        }
        guard firstCheck == true && secondCheck == true else {
            //checker = true
            return
        }
        print("***** \(secondCheck)")
        if firstCheck == false || secondCheck == false {
            return
        }
        
        
        let amountFormatCheck = decimalCheck(amountTextField.text ?? "a")
        guard amountFormatCheck == true else {
            return 
        }
       createIngredient()
        dismiss(animated: true)
    }
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        dismiss(animated: true) //closing viewController
    }
    
    @IBAction func unitButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        switch sender.tag {
        case 1: selectedUnitArray = weightUnitArray
        case 2: selectedUnitArray = volumeUnitArray
        default: selectedUnitArray = weightUnitArray
        }
        
        unitPicker.reloadAllComponents()
    }
    
    func hapticError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func createIngredient() { //creating Ingredient object to be sent back to DishController
        let ingredient = Ingredient()
        ingredient.name = textField.text! //ingredient name
        //stringCountCheck(ingredient.name)
        let testServings = Int(servingsNumLabel!.text!)
        ingredient.servings = Int(testServings ?? 1)   //storing initial servingsNum as an int
        let testAmount = Double(amountTextField!.text!)
        ingredient.amount = Double(testAmount ?? 0.0) //storing initial amount of unit as double
        ingredient.unit = selectedUnit
        
        chosenFood.getIngredient(food: ingredient)
    }
    
    func showAlert(selectedAlert: (String, String))  {
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Back", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true)
        
    }
    
    func stringCountCheck(_ value: String?) -> Bool {
        print("^^^^ \(value?.count ?? 999999)")
        
        if value!.count == 0 {
            showAlert(selectedAlert: ("Error","Neither name or amount can be empty"))
            //textField.shake()
            hapticError()
            print("returning false")
            return false
           // checker = false
        }
        else if value!.count>20 {
            showAlert(selectedAlert:("Error","Enter a shorter name"))
            
            hapticError()
            print("returning false")
            return false
            //checker = false
        }

        return true
    }
    
    
    func decimalCheck(_ value: String) -> Bool {
        let checkNum = Double(value)
        if checkNum == nil {
            showAlert(selectedAlert: ("Error","Amount can only be in decimal notation"))
            return false
        }
        
        
        return true
    }
    

}

extension AddIngredientController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        textField.resignFirstResponder()
        return true
}
}

extension UITextField {
    func shake() { //setting up shake animation for alert error
        let animation = CABasicAnimation(keyPath: "position")
        animation.repeatCount = 2
        animation.duration = 0.05
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.center.x - 4.0, y: self.center.y)
        animation.toValue = CGPoint(x: self.center.x + 4.0, y: self.center.y)
        layer.add(animation, forKey: "position")
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
        //view.begin
        view.endEditing(true)
        
    }
}

