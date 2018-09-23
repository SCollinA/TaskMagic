//
//  TaskView.swift
//  TaskMagic
//
//  Created by Collin Argo on 4/26/18.
//  Copyright © 2018 Loco Motion Enterprises. All rights reserved.
//

import Foundation
import UIKit

class TaskView : UITableViewController, UINavigationControllerDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    static let identifier = "Task View"
    //MARK: - Variables
    var searchController = UISearchController(searchResultsController: nil)
    
    private var parentTask : Task = {
        let task : Task
        if let savedTask = Task.loadTask() {
            task = savedTask
            return task
        }
        task = Task.stubTasks
        return task
    }()
    
    private var childTasks : [Task] {
        var taskArray = [Task]()
        for child in parentTask.children {
            taskArray.append(child)
            if child.selected {
                taskArray.append(contentsOf: child.selectedChildren())
            }
        }
        return parentTask.children
    }
    
    private var selectedTask : Task {
        for child in parentTask.children {
            if child.selected {
                return child
            }
        }
        return parentTask
    }
    
    private var allTasks : [Task] {
        return parentTask.allTasks()
    }

    private var searchResults = [Task]()
        
    //MARK: - Load View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = parentTask.name
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(setEdit))
        navigationController?.delegate = self
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.placeholder = "Add Task"
        searchController.searchBar.autocorrectionType = .no
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let tagButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: nil)
        setToolbarItems([flexibleSpace, tagButton], animated: false)
        
        definesPresentationContext = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        searchController.isActive = false
        searchController.searchBar.resignFirstResponder()
        searchController.searchBar.showsCancelButton = false
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let taskView = viewController as! TaskView
        if taskView != self {
            navigationController.delegate = taskView
        }
        taskView.tableView.reloadData()
        navigationController.navigationBar.barTintColor = tableView.backgroundColor
    }
    
    func goBack() {
        parentTask.clearSelections()
        parentTask = parentTask.currentParent
        parentTask.clearSelections()
        isEditing = false
    }
    
    //MARK: - Table View Setup
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return searchResults.count
        } else {
            return childTasks.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let taskCell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier, for: indexPath) as! TaskCell
        let task : Task
        
        if searchController.isActive {
            task = searchResults[indexPath.row]
        } else {
            task = childTasks[indexPath.row]
        }
        var swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipe(with:)))
        swipe.direction = .right
        taskCell.addGestureRecognizer(swipe)
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipe(with:)))
        swipe.direction = .left
        taskCell.addGestureRecognizer(swipe)
        taskCell.configure(for: task)
        taskCell.tableView = tableView
        
        let _ = self.tableView(tableView, heightForRowAt: indexPath)
        
        return taskCell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if searchController.isActive {
            return false
        } else {
            if parentTask.task(at: indexPath).active {
                return isEditing
            } else {
                return !isEditing
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if isEditing {
            return .none
        } else {
            return .delete
        }
    }
    
    @objc func setEdit() {
        setEditing(!isEditing, animated: true)
        if isEditing {
            searchController.searchBar.placeholder = title
            searchController.searchBar.text = title
        } else {
            searchController.searchBar.placeholder = "Add Task"
            searchController.searchBar.text = ""
            searchController.dismiss(animated: true) {
                self.searchController.searchBar.showsCancelButton = false
            }
            parentTask.clearSelections()
        }
        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }
    
    //MARK: - Actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            let didDeselect = selectTask(at: indexPath)  // just select task
            searchController.searchBar.placeholder = selectedTaskName()
            searchController.searchBar.text = selectedTaskName()
            if didDeselect {
                tableView.deselectRow(at: indexPath, animated: false)
            }
            return
        }
        if selectTask(at: indexPath) { // if selected task is current child
            let newTaskView = storyboard!.instantiateViewController(withIdentifier: TaskView.identifier) as! TaskView
            newTaskView.parentTask = selectedTask
            searchController.searchBar.text = ""
            navigationController?.pushViewController(newTaskView, animated: true)
        } else {
            searchController.searchBar.text = ""
            tableView.reloadData()
        }
    }
    
    func selectTask(at indexPath: IndexPath?, withName name: String = "" ) -> Bool {
        guard let indexPath = indexPath else { // if no index path, adding task from search button
            parentTask.addTask(Task(name: name))
            return false
        }
        if searchController.isActive {  // if searching, add task or push new task view for selected task
            if !parentTask.contains(task: searchResults[indexPath.row]) {
                parentTask.addTask(searchResults[indexPath.row])
                return false
            } else {
                parentTask = searchResults[indexPath.row]
                return true
            }
        } else if isEditing { // if editing, just select task
            // if it's already selected, deselect it
            if parentTask.task(at: indexPath) == selectedTask {
                parentTask.clearSelections()
                return true
            }
            parentTask.selectTask(at: indexPath)
            return false
        } else {  // not editing, not searching, push new task view
            parentTask.selectTask(at: indexPath)
            //parentTask = childTasks[indexPath.row]
            return true
        }
    }
    
    // Remove task
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        parentTask.removeTask(childTasks[indexPath.row])
        tableView.reloadData()
    }
    
    // Moving Tasks
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if parentTask.task(at: proposedDestinationIndexPath).active {
            return proposedDestinationIndexPath
        } else {
            return sourceIndexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        parentTask.moveTask(at: sourceIndexPath, to: destinationIndexPath)
        tableView.reloadData()
    }
    
    func changeName(to searchText: String) {
        selectedTask.changeName(to: searchText)
    }
    
    func selectedTaskName() -> String {
        return selectedTask.name
    }
    
    @objc func swipe(with swipeGestureRecognizer: UISwipeGestureRecognizer) {
        if !isEditing {
            let taskCell = swipeGestureRecognizer.view as! TaskCell
            taskCell.swipe(with: swipeGestureRecognizer)
            // swipe parent task active if not already
            if swipeGestureRecognizer.direction == .right && !parentTask.active {
                parentTask.swipe(true)
            }
        }
    }
    
    //MARK: - Searching
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !isEditing {
            searchController.searchResultsUpdater?.updateSearchResults(for: searchController)
            tableView.reloadData()
        }
    }
    
    // Add task
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        
        if isEditing {
            searchBar.text = ""
            searchBar.placeholder = title
            searchController.dismiss(animated: true, completion: nil)
            setEdit()
        } else { // searching, add task
            if !selectTask(at: nil, withName: searchText) {
                searchController.searchBar.text = ""
            }
        }
        tableView.reloadData()
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        if searchController.isActive { // keeps cursor in search bar
            return false
        } else {
            return true
        }
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        if isEditing {
            setEdit()
        }
        tableView.reloadData()
    }
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive && searchController.searchBar.text != "" {
            guard let searchText = searchController.searchBar.text else {
                return
            }
            searchResults = allTasks
            searchResults = searchResults.filter {
                if ($0).name.lowercased().range(of: searchText.lowercased()) != nil {
                    if $0 != parentTask {
                        return true
                    }
                }
                return false
            }
            searchResults = searchResults.sorted {
                var name1 = $0.name
                var name2 = $1.name
                repeat {
                    if name1.lowercased().starts(with: searchText.lowercased()) {
                        return true
                    } else if name2.lowercased().starts(with: searchText.lowercased()) {
                        return false
                    }
                    name1.removeFirst()
                    name2.removeFirst()
                } while !name1.isEmpty && !name2.isEmpty
                return true
            }
        }
    }
}

enum TaskViewState {
    case normal
    case adding
    case tagging
    case mapping
    case camera
    case timing
}

