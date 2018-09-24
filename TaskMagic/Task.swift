//
//  Task.swift
//  TaskMagic
//
//  Created by Collin Argo on 4/26/18.
//  Copyright © 2018 Loco Motion Enterprises. All rights reserved.
//

import Foundation
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
    
    var dateActivated : Date?
    var dateDeactivated : Date?
    
    var priority : Double {
        if let dateActivated = dateActivated {
            let timeActive = DateInterval(start: dateActivated, end: Date()).duration
            if let index = currentParent.activeChildTasks().index(of: self) {
                // reverse order, first is highest, percent
                let order = Double((currentParent.activeChildTasks().count - index)) / Double(currentParent.activeChildTasks().count)
                // find max time active for currentparent children
                var maxTimeActive = timeActive
                for child in currentParent.activeChildTasks() {
                    let childTimeActive = DateInterval(start: child.dateActivated!, end: Date()).duration
                    if childTimeActive > timeActive {
                        maxTimeActive = childTimeActive
                    }
                }
                let timeFactor = timeActive / maxTimeActive
                return timeFactor * order
            }
        } else if let dateDeactivated = dateDeactivated {
            let timeInactive = DateInterval(start: dateDeactivated, end: Date()).duration
            if let index = currentParent.inactiveChildTasks().index(of: self) {
                // regular order, last is highest, percent
                let order = Double(index) / Double(currentParent.inactiveChildTasks().count)
                // find max time inactive for currentparent children
                var maxTimeInactive = timeInactive
                for child in currentParent.inactiveChildTasks() {
                    let childTimeInactive = DateInterval(start: child.dateDeactivated!, end: Date()).duration
                    if childTimeInactive > timeInactive {
                        maxTimeInactive = childTimeInactive
                    }
                }
                let timeFactor = timeInactive / maxTimeInactive
                return timeFactor * order
            }
        }
        return 0.0
    }

    //MARK: - Setup
    init(name: String = "") {
        self.name = name
        dateActivated = Date()
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
        if let dateActivated = aDecoder.decodeObject(forKey: Task.propertyKeys.dateActivated) as? Date? {
            self.dateActivated = dateActivated
        }
        if let dateDeactivated = aDecoder.decodeObject(forKey: Task.propertyKeys.dateDeactivated) as? Date? {
            self.dateDeactivated = dateDeactivated
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
        sortTasks()
    }
    
    func removeTask(_ task: Task) {
        if let index = children.index(of: task) {
            children.remove(at: index)
        }
        if let index = task.parents.index(of: self) {
            task.parents.remove(at: index)
        }
        sortTasks()
    }
    
    func moveTask(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movingTask = task(at: sourceIndexPath)
        removeTask(movingTask)
        insertTask(movingTask, at: destinationIndexPath)
        sortTasks()
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
//        if currentParent == self { // if at root task
//            // change root task name and save
//            self.name = newName
//        } else
        if !currentParent.contains(taskNamed: newName) {
            // if current parent does not contain task with that name
            // if there is another task with that name
            // add that task here
            for task in allTasks() {
                if task.name == newName {
                    // make sure task is active
                    task.swipe(true)
                    currentParent.insertTask(task, at: IndexPath(row: currentParent.children.index(of: self)!, section: 0))
                    currentParent.removeTask(self)
                    saveTask()
                    return
                }
            }
            // if no task already with that name
            self.name = newName
        }
        saveTask()
    }
    
    func swipe(_ active: Bool) {
        // if already what it's supposed to be, don't change
        if active == self.active {
            return
        }
        self.active = active
        if !active {
            // assign dateDeactivated, unassign dateActivated
            dateDeactivated = Date()
            dateActivated = nil
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
            // assign dateActivated, unassign dateDeactivated
            dateActivated = Date()
            dateDeactivated = nil
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
        sortTasks()
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

    private func sortTasks() {
        // find root task, sort children and children's children
        let rootTask = findRoot()
        rootTask.sortChildTasks()
        saveTask()
    }
    
    private func sortChildTasks() {
        // place all active children in new array
        var activeChildren = activeChildTasks()
        // place all inactive children in new array
        var inactiveChildren = inactiveChildTasks()
        // sort both arrays in place
        activeChildren.sort {
            return $0.priority > $1.priority
        }
        inactiveChildren.sort {
            return $0.priority < $1.priority
        }
        // remove all children
        children.removeAll()
        // append active children to children
        children.append(contentsOf: activeChildren)
        // append inactive children to children
        children.append(contentsOf: inactiveChildren)
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

    func inactiveChildTasks() -> [Task] {
        var inactiveTaskArray = [Task]()
        for task in children {
            if !task.active {
                inactiveTaskArray.append(task)
            }
        }
        return inactiveTaskArray
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
        static let dateActivated = "dateActivated"
        static let dateDeactivated = "dateDeactivated"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Task.propertyKeys.name)
        aCoder.encode(parents, forKey: Task.propertyKeys.parents)
        aCoder.encode(children, forKey: Task.propertyKeys.children)
        aCoder.encode(active, forKey: Task.propertyKeys.active)
        aCoder.encode(dateActivated, forKey: Task.propertyKeys.dateActivated)
        aCoder.encode(dateDeactivated, forKey: Task.propertyKeys.dateDeactivated)
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
