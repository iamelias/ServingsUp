//
//  BookController.swift
//  ServingsUp
//
//  Created by Elias Hall on 1/26/20.
//  Copyright © 2020 Elias Hall. All rights reserved.
//

import Foundation
import UIKit
import CoreData

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
    var tab: TabShareController {
        return tabBarController as! TabShareController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        deleteCoreDishes() //emptying before any call
        //fetchCoreData() //calling core data to populate "dishes" //will be called everytime opening vc
       // stringNameDishes() //populating "coreDishStrings" as an array of dish names( needed for tableview)
        dishes = tab.allDishes
        print("allDishes: \(tab.allDishes)")
        for i in 0..<tab.allDishes.count {
            if tab.allDishes[i].name != nil && tab.allDishes[i].name != "" {
                print("coreDishString: \(coreDishStrings.count)")
                print("allDishes: \(tab.allDishes.count)")
                //print(coreDishStrings[i])
                print(tab.allDishes[i])
            coreDishStrings[i] = tab.allDishes[i].name ?? "Empty"
            }
            
            tableView.reloadData()
            
        }
        
        
        tableView.reloadData() //to reload tableview after dishes is populated
//        deleteCoreDishes()
    }
    
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
    
    func stringNameDishes() {
        print(dishes.count)
        print("&&&&&&&&&")
        print(dishes)
        print("&&&&&&&&&")

//        coreDishStrings = dishes.map{$0.name ?? "Empty"} // converts all dishObject names into string elements in new array
        
        guard dishes.count != 0 else {return}
        for i in 0...dishes.count - 1 { //for every object in dish
            guard dishes[i].name != nil else { continue} //if dish is not nil
            dishStrings[i].append(dishes[i].name!) //append dish string name to dishStrings array
        }
        
//        guard coreDishStrings.count != 0 else { return }
//        for i in 0..<coreDishStrings.count { //removing all empty strings and all nils
//            if coreDishStrings[i] == "Empty" {
//                coreDishStrings.remove(at: i)
//                dishes.remove(at: i)
//            }
//        }

        print(coreDishStrings)
    }
    
    func deleteCoreDishes() {
        for i in 0..<dishes.count {
            context.delete(dishes[i])
            DatabaseController.saveContext()
        }
    }
    
//    func addCoreData(_ newDish: CoreDish) { //saving dish to core data, this is done after adding a new dish
//        let dish = CoreDish()
//        dish.name = newDish.name
//        dish.editedServings = newDish.editedServings
//
//    }
    
    func saveCoreDish(_ dish: CoreDish) { //saving added dish to core data
        var coreDish = CoreDish(context: context)
        coreDish = dish //making passed in object the object that will be saved in core data
        DatabaseController.saveContext() //saving to core data
        
        dishes.append(coreDish) //adding to local dishes array
    }
    
    func clearCoreData() { //Empties all dishes in core data, not currently being used
        for i in 0..<dishes.count {
            context.delete(dishes[i])
        }
    }
    
    func deleteCoreData(_ selectedDish: CoreDish) { //deleting selected dish from Core Data
        context.delete(selectedDish)
        DatabaseController.saveContext()
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
    
    func createDish(_ dishName: String) -> CoreDish { // This function creates a dish
        let newDish = CoreDish()
        newDish.name = dishName
        newDish.creationDate = Date()
        newDish.editedServings = "1"
        return newDish
    }
    
    @objc func alertBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil) //dismissing alert at background tap
    }
    
    @IBAction func newDishButton(_ sender: Any) {
        let title = "Dish"
        let message = "Name your dish"
        createAlert(title, message, true)
    }
}
//****************************
//MARK: TableView
extension BookController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searching {
            return searchDishes.count
        }
        else {
            return coreDishStrings.count //number of dish objects from core data
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")
        
        if searching {
        cell?.textLabel?.text = searchDishes[indexPath.row]
           // searching = false
        } else {
            cell?.textLabel?.text = coreDishStrings[indexPath.row]
            //searching = false
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //save selected dish index path to acess in dish view controller
        
        tab.selectedDish = dishes[indexPath.row] //setting the selectedDish in TabShareController
        tab.returning = true
        tabBarController?.selectedIndex = 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if searching {
        searchDishes.remove(at: indexPath.row)
        }
        coreDishStrings.remove(at: indexPath.row) //removing from tableview array
        dishes.remove(at: indexPath.row) //removing from array of dishes
        deleteCoreData(dishes[indexPath.row]) //deleting from core data
        tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
    }
}

//*****************************

extension BookController: DishDelegate {
    func getDish(passingDish: Dish) {
        coreDishStrings.append(passingDish.dishName)
        searchBar.isUserInteractionEnabled = true
        tableView.reloadData() //so you see it when returning from addDishController
    }
}
//*****************************
//MARK: Search Bar
extension BookController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        searchDishes = coreDishStrings.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        
        searching = true
        tableView.reloadData() //so table changes with search
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        tableView.reloadData() //so table changes with cancel
    }
}

