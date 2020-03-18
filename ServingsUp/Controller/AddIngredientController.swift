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
    func getIngredient(food: Ingredient, type: String, index: Int?)
}

class AddIngredientController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var servingsNumLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var unitPicker: UIPickerView!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyDishIcon: UIImageView!
    
    var chosenFood: AddIngredientDelegate!
    var passServings: Double!
    var updateIngredient: CoreIngredient!
    var passIndex: Int!
    var massUnitArray: [String] = ["","oz","mg","g","kg","lb"] //tag 1
    var volumeUnitArray: [String] = ["","oz","tsp","tbsp","cup","pt","qt","mL","L","gal"] //tag 2
    var selectedUnitArray:[String] = [] //for picker display
    var selectedUnit: String = "" //default mass unit selected with pickerview
    let tryAgain = "Try Again"
    let blankError = "Please enter a name"
    
    //MARK: VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        unitPicker.delegate = self
        unitPicker.dataSource = self
        textField.delegate = self
        amountTextField.delegate = self
        stepper.value = passServings
        servingsNumLabel.text = "\(Int(stepper.value))"
        
        selectedUnitArray = massUnitArray
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddIngredientController.action)) //adding tap gesture
        
        view.addGestureRecognizer(tapGesture)
        
        let swipeGesture: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(AddIngredientController.action)) //adding swipe gesture
        view.addGestureRecognizer(swipeGesture)
        
        unitPicker.selectRow(0, inComponent: 0, animated: true) // default picker selection
        if unitPicker.isUserInteractionEnabled { // if picker is being moved
            view.endEditing(true) //dismiss keyboard
        }
    
        amountTextField.keyboardType = .decimalPad
        preSet(updateIngredient) //if updating instead of adding new, will fill in view with already existing values
        
        createToolbar() //creating toolbar for the num pad's keyboard
        
    }
    
    //MARK: ADDITIONAL METHODS
    func createToolbar() {
        let numPadToolbar: UIToolbar = UIToolbar()
        
        numPadToolbar.barStyle = UIBarStyle.default
        numPadToolbar.items=[
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(self.resignKeyboard))
        ]
        
        numPadToolbar.sizeToFit()
        
        amountTextField.inputAccessoryView = numPadToolbar
    }
    
    @objc func resignKeyboard () {
        amountTextField.resignFirstResponder()
    }
    
    func preSet(_ ingredient: CoreIngredient?) {
        guard ingredient != nil else {
            return
        }
        
        textField.text = ingredient?.name ?? ""
        var reformattedAmount = String(format: "%.3f", ingredient!.editedAmount) //with trailing zeros
        
        reformattedAmount = removeTrailingZeros(reformattedAmount) //removes trailing zeros

        amountTextField.text = reformattedAmount //without trailing zeros
        
        if ingredient!.unit! == "cups" {
            ingredient!.unit! = "cup"
        }
        if volumeUnitArray.contains(ingredient!.unit!) {
            selectedUnitArray = volumeUnitArray
            unitPicker.reloadAllComponents()
            let position = volumeUnitArray.firstIndex(of: ingredient!.unit!)
            unitPicker.selectRow(position ?? 0, inComponent: 0, animated: true) // default picker selection
            selectedUnit = ingredient!.unit!
        }
        else if massUnitArray.contains(ingredient!.unit!) {
            let position = massUnitArray.firstIndex(of: ingredient!.unit!)
            unitPicker.selectRow(position ?? 0, inComponent: 0, animated: true) // default picker selection
            selectedUnit = ingredient!.unit!
        }
        
        addButton.setTitle("Update", for: .normal)
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
        var testAmount = amountTextField.text!
        
        testAmount = testAmount.trimmingCharacters(in: .whitespaces) //removing empty spaces from decimal amount   
        let testAmountDouble = Double(testAmount)
        ingredient.amount = Double(testAmountDouble ?? 0.0) //storing initial amount of unit as double
        ingredient.unit = selectedUnit
        
        chosenFood.getIngredient(food: ingredient, type: addButton.currentTitle!, index: passIndex)
    }
    
    func removeTrailingZeros(_ passText: String) -> String {
        
        var text = passText
        while text.last == "0" { //if last letter is 0
            text.removeLast() //remove it
            if text.last == "." { //check if last element is "."
                text.removeLast() //also remove it
                break //will not remove before whole number
            }
        }
        return text
    }
    
    func stringCountCheck(_ value: String?) -> Bool {
        if value!.count == 0 { //if input string count is 0
            showAlert(selectedAlert: (tryAgain,"Neither name nor amount can be empty"))
            return false
        }
        else if value!.count >= 20 { // if input string count is greater than 20
            showAlert(selectedAlert:(tryAgain,"Please enter a shorter name for the Ingredient"))
            return false
        }
        return true
    }
    
    func decimalCheck(_ value: String) -> Bool { //making sure input is a double number
        
        let filteredValue = value.trimmingCharacters(in: .whitespaces) //removing empty spaces from decimal amount
        let checkNum = Double(filteredValue)
        if checkNum == nil {
            amountTextField.shake()
            showAlert(selectedAlert: (tryAgain,"Please enter Initial Amount in decimal format"))
            return false
        }
        if checkNum! >= 10000 {
            amountTextField.shake()
            showAlert(selectedAlert: (tryAgain,"Please enter smaller number for Initial Amount"))
            return false
        }
        return true
    }
    
    @objc func action() { // if tap or swipe dismiss keyboard
        view.endEditing(true)
    }
    
    //MARK: ALERT METHODS
    func showAlert(selectedAlert: (String, String))  {
        hapticError()
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Back", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    //MARK: IBACTION METHODS
    @IBAction func stepperUsed(_ sender: UIStepper) { // when stepper is tapped
        let number = Int(sender.value)
        servingsNumLabel.text = String(number)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let firstCheck = stringCountCheck(textField.text) //checking string character count returns true or false
        if firstCheck == false {
            textField.shake() // if false shake texfield
        }
        guard firstCheck == true else { return} //don't proceed if firstCheck == false
        
        let secondCheck = stringCountCheck(amountTextField.text) //verify string character count returns true/false
        if secondCheck == false {
            amountTextField.shake()
        }
        guard firstCheck == true && secondCheck == true else { //Both firstCheck and secondCheck must be true else return
            return
        }
        
        let amountFormatCheck = decimalCheck(amountTextField.text ?? "a") //checking if number fits input rules
        guard amountFormatCheck == true else { // if not return
            return 
        }
        createIngredient() //create ingredient then dismiss
        dismiss(animated: true)
    }
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        dismiss(animated: true) //closing viewController
    }
    
    @IBAction func unitButtonTapped(_ sender: UIButton) {
        view.endEditing(true) //dismissing keyboard
        switch sender.tag { //unit array for picker is being selected
        case 1: selectedUnitArray = massUnitArray
        case 2: selectedUnitArray = volumeUnitArray
        default: selectedUnitArray = massUnitArray
        }
        
        if selectedUnitArray == volumeUnitArray {
            selectedUnit = ""
        }
        
        unitPicker.reloadAllComponents() //reloading pickerview to reflect selected unit button
    }
}

//MARK: DELEGATE METHODS
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

//MARK: PICKERVIEW METHODS
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
        view.endEditing(true)
    }
}

