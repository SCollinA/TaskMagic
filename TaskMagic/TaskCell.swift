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
    var tableView = UITableView()
    
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var subtasksNamesLabel: UILabel!
    @IBOutlet weak var taskCellView: UIView!
    
    // set cell height to label height plus 10 above and 10 below = 20
    // must be computed to acquire dynamically
//    var taskCellViewHeight : CGFloat {
//        return taskNameLabel.frame.height >= subtasksNamesLabel.frame.height ? taskNameLabel.frame.height + 30 : subtasksNamesLabel.frame.height + 30
//    }
    
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
            taskNameLabel.font = taskNameLabel.font.withSize(32)
            taskCellView.backgroundColor = UIColor.green
        } else {
            subtasksNamesLabel.text = "✓"
            subtasksNamesLabel.textColor = UIColor.black
            subtasksNamesLabel.font = subtasksNamesLabel.font.withSize(16)
            taskNameLabel.font = taskNameLabel.font.withSize(16)
            taskCellView.backgroundColor = UIColor.lightGray
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
