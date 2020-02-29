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
    var checker: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.title = "Untitled"
        saveButton.isEnabled = false // save button isn't enabled initially. need to add 1 ingredient first
        defaultView()
        fetchDishes() // getting all dishes in core data
        fetchIngredients() // getting all ingredients of last created entity
        tableView.reloadData() //necessary?

        //tabBarController?.selectedIndex = 1 //If wanting to display BookController first //use with core data when determining if there is a saved dish
        cameraButton.isEnabled = true //enabling camera if navTitle does not equal untitled
        if navigationItem.title != "Untitled" {
            saveButton.title = "New"
            cameraButton.isEnabled = false //disabling camera if navTitle = "Untitled"
            saveButton.isEnabled = true
        }
        guard dishes.count>=1 else{return}
        for i in 0..<dishes.count-1 {
            print("Hello")
            if dishes[i].name == "Untitled" {
                print("Hello2")
            context.delete(dishes[i])
            }
        }
        
        DatabaseController.saveContext()

        dishes = dishes.filter{$0.name != "Untitled"}
        dishes = dishes.filter{$0.name != nil}
        DatabaseController.saveContext()
        
        tableView.reloadData()
        

    }
    
     override func viewWillAppear(_ animated: Bool) {
            cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) //disabling camera button if camera isn't available
        
        if navigationItem.title == "Untitled" {
            cameraButton.isEnabled = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
         
        if dishes.last?.name != navigationItem.title {
            //defaultView() //necessary
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
        else {
            cameraButton.isEnabled = false
            saveButton.title = "Save"
            saveButton.isEnabled = true
        }
    }

    func fetchDishes() { //Getting all dishes in creation date order, storing in "dishes" global array Type: CoreDish. The purpose of fetching dishes to get the last dish in the array of dishes to use for ingredients
        let fetchRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) //last dish is latest dated dish
        fetchRequest.sortDescriptors = [sortDescriptor] //last element is most recent date
        
        do {
            dishes = try context.fetch(fetchRequest) //getting all saved dishes and setting equal to dishes
            
            if !dishes.isEmpty { // if dishes is not empty
            if dishes[0].name == "Untitled" { //if first element is Untitled
                dishes.remove(at: 0) //remove untitled
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
                print("Made it here!!!!!")
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
          }
            
          catch{
              print("unable to fetch")
              return
          }
        
        checkNilIngredient() // checking/removing any nil ingredients
        
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
        guard dishes.count != 0 else{return}
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
        quantLabel.text = "1"
        stepper.value = 1.0

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
        quantLabel.text = "1"
        stepper.value = 1.0
        
        tableView.reloadData()
    }
     
    func createDish(_ selectedDish: String) -> CoreDish { //create new dish function
        cameraButton.tintColor = .none
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
        print("ViewDidDisappear called")
        

        
//        if dishes.count != 0 && navigationItem.title == "Untitled" {
//            print("Clearing ingredients at viewWillDisappear")
//            deleteIngredientsCore()
//        }
//
//        if dishes.count == 0 && navigationItem.title == "Untitled" {
//            return
//        }

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
        pickImage.sourceType = .camera
        pickImage.allowsEditing = true
         present(pickImage, animated:true, completion:nil)
     }
     
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            //imagePickerView.image = image
            self.originalPhoto = image//storing image in property for save method
            //self.originalPhoto.imageOrientation = UIImageOriention
           // self.originalPhoto.imageOrientation = up
            saveImage()
             dismiss(animated: true, completion: nil) //closes image picker when image is selected
             
         }
     }
    
    func stringCountCheck(_ value: String?) {
        if value!.count == 0 {
            showAlert(selectedAlert: ("Error","Dish needs a name"))
            checker = false
        }
        else if value!.count>25 {
            showAlert(selectedAlert:("Error","Enter a shorter name"))
            checker = false
        }
        else {
            checker = true
            return
        }
    }
    
    func showAlert(selectedAlert: (String, String))  {
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Back", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true)
        
    }
    
    func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func hapticError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func renameAlert(selectedAlert: (String, String, String)) {
        var nameExists = false
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        alert.addTextField()
        let rename = UIAlertAction(title: selectedAlert.2, style: .default){ [unowned alert] _ in
           let answer = alert.textFields![0]
            let emptyStringTest = self.handleEmpty(answer.text!)
            guard emptyStringTest == false else {
                return
            }
            nameExists = self.checkNameExists(answer.text ?? "nil")
            guard nameExists == false && answer.text != "nil" else {
                self.hapticError()
                self.showAlert(selectedAlert: ("Error", "There is already a dish named \(answer.text!) please enter a new name"))
                 return
            }

               self.dishes[self.dishes.count-1].name = answer.text!
            print(self.dishes[self.dishes.count-1].name!)
               DatabaseController.saveContext()
            self.navigationItem.title = self.dishes[self.dishes.count-1].name
               self.tab.allDishes = self.dishes
          //  self.hapticSuccess()
           }
           
           alert.addAction(rename)
           
           present(alert, animated: true, completion:{ //setting up tap gesture recognizer
               alert.view.superview?.isUserInteractionEnabled = true
               alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
       }
    
    func handleEmpty(_ string: String) -> Bool {
        var edited = string
        edited = string.filter{$0.description != " "}
        
        if edited.count == 0 {
            hapticError()
            showAlert(selectedAlert: ("Error", "Name cannot be blank, Please enter a name"))
        return true
        }
        else {return false}
    }
    
    func checkNameExists(_ name: String) -> Bool { // checking if name already exists
        for i in 0..<dishes.count {
            if dishes[i].name == name {
                print("Name already exists")
                return true //name found
            }
        }
        return false //name doesn't already exits
    }
    
    func secondOptAlert(selectedAlert: (String, String, String)) {
        print("in secondOPt")
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let rename = UIAlertAction(title: "Rename", style: .default){ (action: UIAlertAction) in
            self.renameAlert(selectedAlert: ("Rename Dish", "Enter new name of this Dish", "Rename"))
        }
        
        let new = UIAlertAction(title: "New", style: .default, handler: {(action: UIAlertAction)
            in
            self.createAlert(alertTitle: "Create Dish", alertMessage: "Enter the name of your new dish")
        })
        
        alert.addAction(rename)
        alert.addAction(new)
        
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    func optionAlert(selectedAlert:(String, String, String)) {
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let delete = UIAlertAction(title: selectedAlert.2, style: .destructive, handler: {(action: UIAlertAction) in
            self.deleting()
        })
        
        alert.addAction(cancel)
        alert.addAction(delete)
         //   present(alert, animated: true)
        
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
       
    
    }
        
    
    
    //MARK: IBACTIONS - START
    @IBAction func stepperTapped(_ sender: UIStepper) { //Stepper changing quantLabel/number of servings
        
        guard dishes.count != 0 && ingredients.count != 0 else {
            sender.value = 1.0
            return
        }
        
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
        print(dishes[dishes.count-1].name!)
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
        
        if navigationItem.title == "Untitled" {
            createAlert(alertTitle: "Create Dish", alertMessage: "Enter the name of your new dish")
        }
        
        else {
        
        secondOptAlert(selectedAlert: ("Create Dish", "Rename or Create New", "Rename"))
        }
      //  createAlert(alertTitle: "Create Dish", alertMessage: "Enter the name of your new dish")
    }
    @IBAction func trashButtonTapped(_ sender: Any) {
        guard dishes.count != 0 else{return}
        optionAlert(selectedAlert: ("Delete Dish", "Are you sure you want to permanently delete this dish?", "Delete"))
    }
    
    func deleting() {
        cameraButton.tintColor = .none

        saveButton.title = "Save"
        guard dishes.count != 0 else {
            return
        }
        
        deleteDish(dishes[dishes.count-1]) //will delete the viewing dish
        navigationItem.title = "Untitled"
        clearCoreIngredients() // will delete all ingredients that are in ingredients array
        let newDish = CoreDish(context: context)
        newDish.name = "Untitled"
        newDish.stepperValue = stepper.value
        newDish.editedServings = quantLabel.text
        saveButton.isEnabled = true
        newDish.creationDate = Date()
        dishes.append(newDish)
        
        if navigationItem.title == "Untitled" {
            cameraButton.isEnabled = false
        }
        tableView.reloadData()
        //defaultView()
    }
    
    
    
    //MARK: IBACTIONS - END
}
  //MARK: ALERT - START
    extension DishController {
    func createAlert(alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle , message: alertMessage, preferredStyle: .alert)
        alert.addTextField()
        var submitTitle = "Create"
        if saveButton.title == "New" {
            submitTitle = "Create"
        }
        let submitAction = UIAlertAction(title: submitTitle, style: .default) { [unowned alert] _ in
            let answer = alert.textFields![0]
            let emptyStringCheck = self.handleEmpty(answer.text!)
            guard emptyStringCheck == false else {
                return
            }
            self.stringCountCheck(answer.text)
            guard self.checker == true else {
                return
            }
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
