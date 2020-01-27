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
    
    var allDishes: [Dish] = []
    var stringAllDishes: [String] = []
    var testArray: [Dish] = []
    
    var searchDishes = [String]() //stores filtered returns as user inputs into searchbar
    let context = DatabaseController.persistentStoreContainer().viewContext
    var dishes: [CoreDish] = [] //stores dishes from core data
    var fetchResult: [CoreDish] = [] //retrieved dishes from core data
    var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        addToTestArray()
    }
    
    func addToTestArray() { //uses TabShareController's dishes
        let tab = tabBarController as! TabShareController
        allDishes = tab.testBookArray
        tab.saving = false
        stringAllDishes = tab.stringArray
        
        for i in 0..<tab.testBookArray.count {
            stringAllDishes.append(tab.testBookArray[i].dishName)
        }
        
        
        tableView.reloadData()
        
    }

    func createAlert(_ title: String, _ message: String, _ usesTextField: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if usesTextField == true {
            alert.addTextField()
        }
    }
    
    func fetchCoreData() { //retrieving from core data
        
        let fetchRequest: NSFetchRequest<CoreDish> = CoreDish.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            fetchResult = try context.fetch(fetchRequest) //setting fetched result into array
            dishes = fetchResult
        }
        catch{
            print("unable to fetch")
            //            debugprint(error)
            return
        }
        guard !fetchResult.isEmpty else { //necessary?
            return
        }
        
    }
    
    @IBAction func newDishButton(_ sender: Any) {
        let selectedVC = storyboard?.instantiateViewController(withIdentifier: "AddDishController") as! AddDishController
        selectedVC.selectedDish = self
        
        searching = false
        searchBar.isUserInteractionEnabled = false
        
        present(selectedVC, animated: true, completion: nil)
    }
}

//MARK: TableView
extension BookController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searching {
            return searchDishes.count
        }
        else {
//        return stringAllDishes.count
            return allDishes.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")
        
        let tab = tabBarController as! TabShareController

        //tab.returning = true
        tab.ingredArray = allDishes[indexPath.row].dishContents //returning ingredients array for specific cell
        tab.arrayIndex = indexPath.row
        
        if searching {
        cell?.textLabel?.text = searchDishes[indexPath.row]
           // searching = false
        } else {
            cell?.textLabel?.text = allDishes[indexPath.row].dishName
            //searching = false
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tab = tabBarController as! TabShareController
//        tab.ingredArray = allDishes[indexPath.row].dishContents
//
//        tab.foodName = allDishes[indexPath.row].dishName
//        tab.returning = true
        
        tab.returning = true
        tab.ingredArray = allDishes[indexPath.row].dishContents
        
        tabBarController?.selectedIndex = 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        stringAllDishes.remove(at: indexPath.row) //removing from array
        if searching {
        searchDishes.remove(at: indexPath.row)
        }
        allDishes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade) //removing from table
    }
}

extension BookController: DishDelegate {
    func getDish(passingDish: Dish) {
        //allDishes[0].dishName.append(passingDish) //doesn't contain dishContents
        stringAllDishes.append(passingDish.dishName)
        searchBar.isUserInteractionEnabled = true
        tableView.reloadData() //so you see it when returning from addDishController
    }
}

extension BookController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        
        searchDishes = stringAllDishes.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        
        searching = true
        tableView.reloadData() //so table changes with search
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        tableView.reloadData() //so table changes with cancel
    }
}

