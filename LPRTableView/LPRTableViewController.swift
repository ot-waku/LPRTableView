//
//  LPRTableViewController.swift
//  LPRTableView
//
//  Created by Yuki Nagai on 10/12/15.
//  Copyright © 2015 Nicolas Gomollon. All rights reserved.
//

import UIKit

open class LPRTableViewController: UITableViewController {
    /// Returns the long press to reorder table view managed by the controller object.
    open var longPressReorderTableView: LPRTableView {
        return tableView as! LPRTableView
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    public override init(style: UITableViewStyle) {
        super.init(style: style)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    private func initialize() {
        if !(tableView is LPRTableView) {
            // You should specify LPRTableView class in LPRTableViewController to load from nib.
            tableView = LPRTableView()
        }
        tableView.dataSource = self
        tableView.delegate = self
        longPressReorderTableView.longPressReorderDelegate = self
    }
}

extension LPRTableViewController: LPRTableViewDelegate {
    open func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    open func tableView(_ tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
    }
    open func tableView(_ tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
    }
    open func tableView(_ tableView: UITableView, shouldMoveRowAtIndexPath: IndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        return true
    }
}
