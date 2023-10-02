//
//  TaskListViewController.swift
//  TestTask
//
//  Created by Матвей Авдеев on 02.10.2023.
//

import UIKit

class TaskListViewController: UITableViewController {
    
    // MARK: - Enums
    
    enum AlertAction {
        case addNewTask
        case editTask
        
        var title: String {
            switch self {
                
            case .addNewTask:
                "Save Task"
            case .editTask:
                "Edit Task"
            }
        }
    }
    
    // MARK: - Private properties
    
    private let storageManager = StorageManager.shared
    private let identifier = "cell"
    
    private var task: [Task] = []
    private var completedTask: [Task] = []
    private var selectedIndexPath: IndexPath!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        settingNavigationBar()
        fetchData()
    }
    
    // MARK: - Ovveride functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? task.count : completedTask.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let currentTask = indexPath.section == 0 ? task[indexPath.row] : completedTask[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = currentTask.taskTitle
        content.secondaryText = currentTask.taskDescription
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Current Task" : "Completed Task"
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let selectedTask = indexPath.section == 0 ? task[indexPath.row] : completedTask[indexPath.row]
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete") { [unowned self] _, _, _ in
                storageManager.deleteTask(selectedTask)
                fetchData()
                tableView.reloadData()
            }
        
        let doneAction = UIContextualAction(style: .destructive, title: "Done") { [unowned self] _, _, _ in
            selectedTask.isComplete.toggle()
            storageManager.saveContext()
            fetchData()
            tableView.reloadData()
        }
        
        doneAction.title = indexPath.section == 0 ? "Done" : "Undone"
        doneAction.backgroundColor = .systemGreen
        
        let swipeActions = UISwipeActionsConfiguration(actions: [doneAction, deleteAction])
        
        return swipeActions
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
        showAlert(withTitle: "Edit task", andMessage: "What do you want to change?", alertAction: .editTask)
    }
    
    // MARK: - Private functions
    
    private func fetchData() {
        let fetchRequest = Task.fetchRequest()
        
        do {
            let tasks = try storageManager.viewContext.fetch(fetchRequest)
            task = tasks.filter { !$0.isComplete }
            completedTask = tasks.filter { $0.isComplete }
        } catch {
            print(error)
        }
    }
    
    private func settingNavigationBar() {
        title = "Task List"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTaskButton))
    }
    // MARK: - Objc private functions
    
    @objc private func addNewTaskButton() {
        showAlert(withTitle: "New Task", andMessage: "What do you want to do?", alertAction: .addNewTask)
    }
}
// MARK: - Make AlertController

private extension TaskListViewController {
    func showAlert(withTitle title: String, andMessage message: String, alertAction: AlertAction) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        let saveAction = UIAlertAction(title: alertAction.title, style: .default) { [unowned self] _ in
            guard let taskTitle = alert.textFields?.first?.text, !taskTitle.isEmpty else { return }
            guard let taskDescription = alert.textFields?.last?.text, !taskDescription.isEmpty else { return }
            
            if alertAction == .addNewTask {
                let task = Task(context: storageManager.viewContext)
                storageManager.createTask(task, title: taskTitle, description: taskDescription, isComplete: false)
            } else {
                let selectedTask = selectedIndexPath.section == 0 ?
                task[selectedIndexPath.row] :
                completedTask[selectedIndexPath.row]
                
                selectedTask.taskTitle = taskTitle
                selectedTask.taskDescription = taskDescription
                storageManager.saveContext()
            }
            
            fetchData()
            tableView.reloadData()
        }
        
        alert.addTextField { [unowned self] textField in
            textField.placeholder = "Task"
            if alertAction == .editTask {
               let selectedTask = selectedIndexPath.section == 0 ? task[selectedIndexPath.row] : completedTask[selectedIndexPath.row]
                textField.text = selectedTask.taskTitle
            }
        }
        
        alert.addTextField { [unowned self] textField in
            textField.placeholder = "Description"
            if alertAction == .editTask {
                let selectedTask = selectedIndexPath.section == 0 ? task[selectedIndexPath.row] : completedTask[selectedIndexPath.row]
                textField.text = selectedTask.taskDescription
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        present(alert, animated: true)
    }
}
