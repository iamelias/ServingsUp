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
    //var selectedDish: CoreDish!
    var fetchResult: [CoreDish] = [] //retrieved dishes from core data
    var fetchIngResults: [CoreIngredient] = []
    var ingredients: [CoreIngredient] = [] //stores ingredients frommm core data
    var savedDishName: String = "" //dish name
    var recievedData: UITabBarDelegate!
    var globalTab: TabShareController {
        let tab = tabBarController as! TabShareController
        return tab
    }
    var navigationTitleEmpty: Bool {
        if savedDishName == "" && navigationItem.title == "" { //if there is not a saved name and default
            return true
        }
        
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        hideView.isHidden = false //blocking screen with hideview (*view)
        hideView.backgroundColor = .gray //hideview is gray (*view)
        hideView.alpha = 0.5 //hide view is 50% transparent (*view)
        saveButton.isEnabled = false // save button isn't enabled initially. need to add 1 ingredient first
        //retrieveCoreData() //calling to retrieve all dishes and ingredients from core data. (Move to ViewDidAppear)
        //fetchDishes() // getting all dishes in core data
        //fetchIngredients() // getting all ingredients of last created entity
        //tableView.reloadData()

        //tabBarController?.selectedIndex = 1 //If wanting to display BookController first //use with core data when determining if there is a saved dish
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let tab = tabBarController as! TabShareController

        if tab.returning == true { //if returning from BookController
            navigationItem.title = tab.testBookArray[tab.arrayIndex!].dishName //use saved dishTitle
            ingredientsArray = tab.ingredArray //using saved ingredients array for specific cell
            tab.returning = false //turning off tab returning
        }
        tableView.reloadData()
    }
    
    
    func fetchDishes() { //Getting all dishes in creation date order, storing in dishes global array
        
        let fetchRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
//        let predicate = NSPredicate(format: "lastAccessed == true")
//        fetchRequest.predicate = predicate
        
        do {
            fetchResult = try context.fetch(fetchRequest) //setting fetched result into array
            dishes = fetchResult
        }
        catch{
            print("unable to fetch")
            //            debugprint(error)
            return
        }
    }
    
    func getCurrentDish() -> CoreDish { // returns the last created dish in dishes array
        let lastDish = dishes.popLast() //most recently created
        return lastDish!
    }
    
    func fetchIngredients() { //fetching ingredients that belong to specific dish. Displays them by creation date storing, ingredients in ingredients global array
        
        let selectedDish = getCurrentDish() //getting last dish in dishes array/ most recent created dish
        
        let fetchRequest: NSFetchRequest<CoreIngredient> = CoreIngredient.fetchRequest()
        let predicate = NSPredicate(format: "dish == %@", selectedDish) //%@ will get replaced by selectedPin at runtime. Purpose is to get photos filtered for selected pin
        fetchRequest.predicate = predicate //using setup predicate
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false ) //top is newest photos
        fetchRequest.sortDescriptors = [sortDescriptor]
  
        do {
            fetchIngResults = try context.fetch(fetchRequest) //setting fetched result into array
            ingredients = fetchIngResults
        }
        catch{
            print("unable to fetch")
            return
        }
    }
    
    func retrieveCoreData() { //Getting core data will return dish objects
        //will retrieve from core data full Book. Will retrieve all the dishes and will make it the initial value of the Book class array
        
        let testDishes1 = Dish()
        testDishes1.dishName = "Meal1"
        let testDishes2 = Dish()
        testDishes2.dishName = "Meal2"
        let testDishes3 = Dish()
        testDishes3.dishName = "Meal3"
        let testDishes4 = Dish()
        testDishes4.dishName = "Meal4"
        let testDishes5 = Dish()
        testDishes5.dishName = "Meal5"
        
        let testDishArray: [Dish] = [testDishes1,testDishes2,testDishes3,testDishes4,testDishes5]
        
        let testBook = testDishArray //testBook will be used in place of coredata to test to rep array of dishes
        
        let tab = tabBarController as! TabShareController
        tab.testBookArray = testBook //setting retrieved book array to tabshare book array
    }

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
    @IBAction func test(_ sender: Any) {
        tableView.reloadData()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
        createAlert(alertTitle: "Create Dish", alertMessage: "Enter the name of your new dish")
    }
    @IBAction func trashButtonTapped(_ sender: Any) {
        defaultView()
    }
    
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
            
            self.navigationItem.title = self.savedDishName
            let newDish = self.createDishObject()
            self.addToTabBook(newDish)
        }
        
        alert.addAction(submitAction)
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    func defaultView() {
        ingredientsArray = []
        navigationItem.title = "Untitled"
        quantLabel.text = "1"
        
        tableView.reloadData()
    }
    
    func addToTabBook(_ newDish: Dish) {
        let tab = tabBarController as! TabShareController
        tab.testBookArray.append(newDish)
        
    }
    
    func createDishObject() -> Dish {
        let dishObject = Dish()
        dishObject.dishContents = self.ingredientsArray
        dishObject.editedServings = quantLabel.text ?? "1"
        dishObject.dishName = savedDishName
        dishObject.creationDate = Date()
        
        return dishObject
    }
    
    func saveCurrentDish() { //presents another alert
        
        let tab = self.tabBarController as! TabShareController //saving
        tab.ingredArray = self.ingredientsArray
        tab.foodName = self.savedDishName
        tab.servings = self.quantLabel.text ?? "1" //modified servings
        tab.saving = true
        
    }
    
    @objc func alertBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil) //dismissing alert at background tap
    }
}















//MARK: TableViewController
extension DishController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
    
        if dishes.count == 0 { //if there are no cells title and servings count go back to default
            if savedDishName == "" { // if there is no saved name
            navigationItem.title = "Untitled"
            quantLabel.text = "1"
            }
        }
        
        return ingredients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")
        
        cell?.textLabel!.text = ingredients[indexPath.row].name
        cell?.detailTextLabel!.text = String(ingredients[indexPath.row].modifiedIngredient!)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        ingredients.remove(at: indexPath.row) //removing from array
        tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
    }
}

extension DishController: AddIngredientDelegate {
    
    func getIngredient(food: Ingredient) { //Getting new ingredient to add to dish
        saveButton.isEnabled = true //hideview disappears and save button is enabled when getting new ingredient
        hideView.isHidden = true

        let modifiedFood = modifyServingAmount(food, false) //to change food weight/volume to be for 1 serving
        ingredientsArray.append(modifiedFood) //adding modified food object to array
        
        tableView.reloadData() //reloading table to show food object
    }
    
    func modifyServingAmount(_ food: Ingredient, _ selfStepper: Bool) -> Ingredient { //changing weight/volume to match current screens stepper
        
        food.editedAmount = food.amount/Double(food.servings) //getting weight/volume for 1 serving
        
        let changedQuantLabel = Double(quantLabel!.text!) //converting self stepper to Double for calc
        
        food.editedAmount = food.editedAmount * Double(changedQuantLabel ?? 1.0) //changing
        
        food.modifiedIngredient = "\(food.editedAmount)" + " \(food.unit)"
        
        return food
    }
}

