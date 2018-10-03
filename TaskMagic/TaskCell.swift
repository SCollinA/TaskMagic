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
        return UIColor(hue: CGFloat(task.priority), saturation: CGFloat(task.priority / 2), brightness: 1, alpha: 1) // CGFloat(task.priority))
    }
    
    private var inactiveTaskColor : UIColor {
        return UIColor(white: CGFloat(1 - task.priority / 2), alpha: 1) //CGFloat(task.priority))
    }
    
    var tableView = UITableView()
    
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var subtasksNamesLabel: UILabel!
    @IBOutlet weak var taskCellView: TaskCellView!
    
    func configure(for task: Task) {
        self.task = task
        
        // Set task names and child tasks names
        taskNameLabel.text = task.name
        // Round Edges
        taskCellView.layer.cornerRadius = 20
        
        // set cell color
        if task.active {
            subtasksNamesLabel.text = task.description(of: task.activeChildTasks)
            subtasksNamesLabel.textColor = UIColor.blue
            subtasksNamesLabel.font = subtasksNamesLabel.font.withSize(12)
            // set active font size to 24 max
            let fontSize =  (8.0 * task.priority) + 16.0
            taskNameLabel.font = taskNameLabel.font.withSize(CGFloat(fontSize))
            taskCellView.color = activeTaskColor
            taskNameLabel.sizeToFit()
            subtasksNamesLabel.sizeToFit()
//            taskCellView.frame = CGRect(x: 0, y: 0, width: taskCellView.frame.width * CGFloat(task.priority), height: taskCellView.frame.height)
            print(CGFloat(task.priority) * taskCellView.frame.width)
            
        } else {
            subtasksNamesLabel.text = "✓"
            subtasksNamesLabel.textColor = UIColor.black
            subtasksNamesLabel.font = subtasksNamesLabel.font.withSize(16)
            taskNameLabel.font = taskNameLabel.font.withSize(16)
            taskCellView.color = inactiveTaskColor
            taskNameLabel.sizeToFit()
            subtasksNamesLabel.sizeToFit()
//            taskCellView.frame = CGRect(x: 0, y: 0, width: taskCellView.frame.width * 0.5, height: taskCellView.frame.height)
            print(tableView.frame.width * 0.5)
        }
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

class TaskCellView: UIView {
    // prevent cell from becoming transparent during reordering
    var color: UIColor = .clear {
        didSet {
            backgroundColor = color
        }
    }
    
    override var backgroundColor: UIColor? {
        set {
            guard newValue == color else { return }
            super.backgroundColor = newValue
        }
        
        get {
            return super.backgroundColor
        }
    }
}
