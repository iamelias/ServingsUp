import Foundation
import UIKit
import CoreData

protocol DishDelegate {
    func getDish(passingDish: Dish)
}

class BookController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var coreDishStrings: [String] = [] //will search through this, when looking for string
    var searchDishes = [String]() //stores filtered returns as user inputs into searchbar
    let context = DatabaseController.persistentStoreContainer().viewContext
    var dishes: [CoreDish] = [] //stores dishes from core data
    var dishStrings: [String] = []
    var fetchResult: [CoreDish] = [] //retrieved dishes from core data
    var searching = false
    var tryAgain = "Try Again"
    var tab: TabShareController {
        return tabBarController as! TabShareController
    }
    
    //MARK: VIEW LIFECYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func viewDidAppear(_ animated: Bool) {
        dishes = []
        coreDishStrings = []
        
        dishes = tab.allDishes
        
        let newdishes = dishes.filter{$0.name != nil && $0.name != "Untitled"}
        dishes = newdishes
        
        for i in 0..<newdishes.count {
            coreDishStrings.append(newdishes[i].name ?? "Nil")
            StringDictionary[coreDishStrings[i]] = newdishes[i]
        }
        
        coreDishStrings.sort()//sorting view in alphabetic order
        
        tableView.reloadData() //to reload tableview after dishes is populated
        
        tab.allDishes = dishes
    }
    override func viewWillDisappear(_ animated: Bool) {
        searchBar.text = ""
        searchBar.endEditing(true)
        searching = false
    }
    
    //MARK: CORE DATA FETCH
    func fetchCoreData() { //retrieving dishes from core data. sorted by creation date
        
        let dishRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) //newest as last element
        dishRequest.sortDescriptors = [sortDescriptor]
        
        do {
            dishes = try context.fetch(dishRequest) //setting fetched result into array
        }
        catch{
            print("unable to fetch dishes in BookController")
            return
        }
    }
    
    func setUpCoreString() {
        coreDishStrings = []
        for i in 0..<dishes.count {
            coreDishStrings.append(dishes[i].name ?? "Nil")
            coreDishStrings.sort() //sorting in alphabetic order
        }
    }
    
    func saveCoreDish(_ dish: CoreDish) { //saving added dish to core data
        var coreDish = CoreDish(context: context)
        coreDish = dish //making passed in object the object that will be saved in core data
        DatabaseController.saveContext() //saving to core data
        
        dishes.append(coreDish) //adding to local dishes array
    }
    
    func clearCoreData() { //Empties all dishes in core data, not currently being used
        dishes = []
        DatabaseController.saveContext()
    }
    
    func deleteCoreData(_ selectedDish: CoreDish) { //deleting selected dish from Core Data
        context.delete(selectedDish)
        DatabaseController.saveContext()
    }
    
    //MARK: ADDITIONAL METHODS
    
    func stringNameDishes() {
        
        guard dishes.count != 0 else {return}
        for i in 0...dishes.count - 1 { //for every object in dish
            guard dishes[i].name != nil else { continue} //if dish is not nil
            dishStrings[i].append(dishes[i].name!) //append dish string name to dishStrings array
        }
    }
    
    func stringCountCheck(_ value: String?) {
        if value!.count == 0 {
            showAlert(selectedAlert: (tryAgain,"Dish needs a name"))
        }
        else if value!.count>10 {
            showAlert(selectedAlert:(tryAgain,"Enter a shorter name"))
        }
        else {
            return
        }
    }
    
    func createDish(_ dishName: String) -> CoreDish { // This function creates a dish
        let newDish = CoreDish()
        newDish.name = dishName
        newDish.creationDate = Date()
        newDish.editedServings = "1"
        return newDish
    }
    
    func checkNameExists(_ name: String) { // checking if name already exists
        for i in 0..<dishes.count {
            if dishes[i].name == name {
                return
            }
        }
    }
    
    func hapticError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    @objc func alertBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil) //dismissing alert at background tap
    }
    
    //MARK: ALERT METHODS
    
    func showAlert(selectedAlert: (String, String))  {
        let alert = UIAlertController(title: selectedAlert.0, message: selectedAlert.1, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Back", style: .default, handler: nil)
        
        alert.addAction(ok)
        present(alert, animated: true)
        
    }
    
    func createAlert(_ title: String, _ message: String, _ usesTextField: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if usesTextField == true {
            alert.addTextField()
        }
        
        let submitAction = UIAlertAction(title: "Add", style: .default) { [unowned alert] _ in
            
            let answer = alert.textFields![0]
            guard answer.text != nil else {
                return
            }
            let newDish = self.createDish(answer.text!) //creating a dish object with the user input text
            self.saveCoreDish(newDish)
            self.coreDishStrings.append(newDish.name!) //for BookController tableview
            
            self.tableView.reloadData()
        }
        
        alert.addAction(submitAction)
        present(alert, animated: true, completion:{ //setting up tap gesture recognizer
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertBackgroundTapped)))} )
    }
    
    @IBAction func newDishButton(_ sender: Any) {
        let title = "Dish"
        let message = "Name your dish"
        createAlert(title, message, true)
    }
}
//MARK: TABLE VIEW
extension BookController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        tableView.rowHeight = 90 //size of row
        
        if searching {
            
            return searchDishes.count
        }
        else {
            return coreDishStrings.count //number of dish objects from core data
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")
        if searching { //when typing in search box
            cell?.textLabel?.text = searchDishes[indexPath.row]
            cell?.imageView?.image = #imageLiteral(resourceName: "fullCamera1")
            
            if StringDictionary[searchDishes[indexPath.row]]?.image != nil {
                if let convertedImage = UIImage(data: StringDictionary[searchDishes[indexPath.row]]!.image!,scale: 1.0) {
                    cell?.imageView?.image = convertedImage
                }
                
            }
            else {
                //print("using default image")
            }
        } else {
            cell?.textLabel?.text = coreDishStrings[indexPath.row]
            
            cell?.imageView?.image = #imageLiteral(resourceName: "fullCamera1")
            
            if StringDictionary[coreDishStrings[indexPath.row]]?.image != nil {
                if let convertedImage = UIImage(data: StringDictionary[coreDishStrings[indexPath.row]]!.image!,scale: 1.0) {
                    cell?.imageView?.image = convertedImage
                }
            }
            else {
                //print("using default image")
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.reloadData()
        
        if searching {
            
            for i in 0..<dishes.count {
                if searchDishes[indexPath.row] == dishes[i].name {
                    tab.selectedDish = StringDictionary[searchDishes[indexPath.row]]
                }
            }
        }
        
        if !searching {
            tab.selectedDish = StringDictionary[coreDishStrings[indexPath.row]]
        }
        tab.returning = true
        tabBarController?.selectedIndex = 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { //deleting row by slide
        
        if searching {
            for i in 0..<dishes.count {
                if dishes[i].name == searchDishes[indexPath.row] {
                    deleteCoreData(dishes[i])
                    dishes.remove(at: i)
                    break
                }
            }
            searchDishes.remove(at: indexPath.row)
            
            tableView.reloadData()
            
            searchBar.text = ""
            tableView.reloadData()
            coreDishStrings = coreDishStrings.filter{$0 != "nil"}
            let newDish = dishes
            dishes = newDish.filter{$0.name != nil}
            tab.allDishes = dishes
            setUpCoreString()
            
            searching = false
            tab.allDishes = dishes
            tableView.reloadData()
            
            return
        }
        
        
        if !searching {
            
            for i in 0..<dishes.count {
                if dishes[i].name == coreDishStrings[indexPath.row]{
                    deleteCoreData(dishes[i])
                    dishes.remove(at: i)
                    coreDishStrings.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
                    break
                }
            }
        }
        
        tab.deleting = true
        tab.allDishes = dishes
        tableView.reloadData()
        return
    }
}

//MARK: DELEGATE METHODS
extension BookController: DishDelegate {
    func getDish(passingDish: Dish) {
        coreDishStrings.append(passingDish.dishName)
        searchBar.isUserInteractionEnabled = true
        tableView.reloadData() //so you see it when returning from addDishController
    }
}

//MARK: SEARCH BAR
extension BookController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchDishes = coreDishStrings.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        
        searching = true
        
        tableView.reloadData() //so table changes with search
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        view.endEditing(true)
        
        tableView.reloadData() //so table changes with cancel
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension BookController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}
