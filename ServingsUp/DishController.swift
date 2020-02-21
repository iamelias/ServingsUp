//
//  DishController.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//


import UIKit
import Foundation
import CoreData


class DishController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var quantLabel: UILabel!
    @IBOutlet weak var hideView: UIView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var stepper: UIStepper!
    
    let context = DatabaseController.persistentStoreContainer().viewContext
    var dishes: [CoreDish] = [] //stores dishes from core data, stored by creationdate
    var ingredients: [CoreIngredient] = [] //stores ingredients from core data
   // var ingDish: CoreDish! Last Dish
    var savedDishName: String = "" //dish name
    var tempDish: CoreDish?
    var tempIngred: CoreIngredient?
    var tab: TabShareController {
        return tabBarController as! TabShareController
    }
    var originalPhoto: UIImage! //storing original non-meme image


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        hideView.isHidden = false //blocking screen with hideview (*view)
        navigationItem.title = "Untitled"
        hideView.backgroundColor = .gray //hideview is gray (*view)
        hideView.alpha = 0.5 //hide view is 50% transparent (*view)
        saveButton.isEnabled = false // save button isn't enabled initially. need to add 1 ingredient first
        defaultView()
        fetchDishes() // getting all dishes in core data
        fetchIngredients() // getting all ingredients of last created entity
        tableView.reloadData() //necessary?
//        clearCoreIngredients()

        //tabBarController?.selectedIndex = 1 //If wanting to display BookController first //use with core data when determining if there is a saved dish
        
        if navigationItem.title != "Untitled" {
            saveButton.title = "New"
            saveButton.isEnabled = true
        }
    }
    
     override func viewWillAppear(_ animated: Bool) {
            cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) //disabling camera button if camera isn't available
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if dishes.last?.name != navigationItem.title {
//            let newDish = CoreDish()
//            dishes.append(newDish)
            defaultView()
        }
        if dishes.last?.name != navigationItem.title {
            dishes = tab.allDishes
            navigationItem.title = dishes.last?.name
            fetchIngredients()
            let newDishes = dishes
            tab.allDishes = newDishes
            tableView.reloadData()
        }
        if tab.returning == true {
            dishes = tab.allDishes
            tableView.reloadData()
            rearrangeDishes()
            fetchIngredients()
            tab.returning = false
            
        }
        
        if navigationItem.title == nil || navigationItem.title == "" {
            navigationItem.title = "Untitled"
        }
        
        if navigationItem.title != "Untitled" {
            saveButton.title = "New"
           // tab.returning = false
        }
        

    }

    func fetchDishes() { //Getting all dishes in creation date order, storing in "dishes" global array Type: CoreDish. The purpose of fetching dishes to get the last dish in the array of dishes to use for ingredients
        let fetchRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) //last dish is latest dated dish
        fetchRequest.sortDescriptors = [sortDescriptor] //last element is most recent date
        
        do {
            dishes = try context.fetch(fetchRequest) //getting all saved dishes and setting equal to dishes
            
            if !dishes.isEmpty {
            if dishes[0].name == "Untitled" {
                dishes.remove(at: 0)
                DatabaseController.saveContext()
            }
            }
        }
            
        catch{
            print("unable to fetch")
            return
        }
        
        //checkNilDish() //checking removing any nils from fetch
    
        guard dishes.last?.name != nil && dishes.last?.name != "" else {
            //If last element dish's name is nil or empty use default view
                    dishes = []
                    defaultView() // if last dish == nil or "" will use default view settings
                    return
                }
        if let checkDish = dishes.last { //if last dish != nil, use last dish to update view
                updateView(checkDish) // if last dish is not nil change view to reflect the new dish
        }
                let dishHolder = dishes
                tab.allDishes = dishHolder //updating shared all dishes with what was pulled
                tableView.reloadData() //table reloads after every fetch
    }
    
    func checkNilDish() { // will remove all nils in dishes after fetch if any
        for i in 0..<dishes.count {
            if dishes[i].name == nil {
                dishes.remove(at: i)
            }
        }
    }
    
    func checkNilIngredient() {
        for i in 0..<ingredients.count {
            if ingredients[i].name == nil && dishes[i].name == "Untitled" {
                ingredients.remove(at: i)
            }
        }
    }
    
    func updateView(_ selectedDish: CoreDish) { //change in view after fetch to show last in fetched array
        guard dishes.count != 0 else { return } // if dishes count is 0 return
        hideView.isHidden = true // turn off hideView

        navigationItem.title = dishes.last?.name ?? "Untitled" //used last dish name as navTitle
        stepper.value = Double(selectedDish.editedServings ?? "1") ?? 1.0 //updating stepper value and
        quantLabel.text = selectedDish.editedServings //stepper's label to reflect last dish's last settings.
        DatabaseController.saveContext()
    }
      func fetchIngredients() { //fetching ingredients that belong to specific dish. Displays them by creation date storing, ingredients in ingredients array
        guard dishes.count != 0 else { return} //dish count can't be 0 or will not fetch ingredients

        let ingredRequest: NSFetchRequest<CoreIngredient> = CoreIngredient.fetchRequest()
        let predicate = NSPredicate(format: "dish == %@", dishes.last!) //%@ with ingredients that belong to the specified property dish. dish property is set when saving dish
          ingredRequest.predicate = predicate
          
          let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true ) // from oldest(top) to newest(bottom)
          ingredRequest.sortDescriptors = [sortDescriptor]
    
          do {
              ingredients = try context.fetch(ingredRequest) //storing fetched ingredients in ingredients
            //print("fetched ingredients count: \(ingredients.count)")
          }
            
          catch{
              print("unable to fetch")
              return
          }
        
        checkNilIngredient() // checking/removing any nil ingredients
        
        if !ingredients.isEmpty { // if there is at least 1 ingredient, hideView will disappear
            hideView.isHidden = true
        }
        
        tableView.reloadData() //reload table to show ingredients
      }
    
    func putInTab() {
        tab.allDishes = dishes
    }
    
    func saveCoreDish(_ dish: CoreDish) { //saving added dish to core data
        var coreDish = CoreDish()
        coreDish = dish //making passed in object the object that will be saved in core data
        coreDish.name = dish.name
        coreDish.editedServings = quantLabel.text
        dishes.append(coreDish) //adding to local dishes array
        if dishes[0].name == "Untitled" {
            dishes.remove(at: 0)
        }
        DatabaseController.saveContext() //saving to core data
                
    }
    
    func saveCoreIng(_ food: CoreIngredient) -> CoreIngredient { //creates a CoreIngredient

        DatabaseController.saveContext()//saving new CoreIngredient into Core Data
        tempIngred = food
        return food
    }
    
    func updateIngredients(_ selectedDish: CoreDish) {
        for i in 0..<ingredients.count {
            ingredients[i].dish = selectedDish
            DatabaseController.saveContext()
        }
    }
    
    func addCoreIngredient(_ ingredient: CoreIngredient) { //adding CoreIngredients to "ingredients array)
        
        ingredients.append(ingredient)
        DatabaseController.saveContext()
        
    }
    
    func deleteCoreDishes() {
        for i in 0..<dishes.count {
            context.delete(dishes[i])
            context.delete(tempDish!)
            DatabaseController.saveContext()
        }
    }

    func clearCoreIngredients() { //empties core data
        ingredients = [] //emptying local ingredients
        for i in 0..<ingredients.count { //empties core data
            context.delete(ingredients[i])
            DatabaseController.saveContext()
        }
    }
    

    func deleteDish(_ selectDish: CoreDish) { //deletes a selected dish from core data
        dishes.removeLast() // will remove last dish
        tab.allDishes.removeLast()
        context.delete(selectDish)
        DatabaseController.saveContext()

    }
    
    func deleteIngredient(selectIngredient: CoreIngredient) { //deletes ingredient core data.

        context.delete(selectIngredient)
        DatabaseController.saveContext()
    }

    func defaultView() { //default view setting. If no dish is in dishes array
        navigationItem.title = "Untitled"
        saveButton.title = "Save"
        hideView.isHidden = true
        quantLabel.text = "1"
        stepper.value = 1.0
        
        //deleteIngredientsCore()
        tableView.reloadData()
    }
    
    func deleteIngredientsCore() {
        for i in 0..<ingredients.count { //deleting each ingredient from core data
            context.delete(ingredients[i])
        }
        ingredients = []
        dishes[dishes.count-1].editedServings = "1" //updating the editing servings
        DatabaseController.saveContext()
    }
    
    func newView(title: String) {
        ingredients = []
        navigationItem.title = title
        saveButton.title = "Save"
        hideView.isHidden = true
        quantLabel.text = "1"
        stepper.value = 1.0
        
        tableView.reloadData()
    }
     
    func createDish(_ selectedDish: String) -> CoreDish { //create new dish function
        let newDish = CoreDish(context: context)
//        let newDish = CoreDish()
        newDish.name = selectedDish
        newDish.editedServings = quantLabel.text
        newDish.creationDate = Date()
        
//        newView()
        //DatabaseController.saveContext()
        
        return newDish
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tab.allDishes = dishes
    }
    
    func saveImage() {
        let convertedPhoto = originalPhoto.pngData()
        dishes[dishes.count-1].image = convertedPhoto
        DatabaseController.saveContext()
        tab.allDishes = dishes
    }
    
    func rearrangeDishes() {
       // print("RRRRRRR rearranged called")
        dishes = tab.allDishes
        tab.selectedDish.creationDate = Date() //updating creation date
        //print("^^^^^\(tab.selectedDish.name!)")
        
        for i in 0..<dishes.count{ //Don't include last element in iteration
            if dishes[i].name == tab.selectedDish.name ?? "nil" { //removing dish from dishes if it matches the selected dish
            dishes.remove(at: i)
            break
            }
        }
        dishes.append(tab.selectedDish) //adding selected dish to end of array
        tab.allDishes = dishes

        updateView(dishes.last!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dishes = dishes.compactMap{$0}
        for i in 0..<dishes.count {
            if let checkDish = dishes[i].name {
            }
        }
        tab.allDishes = dishes
    }
    //
    @objc func alertBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil) //dismissing alert at background tap
    }
    
    func pickImageWith(sourceType: UIImagePickerController.SourceType) { //opens album/camera for image pick
         let pickImage = UIImagePickerController() //picking image
         pickImage.delegate = self
         pickImage.sourceType = sourceType
         present(pickImage, animated:true, completion:nil)
     }
     
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
         if let image = info[.originalImage] as? UIImage {
            //imagePickerView.image = image
             self.originalPhoto = image//storing image in property for save method
            saveImage()
             dismiss(animated: true, completion: nil) //closes image picker when image is selected
             
         }
     }
    
    
    
    //MARK: IBACTIONS - START
    @IBAction func stepperTapped(_ sender: UIStepper) { //Stepper changing quantLabel/number of servings
        var number = 1
        number = Int(sender.value)
        quantLabel.text = String(number)
        
        for i in 0..<ingredients.count {
            let converted = convertIngredient(food: ingredients[i])
            ingredients[i] = modifyExisting(converted, true, i)
            //DatabaseController.saveContext()
        }
        //update the stepper value and label in core data.
        dishes[dishes.count-1].editedServings = quantLabel.text
        DatabaseController.saveContext()
        tableView.reloadData()
    }
    @IBAction func cameraButtonTapped(_ sender: Any) {
        pickImageWith(sourceType: UIImagePickerController.SourceType.camera)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        let selectedVC = storyboard?.instantiateViewController(withIdentifier: "AddIngredientController") as! AddIngredientController
        
        selectedVC.chosenFood = self
        
        present(selectedVC, animated: true, completion: nil) //transitioning to AddIngredientController
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        createAlert(alertTitle: "Create Dish", alertMessage: "Enter the name of your new dish")
    }
    @IBAction func trashButtonTapped(_ sender: Any) {
        
        deleteDish(dishes[dishes.count-1]) //will delete the viewing dish
        clearCoreIngredients() // will delete all ingredients that are in ingredients array
        defaultView()
    }
    //MARK: IBACTIONS - END
}
  //MARK: ALERT - START
    extension DishController {
    func createAlert(alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle , message: alertMessage, preferredStyle: .alert)
        alert.addTextField()
        var submitTitle = "Save"
        if saveButton.title == "New" {
            submitTitle = "Create"
        }
        let submitAction = UIAlertAction(title: submitTitle, style: .default) { [unowned alert] _ in
            let answer = alert.textFields![0]
            self.savedDishName = answer.text ?? "Dish"
            guard self.savedDishName != "Dish" else {//Dish name is not allowed
                let passMessage = "Choose a different name"
                self.navigationItem.title = self.savedDishName
                self.createAlert(alertTitle: "Invalid", alertMessage: passMessage) //alert to rechoose name
                return
            }
            self.navigationItem.title = self.savedDishName // nav title updates to saved name
            
            let createdDish = self.createDish(answer.text!)

            
            if self.saveButton.title == "New" {
                self.ingredients = []
                self.navigationItem.title = createdDish.name
            }
            
            self.updateIngredients(createdDish) //changing the ingredients associated dish

            self.saveCoreDish(createdDish) //sending that object to be saved

            let dishHolder = self.dishes
            self.tab.allDishes = dishHolder
            self.tableView.reloadData()
            if self.navigationItem.title != "Untitled" {
            self.saveButton.title = "New"
            }
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

        return ingredients.count // number of cells = number of ingredients
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")
        
        guard ingredients.count != 0 else {
            return cell!
        }
        
        cell?.textLabel!.text = ingredients[indexPath.row].name //cel text = ingredient name at indexPath
        cell?.detailTextLabel!.text = String(ingredients[indexPath.row].modifiedIngredient!) //detailText = ingredient amount and unit combined into modifiedIngredient
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        deleteIngredient(selectIngredient: ingredients[indexPath.row])
        ingredients.remove(at: indexPath.row) //removing from array
        tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
    }
    
}
//MARK: TABLE VIEW - END

//MARK: ADD INGREDIENT DELEGATE - BEGIN
extension DishController: AddIngredientDelegate {

    func getIngredient(food: Ingredient) { //Getting new ingredient to add to dish
        saveButton.isEnabled = true //hideview disappears and save button is enabled when getting new ingredient
        hideView.isHidden = true

       // print("food amount: \(food.amount)")
       // print("food servings: \(food.servings)")
        if dishes.last?.name == nil {
            let newDish = CoreDish(context: context)
            newDish.name = "Untitled"
            newDish.editedServings = quantLabel.text
            newDish.stepperValue = stepper.value
            dishes.append(newDish)
            DatabaseController.saveContext()
        }
        
        let modifiedFood = modifyNew(food, false) //to change food weight/volume to be for 1 serving
        //let coreIng = saveCoreIng(modifiedFood) // creating a CoreIngredient
        addCoreIngredient(modifiedFood) //appending a core Ingredient to "ingredients"
        
        tab.allDishes = dishes
        tableView.reloadData() //reloading table to show new CoreIngredient
    }
    
    func convertIngredient(food: CoreIngredient) -> Ingredient { //converts from core to ingredient  to ingedient
        
        let ingredient = Ingredient()
        ingredient.name = food.name!
        ingredient.editedAmount = food.editedAmount
        ingredient.unit = food.unit!
        ingredient.amount = food.singleAmount // 1 serving of amount
    
        return ingredient
    }
    
    func modifyExisting(_ food: Ingredient? = nil, _ selfStepper: Bool, _ i: Int?) -> CoreIngredient{ //modifys an existing ingredient that came from fetch, updated with stepper
        
            ingredients[i!].creationDate = food!.creationDate
              ingredients[i!].name = food!.name
              ingredients[i!].singleAmount = food!.amount/Double(food!.servings) //amount per 1 serving
              let changedQuantLabel = Double(quantLabel!.text!) //converting self stepper to Double for calc
              ingredients[i!].editedAmount = ingredients[i!].singleAmount * Double(changedQuantLabel ?? 1.0) //amount dependant on stepper
              ingredients[i!].modifiedIngredient = "\(ingredients[i!].editedAmount)" + " \(food!.unit)"
              ingredients[i!].editedServings = "\(food!.servings)"
              //coreIn.singleAmount = food.singleAmount //amount per 1 serving
              ingredients[i!].unit = food!.unit
            
            DatabaseController.saveContext()
            return ingredients[i!]
        
    }
    
    func modifyNew(_ food: Ingredient? = nil, _ selfStepper: Bool) -> CoreIngredient{ //modifys a new ingredient that is newly made
        
     let coreIn = CoreIngredient(context: context)
     coreIn.creationDate = food!.creationDate
     coreIn.name = food!.name
     coreIn.singleAmount = food!.amount/Double(food!.servings) //amount per 1 serving
     let changedQuantLabel = Double(quantLabel!.text ?? "1") //converting self stepper to Double for calc
         coreIn.editedAmount = coreIn.singleAmount * Double(changedQuantLabel ?? 1.0) //amount dependant on stepper
     coreIn.modifiedIngredient = "\(coreIn.editedAmount)" + " \(food!.unit)"
     coreIn.editedServings = "\(food!.servings)"
     //coreIn.singleAmount = food.singleAmount //amount per 1 serving
     coreIn.unit = food!.unit
        // create a new coreDish and use that below to save as coreIn.dish
        coreIn.dish = dishes[dishes.count-1]
     DatabaseController.saveContext()//saving new CoreIngredient into Core Data
     tempIngred = coreIn
    
        
     return coreIn // returning a modified food details
        
    }
    //**********************************
    func modifyServingAmount(_ food: Ingredient? = nil, _ selfStepper: Bool, _ i: Int?) -> CoreIngredient { //changing weight/volume to match current screens stepper
        
        if i != nil {
            //let ingr = CoreIngredient(context: context)
              ingredients[i!].creationDate = food!.creationDate
              ingredients[i!].name = food!.name
              ingredients[i!].singleAmount = food!.amount/Double(food!.servings) //amount per 1 serving
              let changedQuantLabel = Double(quantLabel!.text!) //converting self stepper to Double for calc
              ingredients[i!].editedAmount = ingredients[i!].singleAmount * Double(changedQuantLabel ?? 1.0) //amount dependant on stepper
              ingredients[i!].modifiedIngredient = "\(ingredients[i!].editedAmount)" + " \(food!.unit)"
              ingredients[i!].editedServings = "\(food!.servings)"
              //coreIn.singleAmount = food.singleAmount //amount per 1 serving
              ingredients[i!].unit = food!.unit
            
            DatabaseController.saveContext()
            return ingredients[i!]
        }
        
        else if i == nil {
        let coreIn = CoreIngredient(context: context)
        coreIn.creationDate = food!.creationDate
        coreIn.name = food!.name
        coreIn.singleAmount = food!.amount/Double(food!.servings) //amount per 1 serving
        let changedQuantLabel = Double(quantLabel!.text ?? "1") //converting self stepper to Double for calc
            coreIn.editedAmount = coreIn.singleAmount * Double(changedQuantLabel ?? 1.0) //amount dependant on stepper
        coreIn.modifiedIngredient = "\(coreIn.editedAmount)" + " \(food!.unit)"
        coreIn.editedServings = "\(food!.servings)"
        //coreIn.singleAmount = food.singleAmount //amount per 1 serving
        coreIn.unit = food!.unit
        coreIn.dish = dishes[dishes.count-1] //coreIn.dish is the dish associated with this ingredient needed for fetch
        DatabaseController.saveContext()//saving new CoreIngredient into Core Data

        return coreIn // returning a modified food details
        }
        return tempIngred! // doesn't get called
    }
    
}

//MARK: - ADD INGREDIENT DELEGATE - END
