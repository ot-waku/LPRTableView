//
//  MasterViewController.swift
//  LPRTableView
//
//  Created by Nicolas Gomollon on 6/17/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import UIKit
import LPRTableView

private let cellIdentifier = "Cell"

final class MasterViewController: LPRTableViewController {
    
    private var objects = [Date]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertNewObject(_ sender: UIBarButtonItem) {
        objects.insert(Date(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }


    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        let object = objects[indexPath.row]
        cell.textLabel?.text = object.description
        
        // Reset any possible modifications made in `tableView:draggingCell:atIndexPath:` to avoid reusing the modified cell.

        return cell
    }
    

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            objects.remove(at: indexPath.row)
        default:
            break
        }
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "show":
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                guard let destinationViewController = segue.destination as? DetailViewController else {
                    return
                }
                destinationViewController.detailItem = object as AnyObject?
            }
        default:
            break
        }
    }
    
    // MARK: - Long Press Reorder
    
    // Important: Update your data source after the user reorders a cell.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        objects.insert(objects.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }
    
    /*
    Optional: Modify the cell (visually) before dragging occurs.
    
    NOTE: Any changes made here should be reverted in `tableView:cellForRowAtIndexPath:` to avoid accidentally reusing the modifications.
    */
    override func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    
    /*
    Optional: Called within an animation block when the dragging view is about to show.
    */
    override func tableView(_ tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
        print("The dragged cell is about to be animated!")
    }
    
    /*
    Optional: Called within an animation block when the dragging view is about to hide.
    */
    override func tableView(_ tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
        print("The dragged cell is about to be dropped.")
    }
    
    /*
    Optional: Return false for invalid region on cell.
    */
    override func tableView(_ tableView: UITableView, shouldMoveRowAtIndexPath: IndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        let locationInView = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: locationInView), let cell = tableView.cellForRow(at: indexPath) else {
            return false
        }
        let locationInCell = gestureRecognizer.location(in: cell)
        return locationInCell.x <= (cell.frame.width / 2)
    }
}
