//
//  DishController.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

//Recieves Ingredient objects from AddIngredientController. Ingredient Object has a name, serving size, serving amount, and a unit of measurement. Ingredient object is displayed on tableView. Need to edit serving amount to reflect stepper choice in this controller.

import UIKit
import Foundation
import CoreData


class DishController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var quantLabel: UILabel!
    @IBOutlet weak var hideView: UIView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let context = DatabaseController.persistentStoreContainer().viewContext
    var ingredientsArray: [Ingredient] = [] //holds all current dish ingredients
    var dishes: [CoreDish] = [] //stores dishes from core data, stored by creationdate
    var ingredients: [CoreIngredient] = [] //stores ingredients from core data
   // var ingDish: CoreDish! Last Dish
    var savedDishName: String = "" //dish name
    var tab: TabShareController {
        return tabBarController as! TabShareController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        hideView.isHidden = false //blocking screen with hideview (*view)
        hideView.backgroundColor = .gray //hideview is gray (*view)
        hideView.alpha = 0.5 //hide view is 50% transparent (*view)
        saveButton.isEnabled = false // save button isn't enabled initially. need to add 1 ingredient first
        fetchDishes() // getting all dishes in core data
        fetchIngredients() // getting all ingredients of last created entity
        tableView.reloadData()

        //tabBarController?.selectedIndex = 1 //If wanting to display BookController first //use with core data when determining if there is a saved dish
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if tab.returning == true {
            rearrangeDishes()
            tab.returning = false
        }
        print("disches count: \(dishes.count)")
//        deleteCoreDishes()
//        print("dishes count: \(dishes.count)")

    }
    
    func fetchDishes() { //Getting all dishes in creation date order, storing in "dishes" global array Type: CoreDish. The purpose of fetching dishes to get the last dish in the array of dishes to use for ingredients
        
        let fetchRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) //last dish is latest dated dish
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            dishes = try context.fetch(fetchRequest) //setting fetched result into array
            guard dishes.count != 0 else {
                return
            }
            let homeDish = getCurrentDish()
            updateView(homeDish)
        }
        catch{
            print("unable to fetch")
//                        debugprint(error)
            return
        }
    }
    func updateView(_ selectedDish: CoreDish) {
        hideView.isHidden = true
        navigationItem.title = selectedDish.name
        quantLabel.text = selectedDish.editedServings
    
        
    }
    
      func fetchIngredients() { //fetching ingredients that belong to specific dish. Displays them by creation date storing, ingredients in ingredients global array
        
        guard dishes.count != 0 else { return}
          let selectedDish = getCurrentDish() //getting last dish in dishes array/ most recent created dish
          
          let fetchRequest: NSFetchRequest<CoreIngredient> = CoreIngredient.fetchRequest()
          let predicate = NSPredicate(format: "dish == %@", selectedDish) //%@ will get replaced selected dish at runtime
          fetchRequest.predicate = predicate //using setup predicate
          
          let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true ) //last ingredient is latest dated ingredient
          fetchRequest.sortDescriptors = [sortDescriptor]
    
          do {
              ingredients = try context.fetch(fetchRequest) //fetched results stored in ingredients
          }
          catch{
              print("unable to fetch")
              return
          }
      }
    
    func saveCoreDish(_ dish: CoreDish) { //saving added dish to core data
        var coreDish = CoreDish(context: context)
        coreDish = dish //making passed in object the object that will be saved in core data
        DatabaseController.saveContext() //saving to core data
        
        dishes.append(coreDish) //adding to local dishes array
    }
    
    
    func saveCoreIng(_ food: Ingredient) -> CoreIngredient { //creates a CoreIngredient
        let coreIn = CoreIngredient(context: context)
        coreIn.creationDate = food.creationDate
        coreIn.name = food.name
        coreIn.modifiedIngredient = food.modifiedIngredient
        coreIn.editedServings = "\(food.servings)"
        //coreIn.lastAccessed = Date()
        DatabaseController.saveContext() //saving new CoreIngredient into Core Data
        
        return coreIn
        
    }
    
    func addCoreIngredient(_ ingredient: CoreIngredient) { //adding CoreIngredients to "ingredients array)
        
        ingredients.append(ingredient)
    }
    
    func getCurrentDish() -> CoreDish { // returns the last created dish in dishes array. Used in fetchIngredients for ingredients call
        
        let lastDish = dishes.popLast() //most recently created
       // ingDish = lastDish // saving a copy to class property
        return lastDish!
    }
    
    func deleteCoreDishes() {
        for i in 0..<dishes.count {
            context.delete(dishes[i])
            DatabaseController.saveContext()
        }
    }

    func clearCoreIngredients() { //empties core data
        for i in 0..<ingredients.count { //empties core data
            context.delete(ingredients[i])
            DatabaseController.saveContext()
        }
    }
    
    func deleteDish(selectDish: CoreDish) { //deletes a selected dish from core data
        context.delete(selectDish)
        DatabaseController.saveContext()
    }
    
    func deleteIngredient(selectIngredient: CoreIngredient) { //deletes ingredient core data.

        context.delete(selectIngredient)
        DatabaseController.saveContext()
    }

    func defaultView() { //default view if no dish is selected
        ingredients = []
        clearCoreIngredients() // removes all ingredients from core data
        navigationItem.title = "Untitled"
        quantLabel.text = "1"
        
        tableView.reloadData()
    }
    
    func createDish(_ selectedDish: String) -> CoreDish { //create new dish function
        let newDish = CoreDish(context: context)
        newDish.name = selectedDish
        newDish.editedServings = quantLabel.text
        newDish.creationDate = Date()
        
        return newDish
    }
    
    func rearrangeDishes() {
        tab.selectedDish.creationDate = Date() //updating creation date
        dishes.append(tab.selectedDish) //adding selected dish to end of array
        for i in 0..<dishes.count - 1 { //Don't include last element in iteration
            if dishes[i] == tab.selectedDish! { //removing dish from dishes if it matches the selected dish
            dishes.remove(at: i)
            
            //break
            }
            else { print("dish was not removed from dishes in DishController")}
        }
    }
    
    @objc func alertBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil) //dismissing alert at background tap
    }
    
    //MARK: IBACTIONS - START
    @IBAction func stepperTapped(_ sender: UIStepper) { //Stepper changing quantLabel/number of servings
        var number = 1
        number = Int(sender.value)
        quantLabel.text = String(number)
        
        for i in 0..<ingredientsArray.count {
            ingredientsArray[i] = modifyServingAmount(ingredientsArray[i], true)
        }
        tableView.reloadData()
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        let selectedVC = storyboard?.instantiateViewController(withIdentifier: "AddIngredientController") as! AddIngredientController
        
        selectedVC.chosenFood = self
        
        present(selectedVC, animated: true, completion: nil)
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        createAlert(alertTitle: "Create Dish", alertMessage: "Enter the name of your new dish")
    }
    @IBAction func trashButtonTapped(_ sender: Any) {
        defaultView()
    }
    //MARK: IBACTIONS - END
}
  //MARK: ALERT - START
    extension DishController {
    func createAlert(alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle , message: alertMessage, preferredStyle: .alert)
        alert.addTextField()
        
        let submitAction = UIAlertAction(title: "Save", style: .default) { [unowned alert] _ in
            let answer = alert.textFields![0]
            self.savedDishName = answer.text ?? "Dish"
            guard self.savedDishName != "Dish" else {//Dish name is not allowed
                let passMessage = "Choose a different name"
                self.navigationItem.title = self.savedDishName
                self.createAlert(alertTitle: "Invalid", alertMessage: passMessage) //alert to rechoose name
                return
            }
            self.navigationItem.title = self.savedDishName // nav title updates to saved name
            let newDish = self.createDish(self.savedDishName)//creating an object that has input text as property
            self.saveCoreDish(newDish) //sending that object to be saved
            self.tableView.reloadData()
        }
        
        alert.addAction(submitAction)
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
}

//MARK: ALERT - END














//MARK: TABLE VIEW - START
extension DishController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
    
        if dishes.count == 0 { //if there are no cells title and servings count go back to default
            if savedDishName == "" { // if there is no saved name
            navigationItem.title = "Untitled"
            quantLabel.text = "1"
            }
        }
        
        return ingredients.count // number of cells = number of ingredients
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")
        
        cell?.textLabel!.text = ingredients[indexPath.row].name //cel text = ingredient name at indexPath
        cell?.detailTextLabel!.text = String(ingredients[indexPath.row].modifiedIngredient!) //detailText = ingredient amount and unit combined into modifiedIngredient
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        ingredients.remove(at: indexPath.row) //removing from array
        deleteIngredient(selectIngredient: ingredients[indexPath.row])
        tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
    }
}
//MARK: TABLE VIEW - END

//MARK: ADD INGREDIENT DELEGATE - BEGIN
extension DishController: AddIngredientDelegate {
    
    func getIngredient(food: Ingredient) { //Getting new ingredient to add to dish
        saveButton.isEnabled = true //hideview disappears and save button is enabled when getting new ingredient
        hideView.isHidden = true

        let modifiedFood = modifyServingAmount(food, false) //to change food weight/volume to be for 1 serving
        let coreIng = saveCoreIng(modifiedFood) // creating a CoreIngredient
        addCoreIngredient(coreIng) //appending a core Ingredient to "ingredients"
        
        tableView.reloadData() //reloading table to show new CoreIngredient
    }
    
    func modifyServingAmount(_ food: Ingredient, _ selfStepper: Bool) -> Ingredient { //changing weight/volume to match current screens stepper
        
        food.editedAmount = food.amount/Double(food.servings) //getting weight/volume for 1 serving
        
        let changedQuantLabel = Double(quantLabel!.text!) //converting self stepper to Double for calc
        
        food.editedAmount = food.editedAmount * Double(changedQuantLabel ?? 1.0) //changing
        
        food.modifiedIngredient = "\(food.editedAmount)" + " \(food.unit)"
        
        return food
    }
}

//MARK: - ADD INGREDIENT DELEGATE - END
