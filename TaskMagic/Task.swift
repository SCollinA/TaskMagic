//
//  Task.swift
//  TaskMagic
//
//  Created by Collin Argo on 4/26/18.
//  Copyright © 2018 Loco Motion Enterprises. All rights reserved.
//

import Foundation
import UIKit
import os.log

class Task : NSObject {
    //MARK: - Variables
    var currentParent : Task {
        for parent in parents {
            if parent.selected {
                return parent
            }
        }
        return findRoot()
    }
    
    var name = ""
    var parents = [Task]()
    var children = [Task]()
    var active = true
    var selected = false

    //MARK: - Setup
    init(name: String = "") {
        self.name = name
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        if let name = aDecoder.decodeObject(forKey: Task.propertyKeys.name) as? String {
            self.name = name
        }
        if let parents = aDecoder.decodeObject(forKey: Task.propertyKeys.parents) as? [Task] {
            self.parents = parents
        }
        if let children = aDecoder.decodeObject(forKey: Task.propertyKeys.children) as? [Task] {
            self.children = children
        }
        self.active = aDecoder.decodeBool(forKey: Task.propertyKeys.active)
    }
    
    //MARK: - Actions
    func addTask(_ newTask: Task) {
        children.append(newTask)
        newTask.parents.append(self)
        if !active {
            swipe(true)
        }
        saveTask()
    }
    
    func removeTask(_ task: Task) {
        if let index = children.index(of: task) {
            children.remove(at: index)
        }
        if let index = task.parents.index(of: self) {
            task.parents.remove(at: index)
        }
    }
    
    func moveTask(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movingTask = task(at: sourceIndexPath)
        removeTask(movingTask)
        insertTask(movingTask, at: destinationIndexPath)
        saveTask()
    }
    
    private func insertTask(_ task: Task, at indexPath: IndexPath) {
        task.parents.append(self)
        children.insert(task, at: indexPath.row)
    }
    
    func selectTask(at indexPath: IndexPath) {
        // clear previously selected children, if any
        clearSelections()
        // mark selected task as such
        let selectedTask = task(at: indexPath)
        // if task was selected, unselect, otherwise select it
        selectedTask.selected = !selectedTask.selected
    }
    
    func clearSelections() {
        // for each child, mark as unselected
        for child in children {
            child.selected = false
            // repeat process for children of children
            child.clearSelections()
        }
    }
    
    func changeName(to newName: String) {
        if currentParent == self { // if at root task
            self.name = newName
            saveTask()
        } else if !currentParent.contains(taskNamed: newName) {
            for task in allTasks() {
                if task.name == newName {
                    currentParent.insertTask(task, at: IndexPath(row: currentParent.children.index(of: self)!, section: 0))
                    currentParent.removeTask(self)
                    saveTask()
                    return
                }
            }
            self.name = newName
            saveTask()
        }
    }
    
    func swipe(_ active: Bool) {
        if active == self.active {
            return
        }
        self.active = active
        if !active {
            if currentParent.active && currentParent != findRoot() {
                var activeChild = false
                for child in currentParent.allChildren() {
                    if child.active {
                        activeChild = true
                        break
                    }
                }
                if !activeChild {
                    currentParent.swipe(active)
                }
            }
            for child in children {
                child.swipe(active)
            }
        } else {
            if !currentParent.active {
                currentParent.swipe(active)
            }
            var activeChild = false
            for child in children {
                if child.active {
                    activeChild = true
                }
            }
            if !activeChild {
                for child in children {
                    child.swipe(active)
                }
            }
        }
        saveTask()
    }
    
    //MARK: - Helper Methods
    func task(at indexPath: IndexPath) -> Task {
        return children[indexPath.row]
    }
    
    func description(of tasks: [Task]) -> String {
        var taskNames = ""
        for task in tasks {
            if taskNames == "" {
                taskNames = task.name
            } else {
                taskNames = taskNames + ", " + task.name
            }
        }
        return taskNames
    }

    func activeChildTasks() -> [Task] {
        var activeTaskArray = [Task]()
        for task in children {
            if task.active {
                activeTaskArray.append(task)
            }
        }
        return activeTaskArray
    }
    
    func contains(task: Task) -> Bool {
        if self == task {
            return true
        }
        for child in children {
            if child == task {
                return true
            }
        }
        return false
    }
    
    func contains(taskNamed taskName: String) -> Bool {
        if self.name == taskName {
            return true
        }
        for child in children {
            if child.name == taskName {
                return true
            }
        }
        return false
    }
    
    private func allChildren() -> [Task] {
        var allChildrenArray = [Task]()
        for child in children {
            if !allChildrenArray.contains(child) {
                allChildrenArray.append(child)
            }
            if !child.children.isEmpty {
                for grandChild in child.allChildren() {
                    if !allChildrenArray.contains(grandChild) {
                        allChildrenArray.append(grandChild)
                    }
                }
            }
        }
        return allChildrenArray
    }
    
    func findRoot() -> Task {
        if parents.isEmpty {
            return self
        } else {
            return parents[0].findRoot()
        }
    }
    
    func allTasks() -> [Task] {
        return findRoot().allChildren()
    }
}


//MARK: - Saving Tasks
extension Task : NSCoding {
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("tasks")
    
    struct propertyKeys {
        static let name = "name"
        static let parents = "parents"
        static let children = "children"
        static let active = "active"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Task.propertyKeys.name)
        aCoder.encode(parents, forKey: Task.propertyKeys.parents)
        aCoder.encode(children, forKey: Task.propertyKeys.children)
        aCoder.encode(active, forKey: Task.propertyKeys.active)
    }
    
    private func saveTask() {
        let rootTask = findRoot()
        var isSuccessfulSave = false
        isSuccessfulSave = NSKeyedArchiver.archiveRootObject(rootTask, toFile: Task.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("Tasks successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save tasks...", log: OSLog.default, type: .error)
        }
    }
    
    static func loadTask() -> Task? {
        if let savedTask = NSKeyedUnarchiver.unarchiveObject(withFile: Task.ArchiveURL.path) as? Task {
            return savedTask
        }
        return nil
    }
}

//MARK: - Stub Data
extension Task {
    static var stubTasks : Task = {
        var life = Task(name: "My Life")
        life.selected = true
        var meals = Task(name: "Meals")
        var work = Task(name: "Work")
        var home = Task(name: "Home")
        life.addTask(work)
        life.addTask(home)
        life.addTask(meals)
        var breakfast = Task(name: "Breakfast")
        var lunch = Task(name: "Lunch")
        var dinner = Task(name: "Dinner")
        meals.addTask(breakfast)
        meals.addTask(lunch)
        meals.addTask(dinner)
        var yard = Task(name: "Yardwork")
        var clean = Task(name: "Clean")
        home.addTask(yard)
        home.addTask(clean)
        
        return life
    }()
}
