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
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let context = DatabaseController.persistentStoreContainer().viewContext
    var dishes: [CoreDish] = [] //stores dishes from core data, stored by creationdate
    var ingredients: [CoreIngredient] = [] //stores ingredients from core data
    var savedDishName: String = "" //dish name
    let untitled = "Untitled"
    let tryAgain = "Try Again"
    let blankError = "Please enter a name"
    let existsError = "This dish already exists"
    var tab: TabShareController {
        return tabBarController as! TabShareController
    }
    var trashSetting: Bool {
        return ingredients.count == 0 && navigationItem.title == untitled
    }
    var resetServingsCheck: Bool { //checks if ingredients count is 0
        return ingredients.count == 0
    }
    var originalPhoto: UIImage! //storing original non-meme image
    
    enum SaveButton: String {
        case New = "New"
        case Save = "Save"
    }
    
    //MARK: VIEW LIFECYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        enableCamera(false)
        activityIndicator.isHidden = true
        defaultView()
        fetchDishes() // getting all dishes in core data
        fetchIngredients() // getting all ingredients of last created entity
        
        guard dishes.count>=1 else{return}
        for i in 0..<dishes.count-1 {
            if dishes[i].name == untitled {
                context.delete(dishes[i])
            }
        }
        
        dishes = dishes.filter{$0.name != untitled}
        dishes = dishes.filter{$0.name != nil}
        DatabaseController.saveContext()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if dishes.last?.name != navigationItem.title { //if last dishes name doesn't equal navTitle
            dishes = tab.allDishes
            navigationItem.title = dishes.last?.name
            fetchIngredients()
            tab.allDishes = dishes
            tableView.reloadData()
        }
        if tab.returning == true {
            dishes = tab.allDishes
            rearrangeDishes()
            fetchIngredients()
            tab.returning = false
        }
        
        if navigationItem.title == nil || navigationItem.title == "" { //if nav title is nil or empty make it "Untitled" (safety)
            navigationItem.title = untitled
        }
        
        if navigationItem.title != untitled { //if nav title is string other than "Untitled"
            viewSettings(true,true,SaveButton: SaveButton.New)
        }
        else { //If nav title is "Untitled"
            viewSettings(false,true,SaveButton: SaveButton.Save)
        }
        resetServ()
        disableTrash()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dishes = dishes.compactMap{$0} //removing nils if any in dishes before moving to bookController
        tab.allDishes = dishes //updating shared dishes
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tab.allDishes = dishes
    }
    
    //MARK: CORE DATA FETCHES
    func fetchDishes() { //Getting all dishes in creation date order, storing in "dishes" global array Type: CoreDish. DishController displays last dish in dishes array
        let fetchRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) //last dish is latest dated dish
        fetchRequest.sortDescriptors = [sortDescriptor] //last element is most recent date
        
        do {
            dishes = try context.fetch(fetchRequest) //getting all saved dishes and setting equal to dishes
            
            if dishes.last?.name == nil {
                createTempDish(untitled)
                DatabaseController.saveContext()
            }
            
            if !dishes.isEmpty { // if dishes is not empty
                if dishes[0].name == untitled { //if first element is Untitled
                    dishes.remove(at: 0) //remove untitled dish
                    DatabaseController.saveContext()
                }
            }
        }
            
        catch{
            print("unable to fetch")
            return
        }
        
        guard dishes.last?.name != nil && dishes.last?.name != "" else {
            defaultView() // if last dish == nil is true or "". Use default view
            return
        }
        if let checkDish = dishes.last { //unwrapping last dish
            updateView(checkDish) // changing view to reflect last dish
        }
        tab.allDishes = dishes //updating shared all dishes with what was pulled
        tableView.reloadData() //table reloads after every fetch
    }
    
    func fetchIngredients() { //fetching ingredients that belong to specific dish. Displays them by creation date storing, ingredients in ingredients array
        ingredients = []
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
        
        DatabaseController.saveContext()
        
        tableView.reloadData() //reload table to show ingredients
    }
    
    //MARK: UPDATE CORE DISH METHODS
    func addCoreDish(_ dish: CoreDish) { //saving added dish to core data
        dishes.append(dish)
        if dishes[0].name == untitled { //if first dish is untitled remove it
            dishes.remove(at: 0)
        }
        enableCamera(true)
        DatabaseController.saveContext() //saving to core data
    }
    
    func deleteDish(_ selectDish: CoreDish) { //deletes a selected dish from core data
        guard dishes.count != 0 else{return}
        dishes.removeLast() // will remove last dish
        tab.allDishes.removeLast()
        context.delete(selectDish)
        DatabaseController.saveContext()
    }
    
    //MARK: UPDATE CORE INGREDIENTS METHODS
    func addCoreIngredient(_ ingredient: CoreIngredient) { //saving new ingredient to Core Data
        if ingredient.name == nil {
            return
        }
        ingredients.append(ingredient)
        DatabaseController.saveContext()
    }
    
    func deleteCoreIngredient(selectIngredient: CoreIngredient) { //deletes ingredient core data.
        
        context.delete(selectIngredient)
        DatabaseController.saveContext()
    }
    
    func updateCoreIngredients(_ selectedDish: CoreDish) {  //matching ingredient with dish
        for i in 0..<ingredients.count {
            ingredients[i].dish = selectedDish
        }
        DatabaseController.saveContext()
    }
    
    func clearCoreIngredients() { //empties ingredients
        ingredients = [] //emptying local ingredients
        DatabaseController.saveContext()
    }
    
    //MARK: ADDITIONAL METHODS
    
    func viewSettings(_ cameraSetting: Bool,_ SaveSetting: Bool, SaveButton: SaveButton) { //Nav Setup depending on title
        enableCamera(cameraSetting)
        saveButton.isEnabled = SaveSetting
        saveButton.title = SaveButton.rawValue
    }
    
    func defaultView() { //default view setting. If no dish is in dishes array
        navigationItem.title = untitled
        saveButton.title = SaveButton.Save.rawValue
        quantLabel.text = "1"
        stepper.value = 1.0
        
        if ingredients.count == 0 {
            disableTrash()
            saveButton.isEnabled = false
        }
        tableView.reloadData() //for after changing stepper value
    }
    
    func resetServ() {
        if resetServingsCheck == true {
            resetServings()
        }
    }
    
    func updateView(_ selectedDish: CoreDish) { //change in view after fetch to show last in fetched array
        guard dishes.count != 0 else { return } // if dishes count is 0 return
        
        navigationItem.title = dishes.last?.name ?? untitled //used last dish name as navTitle
        stepper.value = Double(selectedDish.editedServings ?? "1") ?? 1.0 //updating stepper value and
        quantLabel.text = selectedDish.editedServings //stepper's label to reflect last dish's last settings.
        DatabaseController.saveContext()
    }
    
    func checkNilIngredient() { //clears ingredients of nil or "Untitled"

        for i in 0..<ingredients.count {
            if ingredients[i].name == nil && dishes[i].name == untitled{
                ingredients.remove(at: i)
                print("removing \(i)")
            }
        }
    }
    
    func enableCamera(_ setting: Bool) {
        
        switch setting {
        case true: cameraButton.isEnabled = true
        case false: cameraButton.isEnabled = false
        }
    }
    
    func disableTrash() {
        switch trashSetting {
        case true: trashButton.isEnabled = false
        case false: trashButton.isEnabled = true
        }
    }
    func createDish(_ selectedDish: String) -> CoreDish { //create new dish function
        let newDish = CoreDish(context: context)
        newDish.name = selectedDish
        newDish.editedServings = quantLabel.text
        newDish.creationDate = Date()
        
        return newDish
    }
    
    func createTempDish(_ dish: String) {
        let newDish = CoreDish(context: context)
        newDish.name = untitled
        newDish.stepperValue = stepper.value
        newDish.editedServings = quantLabel.text
        saveButton.isEnabled = true
        newDish.creationDate = Date()
        dishes.append(newDish)
    }
    
    func deleting() {
        saveButton.title = SaveButton.Save.rawValue
        guard dishes.count != 0 else {
            return
        }
        
        deleteDish(dishes[dishes.count-1]) //will delete the viewing dish
        navigationItem.title = untitled
        clearCoreIngredients() // will delete all ingredients that are in ingredients array
        //createTempDish()
        createTempDish(untitled)
        
        if navigationItem.title == untitled {
            enableCamera(false)
        }
        tableView.reloadData()
    }
    
    func saveImage() { //saving image to dish
        let convertedPhoto = originalPhoto.pngData()
        dishes[dishes.count-1].image = convertedPhoto
        DatabaseController.saveContext()
        tab.allDishes = dishes
    }
    
    func rearrangeDishes() { //moving dish to end of array by delete and append
        dishes = tab.allDishes
        tab.selectedDish.creationDate = Date() //updating creation date
        
        for i in 0..<dishes.count{ //Don't include last element in iteration
            if dishes[i].name == tab.selectedDish.name ?? "nil" { //removing dish from dishes if it matches the selected dish
                dishes.remove(at: i)
                break
            }
        }
        dishes.append(tab.selectedDish) //adding selected dish to end of array
        tab.allDishes = dishes
        
        updateView(dishes.last!) //updating the nav view
    }
    
    func stringCountCheck(_ value: String?) -> Bool { //Makes sure dish name isn't 0 or greater than 25 sends alert
        
        let first = {}
        
        if value!.count == 0 {
            basicAlert(selectedAlert: (tryAgain,blankError), passClosure: first)
            return false
        }
        else if value!.count>25 {
            basicAlert(selectedAlert:(tryAgain,"Please enter a shorter name"),returnAlert: nil,passClosure: first)
            return false
        }
        else {
            return true
        }
    }
    
    func hapticError() { //haptic error when string is not correct
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func handleEmpty(_ string: String, returnAlert: (String,String,String)? = nil, methodClosure: @escaping()  -> Void) -> Bool { //if string is empty or filled with only spaces
        let edited = string.filter{$0.description != " "} //filtering out spaces
        
        if edited.count == 0 { //if string count is 0 string was either empty or made up of only spaces
            hapticError()
            basicAlert(selectedAlert: (tryAgain, blankError), returnAlert: returnAlert, passClosure: methodClosure)
            return true
        }
        else {return false}
    }
    
    func resetServings() {
        stepper.value = 1.0
        quantLabel.text = "1"
    }
    
    func checkNameExists(_ name: String) -> Bool { // checking if name already exists in dishes
        for i in 0..<dishes.count {
            if dishes[i].name == name {
                return true //name found
            }
        }
        return false //name doesn't already exits
    }
    
    @objc func alertBackgroundTapped() //background tap dismiss
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func convertIngredient(food: CoreIngredient) -> Ingredient { //converts from coreIngredient to Ingredient for modifier
        
        let ingredient = Ingredient()
        ingredient.name = food.name!
        ingredient.editedAmount = food.editedAmount
        ingredient.unit = food.unit!
        ingredient.amount = food.singleAmount // 1 serving of amount
        
        return ingredient
    }
    
    func modify(_ food: Ingredient? = nil, _ selfStepper: Bool, _ i: Int?) -> CoreIngredient{
        var coreIn: CoreIngredient!
        if selfStepper == true { // if using stepper
          coreIn = ingredients[i!]
        }
         else if selfStepper == false {// if not using stepper but(adding ingredient)
            coreIn = CoreIngredient(context: context)
             //coreIn = ingredients[i!]
        }
        if i != nil {
            coreIn = ingredients[i!]
        }
        coreIn.creationDate = food!.creationDate
        coreIn.name = food!.name
        coreIn.singleAmount = food!.amount/Double(food!.servings) //amount per 1 serving
        let changedQuantLabel = Double(quantLabel!.text ?? "1") //converting self stepper to Double for calc
        coreIn.editedAmount = coreIn.singleAmount * Double(changedQuantLabel ?? 1.0) //amount dependant on stepper

        if food!.unit == "cup" && coreIn.editedAmount != 1.0 {
            food!.unit = "cups"
        }
        
        if food!.unit == "cups" && coreIn.editedAmount == 1.0 {
            food!.unit = "cup"
        }
        
        var intAmount: Int = 1
        if coreIn.editedAmount.remainder(dividingBy: 1) == 0 { //if number after dec point is not 0
            intAmount = Int(coreIn.editedAmount) //turn double into int
            coreIn.modifiedIngredient = "\(intAmount)" + " \(food!.unit)" //use int in modifiedIngredient
        }
        else {
            let doubleAmount = Double(String(format: "%.3f", coreIn.editedAmount))
        coreIn.modifiedIngredient = "\(doubleAmount!)" + " \(food!.unit)" //use original double
        }
        coreIn.editedServings = "\(food!.servings)"
        coreIn.unit = food!.unit
        coreIn.dish = dishes[dishes.count-1]
        
        if coreIn.name != nil {
        DatabaseController.saveContext()//saving new CoreIngredient into Core Data
        }
        
        return coreIn // returning a modified food details
    }
    
    //MARK: CAMERA
    func pickImageWith(sourceType: UIImagePickerController.SourceType) { //opens album/camera for image pick
        let pickImage = UIImagePickerController() //picking image
        pickImage.delegate = self
        pickImage.sourceType = .camera
        pickImage.allowsEditing = true
        present(pickImage, animated:true, completion: {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            self.originalPhoto = image//storing image in property for save method
            saveImage() //linking dish and image and saving to core data
            dismiss(animated: true, completion: nil) //closes image picker when image is selected
        }
    }
    
    //MARK: ALERTS
    func basicAlert(selectedAlert: (String, String), returnAlert:(String,String,String)? = nil, passClosure: @escaping()  -> Void){
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Back", style: .default, handler: {action in
                        
            if returnAlert != nil {
                passClosure() //will rerun previous input text alert, result of invalid entry
            }})
    
        alert.addAction(ok)
        present(alert, animated: true)
        
    }
    
    func renameAlert(selectedAlert: (String, String, String)) {
        
        let first = {
            self.renameAlert(selectedAlert: selectedAlert)
        }
        var nameExists = false
       // let newSelect = selectedAlert
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        alert.addTextField()
        let rename = UIAlertAction(title: selectedAlert.2, style: .default){ (action: UIAlertAction) in
            let answer = alert.textFields![0]
            let emptyStringTest = self.handleEmpty(answer.text!, returnAlert: selectedAlert, methodClosure: first) //when empty it returns true
            guard emptyStringTest == false else { //if string is empty return if not empty continue
                return
            }
            nameExists = self.checkNameExists(answer.text ?? "nil")
            guard nameExists == false && answer.text != "nil" else {
                self.hapticError()
                //add return alert(selected alert)

                self.basicAlert(selectedAlert: (self.tryAgain, self.existsError), returnAlert: selectedAlert, passClosure: first)
//                self.renameAlert(selectedAlert: (selectedAlert.0,selectedAlert.1,selectedAlert.2))
                return
            }
            self.dishes[self.dishes.count-1].name = answer.text!
            DatabaseController.saveContext()
            self.navigationItem.title = self.dishes[self.dishes.count-1].name
            self.tab.allDishes = self.dishes
        }
        
        alert.addAction(rename)
        
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    func defaultAlert(first: @escaping() -> Void, second: @escaping() -> Void, selectedAlert:(String,String,String,String)) { //Default style alert
        
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let first = UIAlertAction(title: selectedAlert.2, style: .default){ (action: UIAlertAction) in
            first() //first alert option
        }
        
        let second = UIAlertAction(title: selectedAlert.3, style: .default, handler: {(action: UIAlertAction)
            in
            second() //second alert option
        })
        
        alert.addAction(first)
        alert.addAction(second)
        
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    func cancelAlert(first: @escaping() -> Void, selectedAlert:(String, String, String)) { //cancel alert style
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let delete = UIAlertAction(title: selectedAlert.2, style: .destructive, handler: {(action: UIAlertAction)
            in
            first()
            self.resetServ()
        })
        alert.addAction(cancel)
        alert.addAction(delete)
        
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    func createAlert(alertTitle: String, alertMessage: String) {
        let methodClosure = { //for basicAlert to rerun if error
            self.createAlert(alertTitle: alertTitle, alertMessage: alertMessage)
        }
        var nameExists = false
        let alert = UIAlertController(title: alertTitle , message: alertMessage, preferredStyle: .alert)
        alert.addTextField()
        var submitTitle = "Save"
        if saveButton.title == SaveButton.New.rawValue {
            submitTitle = "Create"
        }
        let submitAction = UIAlertAction(title: submitTitle, style: .default) { [unowned alert] _ in
            let answer = alert.textFields![0]
            let selectedDishTuple: (String, String, String) = (alertTitle, alertMessage, "")

            let emptyStringCheck = self.handleEmpty(answer.text!, returnAlert: selectedDishTuple,methodClosure: methodClosure)
            guard emptyStringCheck == false else {
                return
            }
            
            nameExists = self.checkNameExists(answer.text ?? "nil")
            guard nameExists == false && answer.text != "nil" else {
                self.hapticError()
                self.basicAlert(selectedAlert: (self.tryAgain, "There is already a dish named \(answer.text!). Please enter a new name"),returnAlert: selectedDishTuple,passClosure:methodClosure) //passing in first closure
                return
            }
            
            let count = self.stringCountCheck(answer.text)
            guard count == true else {
                return
            }
            self.savedDishName = answer.text ?? "Dish"
            guard self.savedDishName != "Dish" else {//Dish name is not allowed
                let passMessage = "Choose a different name"
                self.navigationItem.title = self.savedDishName
                self.createAlert(alertTitle: self.tryAgain, alertMessage: passMessage) //alert to rechoose name
                return
            }
            self.navigationItem.title = self.savedDishName // nav title updates to saved name
            
            let createdDish = self.createDish(answer.text!)
            self.disableTrash()
            if self.saveButton.title == SaveButton.New.rawValue {
                self.ingredients = []
                self.navigationItem.title = createdDish.name
            }
            
            self.updateCoreIngredients(createdDish) //changing the ingredients associated dish
            
            self.addCoreDish(createdDish) //sending that object to be saved
            
            self.tab.allDishes = self.dishes
            self.tableView.reloadData()
            if self.navigationItem.title != self.untitled {
                self.saveButton.title = SaveButton.New.rawValue
            }
        }
        
        alert.addAction(submitAction)
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    //MARK: IBACTIONS METHODS
    @IBAction func stepperTapped(_ sender: UIStepper) { //Stepper changing quantLabel/number of servings
        guard dishes.count != 0 && ingredients.count != 0 else {
            sender.value = 1.0 //making sure stepper default is 1
            return
        }
        
        let number = Int(sender.value) //stepper increments by int won't assign nil
        quantLabel.text = String(number) //making stepper label a string version of int number
        
        for i in 0..<ingredients.count { //updating ingredients amounts to reflect step changes
            let converted = convertIngredient(food: ingredients[i])
            // ingredients[i] = modifyExisting(converted, true, i)

            ingredients[i] = modify(converted, true, i)

            if ingredients[i].name == nil {
                return
            }
        }
        
        dishes[dishes.count-1].editedServings = quantLabel.text //updating displayed dish servings label for core data save
        DatabaseController.saveContext()
        tableView.reloadData()
    }
    @IBAction func cameraButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }
        pickImageWith(sourceType: UIImagePickerController.SourceType.camera)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        let selectedVC = storyboard?.instantiateViewController(withIdentifier: "AddIngredientController") as! AddIngredientController
        
        selectedVC.chosenFood = self
        
        present(selectedVC, animated: true, completion: nil) //transitioning to AddIngredientController
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
        if navigationItem.title == untitled {
            createAlert(alertTitle: "Save Dish", alertMessage: "Enter the name of your dish")
        }
            
        else {
            let first = {
                self.renameAlert(selectedAlert: ("Rename Dish", "Enter a new name for this dish", "Rename"))
            }
            
            let second = {
                self.createAlert(alertTitle: "Create Dish", alertMessage: "What will your new dish be called?")
            }
            defaultAlert(first: first, second: second, selectedAlert: ("Create Dish", "Rename or Create New", "Rename",SaveButton.New.rawValue))
        }
    }
    
    @IBAction func trashButtonTapped(_ sender: Any) {
        guard dishes.count != 0 else{return}
        
        let first = { self.deleting()
            self.disableTrash()
        }
        cancelAlert(first: first, selectedAlert: ("Delete Dish", "Are you sure you want to permanently delete this dish?", "Delete"))
    }
}

//MARK: TABLE VIEW
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
        
        deleteCoreIngredient(selectIngredient: ingredients[indexPath.row])
        ingredients.remove(at: indexPath.row) //removing from array
        tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
        resetServ()
        disableTrash()
    }
}

//MARK: ADD INGREDIENT DELEGATE
extension DishController: AddIngredientDelegate {
    
    func getIngredient(food: Ingredient) { //Getting new ingredient to add to dish
        saveButton.isEnabled = true //hideview disappears and save button is enabled when getting new ingredient
        
        if dishes.last?.name == nil {
            createTempDish(untitled)
            DatabaseController.saveContext()
        }
        
        let modifiedFood = modify(food, false, nil)
        addCoreIngredient(modifiedFood) //appending a core Ingredient to "ingredients"
        tab.allDishes = dishes
        resetServ()
        disableTrash()
        tableView.reloadData() //reloading table to show new CoreIngredient
    }
}

