//
//  TaskCell.swift
//  TaskMagic
//
//  Created by Collin Argo on 4/26/18.
//  Copyright © 2018 Loco Motion Enterprises. All rights reserved.
//

import Foundation
import UIKit

class TaskCell : UITableViewCell {
    static let reuseIdentifier = "Task Cell"
    
    private var task = Task()
    
    private var activeTaskColor : UIColor {
        return UIColor(hue: CGFloat(task.priority), saturation: CGFloat(task.priority / 2), brightness: 1, alpha: CGFloat(task.priority))
    }
    
    private var inactiveTaskColor : UIColor {
        return UIColor(white: CGFloat(task.priority), alpha: CGFloat(task.priority))
    }
    
    private var avgTaskColor : UIColor {
        var avgPriority = 0.0
        for child in task.currentParent.activeChildTasks() {
            avgPriority += child.priority
        }
        avgPriority /= Double(task.currentParent.activeChildTasks().count)
        return UIColor(hue: CGFloat(avgPriority), saturation: CGFloat(avgPriority / 4), brightness: 1, alpha: CGFloat(avgPriority))
    }
    
    var tableView = UITableView()
    
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var subtasksNamesLabel: UILabel!
    @IBOutlet weak var taskCellView: UIView!
    
    func configure(for task: Task) {
        self.task = task
        
        // Set task names and child tasks names
        taskNameLabel.text = task.name
        // Round Edges
        taskCellView.layer.cornerRadius = 20
        
        // set cell color
        if task.active {
            subtasksNamesLabel.text = task.description(of: task.activeChildTasks())
            subtasksNamesLabel.textColor = UIColor.blue
            subtasksNamesLabel.font = subtasksNamesLabel.font.withSize(12)
            // set active font size to 60 max
            let fontSize = (16.0 * task.priority) + 16.0
            taskNameLabel.font = taskNameLabel.font.withSize(CGFloat(fontSize))
            taskCellView.backgroundColor = activeTaskColor
        } else {
            subtasksNamesLabel.text = "✓"
            subtasksNamesLabel.textColor = UIColor.black
            subtasksNamesLabel.font = subtasksNamesLabel.font.withSize(16)
            taskNameLabel.font = taskNameLabel.font.withSize(16)
            taskCellView.backgroundColor = inactiveTaskColor
        }
        
        tableView.backgroundColor = avgTaskColor
    }
    
    func swipe(with swipeGestureRecognizer: UISwipeGestureRecognizer) {
        if swipeGestureRecognizer.direction == .right {
            task.swipe(true)
        } else {
            task.swipe(false)
        }
        tableView.reloadData()
    }
}
