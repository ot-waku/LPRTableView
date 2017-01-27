//
//  LPRTableViewDelegate.swift
//  LPRTableView
//
//  Created by Yuki Nagai on 10/12/15.
//  Copyright © 2015 Nicolas Gomollon. All rights reserved.
//

import Foundation

public protocol LPRTableViewDelegate: NSObjectProtocol {
    /**
    Provides the delegate a chance to modify the cell visually before dragging occurs. Defaults to using the cell as-is if not implemented.
    The default implementation of this method is empty—no need to call `super`.
    */
    func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) -> UITableViewCell
    /**
    alled within an animation block when the dragging view is about to show. The default implementation of this method is empty—no need to call `super`.
    */
    func tableView(_ tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: IndexPath)
    /**
    Called within an animation block when the dragging view is about to hide. The default implementation of this method is empty—no need to call `super`.
    */
    func tableView(_ tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: IndexPath)
    /**
    Decide if the cell should move or not for gesture location.
    
    Default: true
    */
    func tableView(_ tableView: UITableView, shouldMoveRowAtIndexPath: IndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool
}

extension LPRTableViewDelegate {
    public func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    public func tableView(_ tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
    }
    public func tableView(_ tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
    }
    public func tableView(_ tableView: UITableView, shouldMoveRowAtIndexPath: IndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        return true
    }
}
